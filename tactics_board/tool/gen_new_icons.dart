// Generates icons + splashes for the 8 new sports.
// Run: dart run tool/gen_new_icons.dart
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  // Field Hockey — blue astroturf, D-circles at each end
  _genFieldHockeyIcon('assets/icon/fieldHockey_icon.png', 1024);
  _genSportSplash('assets/icon/fieldHockey_splash.png', 800, _fieldHockey, 5);

  // Rugby — grass, H-posts at each end
  _genRugbyIcon('assets/icon/rugby_icon.png', 1024);
  _genSportSplash('assets/icon/rugby_splash.png', 800, _rugbyGrass, 7);

  // Baseball — diamond infield
  _genBaseballIcon('assets/icon/baseball_icon.png', 1024);
  _genSportSplash('assets/icon/baseball_splash.png', 800, _outfield, 4);

  // Handball — indoor blue, 6m arcs
  _genHandballIcon('assets/icon/handball_icon.png', 1024);
  _genSportSplash('assets/icon/handball_splash.png', 800, _handballBlue, 7);

  // Water Polo — pool water, lane lines
  _genWaterPoloIcon('assets/icon/waterPolo_icon.png', 1024);
  _genSportSplash('assets/icon/waterPolo_splash.png', 800, _pool, 7);

  // Sepak Takraw — indoor court, small, net
  _genSepakTakrawIcon('assets/icon/sepakTakraw_icon.png', 1024);
  _genSportSplash('assets/icon/sepakTakraw_splash.png', 800, _indoorBlue, 3);

  // Beach Tennis — sand, net
  _genBeachTennisIcon('assets/icon/beachTennis_icon.png', 1024);
  _genSportSplash('assets/icon/beachTennis_splash.png', 800, _beachSand, 2);

  // Footvolley — sand, net
  _genFootvolleyIcon('assets/icon/footvolley_icon.png', 1024);
  _genSportSplash('assets/icon/footvolley_splash.png', 800, _footSand, 2);

  print('Done: 8 sport icons + splashes generated');
}

img.Image _iconBase(int size, img.Color courtColor) {
  final s = size.toDouble();
  final c = img.Image(width: size, height: size);
  img.fill(c, color: _bg);
  final m = (s * 0.10).round();
  img.fillRect(c, x1: m, y1: m, x2: size - m, y2: size - m, color: courtColor);
  _rect(c, m, m, size - m, size - m, _white, max(2, (s * 0.005).round()));
  return c;
}

// --- Field Hockey: blue astroturf with D-shaped shooting arcs ---
void _genFieldHockeyIcon(String path, int size) {
  final s = size.toDouble();
  final c = _iconBase(size, _fieldHockey);
  final m = (s * 0.10).round();
  final lw = max(2, (s * 0.004).round());
  // halfway line
  _hline(c, m, size - m, (s * 0.50).round(), _white, lw);
  // 25-yard lines
  _hline(c, m, size - m, (s * 0.30).round(), _white, lw);
  _hline(c, m, size - m, (s * 0.70).round(), _white, lw);
  // shooting circles (D-shape) at top and bottom
  final dr = (s * 0.22).round();
  final cx = (s * 0.50).round();
  for (int i = 0; i < lw; i++) {
    img.drawCircle(c, x: cx, y: m, radius: dr - i, color: _white);
    img.drawCircle(c, x: cx, y: size - m, radius: dr - i, color: _white);
  }
  // mask outside court
  img.fillRect(c, x1: 0, y1: 0, x2: size, y2: m, color: _bg);
  img.fillRect(c, x1: 0, y1: size - m, x2: size, y2: size, color: _bg);
  // re-draw court border
  _rect(c, m, m, size - m, size - m, _white, max(2, (s * 0.005).round()));
  // goals
  final gw = (s * 0.10).round();
  _rect(c, cx - gw ~/ 2, m - (s * 0.012).round(), cx + gw ~/ 2, m, _white, max(2, (s * 0.003).round()));
  _rect(c, cx - gw ~/ 2, size - m, cx + gw ~/ 2, size - m + (s * 0.012).round(), _white, max(2, (s * 0.003).round()));
  // players: 5 red top, 5 blue bottom
  final r = (s * 0.045).round();
  for (final p in [[0.30, 0.20], [0.50, 0.18], [0.70, 0.20], [0.40, 0.32], [0.60, 0.32]]) {
    _dot(c, (s * p[0]).round(), (s * p[1]).round(), r, _red);
  }
  for (final p in [[0.30, 0.80], [0.50, 0.82], [0.70, 0.80], [0.40, 0.68], [0.60, 0.68]]) {
    _dot(c, (s * p[0]).round(), (s * p[1]).round(), r, _blue);
  }
  File(path).writeAsBytesSync(img.encodePng(c));
}

