import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wash Entry Summary Screen - Shows AI detected items with edit options
class WashEntrySummaryScreen extends StatefulWidget {
  const WashEntrySummaryScreen({super.key});

  @override
  State<WashEntrySummaryScreen> createState() => _WashEntrySummaryScreenState();
}

class _WashEntrySummaryScreenState extends State<WashEntrySummaryScreen> {
  final TextEditingController _notesController = TextEditingController();
  String _selectedDhobi = 'Sunrise Laundry Services';

  final List<Map<String, dynamic>> _detectedItems = [
    {'name': 'Shirts', 'count': 4, 'icon': Icons.checkroom, 'color': const Color(0xFF3B82F6)},
    {'name': 'T-shirts', 'count': 6, 'icon': Icons.checkroom_outlined, 'color': const Color(0xFF10B981)},
    {'name': 'Pants', 'count': 3, 'icon': Icons.person, 'color': const Color(0xFF8B5CF6)},
    {'name': 'Towels', 'count': 2, 'icon': Icons.dry_cleaning, 'color': const Color(0xFFF59E0B)},
    {'name': 'Socks', 'count': 5, 'icon': Icons.accessibility, 'color': const Color(0xFFF97316)},
  ];

  final List<String> _detectedColors = ['Blue', 'White', 'Striped', 'Checked', 'Cotton'];

  @override
  void dispose() {
    _notesController.dispose();
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
          'Wash Entry Summary',
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
              // Info Header
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Text(
                        'AI has detected the following items. Please review and edit if needed.',
                        style: TextStyle(
                          fontSize: screenWidth * 0.033,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              // Detected Items List
              ..._detectedItems.map((item) {
                return Padding(
                  padding: EdgeInsets.only(bottom: screenHeight * 0.012),
                  child: _buildDetectedItemCard(
                    item['name'],
                    item['count'],
                    item['icon'],
                    item['color'],
                    screenWidth,
                    screenHeight,
                  ),
                );
              }),

              SizedBox(height: screenHeight * 0.025),

              // Detected Colors & Patterns
              Text(
                'Detected Colors & Patterns',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: screenHeight * 0.012),
              Wrap(
                spacing: screenWidth * 0.02,
                runSpacing: screenHeight * 0.01,
                children: _detectedColors.map((color) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.035,
                      vertical: screenHeight * 0.008,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                    ),
                    child: Text(
                      color,
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: screenHeight * 0.025),

              // Date & Time
              Text(
                'Date & Time',
                style: TextStyle(
                  fontSize: screenWidth * 0.037,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: screenHeight * 0.012),
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppTheme.textSecondary, size: 20),
                    SizedBox(width: screenWidth * 0.03),
                    Text(
                      'Oct 26, 2023, 10:30 AM',
                      style: TextStyle(
                        fontSize: screenWidth * 0.038,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              // Dhobi
              Text(
                'Dhobi',
                style: TextStyle(
                  fontSize: screenWidth * 0.037,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: screenHeight * 0.012),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.005,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDhobi,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
                    items: [
                      'Sunrise Laundry Services',
                      'Raju Dhobi',
                      'Quick Clean Services',
                      'Express Laundry',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: screenWidth * 0.038,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDhobi = newValue!;
                      });
                    },
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              // Notes
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: screenWidth * 0.037,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: screenHeight * 0.012),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'e.g., Use gentle detergent for the blue striped shirt...',
                  hintStyle: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: screenWidth * 0.035,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(screenWidth * 0.04),
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // Save Wash Entry Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Save wash entry
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Wash Entry',
                    style: TextStyle(
                      fontSize: screenWidth * 0.042,
                      fontWeight: FontWeight.w600,
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

  Widget _buildDetectedItemCard(
    String name,
    int count,
    IconData icon,
    Color color,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: screenWidth * 0.042,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: screenHeight * 0.003),
                Text(
                  'Count: $count',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Edit item
              _showEditDialog(name, count);
            },
            child: Text(
              'Edit',
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String itemName, int currentCount) {
    showDialog(
      context: context,
      builder: (context) {
        int newCount = currentCount;
        return AlertDialog(
          title: Text('Edit $itemName'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (newCount > 0) {
                        setState(() => newCount--);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      newCount.toString(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => newCount++);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Update count
                setState(() {
                  final index = _detectedItems.indexWhere((item) => item['name'] == itemName);
                  if (index != -1) {
                    _detectedItems[index]['count'] = newCount;
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
