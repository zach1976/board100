import 'models/sport_type.dart';

/// Build-shape configuration, set once by an app's `main()` before
/// [mainReal] runs (see main.dart).
///
/// This package is both the multi-sport hub app *and* the shared core that
/// every single-sport app depends on. A single-sport app is a thin shell —
/// its own platform folders (bundle id, icons, plist) plus a ~20-line
/// `main()` that fills this class in and hands over. Mirrors ScoreSyncer's
/// `ConfigConstants` / `FrontEnd` split.
///
/// Every field defaults to the legacy `--dart-define` build path, so the
/// existing `tool/build_sport.sh <sport>` flow keeps producing identical
/// binaries until all 16 shells exist and are verified.
class ConfigConstants {
  ConfigConstants._();

  /// This package's name — the prefix Flutter gives its assets when another
  /// package depends on it (`packages/tactics_board/assets/...`).
  static const String packageName = 'tactics_board';

  /// Fixed sport of a single-sport app; null means the multi-sport hub, which
  /// shows the sport-selection page.
  static SportType? fixedSportType = _sportFromDefine;

  /// The hub app ships ads too (its own AdMob app), but the plain multi-sport
  /// dev build must stay ad-free. Single-sport apps ignore this — their units
  /// are keyed by [fixedSportType] in AdService.
  static bool hubAdsEnabled = String.fromEnvironment('HUB_ADS') == '1';

  /// True when this package is a *dependency* of a shell app rather than the
  /// running app itself: its bundled assets then resolve under
  /// `packages/tactics_board/`. See [packageAsset].
  static bool hasPackagePath = false;

  /// Legacy compile-time flavor: `--dart-define=SPORT=badminton`.
  static const String sportDefine = String.fromEnvironment('SPORT');

  static SportType? get _sportFromDefine {
    if (sportDefine.isEmpty) return null;
    for (final s in SportType.values) {
      if (s.name == sportDefine) return s;
    }
    return null;
  }
}

/// Resolves a bundled asset path for whichever way this package is running.
/// Use for every `assets/...` string handed to Flutter — a shell app's root
/// bundle has this package's assets under `packages/<name>/`.
String packageAsset(String assetPath) =>
    ConfigConstants.hasPackagePath
        ? 'packages/${ConfigConstants.packageName}/$assetPath'
        : assetPath;
