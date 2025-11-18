import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Simple notification service for local notifications only
class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService();

  /// Initialize notification service (local only)
  Future<void> initialize() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Initialize local notifications
      const initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      print('Local notifications initialized successfully');
    } catch (e) {
      print('Error initializing notifications: $e');
      // Don't throw - app can work without notifications
    }
  }

  /// Show simple notification
  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'washlens_general',
        'General Notifications',
        channelDescription: 'General app notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  /// Schedule wash reminder
  Future<void> scheduleWashReminder({
    required String washId,
    required String dhobiName,
    required int itemCount,
    required DateTime scheduledDate,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'washlens_reminders',
        'Laundry Reminders',
        channelDescription: 'Reminders for pending laundry returns',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        washId.hashCode,
        '⚠️ Laundry Reminder',
        'You gave $itemCount items to $dhobiName. Did you collect them?',
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: washId,
      );
    } catch (e) {
      print('Error scheduling reminder: $e');
    }
  }

  /// Show missing item alert
  Future<void> showMissingItemAlert({
    required String dhobiName,
    required int missingCount,
    required String washId,
  }) async {
    await _showNotification(
      title: '❌ Missing Items',
      body: '$missingCount items are missing from $dhobiName!',
      payload: washId,
    );
  }

  /// Show return confirmation
  Future<void> showReturnConfirmation({
    required String dhobiName,
    required int returnedCount,
  }) async {
    await _showNotification(
      title: '✅ Laundry Returned',
      body: 'All $returnedCount items returned from $dhobiName!',
    );
  }

  /// Cancel scheduled notification
  Future<void> cancelScheduledNotification(String washId) async {
    try {
      await _localNotifications.cancel(washId.hashCode);
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Navigate to specific screen based on payload
  }

  /// Request notification permissions
  Future<void> requestPermissions() async {
    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  /// Get FCM token (placeholder - returns null since no Firebase)
  Future<String?> getFCMToken() async {
    return null;
  }
}