import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/category_model.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_utils.dart';

/// Manage Categories Screen
class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  late ResponsiveUtils responsive;
  bool _isLoading = false;

  // Default categories for easy use
  final List<Map<String, dynamic>> _defaultCategories = [
    {'name': 'Shirts', 'visible': true, 'icon': Icons.checkroom},
    {'name': 'T-shirts', 'visible': false, 'icon': Icons.checkroom_outlined},
    {
      'name': 'Pants',
      'visible': true,
      'icon': Icons.airline_seat_legroom_normal,
    },
    {'name': 'Shorts', 'visible': true, 'icon': Icons.fitness_center_outlined},
    {'name': 'Towels', 'visible': true, 'icon': Icons.dry_cleaning_outlined},
    {'name': 'Socks', 'visible': true, 'icon': Icons.local_offer_outlined},
    {'name': 'Bedsheets', 'visible': true, 'icon': Icons.bed_outlined},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    responsive = ResponsiveUtils(context);
    _initializeCategories();
  }

  Future<void> _initializeCategories() async {
    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Load existing categories from database and sync with local categories
      await userProvider.loadCategories();

      // Sync visibility and icon data to match database
      final dbCategories = userProvider.categories;
      for (var localCat in _defaultCategories) {
        final dbCat = dbCategories.firstWhere(
          (cat) => cat['name'] == localCat['name'],
          orElse: () => {},
        );
        if (dbCat.isNotEmpty) {
          localCat['id'] = dbCat['id'];
          localCat['visible'] = dbCat['is_active'] ?? true;
          localCat['iconName'] = dbCat['icon'] ?? 'checkroom_outlined';
        }
      }
    } catch (e) {
      debugPrint('Error initializing categories: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'checkroom':
        return Icons.checkroom;
      case 'checkroom_outlined':
        return Icons.checkroom_outlined;
      case 'person':
        return Icons.person;
      case 'dry_cleaning':
        return Icons.dry_cleaning;
      case 'bed':
        return Icons.bed;
      case 'accessibility':
        return Icons.accessibility;
      case 'airline_seat_legroom_normal':
        return Icons.airline_seat_legroom_normal;
      case 'fitness_center_outlined':
        return Icons.fitness_center_outlined;
      case 'local_offer_outlined':
        return Icons.local_offer_outlined;
      default:
        return Icons.checkroom;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Manage Categories',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: responsive.allPadding(20),
                  color: AppTheme.surfaceVariant,
                  child: Text(
                    'Drag to reorder, swipe left to delete categories.',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14, min: 12, max: 16),
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: responsive.allPadding(16),
                    itemCount: _defaultCategories.length,
                    proxyDecorator: (child, index, animation) => Material(
                      elevation: responsive.elevation(8),
                      borderRadius: responsive.borderRadius(16),
                      child: child,
                    ),
                    onReorder: (oldIndex, newIndex) async {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex--;
                        }
                        final item = _defaultCategories.removeAt(oldIndex);
                        _defaultCategories.insert(newIndex, item);
                      });

                      // Sync reorder to database
                      try {
                        final userProvider =
                            Provider.of<UserProvider>(context, listen: false);
                        await userProvider.updateCategoryOrder(
                            oldIndex, newIndex);

                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Order updated',
                              style:
                                  TextStyle(fontSize: responsive.fontSize(14)),
                            ),
                            duration: const Duration(seconds: 1),
                            backgroundColor: AppTheme.primary.withOpacity(0.9),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to reorder categories',
                              style:
                                  TextStyle(fontSize: responsive.fontSize(14)),
                            ),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    },
                    itemBuilder: (context, index) {
                      final category = _defaultCategories[index];
                      final categoryName = category['name'] as String;
                      final isActive = category['visible'] as bool? ?? true;
                      final categoryId = category['id'];

                      return Container(
                        key: Key('$categoryName-$index'),
                        margin: EdgeInsets.only(bottom: responsive.height(12)),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: responsive.borderRadius(16),
                          boxShadow: AppTheme.shadow1,
                          border: Border.all(
                            color: isActive
                                ? Colors.transparent
                                : AppTheme.surfaceVariant,
                            width: isActive ? 0 : 1,
                          ),
                        ),
                        child: Dismissible(
                          key: Key('dismiss-$categoryName-$index'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              borderRadius: responsive.borderRadius(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: responsive.horizontalPadding(20),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: responsive.iconSize(28),
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            // No dialog - just return true to allow dismiss
                            return true;
                          },
                          onDismissed: (direction) async {
                            // Store deleted data for undo
                            final deletedCategory =
                                Map<String, dynamic>.from(category);
                            final deletedIndex = index;

                            // Remove from local list
                            setState(() {
                              _defaultCategories.removeAt(deletedIndex);
                            });

                            if (categoryId != null) {
                              try {
                                final userProvider = Provider.of<UserProvider>(
                                    context,
                                    listen: false);
                                await userProvider.deleteCategory(categoryId);

                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '"$categoryName" deleted',
                                      style: TextStyle(
                                          fontSize: responsive.fontSize(14)),
                                    ),
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      textColor: Colors.white,
                                      onPressed: () async {
                                        try {
                                          final userProvider =
                                              Provider.of<UserProvider>(context,
                                                  listen: false);
                                          final iconName =
                                              deletedCategory['iconName']
                                                      as String? ??
                                                  'checkroom_outlined';
                                          await userProvider.addCategory(
                                              categoryName,
                                              iconName: iconName);

                                          // Reload categories to get the new ID
                                          await userProvider.loadCategories();

                                          // Re-add to local list
                                          setState(() {
                                            _defaultCategories.insert(
                                                deletedIndex, deletedCategory);
                                          });

                                          ScaffoldMessenger.of(context)
                                              .clearSnackBars();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '"$categoryName" restored',
                                                style: TextStyle(
                                                    fontSize: responsive
                                                        .fontSize(14)),
                                              ),
                                              backgroundColor: AppTheme.primary,
                                              duration:
                                                  const Duration(seconds: 2),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to restore category',
                                                style: TextStyle(
                                                    fontSize: responsive
                                                        .fontSize(14)),
                                              ),
                                              backgroundColor: AppTheme.error,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    duration: const Duration(seconds: 5),
                                    backgroundColor: AppTheme.textPrimary,
                                  ),
                                );
                              } catch (e) {
                                // Restore on error
                                setState(() {
                                  _defaultCategories.insert(
                                      deletedIndex, deletedCategory);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to delete category',
                                      style: TextStyle(
                                          fontSize: responsive.fontSize(14)),
                                    ),
                                    backgroundColor: AppTheme.error,
                                  ),
                                );
                              }
                            }
                          },
                          child: ListTile(
                            contentPadding: responsive.allPadding(16),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.drag_indicator,
                                  color: AppTheme.textTertiary,
                                  size: responsive.iconSize(20),
                                ),
                                SizedBox(width: responsive.width(8)),
                                Container(
                                  width: responsive.size(48),
                                  height: responsive.size(48),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary
                                        .withOpacity(isActive ? 0.1 : 0.05),
                                    borderRadius: responsive.borderRadius(12),
                                  ),
                                  child: Icon(
                                    category['icon'] as IconData,
                                    color: isActive
                                        ? AppTheme.primary
                                        : AppTheme.textTertiary,
                                    size: responsive.iconSize(24),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              categoryName,
                              style: TextStyle(
                                fontSize:
                                    responsive.fontSize(18, min: 16, max: 20),
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? AppTheme.textPrimary
                                    : AppTheme.textTertiary,
                                decoration: isActive
                                    ? null
                                    : TextDecoration.lineThrough,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Edit button
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: AppTheme.textSecondary,
                                    size: responsive.iconSize(20),
                                  ),
                                  tooltip: 'Edit category',
                                  onPressed: () =>
                                      _showEditCategoryDialog(category),
                                ),
                                // Visibility toggle
                                IconButton(
                                  icon: Icon(
                                    isActive
                                        ? Icons.visibility
                                        : Icons.visibility_off_outlined,
                                    color: isActive
                                        ? AppTheme.primary
                                        : AppTheme.textTertiary,
                                    size: responsive.iconSize(24),
                                  ),
                                  tooltip: isActive
                                      ? 'Hide category'
                                      : 'Show category',
                                  onPressed: () async {
                                    setState(() {
                                      category['visible'] = !isActive;
                                    });

                                    if (categoryId != null) {
                                      try {
                                        final userProvider =
                                            Provider.of<UserProvider>(context,
                                                listen: false);
                                        final newVisibility =
                                            category['visible'] as bool;
                                        await userProvider
                                            .updateCategoryVisibility(
                                                categoryId, newVisibility);

                                        ScaffoldMessenger.of(context)
                                            .clearSnackBars();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Category ${newVisibility ? 'shown' : 'hidden'} in QuickAdd',
                                              style: TextStyle(
                                                  fontSize:
                                                      responsive.fontSize(14)),
                                            ),
                                            duration:
                                                const Duration(seconds: 2),
                                            backgroundColor: AppTheme.primary
                                                .withOpacity(0.9),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to update visibility',
                                              style: TextStyle(
                                                  fontSize:
                                                      responsive.fontSize(14)),
                                            ),
                                            backgroundColor: AppTheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(),
        tooltip: 'Add category',
        backgroundColor: AppTheme.primary,
        elevation: responsive.elevation(4),
        child: Icon(
          Icons.add,
          size: responsive.iconSize(24),
          color: Colors.white,
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    late StateSetter dialogSetState;
    bool isAdding = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          dialogSetState = setState;
          return AlertDialog(
            title: Text(
              'Add New Category',
              style: TextStyle(
                fontSize: responsive.fontSize(20, min: 18, max: 24),
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'e.g., Hoodies',
                      labelText: 'Category Name',
                      border: OutlineInputBorder(
                        borderRadius: responsive.borderRadius(12),
                      ),
                      contentPadding: responsive.allPadding(16),
                    ),
                    style: TextStyle(fontSize: responsive.fontSize(16)),
                    autofocus: true,
                    onChanged: (_) => dialogSetState(() {}),
                    enabled: !isAdding,
                  ),
                  SizedBox(height: responsive.height(16)),
                  Text(
                    'Preview:',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: responsive.height(8)),
                  Container(
                    padding: responsive.allPadding(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: responsive.borderRadius(12),
                      border: Border.all(
                        color: controller.text.isNotEmpty
                            ? AppTheme.primary.withOpacity(0.3)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: responsive.size(32),
                          height: responsive.size(32),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.2),
                            borderRadius: responsive.borderRadius(8),
                          ),
                          child: Icon(
                            Icons.checkroom_outlined,
                            color: AppTheme.primary,
                            size: responsive.iconSize(20),
                          ),
                        ),
                        SizedBox(width: responsive.width(12)),
                        Text(
                          controller.text.isEmpty
                              ? 'Category Name'
                              : controller.text,
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.w500,
                            color: controller.text.isEmpty
                                ? Colors.grey
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isAdding ? null : () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: responsive.fontSize(16)),
                ),
              ),
              ElevatedButton(
                onPressed: (controller.text.trim().isNotEmpty && !isAdding)
                    ? () async {
                        dialogSetState(() => isAdding = true);

                        try {
                          final name = controller.text.trim();

                          // Add to local list
                          setState(() {
                            _defaultCategories.add({
                              'name': name,
                              'visible': true,
                              'icon': Icons.checkroom_outlined,
                              'iconName': 'checkroom_outlined',
                            });
                          });

                          // Add to provider/database
                          final userProvider =
                              Provider.of<UserProvider>(context, listen: false);
                          await userProvider.addCategory(name);

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '"$name" added successfully!',
                                  style: TextStyle(
                                      fontSize: responsive.fontSize(14)),
                                ),
                                backgroundColor: AppTheme.primary,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to add category',
                                  style: TextStyle(
                                      fontSize: responsive.fontSize(14)),
                                ),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                          dialogSetState(() => isAdding = false);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: responsive.horizontalPadding(16).copyWith(
                        top: responsive.height(12),
                        bottom: responsive.height(12),
                      ),
                  shape: RoundedRectangleBorder(
                    borderRadius: responsive.borderRadius(8),
                  ),
                ),
                child: isAdding
                    ? SizedBox(
                        width: responsive.size(20),
                        height: responsive.size(20),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Add Category',
                        style: TextStyle(
                          fontSize: responsive.fontSize(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    final controller = TextEditingController(text: category['name'] as String);
    late StateSetter dialogSetState;
    bool isSaving = false;
    String? selectedIconName =
        category['iconName'] as String? ?? 'checkroom_outlined';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          dialogSetState = setState;
          return AlertDialog(
            title: Text(
              'Edit Category',
              style: TextStyle(
                fontSize: responsive.fontSize(20, min: 18, max: 24),
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(
                        borderRadius: responsive.borderRadius(12),
                      ),
                      contentPadding: responsive.allPadding(16),
                    ),
                    style: TextStyle(fontSize: responsive.fontSize(16)),
                    enabled: !isSaving,
                    onChanged: (_) => dialogSetState(() {}),
                  ),
                  SizedBox(height: responsive.height(20)),
                  Text(
                    'Select Icon:',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: responsive.height(12)),
                  _buildIconPicker(selectedIconName, (iconName) {
                    dialogSetState(() {
                      selectedIconName = iconName;
                    });
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: responsive.fontSize(16)),
                ),
              ),
              ElevatedButton(
                onPressed: (controller.text.trim().isNotEmpty && !isSaving)
                    ? () async {
                        if (category['id'] == null) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Cannot edit default category',
                                  style: TextStyle(
                                      fontSize: responsive.fontSize(14)),
                                ),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                          return;
                        }

                        dialogSetState(() => isSaving = true);

                        try {
                          final name = controller.text.trim();
                          final categoryId = category['id'] as String;

                          // Update in provider
                          final userProvider =
                              Provider.of<UserProvider>(context, listen: false);
                          await userProvider.updateCategory(
                            categoryId,
                            name: name,
                            iconName: selectedIconName,
                          );

                          // Update local state
                          setState(() {
                            category['name'] = name;
                            category['iconName'] = selectedIconName;
                            category['icon'] =
                                _getIconFromString(selectedIconName!);
                          });

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Category updated successfully!',
                                  style: TextStyle(
                                      fontSize: responsive.fontSize(14)),
                                ),
                                backgroundColor: AppTheme.primary,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to update category',
                                  style: TextStyle(
                                      fontSize: responsive.fontSize(14)),
                                ),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                          dialogSetState(() => isSaving = false);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: isSaving
                    ? SizedBox(
                        width: responsive.size(20),
                        height: responsive.size(20),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Save',
                        style: TextStyle(
                          fontSize: responsive.fontSize(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIconPicker(
      String? selectedIconName, Function(String) onIconSelected) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: responsive.height(200),
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.surfaceVariant),
        borderRadius: responsive.borderRadius(12),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        padding: responsive.allPadding(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: responsive.width(8),
          mainAxisSpacing: responsive.height(8),
        ),
        itemCount: CategoryIcons.availableIcons.length,
        itemBuilder: (context, index) {
          final iconData = CategoryIcons.availableIcons[index];
          final iconName = iconData['name'] as String;
          final icon = iconData['icon'] as IconData;
          final isSelected = selectedIconName == iconName;

          return InkWell(
            onTap: () => onIconSelected(iconName),
            borderRadius: responsive.borderRadius(8),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withOpacity(0.2)
                    : AppTheme.surfaceVariant.withOpacity(0.3),
                borderRadius: responsive.borderRadius(8),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                size: responsive.iconSize(28),
              ),
            ),
          );
        },
      ),
    );
  }
}
