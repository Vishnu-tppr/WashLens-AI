import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_service.dart';

/// My Laundry Screen - Shows list of all laundry entries with search and filters
class MyLaundryScreen extends StatefulWidget {
  const MyLaundryScreen({super.key});

  @override
  State<MyLaundryScreen> createState() => _MyLaundryScreenState();
}

class _MyLaundryScreenState extends State<MyLaundryScreen> {
  String _selectedFilter = 'Date';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _washEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWashEntries();
  }

  Future<void> _loadWashEntries() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser != null) {
      final entries = await SupabaseService.getWashEntries(userProvider.currentUser!.id);
      if (mounted) {
        setState(() {
          _washEntries = entries;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          'My Laundry',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.01,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Dhobi name or items...',
                hintStyle: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: screenWidth * 0.035,
                ),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textTertiary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.015,
                ),
              ),
            ),
          ),

          // Filter Chips
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: Row(
              children: [
                _buildFilterChip('Date', Icons.calendar_today),
                SizedBox(width: screenWidth * 0.02),
                _buildFilterChip('Dhobi', Icons.person),
                SizedBox(width: screenWidth * 0.02),
                _buildFilterChip('Missing Items', Icons.error_outline),
              ],
            ),
          ),

          SizedBox(height: screenHeight * 0.02),

          // Laundry List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _washEntries.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: AppTheme.textTertiary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No laundry entries yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap + to create your first entry',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadWashEntries,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                          itemCount: _groupedEntries().length,
                          itemBuilder: (context, index) {
                            final group = _groupedEntries()[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(group['title']),
                                ...List.generate(group['entries'].length, (i) {
                                  final entry = group['entries'][i];
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: screenHeight * 0.015),
                                    child: _buildLaundryCard(
                                      entry['dhobi_name'] ?? 'Unknown Dhobi',
                                      '${entry['total_items'] ?? 0} Items',
                                      _formatDate(entry['created_at']),
                                      entry['status'] ?? 'Pending',
                                      hasIssue: entry['has_missing_items'] ?? false,
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                    ),
                                  );
                                }),
                                SizedBox(height: screenHeight * 0.025),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _groupedEntries() {
    final now = DateTime.now();
    final thisWeek = <Map<String, dynamic>>[];
    final lastWeek = <Map<String, dynamic>>[];
    final older = <Map<String, dynamic>>[];

    for (var entry in _washEntries) {
      final createdAt = DateTime.parse(entry['created_at']);
      final difference = now.difference(createdAt).inDays;

      if (difference <= 7) {
        thisWeek.add(entry);
      } else if (difference <= 14) {
        lastWeek.add(entry);
      } else {
        older.add(entry);
      }
    }

    final groups = <Map<String, dynamic>>[];
    if (thisWeek.isNotEmpty) {
      groups.add({'title': 'This Week', 'entries': thisWeek});
    }
    if (lastWeek.isNotEmpty) {
      groups.add({'title': 'Last Week', 'entries': lastWeek});
    }
    if (older.isNotEmpty) {
      final monthYear = older.isNotEmpty
          ? DateFormat('MMMM yyyy').format(DateTime.parse(older.first['created_at']))
          : 'Older';
      groups.add({'title': monthYear, 'entries': older});
    }

    return groups;
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, h:mm a').format(date);
    } catch (e) {
      return 'Unknown date';
    }
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.textTertiary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildLaundryCard(
    String dhobiName,
    String itemCount,
    String dateTime,
    String status, {
    required bool hasIssue,
    required double screenWidth,
    required double screenHeight,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to detail screen
            if (status == 'Returned') {
              Navigator.pushNamed(context, '/return-summary');
            } else {
              Navigator.pushNamed(context, '/wash-summary');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                // Laundry Image
                Container(
                  width: screenWidth * 0.16,
                  height: screenWidth * 0.16,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://cdn-icons-png.flaticon.com/512/3003/3003984.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.checkroom,
                          color: AppTheme.textTertiary,
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dhobiName,
                              style: TextStyle(
                                fontSize: screenWidth * 0.042,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (hasIssue)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 16,
                              ),
                            ),
                          if (!hasIssue)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_outline,
                                color: AppTheme.accent,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        itemCount,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.003),
                      Text(
                        dateTime,
                        style: TextStyle(
                          fontSize: screenWidth * 0.032,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.008),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.025,
                          vertical: screenHeight * 0.004,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'Pending'
                              ? Colors.blue.withOpacity(0.1)
                              : AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: screenWidth * 0.028,
                            color: status == 'Pending' ? Colors.blue : AppTheme.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
