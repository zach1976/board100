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

  // Sport-specific icons
  _genSportIcon('assets/icon/badminton_icon.png', 1024, _court, '🏸');
  _genSportIcon('assets/icon/tableTennis_icon.png', 1024, img.ColorRgb8(0x15, 0x65, 0xC0), '🏓');
  _genSportIcon('assets/icon/tennis_icon.png', 1024, img.ColorRgb8(0x2E, 0x7D, 0x32), '🎾');
  _genSportIcon('assets/icon/basketball_icon.png', 1024, img.ColorRgb8(0xB5, 0x65, 0x1D), '🏀');
  _genSportIcon('assets/icon/volleyball_icon.png', 1024, img.ColorRgb8(0xE6, 0x8A, 0x00), '🏐');
  _genSportIcon('assets/icon/pickleball_icon.png', 1024, img.ColorRgb8(0x2E, 0x7D, 0x32), '🥒');
  _genSportIcon('assets/icon/soccer_icon.png', 1024, img.ColorRgb8(0x2D, 0x8A, 0x2D), '⚽');

  // Sport-specific splash
  _genSportSplash('assets/icon/badminton_splash.png', 800, _court);
  _genSportSplash('assets/icon/tableTennis_splash.png', 800, img.ColorRgb8(0x15, 0x65, 0xC0));
  _genSportSplash('assets/icon/tennis_splash.png', 800, img.ColorRgb8(0x2E, 0x7D, 0x32));
  _genSportSplash('assets/icon/basketball_splash.png', 800, img.ColorRgb8(0xB5, 0x65, 0x1D));
  _genSportSplash('assets/icon/volleyball_splash.png', 800, img.ColorRgb8(0xE6, 0x8A, 0x00));
  _genSportSplash('assets/icon/pickleball_splash.png', 800, img.ColorRgb8(0x2E, 0x7D, 0x32));
  _genSportSplash('assets/icon/soccer_splash.png', 800, img.ColorRgb8(0x2D, 0x8A, 0x2D));

  print('Done: all icons and splash screens generated');
}

/// Sport-specific icon — colored background with 2 players (blue+red) and sport accent
void _genSportIcon(String path, int size, img.Color courtColor, String emoji) {
  final s = size.toDouble();
  final canvas = img.Image(width: size, height: size);

  // Background
  img.fill(canvas, color: _bg);

  // Court area (rounded)
  final cx1 = (s * 0.12).round();
  final cy1 = (s * 0.12).round();
  final cx2 = (s * 0.88).round();
  final cy2 = (s * 0.88).round();
  img.fillRect(canvas, x1: cx1, y1: cy1, x2: cx2, y2: cy2, color: courtColor);
  _rect(canvas, cx1, cy1, cx2, cy2, _white, max(2, (s * 0.005).round()));

  // Net line
  final netY = ((cy1 + cy2) / 2).round();
  _hline(canvas, cx1, cx2, netY, _net, (s * 0.008).round());

  // Two players
  final r = (s * 0.09).round();
  _dot(canvas, (s * 0.35).round(), (s * 0.35).round(), r, _blue);
  _dot(canvas, (s * 0.65).round(), (s * 0.65).round(), r, _red);

  // Movement arrows
  final arrowThk = max(3, (s * 0.006).round());
  _arrow(canvas,
    (s * 0.35).round(), (s * 0.35 + r + s * 0.02).round(),
    (s * 0.35).round(), (netY - s * 0.04).round(),
    _white, arrowThk);
  _arrow(canvas,
    (s * 0.65).round(), (s * 0.65 - r - s * 0.02).round(),
    (s * 0.65).round(), (netY + s * 0.04).round(),
    _white, arrowThk);

  File(path).writeAsBytesSync(img.encodePng(canvas));
}

/// Sport-specific splash — just court color with 2 players, no border
void _genSportSplash(String path, int size, img.Color courtColor) {
  final s = size.toDouble();
  final canvas = img.Image(width: size, height: size);

  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  final cx1 = (s * 0.06).round();
  final cy1 = (s * 0.02).round();
  final cx2 = (s * 0.94).round();
  final cy2 = (s * 0.98).round();

  img.fillRect(canvas, x1: cx1, y1: cy1, x2: cx2, y2: cy2, color: courtColor);
  _rect(canvas, cx1, cy1, cx2, cy2, _white, max(2, (s * 0.005).round()));

  final netY = ((cy1 + cy2) / 2).round();
  _hline(canvas, cx1, cx2, netY, _net, (s * 0.010).round());

  final r = (s * 0.06).round();
  _dot(canvas, (s * 0.35).round(), (s * 0.30).round(), r, _blue);
  _dot(canvas, (s * 0.65).round(), (s * 0.30).round(), r, _blue);
  _dot(canvas, (s * 0.35).round(), (s * 0.70).round(), r, _red);
  _dot(canvas, (s * 0.65).round(), (s * 0.70).round(), r, _red);

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
