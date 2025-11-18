import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Return Summary Screen - Given vs Returned comparison
class ReturnSummaryScreen extends StatefulWidget {
  const ReturnSummaryScreen({super.key});

  @override
  State<ReturnSummaryScreen> createState() => _ReturnSummaryScreenState();
}

class _ReturnSummaryScreenState extends State<ReturnSummaryScreen> {
  final List<Map<String, dynamic>> _comparisonItems = [
    {
      'category': 'T-Shirts',
      'given': 5,
      'returned': 4,
      'status': 'missing',
      'checked': [true, true, true, true, false],
    },
    {
      'category': 'Jeans',
      'given': 2,
      'returned': 2,
      'status': 'matched',
      'checked': [true, true],
    },
    {
      'category': 'Socks (Pairs)',
      'given': 7,
      'returned': 8,
      'status': 'extra',
      'checked': List.generate(8, (i) => true),
    },
    {
      'category': 'Towels',
      'given': 1,
      'returned': 1,
      'status': 'matched',
      'checked': [true],
    },
    {
      'category': 'Hoodies',
      'given': 2,
      'returned': 1,
      'status': 'missing',
      'checked': [true, false],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Laundry Return Summary'),
        backgroundColor: AppTheme.surface,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacing20),
              color: AppTheme.surfaceVariant,
              child: Column(
                children: [
                  Text(
                    'Order from 18 Oct, 2023 / Order ID: WLN987654',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        'Given',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                      Text(
                        'Returned',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing16),

            // Comparison Items
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
              ),
              itemCount: _comparisonItems.length,
              itemBuilder: (context, index) {
                final item = _comparisonItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                  child: _buildComparisonCard(item),
                );
              },
            ),

            const SizedBox(height: AppTheme.spacing24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildComparisonCard(Map<String, dynamic> item) {
    final status = item['status'] as String;
    Color borderColor;
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (status) {
      case 'missing':
        borderColor = AppTheme.error;
        badgeColor = AppTheme.error;
        badgeIcon = Icons.cancel;
        badgeText = '-${item['given'] - item['returned']} Missing';
        break;
      case 'extra':
        borderColor = AppTheme.warning;
        badgeColor = AppTheme.warning;
        badgeIcon = Icons.info;
        badgeText = '+${item['returned'] - item['given']} Extra';
        break;
      default:
        borderColor = AppTheme.success;
        badgeColor = AppTheme.success;
        badgeIcon = Icons.check_circle;
        badgeText = 'Matched';
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: AppTheme.shadow1,
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: Text(
                  item['category'] as String,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 16, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing16),

          // Count Comparison
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Count: ${item['given']}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Count: ${item['returned']}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: badgeColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                // Confirm return
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Return confirmed!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text('Confirm Return'),
            ),
            const SizedBox(height: AppTheme.spacing12),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error),
                foregroundColor: AppTheme.error,
              ),
              child: const Text('Report Missing'),
            ),
            const SizedBox(height: AppTheme.spacing12),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share),
              label: const Text('Export Proof'),
            ),
          ],
        ),
      ),
    );
  }
}
