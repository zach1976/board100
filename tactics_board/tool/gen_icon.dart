// Generates app_icon.png (1024x1024) and splash_logo.png (512x512)
// Run from the tactics_board directory:
//   dart run tool/gen_icon.dart

import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  // Default (multi-sport) icons
  _gen('assets/icon/app_icon.png', 1024);
  _genSplash('assets/icon/splash_logo.png', 800);

  // Sport-specific icons — each with unique court layout
  _genBadmintonIcon('assets/icon/badminton_icon.png', 1024);
  _genTableTennisIcon('assets/icon/tableTennis_icon.png', 1024);
  _genTennisIcon('assets/icon/tennis_icon.png', 1024);
  _genBasketballIcon('assets/icon/basketball_icon.png', 1024);
  _genVolleyballIcon('assets/icon/volleyball_icon.png', 1024);
  _genPickleballIcon('assets/icon/pickleball_icon.png', 1024);
  _genSoccerIcon('assets/icon/soccer_icon.png', 1024);

  // Sport-specific splash — same style, unique colors
  _genSportSplash('assets/icon/badminton_splash.png', 800, _court, 2);
  _genSportSplash('assets/icon/tableTennis_splash.png', 800, img.ColorRgb8(0x15, 0x65, 0xC0), 2);
  _genSportSplash('assets/icon/tennis_splash.png', 800, img.ColorRgb8(0x2E, 0x7D, 0x32), 1);
  _genSportSplash('assets/icon/basketball_splash.png', 800, img.ColorRgb8(0xB5, 0x65, 0x1D), 5);
  _genSportSplash('assets/icon/volleyball_splash.png', 800, img.ColorRgb8(0xE6, 0x8A, 0x00), 6);
  _genSportSplash('assets/icon/pickleball_splash.png', 800, img.ColorRgb8(0x2E, 0x7D, 0x32), 2);
  _genSportSplash('assets/icon/soccer_splash.png', 800, img.ColorRgb8(0x2D, 0x8A, 0x2D), 11);

  print('Done: all icons and splash screens generated');
}

// ─── Per-sport icon helpers ──────────────────────────────────────────────────

img.Image _iconBase(int size, img.Color courtColor) {
  final s = size.toDouble();
  final canvas = img.Image(width: size, height: size);
  img.fill(canvas, color: _bg);
  final m = (s * 0.10).round();
  img.fillRect(canvas, x1: m, y1: m, x2: size - m, y2: size - m, color: courtColor);
  _rect(canvas, m, m, size - m, size - m, _white, max(2, (s * 0.005).round()));
  return canvas;
}

/// Badminton: green court, net, 2 players (doubles stance)
void _genBadmintonIcon(String path, int size) {
  final s = size.toDouble();
  final c = _iconBase(size, _court);
  final m = (s * 0.10).round();
  final netY = (s * 0.50).round();
  _hline(c, m, size - m, netY, _net, (s * 0.012).round());
  // Service lines
  final lw = max(2, (s * 0.003).round());
  _hline(c, m + (s * 0.06).round(), size - m - (s * 0.06).round(), (s * 0.35).round(), _white, lw);
  _hline(c, m + (s * 0.06).round(), size - m - (s * 0.06).round(), (s * 0.65).round(), _white, lw);
  _vline(c, (s * 0.50).round(), (s * 0.35).round(), (s * 0.65).round(), _white, lw);
  // Players: 2v2 doubles
  final r = (s * 0.06).round();
  _dot(c, (s * 0.35).round(), (s * 0.28).round(), r, _red);
  _dot(c, (s * 0.65).round(), (s * 0.38).round(), r, _red);
  _dot(c, (s * 0.35).round(), (s * 0.62).round(), r, _blue);
  _dot(c, (s * 0.65).round(), (s * 0.72).round(), r, _blue);
  // Arrow
  final at = max(3, (s * 0.005).round());
  _arrow(c, (s * 0.35).round(), (s * 0.62 + r + s*0.02).round(), (s * 0.50).round(), (s * 0.78).round(), _white, at);
  File(path).writeAsBytesSync(img.encodePng(c));
}

