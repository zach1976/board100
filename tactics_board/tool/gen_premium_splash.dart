// Premium hub splash — multi-sport ECOSYSTEM brand POSTER.
// Direction: Nike opener / Apple Sports / FIFA brand visual / Olympic motion.
// NOT: centered icon, AI orbit, loading spinner.
// Run: dart run tool/gen_premium_splash.dart
//
// Composition (back → front):
//   1. Deep navy → near-black vertical gradient with soft radial vignette
//   2. Stadium floodlight blooms — large warm-white blurred glows (upper area)
//   3. Atmospheric haze band — soft cool-white horizontal mist mid-canvas
//   4. Pitch perspective lines — faint white lines converging to vanishing
//      point upper-center (worm's-eye field view)
//   5. Grandstand silhouette — subtle dark elliptical shape at bottom edge
//   6. Mid motion curves — 2 lighter secondary trajectory arcs (different
//      angles, suggest multi-sport motion overlapping)
//   7. Hero motion curve — bold parabolic sweep across mid-canvas with
//      ghosting trails (the dominant kinetic element)
//   8. Tiny integrated brand mark — small geometric stamp lower-right area
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

const _W = 1024;
const _H = 1024;

// Palette — premium sports broadcast tones
final _bgTop = img.ColorRgb8(0x0B, 0x12, 0x20); // deep navy
final _bgBot = img.ColorRgb8(0x05, 0x08, 0x10); // near-black
const _lightWarm = [245, 245, 235]; // floodlight warm white
const _coolWhite = [240, 244, 252]; // motion / haze tone
const _accentBlue = [0x60, 0xA5, 0xFA];

void main() {
  final c = img.Image(width: _W, height: _H, numChannels: 4);
  _gradient(c);
  _floodlights(c);
  _haze(c);
  _perspectiveLines(c);
  _grandstand(c);
  _midMotionCurves(c);
  _heroCurve(c);
  _heroGhosts(c);
  _brandMark(c);

  File('assets/icon/splash_logo.png').writeAsBytesSync(img.encodePng(c));
  print('Generated assets/icon/splash_logo.png ($_W x $_H)');
}

// ---------------------------------------------------------------------------
// Layer 1 — gradient + radial vignette (sky → deep ground)
// ---------------------------------------------------------------------------
void _gradient(img.Image c) {
  final cx = _W / 2.0;
  final cy = _H / 2.0;
  final maxD = math.sqrt(cx * cx + cy * cy);
  for (int y = 0; y < _H; y++) {
    final t = y / (_H - 1);
    final br = (_bgTop.r + (_bgBot.r - _bgTop.r) * t);
    final bg = (_bgTop.g + (_bgBot.g - _bgTop.g) * t);
    final bb = (_bgTop.b + (_bgBot.b - _bgTop.b) * t);
    for (int x = 0; x < _W; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final d = math.sqrt(dx * dx + dy * dy) / maxD;
      // Subtle vignette — corners darkened
      final f = 1.0 - d * d * 0.35;
      c.setPixelRgba(x, y, (br * f).round(), (bg * f).round(),
          (bb * f).round(), 255);
    }
  }
}

// ---------------------------------------------------------------------------
// Layer 2 — stadium floodlights (warm soft glows in upper area)
// ---------------------------------------------------------------------------
void _floodlights(img.Image c) {
  final lights = [
    {'cx': 320, 'cy': 200, 'r': 270, 'a': 70, 'blur': 115},
    {'cx': 720, 'cy': 180, 'r': 240, 'a': 60, 'blur': 105},
    {'cx': 870, 'cy': 380, 'r': 160, 'a': 38, 'blur': 80},
    {'cx': 170, 'cy': 360, 'r': 140, 'a': 32, 'blur': 75},
    {'cx': 520, 'cy': 90, 'r': 200, 'a': 45, 'blur': 95},
  ];
  for (final l in lights) {
    final layer = img.Image(width: _W, height: _H, numChannels: 4);
    img.fillCircle(layer,
        x: l['cx'] as int,
        y: l['cy'] as int,
        radius: l['r'] as int,
        color: img.ColorRgba8(
            _lightWarm[0], _lightWarm[1], _lightWarm[2], l['a'] as int));
    img.gaussianBlur(layer, radius: l['blur'] as int);
    img.compositeImage(c, layer);
  }
}

// ---------------------------------------------------------------------------
// Layer 3 — atmospheric haze band across mid-canvas
// ---------------------------------------------------------------------------
void _haze(img.Image c) {
  final layer = img.Image(width: _W, height: _H, numChannels: 4);
  // Soft horizontal band where field would catch most light
  img.fillRect(layer,
      x1: 0,
      y1: 380,
      x2: _W,
      y2: 600,
      color: img.ColorRgba8(_coolWhite[0], _coolWhite[1], _coolWhite[2], 14));
  img.gaussianBlur(layer, radius: 70);
  img.compositeImage(c, layer);
}

