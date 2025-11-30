import 'package:flutter/material.dart';

/// Category Model for laundry items
/// Provides a type-safe representation of categories with icon support
class Category {
  final String id;
  final String name;
  final String iconName;
  final bool isActive;
  final int sortOrder;

  Category({
    required this.id,
    required this.name,
    required this.iconName,
    this.isActive = true,
    this.sortOrder = 0,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': iconName,
        'is_active': isActive,
        'sort_order': sortOrder,
      };

  /// Create from JSON
  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        iconName: json['icon'] as String? ?? 'checkroom_outlined',
        isActive: json['is_active'] as bool? ?? true,
        sortOrder: json['sort_order'] as int? ?? 0,
      );

  /// Create a copy with optional updates
  Category copyWith({
    String? id,
    String? name,
    String? iconName,
    bool? isActive,
    int? sortOrder,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        iconName: iconName ?? this.iconName,
        isActive: isActive ?? this.isActive,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  /// Get Material Icon from icon name string
  IconData get icon => _getIconFromString(iconName);

  static IconData _getIconFromString(String iconName) {
    switch (iconName) {
      // Upper wear
      case 'checkroom':
        return Icons.checkroom;
      case 'checkroom_outlined':
        return Icons.checkroom_outlined;
      case 'dry_cleaning':
        return Icons.dry_cleaning;
      case 'dry_cleaning_outlined':
        return Icons.dry_cleaning_outlined;
      case 'person':
        return Icons.person;

      // Lower wear
      case 'airline_seat_legroom_normal':
        return Icons.airline_seat_legroom_normal;
      case 'fitness_center_outlined':
        return Icons.fitness_center_outlined;
      case 'sports':
        return Icons.sports;
      case 'accessibility':
        return Icons.accessibility;

      // Accessories & Others
      case 'local_offer_outlined':
        return Icons.local_offer_outlined;
      case 'bed_outlined':
        return Icons.bed_outlined;
      case 'bed':
        return Icons.bed;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'badge':
        return Icons.badge;
      case 'watch':
        return Icons.watch;
      case 'backpack':
        return Icons.backpack;

      default:
        return Icons.checkroom_outlined;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Category(id: $id, name: $name, icon: $iconName, active: $isActive, order: $sortOrder)';
}

/// Predefined icon options for categories
class CategoryIcons {
  static final List<Map<String, dynamic>> availableIcons = [
    {'name': 'checkroom', 'icon': Icons.checkroom, 'label': 'Shirt'},
    {
      'name': 'checkroom_outlined',
      'icon': Icons.checkroom_outlined,
      'label': 'Shirt (Outline)'
    },
    {
      'name': 'dry_cleaning',
      'icon': Icons.dry_cleaning,
      'label': 'Dry Cleaning'
    },
    {
      'name': 'dry_cleaning_outlined',
      'icon': Icons.dry_cleaning_outlined,
      'label': 'Dry Cleaning (Outline)'
    },
    {'name': 'person', 'icon': Icons.person, 'label': 'Person'},
    {
      'name': 'airline_seat_legroom_normal',
      'icon': Icons.airline_seat_legroom_normal,
      'label': 'Pants'
    },
    {
      'name': 'fitness_center_outlined',
      'icon': Icons.fitness_center_outlined,
      'label': 'Shorts'
    },
    {'name': 'sports', 'icon': Icons.sports, 'label': 'Sports'},
    {'name': 'accessibility', 'icon': Icons.accessibility, 'label': 'Clothing'},
    {
      'name': 'local_offer_outlined',
      'icon': Icons.local_offer_outlined,
      'label': 'Tag'
    },
    {'name': 'bed_outlined', 'icon': Icons.bed_outlined, 'label': 'Bed'},
    {'name': 'bed', 'icon': Icons.bed, 'label': 'Bed (Filled)'},
    {'name': 'ac_unit', 'icon': Icons.ac_unit, 'label': 'Socks'},
    {'name': 'badge', 'icon': Icons.badge, 'label': 'Badge'},
    {'name': 'watch', 'icon': Icons.watch, 'label': 'Watch'},
    {'name': 'backpack', 'icon': Icons.backpack, 'label': 'Backpack'},
  ];

  static IconData getIcon(String iconName) =>
      Category._getIconFromString(iconName);

  static String getIconName(IconData icon) {
    final match = availableIcons.firstWhere(
      (item) => item['icon'] == icon,
      orElse: () => {'name': 'checkroom_outlined'},
    );
    return match['name'] as String;
  }
}
