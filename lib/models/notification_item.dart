import 'package:uuid/uuid.dart';

/// Represents a real notification in the system
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type; // 'wash_reminder', 'missing_items', 'pickup_timer', 'general'
  final String washId; // Associated wash entry if applicable
  final String? dhobiName;
  final int? itemCount;
  final List<String>? missingItems;
  final DateTime createdAt;
  bool isRead;
  final Map<String, dynamic>? data;

  NotificationItem({
    String? id,
    required this.title,
    required this.message,
    required this.type,
    this.washId = '',
    this.dhobiName,
    this.itemCount,
    this.missingItems,
    DateTime? createdAt,
    this.isRead = false,
    this.data,
  }) :
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();

  // Create from FCM message
  factory NotificationItem.fromFCM(Map<String, dynamic> message) {
    final notification = message['notification'] as Map<String, dynamic>?;
    final data = message['data'] as Map<String, dynamic>?;

    return NotificationItem(
      title: notification?['title'] ?? 'WashLens AI',
      message: notification?['body'] ?? 'New notification',
      type: data?['type'] ?? 'general',
      washId: data?['washId'] ?? '',
      dhobiName: data?['dhobiName'],
      itemCount: data?['itemCount'] != null ? int.tryParse(data!['itemCount'].toString()) : null,
      missingItems: data?['missingItems'] != null
          ? (data!['missingItems'] as List<dynamic>).cast<String>()
          : null,
      data: data,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'washId': washId,
      'dhobiName': dhobiName,
      'itemCount': itemCount,
      'missingItems': missingItems,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  // Create from JSON (for storage retrieval)
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      washId: json['washId'] ?? '',
      dhobiName: json['dhobiName'],
      itemCount: json['itemCount'],
      missingItems: json['missingItems'] != null
          ? (json['missingItems'] as List<dynamic>).cast<String>()
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
      data: json['data'],
    );
  }

  // Copy with method for updates
  NotificationItem copyWith({
    String? title,
    String? message,
    String? type,
    String? washId,
    String? dhobiName,
    int? itemCount,
    List<String>? missingItems,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      washId: washId ?? this.washId,
      dhobiName: dhobiName ?? this.dhobiName,
      itemCount: itemCount ?? this.itemCount,
      missingItems: missingItems ?? this.missingItems,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  // Get formatted time string
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      }
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Get appropriate icon based on type
  String getIconData() {
    switch (type) {
      case 'wash_reminder':
        return 'notifications';
      case 'missing_items':
        return 'search';
      case 'pickup_timer':
        return 'schedule';
      case 'return_confirmation':
        return 'check_circle';
      default:
        return 'notifications';
    }
  }

  // Get appropriate color based on type
  int getIconColor() {
    switch (type) {
      case 'wash_reminder':
        return 0xFF4A6FFF; // Primary blue
      case 'missing_items':
        return 0xFFEF4444; // Red
      case 'pickup_timer':
        return 0xFFF59E0B; // Yellow
      case 'return_confirmation':
        return 0xFF6EE7B7; // Green
      default:
        return 0xFF4A6FFF;
    }
  }

  @override
  String toString() {
    return 'NotificationItem(id: $id, title: $title, type: $type, isRead: $isRead, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