// --- Rugby: grass with H-posts at each end ---
void _genRugbyIcon(String path, int size) {
  final s = size.toDouble();
  final c = _iconBase(size, _rugbyGrass);
  final m = (s * 0.10).round();
  final lw = max(2, (s * 0.004).round());
  // halfway line
  _hline(c, m, size - m, (s * 0.50).round(), _white, lw);
  // try lines (close to ends)
  _hline(c, m, size - m, (s * 0.18).round(), _white, lw);
  _hline(c, m, size - m, (s * 0.82).round(), _white, lw);
  // 22m lines
  _hline(c, m, size - m, (s * 0.30).round(), _white, lw);
  _hline(c, m, size - m, (s * 0.70).round(), _white, lw);
  // H posts at ends — vertical bars + crossbar
  final px = (s * 0.50).round();
  final pw = (s * 0.20).round();
  final pt = max(3, (s * 0.008).round());
  // top H
  _vline(c, px - pw ~/ 2, m, (s * 0.18).round(), _white, pt);
  _vline(c, px + pw ~/ 2, m, (s * 0.18).round(), _white, pt);
  _hline(c, px - pw ~/ 2, px + pw ~/ 2, (s * 0.13).round(), _white, pt);
  // bottom H
  _vline(c, px - pw ~/ 2, (s * 0.82).round(), size - m, _white, pt);
  _vline(c, px + pw ~/ 2, (s * 0.82).round(), size - m, _white, pt);
  _hline(c, px - pw ~/ 2, px + pw ~/ 2, (s * 0.87).round(), _white, pt);
  // players: 7 red top + 7 blue bottom (simplified)
  final r = (s * 0.04).round();
  for (final p in [[0.25, 0.36], [0.50, 0.36], [0.75, 0.36], [0.30, 0.45], [0.50, 0.45], [0.70, 0.45], [0.50, 0.25]]) {
    _dot(c, (s * p[0]).round(), (s * p[1]).round(), r, _red);
  }
  for (final p in [[0.25, 0.64], [0.50, 0.64], [0.75, 0.64], [0.30, 0.55], [0.50, 0.55], [0.70, 0.55], [0.50, 0.75]]) {
    _dot(c, (s * p[0]).round(), (s * p[1]).round(), r, _blue);
  }
  File(path).writeAsBytesSync(img.encodePng(c));
}

// --- Baseball: green outfield + brown diamond infield ---
void _genBaseballIcon(String path, int size) {
  final s = size.toDouble();
  final c = _iconBase(size, _outfield);
  final m = (s * 0.10).round();
  final cx = (s * 0.50).round();
  // outfield arc (top)
  for (int i = 0; i < max(2, (s * 0.004).round()); i++) {
    img.drawCircle(c, x: cx, y: (s * 0.78).round(), radius: (s * 0.40).round() - i, color: _white);
  }
  // mask above outfield arc bottom (draws the curve only on the upper portion)
  // brown diamond infield
  final dr = (s * 0.22).round();
  final dx = cx;
  final dy = (s * 0.62).round();
  // infield diamond (rotated square)
  final infield = [
    [dx, dy - dr],       // top (2nd base)
    [dx + dr, dy],       // right (1st base)
    [dx, dy + dr],       // bottom (home plate)
    [dx - dr, dy],       // left (3rd base)
  ];
  // fill diamond — we approximate with multiple horizontal lines
  for (int y = dy - dr; y <= dy + dr; y++) {
    final dyAbs = (y - dy).abs();
    final w = dr - dyAbs;
    img.fillRect(c, x1: dx - w, y1: y, x2: dx + w, y2: y + 1, color: _infieldBrown);
  }
  // infield lines (foul lines from home plate)
  final lw = max(2, (s * 0.005).round());
  // diamond outline
  _line(c, infield[0][0], infield[0][1], infield[1][0], infield[1][1], _white, lw);
  _line(c, infield[1][0], infield[1][1], infield[2][0], infield[2][1], _white, lw);
  _line(c, infield[2][0], infield[2][1], infield[3][0], infield[3][1], _white, lw);
  _line(c, infield[3][0], infield[3][1], infield[0][0], infield[0][1], _white, lw);
  // bases (white squares)
  final br = (s * 0.025).round();
  for (final pt in infield) {
    img.fillRect(c, x1: pt[0] - br, y1: pt[1] - br, x2: pt[0] + br, y2: pt[1] + br, color: _white);
  }
  // pitcher's mound (small dot)
  img.fillCircle(c, x: dx, y: dy, radius: (s * 0.018).round(), color: _white);
  File(path).writeAsBytesSync(img.encodePng(c));
}

