import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../../models/user_settings.dart';
import '../../providers/user_provider.dart';
import '../../services/notification_service_enhanced.dart';

// Animation durations
const Duration _animationDuration = Duration(milliseconds: 300);
const Curve _animationCurve = Curves.easeInOut;

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late UserSettings _userSettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // Settings are loaded during initialization, access them directly
    if (mounted) {
      setState(() {
        _userSettings = userProvider.userSettings ?? UserSettings(
          userId: userProvider.currentUser?.id ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(VoidCallback update) async {
    if (_isLoading) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() => update());

    // Create updated settings
    final updatedSettings = _userSettings.copyWith(
      reminderDays: _userSettings.reminderDays,
      pickupReminderHours: _userSettings.pickupReminderHours,
      enableNotifications: _userSettings.enableNotifications,
      enablePickupTimerAlerts: _userSettings.enablePickupTimerAlerts,
      enableDryingTimeAlerts: _userSettings.enableDryingTimeAlerts,
      enableMissingItemAlerts: _userSettings.enableMissingItemAlerts,
      dryingAlertSensitivity: _userSettings.dryingAlertSensitivity,
      missingItemAlertDays: _userSettings.missingItemAlertDays,
      updatedAt: DateTime.now(),
    );

    // Save settings
    await userProvider.updateUserSettings(updatedSettings);
  }

  /// Send example notification when toggles are enabled with improved UX
  Future<void> _sendExampleNotificationForToggle({
    required bool wasEnabled,
    required bool isNowEnabled,
    required String type,
  }) async {
    debugPrint('🔔 Toggle changed - Type: $type, Was: $wasEnabled, Now: $isNowEnabled');
    
    // Only send example when toggling from OFF to ON
    if (!wasEnabled && isNowEnabled) {
      debugPrint('✅ Sending sample notification for: $type');
      
      final notificationService = Provider.of<NotificationServiceEnhanced>(context, listen: false);
      
      debugPrint('📱 Service initialized: ${notificationService.isInitialized}');
      debugPrint('🔐 Permissions granted: ${notificationService.permissionsGranted}');

      if (!notificationService.isInitialized) {
        debugPrint('⚠️ NotificationService not initialized');
        _showSnackBar('⚠️ Notification service is initializing... Please try again.');
        return;
      }

      if (!notificationService.permissionsGranted) {
        debugPrint('⚠️ Notification permissions not granted');
        _showSnackBar('🔐 Please enable notification permissions in settings');
        return;
      }

      String title;
      String body;
      String channelId;

      switch (type) {
        case 'pickup_timer':
          title = '🎉 WashLens Example';
          body = 'This is how you\'ll receive laundry ready notifications! ✨';
          channelId = 'wash_reminders';
          break;

        case 'drying_time':
          title = '🌤️ WashLens Example';
          body = 'This is how weather-based alerts look 📅';
          channelId = 'pickup_timer';
          break;

        case 'missing_item':
          title = '⚠️ WashLens Example';
          body = 'This is how missing item alerts appear ❌';
          channelId = 'missing_items';
          break;

        default:
          debugPrint('❌ Unknown type: $type');
          return;
      }

      try {
        debugPrint('📤 Sending notification: $title');
        debugPrint('   Body: $body');
        debugPrint('   Channel: $channelId');
        
        // Show enhanced notification with app logo and branding
        await notificationService.showLocalNotification(
          title: title,
          body: body,
          channelId: channelId,
          priority: NotificationPriority.high,
        );
        
        debugPrint('✅ Notification sent successfully!');
        
        // Show success feedback in UI
        _showSnackBar('✨ Sample notification sent! Check your notification panel.');
      } catch (e, stackTrace) {
        debugPrint('❌ Failed to send notification: $e');
        debugPrint('   Stack trace: $stackTrace');
        _showSnackBar('❌ Failed to send notification. Please check permissions.');
      }
    } else {
      debugPrint('⏭️ Skipping notification (wasEnabled: $wasEnabled, isNowEnabled: $isNowEnabled)');
    }
  }

  /// Show user-friendly snackbar feedback
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            children: [
              // Pending Returns Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pending Returns',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.012),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _IconCircle(icon: Icons.schedule, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Enable notifications for returning items",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w500,
                              fontSize: screenWidth * 0.035,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        _Switch(
                          value: _userSettings.enablePickupTimerAlerts,
                          onChanged: (v) async {
                            // Update setting first
                            await _updateSetting(() => _userSettings = _userSettings.copyWith(enablePickupTimerAlerts: v));
                            // Then send sample notification
                            await _sendExampleNotificationForToggle(
                              wasEnabled: !v, // Inverted since we already updated
                              isNowEnabled: v,
                              type: 'pickup_timer',
                            );
                          },
                        ),
                      ],
                    ),
                    AnimatedOpacity(
                      opacity: _userSettings.enablePickupTimerAlerts ? 1.0 : 0.4,
                      duration: _animationDuration,
                      child: AnimatedSize(
                        duration: _animationDuration,
                        curve: _animationCurve,
                        child: _userSettings.enablePickupTimerAlerts
                          ? Column(
                              children: [
                                _Divider(),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Remind me after",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w500,
                                        fontSize: screenWidth * 0.035,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      "${_userSettings.reminderDays} days",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w400,
                                        fontSize: screenWidth * 0.035,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                                    overlayShape: SliderComponentShape.noOverlay,
                                    trackHeight: 5,
                                    activeTrackColor: AppTheme.primary,
                                    inactiveTrackColor: AppTheme.surfaceVariant,
                                  ),
                                  child: Slider(
                                    min: 1,
                                    max: 10,
                                    value: _userSettings.reminderDays.toDouble(),
                                    divisions: 9,
                                    onChanged: (v) {
                                      final newValue = v.round();
                                      _updateSetting(() => _userSettings = _userSettings.copyWith(reminderDays: newValue));
                                    },
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              // Drying Time Alerts Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Drying Time Alerts',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.012),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _IconCircle(icon: Icons.wb_sunny, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "AI-powered weather-based alerts",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w500,
                              fontSize: screenWidth * 0.035,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        _Switch(
                          value: _userSettings.enableDryingTimeAlerts,
                          onChanged: (v) async {
                            // Update setting first
                            await _updateSetting(() => _userSettings = _userSettings.copyWith(enableDryingTimeAlerts: v));
                            // Then send sample notification
                            await _sendExampleNotificationForToggle(
                              wasEnabled: !v,
                              isNowEnabled: v,
                              type: 'drying_time',
                            );
                          },
                        ),
                      ],
                    ),
                    AnimatedOpacity(
                      opacity: _userSettings.enableDryingTimeAlerts ? 1.0 : 0.4,
                      duration: _animationDuration,
                      child: AnimatedSize(
                        duration: _animationDuration,
                        curve: _animationCurve,
                        child: _userSettings.enableDryingTimeAlerts
                          ? Column(
                              children: [
                                _Divider(),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Alert Sensitivity",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w500,
                                        fontSize: screenWidth * 0.035,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: AppTheme.surfaceVariant),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _userSettings.dryingAlertSensitivity,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: screenWidth * 0.035,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                          borderRadius: BorderRadius.circular(18),
                                          items: const [
                                            DropdownMenuItem(value: "Standard", child: Text("Standard")),
                                            DropdownMenuItem(value: "Quicker (for humid days)", child: Text("Quicker (for humid days)")),
                                            DropdownMenuItem(value: "Delayed (for rainy days)", child: Text("Delayed (for rainy days)")),
                                          ],
                                          onChanged: (value) {
                                            if (value != null) {
                                              _updateSetting(() => _userSettings = _userSettings.copyWith(dryingAlertSensitivity: value));
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              // Missing Item Alerts Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Missing Item Alerts',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.012),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _IconCircle(icon: Icons.search, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Alert me when items are missing",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w500,
                              fontSize: screenWidth * 0.035,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        _Switch(
                          value: _userSettings.enableMissingItemAlerts,
                          onChanged: (v) async {
                            // Update setting first
                            await _updateSetting(() => _userSettings = _userSettings.copyWith(enableMissingItemAlerts: v));
                            // Then send sample notification
                            await _sendExampleNotificationForToggle(
                              wasEnabled: !v,
                              isNowEnabled: v,
                              type: 'missing_item',
                            );
                          },
                        ),
                      ],
                    ),
                    AnimatedOpacity(
                      opacity: _userSettings.enableMissingItemAlerts ? 1.0 : 0.4,
                      duration: _animationDuration,
                      child: AnimatedSize(
                        duration: _animationDuration,
                        curve: _animationCurve,
                        child: _userSettings.enableMissingItemAlerts
                          ? Column(
                              children: [
                                _Divider(),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Alert if missing for",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w500,
                                        fontSize: screenWidth * 0.035,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      "${_userSettings.missingItemAlertDays} day",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w400,
                                        fontSize: screenWidth * 0.035,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                                    overlayShape: SliderComponentShape.noOverlay,
                                    trackHeight: 5,
                                    activeTrackColor: AppTheme.primary,
                                    inactiveTrackColor: AppTheme.surfaceVariant,
                                  ),
                                  child: Slider(
                                    min: 1,
                                    max: 10,
                                    value: _userSettings.missingItemAlertDays.toDouble(),
                                    divisions: 9,
                                    onChanged: (v) {
                                      final newValue = v.round();
                                      _updateSetting(() => _userSettings = _userSettings.copyWith(missingItemAlertDays: newValue));
                                    },
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Card style for section
class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.shadow2,
      ),
      child: child,
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconCircle({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// Toggle switch style
class _Switch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Switch({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primary,
      inactiveTrackColor: AppTheme.surfaceVariant,
      activeTrackColor: AppTheme.primary.withOpacity(0.26),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: double.infinity,
      color: AppTheme.surfaceVariant,
      margin: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}
