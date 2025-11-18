import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'supabase_service.dart';

/// Service for exporting wash data as PDF and sharing via WhatsApp
class ExportService {
  ExportService();

  /// Export all user data (washes, settings, analytics)
  Future<Map<String, dynamic>> exportAllUserData() async {
    final userId = SupabaseService.currentUser?.id ?? 'demo_user';

    try {
      // Get all wash entries
      final washes = await SupabaseService.getWashEntries(userId);

      // Get user settings from provider if available, otherwise use defaults
      final settings = {
        'notificationEnabled': true,
        'reminderDays': 3,
        'pickupReminderHours': 24,
        'exportCount': 0,
      };

      // Get analytics data (if exists)
      final analytics = {
        'totalWashes': washes.length,
        'totalItems': washes.fold(0, (sum, wash) => sum + (wash['total_items'] as int? ?? 0)),
        'completedWashes': washes.where((w) => w['status'] == 'returned').length,
        'exportDate': DateTime.now().toIso8601String(),
        'washlensVersion': '1.0.0',
      };

      return {
        'userId': userId,
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'data': {
          'settings': settings,
          'washes': washes,
          'analytics': analytics,
        },
        'metadata': {
          'exportType': 'full_user_data',
          'containsPersonalData': true,
          'compatibleWith': ['WashLens AI v1.0.0+'],
        },
      };
    } catch (e) {
      throw Exception('Failed to export user data: $e');
    }
  }

  /// Share exported data as JSON file
  Future<void> shareUserDataAsJson() async {
    try {
      final data = await exportAllUserData();

      // Convert to JSON
      final jsonData = jsonEncode(data);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/washlens_data_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonData);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'WashLens AI - My Data Export',
        text: 'Complete export of my WashLens AI data including washes, settings, and analytics.',
      );

      // Clean up file after sharing
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to share data: $e');
    }
  }

  /// Generate PDF for a wash entry
  Future<File> generatePdfForWash(String washId) async {
    final userId = SupabaseService.currentUser?.id ?? 'demo_user';
    final washes = await SupabaseService.getWashEntries(userId);
    final wash = washes.firstWhere((w) => w['id'] == washId,
        orElse: () => throw Exception('Wash not found: $washId'));

    final dhobiName = wash['dhobi_name'] as String? ?? 'Unknown';
    final totalItems = wash['total_items'] as int? ?? 0;
    final status = wash['status'] as String? ?? 'pending';

    final pdf = pw.Document();

    // Add page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                'WashLens AI',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Laundry Tracking Report',
                style:
                    const pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 16),

              // Dhobi Information
              pw.Text(
                'Laundry Service Details',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Service: $dhobiName'),
              pw.Text(
                'Given: ${DateFormat('MMM dd, yyyy h:mm a').format(DateTime.parse(wash['given_at'] as String? ?? DateTime.now().toIso8601String()))}',
              ),
              if (wash['returned_at'] != null)
                pw.Text(
                  'Returned: ${DateFormat('MMM dd, yyyy h:mm a').format(DateTime.parse(wash['returned_at'] as String))}',
                ),
              pw.SizedBox(height: 16),

              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Total',
                      totalItems.toString(),
                      PdfColors.blue,
                    ),
                    _buildSummaryItem(
                      'Status',
                      status.toUpperCase(),
                      PdfColors.green,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Notes
              if (wash['notes'] != null &&
                  (wash['notes'] as String).isNotEmpty) ...[
                pw.Text(
                  'Notes',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(wash['notes'] as String),
                pw.SizedBox(height: 16),
              ],

              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.Text(
                'Generated by WashLens AI on ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF to temporary directory
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/washlens_${washId.substring(0, 8)}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Build summary item widget for PDF
  pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
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
