import 'cloth_item.dart';

/// Main wash entry representing a complete laundry transaction
class WashEntry {
  final String id;
  final String userId;
  final String dhobiName;
  final DateTime givenAt;
  final DateTime? returnedAt;
  final WashStatus status;
  final List<String> givenPhotoUrls;
  final List<String>? returnedPhotoUrls;
  final Map<String, int> givenCounts;
  final Map<String, int>? returnedCounts;
  final List<ClothItem> givenItems;
  final List<ClothItem>? returnedItems;
  final String? notes;
  final List<String>? detectedColors;
  final List<String>? detectedPatterns;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  WashEntry({
    required this.id,
    required this.userId,
    required this.dhobiName,
    required this.givenAt,
    this.returnedAt,
    required this.status,
    required this.givenPhotoUrls,
    this.returnedPhotoUrls,
    required this.givenCounts,
    this.returnedCounts,
    required this.givenItems,
    this.returnedItems,
    this.notes,
    this.detectedColors,
    this.detectedPatterns,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  /// Total items given
  int get totalGiven => givenCounts.values.fold(0, (sum, count) => sum + count);

  /// Total items returned
  int get totalReturned =>
      returnedCounts?.values.fold<int>(0, (sum, count) => sum + count) ?? 0;

  /// Missing items count
  int get totalMissing => totalGiven - totalReturned;

  /// Get missing items by category
  Map<String, int> get missingByCategory {
    if (returnedCounts == null) return {};

    final missing = <String, int>{};
    givenCounts.forEach((category, givenCount) {
      final returnedCount = returnedCounts![category] ?? 0;
      if (givenCount > returnedCount) {
        missing[category] = givenCount - returnedCount;
      }
    });
    return missing;
  }

  /// Get extra items by category
  Map<String, int> get extraByCategory {
    if (returnedCounts == null) return {};

    final extra = <String, int>{};
    returnedCounts!.forEach((category, returnedCount) {
      final givenCount = givenCounts[category] ?? 0;
      if (returnedCount > givenCount) {
        extra[category] = returnedCount - givenCount;
      }
    });
    return extra;
  }

  /// Get matched categories
  List<String> get matchedCategories {
    if (returnedCounts == null) return [];

    return givenCounts.keys
        .where(
          (category) =>
              givenCounts[category] == (returnedCounts![category] ?? 0),
        )
        .toList();
  }

  /// Check if wash is overdue (more than 3 days pending)
  bool get isOverdue {
    if (status != WashStatus.pending) return false;
    return DateTime.now().difference(givenAt).inDays > 3;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'dhobiName': dhobiName,
    'givenAt': givenAt.toIso8601String(),
    'returnedAt': returnedAt?.toIso8601String(),
    'status': status.name,
    'givenPhotoUrls': givenPhotoUrls,
    'returnedPhotoUrls': returnedPhotoUrls,
    'givenCounts': givenCounts,
    'returnedCounts': returnedCounts,
    'givenItems': givenItems.map((item) => item.toJson()).toList(),
    'returnedItems': returnedItems?.map((item) => item.toJson()).toList(),
    'notes': notes,
    'detectedColors': detectedColors,
    'detectedPatterns': detectedPatterns,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isSynced': isSynced,
  };

  factory WashEntry.fromJson(Map<String, dynamic> json) => WashEntry(
    id: json['id'] as String,
    userId: json['userId'] as String,
    dhobiName: json['dhobiName'] as String,
    givenAt: DateTime.parse(json['givenAt'] as String),
    returnedAt: json['returnedAt'] != null
        ? DateTime.parse(json['returnedAt'] as String)
        : null,
    status: WashStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => WashStatus.pending,
    ),
    givenPhotoUrls: (json['givenPhotoUrls'] as List).cast<String>(),
    returnedPhotoUrls: json['returnedPhotoUrls'] != null
        ? (json['returnedPhotoUrls'] as List).cast<String>()
        : null,
    givenCounts: Map<String, int>.from(json['givenCounts'] as Map),
    returnedCounts: json['returnedCounts'] != null
        ? Map<String, int>.from(json['returnedCounts'] as Map)
        : null,
    givenItems: (json['givenItems'] as List)
        .map((item) => ClothItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    returnedItems: json['returnedItems'] != null
        ? (json['returnedItems'] as List)
              .map((item) => ClothItem.fromJson(item as Map<String, dynamic>))
              .toList()
        : null,
    notes: json['notes'] as String?,
    detectedColors: json['detectedColors'] != null
        ? (json['detectedColors'] as List).cast<String>()
        : null,
    detectedPatterns: json['detectedPatterns'] != null
        ? (json['detectedPatterns'] as List).cast<String>()
        : null,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    isSynced: json['isSynced'] as bool? ?? false,
  );

  WashEntry copyWith({
    String? id,
    String? userId,
    String? dhobiName,
    DateTime? givenAt,
    DateTime? returnedAt,
    WashStatus? status,
    List<String>? givenPhotoUrls,
    List<String>? returnedPhotoUrls,
    Map<String, int>? givenCounts,
    Map<String, int>? returnedCounts,
    List<ClothItem>? givenItems,
    List<ClothItem>? returnedItems,
    String? notes,
    List<String>? detectedColors,
    List<String>? detectedPatterns,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) => WashEntry(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    dhobiName: dhobiName ?? this.dhobiName,
    givenAt: givenAt ?? this.givenAt,
    returnedAt: returnedAt ?? this.returnedAt,
    status: status ?? this.status,
    givenPhotoUrls: givenPhotoUrls ?? this.givenPhotoUrls,
    returnedPhotoUrls: returnedPhotoUrls ?? this.returnedPhotoUrls,
    givenCounts: givenCounts ?? this.givenCounts,
    returnedCounts: returnedCounts ?? this.returnedCounts,
    givenItems: givenItems ?? this.givenItems,
    returnedItems: returnedItems ?? this.returnedItems,
    notes: notes ?? this.notes,
    detectedColors: detectedColors ?? this.detectedColors,
    detectedPatterns: detectedPatterns ?? this.detectedPatterns,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isSynced: isSynced ?? this.isSynced,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WashEntry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Wash entry status
enum WashStatus {
  pending,
  partiallyReturned,
  returned,
  completed;

  String get displayName {
    switch (this) {
      case WashStatus.pending:
        return 'Pending';
      case WashStatus.partiallyReturned:
        return 'Partially Returned';
      case WashStatus.returned:
        return 'Returned';
      case WashStatus.completed:
        return 'Completed';
    }
  }
}