// --- Handball: indoor blue with 6m arcs at each end ---
void _genHandballIcon(String path, int size) {
  final s = size.toDouble();
  final c = _iconBase(size, _handballBlue);
  final m = (s * 0.10).round();
  final lw = max(2, (s * 0.004).round());
  final cx = (s * 0.50).round();
  // halfway line
  _hline(c, m, size - m, (s * 0.50).round(), _white, lw);
  // 6m goal arcs
  for (int i = 0; i < lw; i++) {
    img.drawCircle(c, x: cx, y: m, radius: (s * 0.18).round() - i, color: _white);
    img.drawCircle(c, x: cx, y: size - m, radius: (s * 0.18).round() - i, color: _white);
  }
  // mask outside court
  img.fillRect(c, x1: 0, y1: 0, x2: size, y2: m, color: _bg);
  img.fillRect(c, x1: 0, y1: size - m, x2: size, y2: size, color: _bg);
  _rect(c, m, m, size - m, size - m, _white, max(2, (s * 0.005).round()));
  // goals
  final gw = (s * 0.08).round();
  _rect(c, cx - gw ~/ 2, m - (s * 0.012).round(), cx + gw ~/ 2, m, _white, max(2, (s * 0.003).round()));
  _rect(c, cx - gw ~/ 2, size - m, cx + gw ~/ 2, size - m + (s * 0.012).round(), _white, max(2, (s * 0.003).round()));
  // players 7v7
  final r = (s * 0.04).round();
  for (final p in [[0.50, 0.18], [0.30, 0.28], [0.70, 0.28], [0.20, 0.40], [0.50, 0.40], [0.80, 0.40], [0.50, 0.32]]) {
    _dot(c, (s * p[0]).round(), (s * p[1]).round(), r, _red);
  }
  for (final p in [[0.50, 0.82], [0.30, 0.72], [0.70, 0.72], [0.20, 0.60], [0.50, 0.60], [0.80, 0.60], [0.50, 0.68]]) {
    _dot(c, (s * p[0]).round(), (s * p[1]).round(), r, _blue);
  }
  File(path).writeAsBytesSync(img.encodePng(c));
}

