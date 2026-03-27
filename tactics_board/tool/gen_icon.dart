// Generates app_icon.png (1024x1024) and splash_logo.png (512x512)
// Run from the tactics_board directory:
//   dart run tool/gen_icon.dart

import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  _gen('assets/icon/app_icon.png', 1024);
  _gen('assets/icon/splash_logo.png', 1024);
  print('Done: assets/icon/app_icon.png  assets/icon/splash_logo.png');
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
