import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../config_constants.dart';
import '../models/drill.dart';
import '../models/sport_type.dart';

/// Loads the drills that ship with the app.
///
/// Read-only and bundled: no network, no account, and available on a pitch
/// with no signal — which is where a coach opens a session plan. Sports with
/// no library yet return an empty list rather than an error, so the UI can
/// simply not offer the entry.
class DrillLibraryService {
  DrillLibraryService._();
  static final DrillLibraryService instance = DrillLibraryService._();

  final Map<SportType, List<Drill>> _cache = {};

  Future<List<Drill>> forSport(SportType sport) async {
    final cached = _cache[sport];
    if (cached != null) return cached;

    List<Drill> drills;
    try {
      final raw = await rootBundle
          .loadString(packageAsset('assets/drills/${sport.name}.json'));
      final json = jsonDecode(raw) as Map<String, dynamic>;
      drills = (json['drills'] as List)
          .map((d) => Drill.fromJson(d as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // No library for this sport yet.
      drills = const [];
    }
    _cache[sport] = drills;
    return drills;
  }

  /// Whether this sport has anything to show, without loading twice.
  Future<bool> hasLibrary(SportType sport) async =>
      (await forSport(sport)).isNotEmpty;
}