// ---------------------------------------------------------------------------
// Layer 4 — perspective pitch lines converging upward
// ---------------------------------------------------------------------------
void _perspectiveLines(img.Image c) {
  // Vanishing point in upper-mid (creates "looking up across field" feel)
  final vpX = _W ~/ 2;
  final vpY = 240;
  final col = img.ColorRgba8(255, 255, 255, 16);

  // 6 lines fanning down from vanishing point to bottom edge
  final bottomXs = [-220, 100, 380, 660, 940, 1240];
  for (final bx in bottomXs) {
    _line(c, x0: bx, y0: _H + 40, x1: vpX, y1: vpY, color: col);
  }

  // 2 horizontal "field lines" cutting across at perspective y-positions
  // (would be horizontal lines in a real perspective view)
  _line(c,
      x0: -50,
      y0: 540,
      x1: _W + 50,
      y1: 540,
      color: img.ColorRgba8(255, 255, 255, 10));
  _line(c,
      x0: -50,
      y0: 720,
      x1: _W + 50,
      y1: 720,
      color: img.ColorRgba8(255, 255, 255, 8));
}

// ---------------------------------------------------------------------------
// Layer 5 — grandstand silhouette (subtle dark elliptical shape at bottom)
// ---------------------------------------------------------------------------
void _grandstand(img.Image c) {
  // A subtle dome at the bottom that reads as "stand" — slightly darker than
  // the local background to imply silhouette without heavy shape.
  final layer = img.Image(width: _W, height: _H, numChannels: 4);
  final cx = _W ~/ 2;
  final cy = _H + 120; // ellipse center below canvas
  final rx = 700;
  final ry = 180;
  for (int y = _H - 220; y < _H; y++) {
    for (int x = 0; x < _W; x++) {
      final dx = (x - cx) / rx;
      final dy = (y - cy) / ry;
      final d = dx * dx + dy * dy;
      if (d < 1.0) {
        final t = 1.0 - d;
        // Darken; alpha rises near the top edge of the silhouette
        final alpha = (t * 110).round().clamp(0, 110);
        layer.setPixelRgba(x, y, 0, 0, 0, alpha);
      }
    }
  }
  img.gaussianBlur(layer, radius: 18);
  img.compositeImage(c, layer);
}

// ---------------------------------------------------------------------------
// Layer 6 — mid-layer secondary motion curves (multi-sport overlap)
// ---------------------------------------------------------------------------
void _midMotionCurves(img.Image c) {
  final cx = _W ~/ 2;
  final cy = _H ~/ 2;

  // Curve A — opposite direction, longer, very faint
  final layerA = img.Image(width: _W, height: _H, numChannels: 4);
  _bezierStroke(layerA,
      p0x: cx + 320,
      p0y: cy - 200,
      p1x: cx - 60,
      p1y: cy + 60,
      p2x: cx - 360,
      p2y: cy + 220,
      thickness: 5,
      baseAlpha: 90);
  img.gaussianBlur(layerA, radius: 3);
  img.compositeImage(c, layerA);

  // Curve B — short curl high above hero curve
  final layerB = img.Image(width: _W, height: _H, numChannels: 4);
  _bezierStroke(layerB,
      p0x: cx - 180,
      p0y: cy - 220,
      p1x: cx,
      p1y: cy - 320,
      p2x: cx + 200,
      p2y: cy - 200,
      thickness: 4,
      baseAlpha: 80);
  img.gaussianBlur(layerB, radius: 2);
  img.compositeImage(c, layerB);
}

// ---------------------------------------------------------------------------
// Layer 7a — hero parabolic motion curve (bold, dominant)
// ---------------------------------------------------------------------------
void _heroCurve(img.Image c) {
  final cx = _W ~/ 2;
  final cy = _H ~/ 2 + 40;

  _bezierStroke(c,
      p0x: cx - 360,
      p0y: cy + 90,
      p1x: cx + 60,
      p1y: cy - 240,
      p2x: cx + 360,
      p2y: cy + 30,
      thickness: 13,
      baseAlpha: 245);

  // Subtle apex highlight (small bright dot at trajectory peak ≈ t=0.45)
  final apexT = 0.45;
  final u = 1 - apexT;
  final apexX =
      (u * u * (cx - 360) + 2 * u * apexT * (cx + 60) + apexT * apexT * (cx + 360))
          .round();
  final apexY =
      (u * u * (cy + 90) + 2 * u * apexT * (cy - 240) + apexT * apexT * (cy + 30))
          .round();
  // Glow halo behind apex
  final glow = img.Image(width: _W, height: _H, numChannels: 4);
  img.fillCircle(glow,
      x: apexX, y: apexY, radius: 35, color: img.ColorRgba8(255, 255, 255, 70));
  img.gaussianBlur(glow, radius: 22);
  img.compositeImage(c, glow);
  // Small bright core
  img.fillCircle(c, x: apexX, y: apexY, radius: 6, color: img.ColorRgb8(255, 255, 255));
}

