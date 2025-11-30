import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Color scheme for cropper
class _CropperColors {
  static const primary = Color(0xFF4A6FFF);
  static const secondary = Color(0xFFA3B4FF);
  static const accent = Color(0xFF6EE7B7);
  static const bgDark = Color(0xFF0F172A);
  static const surface = Color(0xFF1E293B);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF94A3B8);
}

enum CropShape { square, circle, rectangle, free }

/// Custom Image Cropper Widget with improved UI/UX
class CustomImageCropper extends StatefulWidget {
  final String imagePath;
  final Function(Uint8List) onCropped;
  final VoidCallback? onCancel;

  const CustomImageCropper({
    super.key,
    required this.imagePath,
    required this.onCropped,
    this.onCancel,
  });

  @override
  State<CustomImageCropper> createState() => _CustomImageCropperState();
}

class _CustomImageCropperState extends State<CustomImageCropper> 
    with SingleTickerProviderStateMixin {
  final CropController _controller = CropController();
  CropShape _selectedShape = CropShape.square;
  double _aspectRatio = 1.0;
  bool _isCropping = false;
  bool _isLoading = true;
  Uint8List? _imageData;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadImage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final file = File(widget.imagePath);
      _imageData = await file.readAsBytes();
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;
    
    // Calculate available height for crop area
    final topBarHeight = 60.0;
    final bottomControlsHeight = 200.0;
    final availableHeight = screenSize.height - safePadding.top - safePadding.bottom - topBarHeight - bottomControlsHeight;
    final cropAreaSize = availableHeight.clamp(200.0, screenSize.width - 40);

    return Scaffold(
      backgroundColor: _CropperColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar - Fixed height
            _buildTopBar(),

            // Crop area - Flexible with constraints
            Expanded(
              child: Center(
                child: _buildCropArea(cropAreaSize),
              ),
            ),

            // Bottom controls - Fixed height
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _CropperColors.surface.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: _CropperColors.textPrimary),
            onPressed: _handleCancel,
            splashRadius: 24,
          ),
          const Expanded(
            child: Text(
              'Crop Photo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _CropperColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Placeholder for symmetry
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCropArea(double maxSize) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _CropperColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading image...',
              style: TextStyle(color: _CropperColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_imageData == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: _CropperColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load image',
              style: TextStyle(color: _CropperColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleCancel,
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxSize,
          maxHeight: maxSize,
        ),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _CropperColors.primary.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Crop(
            controller: _controller,
            image: _imageData!,
            onCropped: (Uint8List croppedData) async {
              try {
                if (croppedData.isNotEmpty) {
                  widget.onCropped(croppedData);
                  setState(() => _isCropping = false);
                } else {
                  throw Exception('No cropped image data');
                }
              } catch (error) {
                debugPrint('Crop failed: $error');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to crop image'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                setState(() => _isCropping = false);
              }
            },
            aspectRatio: _selectedShape == CropShape.free ? null : _aspectRatio,
            initialSize: 0.8,
            withCircleUi: _selectedShape == CropShape.circle,
            cornerDotBuilder: (size, edge) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: _CropperColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _CropperColors.primary.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
            maskColor: Colors.black.withOpacity(0.7),
            baseColor: _CropperColors.bgDark,
            radius: _selectedShape == CropShape.circle ? 1000 : 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: _CropperColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle indicator
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Shape selection
          Text(
            'CROP SHAPE',
            style: GoogleFonts.inter(
              color: _CropperColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildShapeChip(CropShape.free, 'Free', Icons.crop_free),
                const SizedBox(width: 8),
                _buildShapeChip(CropShape.square, 'Square', Icons.crop_square),
                const SizedBox(width: 8),
                _buildShapeChip(CropShape.circle, 'Circle', Icons.circle_outlined),
                const SizedBox(width: 8),
                _buildShapeChip(CropShape.rectangle, '4:3', Icons.crop_landscape),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isCropping ? null : _handleCancel,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _CropperColors.textPrimary,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isCropping || _imageData == null ? null : _cropImage,
                  icon: _isCropping
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(_isCropping ? 'Cropping...' : 'Apply Crop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _CropperColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShapeChip(CropShape shape, String label, IconData icon) {
    final isSelected = _selectedShape == shape;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedShape = shape;
          _updateAspectRatio();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? _CropperColors.primary 
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? _CropperColors.primary 
                : Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected 
                  ? Colors.white 
                  : _CropperColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected 
                    ? Colors.white 
                    : _CropperColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateAspectRatio() {
    switch (_selectedShape) {
      case CropShape.square:
        _aspectRatio = 1.0;
        break;
      case CropShape.circle:
        _aspectRatio = 1.0;
        break;
      case CropShape.rectangle:
        _aspectRatio = 4 / 3;
        break;
      case CropShape.free:
        _aspectRatio = 1.0;
        break;
    }
  }

  void _cropImage() {
    HapticFeedback.mediumImpact();
    setState(() => _isCropping = true);
    _controller.crop();
  }
}