// --- Water Polo: pool blue with lane stripes ---
void _genWaterPoloIcon(String path, int size) {
  final s = size.toDouble();
  final c = _iconBase(size, _pool);
  final m = (s * 0.10).round();
  final lw = max(2, (s * 0.003).round());
  // lane stripes (vertical, lighter blue)
  final laneColor = img.ColorRgba8(255, 255, 255, 60);
  for (final x in [0.25, 0.40, 0.60, 0.75]) {
    _vline(c, (s * x).round(), m, size - m, laneColor, lw);
  }
  // halfway line
  _hline(c, m, size - m, (s * 0.50).round(), _white, lw);
  // 2m and 5m goal area lines
  _hline(c, m, size - m, (s * 0.20).round(), _white, lw);
  _hline(c, m, size - m, (s * 0.30).round(), _white, lw);
  _hline(c, m, size - m, (s * 0.70).round(), _white, lw);
  _hline(c, m, size - m, (s * 0.80).round(), _white, lw);
  // goals
  final cx = (s * 0.50).round();
  final gw = (s * 0.10).round();
  _rect(c, cx - gw ~/ 2, m - (s * 0.014).round(), cx + gw ~/ 2, m, _white, max(2, (s * 0.004).round()));
  _rect(c, cx - gw ~/ 2, size - m, cx + gw ~/ 2, size - m + (s * 0.014).round(), _white, max(2, (s * 0.004).round()));
  // ball at center
  img.fillCircle(c, x: cx, y: (s * 0.50).round(), radius: (s * 0.04).round(), color: img.ColorRgb8(0xFF, 0xD6, 0x00));
  // players 7v7
  final r = (s * 0.038).round();
  for (final p in [[0.30, 0.28], [0.50, 0.25], [0.70, 0.28], [0.30, 0.40], [0.50, 0.40], [0.70, 0.40], [0.50, 0.16]]) {
    _dot(c, (s * p[0]).round(), (s * p[1]).round(), r, _red);
  }
  for (final p in [[0.30, 0.72], [0.50, 0.75], [0.70, 0.72], [0.30, 0.60], [0.50, 0.60], [0.70, 0.60], [0.50, 0.84]]) {
    _dot(c, (s * p[0]).round(), (s * p[1]).round(), r, _blue);
  }
  File(path).writeAsBytesSync(img.encodePng(c));
}

// --- Sepak Takraw: indoor court with raised net ---
void _genSepakTakrawIcon(String path, int size) {
  final s = size.toDouble();
  final c = _iconBase(size, _indoorBlue);
  final m = (s * 0.10).round();
  final netY = (s * 0.50).round();
  // net (yellow horizontal)
  _hline(c, m, size - m, netY, _net, (s * 0.012).round());
  // service circles (sepak takraw has center service circles)
  for (int i = 0; i < max(2, (s * 0.003).round()); i++) {
    img.drawCircle(c, x: (s * 0.50).round(), y: (s * 0.30).round(), radius: (s * 0.08).round() - i, color: _white);
    img.drawCircle(c, x: (s * 0.50).round(), y: (s * 0.70).round(), radius: (s * 0.08).round() - i, color: _white);
  }
  // rattan ball at center
  img.fillCircle(c, x: (s * 0.50).round(), y: netY, radius: (s * 0.05).round(), color: img.ColorRgb8(0xCD, 0x85, 0x3F));
  // 3v3
  final r = (s * 0.06).round();
  _dot(c, (s * 0.30).round(), (s * 0.30).round(), r, _red);
  _dot(c, (s * 0.70).round(), (s * 0.30).round(), r, _red);
  _dot(c, (s * 0.50).round(), (s * 0.18).round(), r, _red);
  _dot(c, (s * 0.30).round(), (s * 0.70).round(), r, _blue);
  _dot(c, (s * 0.70).round(), (s * 0.70).round(), r, _blue);
  _dot(c, (s * 0.50).round(), (s * 0.82).round(), r, _blue);
  File(path).writeAsBytesSync(img.encodePng(c));
}

// --- Beach Tennis: sand color, net, 2v2 ---
void _genBeachTennisIcon(String path, int size) {
  final s = size.toDouble();
  final c = _iconBase(size, _beachSand);
  final m = (s * 0.10).round();
  final netY = (s * 0.50).round();
  _hline(c, m, size - m, netY, _white, (s * 0.012).round());
  // service lines
  final lw = max(2, (s * 0.003).round());
  _hline(c, (s * 0.20).round(), (s * 0.80).round(), (s * 0.30).round(), _white, lw);
  _hline(c, (s * 0.20).round(), (s * 0.80).round(), (s * 0.70).round(), _white, lw);
  _vline(c, (s * 0.50).round(), (s * 0.30).round(), (s * 0.70).round(), _white, lw);
  // tennis ball at center
  img.fillCircle(c, x: (s * 0.50).round(), y: netY, radius: (s * 0.04).round(), color: img.ColorRgb8(0xC8, 0xFF, 0x00));
  // 2v2
  final r = (s * 0.07).round();
  _dot(c, (s * 0.35).round(), (s * 0.28).round(), r, _red);
  _dot(c, (s * 0.65).round(), (s * 0.28).round(), r, _red);
  _dot(c, (s * 0.35).round(), (s * 0.72).round(), r, _blue);
  _dot(c, (s * 0.65).round(), (s * 0.72).round(), r, _blue);
  File(path).writeAsBytesSync(img.encodePng(c));
}

