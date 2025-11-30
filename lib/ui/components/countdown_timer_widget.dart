import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/notification_timer_service.dart';
import '../../models/wash_entry.dart';
import '../../models/user_settings.dart';
import '../theme/app_theme.dart';

/// Live countdown timer widget that displays time until next notification
class CountdownTimerWidget extends StatefulWidget {
  final WashEntry washEntry;
  final UserSettings userSettings;

  const CountdownTimerWidget({
    super.key,
    required this.washEntry,
    required this.userSettings,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  Duration? _timeRemaining;
  StreamSubscription<Map<String, Duration>>? _countdownSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCountdown();
  }

  @override
  void didUpdateWidget(CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.washEntry.id != widget.washEntry.id ||
        oldWidget.userSettings != widget.userSettings) {
      _initializeCountdown();
    }
  }

  void _initializeCountdown() {
    // Cancel existing timer and subscription
    _timer?.cancel();
    _countdownSubscription?.cancel();

    // Get initial countdown data
    final timerService = NotificationTimerService();
    _timeRemaining = timerService.getCountdownForWashEntry(widget.washEntry, widget.userSettings);

    // Subscribe to live countdown updates
    _countdownSubscription = timerService.countdownStream.listen((update) {
      if (update.containsKey(widget.washEntry.id)) {
        if (mounted) {
          setState(() {
            _timeRemaining = update[widget.washEntry.id];
          });
        }
      }
    });

    // Set up local timer for additional updates
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          final timerService = NotificationTimerService();
          _timeRemaining = timerService.getCountdownForWashEntry(widget.washEntry, widget.userSettings);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.washEntry.status != WashStatus.pending || _timeRemaining == null) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isOverdue = _timeRemaining!.isNegative;
    final timeService = NotificationTimerService();
    final timeString = timeService.getTimeRemainingString(_timeRemaining!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOverdue ? AppTheme.error.withOpacity(0.1) : AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue ? AppTheme.error.withOpacity(0.3) : AppTheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.schedule,
            size: screenWidth * 0.035,
            color: isOverdue ? AppTheme.error : AppTheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            timeString,
            style: GoogleFonts.plusJakartaSans(
              fontSize: screenWidth * 0.032,
              fontWeight: FontWeight.w600,
              color: isOverdue ? AppTheme.error : AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact countdown badge for lists/cards
class CountdownBadge extends StatefulWidget {
  final WashEntry washEntry;
  final UserSettings userSettings;
  final bool showIcon;

  const CountdownBadge({
    super.key,
    required this.washEntry,
    required this.userSettings,
    this.showIcon = true,
  });

  @override
  State<CountdownBadge> createState() => _CountdownBadgeState();
}

class _CountdownBadgeState extends State<CountdownBadge> {
  Timer? _timer;
  Duration? _timeRemaining;

  @override
  void initState() {
    super.initState();
    _updateCountdown();

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _updateCountdown();
      }
    });
  }

  @override
  void didUpdateWidget(CountdownBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.washEntry.id != widget.washEntry.id ||
        oldWidget.userSettings != widget.userSettings) {
      _updateCountdown();
    }
  }

  void _updateCountdown() {
    final timerService = NotificationTimerService();
    final timeRemaining = timerService.getCountdownForWashEntry(widget.washEntry, widget.userSettings);
    if (mounted) {
      setState(() {
        _timeRemaining = timeRemaining;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.washEntry.status != WashStatus.pending || _timeRemaining == null) {
      return const SizedBox.shrink();
    }

    final isOverdue = _timeRemaining!.isNegative;
    final screenWidth = MediaQuery.of(context).size.width;

    // Show only for imminent notifications (within 7 days)
    if (_timeRemaining!.inDays > 7 && !isOverdue) {
      return const SizedBox.shrink();
    }

    final timeService = NotificationTimerService();
    final timeString = _formatCompactTime(_timeRemaining!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppTheme.error.withOpacity(0.9)
            : _timeRemaining!.inHours < 24
                ? AppTheme.warning.withOpacity(0.9)
                : AppTheme.info.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
            Icon(
              isOverdue
                  ? Icons.warning
                  : _timeRemaining!.inHours < 24
                      ? Icons.access_time
                      : Icons.notifications,
              size: screenWidth * 0.035,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            timeString,
            style: GoogleFonts.plusJakartaSans(
              fontSize: screenWidth * 0.028,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompactTime(Duration duration) {
    if (duration.isNegative) {
      return 'Overdue';
    }

    if (duration.inDays > 0) {
      return '${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '<1m';
    }
  }
}

/// Status indicator for wash entry with countdown
class WashEntryStatusIndicator extends StatefulWidget {
  final WashEntry washEntry;
  final UserSettings userSettings;

  const WashEntryStatusIndicator({
    super.key,
    required this.washEntry,
    required this.userSettings,
  });

  @override
  State<WashEntryStatusIndicator> createState() => _WashEntryStatusIndicatorState();
}

class _WashEntryStatusIndicatorState extends State<WashEntryStatusIndicator> {
  Timer? _timer;
  Duration? _timeRemaining;

  @override
  void initState() {
    super.initState();
    _updateCountdown();

    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _updateCountdown();
      }
    });
  }

  void _updateCountdown() {
    final timerService = NotificationTimerService();
    final timeRemaining = timerService.getCountdownForWashEntry(widget.washEntry, widget.userSettings);
    if (mounted) {
      setState(() {
        _timeRemaining = timeRemaining;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (widget.washEntry.status != WashStatus.pending) {
      return Row(
        children: [
          Icon(
            Icons.check_circle,
            size: screenWidth * 0.04,
            color: AppTheme.success,
          ),
          const SizedBox(width: 6),
          Text(
            'Completed',
            style: GoogleFonts.plusJakartaSans(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      );
    }

    if (_timeRemaining == null) {
      return Row(
        children: [
          Icon(
            Icons.schedule,
            size: screenWidth * 0.04,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            'Pending',
            style: GoogleFonts.plusJakartaSans(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      );
    }

    final isOverdue = _timeRemaining!.isNegative;
    final timeService = NotificationTimerService();
    final timeString = timeService.getTimeRemainingString(_timeRemaining!);

    return Row(
      children: [
        Icon(
          isOverdue ? Icons.warning : Icons.access_time,
          size: screenWidth * 0.04,
          color: isOverdue
              ? AppTheme.error
              : _timeRemaining!.inHours < 24
                  ? AppTheme.warning
                  : AppTheme.primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            timeString,
            style: GoogleFonts.plusJakartaSans(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w500,
              color: isOverdue
                  ? AppTheme.error
                  : _timeRemaining!.inHours < 24
                      ? AppTheme.warning
                      : AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
