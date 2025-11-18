import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Tailwind-style tokens
class AppColors {
  static const primary = Color(0xFF4A6FFF);
  static const secondary = Color(0xFFA3B4FF);
  static const accent = Color(0xFF6EE7B7);
  static const cardLight = Color(0xFFFFFFFF);
  static const bgLight = Color(0xFFF8FAFC);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const red500 = Color(0xFFEF4444);
  static const yellow500 = Color(0xFFF59E0B);
  static const blue500 = Color(0xFF4A6FFF);
}

List<BoxShadow> softShadow = [
  const BoxShadow(
    color: Color(0x144A6FFF),
    blurRadius: 20,
    spreadRadius: -4,
    offset: Offset(0, 8),
  ),
  const BoxShadow(
    color: Color(0x10000000),
    blurRadius: 12,
    spreadRadius: -5,
    offset: Offset(0, 4),
  ),
];

class NotificationItem {
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final Color fillColor;
  final Color iconColor;
  final bool highlightDot;

  NotificationItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    required this.fillColor,
    required this.iconColor,
    this.highlightDot = false,
  });
}

// Demo list - realistic laundry notifications
final demoNotifications = [
  NotificationItem(
    icon: Icons.done_all_rounded,
    title: "Laundry Ready for Pickup",
    message: "Your wash containing 12 items is now ready at Anil Dhobi.",
    time: "Just now",
    fillColor: AppColors.accent.withOpacity(0.2),
    iconColor: AppColors.accent,
    highlightDot: true,
  ),
  NotificationItem(
    icon: Icons.inventory_2_rounded,
    title: "Wash Report Generated",
    message: "Monthly wash summary for November sent to your email.",
    time: "2 hours ago",
    fillColor: AppColors.blue500.withOpacity(0.2),
    iconColor: AppColors.blue500,
    highlightDot: true,
  ),
  NotificationItem(
    icon: Icons.error_outline_rounded,
    title: "Failed to fetch items",
    message: "Could not sync with the cloud. Please try again.",
    time: "Yesterday",
    fillColor: AppColors.red500.withOpacity(0.2),
    iconColor: AppColors.red500,
    highlightDot: false,
  ),
  NotificationItem(
    icon: Icons.notifications_rounded,
    title: "Reminder: Laundry returned",
    message: "Don't forget to mark your items as returned.",
    time: "Yesterday",
    fillColor: AppColors.yellow500.withOpacity(0.2),
    iconColor: AppColors.yellow500,
    highlightDot: false,
  ),
  NotificationItem(
    icon: Icons.task_alt_rounded,
    title: "Process completed",
    message: "Your laundry wash #1023 is complete.",
    time: "2 days ago",
    fillColor: AppColors.accent.withOpacity(0.2),
    iconColor: AppColors.accent,
    highlightDot: false,
  ),
];

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = List.from(demoNotifications);
  }

  void _clearAllNotifications() {
    setState(() {
      _notifications.clear();
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'All notifications cleared',
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );

    // Pass result back to home screen
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Notifications",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28, // text-2xl
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: _notifications.isNotEmpty ? _clearAllNotifications : null,
                    child: Text(
                      "Clear All",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _notifications.isNotEmpty ? AppColors.primary : AppColors.textSecondary.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _notifications.isEmpty
                    ? const _EmptyNotificationsView()
                    : ListView.separated(
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (_, i) => _NotificationCard(item: _notifications[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotificationsView extends StatelessWidget {
  const _EmptyNotificationsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see updates about your laundry here',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: item.highlightDot
            ? AppColors.primary.withOpacity(0.05)
            : AppColors.cardLight,
        borderRadius: BorderRadius.circular(22), // rounded-xl
        boxShadow: softShadow,
      ),
      padding: const EdgeInsets.all(16), // p-4
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leading blue dot for unread
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: SizedBox(
              width: 10,
              child: item.highlightDot
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    )
                  : const SizedBox(width: 10),
            ),
          ),
          const SizedBox(width: 12),
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.fillColor,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  item.message,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.time,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