/// Table Tennis: blue table, smaller, centered
void _genTableTennisIcon(String path, int size) {
  final s = size.toDouble();
  final c = img.Image(width: size, height: size);
  img.fill(c, color: _bg);
  // Table (smaller, centered)
  final tx1 = (s * 0.18).round(), ty1 = (s * 0.22).round();
  final tx2 = (s * 0.82).round(), ty2 = (s * 0.78).round();
  img.fillRect(c, x1: tx1, y1: ty1, x2: tx2, y2: ty2, color: img.ColorRgb8(0x15, 0x65, 0xC0));
  _rect(c, tx1, ty1, tx2, ty2, _white, max(3, (s * 0.006).round()));
  final netY = ((ty1 + ty2) / 2).round();
  _hline(c, tx1, tx2, netY, _net, (s * 0.010).round());
  _vline(c, ((tx1 + tx2) / 2).round(), ty1, ty2, img.ColorRgba8(255, 255, 255, 100), max(1, (s * 0.002).round()));
  // Players outside table
  final r = (s * 0.06).round();
  _dot(c, (s * 0.50).round(), (s * 0.14).round(), r, _red);
  _dot(c, (s * 0.50).round(), (s * 0.86).round(), r, _blue);
  File(path).writeAsBytesSync(img.encodePng(c));
}

/// Tennis: green court, service boxes
void _genTennisIcon(String path, int size) {
  final s = size.toDouble();
  final c = _iconBase(size, img.ColorRgb8(0x2E, 0x7D, 0x32));
  final m = (s * 0.10).round();
  final netY = (s * 0.50).round();
  _hline(c, m, size - m, netY, _white, (s * 0.006).round());
  // Service boxes
  final lw = max(2, (s * 0.003).round());
  _hline(c, (s * 0.20).round(), (s * 0.80).round(), (s * 0.35).round(), _white, lw);
  _hline(c, (s * 0.20).round(), (s * 0.80).round(), (s * 0.65).round(), _white, lw);
  _vline(c, (s * 0.50).round(), (s * 0.35).round(), (s * 0.65).round(), _white, lw);
  // Players: 1v1 singles
  final r = (s * 0.07).round();
  _dot(c, (s * 0.50).round(), (s * 0.25).round(), r, _red);
  _dot(c, (s * 0.50).round(), (s * 0.75).round(), r, _blue);
  final at = max(3, (s * 0.005).round());
  _arrow(c, (s * 0.50).round(), (s * 0.75 - r - s*0.02).round(), (s * 0.35).round(), (s * 0.58).round(), _white, at);
  File(path).writeAsBytesSync(img.encodePng(c));
}

/// Basketball: wood court, half-court arc, 5 players
void _genBasketballIcon(String path, int size) {
  final s = size.toDouble();
  final c = _iconBase(size, img.ColorRgb8(0xB5, 0x65, 0x1D));
  final m = (s * 0.10).round();
  // Center line + circle
  _hline(c, m, size - m, (s * 0.50).round(), _white, max(2, (s * 0.004).round()));
  final ctr = (s * 0.08).round();
  for (int i = 0; i < max(2, (s * 0.004).round()); i++) {
    img.drawCircle(c, x: (s * 0.50).round(), y: (s * 0.50).round(), radius: ctr - i, color: _white);
  }
  // 3pt arc (bottom half)
  final arcCx = (s * 0.50).round(), arcCy = (s * 0.88).round();
  final arcR = (s * 0.28).round();
  for (int i = 0; i < max(2, (s * 0.004).round()); i++) {
    img.drawCircle(c, x: arcCx, y: arcCy, radius: arcR - i, color: _white);
  }
  // Mask out bottom part of arc (below court)
  img.fillRect(c, x1: m, y1: size - m, x2: size - m, y2: size, color: _bg);
  // Key box
  final kw = (s * 0.20).round(), kh = (s * 0.16).round();
  _rect(c, (s * 0.50 - kw / 2).round(), (size - m - kh), (s * 0.50 + kw / 2).round(), size - m, _white, max(2, (s * 0.003).round()));
  // Rim
  img.fillCircle(c, x: arcCx, y: (s * 0.84).round(), radius: (s * 0.02).round(), color: img.ColorRgb8(0xFF, 0x8F, 0x00));
  // Players: 5 blue
  final r = (s * 0.045).round();
  _dot(c, (s * 0.50).round(), (s * 0.56).round(), r, _blue);
  _dot(c, (s * 0.25).round(), (s * 0.65).round(), r, _blue);
  _dot(c, (s * 0.75).round(), (s * 0.65).round(), r, _blue);
  _dot(c, (s * 0.35).round(), (s * 0.76).round(), r, _blue);
  _dot(c, (s * 0.65).round(), (s * 0.76).round(), r, _blue);
  // 5 red (top half)
  _dot(c, (s * 0.50).round(), (s * 0.44).round(), r, _red);
  _dot(c, (s * 0.25).round(), (s * 0.35).round(), r, _red);
  _dot(c, (s * 0.75).round(), (s * 0.35).round(), r, _red);
  _dot(c, (s * 0.35).round(), (s * 0.24).round(), r, _red);
  _dot(c, (s * 0.65).round(), (s * 0.24).round(), r, _red);
  File(path).writeAsBytesSync(img.encodePng(c));
}

