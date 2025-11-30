import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';

/// Service for storing and managing notifications locally
class NotificationStorageService {
  static const String _storageKey = 'washlens_notifications';
  static const int _maxNotifications = 100; // Keep only latest 100 notifications

  // Singleton pattern
  static final NotificationStorageService _instance = NotificationStorageService._internal();
  factory NotificationStorageService() => _instance;
  NotificationStorageService._internal();

  SharedPreferences? _prefs;

  /// Initialize the storage service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get all notifications
  Future<List<NotificationItem>> getAllNotifications() async {
    if (_prefs == null) await initialize();

    final storedData = _prefs!.getString(_storageKey);
    if (storedData == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(storedData);
      final notifications = jsonList
          .map((json) => NotificationItem.fromJson(json))
          .toList();

      // Sort by created date (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    } catch (e) {
      print('Error loading notifications: $e');
      return [];
    }
  }

  /// Get unread notifications
  Future<List<NotificationItem>> getUnreadNotifications() async {
    final all = await getAllNotifications();
    return all.where((notification) => !notification.isRead).toList();
  }

  /// Get notification by ID
  Future<NotificationItem?> getNotificationById(String id) async {
    final notifications = await getAllNotifications();
    for (final n in notifications) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// Add a new notification
  Future<void> addNotification(NotificationItem notification) async {
    if (_prefs == null) await initialize();

    final notifications = await getAllNotifications();
    notifications.insert(0, notification); // Add to beginning (newest first)

    // Limit to max notifications to prevent storage bloat
    if (notifications.length > _maxNotifications) {
      notifications.removeRange(_maxNotifications, notifications.length);
    }

    await _saveNotifications(notifications);
    print('📱 Added notification: ${notification.title}');
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final notifications = await getAllNotifications();
    final updatedNotifications = notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    await _saveNotifications(updatedNotifications);
  }

  /// Mark multiple notifications as read
  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    final notifications = await getAllNotifications();
    final updatedNotifications = notifications.map((n) {
      if (notificationIds.contains(n.id)) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    await _saveNotifications(updatedNotifications);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final notifications = await getAllNotifications();
    final updatedNotifications = notifications.map((n) => n.copyWith(isRead: true)).toList();

    await _saveNotifications(updatedNotifications);
  }

  /// Delete notification by ID
  Future<void> deleteNotification(String notificationId) async {
    final notifications = await getAllNotifications();
    notifications.removeWhere((n) => n.id == notificationId);

    await _saveNotifications(notifications);
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _prefs?.remove(_storageKey);
  }

  /// Get unread count for badge
  Future<int> getUnreadCount() async {
    final unread = await getUnreadNotifications();
    return unread.length;
  }

  /// Create and store notification from FCM message
  Future<NotificationItem> createAndStoreFromFCM(Map<String, dynamic> fcmMessage) async {
    final notification = NotificationItem.fromFCM(fcmMessage);
    await addNotification(notification);
    return notification;
  }

  /// Create and store local notification
  Future<NotificationItem> createAndStoreLocal({
    required String title,
    required String message,
    required String type,
    String washId = '',
    String? dhobiName,
    int? itemCount,
    List<String>? missingItems,
    Map<String, dynamic>? data,
  }) async {
    final notification = NotificationItem(
      title: title,
      message: message,
      type: type,
      washId: washId,
      dhobiName: dhobiName,
      itemCount: itemCount,
      missingItems: missingItems,
      data: data,
    );
    await addNotification(notification);
    return notification;
  }

  /// Save notifications to storage
  Future<void> _saveNotifications(List<NotificationItem> notifications) async {
    if (_prefs == null) await initialize();

    final jsonList = notifications.map((n) => n.toJson()).toList();
    final jsonString = json.encode(jsonList);

    await _prefs!.setString(_storageKey, jsonString);
  }

  /// Get notifications by wash ID
  Future<List<NotificationItem>> getNotificationsByWashId(String washId) async {
    final all = await getAllNotifications();
    return all.where((n) => n.washId == washId).toList();
  }

  /// Static method for storing FCM notifications in background/isolates
  /// Can be called from background message handler without full service initialization
  static Future<void> storeFCMNotificationBackground(Map<String, dynamic> message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const jsonKey = 'washlens_notifications';

      final storedData = prefs.getString(jsonKey);
      List<Map<String, dynamic>> notifications = [];

      if (storedData != null) {
        final List<dynamic> jsonList = json.decode(storedData);
        notifications = jsonList.cast<Map<String, dynamic>>();
      }

      final notification = NotificationItem.fromFCM(message);
      final notificationJson = notification.toJson();

      notifications.insert(0, notificationJson); // Add to beginning

      // Limit to max notifications
      if (notifications.length > 100) {
        notifications = notifications.sublist(0, 100);
      }

      final jsonString = json.encode(notifications);
      await prefs.setString(jsonKey, jsonString);

      print('📝 FCM notification stored in background: ${notification.title}');
    } catch (e) {
      print('❌ Failed to store FCM notification in background: $e');
    }
  }

  /// Get notifications by type
  Future<List<NotificationItem>> getNotificationsByType(String type) async {
    final all = await getAllNotifications();
    return all.where((n) => n.type == type).toList();
  }

  /// Get notifications between dates
  Future<List<NotificationItem>> getNotificationsBetweenDates(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllNotifications();
    return all.where((n) => n.createdAt.isAfter(start) && n.createdAt.isBefore(end)).toList();
  }

    /// Search notifications by text
    Future<List<NotificationItem>> searchNotifications(String query) async {
      final all = await getAllNotifications();
      final lowercaseQuery = query.toLowerCase();
  
      return all.where((n) =>
        n.title.toLowerCase().contains(lowercaseQuery) ||
        n.message.toLowerCase().contains(lowercaseQuery)
      ).toList();
    }
  }
