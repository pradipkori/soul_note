import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'drawing_stroke.g.dart';

@HiveType(typeId: 3)
class DrawingPoint {
  @HiveField(0)
  final double x;
  @HiveField(1)
  final double y;

  DrawingPoint({required this.x, required this.y});

  Offset toOffset() => Offset(x, y);

  Map<String, double> toMap() => {'x': x, 'y': y};

  factory DrawingPoint.fromMap(Map<String, dynamic> map) {
    return DrawingPoint(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
    );
  }
}

@HiveType(typeId: 4)
class DrawingStroke extends HiveObject {
  @HiveField(0)
  List<DrawingPoint> points;

  @HiveField(1)
  int colorValue;

  @HiveField(2)
  double strokeWidth;

  DrawingStroke({
    required this.points,
    required this.colorValue,
    required this.strokeWidth,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => p.toMap()).toList(),
      'colorValue': colorValue,
      'strokeWidth': strokeWidth,
    };
  }

  factory DrawingStroke.fromMap(Map<String, dynamic> map) {
    return DrawingStroke(
      points: (map['points'] as List<dynamic>)
          .map((p) => DrawingPoint.fromMap(p as Map<String, dynamic>))
          .toList(),
      colorValue: map['colorValue'] as int,
      strokeWidth: (map['strokeWidth'] as num).toDouble(),
    );
  }
}