// ---------------------------------------------------------------------------
// Layer 7b — ghost trails behind hero curve (motion blur replicas)
// ---------------------------------------------------------------------------
void _heroGhosts(img.Image c) {
  final cx = _W ~/ 2;
  final cy = _H ~/ 2 + 40;

  final ghosts = [
    {'dy': -42, 'alpha': 24, 'blur': 11},
    {'dy': -22, 'alpha': 36, 'blur': 8},
    {'dy': 24, 'alpha': 30, 'blur': 9},
    {'dy': 50, 'alpha': 20, 'blur': 12},
  ];

  for (final g in ghosts) {
    final dy = g['dy'] as int;
    final alpha = g['alpha'] as int;
    final blur = g['blur'] as int;

    final layer = img.Image(width: _W, height: _H, numChannels: 4);
    _bezierStroke(layer,
        p0x: cx - 360,
        p0y: cy + 90 + dy,
        p1x: cx + 60,
        p1y: cy - 240 + dy,
        p2x: cx + 360,
        p2y: cy + 30 + dy,
        thickness: 4,
        baseAlpha: alpha);
    img.gaussianBlur(layer, radius: blur);
    img.compositeImage(c, layer);
  }
}

// ---------------------------------------------------------------------------
// Layer 8 — tiny integrated brand mark
// ---------------------------------------------------------------------------
void _brandMark(img.Image c) {
  // Small geometric stamp at lower right — feels like sponsor/brand corner.
  // Two thin stacked accent bars + small dot. Reads as "stamp", not loading.
  final mx = _W - 110;
  final my = _H - 110;
  final col = img.ColorRgba8(_coolWhite[0], _coolWhite[1], _coolWhite[2], 200);
  // Bars
  for (int x = mx - 24; x <= mx + 24; x++) {
    for (int dy = 0; dy < 2; dy++) {
      _blend(c, x, my + dy, col);
      _blend(c, x, my + 8 + dy, col);
    }
  }
  // Tiny dot
  img.fillCircle(c,
      x: mx + 36,
      y: my + 5,
      radius: 3,
      color: img.ColorRgb8(_coolWhite[0], _coolWhite[1], _coolWhite[2]));
}

// ---------------------------------------------------------------------------
// Drawing helpers
// ---------------------------------------------------------------------------

void _line(img.Image c,
    {required int x0,
    required int y0,
    required int x1,
    required int y1,
    required img.Color color}) {
  final dx = (x1 - x0).toDouble();
  final dy = (y1 - y0).toDouble();
  final length = math.sqrt(dx * dx + dy * dy).round();
  if (length == 0) return;
  final ux = dx / length;
  final uy = dy / length;
  for (int s = 0; s < length; s++) {
    final px = (x0 + ux * s).round();
    final py = (y0 + uy * s).round();
    _blend(c, px, py, color);
  }
}

void _bezierStroke(img.Image c,
    {required int p0x,
    required int p0y,
    required int p1x,
    required int p1y,
    required int p2x,
    required int p2y,
    required int thickness,
    required int baseAlpha}) {
  const samples = 1500;
  for (int s = 0; s <= samples; s++) {
    final t = s / samples;
    final u = 1 - t;
    final x = u * u * p0x + 2 * u * t * p1x + t * t * p2x;
    final y = u * u * p0y + 2 * u * t * p1y + t * t * p2y;
    final tx = -2 * u * p0x + 2 * (1 - 2 * t) * p1x + 2 * t * p2x;
    final ty = -2 * u * p0y + 2 * (1 - 2 * t) * p1y + 2 * t * p2y;
    final tlen = math.sqrt(tx * tx + ty * ty);
    final perpX = -ty / tlen;
    final perpY = tx / tlen;
    final endFade = math.sin(t * math.pi).clamp(0.0, 1.0);
    for (int r = -thickness ~/ 2; r <= thickness ~/ 2; r++) {
      final st = (r + thickness / 2) / thickness;
      final smooth = math.sin(st * math.pi).clamp(0.0, 1.0);
      final alpha = (baseAlpha * smooth * endFade).round().clamp(0, 255);
      final col = img.ColorRgba8(255, 255, 255, alpha);
      _blend(c, (x + perpX * r).round(), (y + perpY * r).round(), col);
    }
  }
}

// Porter-Duff "over" composition. Handles transparent destinations correctly
// so drawing onto a fully-transparent layer preserves the source alpha.
void _blend(img.Image c, int x, int y, img.Color src) {
  if (x < 0 || x >= _W || y < 0 || y >= _H) return;
  final sa = src.a / 255.0;
  if (sa <= 0) return;
  final dst = c.getPixel(x, y);
  final da = dst.a / 255.0;
  final outA = sa + da * (1 - sa);
  if (outA <= 0) {
    c.setPixelRgba(x, y, 0, 0, 0, 0);
    return;
  }
  final outR = ((src.r * sa) + (dst.r * da * (1 - sa))) / outA;
  final outG = ((src.g * sa) + (dst.g * da * (1 - sa))) / outA;
  final outB = ((src.b * sa) + (dst.b * da * (1 - sa))) / outA;
  c.setPixelRgba(
      x, y, outR.round(), outG.round(), outB.round(), (outA * 255).round());
}
