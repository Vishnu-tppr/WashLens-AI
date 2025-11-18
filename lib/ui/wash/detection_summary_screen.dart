import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Detection Summary Screen showing AI-detected items
class DetectionSummaryScreen extends StatefulWidget {
  const DetectionSummaryScreen({super.key});

  @override
  State<DetectionSummaryScreen> createState() => _DetectionSummaryScreenState();
}

class _DetectionSummaryScreenState extends State<DetectionSummaryScreen> {
  final Map<String, int> _detectedItems = {
    'Shirts': 4,
    'T-Shirts': 6,
    'Pants': 3,
    'Towels': 2,
    'Socks': 5,
  };

  final List<String> _detectedColors = [
    'Blue',
    'White',
    'Striped',
    'Checked',
    'Cotton',
  ];

  final TextEditingController _dhobiController = TextEditingController(
    text: 'Sunrise Laundry Services',
  );
  final TextEditingController _notesController = TextEditingController(
    text: 'e.g., Use gentle detergent for the blue striped shirt...',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Wash Entry Summary'),
        backgroundColor: AppTheme.surface,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Detection Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacing20),
              color: AppTheme.primary.withOpacity(0.05),
              child: Text(
                'AI has detected the following items. Please review and edit if needed.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // Detected Items
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._detectedItems.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacing12,
                      ),
                      child: _buildDetectionCard(entry.key, entry.value),
                    );
                  }),

                  const SizedBox(height: AppTheme.spacing24),

                  // Detected Colors & Patterns
                  Text(
                    'Detected Colors & Patterns',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),

                  const SizedBox(height: AppTheme.spacing12),

                  Wrap(
                    spacing: AppTheme.spacing8,
                    runSpacing: AppTheme.spacing8,
                    children: _detectedColors.map((color) {
                      return Chip(
                        label: Text(color),
                        backgroundColor: AppTheme.accent.withOpacity(0.15),
                        labelStyle: Theme.of(context).textTheme.labelMedium,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppTheme.spacing24),

                  // Date & Time
                  Text(
                    'Date & Time',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),

                  const SizedBox(height: AppTheme.spacing12),

                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                      border: Border.all(color: AppTheme.textLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: AppTheme.spacing12),
                        Text(
                          'Oct 26, 2023, 10:30 AM',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacing24),

                  // Dhobi
                  Text('Dhobi', style: Theme.of(context).textTheme.titleLarge),

                  const SizedBox(height: AppTheme.spacing12),

                  TextField(
                    controller: _dhobiController,
                    decoration: const InputDecoration(
                      hintText: 'Enter dhobi name',
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacing24),

                  // Notes
                  Text('Notes', style: Theme.of(context).textTheme.titleLarge),

                  const SizedBox(height: AppTheme.spacing12),

                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Add any special instructions...',
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacing32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing20),
          child: ElevatedButton(
            onPressed: () {
              // Save and navigate
              Navigator.pushNamed(context, '/history');
            },
            child: const Text('Save Wash Entry'),
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionCard(String category, int count) {
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.getCategoryColor(category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
            child: Icon(
              AppTheme.getCategoryIcon(category),
              color: AppTheme.getCategoryColor(category),
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  'Count: $count',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Edit')),
        ],
      ),
    );
  }
}
