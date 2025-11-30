import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_utils.dart';
import '../scan/scan_screen.dart';
import 'confirm_manual_return_screen.dart';

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

class MarkReturnedScreen extends StatelessWidget {
  final String? washId;

  const MarkReturnedScreen({super.key, this.washId});

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Mark as Returned',
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
              const SizedBox(height: 8),
              // Subtitle
              Text(
                "Confirm Return for Anil Dhobi?",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Info Card
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: softShadow,
                ),
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(vertical: 8),
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
                              "Anil Dhobi",
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
                            size: 32, // text-4xl
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
                              "32",
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
                              "May 28, 2024",
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
              const Spacer(),
              // Scan button
              _BigPrimaryButton(
                icon: Icons.qr_code_scanner_rounded,
                label: "Scan Returned Clothes",
                onTap: () {
                  // Navigate to scan screen with wash data for AI comparison
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScanScreen(
                        washId: washId,
                        role: 'returned',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Manual button
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ConfirmManualReturnScreen(washId: washId),
                    ),
                  );
                },
                child: Text(
                  "Mark All Returned Manually",
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
}

class _BigPrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _BigPrimaryButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white, size: 28),
        label: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 7,
          shadowColor: AppTheme.primary.withAlpha(46),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        onPressed: onTap,
      ),
    );
  }
}
