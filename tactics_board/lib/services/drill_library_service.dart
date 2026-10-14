import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../config_constants.dart';
import '../models/drill.dart';
import '../models/session_template.dart';
import '../models/sport_type.dart';
import '../pages/main_shell.dart' show kAppVersion;

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
  Future<Map<SportType, int>>? _counts;

  /// How many drills each sport has, for the number on every picker card.
  ///
  /// Normally from the index gen_drills.py writes beside the libraries:
  /// parsing the fifteen libraries to find out would be 13MB of JSON on the
  /// first page. But a sport that has taken a pack from the server no longer
  /// ships the library it is showing, and the index would keep promising the
  /// count the app was built with — a drill library that grew over the air
  /// would advertise itself as unchanged. So a cached pack, when there is
  /// one, is counted; only the sports with no cache fall back to the index,
  /// and those cost nothing to skip.
  Future<Map<SportType, int>> bundledCounts() => _counts ??= _countDrills();

  Future<Map<SportType, int>> _countDrills() async {
    var index = const <String, dynamic>{};
    try {
      index = jsonDecode(await rootBundle
          .loadString(packageAsset('assets/drills/index.json'))) as Map<String, dynamic>;
    } catch (_) {
      // No index: the cached packs, if any, still answer for themselves.
    }
    return {
      for (final s in SportType.values)
        s: await _cachedCount(s) ?? (index[s.name] as num?)?.toInt() ?? 0,
    };
  }

  /// The drill count of this sport's cached pack, or null when it has none.
  Future<int?> _cachedCount(SportType sport) async {
    // The documents directory is a platform call that, under the test
    // binding, never answers at all — not an error, just a future that
    // hangs, and with it the picker that is waiting for these numbers.
    if (Platform.environment['FLUTTER_TEST'] == 'true') return null;
    try {
      final f = await _cacheFile(sport);
      if (!await f.exists()) return null;
      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return (json['drills'] as List).length;
    } catch (_) {
      return null;
    }
  }

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
            .loadString(sportAsset(sport, 'assets/drills/${sport.name}.json'));
        json = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        // No library for this sport yet.
      }
    }
    _adoptStrings(json);
    _adoptTemplates(sport, json);
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

  /// The tag the server gave the copy in [_cacheFile], beside it so the two
  /// are lost together: a tag without its pack would tell the server we
  /// already have what we no longer have.
  Future<File> _etagFile(SportType sport) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/drills/${sport.name}.etag');
  }

  Future<Map<String, dynamic>?> _readCached(SportType sport) async {
    try {
      final f = await _cacheFile(sport);
      if (!await f.exists()) return null;
      final cached = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      final raw = await rootBundle
          .loadString(sportAsset(sport, 'assets/drills/${sport.name}.json'));
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
      // The tag of the copy already on disk, so an unchanged pack costs a
      // few hundred bytes instead of a download. Every sport a coach opens
      // asks once per launch, and the hub can open fifteen — that was 2MB
      // of pack the phone already had. Only sent when the pack it names is
      // still there to be kept.
      final tag = await _knownEtag(sport);
      final resp = await http
          .get(Uri.parse('$_remoteBase/${sport.name}'),
              headers: tag == null ? null : {'If-None-Match': tag})
          .timeout(const Duration(seconds: 45));
      // 304: what is on disk is what the server would have sent.
      if (resp.statusCode == 304) return;
      if (resp.statusCode != 200) return;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final version = (json['version'] as num?)?.toInt() ?? 0;
      if (version <= haveVersion) return;
      // A pack may one day need a way of drawing that this build does not
      // have; it says so by naming the oldest release that can render it.
      // Refusing it leaves the coach with the library that ships in the
      // app, which is always something that works, instead of a board with
      // a piece missing. Packs that name nothing are for everyone.
      final min = json['minClient'] as String?;
      if (min != null && olderThan(await _clientVersion(), min)) return;
      // Parse before persisting: a half-served or wrong-shaped payload must
      // never become the cache the next launch trusts.
      final parsed = (json['drills'] as List)
          .map((d) => Drill.fromJson(d as Map<String, dynamic>))
          .toList();
      final f = await _cacheFile(sport);
      await f.create(recursive: true);
      await f.writeAsString(resp.body);
      // The tag is written after the pack, never before: a tag for a pack
      // that failed to land would stop the next launch asking for it.
      final etag = resp.headers['etag'];
      final tagFile = await _etagFile(sport);
      if (etag == null) {
        if (await tagFile.exists()) await tagFile.delete();
      } else {
        await tagFile.writeAsString(etag);
      }
      // In use from the next open in this session, not the next launch: a
      // coach who opens the library twice should not need a restart to see
      // a correction that has already arrived. The counts follow.
      _cache[sport] = parsed;
      _counts = null;
      _adoptStrings(json);
      _adoptTemplates(sport, json);
    } catch (_) {
      // Offline, slow, or a bad payload — the bundled library is the product.
    }
  }

  /// Words a pack brings for the labels the library shows around its
  /// drills — category and level chips, usage tags — keyed by the same
  /// translation key the app uses, then by locale ("zh-CN", "en").
  ///
  /// The labels used to live only in the app's translation files, so the
  /// day "Finishing" turned out to read 射门 (shot on goal) for table
  /// tennis, correcting one word of a drill library needed an app release.
  /// A pack can now carry the corrected word and it wins over the app's.
  final Map<String, Map<String, String>> _strings = {};

  /// The ready sessions a pack brings (its `plans`), by sport. Read with
  /// the drills, so a pack that arrives over the air brings its sessions
  /// along; a pack without any leaves the list empty, never stale.
  final Map<SportType, List<SessionTemplate>> _templates = {};

  /// The ready sessions for [sport], once [forSport] has answered.
  List<SessionTemplate> templatesFor(SportType sport) =>
      _templates[sport] ?? const [];

  void _adoptTemplates(SportType sport, Map<String, dynamic>? pack) {
    final raw = pack?['plans'];
    _templates[sport] = raw is List
        ? raw.map(SessionTemplate.fromJson).whereType<SessionTemplate>().toList()
        : const [];
  }

  void _adoptStrings(Map<String, dynamic>? pack) {
    final raw = pack?['strings'];
    if (raw is! Map) return;
    raw.forEach((key, byLocale) {
      if (key is String && byLocale is Map) {
        _strings[key] = {
          for (final e in byLocale.entries)
            if (e.key is String && e.value is String)
              e.key as String: e.value as String,
        };
      }
    });
  }

  /// [key] in the current language: the pack's word when it brought one,
  /// otherwise the app's own translation.
  String label(BuildContext context, String key) {
    final byLocale = _strings[key];
    if (byLocale != null) {
      final tag = context.locale.toLanguageTag();
      final hit = byLocale[tag] ??
          (context.locale.languageCode == 'en' ? byLocale['en'] : null) ??
          byLocale[context.locale.languageCode];
      if (hit != null && hit.isNotEmpty) return hit;
    }
    return key.tr();
  }

  @visibleForTesting
  void debugAdoptStrings(Map<String, dynamic> pack) => _adoptStrings(pack);

  /// The release this build is, for the [olderThan] gate.
  ///
  /// The build passes it in (APP_VERSION); a build that did not — an Xcode
  /// archive, `flutter run` — used to compare as version nothing, and
  /// nothing is older than every pack, so it refused all of them. The
  /// platform knows the version the bundle was stamped with; ask it.
  String? _resolvedVersion;
  Future<String> _clientVersion() async {
    if (kAppVersion.isNotEmpty) return kAppVersion;
    if (_resolvedVersion != null) return _resolvedVersion!;
    try {
      return _resolvedVersion = (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      return _resolvedVersion = '';
    }
  }

  /// The tag of the cached pack, or null when there is no pack to keep.
  Future<String?> _knownEtag(SportType sport) async {
    try {
      if (!await (await _cacheFile(sport)).exists()) return null;
      final f = await _etagFile(sport);
      if (!await f.exists()) return null;
      final tag = (await f.readAsString()).trim();
      return tag.isEmpty ? null : tag;
    } catch (_) {
      return null;
    }
  }

  /// Whether this sport has anything to show, without loading twice.
  Future<bool> hasLibrary(SportType sport) async =>
      (await forSport(sport)).isNotEmpty;
}

/// Whether release [have] came before release [want], comparing the dotted
/// numbers left to right.
///
/// Anything it cannot read counts as new enough. The question is only ever
/// asked to withhold a pack, and withholding one because a version string
/// was a shape this code did not expect would break updates for everybody
/// on the strength of a typo.
@visibleForTesting
bool olderThan(String have, String want) {
  // A version this build cannot name is not "older": see above. The empty
  // string used to read as 0.0.0 and refused every pack.
  if (have.trim().isEmpty || int.tryParse(have.split('.').first) == null) {
    return false;
  }
  final mine = have.split('.');
  final theirs = want.split('.');
  for (var i = 0; i < theirs.length; i++) {
    final a = i < mine.length ? (int.tryParse(mine[i]) ?? 0) : 0;
    final b = int.tryParse(theirs[i]) ?? 0;
    if (a != b) return a < b;
  }
  return false;
}
