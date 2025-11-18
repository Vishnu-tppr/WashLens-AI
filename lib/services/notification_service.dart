import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Notification service for local and push notifications
class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _fcm;
  bool _fcmAvailable = false;

  NotificationService(); // Empty constructor

  /// Initialize notification service
  Future<void> initialize() async {
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

    // Try to initialize FCM (optional) - only if Firebase is available
    try {
      // Check if Firebase app is initialized first
      Firebase.app();
      _fcm = FirebaseMessaging.instance;
      await _requestFCMPermission();
      _fcmAvailable = true;

      // Handle FCM messages
      FirebaseMessaging.onMessage.listen(_handleFCMMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleFCMMessageOpenedApp);

      print('FCM initialized successfully');
    } catch (e) {
      print('FCM not available, using local notifications only: $e');
      _fcmAvailable = false;
      _fcm = null;
    }
  }

  /// Request FCM permissions
  Future<void> _requestFCMPermission() async {
    if (_fcm == null) return;

    final settings = await _fcm!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    if (_fcm == null || !_fcmAvailable) return null;
    return await _fcm!.getToken();
  }

  /// Handle FCM message
  void _handleFCMMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      _showNotification(
        title: message.notification!.title ?? 'WashLens AI',
        body: message.notification!.body ?? '',
        payload: message.data['washId'],
      );
    }
  }

  /// Handle FCM message opened app
  void _handleFCMMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.data}');
    // Navigate to specific screen based on payload
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Navigate to specific screen based on payload
  }

  /// Show immediate notification
  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'washlens_channel',
      'WashLens Notifications',
      channelDescription: 'Notifications for laundry tracking',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Schedule reminder notification
  Future<void> scheduleReminder({
    required String washId,
    required String dhobiName,
    required int itemCount,
    required DateTime scheduledDate,
  }) async {
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
  Future<void> cancelNotification(int notificationId) async {
    await _localNotifications.cancel(notificationId);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
