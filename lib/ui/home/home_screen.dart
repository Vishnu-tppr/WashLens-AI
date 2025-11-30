import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service_enhanced.dart';
import '../../models/wash_entry.dart';
import '../../models/app_user.dart' as models;
import '../theme/responsive_utils.dart';

// Tailwind-style design tokens
class AppColors {
  static const primary = Color(0xFF4A6FFF);
  static const secondary = Color(0xFFA3B4FF);
  static const accent = Color(0xFF6EE7B7);
  static const backgroundLight = Color(0xFFF8FAFC);
  static const textLightPrimary = Color(0xFF0F172A);
  static const textLightSecondary = Color(0xFF475569);
  static const cardLight = Color(0xFFFFFFFF);
  static const red500 = Color(0xFFEF4444);
  static const yellow500 = Color(0xFFF59E0B);
}

List<BoxShadow> softShadow(bool dark) => dark
    ? [
        const BoxShadow(
            color: Color(0x33000000),
            blurRadius: 28,
            spreadRadius: -5,
            offset: Offset(0, 10)),
        const BoxShadow(
            color: Color(0x40000000),
            blurRadius: 16,
            spreadRadius: -6,
            offset: Offset(0, 4)),
      ]
    : [
        const BoxShadow(
            color: Color(0x1A4A6FFF),
            blurRadius: 28,
            spreadRadius: -5,
            offset: Offset(0, 10)),
        const BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            spreadRadius: -6,
            offset: Offset(0, 4)),
      ];