// --- Footvolley: sand, net, 2v2 ---
void _genFootvolleyIcon(String path, int size) {
  final s = size.toDouble();
  final c = _iconBase(size, _footSand);
  final m = (s * 0.10).round();
  final netY = (s * 0.50).round();
  _hline(c, m, size - m, netY, _white, (s * 0.014).round());
  // attack lines (3m)
  final lw = max(2, (s * 0.003).round());
  _hline(c, m, size - m, (s * 0.36).round(), _white, lw);
  _hline(c, m, size - m, (s * 0.64).round(), _white, lw);
  // soccer ball at center (white with hex pattern simplified)
  final ballR = (s * 0.05).round();
  img.fillCircle(c, x: (s * 0.50).round(), y: netY, radius: ballR, color: _white);
  img.fillCircle(c, x: (s * 0.50).round(), y: netY, radius: (ballR * 0.5).round(), color: _bg);
  // 2v2
  final r = (s * 0.07).round();
  _dot(c, (s * 0.35).round(), (s * 0.24).round(), r, _red);
  _dot(c, (s * 0.65).round(), (s * 0.24).round(), r, _red);
  _dot(c, (s * 0.35).round(), (s * 0.76).round(), r, _blue);
  _dot(c, (s * 0.65).round(), (s * 0.76).round(), r, _blue);
  File(path).writeAsBytesSync(img.encodePng(c));
}

// --- Splash: court + N players per side (transparent BG) ---
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
  final n = playersPerSide.clamp(1, 11);
  final r = n <= 2 ? (s * 0.06).round() : n <= 6 ? (s * 0.04).round() : (s * 0.025).round();
  if (n <= 2) {
    for (int i = 0; i < n; i++) {
      final x = n == 1 ? 0.50 : (i == 0 ? 0.35 : 0.65);
      _dot(canvas, (s * x).round(), (s * 0.30).round(), r, _blue);
      _dot(canvas, (s * x).round(), (s * 0.70).round(), r, _red);
    }
  } else {
    final cols = n <= 3 ? n : (n <= 6 ? 3 : 4);
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

// --- palette ---
final _bg            = img.ColorRgb8(0x1E, 0x1E, 0x2E);
final _white         = img.ColorRgb8(0xFF, 0xFF, 0xFF);
final _net           = img.ColorRgb8(0xFF, 0xD6, 0x00);
final _blue          = img.ColorRgb8(0x42, 0x9B, 0xFF);
final _red           = img.ColorRgb8(0xFF, 0x45, 0x45);
final _shadow        = img.ColorRgba8(0x00, 0x00, 0x00, 0x80);
final _fieldHockey   = img.ColorRgb8(0x19, 0x76, 0xD2);
final _rugbyGrass    = img.ColorRgb8(0x2E, 0x7D, 0x32);
final _outfield      = img.ColorRgb8(0x2E, 0x7D, 0x32);
final _infieldBrown  = img.ColorRgb8(0xB3, 0x7A, 0x4C);
final _handballBlue  = img.ColorRgb8(0x15, 0x65, 0xC0);
final _pool          = img.ColorRgb8(0x02, 0x77, 0xBD);
final _indoorBlue    = img.ColorRgb8(0x15, 0x65, 0xC0);
final _beachSand     = img.ColorRgb8(0xEA, 0xC4, 0x78);
final _footSand      = img.ColorRgb8(0xE5, 0xB8, 0x80);

// --- helpers ---
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

void _line(img.Image c, int x1, int y1, int x2, int y2, img.Color color, int t) {
  img.drawLine(c, x1: x1, y1: y1, x2: x2, y2: y2, color: color, thickness: t.toDouble());
}

void _dot(img.Image c, int cx, int cy, int r, img.Color color) {
  img.fillCircle(c, x: cx + r ~/ 6, y: cy + r ~/ 6, radius: r, color: _shadow);
  img.fillCircle(c, x: cx, y: cy, radius: r, color: color);
  for (int i = 0; i < max(2, r ~/ 12); i++) {
    img.drawCircle(c, x: cx, y: cy, radius: r - i, color: _white);
  }
}
