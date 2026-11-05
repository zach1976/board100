import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../config_constants.dart';
import '../models/sport_type.dart';

/// Pictures a court painter lays on the pitch — today the football goals.
///
/// A court is painted with lines, which is right for everything a pitch has
/// painted on it and wrong for the goal, which stands on it: drawn as a
/// stroked box with a mesh inside it the goal never stopped looking like a
/// diagram next to figures that are pictures. So the goal is a picture too,
/// one per end, because a goal seen from above and a little in front shows
/// its mouth at the far end and its back at the near one.
///
/// The same arrangement as [PlayerArt]: asked for lazily, decoded once, and
/// a notifier that bumps when one lands so the painter listening to it
/// repaints. Until then — and for a sport that ships no picture — the
/// painter draws its box.
class CourtArt {
  CourtArt._();

  /// Bumped once per image decoded.
  static final ValueNotifier<int> ready = ValueNotifier<int>(0);

  static final Map<String, ui.Image> _images = {};
  static final Set<String> _asked = {};
  static final Set<String> _missing = {};

  /// The goal at the [view] end — `far` shows its mouth, `near` its back —
  /// or null while it decodes or if this sport has none.
  static ui.Image? goal(SportType sport, String view) {
    final key = '${sport.name}_$view';
    if (_asked.add(key)) {
      _load(key, sportAsset(sport, 'assets/icon/goal_${sport.name}_$view.png'));
    }
    return _images[key];
  }

  /// Decodes every goal and waits. Only the headless board renderer needs
  /// it: it shoots a frame the moment it pumps and would otherwise catch
  /// every first board with its boxes still drawn.
  static Future<void> warm() async {
    final want = <String>{};
    for (final s in SportType.values) {
      for (final v in ['far', 'near']) {
        want.add('${s.name}_$v');
        goal(s, v);
      }
    }
    while (!want.every((k) => _images.containsKey(k) || _missing.contains(k))) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  static Future<void> _load(String key, String path) async {
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _images[key] = frame.image;
      ready.value++;
    } catch (_) {
      // No picture, no crash: the painter keeps its box.
      _missing.add(key);
    }
  }
}
