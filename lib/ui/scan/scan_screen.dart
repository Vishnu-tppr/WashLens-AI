import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../ml/detector.dart';
import '../../models/detection_result.dart' as model;

/// Scan screen for capturing and analyzing laundry images
class ScanScreen extends StatefulWidget {
  final String? washId; // If scanning for return, pass existing washId
  final String role; // 'given' or 'returned'

  const ScanScreen({super.key, this.washId, this.role = 'given'});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  final List<File> _capturedImages = [];
  model.DetectionResult? _currentDetection;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        return;
      }

      _controller = CameraController(
        _cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final image = await _controller!.takePicture();
      final imageFile = File(image.path);
      _capturedImages.add(imageFile);

      // Run ML detection
      final detector = context.read<ClothDetector>();
      final result = await detector.detectFromFile(imageFile);

      setState(() {
        _currentDetection = model.DetectionResult(
          totalItems: result.totalItems,
          counts: result.counts,
          detections: result.items
              .map(
                (item) => model.Detection(
                  classLabel: item.category,
                  score: item.confidence,
                  bbox: Rect.fromLTWH(
                    item.bbox!.x,
                    item.bbox!.y,
                    item.bbox!.width,
                    item.bbox!.height,
                  ),
                ),
              )
              .toList(),
          meanConfidence: result.items.isEmpty
              ? 0.0
              : result.items.map((e) => e.confidence).reduce((a, b) => a + b) /
                    result.items.length,
        );
      });

      // Show preview with detection overlay
      _showDetectionPreview();
    } catch (e) {
      print('Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      for (final image in images) {
        final imageFile = File(image.path);
        _capturedImages.add(imageFile);
      }

      // Process all images
      final detector = context.read<ClothDetector>();
      final allDetections = <model.Detection>[];
      final allCounts = <String, int>{};

      for (final imageFile in _capturedImages) {
        final result = await detector.detectFromFile(imageFile);

        // Merge counts
        result.counts.forEach((key, value) {
          allCounts[key] = (allCounts[key] ?? 0) + value;
        });

        // Add detections
        allDetections.addAll(
          result.items.map(
            (item) => model.Detection(
              classLabel: item.category,
              score: item.confidence,
              bbox: Rect.fromLTWH(
                item.bbox!.x,
                item.bbox!.y,
                item.bbox!.width,
                item.bbox!.height,
              ),
            ),
          ),
        );
      }

      setState(() {
        _currentDetection = model.DetectionResult(
          totalItems: allCounts.values.fold<int>(0, (a, b) => a + b),
          counts: allCounts,
          detections: allDetections,
          meanConfidence: allDetections.isEmpty
              ? 0.0
              : allDetections.map((e) => e.score).reduce((a, b) => a + b) /
                    allDetections.length,
        );
      });

      _showDetectionPreview();
    } catch (e) {
      print('Error processing images: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showDetectionPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetectionPreview(),
    );
  }

  Widget _buildDetectionPreview() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              const Text(
                'Detection Results',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${_currentDetection?.totalItems ?? 0} items detected',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // Confidence indicator
              if (_currentDetection != null) ...[
                LinearProgressIndicator(
                  value: _currentDetection!.meanConfidence,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _currentDetection!.meanConfidence > 0.7
                        ? Colors.green
                        : _currentDetection!.meanConfidence > 0.5
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confidence: ${(_currentDetection!.meanConfidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
              ],

              // Category breakdown
              const Text(
                'Detected Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...(_currentDetection?.counts.entries ?? []).map((entry) {
                return _buildCategoryChip(entry.key, entry.value);
              }),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _capturedImages.clear();
                          _currentDetection = null;
                        });
                      },
                      child: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, {
                          'images': _capturedImages,
                          'detection': _currentDetection,
                        });
                      },
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String category, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(_getCategoryIcon(category), color: Colors.blue),
              const SizedBox(width: 12),
              Text(
                _formatCategoryName(category),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'shirt':
        return Icons.checkroom;
      case 'tshirt':
        return Icons.checkroom_outlined;
      case 'pants':
      case 'shorts':
      case 'track_pant':
        return Icons.man;
      case 'towel':
        return Icons.dry_cleaning;
      case 'socks':
        return Icons.accessibility;
      case 'bedsheet':
        return Icons.bed;
      default:
        return Icons.checkroom;
    }
  }

  String _formatCategoryName(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            Positioned.fill(child: CameraPreview(_controller!))
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Scan Your Laundry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ready to Scan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Point your camera at the laundry pile and tap the capture button to begin.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button
                      _buildControlButton(
                        icon: Icons.photo_library,
                        onPressed: _isProcessing ? null : _pickFromGallery,
                      ),

                      // Capture button
                      GestureDetector(
                        onTap: _isProcessing ? null : _captureImage,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.blue, width: 4),
                          ),
                          child: _isProcessing
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 36,
                                  color: Colors.blue,
                                ),
                        ),
                      ),

                      // Multiple images indicator
                      _buildControlButton(
                        icon: Icons.collections,
                        badge: _capturedImages.isNotEmpty
                            ? _capturedImages.length.toString()
                            : null,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    String? badge,
    VoidCallback? onPressed,
  }) {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.3),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 28),
            onPressed: onPressed,
          ),
        ),
        if (badge != null)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Center(
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
