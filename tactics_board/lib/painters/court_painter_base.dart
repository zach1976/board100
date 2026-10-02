import 'package:flutter/material.dart';

abstract class CourtPainterBase extends CustomPainter {
  final Color lineColor;
  final Color courtColor;

  /// [repaint] is for a court that draws a bitmap: the picture decodes after
  /// the first frame, and a painter with nothing to listen to would keep the
  /// fallback until something else happened to repaint the board.
  const CourtPainterBase({
    this.lineColor = Colors.white,
    this.courtColor = const Color(0xFF1B5E20),
    Listenable? repaint,
  }) : super(repaint: repaint);

  Paint get linePaint => Paint()
    ..color = lineColor
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  Paint get courtPaint => Paint()
    ..color = courtColor
    ..style = PaintingStyle.fill;

  /// The surface, with something under the paint.
  ///
  /// A court used to be one flat fill: a plastic slab with lines on it.
  /// This lays the same colour down and then gives it two things a real
  /// surface has — bands where it was laid or mown, and a light over the
  /// middle that falls off to the edges. Basketball had both already, drawn
  /// by hand inside its own painter; this is that treatment, shared.
  ///
  /// [bands] is how many strips run ACROSS the court — perpendicular to the
  /// goal-to-goal axis, the way a pitch is mown and a floor is laid, which
  /// is also the way the soccer painter has always drawn them. 0 for a
  /// surface that has none (a hard court, sand). [bandTint] is how far a
  /// band lifts from the base — tiny, because the players have to stay the
  /// brightest thing on the board.
  void drawSurface(Canvas canvas, Size size,
      {int bands = 0, double bandTint = 0.045, bool vignette = true}) {
    canvas.drawRect(Offset.zero & size, courtPaint);
    if (bands > 1) {
      final bh = size.height / bands;
      final lift = Paint()
        ..color = Colors.white.withValues(alpha: bandTint)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < bands; i += 2) {
        canvas.drawRect(Rect.fromLTWH(0, i * bh, size.width, bh), lift);
      }
    }
    if (!vignette) return;
    // Brighter in the middle, deeper at the edges. Same numbers the
    // hardwood floor was using, which is where they were tuned.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: [Color(0x1FFFFFFF), Color(0x00000000), Color(0x2B000000)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  /// A goal, drawn as a goal rather than an empty box.
  ///
  /// It used to be a stroked rectangle hanging off the goal line: two thin
  /// lines and some pitch showing through. Then a flat mesh. This is the
  /// goal seen from above and a little in front, the way the board sees
  /// everything else: a thick bar along the goal line where the frame is,
  /// the net box receding to a thinner back bar, the side nets drawn as
  /// strings fanning from front corner to back corner, the inside darkening
  /// toward the back, and a soft shadow thrown off the back of it.
  ///
  /// [canvas] says which way the pitch is: the mouth faces the middle of
  /// it. Without it the mouth is taken to be the bottom edge, which is the
  /// top goal, the one a half-pitch board shows.
  void drawGoal(Canvas canvas, Rect r, {Size? pitch}) {
    if (r.width <= 0 || r.height <= 0) return;
    // Which edge is the mouth. The pitch's middle is on that side.
    final mouthBelow = pitch == null || r.center.dy < pitch.height / 2;
    final mouthY = mouthBelow ? r.bottom : r.top;
    final backY = mouthBelow ? r.top : r.bottom;
    final into = mouthBelow ? -1.0 : 1.0; // from the mouth toward the back

    // The shadow, thrown past the back of the net.
    final shadow = r.shift(Offset(r.width * 0.04, into * r.height * 0.18));
    canvas.drawRect(
      shadow,
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    canvas.save();
    canvas.clipRect(r);
    // Inside: open at the mouth, dark at the back.
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: mouthBelow ? Alignment.bottomCenter : Alignment.topCenter,
          end: mouthBelow ? Alignment.topCenter : Alignment.bottomCenter,
          colors: const [Color(0x33000000), Color(0x8C000000)],
        ).createShader(r),
    );
    // The back net: a mesh, finer than before, with the gauge taken from
    // the goal's own short side so a 3m hockey goal and a 7.32m football
    // goal both get squares rather than one a grid and the other a smear.
    final mesh = (r.shortestSide / 3.2).clamp(2.5, 8.0);
    final thread = Paint()
      ..color = const Color(0x4DFFFFFF)
      ..strokeWidth = 0.6;
    for (double x = r.left + mesh; x < r.right; x += mesh) {
      canvas.drawLine(Offset(x, r.top), Offset(x, r.bottom), thread);
    }
    for (double y = r.top + mesh; y < r.bottom; y += mesh) {
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), thread);
    }
    // The side nets: strings from the front post to the back corner, a few
    // of them fanning, which is what gives the box its depth.
    final side = Paint()
      ..color = const Color(0x73FFFFFF)
      ..strokeWidth = 0.8;
    for (final x in [r.left, r.right]) {
      final inward = x == r.left ? 1.0 : -1.0;
      for (var k = 1; k <= 3; k++) {
        final t = k / 4;
        canvas.drawLine(
          Offset(x, mouthY),
          Offset(x + inward * r.width * 0.22 * t, backY),
          side,
        );
      }
    }
    canvas.restore();

    // The frame: posts and back bar thin, the crossbar along the goal line
    // thick — it is the nearest part and the one a shot has to pass.
    final frame = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRect(r, frame);
    canvas.drawLine(
      Offset(r.left, mouthY),
      Offset(r.right, mouthY),
      Paint()
        ..color = lineColor
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
  }

  /// The mesh of a net, over the band a court painter already draws.
  ///
  /// The net was a translucent white bar with a bright tape along it: a
  /// highlighter stroke across the court. Real netting is visible as the one
  /// thing on the board you can see through, and drawing the threads costs
  /// ten lines — vertical ones across the band and one horizontal halfway
  /// down it, which is what reads as mesh at this size.
  void drawNetMesh(Canvas canvas, Offset a, Offset b, double band) {
    final d = b - a;
    final len = d.distance;
    if (len <= 0 || band <= 0) return;
    final u = d / len;
    final n = Offset(-u.dy, u.dx) * (band / 2);
    final thread = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 0.7;
    final gap = band * 0.55;
    for (double t = gap; t < len; t += gap) {
      final at = a + u * t;
      canvas.drawLine(at - n, at + n, thread);
    }
    canvas.drawLine(a, b, thread);
  }

  void drawDashedLine(Canvas canvas, Paint paint, Offset p1, Offset p2,
      {double dashLength = 8, double gapLength = 5}) {
    final total = (p2 - p1).distance;
    final dir = (p2 - p1) / total;
    double drawn = 0;
    bool drawing = true;
    while (drawn < total) {
      final segLen = drawing
          ? dashLength.clamp(0, total - drawn)
          : gapLength.clamp(0, total - drawn);
      if (drawing) {
        canvas.drawLine(
          p1 + dir * drawn,
          p1 + dir * (drawn + segLen),
          paint,
        );
      }
      drawn += segLen;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