/// Volleyball: orange/amber court, net, 6v6
void _genVolleyballIcon(String path, int size) {
  final s = size.toDouble();
  final c = _iconBase(size, img.ColorRgb8(0xE6, 0x8A, 0x00));
  final m = (s * 0.10).round();
  final netY = (s * 0.50).round();
  _hline(c, m, size - m, netY, _white, (s * 0.010).round());
  // Attack lines
  final lw = max(2, (s * 0.003).round());
  _hline(c, m, size - m, (s * 0.38).round(), _white, lw);
  _hline(c, m, size - m, (s * 0.62).round(), _white, lw);
  // 6 players per side
  final r = (s * 0.04).round();
  // Red (top)
  _dot(c, (s * 0.25).round(), (s * 0.30).round(), r, _red);
  _dot(c, (s * 0.50).round(), (s * 0.28).round(), r, _red);
  _dot(c, (s * 0.75).round(), (s * 0.30).round(), r, _red);
  _dot(c, (s * 0.25).round(), (s * 0.18).round(), r, _red);
  _dot(c, (s * 0.50).round(), (s * 0.16).round(), r, _red);
  _dot(c, (s * 0.75).round(), (s * 0.18).round(), r, _red);
  // Blue (bottom)
  _dot(c, (s * 0.25).round(), (s * 0.70).round(), r, _blue);
  _dot(c, (s * 0.50).round(), (s * 0.72).round(), r, _blue);
  _dot(c, (s * 0.75).round(), (s * 0.70).round(), r, _blue);
  _dot(c, (s * 0.25).round(), (s * 0.82).round(), r, _blue);
  _dot(c, (s * 0.50).round(), (s * 0.84).round(), r, _blue);
  _dot(c, (s * 0.75).round(), (s * 0.82).round(), r, _blue);
  File(path).writeAsBytesSync(img.encodePng(c));
}

/// Pickleball: green court, kitchen line
void _genPickleballIcon(String path, int size) {
  final s = size.toDouble();
  final c = _iconBase(size, img.ColorRgb8(0x1B, 0x5E, 0x20));
  final m = (s * 0.10).round();
  final netY = (s * 0.50).round();
  _hline(c, m, size - m, netY, _net, (s * 0.010).round());
  // Kitchen (non-volley zone) lines
  final lw = max(2, (s * 0.004).round());
  _hline(c, m, size - m, (s * 0.38).round(), _white, lw);
  _hline(c, m, size - m, (s * 0.62).round(), _white, lw);
  // Center service line
  _vline(c, (s * 0.50).round(), m, size - m, _white, lw);
  // 2v2 doubles
  final r = (s * 0.06).round();
  _dot(c, (s * 0.35).round(), (s * 0.28).round(), r, _red);
  _dot(c, (s * 0.65).round(), (s * 0.28).round(), r, _red);
  _dot(c, (s * 0.35).round(), (s * 0.72).round(), r, _blue);
  _dot(c, (s * 0.65).round(), (s * 0.72).round(), r, _blue);
  File(path).writeAsBytesSync(img.encodePng(c));
}

