import 'package:flutter/material.dart';
import 'dart:io';
import '../../services/supabase_service.dart';
import '../../models/detection_result.dart' as model;
import '../scan/scan_screen.dart';

/// New wash entry screen for creating a laundry session
class NewWashScreen extends StatefulWidget {
  const NewWashScreen({super.key});

  @override
  State<NewWashScreen> createState() => _NewWashScreenState();
}

class _NewWashScreenState extends State<NewWashScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dhobiController = TextEditingController();
  final _notesController = TextEditingController();

  final Map<String, int> _basketCounts = {};
  List<File> _capturedImages = [];
  model.DetectionResult? _detectionResult;
  List<Map<String, dynamic>> _dhobis = [];
  String? _selectedDhobiId;
  bool _isLoading = false;

  // Default categories
  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'shirt',
      'name': 'Shirts',
      'icon': Icons.checkroom,
      'color': Colors.blue,
    },
    {
      'id': 'tshirt',
      'name': 'T-Shirts',
      'icon': Icons.checkroom_outlined,
      'color': Colors.green,
    },
    {'id': 'pants', 'name': 'Pants', 'icon': Icons.man, 'color': Colors.purple},
    {
      'id': 'towel',
      'name': 'Towels',
      'icon': Icons.dry_cleaning,
      'color': Colors.orange,
    },
    {
      'id': 'bedsheet',
      'name': 'Bedsheets',
      'icon': Icons.bed,
      'color': Colors.teal,
    },
    {
      'id': 'socks',
      'name': 'Socks (Pairs)',
      'icon': Icons.accessibility,
      'color': Colors.red,
    },
    {
      'id': 'shorts',
      'name': 'Shorts',
      'icon': Icons.man_outlined,
      'color': Colors.amber,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDhobis();
  }

  Future<void> _loadDhobis() async {
    // Get current user ID (anonymous auth)
    final user = SupabaseService.currentUser;
    if (user == null) {
      // Sign in anonymously if not authenticated
      await SupabaseService.signInAnonymously();
    }

    final userId = SupabaseService.currentUser?.id ?? 'demo_user';
    final dhobis = await SupabaseService.getDhobis(userId);
    setState(() {
      _dhobis = dhobis;
    });
  }

  @override
  void dispose() {
    _dhobiController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const ScanScreen(role: 'given')),
    );

    if (result != null && mounted) {
      setState(() {
        _capturedImages = result['images'] as List<File>;
        _detectionResult = result['detection'] as model.DetectionResult?;

        // Auto-fill basket from detection
        if (_detectionResult != null) {
          _basketCounts.addAll(_detectionResult!.counts);
        }
      });
    }
  }

  void _updateCount(String categoryId, int delta) {
    setState(() {
      _basketCounts[categoryId] = (_basketCounts[categoryId] ?? 0) + delta;
      if (_basketCounts[categoryId]! <= 0) {
        _basketCounts.remove(categoryId);
      }
    });
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    if (_basketCounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.currentUser?.id ?? 'demo_user';
      final now = DateTime.now();
      final totalItems = _basketCounts.values.fold<int>(0, (a, b) => a + b);

      // Create or get dhobi
      String? dhobiName;
      if (_selectedDhobiId != null) {
        dhobiName = _dhobis
            .firstWhere((d) => d['id'] == _selectedDhobiId)['name'] as String?;
      } else {
        dhobiName = _dhobiController.text;
        // Save new dhobi to Supabase
        await SupabaseService.saveDhobi({
          'user_id': userId,
          'name': _dhobiController.text,
        });
      }

      // Create wash entry in Supabase
      final washEntry = await SupabaseService.saveWashEntry({
        'user_id': userId,
        'dhobi_name': dhobiName,
        'total_items': totalItems,
        'status': 'pending',
        'given_at': now.toIso8601String(),
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      });

      if (washEntry == null) {
        throw Exception('Failed to save wash entry');
      }

      final washId = washEntry['id'] as String;

      // Save wash items
      for (final entry in _basketCounts.entries) {
        await SupabaseService.client?.from('wash_items').insert({
          'wash_entry_id': washId,
          'category': entry.key,
          'count': entry.value,
        });
      }

      // Upload images if any
      if (_capturedImages.isNotEmpty) {
        for (final imageFile in _capturedImages) {
          try {
            final bytes = await imageFile.readAsBytes();
            final fileName =
                '$washId/${DateTime.now().millisecondsSinceEpoch}.jpg';
            final imageUrl = await SupabaseService.uploadImage(
              'wash-images',
              fileName,
              bytes,
            );

            if (imageUrl != null) {
              // Save image reference
              await SupabaseService.client?.from('wash_images').insert({
                'wash_entry_id': washId,
                'image_url': imageUrl,
                'image_type': 'given',
              });
            }
          } catch (e) {
            print('Error uploading image: $e');
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wash entry saved successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error saving wash entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _basketCounts.values.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Laundry Entry'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'scan',
            onPressed: _openScanner,
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'save',
            onPressed: _isLoading ? null : _saveEntry,
            icon: const Icon(Icons.save),
            label: const Text('Save Entry'),
          ),
        ],
      ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Dhobi selection
              const Text(
                'Dhobi / Laundry Service',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_dhobis.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: _dhobis.map((dhobi) {
                    final dhobiId = dhobi['id'] as String?;
                    final dhobiName = dhobi['name'] as String? ?? 'Unknown';
                    final isSelected = _selectedDhobiId == dhobiId;
                    return ChoiceChip(
                      label: Text(dhobiName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedDhobiId = selected ? dhobiId : null;
                          if (selected) {
                            _dhobiController.clear();
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Text('or', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: _dhobiController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Raju Bhaiya',
                  prefixIcon: Icon(Icons.person),
                ),
                enabled: _selectedDhobiId == null,
                validator: (value) {
                  if (_selectedDhobiId == null &&
                      (value == null || value.isEmpty)) {
                    return 'Please enter dhobi name or select from chips';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Categories
              const Text(
                'What are you sending?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _buildCategoryChip(category);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Notes
              const Text(
                'Notes (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Please use gentle wash for the blue shirt',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Basket
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Laundry Basket ($totalItems Items)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_capturedImages.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_capturedImages.length} photo${_capturedImages.length > 1 ? "s" : ""}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_basketCounts.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No items added yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ..._basketCounts.entries.map((entry) {
                        final category = _categories.firstWhere(
                          (cat) => cat['id'] == entry.key,
                          orElse: () => {
                            'name': entry.key,
                            'icon': Icons.checkroom,
                          },
                        );
                        return _buildBasketItem(
                          category['name'] as String,
                          entry.value,
                          category['icon'] as IconData,
                          entry.key,
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(Map<String, dynamic> category) {
    final count = _basketCounts[category['id'] as String] ?? 0;
    final hasItems = count > 0;

    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _updateCount(category['id'] as String, 1),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: hasItems
                    ? (category['color'] as Color).withOpacity(0.2)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasItems
                      ? (category['color'] as Color)
                      : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      category['icon'] as IconData,
                      color: hasItems
                          ? (category['color'] as Color)
                          : Colors.grey[600],
                      size: 32,
                    ),
                  ),
                  if (hasItems)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category['name'] as String,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBasketItem(
    String name,
    int count,
    IconData icon,
    String categoryId,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => _updateCount(categoryId, -1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: () => _updateCount(categoryId, 1),
                color: Colors.blue,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
