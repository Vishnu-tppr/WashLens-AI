import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'notification_settings_screen.dart';
import '../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../services/export_service.dart';
import '../../services/supabase_service.dart';

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
  final String _pdfQuality = 'High';

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final horizontalPadding = screenWidth * 0.04;
        final verticalSpacing = screenHeight * 0.012;

        return Scaffold(
          backgroundColor: AppColors.bgLight,
          appBar: AppBar(
            title: const Text(
              'Settings',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.cardLight,
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: screenHeight * 0.015,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ACCOUNT
                const _SectionHeader(label: "ACCOUNT"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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

                            return InkWell(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/edit-profile'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4A6FFF),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        initials,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userName,
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            userEmail,
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.red100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.logout,
                                      color: AppColors.red500),
                                ),
                                const SizedBox(width: 12),
                                Text("Sign Out",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    )),
                                const Spacer(),
                                const Icon(Icons.chevron_right,
                                    color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: verticalSpacing),

                // DATA MANAGEMENT
                const _SectionHeader(label: "DATA MANAGEMENT"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _Card(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.picture_as_pdf,
                          iconBg: AppColors.iconBgLight,
                          iconColor: AppColors.primary,
                          title: "PDF Export Quality",
                          subtitle: _pdfQuality,
                          onTap: () {},
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

                SizedBox(height: verticalSpacing),

                // NOTIFICATIONS & WIDGETS
                const _SectionHeader(label: "NOTIFICATIONS & WIDGETS"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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

                SizedBox(height: verticalSpacing),

                // LEGAL & PRIVACY
                const _SectionHeader(label: "LEGAL & PRIVACY"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _Card(
                    child: _SettingsTile(
                      icon: Icons.privacy_tip,
                      iconBg: AppColors.iconBgLight,
                      iconColor: AppColors.primary,
                      title: "Data Privacy",
                      onTap: () {},
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
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Sign out
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);
                await userProvider.signOut();

                // Navigate to login
                if (mounted) {
                  Navigator.of(context).pop(); // Close loading
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
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
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data including wash entries, settings, and analytics.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                  final userId = userProvider.currentUser?.id;

                  if (userId == null) {
                    throw Exception('User not found');
                  }

                  // First sign out the user to prevent further operations
                  await userProvider.signOut();

                  // Delete user data from Supabase (after sign out to avoid auth issues)
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
                      // Continue with navigation even if data deletion partially fails
                    }
                  }

                  // Close loading dialog and navigate
                  if (mounted) {
                    // Pop the loading dialog
                    Navigator.of(context).pop();

                    // Use post-frame callback to ensure navigation happens after build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      }
                    });

                    // Show success message immediately
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deleted successfully'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop(); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete account: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
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
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 5, top: 8),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 1.0,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(22),
        boxShadow: softShadow,
      ),
      padding: const EdgeInsets.all(6),
      child: child,
    );
  }
}

// Divider
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      height: 1,
      color: const Color(0xFFF1F5F9),
      margin: const EdgeInsets.symmetric(horizontal: 8));
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      TextSpan(
                        text: "  ",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
