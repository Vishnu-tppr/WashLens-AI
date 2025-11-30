import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/wash_entry.dart';
import '../models/user_settings.dart';
import './notification_service_enhanced.dart';

/// Service for managing countdown timers and real notification scheduling
/// This connects user settings to actual notification scheduling based on wash events
class NotificationTimerService {
  // Singleton pattern
  static final NotificationTimerService _instance = NotificationTimerService._internal();
  factory NotificationTimerService() => _instance;
  NotificationTimerService._internal();

  // Services
  NotificationServiceEnhanced? _notificationService;
  Timer? _checkTimer;

  // State tracking
  bool _isInitialized = false;
  final Map<String, Timer> _activeTimers = {}; // washId -> timer
  final Map<String, DateTime> _scheduledNotifications = {}; // washId -> due date

  // Callbacks for UI updates
  final StreamController<Map<String, Duration>> _countdownController = StreamController.broadcast();
  Stream<Map<String, Duration>> get countdownStream => _countdownController.stream;

  /// Initialize the timer service
  Future<void> initialize(NotificationServiceEnhanced notificationService) async {
    if (_isInitialized) return;

    _notificationService = notificationService;

    // Start periodic check (every 1 minute)
    _checkTimer = Timer.periodic(const Duration(minutes: 1), _checkDueNotifications);

    // Initialize with existing wash entries (if service becomes available later)
    // This would be called from somewhere that has access to wash entries

    _isInitialized = true;
    debugPrint('🔔 NotificationTimerService initialized');
  }

  /// Start monitoring a wash entry for notifications
  Future<void> startMonitoringWashEntry(WashEntry washEntry, UserSettings userSettings) async {
    if (!_isInitialized || _notificationService == null) return;

    final washId = washEntry.id;

    // Cancel any existing timers for this wash entry
    _cancelTimersForWashEntry(washId);

    // Only monitor if wash is still pending
    if (washEntry.status != WashStatus.pending) {
      debugPrint('🚫 Wash entry $washId is not pending, skipping monitoring');
      return;
    }

    // Calculate all notification dates
    final notificationDates = _calculateNotificationDates(washEntry, userSettings);

    // Schedule payment reminder if enabled
    if (userSettings.enableNotifications && userSettings.enablePickupTimerAlerts) {
      _schedulePaymentReminder(washEntry, userSettings, notificationDates['payment']);
    }

    // Schedule drying time alerts if enabled
    if (userSettings.enableDryingTimeAlerts) {
      _scheduleDryingAlerts(washEntry, userSettings, notificationDates['drying']);
    }

    // Schedule missing item alerts if enabled
    if (userSettings.enableMissingItemAlerts) {
      _scheduleMissingItemAlerts(washEntry, userSettings, notificationDates['missing']);
    }

    debugPrint('🔍 Started monitoring wash entry: $washId with ${notificationDates.length} scheduled notifications');
  }

  /// Stop monitoring a wash entry (when returned/completed)
  void stopMonitoringWashEntry(String washId) {
    _cancelTimersForWashEntry(washId);

    // Cancel any scheduled notifications
    if (_notificationService != null) {
      _notificationService!.cancelScheduledNotification(washId);
    }

    debugPrint('🛑 Stopped monitoring wash entry: $washId');
  }

  /// Get live countdown data for a specific wash entry
  Duration? getCountdownForWashEntry(WashEntry washEntry, UserSettings userSettings) {
    if (washEntry.status != WashStatus.pending) return null;

    final now = DateTime.now();
    Duration? earliestDeadline;

    // Calculate time until next notification
    final notificationDates = _calculateNotificationDates(washEntry, userSettings);

    for (final date in notificationDates.values) {
      if (date != null && date.isAfter(now)) {
        final timeUntil = date.difference(now);
        if (earliestDeadline == null || timeUntil < earliestDeadline) {
          earliestDeadline = timeUntil;
        }
      }
    }

    return earliestDeadline;
  }

