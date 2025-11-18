import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../models/user_settings.dart';

/// Notification Settings Screen
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final horizontalPadding = screenWidth * 0.04;
        final verticalSpacing = screenHeight * 0.012;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text(
              'Notification Settings',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppTheme.surface,
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: screenHeight * 0.015,
            ),
            child: Column(
              children: [
                // Pending Returns Card
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.035),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: screenWidth * 0.11,
                            height: screenWidth * 0.11,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.025),
                            ),
                            child: Icon(
                              Icons.access_time,
                              color: AppTheme.primary,
                              size: screenWidth * 0.055,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Text(
                              'Pending Returns',
                              style: TextStyle(
                                fontSize: screenWidth * 0.042,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: userProvider
                                      .userSettings?.enableNotifications ??
                                  true,
                              onChanged: (val) async {
                                final settings = userProvider.userSettings ??
                                    UserSettings(
                                      userId:
                                          userProvider.currentUser?.id ?? '',
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                    );
                                final updatedSettings =
                                    settings.copyWith(enableNotifications: val);
                                await userProvider
                                    .updateUserSettings(updatedSettings);
                              },
                              activeColor: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remind me after',
                            style: TextStyle(
                              fontSize: screenWidth * 0.036,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '${userProvider.userSettings?.reminderDays ?? 3} days',
                            style: TextStyle(
                              fontSize: screenWidth * 0.036,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: screenHeight * 0.006,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: screenWidth * 0.018,
                          ),
                          overlayShape: RoundSliderOverlayShape(
                            overlayRadius: screenWidth * 0.035,
                          ),
                        ),
                        child: Slider(
                          value: (userProvider.userSettings?.reminderDays ?? 3)
                              .toDouble(),
                          min: 1,
                          max: 7,
                          divisions: 6,
                          activeColor: AppTheme.primary,
                          inactiveColor: AppTheme.surfaceVariant,
                          onChanged: (val) async {
                            final settings = userProvider.userSettings ??
                                UserSettings(
                                  userId: userProvider.currentUser?.id ?? '',
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                );
                            final updatedSettings =
                                settings.copyWith(reminderDays: val.round());
                            await userProvider
                                .updateUserSettings(updatedSettings);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: verticalSpacing * 1.2),

                // Pickup Timer Card
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.035),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: screenWidth * 0.11,
                            height: screenWidth * 0.11,
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.025),
                            ),
                            child: Icon(
                              Icons.timer,
                              color: AppTheme.accent,
                              size: screenWidth * 0.055,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pickup Timer',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.042,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'When to expect laundry pickup',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.03,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: true, // Always enabled for timer display
                              onChanged: (val) async {
                                // Timer is always shown, no toggle needed yet
                              },
                              activeColor: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Expected pickup in',
                            style: TextStyle(
                              fontSize: screenWidth * 0.036,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '${userProvider.userSettings?.pickupReminderHours ?? 24} hours',
                            style: TextStyle(
                              fontSize: screenWidth * 0.036,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: screenHeight * 0.006,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: screenWidth * 0.018,
                          ),
                          overlayShape: RoundSliderOverlayShape(
                            overlayRadius: screenWidth * 0.035,
                          ),
                        ),
                        child: Slider(
                          value:
                              (userProvider.userSettings?.pickupReminderHours ??
                                      24)
                                  .toDouble(),
                          min: 8,
                          max: 48,
                          divisions: 20,
                          activeColor: AppTheme.primary,
                          inactiveColor: AppTheme.surfaceVariant,
                          onChanged: (val) async {
                            final settings = userProvider.userSettings ??
                                UserSettings(
                                  userId: userProvider.currentUser?.id ?? '',
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                );
                            final updatedSettings = settings.copyWith(
                                pickupReminderHours: val.round());
                            await userProvider
                                .updateUserSettings(updatedSettings);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: verticalSpacing * 1.2),

                // Drying Time Alerts Card
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.035),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: screenWidth * 0.11,
                            height: screenWidth * 0.11,
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.025),
                            ),
                            child: Icon(
                              Icons.wb_sunny_outlined,
                              color: AppTheme.accent,
                              size: screenWidth * 0.055,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Drying Time Alerts',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.042,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'AI-powered alerts based on weather data',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.03,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value:
                                  true, // Default to enabled for now (not in settings model yet)
                              onChanged: (val) async {
                                // TODO: Add this to settings model later
                                // For now, it will be enabled
                              },
                              activeColor: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.06),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.012,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Alert Sensitivity',
                              style: TextStyle(
                                fontSize: screenWidth * 0.036,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Standard', // Default value (not in settings model yet)
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.036,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: screenWidth * 0.045,
                                  color: AppTheme.textTertiary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: verticalSpacing * 1.2),

                // Missing Item Alerts Card
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.035),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: screenWidth * 0.11,
                            height: screenWidth * 0.11,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.025),
                            ),
                            child: Icon(
                              Icons.search,
                              color: AppTheme.primary,
                              size: screenWidth * 0.055,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Text(
                              'Missing Item Alerts',
                              style: TextStyle(
                                fontSize: screenWidth * 0.042,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value:
                                  true, // Default to enabled for now (not in settings model yet)
                              onChanged: (val) async {
                                // TODO: Add this to settings model later
                              },
                              activeColor: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Alert if missing for',
                            style: TextStyle(
                              fontSize: screenWidth * 0.036,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '1 day', // Default value (not in settings model yet)
                            style: TextStyle(
                              fontSize: screenWidth * 0.036,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: screenHeight * 0.006,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: screenWidth * 0.018,
                          ),
                          overlayShape: RoundSliderOverlayShape(
                            overlayRadius: screenWidth * 0.035,
                          ),
                        ),
                        child: Slider(
                          value:
                              1.0, // Default value (not in settings model yet)
                          min: 1,
                          max: 7,
                          divisions: 6,
                          activeColor: AppTheme.primary,
                          inactiveColor: AppTheme.surfaceVariant,
                          onChanged: (val) async {
                            // TODO: Add this to settings model later
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: verticalSpacing * 1.2),

                // Auto-compose WhatsApp Card
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.035),
                  child: Row(
                    children: [
                      Container(
                        width: screenWidth * 0.09,
                        height: screenWidth * 0.09,
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondary.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.02),
                        ),
                        child: Icon(
                          Icons.message,
                          color: AppTheme.textSecondary,
                          size: screenWidth * 0.045,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Text(
                          'Auto-compose WhatsApp message',
                          style: TextStyle(
                            fontSize: screenWidth * 0.038,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value:
                              false, // Default to disabled for now (not in settings model yet)
                          onChanged: (val) async {
                            // TODO: Add this to settings model later
                          },
                          activeColor: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
