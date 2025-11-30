import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'supabase_service.dart';

/// PDF Quality levels with specific settings
enum PdfQuality {
  low('Low', 72.0, PdfPageFormat.a5),
  medium('Medium', 150.0, PdfPageFormat.a4),
  high('High', 300.0, PdfPageFormat.a4),
  ;

  const PdfQuality(this.displayName, this.dpi, this.pageFormat);

  final String displayName;
  final double dpi;
  final PdfPageFormat pageFormat;
}

/// Service for exporting wash data as PDF and sharing
class ExportService {
  ExportService();

  /// Export all user data (washes, dhobis, categories, analytics)
  Future<Map<String, dynamic>> exportAllUserData() async {
    final userId = SupabaseService.currentUser?.id;

    if (userId == null) {
      throw Exception('No user logged in');
    }

    try {
      // Get all user data
      final washes = await SupabaseService.getWashEntries(userId);
      final dhobis = await SupabaseService.getDhobis(userId);
      final categories = await SupabaseService.getCategories(userId);

      // Calculate analytics
      final totalItems = washes.fold<int>(
          0, (sum, wash) => sum + (wash['total_items'] as int? ?? 0));
      final completedWashes =
          washes.where((w) => w['status'] == 'returned').length;
      final pendingWashes =
          washes.where((w) => w['status'] != 'returned').length;

      // Calculate average turnaround time for completed washes
      int totalDays = 0;
      int countWithDates = 0;
      for (var wash in washes) {
        if (wash['status'] == 'returned' &&
            wash['given_at'] != null &&
            wash['returned_at'] != null) {
          final givenDate = DateTime.parse(wash['given_at'] as String);
          final returnedDate = DateTime.parse(wash['returned_at'] as String);
          totalDays += returnedDate.difference(givenDate).inDays;
          countWithDates++;
        }
      }
      final avgTurnaround =
          countWithDates > 0 ? (totalDays / countWithDates).round() : 0;

      final analytics = {
        'totalWashes': washes.length,
        'totalItems': totalItems,
        'completedWashes': completedWashes,
        'pendingWashes': pendingWashes,
        'averageTurnaroundDays': avgTurnaround,
        'totalDhobis': dhobis.length,
        'totalCategories': categories.length,
        'exportDate': DateTime.now().toIso8601String(),
        'washlensVersion': '1.0.0',
      };

      return {
        'userId': userId,
        'userEmail': SupabaseService.currentUser?.email ?? '',
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'data': {
          'washes': washes,
          'dhobis': dhobis,
          'categories': categories,
          'analytics': analytics,
        },
        'metadata': {
          'exportType': 'full_user_data',
          'containsPersonalData': true,
          'compatibleWith': ['WashLens AI v1.0.0+'],
          'format': 'json',
        },
      };
    } catch (e) {
      debugPrint('Export error: $e');
      throw Exception('Failed to export user data: $e');
    }
  }

  /// Share exported data as JSON and CSV files
  Future<void> shareUserDataAsJson() async {
    try {
      final data = await exportAllUserData();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final files = <XFile>[];

      // 1. Create JSON file
      final jsonFile =
          File('${tempDir.path}/washlens_complete_data_$timestamp.json');
      await jsonFile.writeAsString(jsonEncode(data));
      files.add(XFile(jsonFile.path));

      // 2. Create CSV file for washes (most important data)
      final csvFile = File('${tempDir.path}/washlens_washes_$timestamp.csv');
      final csvData = _generateWashesCsv(data['data']['washes'] as List);
      await csvFile.writeAsString(csvData);
      files.add(XFile(csvFile.path));

      // 3. Create summary text file
      final summaryFile =
          File('${tempDir.path}/washlens_summary_$timestamp.txt');
      final summaryData = _generateSummaryText(data);
      await summaryFile.writeAsString(summaryData);
      files.add(XFile(summaryFile.path));

      // Share all files
      await Share.shareXFiles(
        files,
        subject: 'WashLens AI - Complete Data Export',
        text:
            'My complete WashLens AI data including ${(data['data']['washes'] as List).length} wash entries and analytics.',
      );

      // Clean up files
      await Future.delayed(const Duration(seconds: 2));
      for (var file in [jsonFile, csvFile, summaryFile]) {
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Share data error: $e');
      throw Exception('Failed to share data: $e');
    }
  }

  /// Generate CSV format for wash entries
  String _generateWashesCsv(List washes) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln(
        'ID,Dhobi Name,Total Items,Status,Given At,Returned At,Expected Return,Notes,Created At');

    // CSV Rows
    for (var wash in washes) {
      final id = wash['id'] ?? '';
      final dhobiName =
          wash['dhobi_name']?.toString().replaceAll(',', ';') ?? '';
      final totalItems = wash['total_items'] ?? 0;
      final status = wash['status'] ?? '';
      final givenAt = wash['given_at'] ?? '';
      final returnedAt = wash['returned_at'] ?? '';
      final expectedReturn = wash['expected_return_date'] ?? '';
      final notes = wash['notes']
              ?.toString()
              .replaceAll(',', ';')
              .replaceAll('\n', ' ') ??
          '';
      final createdAt = wash['created_at'] ?? '';

      buffer.writeln(
          '$id,$dhobiName,$totalItems,$status,$givenAt,$returnedAt,$expectedReturn,"$notes",$createdAt');
    }

    return buffer.toString();
  }

