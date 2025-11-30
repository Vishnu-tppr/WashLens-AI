import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Laundry Return Summary Screen - Compares given vs returned items
class LaundryReturnSummaryScreen extends StatefulWidget {
  const LaundryReturnSummaryScreen({super.key});

  @override
  State<LaundryReturnSummaryScreen> createState() =>
      _LaundryReturnSummaryScreenState();
}

class _LaundryReturnSummaryScreenState
    extends State<LaundryReturnSummaryScreen> {
  final List<Map<String, dynamic>> _comparisonItems = [
    {
      'name': 'T-Shirts',
      'given': 5,
      'returned': 4,
      'status': 'missing',
      'icon': Icons.checkroom_outlined,
    },
    {
      'name': 'Jeans',
      'given': 2,
      'returned': 2,
      'status': 'matched',
      'icon': Icons.man,
    },
    {
      'name': 'Socks (Pairs)',
      'given': 7,
      'returned': 8,
      'status': 'extra',
      'icon': Icons.accessibility,
    },
    {
      'name': 'Towels',
      'given': 1,
      'returned': 1,
      'status': 'matched',
      'icon': Icons.dry_cleaning,
    },
    {
      'name': 'Hoodies',
      'given': 2,
      'returned': 1,
      'status': 'missing',
      'icon': Icons.checkroom,
    },
  ];

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
          'Laundry Return Summary',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Info
              Text(
                'Order from 18 Oct, 2023 / Order ID: WLN987654',
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  color: AppTheme.textSecondary,
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              // Given vs Returned Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Given',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Returned',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.015),

              // Comparison Cards
              ..._comparisonItems.map((item) {
                return Padding(
                  padding: EdgeInsets.only(bottom: screenHeight * 0.015),
                  child: _buildComparisonCard(
                    item['name'],
                    item['given'],
                    item['returned'],
                    item['status'],
                    item['icon'],
                    screenWidth,
                    screenHeight,
                  ),
                );
              }),

              SizedBox(height: screenHeight * 0.03),

              // Confirm Return Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Confirm return
                    _showConfirmDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Confirm Return',
                    style: TextStyle(
                      fontSize: screenWidth * 0.042,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.015),

              // Report Missing Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Report missing items
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    padding:
                        EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                    side: const BorderSide(color: AppTheme.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Report Missing',
                    style: TextStyle(
                      fontSize: screenWidth * 0.042,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.015),

              // Export Proof Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    // Export proof
                  },
                  icon: const Icon(Icons.ios_share,
                      color: AppTheme.textSecondary),
                  label: Text(
                    'Export Proof',
                    style: TextStyle(
                      fontSize: screenWidth * 0.042,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonCard(
    String name,
    int given,
    int returned,
    String status,
    IconData icon,
    double screenWidth,
    double screenHeight,
  ) {
    Color borderColor;
    Color bgColor;
    Color badgeBgColor;
    String badgeText;
    IconData statusIcon;

    switch (status) {
      case 'missing':
        borderColor = Colors.red.shade300;
        bgColor = Colors.red.shade50;
        badgeBgColor = Colors.red.shade100;
        badgeText = '-${given - returned} Missing';
        statusIcon = Icons.cancel;
        break;
      case 'extra':
        borderColor = Colors.orange.shade300;
        bgColor = Colors.orange.shade50;
        badgeBgColor = Colors.orange.shade100;
        badgeText = '+${returned - given} Extra';
        statusIcon = Icons.info;
        break;
      case 'matched':
      default:
        borderColor = AppTheme.accent.withOpacity(0.3);
        bgColor = AppTheme.accent.withOpacity(0.05);
        badgeBgColor = AppTheme.accent.withOpacity(0.15);
        badgeText = 'Matched';
        statusIcon = Icons.check_circle;
    }

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Item Name
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, color: AppTheme.textPrimary, size: 24),
                    SizedBox(width: screenWidth * 0.03),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Row(
                children: [
                  Icon(
                    statusIcon,
                    color: status == 'missing'
                        ? Colors.red
                        : status == 'extra'
                            ? Colors.orange
                            : AppTheme.accent,
                    size: 20,
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.025,
                      vertical: screenHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.w600,
                        color: status == 'missing'
                            ? Colors.red.shade700
                            : status == 'extra'
                                ? Colors.orange.shade700
                                : AppTheme.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          // Count Comparison
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Count: $given',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Count: $returned',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
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

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Return'),
          content: const Text(
            'Are you sure you want to confirm this return? '
            'This will mark the laundry as returned in your records.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Return to previous screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Return confirmed successfully'),
                    backgroundColor: AppTheme.accent,
                  ),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
