import 'package:flutter/material.dart';

/// Clothing category definition
class ClothingCategory {
  final String id;
  final String name;
  final String displayName;
  final IconData icon;
  final Color color;
  final bool isVisible;
  final int sortOrder;
  final CategoryGroup group;

  ClothingCategory({
    required this.id,
    required this.name,
    required this.displayName,
    required this.icon,
    required this.color,
    this.isVisible = true,
    required this.sortOrder,
    required this.group,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'displayName': displayName,
    'icon': icon.codePoint,
    'color': color.value,
    'isVisible': isVisible,
    'sortOrder': sortOrder,
    'group': group.name,
  };

  factory ClothingCategory.fromJson(Map<String, dynamic> json) =>
      ClothingCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        displayName: json['displayName'] as String,
        icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
        color: Color(json['color'] as int),
        isVisible: json['isVisible'] as bool? ?? true,
        sortOrder: json['sortOrder'] as int,
        group: CategoryGroup.values.firstWhere(
          (g) => g.name == json['group'],
          orElse: () => CategoryGroup.others,
        ),
      );

  ClothingCategory copyWith({
    String? id,
    String? name,
    String? displayName,
    IconData? icon,
    Color? color,
    bool? isVisible,
    int? sortOrder,
    CategoryGroup? group,
  }) => ClothingCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    displayName: displayName ?? this.displayName,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    isVisible: isVisible ?? this.isVisible,
    sortOrder: sortOrder ?? this.sortOrder,
    group: group ?? this.group,
  );
}

/// Category grouping for organization
enum CategoryGroup {
  upperWear,
  lowerWear,
  others;

  String get displayName {
    switch (this) {
      case CategoryGroup.upperWear:
        return 'Upper Wear';
      case CategoryGroup.lowerWear:
        return 'Lower Wear';
      case CategoryGroup.others:
        return 'Others';
    }
  }
}

/// Default categories
class DefaultCategories {
  static final List<ClothingCategory> categories = [
    // Upper Wear
    ClothingCategory(
      id: 'shirt',
      name: 'shirt',
      displayName: 'Shirts',
      icon: Icons.checkroom,
      color: const Color(0xFF5B9BF3),
      sortOrder: 1,
      group: CategoryGroup.upperWear,
    ),
    ClothingCategory(
      id: 'tshirt',
      name: 'tshirt',
      displayName: 'T-Shirts',
      icon: Icons.dry_cleaning,
      color: const Color(0xFF6FCF97),
      sortOrder: 2,
      group: CategoryGroup.upperWear,
    ),
    ClothingCategory(
      id: 'hoodie',
      name: 'hoodie',
      displayName: 'Hoodies',
      icon: Icons.person,
      color: const Color(0xFFBB6BD9),
      sortOrder: 3,
      group: CategoryGroup.upperWear,
    ),

    // Lower Wear
    ClothingCategory(
      id: 'pants',
      name: 'pants',
      displayName: 'Pants',
      icon: Icons.accessibility,
      color: const Color(0xFFA07AFF),
      sortOrder: 4,
      group: CategoryGroup.lowerWear,
    ),
    ClothingCategory(
      id: 'shorts',
      name: 'shorts',
      displayName: 'Shorts',
      icon: Icons.sports,
      color: const Color(0xFFF2994A),
      sortOrder: 5,
      group: CategoryGroup.lowerWear,
    ),
    ClothingCategory(
      id: 'track_pant',
      name: 'track_pant',
      displayName: 'Track Pants',
      icon: Icons.directions_run,
      color: const Color(0xFF56CCF2),
      sortOrder: 6,
      group: CategoryGroup.lowerWear,
    ),
    ClothingCategory(
      id: 'jeans',
      name: 'jeans',
      displayName: 'Jeans',
      icon: Icons.straighten,
      color: const Color(0xFF2D9CDB),
      sortOrder: 7,
      group: CategoryGroup.lowerWear,
    ),

    // Others
    ClothingCategory(
      id: 'towel',
      name: 'towel',
      displayName: 'Towels',
      icon: Icons.bathtub,
      color: const Color(0xFFFFA07A),
      sortOrder: 8,
      group: CategoryGroup.others,
    ),
    ClothingCategory(
      id: 'socks',
      name: 'socks',
      displayName: 'Socks',
      icon: Icons.ac_unit,
      color: const Color(0xFFEB5757),
      sortOrder: 9,
      group: CategoryGroup.others,
    ),
    ClothingCategory(
      id: 'bedsheet',
      name: 'bedsheet',
      displayName: 'Bedsheets',
      icon: Icons.bed,
      color: const Color(0xFF9B51E0),
      sortOrder: 10,
      group: CategoryGroup.others,
    ),
  ];

  static ClothingCategory? findByName(String name) {
    try {
      return categories.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  static ClothingCategory? findById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
