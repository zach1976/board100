import 'package:flutter/material.dart';

enum StrokeStyle { solid, dashed }

/// Terminator drawn at the end of a stroke. New values are appended so the
/// serialized index of existing strokes stays valid.
enum ArrowStyle { none, end, both, cross, tbar }

/// Geometry of the stroke body, independent of dash pattern and terminator.
/// [freehand] follows the drawn points, [straight] is a line from the first
/// point to the last, [wavy] oscillates perpendicular to the drawn path.
enum LineShape { freehand, straight, wavy }

class DrawingStroke {
  final String id;
  final List<Offset> points;
  final Color color;
  final double width;
  final StrokeStyle style;
  final ArrowStyle arrow;
  final LineShape shape;
  /// Start phase in timeline (inclusive). -1 = always visible.
  int startPhase;
  /// End phase in timeline (inclusive). -1 = always visible.
  int endPhase;

  DrawingStroke({
    required this.id,
    required this.points,
    this.color = const Color(0xFFFFD600),
    this.width = 3.0,
    this.style = StrokeStyle.solid,
    this.arrow = ArrowStyle.end,
    this.shape = LineShape.freehand,
    this.startPhase = -1,
    this.endPhase = -1,
  });

  /// Legacy single-phase getter for backward compat
  int get phase => startPhase;

  /// True when stroke spans all phases
  bool get isFullSpan => startPhase < 0 || endPhase < 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'points': points.map((p) => [p.dx, p.dy]).toList(),
    'color': color.value,
    'width': width,
    'style': style.index,
    'arrow': arrow.index,
    'shape': shape.index,
    'startPhase': startPhase,
    'endPhase': endPhase,
  };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    // Support legacy single 'phase' field
    final legacyPhase = (json['phase'] as int?) ?? -1;
    // Clamp enum indices: a board saved by a newer build may carry values this
    // build doesn't know about.
    T byIndex<T>(List<T> values, int? i, T fallback) =>
        (i != null && i >= 0 && i < values.length) ? values[i] : fallback;
    return DrawingStroke(
      id: json['id'] as String,
      points: (json['points'] as List).map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble())).toList(),
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
      style: byIndex(StrokeStyle.values, json['style'] as int?, StrokeStyle.solid),
      arrow: byIndex(ArrowStyle.values, json['arrow'] as int?, ArrowStyle.end),
      shape: byIndex(LineShape.values, json['shape'] as int?, LineShape.freehand),
      startPhase: (json['startPhase'] as int?) ?? legacyPhase,
      endPhase: (json['endPhase'] as int?) ?? legacyPhase,
    );
  }

  DrawingStroke copyWith({
    String? id,
    List<Offset>? points,
    Color? color,
    double? width,
    StrokeStyle? style,
    ArrowStyle? arrow,
    LineShape? shape,
    int? startPhase,
    int? endPhase,
  }) {
    return DrawingStroke(
      id: id ?? this.id,
      points: points ?? List.from(this.points),
      color: color ?? this.color,
      width: width ?? this.width,
      style: style ?? this.style,
      arrow: arrow ?? this.arrow,
      shape: shape ?? this.shape,
      startPhase: startPhase ?? this.startPhase,
      endPhase: endPhase ?? this.endPhase,
    );
  }
}
