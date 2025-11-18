/// Represents a single cloth item with detection metadata
class ClothItem {
  final String id;
  final String category;
  final String? color;
  final String? pattern;
  final double confidence;
  final BoundingBox? bbox;
  final DateTime detectedAt;

  ClothItem({
    required this.id,
    required this.category,
    this.color,
    this.pattern,
    required this.confidence,
    this.bbox,
    required this.detectedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'color': color,
    'pattern': pattern,
    'confidence': confidence,
    'bbox': bbox?.toJson(),
    'detectedAt': detectedAt.toIso8601String(),
  };

  factory ClothItem.fromJson(Map<String, dynamic> json) => ClothItem(
    id: json['id'] as String,
    category: json['category'] as String,
    color: json['color'] as String?,
    pattern: json['pattern'] as String?,
    confidence: (json['confidence'] as num).toDouble(),
    bbox: json['bbox'] != null
        ? BoundingBox.fromJson(json['bbox'] as Map<String, dynamic>)
        : null,
    detectedAt: DateTime.parse(json['detectedAt'] as String),
  );

  ClothItem copyWith({
    String? id,
    String? category,
    String? color,
    String? pattern,
    double? confidence,
    BoundingBox? bbox,
    DateTime? detectedAt,
  }) => ClothItem(
    id: id ?? this.id,
    category: category ?? this.category,
    color: color ?? this.color,
    pattern: pattern ?? this.pattern,
    confidence: confidence ?? this.confidence,
    bbox: bbox ?? this.bbox,
    detectedAt: detectedAt ?? this.detectedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClothItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Bounding box coordinates for detected item
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };

  factory BoundingBox.fromJson(Map<String, dynamic> json) => BoundingBox(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    width: (json['width'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
  );
}