/// Soccer: green field, center circle, penalty areas, 11v11
void _genSoccerIcon(String path, int size) {
  final s = size.toDouble();
  final c = _iconBase(size, img.ColorRgb8(0x2D, 0x8A, 0x2D));
  final m = (s * 0.10).round();
  // Center line + circle
  final lw = max(2, (s * 0.004).round());
  _hline(c, m, size - m, (s * 0.50).round(), _white, lw);
  final ctr = (s * 0.08).round();
  for (int i = 0; i < lw; i++) {
    img.drawCircle(c, x: (s * 0.50).round(), y: (s * 0.50).round(), radius: ctr - i, color: _white);
  }
  // Penalty areas
  final pw = (s * 0.40).round(), ph = (s * 0.12).round();
  _rect(c, ((s * 0.50 - pw / 2).round()), m, ((s * 0.50 + pw / 2).round()), m + ph, _white, lw);
  _rect(c, ((s * 0.50 - pw / 2).round()), size - m - ph, ((s * 0.50 + pw / 2).round()), size - m, _white, lw);
  // Goal boxes
  final gw = (s * 0.20).round(), gh = (s * 0.05).round();
  _rect(c, ((s * 0.50 - gw / 2).round()), m, ((s * 0.50 + gw / 2).round()), m + gh, _white, lw);
  _rect(c, ((s * 0.50 - gw / 2).round()), size - m - gh, ((s * 0.50 + gw / 2).round()), size - m, _white, lw);
  // Players: 4-4-2 formation (simplified)
  final r = (s * 0.03).round();
  // Red (top): GK + 4 DEF + 4 MID + 2 FWD
  _dot(c, (s*0.50).round(), (s*0.15).round(), r, _red);
  for (final x in [0.20, 0.40, 0.60, 0.80]) _dot(c, (s*x).round(), (s*0.24).round(), r, _red);
  for (final x in [0.20, 0.40, 0.60, 0.80]) _dot(c, (s*x).round(), (s*0.36).round(), r, _red);
  _dot(c, (s*0.40).round(), (s*0.45).round(), r, _red);
  _dot(c, (s*0.60).round(), (s*0.45).round(), r, _red);
  // Blue (bottom)
  _dot(c, (s*0.50).round(), (s*0.85).round(), r, _blue);
  for (final x in [0.20, 0.40, 0.60, 0.80]) _dot(c, (s*x).round(), (s*0.76).round(), r, _blue);
  for (final x in [0.20, 0.40, 0.60, 0.80]) _dot(c, (s*x).round(), (s*0.64).round(), r, _blue);
  _dot(c, (s*0.40).round(), (s*0.55).round(), r, _blue);
  _dot(c, (s*0.60).round(), (s*0.55).round(), r, _blue);
  File(path).writeAsBytesSync(img.encodePng(c));
}

/// Splash: court + N players per side
void _genSportSplash(String path, int size, img.Color courtColor, int playersPerSide) {
  final s = size.toDouble();
  final canvas = img.Image(width: size, height: size);
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  final cx1 = (s * 0.06).round(), cy1 = (s * 0.02).round();
  final cx2 = (s * 0.94).round(), cy2 = (s * 0.98).round();
  img.fillRect(canvas, x1: cx1, y1: cy1, x2: cx2, y2: cy2, color: courtColor);
  _rect(canvas, cx1, cy1, cx2, cy2, _white, max(2, (s * 0.005).round()));

  final netY = ((cy1 + cy2) / 2).round();
  _hline(canvas, cx1, cx2, netY, _net, (s * 0.010).round());

  // Distribute players evenly
  final n = playersPerSide.clamp(1, 11);
  final r = n <= 2 ? (s * 0.06).round() : n <= 6 ? (s * 0.04).round() : (s * 0.025).round();

  if (n <= 2) {
    for (int i = 0; i < n; i++) {
      final x = n == 1 ? 0.50 : (i == 0 ? 0.35 : 0.65);
      _dot(canvas, (s * x).round(), (s * 0.30).round(), r, _blue);
      _dot(canvas, (s * x).round(), (s * 0.70).round(), r, _red);
    }
  } else {
    // Grid layout
    final cols = n <= 3 ? n : (n <= 6 ? 3 : 4);
    final rows = (n / cols).ceil();
    for (int i = 0; i < n; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      final x = 0.20 + (col / (cols - 1).clamp(1, 10)) * 0.60;
      final yTop = 0.10 + row * 0.10;
      final yBot = 0.90 - row * 0.10;
      _dot(canvas, (s * x).round(), (s * yTop).round(), r, _blue);
      _dot(canvas, (s * x).round(), (s * yBot).round(), r, _red);
    }
  }

  File(path).writeAsBytesSync(img.encodePng(canvas));
}

