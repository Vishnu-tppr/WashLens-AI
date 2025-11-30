import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../../services/local_storage_service.dart';
import '../../providers/user_provider.dart';

/// App Colors for History Screen
class _HistoryColors {
  static const primary = Color(0xFF4A6FFF);
  static const secondary = Color(0xFFA3B4FF);
  static const accent = Color(0xFF6EE7B7);
  static const bgLight = Color(0xFFF8FAFC);
  static const card = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const danger = Color(0xFFEF4444);
  static const green = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
}

/// History/My Laundry Screen with improved UI
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  String _selectedFilter = 'Date';
  String _searchQuery = '';
  List<Map<String, dynamic>> _allWashes = [];
  List<Map<String, dynamic>> _filteredWashes = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadWashes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
    _filterWashes();
  }

  Future<void> _loadWashes() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.id ?? '';

      if (userId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final washes = await LocalStorageService.getWashes(userId);
      setState(() {
        _allWashes = washes;
        _isLoading = false;
      });

      _filterWashes();
    } catch (e) {
      debugPrint('Error loading washes: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load laundry history: $e'),
            backgroundColor: _HistoryColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _refreshWashes() async {
    if (!mounted) return;

    setState(() => _isRefreshing = true);

    try {
      await _loadWashes();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _filterWashes() {
    final filtered = _allWashes.where((wash) {
      if (_searchQuery.isEmpty) return true;

      final dhobi = (wash['dhobi_name'] ?? wash['dhobiName'] ?? '').toString().toLowerCase();
      final status = (wash['status'] ?? '').toString().toLowerCase();
      final notes = (wash['notes'] ?? '').toString().toLowerCase();

      return dhobi.contains(_searchQuery) || 
             status.contains(_searchQuery) ||
             notes.contains(_searchQuery);
    }).toList();

    setState(() => _filteredWashes = filtered);
    _sortWashes();
  }

  void _sortWashes() {
    _filteredWashes.sort((a, b) {
      final dateA = DateTime.tryParse(a['given_at'] ?? a['givenAt'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['given_at'] ?? b['givenAt'] ?? '') ?? DateTime.now();

      switch (_selectedFilter) {
        case 'Date':
          return dateB.compareTo(dateA); // Newest first
        case 'Dhobi':
          final dhobiA = (a['dhobi_name'] ?? a['dhobiName'] ?? '').toString();
          final dhobiB = (b['dhobi_name'] ?? b['dhobiName'] ?? '').toString();
          return dhobiA.compareTo(dhobiB);
        case 'Missing Items':
          final missingA = (a['total_missing'] ?? a['totalMissing'] ?? 0) as int;
          final missingB = (b['total_missing'] ?? b['totalMissing'] ?? 0) as int;
          if (missingA != missingB) {
            return missingB.compareTo(missingA); // Most missing first
          }
          return dateB.compareTo(dateA);
        default:
          return dateB.compareTo(dateA);
      }
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupWashesByTime() {
    final now = DateTime.now();
    final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));
    final startOfThisMonth = DateTime(now.year, now.month, 1);

    final groups = <String, List<Map<String, dynamic>>>{};

    for (final wash in _filteredWashes) {
      final givenAt = DateTime.tryParse(wash['given_at'] ?? wash['givenAt'] ?? '');
      if (givenAt == null) continue;

      String groupKey;
      if (givenAt.isAfter(startOfThisWeek)) {
        groupKey = 'This Week';
      } else if (givenAt.isAfter(startOfLastWeek)) {
        groupKey = 'Last Week';
      } else if (givenAt.isAfter(startOfThisMonth)) {
        groupKey = 'This Month';
      } else {
        groupKey = '${_getMonthName(givenAt.month)} ${givenAt.year}';
      }

      groups.putIfAbsent(groupKey, () => []);
      groups[groupKey]!.add(wash);
    }

    // Sort within each group
    groups.forEach((key, value) {
      value.sort((a, b) {
        final dateA = DateTime.tryParse(a['given_at'] ?? a['givenAt'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['given_at'] ?? b['givenAt'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
    });

    return groups;
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final amPm = date.hour >= 12 ? 'PM' : 'AM';
      return 'Today, $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${dayNames[date.weekday - 1]}, ${_getMonthName(date.month).substring(0, 3)} ${date.day}';
    } else {
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final amPm = date.hour >= 12 ? 'PM' : 'AM';
      return '${_getMonthName(date.month).substring(0, 3)} ${date.day}, $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _HistoryColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  Text(
                    "My Laundry",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      color: _HistoryColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Consumer<UserProvider>(
                    builder: (context, userProvider, _) {
                      final userName = userProvider.userName;
                      final initials = userName.isNotEmpty
                          ? userName[0].toUpperCase()
                          : 'U';
                      return Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _HistoryColors.secondary.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: _HistoryColors.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Icon(Icons.search, color: _HistoryColors.textSecondary, size: 22),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Search by Dhobi name or items...",
                          hintStyle: GoogleFonts.inter(
                            fontSize: 16,
                            color: _HistoryColors.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                          isDense: true,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: _HistoryColors.textPrimary,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          _searchController.clear();
                        },
                        color: _HistoryColors.textSecondary,
                      ),
                  ],
                ),
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      isSelected: _selectedFilter == 'Date',
                      icon: Icons.calendar_today_rounded,
                      label: "Date",
                      onTap: () {
                        setState(() => _selectedFilter = 'Date');
                        _sortWashes();
                      },
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      isSelected: _selectedFilter == 'Dhobi',
                      icon: Icons.person,
                      label: "Dhobi",
                      onTap: () {
                        setState(() => _selectedFilter = 'Dhobi');
                        _sortWashes();
                      },
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      isSelected: _selectedFilter == 'Missing Items',
                      icon: Icons.error_outline_rounded,
                      label: "Missing Items",
                      onTap: () {
                        setState(() => _selectedFilter = 'Missing Items');
                        _sortWashes();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Laundry List
            Expanded(
              child: _buildLaundryList(),
            ),
          ],
        ),
      ),
      // Bottom navigation bar with frost/blur effect
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: _HistoryColors.card.withOpacity(0.85),
              border: const Border(
                top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTabItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: 'Home',
                      isSelected: false,
                      onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (route) => false,
                      ),
                    ),
                    _buildTabItem(
                      icon: Icons.add_a_photo_outlined,
                      selectedIcon: Icons.add_a_photo,
                      label: 'New Wash',
                      isSelected: false,
                      onTap: () => Navigator.pushNamed(context, '/scan'),
                    ),
                    _buildTabItem(
                      icon: Icons.receipt_long_outlined,
                      selectedIcon: Icons.receipt_long,
                      label: 'History',
                      isSelected: true,
                      onTap: () {},
                    ),
                    _buildTabItem(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: 'Settings',
                      isSelected: false,
                      onTap: () => Navigator.pushNamed(context, '/settings'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected
                  ? _HistoryColors.primary
                  : _HistoryColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? _HistoryColors.primary
                    : _HistoryColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaundryList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _HistoryColors.primary),
      );
    }

    if (_allWashes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _HistoryColors.secondary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_laundry_service,
                  size: 64,
                  color: _HistoryColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No laundry history yet',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _HistoryColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start tracking your laundry by adding\nyour first wash entry',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: _HistoryColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/scan'),
                icon: const Icon(Icons.add),
                label: const Text('Add First Wash'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _HistoryColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredWashes.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                size: 64,
                color: _HistoryColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No results found',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _HistoryColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search terms',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: _HistoryColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final groupedWashes = _groupWashesByTime();

    return RefreshIndicator(
      onRefresh: _refreshWashes,
      color: _HistoryColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ...groupedWashes.entries.where((entry) => entry.value.isNotEmpty).map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                  child: Text(
                    entry.key,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: _HistoryColors.textPrimary,
                    ),
                  ),
                ),
                ...entry.value.map((wash) => _LaundryCard(
                  wash: wash,
                  formatDateTime: _formatDateTime,
                  onTap: () => _showWashDetails(wash),
                )),
              ],
            );
          }),
          const SizedBox(height: 100), // Bottom padding for nav bar
        ],
      ),
    );
  }

  void _showWashDetails(Map<String, dynamic> wash) {
    final dhobiName = wash['dhobi_name'] ?? wash['dhobiName'] ?? 'Unknown Dhobi';
    final totalItems = wash['total_items_given'] ?? wash['totalGiven'] ?? 0;
    final status = wash['status'] ?? 'pending';
    final givenAt = DateTime.tryParse(wash['given_at'] ?? wash['givenAt'] ?? '');
    final notes = wash['notes'] ?? '';
    final totalMissing = wash['total_missing'] ?? wash['totalMissing'] ?? 0;
    final totalReturned = wash['total_items_returned'] ?? wash['totalReturned'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _HistoryColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.local_laundry_service,
                    color: _getStatusColor(status),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dhobiName,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _HistoryColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        givenAt != null ? _formatDateTime(givenAt) : 'Unknown date',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _HistoryColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _HistoryColors.bgLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(label: 'Given', value: '$totalItems', color: _HistoryColors.primary),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _StatItem(label: 'Returned', value: '$totalReturned', color: _HistoryColors.green),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _StatItem(
                    label: 'Missing',
                    value: '$totalMissing',
                    color: totalMissing > 0 ? _HistoryColors.danger : _HistoryColors.green,
                  ),
                ],
              ),
            ),
            
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _HistoryColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                notes,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: _HistoryColors.textPrimary,
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteWash(wash);
                    },
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _HistoryColors.danger,
                      side: const BorderSide(color: _HistoryColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Navigate to edit screen
                    },
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _HistoryColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteWash(Map<String, dynamic> wash) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _HistoryColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.id ?? '';
      final washId = wash['id']?.toString() ?? '';

      if (washId.isNotEmpty) {
        final success = await LocalStorageService.deleteWash(userId, washId);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entry deleted'),
              backgroundColor: _HistoryColors.green,
            ),
          );
          _loadWashes();
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'returned':
      case 'completed':
        return _HistoryColors.green;
      case 'partiallyreturned':
      case 'partial':
        return _HistoryColors.warning;
      case 'pending':
      case 'given':
      default:
        return _HistoryColors.primary;
    }
  }
}

/// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterChip({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? _HistoryColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : _HistoryColors.textPrimary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isSelected ? Colors.white : _HistoryColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: isSelected ? Colors.white : _HistoryColors.textPrimary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Laundry Card Widget
class _LaundryCard extends StatelessWidget {
  final Map<String, dynamic> wash;
  final String Function(DateTime) formatDateTime;
  final VoidCallback onTap;

  const _LaundryCard({
    required this.wash,
    required this.formatDateTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dhobiName = wash['dhobi_name'] ?? wash['dhobiName'] ?? 'Unknown Dhobi';
    final totalItems = wash['total_items_given'] ?? wash['totalGiven'] ?? 0;
    final status = wash['status'] ?? 'pending';
    final givenAt = DateTime.tryParse(wash['given_at'] ?? wash['givenAt'] ?? '');
    final totalMissing = wash['total_missing'] ?? wash['totalMissing'] ?? 0;
    final hasMissing = totalMissing > 0;

    final displayDate = givenAt != null ? formatDateTime(givenAt) : 'Unknown date';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final dotColor = _getDotColor(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _HistoryColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _HistoryColors.textSecondary.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon/Image
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.local_laundry_service,
                          color: statusColor,
                          size: 28,
                        ),
                      ),
                      if (hasMissing)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: _HistoryColors.danger,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dhobiName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                color: _HistoryColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasMissing)
                            const Icon(
                              Icons.error,
                              size: 16,
                              color: _HistoryColors.danger,
                            ),
                          const SizedBox(width: 6),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalItems Items',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w400,
                          fontSize: 15,
                          color: _HistoryColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayDate,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: _HistoryColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status badge
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: statusColor,
                    ),
                  ),
                ),
                if (hasMissing) ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _HistoryColors.danger.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      '$totalMissing missing',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _HistoryColors.danger,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'returned':
      case 'completed':
        return _HistoryColors.green;
      case 'partiallyreturned':
      case 'partial':
        return _HistoryColors.warning;
      case 'pending':
      case 'given':
      default:
        return _HistoryColors.primary;
    }
  }

  Color _getDotColor(String status) {
    switch (status.toLowerCase()) {
      case 'returned':
      case 'completed':
        return _HistoryColors.accent;
      case 'partiallyreturned':
      case 'partial':
        return _HistoryColors.warning;
      case 'pending':
      case 'given':
      default:
        return _HistoryColors.secondary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'returned':
        return 'Returned';
      case 'completed':
        return 'Completed';
      case 'partiallyreturned':
      case 'partial':
        return 'Partial';
      case 'pending':
        return 'Pending';
      case 'given':
        return 'Given';
      default:
        return 'Pending';
    }
  }
}

/// Status Badge Widget
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        statusText,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: statusColor,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'returned':
      case 'completed':
        return _HistoryColors.green;
      case 'partiallyreturned':
      case 'partial':
        return _HistoryColors.warning;
      case 'pending':
      case 'given':
      default:
        return _HistoryColors.primary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'returned':
        return 'Returned';
      case 'completed':
        return 'Completed';
      case 'partiallyreturned':
      case 'partial':
        return 'Partial';
      case 'pending':
        return 'Pending';
      case 'given':
        return 'Given';
      default:
        return 'Pending';
    }
  }
}

/// Stat Item Widget for details modal
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _HistoryColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
