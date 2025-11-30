/// User settings and preferences
class UserSettings {
  final String userId;
  final int reminderDays;
  final int pickupReminderHours;
  final bool enableNotifications;
  final bool enablePushNotifications;
  final bool enableMissingItemAlerts;
  final bool enablePickupTimerAlerts;
  final bool enableDryingTimeAlerts;
  final bool autoComposeWhatsAppMessage;
  final String dryingAlertSensitivity;
  final int missingItemAlertDays;
  final bool enableCloudBackup;
  final bool enableOfflineMode;
  final bool showOnboarding;
  final String? lastSyncedAt;
  final String? fcmToken;
  final DateTime? fcmTokenUpdatedAt;
  final Map<String, bool> categoryVisibility;
  final List<String> customCategories;
  final String? preferredDhobi;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    required this.userId,
    this.reminderDays = 3,
    this.pickupReminderHours = 24,
    this.enableNotifications = true,
    this.enablePushNotifications = true,
    this.enableMissingItemAlerts = true,
    this.enablePickupTimerAlerts = true,
    this.enableDryingTimeAlerts = false,
    this.autoComposeWhatsAppMessage = false,
    this.dryingAlertSensitivity = 'Standard',
    this.missingItemAlertDays = 1,
    this.enableCloudBackup = true,
    this.enableOfflineMode = true,
    this.showOnboarding = true,
    this.lastSyncedAt,
    this.fcmToken,
    this.fcmTokenUpdatedAt,
    this.categoryVisibility = const {},
    this.customCategories = const [],
    this.preferredDhobi,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'reminderDays': reminderDays,
        'pickupReminderHours': pickupReminderHours,
        'enableNotifications': enableNotifications,
        'enablePushNotifications': enablePushNotifications,
        'enableMissingItemAlerts': enableMissingItemAlerts,
        'enablePickupTimerAlerts': enablePickupTimerAlerts,
        'enableDryingTimeAlerts': enableDryingTimeAlerts,
        'autoComposeWhatsAppMessage': autoComposeWhatsAppMessage,
        'dryingAlertSensitivity': dryingAlertSensitivity,
        'missingItemAlertDays': missingItemAlertDays,
        'enableCloudBackup': enableCloudBackup,
        'enableOfflineMode': enableOfflineMode,
        'showOnboarding': showOnboarding,
        'lastSyncedAt': lastSyncedAt,
        'fcmToken': fcmToken,
        'fcmTokenUpdatedAt': fcmTokenUpdatedAt?.toIso8601String(),
        'categoryVisibility': categoryVisibility,
        'customCategories': customCategories,
        'preferredDhobi': preferredDhobi,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        userId: json['userId'] as String,
        reminderDays: json['reminderDays'] as int? ?? 3,
        pickupReminderHours: json['pickupReminderHours'] as int? ?? 24,
        enableNotifications: json['enableNotifications'] as bool? ?? true,
        enablePushNotifications:
            json['enablePushNotifications'] as bool? ?? true,
        enableMissingItemAlerts:
            json['enableMissingItemAlerts'] as bool? ?? true,
        enablePickupTimerAlerts:
            json['enablePickupTimerAlerts'] as bool? ?? true,
        enableDryingTimeAlerts:
            json['enableDryingTimeAlerts'] as bool? ?? false,
        autoComposeWhatsAppMessage:
            json['autoComposeWhatsAppMessage'] as bool? ?? false,
        dryingAlertSensitivity:
            json['dryingAlertSensitivity'] as String? ?? 'Standard',
        missingItemAlertDays: json['missingItemAlertDays'] as int? ?? 1,
        enableCloudBackup: json['enableCloudBackup'] as bool? ?? true,
        enableOfflineMode: json['enableOfflineMode'] as bool? ?? true,
        showOnboarding: json['showOnboarding'] as bool? ?? true,
        lastSyncedAt: json['lastSyncedAt'] as String?,
        fcmToken: json['fcmToken'] as String?,
        fcmTokenUpdatedAt: json['fcmTokenUpdatedAt'] != null
            ? DateTime.parse(json['fcmTokenUpdatedAt'] as String)
            : null,
        categoryVisibility: json['categoryVisibility'] != null
            ? Map<String, bool>.from(json['categoryVisibility'] as Map)
            : {},
        customCategories: json['customCategories'] != null
            ? (json['customCategories'] as List).cast<String>()
            : [],
        preferredDhobi: json['preferredDhobi'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  UserSettings copyWith({
    String? userId,
    int? reminderDays,
    int? pickupReminderHours,
    bool? enableNotifications,
    bool? enablePushNotifications,
    bool? enableMissingItemAlerts,
    bool? enablePickupTimerAlerts,
    bool? enableDryingTimeAlerts,
    bool? autoComposeWhatsAppMessage,
    String? dryingAlertSensitivity,
    int? missingItemAlertDays,
    bool? enableCloudBackup,
    bool? enableOfflineMode,
    bool? showOnboarding,
    String? lastSyncedAt,
    String? fcmToken,
    DateTime? fcmTokenUpdatedAt,
    Map<String, bool>? categoryVisibility,
    List<String>? customCategories,
    String? preferredDhobi,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserSettings(
        userId: userId ?? this.userId,
        reminderDays: reminderDays ?? this.reminderDays,
        pickupReminderHours: pickupReminderHours ?? this.pickupReminderHours,
        enableNotifications: enableNotifications ?? this.enableNotifications,
        enablePushNotifications:
            enablePushNotifications ?? this.enablePushNotifications,
        enableMissingItemAlerts:
            enableMissingItemAlerts ?? this.enableMissingItemAlerts,
        enablePickupTimerAlerts:
            enablePickupTimerAlerts ?? this.enablePickupTimerAlerts,
        enableDryingTimeAlerts:
            enableDryingTimeAlerts ?? this.enableDryingTimeAlerts,
        autoComposeWhatsAppMessage:
            autoComposeWhatsAppMessage ?? this.autoComposeWhatsAppMessage,
        dryingAlertSensitivity:
            dryingAlertSensitivity ?? this.dryingAlertSensitivity,
        missingItemAlertDays: missingItemAlertDays ?? this.missingItemAlertDays,
        enableCloudBackup: enableCloudBackup ?? this.enableCloudBackup,
        enableOfflineMode: enableOfflineMode ?? this.enableOfflineMode,
        showOnboarding: showOnboarding ?? this.showOnboarding,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        fcmToken: fcmToken ?? this.fcmToken,
        fcmTokenUpdatedAt: fcmTokenUpdatedAt ?? this.fcmTokenUpdatedAt,
        categoryVisibility: categoryVisibility ?? this.categoryVisibility,
        customCategories: customCategories ?? this.customCategories,
        preferredDhobi: preferredDhobi ?? this.preferredDhobi,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Dhobi risk assessment
class DhobiRisk {
  final String dhobiName;
  final int totalWashes;
  final int totalMissing;
  final double missRate;
  final Map<String, int> frequentlyMissing;
  final RiskLevel riskLevel;
  final DateTime lastWashAt;

  DhobiRisk({
    required this.dhobiName,
    required this.totalWashes,
    required this.totalMissing,
    required this.missRate,
    required this.frequentlyMissing,
    required this.riskLevel,
    required this.lastWashAt,
  });

  Map<String, dynamic> toJson() => {
        'dhobiName': dhobiName,
        'totalWashes': totalWashes,
        'totalMissing': totalMissing,
        'missRate': missRate,
        'frequentlyMissing': frequentlyMissing,
        'riskLevel': riskLevel.name,
        'lastWashAt': lastWashAt.toIso8601String(),
      };

  factory DhobiRisk.fromJson(Map<String, dynamic> json) => DhobiRisk(
        dhobiName: json['dhobiName'] as String,
        totalWashes: json['totalWashes'] as int,
        totalMissing: json['totalMissing'] as int,
        missRate: (json['missRate'] as num).toDouble(),
        frequentlyMissing:
            Map<String, int>.from(json['frequentlyMissing'] as Map),
        riskLevel: RiskLevel.values.firstWhere(
          (level) => level.name == json['riskLevel'], 
          orElse: () => RiskLevel.low,
        ),
        lastWashAt: DateTime.parse(json['lastWashAt'] as String),
      );
}

enum RiskLevel {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
    }
  }
}
