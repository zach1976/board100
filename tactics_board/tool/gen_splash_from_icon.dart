// Generates per-sport splash logos from existing photorealistic app icons.
// Run: dart run tool/gen_splash_from_icon.dart
//
// Output: 1024x1024 PNG with brand-color (#1A3A4A) background and the icon
// scaled to 880x880 centered (72px breathing room around it). The result is
// consumed as the source `splash_logo.png` for flutter_native_splash.
import 'dart:io';
import 'package:image/image.dart' as img;

const _bgR = 0x1A;
const _bgG = 0x3A;
const _bgB = 0x4A;
const _canvas = 1024;
const _iconSize = 880;

const _sports = [
  'badminton', 'tableTennis', 'tennis', 'basketball', 'volleyball',
  'pickleball', 'soccer', 'fieldHockey', 'rugby', 'baseball',
  'handball', 'waterPolo', 'sepakTakraw', 'beachTennis', 'footvolley',
];

void main() {
  _generate('assets/icon/app_icon.png', 'assets/icon/splash_logo.png');
  for (final sport in _sports) {
    _generate(
      'assets/icon/${sport}_icon.png',
      'assets/icon/${sport}_splash.png',
    );
  }
  print('Done: ${_sports.length + 1} splash images regenerated');
}

void _generate(String iconPath, String splashPath) {
  final iconFile = File(iconPath);
  if (!iconFile.existsSync()) {
    print('skip (missing): $iconPath');
    return;
  }
  final src = img.decodeImage(iconFile.readAsBytesSync());
  if (src == null) {
    print('skip (decode failed): $iconPath');
    return;
  }

  final canvas = img.Image(width: _canvas, height: _canvas, numChannels: 4);
  img.fill(canvas, color: img.ColorRgb8(_bgR, _bgG, _bgB));

  final scaled = img.copyResize(
    src,
    width: _iconSize,
    height: _iconSize,
    interpolation: img.Interpolation.cubic,
  );
  final offset = (_canvas - _iconSize) ~/ 2;
  img.compositeImage(canvas, scaled, dstX: offset, dstY: offset);

  File(splashPath).writeAsBytesSync(img.encodePng(canvas));
  print('wrote $splashPath');
}
