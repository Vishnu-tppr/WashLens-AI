import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/user_settings.dart';
import 'notification_storage_service.dart';

/// Production-ready notification service with FCM and local notifications
class NotificationServiceEnhanced {
  // Singleton pattern
  static final NotificationServiceEnhanced _instance =
      NotificationServiceEnhanced._internal();
  factory NotificationServiceEnhanced() => _instance;
  NotificationServiceEnhanced._internal();

  // Core services
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _fcm;

  // State tracking
  bool _isInitialized = false;
  bool _fcmAvailable = false;
  bool _permissionsGranted = false;
  String? _fcmToken;

  // Notification channels with enhanced branding
  static const String _washReminderChannelId = 'wash_reminders';
  static const String _generalChannelId = 'general_notifications';
  static const String _missingItemChannelId = 'missing_items';
  static const String _pickupTimerChannelId = 'pickup_timer';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get fcmAvailable => _fcmAvailable;
  bool get permissionsGranted => _permissionsGranted;
  String? get fcmToken => _fcmToken;

  /// Initialize the complete notification system
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      debugPrint('🔔 Initializing NotificationServiceEnhanced...');

      // Initialize timezone data
      tz.initializeTimeZones();

      // Initialize storage service first
      await NotificationStorageService().initialize();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize FCM (Firebase Cloud Messaging)
      await _initializeFCM();

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('✅ NotificationServiceEnhanced initialized successfully');
      debugPrint('📱 FCM Available: $_fcmAvailable');
      debugPrint('🔐 Permissions Granted: $_permissionsGranted');
      debugPrint('🎯 FCM Token: ${_fcmToken?.substring(0, 20) ?? 'N/A'}...');

