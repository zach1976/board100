import 'package:flutter/material.dart';

enum StrokeStyle { solid, dashed }
enum ArrowStyle { none, end, both }

class DrawingStroke {
  final String id;
  final List<Offset> points;
  final Color color;
  final double width;
  final StrokeStyle style;
  final ArrowStyle arrow;

  const DrawingStroke({
    required this.id,
    required this.points,
    this.color = const Color(0xFFFFD600),
    this.width = 3.0,
    this.style = StrokeStyle.solid,
    this.arrow = ArrowStyle.end,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'points': points.map((p) => [p.dx, p.dy]).toList(),
    'color': color.value,
    'width': width,
    'style': style.index,
    'arrow': arrow.index,
  };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) => DrawingStroke(
    id: json['id'] as String,
    points: (json['points'] as List).map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble())).toList(),
    color: Color(json['color'] as int),
    width: (json['width'] as num).toDouble(),
    style: StrokeStyle.values[json['style'] as int],
    arrow: ArrowStyle.values[json['arrow'] as int],
  );

  DrawingStroke copyWith({
    String? id,
    List<Offset>? points,
    Color? color,
    double? width,
    StrokeStyle? style,
    ArrowStyle? arrow,
  }) {
    return DrawingStroke(
      id: id ?? this.id,
      points: points ?? List.from(this.points),
      color: color ?? this.color,
      width: width ?? this.width,
      style: style ?? this.style,
      arrow: arrow ?? this.arrow,
    );
  }
}
