import 'package:flutter/material.dart';
import 'court_painter_base.dart';

class WaterPoloCourtPainter extends CourtPainterBase {
  const WaterPoloCourtPainter()
      : super(
          lineColor: Colors.white,
          courtColor: const Color(0xFF0277BD),
        );

  @override
  void paint(Canvas canvas, Size size) {
    _drawWater(canvas, size);

    final w = size.width;
    final h = size.height;

    // FINA: 30m × 20m. Portrait = 20 wide × 30 tall.
    const fieldW = 20.0;
    const fieldH = 30.0;
    const ratio = fieldW / fieldH;

    double cw, ch;
    if (w / h > ratio) {
      ch = h * 0.88;
      cw = ch * ratio;
    } else {
      cw = w * 0.88;
      ch = cw / ratio;
    }
    final left = (w - cw) / 2;
    final top = (h - ch) / 2;

    final scX = cw / fieldW;
    final scY = ch / fieldH;
    Offset o(double x, double y) => Offset(left + x * scX, top + y * scY);

    final whiteLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final redLine = Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final yellowLine = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Pool boundary (white)
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), whiteLine);

    // Goal lines (red, full width)
    canvas.drawLine(o(0, 0), o(fieldW, 0), redLine);
    canvas.drawLine(o(0, fieldH), o(fieldW, fieldH), redLine);

    // 2m line — white, close to goal
    canvas.drawLine(o(0, 2), o(fieldW, 2), whiteLine);
    canvas.drawLine(o(0, fieldH - 2), o(fieldW, fieldH - 2), whiteLine);

    // 6m line — yellow
    canvas.drawLine(o(0, 6), o(fieldW, 6), yellowLine);
    canvas.drawLine(o(0, fieldH - 6), o(fieldW, fieldH - 6), yellowLine);

    // 5m mark — short yellow ticks (penalty mark)
    final yellowFill = Paint()..color = const Color(0xFFFFEB3B)..style = PaintingStyle.fill;
    canvas.drawCircle(o(fieldW / 2, 5), 0.18 * scX, yellowFill);
    canvas.drawCircle(o(fieldW / 2, fieldH - 5), 0.18 * scX, yellowFill);

    // Halfway line (white)
    canvas.drawLine(o(0, fieldH / 2), o(fieldW, fieldH / 2), whiteLine);

    // Center spot
    canvas.drawCircle(o(fieldW / 2, fieldH / 2), 0.22 * scX,
        Paint()..color = Colors.white..style = PaintingStyle.fill);

    // Goals (3m wide × 0.7m visual depth)
    const goalW = 3.0;
    const goalDepth = 0.7;
    const goalLeft = (fieldW - goalW) / 2;

    final goalPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(o(goalLeft, -goalDepth).dx, o(goalLeft, -goalDepth).dy,
          goalW * scX, goalDepth * scY),
      goalPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(o(goalLeft, fieldH).dx, o(goalLeft, fieldH).dy,
          goalW * scX, goalDepth * scY),
      goalPaint,
    );
  }

  void _drawWater(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0277BD)..style = PaintingStyle.fill,
    );
    // Subtle water ripple stripes
    final stripe = Paint()
      ..color = const Color(0xFF0288D1).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    final laneH = size.height / 16;
    for (int i = 0; i < 16; i++) {
      if (i.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(0, i * laneH, size.width, laneH),
          stripe,
        );
      }
    }
  }
}