/// Beautiful Home Screen with Frost Effect Navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WashEntry? _nextWash;
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;
  final NotificationServiceEnhanced _notificationService =
      NotificationServiceEnhanced();

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
    _loadNextWash();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNextWash() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser != null) {
      final entries =
          await SupabaseService.getWashEntries(userProvider.currentUser!.id);
      // Find the next pending wash (earliest givenAt that hasn't returned)
      final pendingWashes = entries
          .map((e) => WashEntry.fromJson(e))
          .where((wash) =>
              wash.status != WashStatus.returned &&
              wash.status != WashStatus.completed)
          .toList();

      if (pendingWashes.isNotEmpty) {
        // Sort by givenAt ascending (earliest first)
        pendingWashes.sort((a, b) => a.givenAt.compareTo(b.givenAt));
        setState(() {
          _nextWash = pendingWashes.first;
        });
        _startCountdown();
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();

    if (_nextWash != null) {
      _updateRemainingTime();
      _schedulePickupReminder();
      _countdownTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
        if (mounted) {
          setState(() {
            _updateRemainingTime();
          });
        }
      });
    }
  }

  Future<void> _schedulePickupReminder() async {
    if (_nextWash == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final pickupHours = userProvider.userSettings?.pickupReminderHours ?? 24;
    final pickupDeadline = _nextWash!.givenAt.add(Duration(hours: pickupHours));

    // Only schedule if deadline is in the future and wash status is not completed
    if (pickupDeadline.isAfter(DateTime.now()) &&
        (_nextWash!.status != WashStatus.completed &&
            _nextWash!.status != WashStatus.returned)) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await _notificationService.scheduleReminderNotification(
        washId: _nextWash!.id,
        dhobiName: _nextWash!.dhobiName,
        itemCount:
            _nextWash!.givenCounts.values.fold(0, (sum, count) => sum + count),
        scheduledDate: pickupDeadline,
        userSettings: userProvider.userSettings!,
      );
    }
  }

  void _updateRemainingTime() {
    if (_nextWash == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final pickupHours = userProvider.userSettings?.pickupReminderHours ?? 24;
    final pickupDeadline = _nextWash!.givenAt.add(Duration(hours: pickupHours));
    final now = DateTime.now();

    if (pickupDeadline.isAfter(now)) {
      _remainingTime = pickupDeadline.difference(now);
    } else {
      _remainingTime = Duration.zero;
    }
  }

  String _formatTimeUnit(int value) {
    return value.toString().padLeft(2, '0');
  }

  int get _days => _remainingTime.inDays;
  int get _hours => _remainingTime.inHours % 24;
  int get _minutes => _remainingTime.inMinutes % 60;

  late bool _hasUnreadNotifications = false; // TODO: Implement real notification checking

  String get _dueText {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final pickupHours = userProvider.userSettings?.pickupReminderHours ?? 24;

    if (_nextWash != null) {
      final deadline = _nextWash!.givenAt.add(Duration(hours: pickupHours));
      final now = DateTime.now();
      final hoursLeft = deadline.difference(now).inHours;

      if (hoursLeft > 24) {
        final daysLeft = deadline.difference(now).inDays;
        if (daysLeft == 1) return 'Return Due Tomorrow';
        return 'Return Due in $daysLeft days';
      } else if (hoursLeft > 0) {
        if (hoursLeft == 1) return 'Return Due in 1 hour';
        return 'Return Due in $hoursLeft hours';
      }
    }
    return 'Return Overdue';
  }

  @override
  Widget build(BuildContext context) {
    // --- Global font override ---
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final r = context.responsive;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: r.padding(horizontal: 24, vertical: 24),
          child: ListView(
            padding: EdgeInsets.only(bottom: r.height(120)),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const _Avatar(),
                      r.spacingWidth(12),
                      Consumer<UserProvider>(
                        builder: (context, userProvider, _) {
                          final userName = userProvider.userName;
                          return Text(
                            'Hi, $userName 👋',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: r.fontSize(24, min: 18, max: 28),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textLightPrimary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  // Notification icon
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                              context, '/notifications');
                          if (result == true && mounted) {
                            setState(() {
                              _hasUnreadNotifications = false;
                            });
                          }
                        },
                        icon: Icon(
                          Icons.notifications_outlined,
                          size: r.iconSize(30),
                          color: AppColors.textLightSecondary,
                        ),
                      ),
                      if (_hasUnreadNotifications)
                        Positioned(
                          top: r.size(8),
                          right: r.size(8),
                          child: Container(
                            width: r.size(11),
                            height: r.size(11),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 250, 2, 2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.cardLight,
                                width: r.size(2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              r.spacingHeight(24),

              // Next Return card
              _Card(
                dark: dark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Next Return',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: r.fontSize(16, min: 14, max: 18),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLightSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.error_outline,
                                size: r.iconSize(16), color: AppColors.red500),
                            r.spacingWidth(6),
                            Text(
                              '1 item missing!',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: r.fontSize(16, min: 14, max: 18),
                                fontWeight: FontWeight.w700,
                                color: AppColors.red500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    r.spacingHeight(8),
                    Text(
                      _dueText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: r.fontSize(20, min: 18, max: 24),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLightPrimary,
                      ),
                    ),
                    r.spacingHeight(20),

                    // Countdown timer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _TimeBlock(
                            value: _formatTimeUnit(_days), label: 'Days'),
                        const _TimeColon(),
                        _TimeBlock(
                            value: _formatTimeUnit(_hours), label: 'Hours'),
                        const _TimeColon(),
                        _TimeBlock(
                            value: _formatTimeUnit(_minutes), label: 'Minutes'),
                      ],
                    ),
                    r.spacingHeight(24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _PillButton(
                            label: 'Remainder',
                            background: AppColors.secondary
                                .withOpacity(dark ? 0.10 : 0.20),
                            foreground:
                                dark ? AppColors.secondary : AppColors.primary,
                            onTap: () =>
                                Navigator.pushNamed(context, '/notification-settings'),
                          ),
                        ),
                        r.spacingWidth(12),
                        Expanded(
                          child: _PillButton(
                            label: 'Mark Returned',
                            background: AppColors.primary,
                            foreground: Colors.white,
                            onTap: () =>
                                Navigator.pushNamed(context, '/mark_returned'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              r.spacingHeight(16),

              // GRID
              Column(
                children: [
                  // New Wash — full width, responsive height
                  SizedBox(
                    height: r.height(140), // Responsive height
                    width: double.infinity,
                    child: _Pressable(
                      onTap: () =>
                          Navigator.pushNamed(context, '/scan'), // navigation
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: r.borderRadius(28),
                          boxShadow: softShadow(dark),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                size: r.iconSize(32), color: Colors.white),
                            r.spacingHeight(8),
                            Text(
                              "New Wash",
                              style: TextStyle(
                                fontSize: r.fontSize(18, min: 16, max: 20),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  r.spacingHeight(16),
                  // Two half tiles
                  Row(
                    children: [
                      Expanded(
                        child: _SmallInfoTile(
                          iconBg: dark
                              ? const Color(0x1A6EE7B7)
                              : const Color(0x336EE7B7),
                          iconColor: AppColors.accent,
                          icon: Icons.history,
                          title: 'Recent Activity',
                          subtitle: 'Anil Dhobi - 32 items',
                          onTap: () => Navigator.pushNamed(context, '/history'),
                        ),
                      ),
                      r.spacingWidth(16),
                      Expanded(
                        child: _SmallInfoTile(
                          iconBg: dark
                              ? const Color(0x1AFACC15)
                              : const Color(0x33F59E0B),
                          iconColor: AppColors.yellow500,
                          icon: Icons.auto_awesome,
                          title: 'Quick Add',
                          subtitle: 'Manual mode',
                          onTap: () => Navigator.pushNamed(context, '/quick-add'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      // Bottom navigation bar with "frost"/blur effect
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardLight.withOpacity(0.8),
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFE5E7EB),
                  width: r.size(1),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: r.size(8),
                  offset: Offset(0, r.size(-2)),
                ),
              ],
            ),
            height: r.height(80),
            child: SafeArea(
              child: Padding(
                padding: r.horizontalPadding(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTabItem(
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home,
                        label: 'Home',
                        index: 0,
                        isSelected: true),
                    _buildTabItem(
                        icon: Icons.add_a_photo_outlined,
                        selectedIcon: Icons.add_a_photo,
                        label: 'New Wash',
                        index: 1,
                        isSelected: false),
                    _buildTabItem(
                        icon: Icons.history_outlined,
                        selectedIcon: Icons.history,
                        label: 'History',
                        index: 2,
                        isSelected: false),
                    _buildTabItem(
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings,
                        label: 'Settings',
                        index: 3,
                        isSelected: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final r = context.responsive;
    return Expanded(
      child: InkWell(
        onTap: () {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.pushNamed(context, '/scan');
              break;
            case 2:
              Navigator.pushNamed(context, '/history');
              break;
            case 3:
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color:
                  isSelected ? AppColors.primary : AppColors.textLightSecondary,
              size: r.iconSize(30),
            ),
            r.spacingHeight(4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: r.fontSize(12, min: 10, max: 14),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textLightSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Avatar widget
class _Avatar extends StatelessWidget {
  const _Avatar();
  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final userName = userProvider.userName;
        final firstInitial =
            userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

        // Check if user has a profile photo (supports both Supabase and Firebase)
        final currentAuthUser = userProvider.currentUser;
        String? avatarUrl;

        if (currentAuthUser != null) {
          if (currentAuthUser is models.SupabaseAuthUser) {
            // Supabase user - check for avatar_url in user metadata
            final userMetadata = currentAuthUser.user.userMetadata;
            if (userMetadata != null && userMetadata.containsKey('avatar_url')) {
              avatarUrl = userMetadata['avatar_url'] as String?;
            }
          } else if (currentAuthUser is models.FirebaseAuthUser) {
            // Firebase user - get photoURL from Google Sign-In
            avatarUrl = currentAuthUser.photoURL;
          }
        }

        // If we have an avatar URL, show the image; otherwise show letter avatar
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          return CircleAvatar(
            key: ValueKey(avatarUrl), // Force rebuild when URL changes
            radius: r.avatarSize(24),
            backgroundColor: AppColors.primary,
            backgroundImage: avatarUrl.startsWith('http')
                ? NetworkImage(avatarUrl) as ImageProvider
                : FileImage(File(avatarUrl)),
            onBackgroundImageError: (_, __) {
              // Fallback to letter avatar if image fails to load
            },
            child: avatarUrl.isEmpty
                ? Text(
                    firstInitial,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: r.fontSize(14, min: 12, max: 16),
                        color: Colors.white, fontWeight: FontWeight.w700),
                  )
                : null,
          );
        } else {
          return CircleAvatar(
            radius: r.avatarSize(24),
            backgroundColor: AppColors.primary,
            child: Text(
              firstInitial,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: r.fontSize(14, min: 12, max: 16),
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          );
        }
      },
    );
  }
}

// Card widget w/ scaling
class _Card extends StatelessWidget {
  final Widget child;
  final bool dark;
  const _Card({required this.child, required this.dark});
  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return _Pressable(
      scale: 1.02,
      child: Container(
        padding: r.allPadding(24),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: r.borderRadius(28),
          boxShadow: softShadow(dark),
        ),
        child: child,
      ),
    );
  }
}

// Timer number+label
class _TimeBlock extends StatelessWidget {
  final String value;
  final String label;
  const _TimeBlock({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: r.fontSize(32, min: 24, max: 40),
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.1,
            )),
        r.spacingHeight(4),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: r.fontSize(12, min: 10, max: 14),
                fontWeight: FontWeight.w500,
                color: AppColors.textLightSecondary)),
      ],
    );
  }
}

// Timer colon
class _TimeColon extends StatelessWidget {
  const _TimeColon();
  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.only(bottom: r.height(12)),
      child: Text(
        ':',
        style: GoogleFonts.plusJakartaSans(
          fontSize: r.fontSize(32, min: 24, max: 40),
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          height: 1.1,
        ),
      ),
    );
  }
}

// Rounded pill button
class _PillButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  const _PillButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Material(
      color: background,
      borderRadius: r.borderRadius(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: r.borderRadius(24),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: r.height(14)),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: r.fontSize(16, min: 14, max: 18),
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

// Small info tile
class _SmallInfoTile extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _SmallInfoTile({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return _Pressable(
      onTap: onTap,
      child: Container(
        height: r.size(150), // Fixed height to equalize sizes
        padding: r.allPadding(20),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: r.borderRadius(28),
          boxShadow: softShadow(false),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: r.size(48),
              height: r.size(48),
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: r.borderRadius(14)),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: r.iconSize(28)),
            ),
            r.spacingHeight(14),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: r.fontSize(16, min: 14, max: 18),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLightPrimary),
            ),
            r.spacingHeight(2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: r.fontSize(12, min: 10, max: 14),
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLightSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// Tap-scale effect (for Pressable cards)
class _Pressable extends StatefulWidget {
  final Widget child;
  final double scale;
  final VoidCallback? onTap;
  const _Pressable({required this.child, this.onTap, this.scale = 1.03});
  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable>
    with SingleTickerProviderStateMixin {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: _down ? widget.scale : 1.0,
        child: widget.child,
      ),
    );
  }
}