  /// Calculate all notification dates for a wash entry
  Map<String, DateTime?> _calculateNotificationDates(WashEntry washEntry, UserSettings userSettings) {
    final givenDate = washEntry.givenAt;
    final now = DateTime.now();

    // Estimate return date (typical laundry takes 2-3 days)
    // This could be improved with real dhobi data or user input
    final estimatedReturnDate = givenDate.add(const Duration(days: 3));

    final dates = <String, DateTime?>{};

    // Payment reminder (days before estimated return)
    if (userSettings.enableNotifications && userSettings.enablePickupTimerAlerts) {
      final reminderDate = estimatedReturnDate.subtract(Duration(days: userSettings.reminderDays));
      dates['payment'] = reminderDate.isAfter(now) ? reminderDate : null;
    }

    // Drying time alerts based on sensitivity
    if (userSettings.enableDryingTimeAlerts) {
      int dryingDays;
      switch (userSettings.dryingAlertSensitivity) {
        case 'Quicker (for humid days)':
          dryingDays = 1; // Alert 1 day before to air dry while humid
          break;
        case 'Delayed (for rainy days)':
          dryingDays = 7; // Delay drying for rainy weather
          break;
        case 'Standard':
        default:
          dryingDays = 3; // Standard 3 days
          break;
      }
      dates['drying'] = estimatedReturnDate.add(Duration(days: dryingDays));
    }

    // Missing item alerts (days after estimated return when still missing)
    if (userSettings.enableMissingItemAlerts) {
      dates['missing'] = estimatedReturnDate.add(Duration(days: userSettings.missingItemAlertDays));
    }

    // Due date reminder (when laundry should be ready for pickup)
    if (userSettings.enablePickupTimerAlerts) {
      dates['pickup'] = estimatedReturnDate.subtract(Duration(hours: userSettings.pickupReminderHours));
    }

    debugPrint('📅 Notification dates for ${washEntry.id}: $dates');
    return dates;
  }

  /// Schedule payment reminder notification
  void _schedulePaymentReminder(WashEntry washEntry, UserSettings userSettings, DateTime? scheduledDate) {
    if (scheduledDate == null || !_isInitialized) return;

    final washId = washEntry.id;
    final notificationId = 'payment_reminder_$washId'.hashCode;

    // Cancel any existing reminder for this wash
    _notificationService?.cancelScheduledNotification(notificationId.toString());

    // Schedule the actual notification
    _notificationService?.scheduleReminderNotification(
      washId: washId,
      dhobiName: washEntry.dhobiName,
      itemCount: washEntry.totalGiven,
      scheduledDate: scheduledDate,
      userSettings: userSettings,
    );

    // Set up live countdown updates
    _setupCountdownTimer(washId, scheduledDate);

    debugPrint('💰 Payment reminder scheduled for ${washEntry.dhobiName} on $scheduledDate');
  }

  /// Schedule drying time alerts
  void _scheduleDryingAlerts(WashEntry washEntry, UserSettings userSettings, DateTime? scheduledDate) {
    if (scheduledDate == null || !_isInitialized) return;

    final washId = washEntry.id;
    final now = DateTime.now();

    if (scheduledDate.isBefore(now)) return; // Don't schedule past dates

    // Calculate timing based on sensitivity
    final washIdHash = washEntry.id.hashCode;
    final dryingNotificationId = 'drying_alert_$washId'.hashCode;

    // Schedule drying alert
    _notificationService?.showPickupTimerNotification(
      washId: dryingNotificationId.toString(),
      dhobiName: washEntry.dhobiName,
      hoursRemaining: scheduledDate.difference(now).inHours,
      userSettings: userSettings,
    );

    // Set up drying-specific countdown
    _setupCountdownTimer(washId, scheduledDate);

    debugPrint('🌞 Drying alert scheduled for ${washEntry.dhobiName} on $scheduledDate');
  }

  /// Schedule missing item alerts
  void _scheduleMissingItemAlerts(WashEntry washEntry, UserSettings userSettings, DateTime? scheduledDate) {
    if (scheduledDate == null || !_isInitialized) return;

    // Only schedule if we still expect items by this date
    if (scheduledDate.isBefore(DateTime.now()) && washEntry.status == WashStatus.pending) {
      // This wash entry might have missing items
      _notificationService?.showMissingItemAlert(
        washId: washEntry.id,
        dhobiName: washEntry.dhobiName,
        missingItems: _getMissingItemNames(washEntry),
        userSettings: userSettings,
      );

      debugPrint('🚨 Missing item alert triggered for ${washEntry.dhobiName}');
    } else if (scheduledDate.isAfter(DateTime.now())) {
      // Schedule future alert
      _setupCountdownTimer(washEntry.id, scheduledDate, isMissingAlert: true);
      debugPrint('🚨 Missing item alert scheduled for ${washEntry.dhobiName} on $scheduledDate');
    }
  }

