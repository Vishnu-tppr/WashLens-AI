import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// History/My Laundry Screen
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Date';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Laundry',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.person_outline),
                    iconSize: 28,
                  ),
                ],
              ),
            ),

            // Search Bar
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing20,
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by Dhobi name or items...',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: AppTheme.surface,
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacing16),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing20,
              ),
              child: Row(
                children: [
                  _buildFilterChip('Date', Icons.calendar_today),
                  const SizedBox(width: AppTheme.spacing8),
                  _buildFilterChip('Dhobi', Icons.person),
                  const SizedBox(width: AppTheme.spacing8),
                  _buildFilterChip(
                    'Missing Items',
                    Icons.warning_amber_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing20),

            // Laundry List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing20,
                ),
                children: [
                  Text(
                    'This Week',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _buildLaundryCard(
                    dhobi: 'Raju Dhobi',
                    items: 15,
                    date: 'Oct 26, 10:00 AM',
                    status: 'Pending',
                    statusColor: AppTheme.warning,
                    hasMissing: true,
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _buildLaundryCard(
                    dhobi: 'Anil\'s Laundry',
                    items: 8,
                    date: 'Oct 24, 4:30 PM',
                    status: 'Returned',
                    statusColor: AppTheme.success,
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  Text(
                    'Last Week',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _buildLaundryCard(
                    dhobi: 'Raju Dhobi',
                    items: 22,
                    date: 'Oct 19, 9:00 AM',
                    status: 'Returned',
                    statusColor: AppTheme.success,
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  Text(
                    'September 2024',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _buildLaundryCard(
                    dhobi: 'Vicky Laundry',
                    items: 12,
                    date: 'Sep 28, 11:30 AM',
                    status: 'Returned',
                    statusColor: AppTheme.success,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          ),
          const SizedBox(width: AppTheme.spacing4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = label);
      },
    );
  }

  Widget _buildLaundryCard({
    required String dhobi,
    required int items,
    required String date,
    required String status,
    required Color statusColor,
    bool hasMissing = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        boxShadow: AppTheme.shadow1,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.local_laundry_service,
                    color: statusColor,
                    size: 32,
                  ),
                ),
                if (hasMissing)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
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
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dhobi, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  '$items Items',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing8,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radius8),
            ),
            child: Text(
              status,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