  /// Generate summary text
  String _generateSummaryText(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    final analytics = data['data']['analytics'] as Map<String, dynamic>;

    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('   WASHLENS AI - DATA EXPORT SUMMARY');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('');
    buffer.writeln(
        'Export Date: ${DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now())}');
    buffer.writeln('User: ${data['userEmail']}');
    buffer.writeln('Version: ${data['version']}');
    buffer.writeln('');
    buffer.writeln('───────────────────────────────────────');
    buffer.writeln('STATISTICS');
    buffer.writeln('───────────────────────────────────────');
    buffer.writeln('Total Washes: ${analytics['totalWashes']}');
    buffer.writeln('Total Items Washed: ${analytics['totalItems']}');
    buffer.writeln('Completed Washes: ${analytics['completedWashes']}');
    buffer.writeln('Pending Washes: ${analytics['pendingWashes']}');
    buffer.writeln(
        'Average Turnaround: ${analytics['averageTurnaroundDays']} days');
    buffer.writeln('Total Dhobis: ${analytics['totalDhobis']}');
    buffer.writeln('Total Categories: ${analytics['totalCategories']}');
    buffer.writeln('');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('Files included in this export:');
    buffer.writeln('  • Complete data (JSON format)');
    buffer.writeln('  • Wash entries (CSV format)');
    buffer.writeln('  • This summary (TXT format)');
    buffer.writeln('═══════════════════════════════════════');

    return buffer.toString();
  }

