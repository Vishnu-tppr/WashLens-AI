import 'dart:ui';

/// Result of ML inference on laundry images
class DetectionResult {
  final int totalItems;
  final Map<String, int> counts; // category_slug -> count
  final List<Detection> detections;
  final double meanConfidence;

  DetectionResult({
    required this.totalItems,
    required this.counts,
    required this.detections,
    required this.meanConfidence,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      totalItems: json['total_items'] as int,
      counts: Map<String, int>.from(json['counts'] as Map),
      detections: (json['detections'] as List)
          .map((d) => Detection.fromJson(d as Map<String, dynamic>))
          .toList(),
      meanConfidence: (json['mean_confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_items': totalItems,
      'counts': counts,
      'detections': detections.map((d) => d.toJson()).toList(),
      'mean_confidence': meanConfidence,
    };
  }
}

/// Single detected item
class Detection {
  final String classLabel; // e.g., "shirt", "tshirt", "pants"
  final double score;
  final Rect bbox;
  final String? color;
  final String? pattern;
  final bool? logo;
  final String? collarType;

  Detection({
    required this.classLabel,
    required this.score,
    required this.bbox,
    this.color,
    this.pattern,
    this.logo,
    this.collarType,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    final bboxList = json['bbox'] as List;
    return Detection(
      classLabel: json['class'] as String,
      score: (json['score'] as num).toDouble(),
      bbox: Rect.fromLTWH(
        (bboxList[0] as num).toDouble(),
        (bboxList[1] as num).toDouble(),
        (bboxList[2] as num).toDouble(),
        (bboxList[3] as num).toDouble(),
      ),
      color: json['color'] as String?,
      pattern: json['pattern'] as String?,
      logo: json['logo'] as bool?,
      collarType: json['collar_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class': classLabel,
      'score': score,
      'bbox': [bbox.left, bbox.top, bbox.width, bbox.height],
      if (color != null) 'color': color,
      if (pattern != null) 'pattern': pattern,
      if (logo != null) 'logo': logo,
      if (collarType != null) 'collar_type': collarType,
    };
  }
}