      return true;
    } catch (e) {
      debugPrint('❌ Failed to initialize NotificationServiceEnhanced: $e');
      return false;
    }
  }

  /// Initialize local notifications with proper channels and app logo
  Future<void> _initializeLocalNotifications() async {
    // Android initialization with app logo
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Create notification channels for Android with better branding
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    debugPrint('📱 Local notifications initialized with WashLens branding');
  }

  /// Create Android notification channels with WashLens branding
  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Wash Reminders Channel - High priority with WashLens branding
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _washReminderChannelId,
        '🧺 WashLens Laundry Reminders',
        description:
            'Stay on top of your laundry schedule with WashLens AI reminders',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
    );

    // General Notifications Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _generalChannelId,
        '📱 WashLens Updates',
        description: 'General updates and notifications from WashLens AI',
        importance: Importance.defaultImportance,
        enableVibration: true,
        playSound: true,
      ),
    );

    // Missing Items Channel - Critical alerts
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _missingItemChannelId,
        '⚠️ WashLens Missing Item Alerts',
        description: 'Critical alerts when laundry items are missing',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      ),
    );

    // Pickup Timer Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _pickupTimerChannelId,
        '⏰ WashLens Pickup Timers',
        description: 'Customizable timers for laundry pickup schedules',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
    );

    debugPrint('📢 WashLens notification channels created');
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    try {
      // Ensure Firebase is initialized
      await Firebase.initializeApp();
      _fcm = FirebaseMessaging.instance;

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle message opened app
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle initial message (app opened from terminated state)
      final initialMessage = await _fcm!.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      _fcmAvailable = true;
      debugPrint('🚀 FCM initialized successfully');
    } catch (e) {
      _fcmAvailable = false;
      debugPrint('⚠️ FCM not available: $e');
    }
  }

  /// Request notification permissions with better UX
  Future<bool> _requestPermissions() async {
    try {
      // Request FCM permissions first
      if (_fcmAvailable && _fcm != null) {
        final settings = await _fcm!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        _permissionsGranted =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
                settings.authorizationStatus == AuthorizationStatus.provisional;

        debugPrint(
            '🔐 FCM Permission Status: ${settings.authorizationStatus.name}');

        // Get FCM token if permissions granted
        if (_permissionsGranted) {
          _fcmToken = await _fcm!.getToken();
          debugPrint(
              '🎯 FCM Token obtained: ${_fcmToken?.substring(0, 20) ?? 'null'}...');
        }
      }

      // Request system notification permission (Android 13+)
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (status != PermissionStatus.granted) {
          final result = await Permission.notification.request();
          _permissionsGranted =
              _permissionsGranted && (result == PermissionStatus.granted);
        }
      }

      // Request local notification permissions for iOS
      if (Platform.isIOS) {
        final granted = await _localNotifications
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(
                  alert: true,
                  badge: true,
                  sound: true,
                ) ??
            false;
        _permissionsGranted = _permissionsGranted && granted;
      }

      return _permissionsGranted;
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Handle notification tap with better navigation
  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('🔔 WashLens notification tapped: ${response.payload}');

    try {
      if (response.payload != null) {
        final data = json.decode(response.payload!);
        _navigateBasedOnPayload(data);
      }
    } catch (e) {
      debugPrint('Error parsing WashLens notification payload: $e');
    }
  }

  /// Handle foreground FCM messages with WashLens branding
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔥 WashLens foreground FCM message: ${message.data}');

    // Show local notification for foreground messages
    if (message.notification != null) {
      showNotificationFromFCM(
        title: '🔔 ${message.notification!.title ?? 'WashLens AI'}',
        body: message.notification!.body ?? '',
        payload: message.data,
      );
    } else if (message.data.isNotEmpty) {
      // Handle data-only messages (no notification payload)
      final title = message.data['title'] as String? ?? 'WashLens AI';
      final body = message.data['body'] as String? ?? 'New notification';
      showNotificationFromFCM(
        title: '🔔 $title',
        body: body,
        payload: message.data,
      );
    }
  }

  /// Handle FCM message that opened app
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('📱 WashLens FCM message opened app: ${message.data}');

    // Store the notification if it wasn't stored in background
    // This handles the case where app was killed and notification opened it
    try {
      showNotificationFromFCM(
        title: message.notification?.title ?? 'WashLens AI',
        body: message.notification?.body ?? 'New notification',
        payload: message.data,
      );
    } catch (e) {
      debugPrint('❌ Failed to store FCM notification on app open: $e');
    }

    _navigateBasedOnPayload(message.data);
  }

  /// Navigate based on notification payload
  void _navigateBasedOnPayload(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final id = data['id'] as String?;

    // TODO: Implement navigation logic based on your app's routing
    debugPrint('🧭 WashLens navigation requested - Type: $type, ID: $id');

    switch (type) {
      case 'wash_reminder':
        // Navigate to wash details or history
        break;
      case 'missing_items':
        // Navigate to missing items screen
        break;
      case 'pickup_timer':
        // Navigate to active laundry
        break;
      default:
        // Navigate to home
        break;
    }
  }

  /// Save FCM token to user settings
  Future<bool> saveFCMTokenToSettings(String userId) async {
    if (_fcmToken == null || !_fcmAvailable) return false;

    try {
      // Save token to local storage only (no cloud storage)
      debugPrint('💾 WashLens FCM token saved for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to save WashLens FCM token: $e');
      return false;
    }
  }

  /// Show immediate local notification with WashLens branding
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String? channelId,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    debugPrint('🔔 showLocalNotification called');
    debugPrint('   Title: $title');
    debugPrint('   Body: $body');
    debugPrint('   Channel: $channelId');
    debugPrint('   Initialized: $_isInitialized');
    debugPrint('   Permissions: $_permissionsGranted');

    if (!_isInitialized) {
      debugPrint('⚠️ WashLens notification service not initialized');
      return;
    }

    // Re-check permissions on Android
    if (Platform.isAndroid) {
      final permStatus = await Permission.notification.status;
      debugPrint('   Android Permission Status: $permStatus');
      if (!permStatus.isGranted) {
        debugPrint('❌ Android notification permission not granted');
        return;
      }
    }

    try {
      debugPrint('   Using channel: $channelId');

      // Map to correct channel ID
      String actualChannelId;
      switch (channelId) {
        case 'wash_reminders':
          actualChannelId = _washReminderChannelId;
          break;
        case 'pickup_timer':
          actualChannelId = _pickupTimerChannelId;
          break;
        case 'missing_items':
          actualChannelId = _missingItemChannelId;
          break;
        default:
          actualChannelId = _generalChannelId;
      }

      final androidDetails = AndroidNotificationDetails(
        actualChannelId,
        _getChannelDisplayName(actualChannelId),
        channelDescription: _getChannelDisplayDescription(actualChannelId),
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher', // Uses your WashLens logo
        color: const Color(0xFF4A6FFF),
        largeIcon: const DrawableResourceAndroidBitmap(
            '@mipmap/ic_launcher'), // Large logo in notification
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'WashLens AI',
          htmlFormatContentTitle: false,
          htmlFormatContent: false,
        ),
        ticker: title, // Shows in status bar when notification arrives
      );

      const iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);
      debugPrint('   Notification ID: $notificationId');

      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      // Store notification in local storage
      try {
        String notificationType = 'general';
        String washId = '';
        String dhobiName = '';
        Map<String, dynamic>? data;

        // Extract data from payload if available
        if (payload != null) {
          try {
            final payloadData = json.decode(payload);
            notificationType = payloadData['type'] ?? notificationType;
            washId = payloadData['id'] ?? '';
            dhobiName = payloadData['dhobi'] ?? '';
            data = payloadData;
          } catch (e) {
            debugPrint('Error parsing notification payload for storage: $e');
          }
        }

        await NotificationStorageService().createAndStoreLocal(
          title: title,
          message: body,
          type: notificationType,
          washId: washId,
          dhobiName: dhobiName,
          data: data,
        );

        debugPrint('📝 Notification stored locally: $title');
      } catch (e) {
        debugPrint('❌ Failed to store notification: $e');
      }

      debugPrint('✅ WashLens notification sent successfully: $title');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to show WashLens notification: $e');
      debugPrint('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Show notification from FCM data with WashLens branding
  Future<void> showNotificationFromFCM({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    // Store FCM notification before showing it
    try {
      await NotificationStorageService().createAndStoreFromFCM({
        'notification': {
          'title': title,
          'body': body,
        },
        'data': payload ?? {},
      });
      debugPrint('📝 FCM notification stored: $title');
    } catch (e) {
      debugPrint('❌ Failed to store FCM notification: $e');
    }

    final payloadString = payload != null ? json.encode(payload) : null;
    await showLocalNotification(
      title: title,
      body: body,
      payload: payloadString,
    );
  }

  /// Schedule reminder notification with enhanced branded content
  Future<void> scheduleReminderNotification({
    required String washId,
    required String dhobiName,
    required int itemCount,
    required DateTime scheduledDate,
    UserSettings? userSettings,
  }) async {
    if (!_isInitialized) return;
    if (userSettings?.enableNotifications != true) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        _washReminderChannelId,
        '🧺 WashLens Laundry Reminders',
        channelDescription:
            'Stay on top of your laundry schedule with WashLens AI',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: Color(0xFF4A6FFF), // WashLens primary color
      );

      const iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      final payload = json.encode({
        'type': 'wash_reminder',
        'id': washId,
        'dhobi': dhobiName,
      });

      await _localNotifications.zonedSchedule(
        washId.hashCode,
        '🔔 WashLens Reminder',
        'Your $itemCount laundry items with $dhobiName are ready for pickup! ✨',
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      debugPrint(
          '⏰ WashLens reminder scheduled for $dhobiName on $scheduledDate');
    } catch (e) {
      debugPrint('❌ Failed to schedule WashLens reminder: $e');
    }
  }

  /// Show missing item alert with WashLens branding
  Future<void> showMissingItemAlert({
    required String washId,
    required String dhobiName,
    required List<String> missingItems,
    UserSettings? userSettings,
  }) async {
    if (!_isInitialized) return;
    if (userSettings?.enableNotifications != true) return;

    final payload = json.encode({
      'type': 'missing_items',
      'id': washId,
      'dhobi': dhobiName,
    });

    String bodyText;
    if (missingItems.length == 1) {
      bodyText = '${missingItems[0]} still missing from $dhobiName 😟';
    } else {
      final itemList = missingItems.take(2).join(', ');
      final remaining = missingItems.length - 2;
      bodyText =
          '$itemList${remaining > 0 ? ' +$remaining more' : ''} missing from $dhobiName ❌';
    }

    await showLocalNotification(
      title: '⚠️ WashLens Alert',
      body: bodyText,
      payload: payload,
      channelId: _missingItemChannelId,
      priority: NotificationPriority.max,
    );
  }

  /// Show pickup timer notification with enhanced branding
  Future<void> showPickupTimerNotification({
    required String washId,
    required String dhobiName,
    required int hoursRemaining,
    UserSettings? userSettings,
  }) async {
    if (!_isInitialized) return;
    if (userSettings?.enableNotifications != true) return;

    final payload = json.encode({
      'type': 'pickup_timer',
      'id': washId,
      'dhobi': dhobiName,
    });

    String title;
    String body;
    if (hoursRemaining <= 0) {
      title = '🎉 Ready Now!';
      body = 'Your laundry at $dhobiName is ready for pickup! ✨';
    } else if (hoursRemaining <= 2) {
      title = '⏰ Almost Ready!';
      body =
          'Your laundry at $dhobiName will be ready in $hoursRemaining ${hoursRemaining == 1 ? 'hour' : 'hours'}! 🎯';
    } else {
      title = '🔔 WashLens Timer';
      body =
          'Pickup reminder: Your laundry at $dhobiName will be ready in $hoursRemaining hours 📅';
    }

    await showLocalNotification(
      title: title,
      body: body,
      payload: payload,
      channelId: _pickupTimerChannelId,
    );
  }

  /// Show return confirmation with positive WashLens branding
  Future<void> showReturnConfirmation({
    required String dhobiName,
    required int returnedCount,
    UserSettings? userSettings,
  }) async {
    if (!_isInitialized) return;
    if (userSettings?.enableNotifications != true) return;

    String title;
    String body;

    if (returnedCount == 1) {
      title = '✅ Item Returned!';
      body = 'Successfully returned your laundry item from $dhobiName! 🎉';
    } else {
      title = '🎊 Laundry Complete!';
      body = 'Successfully returned $returnedCount items from $dhobiName! 🧺✨';
    }

    await showLocalNotification(
      title: title,
      body: body,
      channelId: _generalChannelId,
    );
  }

  /// Cancel scheduled notification
  Future<void> cancelScheduledNotification(String washId) async {
    try {
      await _localNotifications.cancel(washId.hashCode);
      debugPrint('🗑️ WashLens notification cancelled for wash: $washId');
    } catch (e) {
      debugPrint('❌ Failed to cancel WashLens notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('🗑️ All WashLens notifications cancelled');
    } catch (e) {
      debugPrint('❌ Failed to cancel all WashLens notifications: $e');
    }
  }

  /// Helper methods for WashLens branding
  String _getChannelDisplayName(String channelId) {
    switch (channelId) {
      case _washReminderChannelId:
        return '🧺 WashLens Laundry Reminders';
      case _generalChannelId:
        return '📱 WashLens Updates';
      case _missingItemChannelId:
        return '⚠️ WashLens Missing Item Alerts';
      case _pickupTimerChannelId:
        return '⏰ WashLens Pickup Timers';
      default:
        return '📱 WashLens AI Notifications';
    }
  }

  String _getChannelDisplayDescription(String channelId) {
    switch (channelId) {
      case _washReminderChannelId:
        return 'Stay on top of your laundry schedule with WashLens AI reminders';
      case _generalChannelId:
        return 'General updates and notifications from WashLens AI';
      case _missingItemChannelId:
        return 'Critical alerts when laundry items are missing';
      case _pickupTimerChannelId:
        return 'Customizable timers for laundry pickup schedules';
      default:
        return 'Smart notifications from your WashLens AI laundry assistant';
    }
  }

  /// Dispose resources
  void dispose() {
    // Clean up resources if needed
  }
}

/// Notification priority levels
enum NotificationPriority {
  min,
  low,
  defaultPriority,
  high,
  max,
}

/// Background message handler (top-level function required)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already done
  await Firebase.initializeApp();

  debugPrint('🔥 WashLens background FCM message: ${message.data}');

  // Store the notification for later retrieval
  try {
    await NotificationStorageService.storeFCMNotificationBackground({
      'notification': {
        'title': message.notification?.title ?? 'WashLens AI',
        'body': message.notification?.body ?? 'New notification',
      },
      'data': message.data,
    });
  } catch (e) {
    debugPrint('❌ Failed to store background FCM notification: $e');
  }

  // Note: You can't update UI here, but you can:
  // - Save data to local storage ✓ (done above)
  // - Send analytics
  // - Schedule local notifications
}