  /// Generate comprehensive PDF for a wash entry with item details
  Future<File> generatePdfForWash(String washId, {PdfQuality quality = PdfQuality.high}) async {
    final userId = SupabaseService.currentUser?.id;

    if (userId == null) {
      throw Exception('No user logged in');
    }

    final washes = await SupabaseService.getWashEntries(userId);
    final wash = washes.firstWhere(
      (w) => w['id'] == washId,
      orElse: () => throw Exception('Wash not found: $washId'),
    );

    final dhobiName = wash['dhobi_name'] as String? ?? 'Unknown Dhobi';
    final totalItems = wash['total_items'] as int? ?? 0;
    final status = wash['status'] as String? ?? 'pending';
    final givenAt = DateTime.parse(
        wash['given_at'] as String? ?? DateTime.now().toIso8601String());
    final returnedAt = wash['returned_at'] != null
        ? DateTime.parse(wash['returned_at'] as String)
        : null;
    final expectedReturn = wash['expected_return_date'] != null
        ? DateTime.parse(wash['expected_return_date'] as String)
        : null;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: quality.pageFormat,
        margin: pw.EdgeInsets.all(quality == PdfQuality.low ? 16 : 32),
        build: (pw.Context context) {
          // Calculate font sizes based on quality
          final titleFontSize = quality == PdfQuality.low ? 20.0 : 28.0;
          final subtitleFontSize = quality == PdfQuality.low ? 10.0 : 14.0;
          final sectionTitleFontSize = quality == PdfQuality.low ? 16.0 : 20.0;
          final normalFontSize = quality == PdfQuality.low ? 10.0 : 12.0;
          final summaryFontSize = quality == PdfQuality.low ? 24.0 : 32.0;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with branding
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'WashLens AI',
                        style: pw.TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700,
                        ),
                      ),
                      pw.Text(
                        'Smart Laundry Tracking',
                        style: pw.TextStyle(
                          fontSize: subtitleFontSize,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: status == 'returned'
                          ? PdfColors.green100
                          : PdfColors.orange100,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      status.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: normalFontSize,
                        fontWeight: pw.FontWeight.bold,
                        color: status == 'returned'
                            ? PdfColors.green800
                            : PdfColors.orange800,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: quality == PdfQuality.low ? 1.5 : 2.0, color: PdfColors.blue700),
              pw.SizedBox(height: 24),

              // Laundry Service Information
              pw.Text(
                'Laundry Service Details',
                style: pw.TextStyle(
                  fontSize: sectionTitleFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: pw.EdgeInsets.all(quality == PdfQuality.low ? 12 : 16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Service Provider:', dhobiName, quality),
                    pw.SizedBox(height: 8),
                    _buildInfoRow(
                        'Given On:',
                        DateFormat('EEEE, MMMM dd, yyyy - hh:mm a')
                            .format(givenAt), quality),
                    if (expectedReturn != null) ...[
                      pw.SizedBox(height: 8),
                      _buildInfoRow(
                          'Expected Return:',
                          DateFormat('EEEE, MMMM dd, yyyy')
                              .format(expectedReturn), quality),
                    ],
                    if (returnedAt != null) ...[
                      pw.SizedBox(height: 8),
                      _buildInfoRow(
                          'Returned On:',
                          DateFormat('EEEE, MMMM dd, yyyy - hh:mm a')
                              .format(returnedAt), quality),
                      pw.SizedBox(height: 8),
                      _buildInfoRow('Turnaround Time:',
                          '${returnedAt.difference(givenAt).inDays} days', quality),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Summary Statistics
              pw.Text(
                'Summary',
                style: pw.TextStyle(
                  fontSize: sectionTitleFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: pw.EdgeInsets.all(quality == PdfQuality.low ? 12 : 16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Total Items', totalItems.toString(),
                        PdfColors.blue700, quality),
                    _buildSummaryItem(
                      'Status',
                      status == 'returned'
                          ? 'RETURNED'
                          : status == 'pending'
                              ? 'PENDING'
                              : status.toUpperCase(),
                      status == 'returned'
                          ? PdfColors.green700
                          : PdfColors.orange700,
                      quality,
                    ),
                    if (returnedAt != null)
                      _buildSummaryItem(
                        'Days',
                        returnedAt.difference(givenAt).inDays.toString(),
                        PdfColors.purple700,
                        quality,
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Notes Section
              if (wash['notes'] != null &&
                  (wash['notes'] as String).isNotEmpty) ...[
                pw.Text(
                  'Additional Notes',
                  style: pw.TextStyle(
                    fontSize: sectionTitleFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  width: double.infinity,
                  padding: pw.EdgeInsets.all(quality == PdfQuality.low ? 12 : 16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Text(
                    wash['notes'] as String,
                    style: pw.TextStyle(
                        fontSize: normalFontSize, color: PdfColors.grey800),
                  ),
                ),
                pw.SizedBox(height: 24),
              ],

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated: ${DateFormat('MMMM dd, yyyy • hh:mm a').format(DateTime.now())}',
                    style: pw.TextStyle(
                        fontSize: quality == PdfQuality.low ? 8 : 10, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Quality: ${quality.displayName} • Wash ID: ${washId.substring(0, 8)}',
                    style: pw.TextStyle(
                        fontSize: quality == PdfQuality.low ? 8 : 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save to temp directory
    final tempDir = await getTemporaryDirectory();
    final fileName =
        'washlens_${dhobiName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(givenAt)}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Build info row for PDF
  pw.Widget _buildInfoRow(String label, String value, PdfQuality quality) {
    final fontSize = quality == PdfQuality.low ? 8.0 : 10.0;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: quality == PdfQuality.low ? 100 : 140,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              color: PdfColors.grey900,
            ),
          ),
        ),
      ],
    );
  }

  /// Build summary item widget for PDF
  pw.Widget _buildSummaryItem(String label, String value, PdfColor color, PdfQuality quality) {
    final summaryFontSize = quality == PdfQuality.low ? 20.0 : (quality == PdfQuality.medium ? 28.0 : 32.0);
    final labelFontSize = quality == PdfQuality.low ? 8.0 : 10.0;
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: summaryFontSize,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: labelFontSize,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  /// Share PDF via system share sheet
  Future<void> sharePdf(File pdfFile) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      subject: 'WashLens Laundry Report',
      text: 'Here is my laundry tracking report from WashLens AI',
    );
  }

  /// Generate WhatsApp message for a wash
  String generateWhatsAppMessage(Map<String, dynamic> wash) {
    final buffer = StringBuffer();
    final dhobiName = wash['dhobi_name'] as String? ?? 'Unknown';
    final totalItems = wash['total_items'] as int? ?? 0;

    buffer.writeln('📋 *Laundry Report - $dhobiName*');
    buffer.writeln('');
    buffer.writeln(
      '📅 Given: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(wash['given_at'] as String? ?? DateTime.now().toIso8601String()))}',
    );
    buffer.writeln('');
    buffer.writeln('📊 Summary:');
    buffer.writeln('✅ Total Items: $totalItems');
    buffer.writeln('📌 Status: ${wash['status']}');

    buffer.writeln('');
    buffer.writeln('_Generated by WashLens AI_');

    return buffer.toString();
  }

  /// Share WhatsApp message
  Future<void> shareWhatsAppMessage(String message) async {
    await Share.share(message, subject: 'WashLens Laundry Report');
  }

  /// Print PDF
  Future<void> printPdf(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
  }
}
