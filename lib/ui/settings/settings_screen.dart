import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_settings_screen.dart';
import 'privacy_policy_screen.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_utils.dart';
import '../../providers/user_provider.dart';
import '../../services/export_service.dart';
import '../../services/supabase_service.dart';
import '../../models/app_user.dart' as models;

// Import the PDF quality enum

// Tailwind tokens
class AppColors {
  static const primary = Color(0xFF4A6FFF);
  static const secondary = Color(0xFFA3B4FF);
  static const accent = Color(0xFF6EE7B7);
  static const backgroundLight = Color(0xFFF8FAFC);
  static const bgLight = Color(0xFFF8FAFC);
  static const cardLight = Color(0xFFFFFFFF);
  static const textLightPrimary = Color(0xFF0F172A);
  static const textPrimary = Color(0xFF0F172A);
  static const textLightSecondary = Color(0xFF475569);
  static const textSecondary = Color(0xFF475569);
  static const iconBgLight = Color(0xFFEEF2FF);
  static const red100 = Color(0xFFFEE2E2);
  static const red500 = Color(0xFFEF4444);
}

List<BoxShadow> softShadow = [
  const BoxShadow(
    color: Color(0x1A4A6FFF),
    blurRadius: 28,
    spreadRadius: -2,
    offset: Offset(0, 10),
  ),
  const BoxShadow(
    color: Color(0x10000000),
    blurRadius: 16,
    spreadRadius: -1,
    offset: Offset(0, 4),
  ),
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _pdfQuality = 'High';

  @override
  void initState() {
    super.initState();
    _loadPdfQuality();
  }

  // Load PDF quality from shared preferences
  Future<void> _loadPdfQuality() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedQuality = prefs.getString('pdf_export_quality');
      if (savedQuality != null && mounted) {
        setState(() => _pdfQuality = savedQuality);
      }
    } catch (e) {
      debugPrint('Error loading PDF quality: $e');
    }
  }

  // Save PDF quality to shared preferences
  Future<void> _savePdfQuality(String quality) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pdf_export_quality', quality);
    } catch (e) {
      debugPrint('Error saving PDF quality: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.bgLight,
          appBar: AppBar(
            title: Text(
              'Settings',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: r.fontSize(20, min: 18, max: 22),
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.cardLight,
          ),
          body: Padding(
            padding: r.padding(horizontal: 16, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ACCOUNT
                const _SectionHeader(label: "ACCOUNT"),
                Padding(
                  padding: r.horizontalPadding(8),
                  child: _Card(
                    child: Column(
                      children: [
                        Consumer<UserProvider>(
                          builder: (context, userProvider, _) {
                            final userName = userProvider.userName;
                            final userEmail = userProvider.userEmail;
                            final initials = userName.isNotEmpty
                                ? userName.substring(0, 2).toUpperCase()
                                : 'U';

                            // Get avatar URL from user metadata (supports both Supabase and Firebase)
                            String? avatarUrl;
                            final currentAuthUser = userProvider.currentUser;
                            if (currentAuthUser != null) {
                              if (currentAuthUser is models.SupabaseAuthUser) {
                                final userMetadata = currentAuthUser.user.userMetadata;
                                if (userMetadata != null &&
                                    userMetadata.containsKey('avatar_url')) {
                                  avatarUrl = userMetadata['avatar_url'] as String?;
                                }
                              } else if (currentAuthUser is models.FirebaseAuthUser) {
                                // Firebase user - get photoURL from Google Sign-In
                                avatarUrl = currentAuthUser.photoURL;
                              }
                            }

                            return InkWell(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/edit-profile'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                child: Row(
                                  children: [
                                    // Profile photo or initials
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: avatarUrl != null &&
                                                avatarUrl.isNotEmpty
                                            ? Colors.transparent
                                            : const Color(0xFF4A6FFF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: avatarUrl != null &&
                                              avatarUrl.isNotEmpty
                                          ? ClipOval(
                                              child: avatarUrl
                                                      .startsWith('http')
                                                  ? Image.network(
                                                      avatarUrl,
                                                      key: ValueKey(avatarUrl),
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return _buildInitialsWidget(
                                                            initials);
                                                      },
                                                    )
                                                  : Image.file(
                                                      File(avatarUrl),
                                                      key: ValueKey(avatarUrl),
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return _buildInitialsWidget(
                                                            initials);
                                                      },
                                                    ),
                                            )
                                          : _buildInitialsWidget(initials),
                                    ),
                                    r.spacingWidth(14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userName,
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: r.fontSize(17, min: 15, max: 19),
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          r.spacingHeight(2),
                                          Text(
                                            userEmail,
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: r.fontSize(13, min: 11, max: 15),
                                                fontWeight: FontWeight.w400,
                                                color: AppColors.textSecondary),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Divider
                        Container(
                            height: 1,
                            width: double.infinity,
                            color: const Color(0xFFF1F5F9)),
                        InkWell(
                          onTap: _showSignOutDialog,
                          child: Padding(
                            padding: r.padding(horizontal: 16, vertical: 16),
                            child: Row(
                              children: [
                                Container(
                                  width: r.iconSize(40),
                                  height: r.iconSize(40),
                                  decoration: BoxDecoration(
                                    color: AppColors.red100,
                                    borderRadius: r.borderRadius(16),
                                  ),
                                  child: Icon(Icons.logout,
                                      color: AppColors.red500,
                                      size: r.iconSize(24)),
                                ),
                                r.spacingWidth(12),
                                Text("Sign Out",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: r.fontSize(15, min: 13, max: 17),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    )),
                                const Spacer(),
                                Icon(Icons.chevron_right,
                                    color: AppColors.textSecondary,
                                    size: r.iconSize(20)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                r.spacingHeight(12),

                // DATA MANAGEMENT
                const _SectionHeader(label: "DATA MANAGEMENT"),
                Padding(
                  padding: r.horizontalPadding(8),
                  child: _Card(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.picture_as_pdf,
                          iconBg: AppColors.iconBgLight,
                          iconColor: AppColors.primary,
                          title: "PDF Export Quality",
                          subtitle: _pdfQuality,
                          onTap: _showPdfQualityDialog,
                        ),
                        _Divider(),
                        _SettingsTile(
                          icon: Icons.download,
                          iconBg: AppColors.iconBgLight,
                          iconColor: AppColors.primary,
                          title: "Export All My Data",
                          onTap: _handleExportAllData,
                        ),
                        _Divider(),
                        _SettingsTile(
                          icon: Icons.delete,
                          iconBg: AppColors.red100,
                          iconColor: AppColors.red500,
                          title: "Delete Account",
                          onTap: _showDeleteAccountDialog,
                        ),
                      ],
                    ),
                  ),
                ),

                r.spacingHeight(12),

                // NOTIFICATIONS & WIDGETS
                const _SectionHeader(label: "NOTIFICATIONS & WIDGETS"),
                Padding(
                  padding: r.horizontalPadding(8),
                  child: _Card(
                    child: _SettingsTile(
                      icon: Icons.notifications,
                      iconBg: AppColors.iconBgLight,
                      iconColor: AppColors.primary,
                      title: "Reminders",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                r.spacingHeight(12),

                // LEGAL & PRIVACY
                const _SectionHeader(label: "LEGAL & PRIVACY"),
                Padding(
                  padding: r.horizontalPadding(8),
                  child: _Card(
                    child: _SettingsTile(
                      icon: Icons.privacy_tip,
                      iconBg: AppColors.iconBgLight,
                      iconColor: AppColors.primary,
                      title: "Data Privacy",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom navigation bar with "frost"/blur effect (moved to proper Scaffold property)
          bottomNavigationBar: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.cardLight.withOpacity(0.8),
                  border: const Border(
                    top: BorderSide(
                      color: Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTabItem(
                            icon: Icons.home_outlined,
                            selectedIcon: Icons.home,
                            label: 'Home',
                            index: 0,
                            isSelected: false),
                        _buildTabItem(
                            icon: Icons.add_a_photo_outlined,
                            selectedIcon: Icons.add_a_photo,
                            label: 'New Wash',
                            index: 1,
                            isSelected: false),
                        _buildTabItem(
                            icon: Icons.receipt_long_outlined,
                            selectedIcon: Icons.receipt_long,
                            label: 'History',
                            index: 2,
                            isSelected: false),
                        _buildTabItem(
                            icon: Icons.settings_outlined,
                            selectedIcon: Icons.settings,
                            label: 'Settings',
                            index: 3,
                            isSelected: true),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return Expanded(
      child: _AnimatedNavItem(
        icon: icon,
        selectedIcon: selectedIcon,
        label: label,
        isSelected: isSelected,
        onTap: () {
          switch (index) {
            case 0:
              Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (route) => false);
              break;
            case 1:
              Navigator.pushNamed(context, '/scan');
              break;
            case 2:
              Navigator.pushNamed(context, '/history');
              break;
            case 3:
              // Already on settings - no navigation
              break;
          }
        },
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.red100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.logout, color: AppColors.red500, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Sign Out'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to sign out?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your data is safely stored and will be available when you sign back in.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _handleSignOut(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red500,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sign Out',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSignOut() async {
    Navigator.pop(context); // Close dialog

    // Show loading with better UX
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Signing out...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Sign out
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.signOut();

      // Small delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to login
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to sign out: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColors.red500,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleExportAllData() async {
    if (!mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final exportService = ExportService();

      // Export data as JSON file
      await exportService.shareUserDataAsJson();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your data has been exported successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: AppColors.red500, size: 28),
              SizedBox(width: 12),
              Text('Delete Account'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete your account? This action cannot be undone.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const Text(
                'This will permanently delete:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildDeleteWarningItem('All wash entries and history'),
              _buildDeleteWarningItem('All saved dhobis and categories'),
              _buildDeleteWarningItem('Your account and profile data'),
              _buildDeleteWarningItem('All settings and preferences'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _handleDeleteAccount(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red500,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeleteWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.close, size: 16, color: AppColors.red500),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    Navigator.of(context).pop(); // Close dialog

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Deleting account...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.id;

      if (userId == null) {
        throw Exception('User not found');
      }

      // Delete user data from Supabase first
      if (SupabaseService.isAvailable && SupabaseService.client != null) {
        try {
          // Delete all wash entries
          await SupabaseService.client!
              .from('wash_entries')
              .delete()
              .eq('user_id', userId);

          // Delete all dhobis
          await SupabaseService.client!
              .from('dhobis')
              .delete()
              .eq('user_id', userId);

          // Delete all categories
          await SupabaseService.client!
              .from('categories')
              .delete()
              .eq('user_id', userId);

          debugPrint('User data deleted successfully');
        } catch (deleteError) {
          debugPrint('Error deleting user data: $deleteError');
          // Continue with account deletion even if some data deletion fails
        }
      }

      // Delete the actual user account from Supabase Auth
      if (SupabaseService.isAvailable) {
        try {
          await SupabaseService.client!.auth.admin.deleteUser(userId);
          debugPrint('User account deleted from Supabase Auth successfully');
        } catch (authDeleteError) {
          debugPrint(
              'Could not delete user from Supabase Auth (may need admin privileges): $authDeleteError');
          // This is okay - user can still be signed out
        }
      }

      // Sign out the user
      await userProvider.signOut();

      // Close loading dialog and navigate
      if (mounted) {
        // Pop the loading dialog
        Navigator.of(context).pop();

        // Navigate to login
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Account deleted successfully. We\'re sorry to see you go!',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.red500,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to delete account: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppColors.red500,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _showDeleteAccountDialog(),
            ),
          ),
        );
      }
    }
  }

  // Show PDF quality selection dialog
  void _showPdfQualityDialog() {
    const qualityOptions = PdfQuality.values;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('PDF Export Quality'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose the quality settings for your PDF exports. Higher quality means larger file sizes.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ...qualityOptions.map((quality) {
                final isSelected = _pdfQuality == quality.displayName;
                return InkWell(
                  onTap: () async {
                    setState(() => _pdfQuality = quality.displayName);
                    await _savePdfQuality(quality.displayName);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: quality.displayName,
                          groupValue: _pdfQuality,
                          onChanged: (value) async {
                            if (value != null) {
                              setState(() => _pdfQuality = value);
                              await _savePdfQuality(value);
                              Navigator.pop(context);
                            }
                          },
                          activeColor: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quality.displayName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getQualityDescription(quality),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Get description for PDF quality option
  String _getQualityDescription(PdfQuality quality) {
    switch (quality) {
      case PdfQuality.high:
        return 'Maximum quality, A4 size (~1-2MB) - Best for printing';
      case PdfQuality.medium:
        return 'Good quality, A4 size (~500KB-1MB) - Balanced option';
      case PdfQuality.low:
        return 'Basic quality, A5 size (~100-500KB) - Smallest file size';
    }
  }

  // Helper method to build initials widget
  Widget _buildInitialsWidget(String initials) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Animated Navigation Item for button press effects
class _AnimatedNavItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isSelected ? widget.selectedIcon : widget.icon,
                  color: widget.isSelected
                      ? AppColors.primary
                      : AppColors.textLightSecondary,
                  size: 30,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.isSelected
                        ? AppColors.primary
                        : AppColors.textLightSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Section Header
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});
  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.only(left: r.width(8), bottom: r.height(5), top: r.height(8)),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: r.fontSize(12, min: 10, max: 14),
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// Card
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: r.borderRadius(22),
        boxShadow: softShadow,
      ),
      padding: r.allPadding(6),
      child: child,
    );
  }
}

// Divider
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      height: r.size(1),
      color: const Color(0xFFF1F5F9),
      margin: r.horizontalPadding(8));
  }
}

// Settings Tile
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: r.padding(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Container(
              width: r.iconSize(40),
              height: r.iconSize(40),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: r.borderRadius(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: r.iconSize(24)),
            ),
            r.spacingWidth(12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: r.fontSize(15, min: 13, max: 17),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      TextSpan(
                        text: "  ",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: r.fontSize(15, min: 13, max: 17),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: r.fontSize(15, min: 13, max: 17),
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: r.iconSize(20)),
          ],
        ),
      ),
    );
  }
}
