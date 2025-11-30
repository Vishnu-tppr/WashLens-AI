import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_utils.dart';
import '../../services/supabase_service.dart';
import '../../providers/user_provider.dart';

List<BoxShadow> softShadow = [
  const BoxShadow(
    color: Color(0x1A4A6FFF),
    blurRadius: 28,
    spreadRadius: -5,
    offset: Offset(0, 10),
  ),
  const BoxShadow(
    color: Color(0x14000000),
    blurRadius: 16,
    spreadRadius: -6,
    offset: Offset(0, 4),
  ),
];

class ConfirmManualReturnScreen extends StatefulWidget {
  final String? washId;
  final Map<String, dynamic>? washData;

  const ConfirmManualReturnScreen({super.key, this.washId, this.washData});

  @override
  State<ConfirmManualReturnScreen> createState() =>
      _ConfirmManualReturnScreenState();
}

class _ConfirmManualReturnScreenState extends State<ConfirmManualReturnScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _wash;

  @override
  void initState() {
    super.initState();
    if (widget.washData != null) {
      _wash = widget.washData;
    } else if (widget.washId != null) {
      _loadWashData();
    }
  }

  Future<void> _loadWashData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.currentUser?.id;

    if (userId != null) {
      final washes = await SupabaseService.getWashEntries(userId);
      final wash = washes.firstWhere(
        (w) => w['id'] == widget.washId,
        orElse: () => {},
      );

      if (mounted && wash.isNotEmpty) {
        setState(() => _wash = wash);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final dhobiName = _wash?['dhobi_name'] ?? 'Unknown Dhobi';
    final totalItems = _wash?['total_items'] ?? 0;
    final givenDate = _wash?['given_at'] != null
        ? DateTime.parse(_wash!['given_at'] as String)
        : DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy').format(givenDate);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Confirm Manual Return',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: r.fontSize(20, min: 18, max: 22),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: r.padding(horizontal: 24, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              // Info Card
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: softShadow,
                ),
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  children: [
                    // Top row (Dhobi name & icon)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Dhobi",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              dhobiName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.local_laundry_service_rounded,
                            color: AppTheme.primary,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Item & Date row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Items Given",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              totalItems.toString(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Date Given",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              // Warning card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB), // warningBg
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppTheme.warning, size: 30), // warningIcon
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "No AI Verification will be performed. Are you sure all items are back?",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme
                              .warning, // warningText (using warning instead of custom color)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Confirm button
              _GradientButton(
                icon: Icons.check_circle_rounded,
                label: "Confirm All Returned",
                isLoading: _isLoading,
                onTap: _isLoading ? null : _handleConfirmReturn,
              ),
              const SizedBox(height: 14),
              // Cancel button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Cancel",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleConfirmReturn() async {
    if (_wash == null || widget.washId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Wash data not found'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update wash entry to mark as returned
      final success = await SupabaseService.updateWashEntry(
        widget.washId!,
        {
          'status': 'returned',
          'returned_at': DateTime.now().toIso8601String(),
          'return_method': 'manual',
        },
      );

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Laundry marked as returned! ${_wash!['total_items']} items confirmed.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back to home
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } else if (mounted) {
        throw Exception('Failed to update wash entry');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to confirm return: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _GradientButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          elevation: 7,
          shadowColor: AppTheme.primary.withAlpha(46),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Utility for gradient on ElevatedButton (works with Material v3)
extension GradientButtonExtension on Widget {
  Widget applyGradient({required Gradient gradient}) => Container(
        decoration: BoxDecoration(
            gradient: gradient, borderRadius: BorderRadius.circular(16)),
        child: this,
      );
}