  /// Set up live countdown timer for a wash entry
  void _setupCountdownTimer(String washId, DateTime targetDate, {bool isMissingAlert = false}) {
    final timerKey = '${washId}_${isMissingAlert ? 'missing' : 'countdown'}';

    _activeTimers[timerKey]?.cancel();

    _activeTimers[timerKey] = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      final timeRemaining = targetDate.difference(now);

      // Stop timer if past due date
      if (timeRemaining.isNegative) {
        timer.cancel();
        _activeTimers.remove(timerKey);

        // Notify about past due
        _emitCountdownUpdate(washId, Duration.zero, isPastDue: true);
        return;
      }

      // Emit countdown update
      _emitCountdownUpdate(washId, timeRemaining);
    });

    debugPrint('⏱️ Started countdown timer for wash $washId until $targetDate');
  }

  /// Emit countdown update to stream
  void _emitCountdownUpdate(String washId, Duration timeRemaining, {bool isPastDue = false}) {
    final update = {
      'washId': washId,
      'timeRemaining': timeRemaining,
      'isPastDue': isPastDue,
      'days': timeRemaining.inDays,
      'hours': timeRemaining.inHours.remainder(24),
      'minutes': timeRemaining.inMinutes.remainder(60),
    };

    _countdownController.add({washId: timeRemaining});
  }

  /// Cancel all timers for a wash entry
  void _cancelTimersForWashEntry(String washId) {
    final timersToCancel = _activeTimers.keys.where((key) => key.startsWith(washId)).toList();

    for (final timerKey in timersToCancel) {
      _activeTimers[timerKey]?.cancel();
      _activeTimers.remove(timerKey);
    }
  }

  /// Check for due notifications periodically
  void _checkDueNotifications(Timer timer) {
    final now = DateTime.now();

    // Check all scheduled notifications for past-due items
    _scheduledNotifications.removeWhere((washId, dueDate) {
      if (dueDate.isBefore(now)) {
        debugPrint('⚠️ Past-due notification found for wash: $washId');
        // Here you could trigger urgent notifications or status updates
        return true; // Remove from map
      }
      return false;
    });
  }

  /// Update notification settings for all monitored wash entries
  Future<void> updateNotificationSettings(UserSettings newSettings, List<WashEntry> washEntries) async {
    debugPrint('🔄 Updating notification settings for ${washEntries.length} wash entries');

    // Re-monitor all pending wash entries with new settings
    for (final washEntry in washEntries) {
      if (washEntry.status == WashStatus.pending) {
        await startMonitoringWashEntry(washEntry, newSettings);
      }
    }
  }

  /// Get readable time remaining string
  String getTimeRemainingString(Duration timeRemaining) {
    if (timeRemaining.isNegative) {
      final overdue = timeRemaining.abs();
      if (overdue.inDays > 0) {
        return '${overdue.inDays} days overdue';
      } else if (overdue.inHours > 0) {
        return '${overdue.inHours} hours overdue';
      } else {
        return '${overdue.inMinutes} minutes overdue';
      }
    }

    if (timeRemaining.inDays > 0) {
      return '${timeRemaining.inDays}d ${timeRemaining.inHours.remainder(24)}h left';
    } else if (timeRemaining.inHours > 0) {
      return '${timeRemaining.inHours}h ${timeRemaining.inMinutes.remainder(60)}m left';
    } else {
      return '${timeRemaining.inMinutes}m left';
    }
  }

  /// Get missing item names for alert
  List<String> _getMissingItemNames(WashEntry washEntry) {
    final missingCategories = washEntry.missingByCategory;
    return missingCategories.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${entry.value} ${entry.key}')
        .toList();
  }

  /// Get notification schedule summary for UI
  Map<String, dynamic> getNotificationScheduleSummary(WashEntry washEntry, UserSettings userSettings) {
    final notificationDates = _calculateNotificationDates(washEntry, userSettings);
    final now = DateTime.now();

    return {
      'washId': washEntry.id,
      'dhobiName': washEntry.dhobiName,
      'nextNotification': _findNextNotificationDate(notificationDates),
      'notificationCount': notificationDates.values.where((date) => date != null && date.isAfter(now)).length,
      'hasActiveTimers': _activeTimers.keys.any((key) => key.contains(washEntry.id)),
      'scheduledNotifications': notificationDates,
    };
  }

  /// Find the next upcoming notification date
  DateTime? _findNextNotificationDate(Map<String, DateTime?> dates) {
    final now = DateTime.now();
    DateTime? nextDate;

    for (final date in dates.values) {
      if (date != null && date.isAfter(now)) {
        if (nextDate == null || date.isBefore(nextDate)) {
          nextDate = date;
        }
      }
    }

    return nextDate;
  }

  /// Dispose resources
  void dispose() {
    _checkTimer?.cancel();
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    _countdownController.close();
    debugPrint('♻️ NotificationTimerService disposed');
  }

  /// Check if service is running and return status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'hasNotificationService': _notificationService != null,
      'activeTimersCount': _activeTimers.length,
      'scheduledNotificationsCount': _scheduledNotifications.length,
      'checkTimerRunning': _checkTimer?.isActive ?? false,
    };
  }
}
