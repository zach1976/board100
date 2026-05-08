import 'package:flutter/material.dart';
import '../models/player_icon.dart';

/// CustomClipper that produces the path of a [MarkerShape] inscribed in the
/// child's [Size]. Used to clip a photo into the user's chosen marker shape
/// (square / triangle / diamond / circle) so a single image can drive
/// non-circular custom markers on the board.
class MarkerShapeClipper extends CustomClipper<Path> {
  final MarkerShape shape;
  const MarkerShapeClipper(this.shape);

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = w * 0.5; // shapes use the full extent

    switch (shape) {
      case MarkerShape.square:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
            const Radius.circular(8),
          ));
      case MarkerShape.triangle:
        return Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * 0.95, cy + r * 0.7)
          ..lineTo(cx - r * 0.95, cy + r * 0.7)
          ..close();
      case MarkerShape.diamond:
        return Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * 0.85, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r * 0.85, cy)
          ..close();
      case MarkerShape.circle:
      default:
        return Path()
          ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    }
  }

  @override
  bool shouldReclip(MarkerShapeClipper old) => old.shape != shape;
}

/// Available marker shapes for custom-photo elements.
const List<MarkerShape> kPhotoMarkerShapes = [
  MarkerShape.circle,
  MarkerShape.square,
  MarkerShape.triangle,
  MarkerShape.diamond,
];
