import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// New Laundry Entry Screen - For manually creating a new laundry entry
class NewLaundryEntryScreen extends StatefulWidget {
  const NewLaundryEntryScreen({super.key});

  @override
  State<NewLaundryEntryScreen> createState() => _NewLaundryEntryScreenState();
}

class _NewLaundryEntryScreenState extends State<NewLaundryEntryScreen> {
  final TextEditingController _dhobiController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final Map<String, int> _laundryBasket = {
    'Shirts': 0,
    'T-Shirts': 2,
    'Pants': 1,
    'Towels': 0,
    'Socks': 0,
    'Bedsheets': 0,
    'Jeans': 0,
  };

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Shirts', 'icon': Icons.checkroom, 'color': const Color(0xFF3B82F6)},
    {'name': 'T-Shirts', 'icon': Icons.checkroom_outlined, 'color': const Color(0xFF10B981)},
    {'name': 'Pants', 'icon': Icons.person, 'color': const Color(0xFF8B5CF6)},
    {'name': 'Towels', 'icon': Icons.dry_cleaning, 'color': const Color(0xFFF59E0B)},
    {'name': 'Bedsheets', 'icon': Icons.bed, 'color': const Color(0xFFEF4444)},
    {'name': 'Socks', 'icon': Icons.accessibility, 'color': const Color(0xFFF97316)},
    {'name': 'Jeans', 'icon': Icons.man, 'color': const Color(0xFF6366F1)},
  ];

  @override
  void dispose() {
    _dhobiController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _totalItems => _laundryBasket.values.fold(0, (sum, count) => sum + count);

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
          'New Laundry Entry',
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
              // Dhobi / Laundry Service
              Text(
                'Dhobi / Laundry Service',
                style: TextStyle(
                  fontSize: screenWidth * 0.037,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: screenHeight * 0.012),
              TextField(
                controller: _dhobiController,
                decoration: InputDecoration(
                  hintText: 'e.g., Raju Bhaiya',
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.018,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              // What are you sending?
              Text(
                'What are you sending?',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),

              // Category Icons Grid
              Wrap(
                spacing: screenWidth * 0.02,
                runSpacing: screenHeight * 0.012,
                children: _categories.map((category) {
                  return _buildCategoryButton(
                    category['name'],
                    category['icon'],
                    category['color'],
                    screenWidth,
                  );
                }).toList(),
              ),

              SizedBox(height: screenHeight * 0.025),

              // Notes
              Text(
                'Notes (Optional)',
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
                  hintText: 'e.g., Please use gentle wash for the blue shirt',
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

              SizedBox(height: screenHeight * 0.025),

              // Your Laundry Basket
              Text(
                'Your Laundry Basket ($_totalItems Items)',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),

              Container(
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
                child: Column(
                  children: _laundryBasket.entries.where((e) => e.value > 0).map((entry) {
                    return _buildBasketItem(
                      entry.key,
                      entry.value,
                      _getCategoryIcon(entry.key),
                      _getCategoryColor(entry.key),
                      screenWidth,
                      screenHeight,
                    );
                  }).toList(),
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // Save Entry Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Save entry logic
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
                    'Save Entry',
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

  Widget _buildCategoryButton(String name, IconData icon, Color color, double screenWidth) {
    final count = _laundryBasket[name] ?? 0;
    final isSelected = count > 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_laundryBasket[name] == 0) {
            _laundryBasket[name] = 1;
          }
        });
      },
      child: Container(
        width: screenWidth * 0.19,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 6),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasketItem(
    String name,
    int count,
    IconData icon,
    Color color,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.015,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.background,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          // Decrease button
          IconButton(
            onPressed: () {
              setState(() {
                if (_laundryBasket[name]! > 0) {
                  _laundryBasket[name] = _laundryBasket[name]! - 1;
                }
              });
            },
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppTheme.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.remove, size: 18, color: AppTheme.textPrimary),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          SizedBox(width: screenWidth * 0.03),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: screenWidth * 0.042,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          // Increase button
          IconButton(
            onPressed: () {
              setState(() {
                _laundryBasket[name] = _laundryBasket[name]! + 1;
              });
            },
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 18, color: Colors.white),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Shirts':
        return Icons.checkroom;
      case 'T-Shirts':
        return Icons.checkroom_outlined;
      case 'Pants':
        return Icons.person;
      case 'Towels':
        return Icons.dry_cleaning;
      case 'Bedsheets':
        return Icons.bed;
      case 'Socks':
        return Icons.accessibility;
      case 'Jeans':
        return Icons.man;
      default:
        return Icons.checkroom;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Shirts':
        return const Color(0xFF3B82F6);
      case 'T-Shirts':
        return const Color(0xFF10B981);
      case 'Pants':
        return const Color(0xFF8B5CF6);
      case 'Towels':
        return const Color(0xFFF59E0B);
      case 'Bedsheets':
        return const Color(0xFFEF4444);
      case 'Socks':
        return const Color(0xFFF97316);
      case 'Jeans':
        return const Color(0xFF6366F1);
      default:
        return AppTheme.primary;
    }
  }
}
