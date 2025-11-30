import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/notification_storage_service.dart';
import '../../models/notification_item.dart';
import '../theme/responsive_utils.dart';

// Tailwind-style tokens
class AppColors {
  static const primary = Color(0xFF4A6FFF);
  static const secondary = Color(0xFFA3B4FF);
  static const accent = Color(0xFF6EE7B7);
  static const cardLight = Color(0xFFFFFFFF);
  static const bgLight = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const red500 = Color(0xFFEF4444);
  static const yellow500 = Color(0xFFF59E0B);
  static const blue500 = Color(0xFF4A6FFF);
}

List<BoxShadow> softShadow = [
  const BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 20,
    spreadRadius: -4,
    offset: Offset(0, 8),
  ),
  const BoxShadow(
    color: Color(0x08000000),
    blurRadius: 12,
    spreadRadius: -5,
    offset: Offset(0, 4),
  ),
];



// Real notification system will be populated from local storage and FCM messages
// This list will be replaced with actual notifications

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<NotificationItem> _notifications;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final storedNotifications = await NotificationStorageService().getAllNotifications();
      setState(() {
        _notifications = storedNotifications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      await NotificationStorageService().clearAllNotifications();
      await _loadNotifications();

      // Show success message
      if (mounted) {
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
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    try {
      await NotificationStorageService().markAsRead(notification.id);
      await _loadNotifications();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Add refresh capability
  Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: r.fontSize(20, min: 18, max: 22),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.cardLight,
        actions: [
          TextButton(
            onPressed: _notifications.isNotEmpty
                ? _clearAllNotifications
                : null,
            child: Text(
              "Clear All",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _notifications.isNotEmpty
                    ? AppColors.primary
                    : AppColors.textSecondary.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: r.padding(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _notifications.isEmpty
                  ? const _EmptyNotificationsView()
                  : ListView.separated(
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, i) =>
                          _NotificationCard(item: _notifications[i]),
                    ),
            ),
          ],
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
    final iconData = _getIconFromString(item.getIconData());
    final iconColor = Color(item.getIconColor());
    final bgColor = iconColor.withOpacity(0.1);

    return InkWell(
      onTap: item.isRead
          ? null
          : () => _markAsRead(context, item),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: !item.isRead
              ? const Color(0xFFF1F5F9)
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
                child: !item.isRead
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
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 28),
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
                    item.getFormattedTime(),
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
      ),
    );
  }

  void _markAsRead(BuildContext context, NotificationItem notification) {
    final state = context.findAncestorStateOfType<_NotificationsScreenState>();
    state?._markAsRead(notification);
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'notifications':
        return Icons.notifications;
      case 'search':
        return Icons.search;
      case 'schedule':
        return Icons.schedule;
      case 'check_circle':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }
}
