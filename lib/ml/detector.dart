import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;
// import 'package:tflite_flutter/tflite_flutter.dart';  // Temporarily disabled
import 'package:uuid/uuid.dart';
import '../models/cloth_item.dart';

/// ML-based cloth detector using TFLite
class ClothDetector {
  static const int inputSize = 640;
  static const double confidenceThreshold = 0.5;
  static const double iouThreshold = 0.45;
  static const int maxDetections = 100;

  // Interpreter? _interpreter;  // Temporarily disabled
  bool _isInitialized = false;

  /// Class mapping for YOLO model
  static const Map<int, String> classMapping = {
    0: 'shirt',
    1: 'tshirt',
    2: 'pants',
    3: 'shorts',
    4: 'track_pant',
    5: 'towel',
    6: 'socks',
    7: 'bedsheet',
  };

  /// Initialize the detector
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // TFLite temporarily disabled - using demo mode
      print('Running in demo mode (TFLite disabled)');
      _isInitialized = true;
    } catch (e) {
      print('Warning: TFLite model not found, using demo mode: $e');
      _isInitialized = true;
    }
  }

  /// Detect clothes from image file
  Future<DetectionResult> detectFromFile(File imageFile) async {
    if (!_isInitialized) await initialize();

    // Read and decode image
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    return await detectFromImage(image);
  }

  /// Detect clothes from Image object
  Future<DetectionResult> detectFromImage(img.Image image) async {
    if (!_isInitialized) await initialize();

    final startTime = DateTime.now();

    // Demo mode (TFLite disabled)
    return _demoDetection(image);

    // Preprocess image
    final input = _preprocessImage(image);

    // Run inference
    final output = _runInference(input);

    // Post-process results
    final detections = _postProcess(output, image.width, image.height);

    // Apply NMS
    final filteredDetections = _applyNMS(detections);

    // Group by category and count
    final counts = _groupAndCount(filteredDetections);

    // Extract colors and patterns
    final colorsAndPatterns = await _extractColorsAndPatterns(
      image,
      filteredDetections,
    );

    final inferenceTime = DateTime.now().difference(startTime).inMilliseconds;

    return DetectionResult(
      items: filteredDetections,
      counts: counts,
      detectedColors: colorsAndPatterns['colors'] as List<String>,
      detectedPatterns: colorsAndPatterns['patterns'] as List<String>,
      inferenceTimeMs: inferenceTime,
      imageWidth: image.width,
      imageHeight: image.height,
    );
  }

  /// Demo detection when no model is available
  DetectionResult _demoDetection(img.Image image) {
    final demoItems = <ClothItem>[
      ClothItem(
        id: const Uuid().v4(),
        category: 'shirt',
        confidence: 0.92,
        color: 'blue',
        pattern: 'striped',
        detectedAt: DateTime.now(),
      ),
      ClothItem(
        id: const Uuid().v4(),
        category: 'tshirt',
        confidence: 0.88,
        color: 'white',
        pattern: 'plain',
        detectedAt: DateTime.now(),
      ),
      ClothItem(
        id: const Uuid().v4(),
        category: 'pants',
        confidence: 0.85,
        color: 'black',
        pattern: 'plain',
        detectedAt: DateTime.now(),
      ),
      ClothItem(
        id: const Uuid().v4(),
        category: 'towel',
        confidence: 0.90,
        color: 'red',
        pattern: 'plain',
        detectedAt: DateTime.now(),
      ),
    ];

    final counts = <String, int>{
      'shirt': 2,
      'tshirt': 3,
      'pants': 1,
      'towel': 2,
    };

    return DetectionResult(
      items: demoItems,
      counts: counts,
      detectedColors: ['blue', 'white', 'black', 'red'],
      detectedPatterns: ['striped', 'plain'],
      inferenceTimeMs: 150,
      imageWidth: image.width,
      imageHeight: image.height,
    );
  }

  /// Preprocess image for model input
  Float32List _preprocessImage(img.Image image) {
    // Resize image to 640x640
    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Normalize pixel values to [0, 1]
    final input = Float32List(1 * inputSize * inputSize * 3);
    var pixelIndex = 0;

    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return input;
  }

  /// Run TFLite inference (temporarily disabled)
  List<List<double>> _runInference(Float32List input) {
    // TFLite temporarily disabled
    return [];
    /*
    if (_interpreter == null) {
      throw Exception('Interpreter not initialized');
    }

    // Reshape input
    final inputTensor = input.reshape([1, inputSize, inputSize, 3]);

    // Prepare output tensor
    // YOLOv8 output: [1, 8400, 13] where 13 = [x, y, w, h, conf, class_0...class_7]
    final outputTensor = List.generate(
      1,
      (i) => List.generate(8400, (j) => List.filled(13, 0.0)),
    );

    // Run inference
    _interpreter!.run(inputTensor, outputTensor);

    // Flatten to 2D list
    return List<List<double>>.from(
      outputTensor[0].map((row) => List<double>.from(row)),
    );
    */
  }

  /// Post-process model output
  List<ClothItem> _postProcess(
    List<List<double>> output,
    int originalWidth,
    int originalHeight,
  ) {
    final detections = <ClothItem>[];
    final scaleX = originalWidth / inputSize;
    final scaleY = originalHeight / inputSize;

    for (var i = 0; i < output.length; i++) {
      final row = output[i];

      // Extract box coordinates (center format)
      final cx = row[0] * scaleX;
      final cy = row[1] * scaleY;
      final w = row[2] * scaleX;
      final h = row[3] * scaleY;
      final confidence = row[4];

      // Skip low-confidence detections
      if (confidence < confidenceThreshold) continue;

      // Find class with highest score
      var maxClassScore = 0.0;
      var maxClassIndex = 0;
      for (var j = 5; j < 13; j++) {
        if (row[j] > maxClassScore) {
          maxClassScore = row[j];
          maxClassIndex = j - 5;
        }
      }

      final finalConfidence = confidence * maxClassScore;
      if (finalConfidence < confidenceThreshold) continue;

      // Convert to corner format
      final x = cx - w / 2;
      final y = cy - h / 2;

      final bbox = BoundingBox(x: x, y: y, width: w, height: h);
      final category = classMapping[maxClassIndex] ?? 'unknown';

      detections.add(
        ClothItem(
          id: const Uuid().v4(),
          category: category,
          confidence: finalConfidence,
          bbox: bbox,
          detectedAt: DateTime.now(),
        ),
      );
    }

    return detections;
  }

  /// Apply Non-Maximum Suppression
  List<ClothItem> _applyNMS(List<ClothItem> detections) {
    // Sort by confidence descending
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final keep = <ClothItem>[];

    while (detections.isNotEmpty) {
      final current = detections.removeAt(0);
      keep.add(current);

      detections.removeWhere((detection) {
        final iou = _calculateIoU(current.bbox!, detection.bbox!);
        return iou > iouThreshold;
      });
    }

    return keep;
  }

  /// Calculate Intersection over Union
  double _calculateIoU(BoundingBox a, BoundingBox b) {
    final xLeft = a.x > b.x ? a.x : b.x;
    final yTop = a.y > b.y ? a.y : b.y;
    final xRight =
        (a.x + a.width) < (b.x + b.width) ? (a.x + a.width) : (b.x + b.width);
    final yBottom = (a.y + a.height) < (b.y + b.height)
        ? (a.y + a.height)
        : (b.y + b.height);

    if (xRight < xLeft || yBottom < yTop) return 0.0;

    final intersectionArea = (xRight - xLeft) * (yBottom - yTop);
    final aArea = a.width * a.height;
    final bArea = b.width * b.height;
    final unionArea = aArea + bArea - intersectionArea;

    return intersectionArea / unionArea;
  }

  /// Group detections by category and count
  Map<String, int> _groupAndCount(List<ClothItem> detections) {
    final counts = <String, int>{};
    for (final detection in detections) {
      counts[detection.category] = (counts[detection.category] ?? 0) + 1;
    }
    return counts;
  }

  /// Extract dominant colors and patterns from detected regions
  Future<Map<String, List<String>>> _extractColorsAndPatterns(
    img.Image image,
    List<ClothItem> detections,
  ) async {
    final colors = <String>{};
    final patterns = <String>{};

    for (final detection in detections) {
      if (detection.bbox == null) continue;

      // Extract region of interest
      final bbox = detection.bbox!;
      final x = bbox.x.clamp(0, image.width - 1).toInt();
      final y = bbox.y.clamp(0, image.height - 1).toInt();
      final w = bbox.width.clamp(1, image.width - x).toInt();
      final h = bbox.height.clamp(1, image.height - y).toInt();

      if (w <= 0 || h <= 0) continue;

      final region = img.copyCrop(image, x: x, y: y, width: w, height: h);

      // Analyze dominant color
      final color = _getDominantColor(region);
      colors.add(color);

      // Simple pattern detection (placeholder)
      final pattern = _detectPattern(region);
      patterns.add(pattern);
    }

    return {'colors': colors.toList(), 'patterns': patterns.toList()};
  }

  /// Get dominant color from image region
  String _getDominantColor(img.Image region) {
    var rSum = 0, gSum = 0, bSum = 0, count = 0;

    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final pixel = region.getPixel(x, y);
        rSum += pixel.r.toInt();
        gSum += pixel.g.toInt();
        bSum += pixel.b.toInt();
        count++;
      }
    }

    if (count == 0) return 'unknown';

    final r = rSum ~/ count;
    final g = gSum ~/ count;
    final b = bSum ~/ count;

    return _colorName(r, g, b);
  }

  /// Map RGB to color name
  String _colorName(int r, int g, int b) {
    // Simple color classification
    final brightness = (r + g + b) / 3;

    if (brightness < 50) return 'black';
    if (brightness > 200) return 'white';

    if (r > g && r > b) {
      return r > 150 ? 'red' : 'brown';
    } else if (g > r && g > b) {
      return 'green';
    } else if (b > r && b > g) {
      return b > 150 ? 'blue' : 'navy';
    } else if (r > 100 && g > 100 && b < 100) {
      return 'yellow';
    } else if (r > 100 && b > 100) {
      return 'purple';
    }

    return 'gray';
  }

  /// Detect pattern (simplified)
  String _detectPattern(img.Image region) {
    // Placeholder: could use edge detection, frequency analysis, etc.
    // For now, return 'plain' - extend with actual pattern detection
    return 'plain';
  }

  /// Dispose resources
  void dispose() {
    // _interpreter?.close();  // Temporarily disabled
    _isInitialized = false;
  }
}

/// Detection result wrapper
class DetectionResult {
  final List<ClothItem> items;
  final Map<String, int> counts;
  final List<String> detectedColors;
  final List<String> detectedPatterns;
  final int inferenceTimeMs;
  final int imageWidth;
  final int imageHeight;

  DetectionResult({
    required this.items,
    required this.counts,
    required this.detectedColors,
    required this.detectedPatterns,
    required this.inferenceTimeMs,
    required this.imageWidth,
    required this.imageHeight,
  });

  int get totalItems => counts.values.fold<int>(0, (sum, count) => sum + count);

  @override
  String toString() {
    return 'DetectionResult(items: ${items.length}, total: $totalItems, '
        'time: ${inferenceTimeMs}ms, counts: $counts)';
  }
}
