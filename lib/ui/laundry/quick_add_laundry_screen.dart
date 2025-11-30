import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';
import '../../providers/user_provider.dart';
import '../categories/manage_categories_screen.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_utils.dart';

class AppColors {
  static const primary = Color(0xFF4A6FFF);
  static const secondary = Color(0xFFA3B4FF);
  static const accent = Color(0xFF6EE7B7);
  static const bg = Color(0xFFF8FAFC);
  static const card = Color(0xFFFFFFFF);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
}

class QuickAddLaundryScreen extends StatefulWidget {
  const QuickAddLaundryScreen({super.key});

  @override
  State<QuickAddLaundryScreen> createState() => _QuickAddLaundryScreenState();
}

class _QuickAddLaundryScreenState extends State<QuickAddLaundryScreen> {
  Map<String, int> counts = {};
  bool _isLoading = false;
  late ResponsiveUtils responsive;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    responsive = ResponsiveUtils(context);
  }

  @override
  void initState() {
    super.initState();
    _initializeCategories();
  }

  Future<void> _initializeCategories() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Load categories if not already loaded
    if (userProvider.categories.isEmpty) {
      await userProvider.loadCategories();
    }

    final categories = userProvider.getCategoryNames();
    counts = {for (var cat in categories) cat: 0};
    if (mounted) setState(() {});
  }

  // Helper to get icon from icon name string
  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'checkroom':
        return Icons.checkroom;
      case 'checkroom_outlined':
        return Icons.checkroom_outlined;
      case 'airline_seat_legroom_normal':
        return Icons.airline_seat_legroom_normal;
      case 'fitness_center_outlined':
        return Icons.fitness_center_outlined;
      case 'dry_cleaning_outlined':
        return Icons.dry_cleaning_outlined;
      case 'local_offer_outlined':
        return Icons.local_offer_outlined;
      case 'bed_outlined':
        return Icons.bed_outlined;
      default:
        return Icons.checkroom_outlined;
    }
  }

  int get total =>
      counts.values.isNotEmpty ? counts.values.reduce((a, b) => a + b) : 0;

  void _resetCounts() {
    setState(() {
      for (var key in counts.keys) {
        counts[key] = 0;
      }
    });
    HapticFeedback.lightImpact(); // Haptic feedback
  }

  Future<void> _saveWashEntry() async {
    if (total == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    // Confirmation for large counts
    if (total > 20) {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Large Entry',
                  style: TextStyle(fontSize: responsive.fontSize(20))),
              content: Text('You\'re adding $total items. Continue?',
                  style: TextStyle(fontSize: responsive.fontSize(16))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Continue')),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.currentUser?.id ?? 'demo_user';
      final now = DateTime.now();

      // Save to local storage
      final washData = {
        'user_id': userId,
        'dhobi_name': 'Quick Laundry Service',
        'status': 'given',
        'given_at': now.toIso8601String(),
        'expected_return_at':
            now.add(const Duration(days: 3)).toIso8601String(),
        'returned_at': null,
        'notes':
            'Quick add entry with counts: ${counts.entries.where((e) => e.value > 0).map((e) => '${e.key}: ${e.value}').join(', ')}',
        'total_items_given': total,
        'total_items_returned': 0,
        'total_missing': 0,
        'total_extra': 0,
        'risk_level': null,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      await LocalStorageService.addWash(userId, washData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wash entry saved successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quick Add Laundry',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [],
      ),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [

              // ---- Total Items Card ----
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin:
                    responsive.padding(horizontal: 16, vertical: 8), // Reduced
                padding:
                    responsive.padding(horizontal: 16, vertical: 12), // Reduced
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(
                      responsive.size(18)), // Smaller radius
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withOpacity(total > 0 ? 0.12 : 0.09),
                      blurRadius: responsive.size(20), // Smaller shadow
                      spreadRadius:
                          total > 0 ? -responsive.size(3) : -responsive.size(8),
                      offset: Offset(0, responsive.height(6)), // Smaller
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: responsive.size(8), // Smaller
                      spreadRadius: -responsive.size(6),
                      offset: Offset(0, responsive.height(3)),
                    ),
                  ],
                  border: total > 0
                      ? Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.primary,
                          size: responsive.iconSize(20), // Smaller
                        ),
                        SizedBox(width: responsive.width(6)), // Smaller
                        Text("Total Items",
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: responsive.fontSize(16), // Smaller
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Text(
                        "$total",
                        key: ValueKey<int>(total),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: responsive.fontSize(28), // Smaller
                          fontWeight: FontWeight.w800,
                          color: total > 0
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ---- Categories & Manage ----
              Padding(
                padding:
                    responsive.padding(horizontal: 20, vertical: 4), // Reduced
                child: Row(
                  children: [
                    Text("YOUR CATEGORIES",
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: responsive.fontSize(12), // Smaller
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.0)), // Smaller
                    const Spacer(),
                    InkWell(
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const ManageCategoriesScreen()));
                        // Categories will auto-refresh due to provider updates
                      },
                      child: Row(
                        children: [
                          Icon(Icons.style_rounded,
                              color: AppColors.primary,
                              size: responsive.iconSize(18)), // Smaller
                          SizedBox(width: responsive.width(3)), // Smaller
                          Text("Manage Categories",
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: responsive.fontSize(14), // Smaller
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ---- Category List (Dynamic from UserProvider) ----
              Expanded(
                child: Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    // Get active categories in order from provider
                    final categoriesData = userProvider.categories
                        .where((c) => c['is_active'] as bool? ?? true)
                        .toList();

                    // Update counts map when categories change
                    final categoryNames =
                        categoriesData.map((c) => c['name'] as String).toList();
                    for (var name in categoryNames) {
                      if (!counts.containsKey(name)) {
                        counts[name] = 0;
                      }
                    }

                    // Remove old categories that no longer exist
                    counts.removeWhere(
                        (key, value) => !categoryNames.contains(key));

                    return ListView.builder(
                      itemCount: categoriesData.length,
                      padding: responsive.padding(
                          horizontal: 16, vertical: 2), // Reduced
                      itemBuilder: (context, i) {
                        final categoryData = categoriesData[i];
                        final cat = categoryData['name'] as String;
                        final iconName = categoryData['icon'] as String?;
                        final icon = _getIcon(iconName);
                        final value = counts[cat] ?? 0;

                        return Container(
                          margin: responsive.verticalPadding(5), // Reduced
                          padding: responsive.horizontalPadding(10), // Reduced
                          height: responsive.height(60), // Smaller height
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(
                                responsive.size(18)), // Smaller
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: responsive.size(12), // Smaller
                                spreadRadius: -1,
                                offset:
                                    Offset(0, responsive.height(3)), // Smaller
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Category name with icon
                              Row(
                                children: [
                                  Icon(icon,
                                      color: AppColors.primary,
                                      size: responsive.iconSize(20)), // Smaller
                                  SizedBox(
                                      width: responsive.width(10)), // Smaller
                                  Text(
                                    cat,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize:
                                          responsive.fontSize(16), // Smaller
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  // Minus button
                                  _RoundActionButton(
                                    icon: Icons.remove,
                                    bg: AppColors.secondary.withOpacity(0.18),
                                    iconColor: AppColors.primary,
                                    responsive: responsive,
                                    onTap: () {
                                      setState(() {
                                        counts[cat] = (counts[cat] ?? 0) <= 0
                                            ? 0
                                            : (counts[cat]! - 1);
                                      });
                                    },
                                  ),
                                  SizedBox(
                                    width: responsive.width(32), // Smaller
                                    child: Text(
                                      value.toString(),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize:
                                            responsive.fontSize(20), // Smaller
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  // Plus button
                                  _RoundActionButton(
                                    icon: Icons.add,
                                    bg: AppColors.primary,
                                    iconColor: Colors.white,
                                    shadow: AppColors.primary.withOpacity(0.22),
                                    responsive: responsive,
                                    onTap: () {
                                      setState(() {
                                        counts[cat] = (counts[cat] ?? 0) + 1;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // ---- Save and Cancel Buttons ----
              Padding(
                padding:
                    responsive.padding(horizontal: 16, vertical: 6), // Reduced
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                              responsive.size(14)), // Smaller
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.18),
                              blurRadius: responsive.size(14), // Smaller
                              offset:
                                  Offset(0, responsive.height(6)), // Smaller
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isLoading ? null : _saveWashEntry,
                            borderRadius: BorderRadius.circular(
                                responsive.size(14)), // Smaller
                            child: Container(
                              padding:
                                  responsive.verticalPadding(14), // Smaller
                              alignment: Alignment.center,
                              constraints: BoxConstraints(
                                  minHeight: responsive.height(45)), // Smaller
                              child: _isLoading
                                  ? SizedBox(
                                      height: responsive.size(20), // Smaller
                                      width: responsive.size(20), // Smaller
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "Save Wash Entry",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize:
                                            responsive.fontSize(16), // Smaller
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.height(6)), // Smaller
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _resetCounts,
                          child: Text(
                            "Reset Counts",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: responsive.fontSize(15),
                              fontWeight: FontWeight.w500,
                              color: total > 0
                                  ? AppTheme.primary.withOpacity(0.8)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: responsive.width(16)),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: responsive.fontSize(15),
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.height(10)), // Smaller
            ],
          ),
        ),
      ),
    );
  }
}

// Action Button Widget (+/-)
class _RoundActionButton extends StatefulWidget {
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final Color? shadow;
  final VoidCallback onTap;
  final ResponsiveUtils responsive;

  const _RoundActionButton({
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.onTap,
    required this.responsive,
    this.shadow,
  });

  @override
  State<_RoundActionButton> createState() => _RoundActionButtonState();
}

class _RoundActionButtonState extends State<_RoundActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    HapticFeedback.lightImpact(); // Haptic feedback
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.responsive.size(40), // Smaller
            height: widget.responsive.size(40), // Smaller
            margin: widget.responsive.horizontalPadding(2),
            decoration: BoxDecoration(
              color: widget.bg,
              borderRadius: BorderRadius.circular(999),
              boxShadow: widget.shadow != null
                  ? [
                      BoxShadow(
                          color: widget.shadow!,
                          blurRadius: widget.responsive.size(10), // Smaller
                          offset: Offset(0, widget.responsive.height(4)))
                    ] // Smaller
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _handleTap,
                splashColor: widget.iconColor.withOpacity(0.2),
                highlightColor: widget.iconColor.withOpacity(0.1),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: widget.responsive.iconSize(24), // Smaller
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