/// Splash logo — just the court icon on transparent background, no navy border
void _genSplash(String path, int size) {
  final s = size.toDouble();
  final canvas = img.Image(width: size, height: size);

  // Transparent background
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  // Rounded court area fills the whole image
  final cx1 = (s * 0.06).round();
  final cy1 = (s * 0.02).round();
  final cx2 = (s * 0.94).round();
  final cy2 = (s * 0.98).round();

  img.fillRect(canvas, x1: cx1, y1: cy1, x2: cx2, y2: cy2, color: _court);
  _rect(canvas, cx1, cy1, cx2, cy2, _white, max(2, (s * 0.006).round()));

  // Net
  final netY = ((cy1 + cy2) / 2).round();
  _hline(canvas, cx1, cx2, netY, _net, (s * 0.012).round());
  final postW = (s * 0.014).round();
  final postH = (s * 0.042).round();
  img.fillRect(canvas, x1: cx1 - postW ~/ 2, y1: netY - postH ~/ 2, x2: cx1 + postW ~/ 2, y2: netY + postH ~/ 2, color: _net);
  img.fillRect(canvas, x1: cx2 - postW ~/ 2, y1: netY - postH ~/ 2, x2: cx2 + postW ~/ 2, y2: netY + postH ~/ 2, color: _net);

  // Service lines
  final thirdH = ((cy2 - cy1) / 3).round();
  final lineThk = max(2, (s * 0.004).round());
  final inset = (s * 0.06).round();
  _hline(canvas, cx1 + inset, cx2 - inset, cy1 + thirdH, _white, lineThk);
  _hline(canvas, cx1 + inset, cx2 - inset, cy2 - thirdH, _white, lineThk);
  final midX = ((cx1 + cx2) / 2).round();
  _vline(canvas, midX, cy1 + thirdH, cy2 - thirdH, _white, lineThk);

  // 4 players — top-down circles
  final r = (s * 0.06).round();
  final bx1 = cx1 + (s * 0.22).round(), by1 = cy1 + (s * 0.18).round();
  final bx2 = cx2 - (s * 0.22).round(), by2 = cy1 + (s * 0.18).round();
  final rx1 = cx1 + (s * 0.22).round(), ry1 = cy2 - (s * 0.18).round();
  final rx2 = cx2 - (s * 0.22).round(), ry2 = cy2 - (s * 0.18).round();

  _dot(canvas, bx1, by1, r, _blue);
  _dot(canvas, bx2, by2, r, _blue);
  _dot(canvas, rx1, ry1, r, _red);
  _dot(canvas, rx2, ry2, r, _red);

  File(path).writeAsBytesSync(img.encodePng(canvas));
}

// ─── palette ─────────────────────────────────────────────────────────────────
final _bg      = img.ColorRgb8(0x1E, 0x1E, 0x2E); // dark navy
final _court   = img.ColorRgb8(0x1B, 0x7A, 0x3E); // court green
final _white   = img.ColorRgb8(0xFF, 0xFF, 0xFF);
final _net     = img.ColorRgb8(0xFF, 0xD6, 0x00); // yellow net
final _blue    = img.ColorRgb8(0x42, 0x9B, 0xFF); // home team
final _red     = img.ColorRgb8(0xFF, 0x45, 0x45); // away team
final _shadow  = img.ColorRgba8(0x00, 0x00, 0x00, 0x80);

