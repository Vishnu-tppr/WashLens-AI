import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Manage Categories Screen
class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final List<Map<String, dynamic>> _categories = [
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: AppTheme.surface,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacing20),
            color: AppTheme.surfaceVariant,
            child: Text(
              'Drag to reorder, swipe left to delete.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              itemCount: _categories.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex--;
                  }
                  final item = _categories.removeAt(oldIndex);
                  _categories.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Dismissible(
                  key: Key(category['name'] as String),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(AppTheme.radius16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppTheme.spacing20),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  onDismissed: (direction) {
                    setState(() {
                      _categories.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${category['name']} deleted'),
                        action: SnackBarAction(
                          label: 'UNDO',
                          onPressed: () {
                            setState(() {
                              _categories.insert(index, category);
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radius16),
                      boxShadow: AppTheme.shadow1,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                        vertical: AppTheme.spacing8,
                      ),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.drag_indicator,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius12,
                              ),
                            ),
                            child: Icon(
                              category['icon'] as IconData,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        category['name'] as String,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          category['visible'] as bool
                              ? Icons.visibility
                              : Icons.visibility_off_outlined,
                          color: category['visible'] as bool
                              ? AppTheme.primary
                              : AppTheme.textTertiary,
                        ),
                        onPressed: () {
                          setState(() {
                            category['visible'] =
                                !(category['visible'] as bool);
                          });
                        },
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
        onPressed: () {
          _showAddCategoryDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g., Hoodies'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _categories.add({
                    'name': controller.text,
                    'visible': true,
                    'icon': Icons.checkroom_outlined,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
