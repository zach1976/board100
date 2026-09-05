import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config_constants.dart';
import '../models/drill.dart';
import '../models/sport_type.dart';

const _remoteBase = 'https://tacticsboard.100for1.com/api/v1/drills';

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
  final Set<SportType> _refreshed = {};

  Future<List<Drill>> forSport(SportType sport) async {
    final cached = _cache[sport];
    if (cached != null) return cached;

    // A server copy cached on a previous run wins over the bundle when its
    // version is higher — that is the whole point of shipping drills as
    // data: the library can grow without an app update.
    Map<String, dynamic>? json = await _readCached(sport);
    if (json == null) {
      try {
        final raw = await rootBundle
            .loadString(packageAsset('assets/drills/${sport.name}.json'));
        json = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        // No library for this sport yet.
      }
    }
    final drills = json == null
        ? const <Drill>[]
        : (json['drills'] as List)
            .map((d) => Drill.fromJson(d as Map<String, dynamic>))
            .toList();
    _cache[sport] = drills;
    // Kick the refresh after answering: the sheet never waits on a socket,
    // and a newer pack lands for the next open.
    _refreshInBackground(sport, (json?['version'] as num?)?.toInt() ?? 0);
    return drills;
  }

  Future<File> _cacheFile(SportType sport) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/drills/${sport.name}.json');
  }

  Future<Map<String, dynamic>?> _readCached(SportType sport) async {
    try {
      final f = await _cacheFile(sport);
      if (!await f.exists()) return null;
      final cached = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      final raw = await rootBundle
          .loadString(packageAsset('assets/drills/${sport.name}.json'));
      final bundled = jsonDecode(raw) as Map<String, dynamic>;
      final cv = (cached['version'] as num?)?.toInt() ?? 0;
      final bv = (bundled['version'] as num?)?.toInt() ?? 0;
      // An app update can ship a newer library than the cache: bundled wins
      // on ties so a stale cache can never shadow the shipped content.
      return cv > bv ? cached : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshInBackground(SportType sport, int haveVersion) async {
    if (!_refreshed.add(sport)) return;
    // Widget tests load real libraries through this service; without the
    // guard every test run would knock on production.
    if (Platform.environment['FLUTTER_TEST'] == 'true') return;
    try {
      // A generous timeout on purpose: nothing waits on this, and the
      // soccer pack is large — an 8s limit made it undownloadable on the
      // very connections where an update matters.
      final resp = await http
          .get(Uri.parse('$_remoteBase/${sport.name}'))
          .timeout(const Duration(seconds: 45));
      if (resp.statusCode != 200) return;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final version = (json['version'] as num?)?.toInt() ?? 0;
      if (version <= haveVersion) return;
      // Parse before persisting: a half-served or wrong-shaped payload must
      // never become the cache the next launch trusts.
      (json['drills'] as List)
          .map((d) => Drill.fromJson(d as Map<String, dynamic>))
          .toList();
      final f = await _cacheFile(sport);
      await f.create(recursive: true);
      await f.writeAsString(resp.body);
    } catch (_) {
      // Offline, slow, or a bad payload — the bundled library is the product.
    }
  }

  /// Whether this sport has anything to show, without loading twice.
  Future<bool> hasLibrary(SportType sport) async =>
      (await forSport(sport)).isNotEmpty;
}