void _gen(String path, int size) {
  final s = size.toDouble();
  final canvas = img.Image(width: size, height: size);

  // ── background ──────────────────────────────────────────────────────────
  img.fill(canvas, color: _bg);

  // ── court rectangle (with rounded feel via inset) ────────────────────────
  final cx1 = (s * 0.175).round();
  final cy1 = (s * 0.115).round();
  final cx2 = (s * 0.825).round();
  final cy2 = (s * 0.885).round();

  img.fillRect(canvas, x1: cx1, y1: cy1, x2: cx2, y2: cy2, color: _court);

  // court border (thick white)
  _rect(canvas, cx1, cy1, cx2, cy2, _white, (s * 0.007).round());

  // ── net (horizontal centre) ───────────────────────────────────────────────
  final netY = ((cy1 + cy2) / 2).round();
  _hline(canvas, cx1, cx2, netY, _net, (s * 0.010).round());
  // net posts (small rectangles)
  final postW = (s * 0.012).round();
  final postH = (s * 0.038).round();
  img.fillRect(canvas,
      x1: cx1 - postW ~/ 2, y1: netY - postH ~/ 2,
      x2: cx1 + postW ~/ 2, y2: netY + postH ~/ 2,
      color: _net);
  img.fillRect(canvas,
      x1: cx2 - postW ~/ 2, y1: netY - postH ~/ 2,
      x2: cx2 + postW ~/ 2, y2: netY + postH ~/ 2,
      color: _net);

  // ── service lines ─────────────────────────────────────────────────────────
  final inset   = (s * 0.085).round();
  final thirdH  = ((cy2 - cy1) / 3).round();
  final lineThk = max(2, (s * 0.004).round());
  _hline(canvas, cx1 + inset, cx2 - inset, cy1 + thirdH,        _white, lineThk);
  _hline(canvas, cx1 + inset, cx2 - inset, cy2 - thirdH,        _white, lineThk);
  // centre vertical (doubles lane)
  final midX = ((cx1 + cx2) / 2).round();
  _vline(canvas, midX, cy1 + thirdH, cy2 - thirdH, _white, lineThk);

  // ── player dots ──────────────────────────────────────────────────────────
  final r = (s * 0.065).round();
  // blue: top-left
  final bx1 = cx1 + (s * 0.17).round();
  final by1 = cy1 + (s * 0.14).round();
  // blue: top-right
  final bx2 = cx2 - (s * 0.17).round();
  final by2 = cy1 + (s * 0.14).round();
  // red: bottom-left
  final rx1 = cx1 + (s * 0.17).round();
  final ry1 = cy2 - (s * 0.14).round();
  // red: bottom-right
  final rx2 = cx2 - (s * 0.17).round();
  final ry2 = cy2 - (s * 0.14).round();

  _dot(canvas, bx1, by1, r, _blue);
  _dot(canvas, bx2, by2, r, _blue);
  _dot(canvas, rx1, ry1, r, _red);
  _dot(canvas, rx2, ry2, r, _red);

  // ── movement arrows (red players → net) ──────────────────────────────────
  final arrowThk = max(3, (s * 0.008).round());
  _arrow(canvas, rx1, ry1 - r - (s * 0.03).round(), rx1, netY + (s * 0.06).round(), _white, arrowThk);
  _arrow(canvas, rx2, ry2 - r - (s * 0.03).round(), rx2, netY + (s * 0.06).round(), _white, arrowThk);

  // ── save ─────────────────────────────────────────────────────────────────
  File(path).writeAsBytesSync(img.encodePng(canvas));
}

// ─── helpers ─────────────────────────────────────────────────────────────────

void _rect(img.Image c, int x1, int y1, int x2, int y2, img.Color color, int t) {
  _hline(c, x1, x2, y1, color, t);
  _hline(c, x1, x2, y2, color, t);
  _vline(c, x1, y1, y2, color, t);
  _vline(c, x2, y1, y2, color, t);
}

void _hline(img.Image c, int x1, int x2, int y, img.Color color, int t) {
  final half = t ~/ 2;
  img.fillRect(c, x1: x1, y1: y - half, x2: x2, y2: y + half, color: color);
}

void _vline(img.Image c, int x, int y1, int y2, img.Color color, int t) {
  final half = t ~/ 2;
  img.fillRect(c, x1: x - half, y1: y1, x2: x + half, y2: y2, color: color);
}

void _dot(img.Image c, int cx, int cy, int r, img.Color color) {
  // shadow
  img.fillCircle(c, x: cx + r ~/ 6, y: cy + r ~/ 6, radius: r, color: _shadow);
  // fill
  img.fillCircle(c, x: cx, y: cy, radius: r, color: color);
  // white border
  for (int i = 0; i < max(2, r ~/ 12); i++) {
    img.drawCircle(c, x: cx, y: cy, radius: r - i, color: _white);
  }
  // number "1"  — tiny white text via two pixels (purely decorative at small sizes)
}

void _arrow(img.Image c, int x1, int y1, int x2, int y2, img.Color color, int t) {
  // shaft
  _vline(c, x1, y1, y2, color, t);

  // arrowhead (triangle pointing down toward y2)
  final hw = t * 3; // half-width of arrowhead
  final ah = t * 4; // arrowhead height
  final dir = y2 > y1 ? 1 : -1;
  final tipY = y2;
  final baseY = y2 - dir * ah;

  for (int dy = 0; dy <= ah; dy++) {
    final frac = dy / ah;
    final w = (hw * frac).round();
    final rowY = baseY + dir * dy;
    img.fillRect(c,
        x1: x1 - w, y1: rowY,
        x2: x1 + w, y2: rowY + 1,
        color: color);
  }
}
