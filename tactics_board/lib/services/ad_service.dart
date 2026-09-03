import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config_constants.dart';
import '../models/sport_type.dart';
import 'purchase_service.dart';
import 'tap_guard.dart';

class _AdUnitIds {
  /// Null disables the app-open format for this sport/platform while leaving
  /// the interstitial live — used to circuit-break units whose CTR indicates
  /// accidental clicks (see the commented-out entries in [_liveAdUnits]).
  final String? appOpen;
  final String interstitial;
  const _AdUnitIds({this.appOpen, required this.interstitial});
}

class _SportAds {
  final _AdUnitIds? ios;
  final _AdUnitIds? android;
  const _SportAds({this.ios, this.android});
}

/// Live ad unit IDs, keyed by sport then platform. AdMob treats iOS and
/// Android as separate apps, so each platform has its own App ID and ad units.
/// Only the (sport, platform) pairs present here serve ads; anything absent —
/// and the multi-sport dev build — runs ad-free (see [AdService.isEnabled]).
///
/// To turn ads on for another sport/platform: create its AdMob app + ad units,
/// fill the slot here, and wire its AdMob App ID into the matching build script
/// (tool/build_sport.sh for iOS, tool/build_sport_android.sh for Android).
const Map<SportType, _SportAds> _liveAdUnits = {
  SportType.badminton: _SportAds(
    ios: _AdUnitIds(
      appOpen: 'ca-app-pub-4247621509300508/9358005481',
      interstitial: 'ca-app-pub-4247621509300508/9599194001',
    ),
    android: _AdUnitIds(
      appOpen: 'ca-app-pub-4247621509300508/3517001384',
      interstitial: 'ca-app-pub-4247621509300508/9832952121',
    ),
  ),
  SportType.tableTennis: _SportAds(
    ios: _AdUnitIds(
      appOpen: 'ca-app-pub-4247621509300508/6704225901',
      interstitial: 'ca-app-pub-4247621509300508/3666999022',
    ),
  ),
  SportType.tennis: _SportAds(
    ios: _AdUnitIds(
      appOpen: 'ca-app-pub-4247621509300508/3197437187',
      interstitial: 'ca-app-pub-4247621509300508/3568972271',
    ),
  ),
  SportType.basketball: _SportAds(
    ios: _AdUnitIds(
      appOpen: 'ca-app-pub-4247621509300508/7826798940',
      interstitial: 'ca-app-pub-4247621509300508/2933868834',
    ),
    android: _AdUnitIds(
      appOpen: 'ca-app-pub-4247621509300508/6072836362',
      interstitial: 'ca-app-pub-4247621509300508/9741148862',
    ),
  ),
  SportType.volleyball: _SportAds(
    ios: _AdUnitIds(
      // App-open circuit-broken 2026-07-26 — CTR 13.7%. Restore once the
      // TapGuard rollout has held CTR <= 4% for two weeks:
      // appOpen: 'ca-app-pub-4247621509300508/2353917358',
      interstitial: 'ca-app-pub-4247621509300508/6733357514',
    ),
  ),
  SportType.pickleball: _SportAds(
    ios: _AdUnitIds(
      // App-open circuit-broken 2026-07-26 — CTR 21.3%, the worst unit in the
      // portfolio. Restore only after TapGuard proves out:
      // appOpen: 'ca-app-pub-4247621509300508/2447462291',
      interstitial: 'ca-app-pub-4247621509300508/3133858004',
    ),
  ),
  SportType.soccer: _SportAds(
    ios: _AdUnitIds(
      appOpen: 'ca-app-pub-4247621509300508/9521960937',
      interstitial: 'ca-app-pub-4247621509300508/3511086352',
    ),
  ),
  SportType.fieldHockey: _SportAds(
    ios: _AdUnitIds(
      // App-open circuit-broken 2026-07-26 — CTR 16.1%:
      // appOpen: 'ca-app-pub-4247621509300508/5456769018',
      interstitial: 'ca-app-pub-4247621509300508/9003086181',
    ),
    // Android CTR is 4.4% portfolio-wide and this unit is not on the risk
    // list — leave it serving.
    android: _AdUnitIds(
      appOpen: 'ca-app-pub-4247621509300508/4349062288',
      interstitial: 'ca-app-pub-4247621509300508/7637266687',
    ),
  ),
  SportType.rugby: _SportAds(
    ios: _AdUnitIds(
      // App-open circuit-broken 2026-07-26 — CTR 15.9%:
      // appOpen: 'ca-app-pub-4247621509300508/5171652386',
      interstitial: 'ca-app-pub-4247621509300508/5611847534',
    ),
  ),
  SportType.baseball: _SportAds(
    ios: _AdUnitIds(
      appOpen: 'ca-app-pub-4247621509300508/8832907249',
      interstitial: 'ca-app-pub-4247621509300508/3022177363',
    ),
  ),
  SportType.handball: _SportAds(
    ios: _AdUnitIds(
      appOpen: 'ca-app-pub-4247621509300508/9685612467',
      interstitial: 'ca-app-pub-4247621509300508/3311775804',
    ),
  ),
  SportType.waterPolo: _SportAds(
    ios: _AdUnitIds(
      appOpen: 'ca-app-pub-4247621509300508/8258192176',
      interstitial: 'ca-app-pub-4247621509300508/1481030838',
    ),
  ),
  SportType.beachTennis: _SportAds(
    ios: _AdUnitIds(
      appOpen: 'ca-app-pub-4247621509300508/1651209779',
      interstitial: 'ca-app-pub-4247621509300508/2871957953',
    ),
  ),
  SportType.footvolley: _SportAds(
    ios: _AdUnitIds(
      appOpen: 'ca-app-pub-4247621509300508/4143687349',
      interstitial: 'ca-app-pub-4247621509300508/3580580568',
    ),
  ),
  SportType.sepakTakraw: _SportAds(
    ios: _AdUnitIds(
      appOpen: 'ca-app-pub-4247621509300508/6195135611',
      interstitial: 'ca-app-pub-4247621509300508/2389576375',
    ),
  ),
};

/// The multi-sport hub app ("Tactics Board – Coach Playbook", com.zach.tacticsBoard)
/// has no fixed sport, so it can't be keyed in [_liveAdUnits]. It opts into ads
/// via --dart-define=HUB_ADS=1 (set by the hub build in tool/build_all_ipa.sh for
/// iOS and tool/build_sport_android.sh for Android); the plain multi-sport dev
/// build leaves this off and stays ad-free.
// NB: the build passes --dart-define=HUB_ADS=1, and bool.fromEnvironment only
// treats the literal "true" as true (a value of "1" yields false), so compare
// the string explicitly — otherwise hub ads silently stay off.
bool get _hubAdsEnabled => ConfigConstants.hubAdsEnabled;

/// Ad units for the hub app's own AdMob apps (iOS App ID ~5907516538,
/// Android App ID ~4532136942 — AdMob treats them as separate apps).
const _AdUnitIds _hubIosAdUnits = _AdUnitIds(
  appOpen: 'ca-app-pub-4247621509300508/8532312895',
  interstitial: 'ca-app-pub-4247621509300508/4078062561',
);
const _AdUnitIds _hubAndroidAdUnits = _AdUnitIds(
  appOpen: 'ca-app-pub-4247621509300508/8478743512',
  interstitial: 'ca-app-pub-4247621509300508/1809393384',
);

/// Google's official test ad units (per platform) — always used in debug builds
/// so development traffic never hits the live units (which would risk AdMob
/// policy strikes for invalid traffic).
const _AdUnitIds _testIosAdUnits = _AdUnitIds(
  appOpen: 'ca-app-pub-3940256099942544/5575463023',
  interstitial: 'ca-app-pub-3940256099942544/4411468910',
);
const _AdUnitIds _testAndroidAdUnits = _AdUnitIds(
  appOpen: 'ca-app-pub-3940256099942544/9257395921',
  interstitial: 'ca-app-pub-3940256099942544/1033173712',
);

/// Owns AdMob SDK init and the two ad formats used by the single-sport apps
/// (iOS + Android): an interstitial shown after the user successfully
/// shares/exports a board, and an app-open ad shown on cold start and on
/// returns to the foreground.
///
/// Every entry point is a no-op unless [isEnabled] — so the shared codebase
/// keeps building ad-free for the multi-sport dev build and any
/// sport/platform without configured ad units.
///
/// Guards against the classic app-open misfires: callers wrap flows that send
/// the app to the background (photo picker, share sheet, sign-in) with
/// [suppressNextAppOpen], and "stage" screens (presentation mode, practice
/// run) bracket themselves with [pushAdSuppression]/[popAdSuppression] so no
/// ad interrupts live coaching. Both formats are additionally rate-limited.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // Don't show two full-screen ads back-to-back; give users breathing room.
  //
  // NB: these gaps are deliberately NOT lengthened. The 2026-07 AdMob data
  // showed the flashcard apps running a 3-minute gap at a 2.5% CTR while these
  // board apps ran a 4-minute gap at 11.5% — frequency was never the driver of
  // the accidental clicks, finger-on-glass was. Widening the gap would cost
  // impressions without moving CTR. See TapGuard.
  static const Duration _minInterstitialGap = Duration(minutes: 3);
  static const Duration _minAppOpenGap = Duration(minutes: 4);
  // How long a suppressNextAppOpen() request stays armed (covers the round
  // trip out to a picker/share/auth flow and back).
  static const Duration _suppressWindow = Duration(seconds: 60);

  // An app-open ad must appear within this window after launch. If the ad only
  // finishes loading later (slow network), showing it would drop an ad in the
  // middle of an active session — keep it cached for the next cold start
  // instead. Mirrors ScoreSyncer's _coldStartWindow.
  static const Duration _coldStartWindow = Duration(seconds: 12);
  // Reopening this quickly after backgrounding is a continuation of the same
  // session, not a fresh launch — no ad.
  static const Duration _backgroundReopenGrace = Duration(seconds: 30);

  // Daily ceilings. Even a user who launches the app all day should not see
  // more than this.
  static const int _maxAppOpenPerDay = 3;
  static const int _maxInterstitialsPerDay = 6;

  static const String _kFirstLaunchSeen = 'ad_first_launch_seen';
  static const String _kCountersDate = 'ad_counters_date';
  static const String _kAppOpenCount = 'ad_app_open_count';
  static const String _kInterstitialCount = 'ad_interstitial_count';
  static const String _kLastBackgroundAt = 'ad_last_background_at';

  bool _initialized = false;

  SharedPreferences? _prefs;
  String _countersDate = '';
  int _appOpenToday = 0;
  int _interstitialToday = 0;
  // True for the whole of the very first session after install — a brand-new
  // user should meet the app, not an ad.
  bool _isFirstLaunch = false;

  InterstitialAd? _interstitial;
  bool _interstitialLoading = false;
  DateTime? _lastInterstitialAt;

  AppOpenAd? _appOpenAd;
  bool _appOpenLoading = false;
  DateTime? _appOpenLoadedAt;
  DateTime? _lastAppOpenShownAt;
  DateTime? _backgroundedAt; // when the app last actually went to background

  bool _isShowingFullScreenAd = false;
  bool _coldStart = true;
  DateTime? _coldStartDeadline;

  /// Wall-clock launch time, stamped by main() before any awaited startup work.
  /// Static because it has to be recorded long before the singleton's [init].
  static DateTime? _launchAt;

  /// Call once at the very top of main(), before any `await`.
  static void markLaunch() => _launchAt ??= DateTime.now();

  // At most one deferred retry is in flight per format, so a user who keeps
  // touching the screen doesn't accumulate a queue of pending shows.
  bool _appOpenRetryPending = false;
  bool _interstitialRetryPending = false;

  DateTime? _suppressAppOpenUntil; // set before flows that background the app
  int _suppressDepth = 0; // >0 while on a "stage" screen (presentation/run)

  /// Ad units for the current build, or null when ads are off.
  _AdUnitIds? get _ids {
    // Pro (ad-removal) purchase disables every ad — load AND show, since both
    // paths funnel through here / isEnabled. Read live so a mid-session
    // purchase or restore takes effect immediately.
    if (PurchaseService.instance.hasPro) return null;
    final sport = ConfigConstants.fixedSportType;
    if (sport == null) {
      // Multi-sport hub app: ads only when the production hub build opts in
      // (HUB_ADS=1); the plain dev build stays ad-free. Has its own AdMob app
      // on both iOS and Android.
      if (!_hubAdsEnabled) return null;
      if (Platform.isIOS) return kDebugMode ? _testIosAdUnits : _hubIosAdUnits;
      if (Platform.isAndroid) {
        return kDebugMode ? _testAndroidAdUnits : _hubAndroidAdUnits;
      }
      return null;
    }
    final ads = _liveAdUnits[sport];
    if (ads == null) return null; // sport has no AdMob app yet
    if (Platform.isIOS) {
      return ads.ios == null ? null : (kDebugMode ? _testIosAdUnits : ads.ios);
    }
    if (Platform.isAndroid) {
      return ads.android == null
          ? null
          : (kDebugMode ? _testAndroidAdUnits : ads.android);
    }
    return null;
  }

  bool get isEnabled => _ids != null;

  /// Whether this build is configured to show ads at all on the current
  /// platform, INDEPENDENT of a Pro purchase. Gates the "Remove Ads" entry: an
  /// app/platform with no ads must not offer to remove them (App Store 3.1.1 /
  /// accurate metadata — selling something that does nothing gets rejected).
  bool get servesAds {
    final sport = ConfigConstants.fixedSportType;
    if (sport == null) {
      return _hubAdsEnabled && (Platform.isIOS || Platform.isAndroid);
    }
    final ads = _liveAdUnits[sport];
    if (ads == null) return false;
    if (Platform.isIOS) return ads.ios != null;
    if (Platform.isAndroid) return ads.android != null;
    return false;
  }

  bool get _suppressed => _suppressDepth > 0;

  /// Suppress the *next* return-to-foreground app-open ad. Call this right
  /// before presenting the photo picker, a share sheet, or a sign-in flow —
  /// otherwise coming back from them would wrongly trigger an app-open ad.
  /// No-op when ads are disabled, so it's safe to call unconditionally.
  void suppressNextAppOpen() {
    if (!isEnabled) return;
    _suppressAppOpenUntil = DateTime.now().add(_suppressWindow);
  }

  /// Bracket a screen that must stay ad-free (presentation mode, practice run)
  /// with push/pop. Reference-counted so nested/overlapping screens are safe.
  void pushAdSuppression() {
    if (!isEnabled) return;
    _suppressDepth++;
  }

  void popAdSuppression() {
    if (_suppressDepth > 0) _suppressDepth--;
  }

  /// Initialize the SDK and preload both formats. Safe to call once from
  /// main(); returns immediately when ads are disabled for this build.
  Future<void> init() async {
    if (_initialized || !isEnabled) return;
    _initialized = true;
    // Anchor the cold-start window to launch, not to whenever the SDK and
    // SharedPreferences happen to finish initializing. main() awaits
    // PurchaseService (a StoreKit round trip) before it ever calls init(), so
    // measuring from here would restart the window mid-session on a slow
    // network — exactly the mid-session app-open this gate exists to stop.
    _coldStartDeadline = (_launchAt ?? DateTime.now()).add(_coldStartWindow);
    await _loadCounters();
    await MobileAds.instance.initialize();
    // Deliberately no interstitial preload here. The only trigger is a
    // completed board share, which 2026-07 reporting showed is rare enough
    // that eager preloading burned 5,520 requests for 6 impressions (0.1%
    // show rate). Callers now warm it up when a share actually begins — see
    // [warmUpInterstitial]. The app-open ad still preloads, since its trigger
    // (this very launch) is certain.
    _loadAppOpenAd();
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream.listen((state) {
      if (state == AppState.foreground) {
        _onForeground();
      } else if (state == AppState.background) {
        _onBackground();
      }
    });
  }

  // ── Daily caps + first-launch state ─────────────────────────────────────────

  static String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  /// Read the persisted counters, rolling them over if the stored date isn't
  /// today. Also latches the first-launch flag. Best-effort: if
  /// SharedPreferences is unavailable the caps simply fall back to the
  /// in-memory session counts.
  Future<void> _loadCounters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      _isFirstLaunch = !(prefs.getBool(_kFirstLaunchSeen) ?? false);
      if (_isFirstLaunch) await prefs.setBool(_kFirstLaunchSeen, true);
      final today = _todayStr();
      _countersDate = prefs.getString(_kCountersDate) ?? '';
      if (_countersDate == today) {
        _appOpenToday = prefs.getInt(_kAppOpenCount) ?? 0;
        _interstitialToday = prefs.getInt(_kInterstitialCount) ?? 0;
      } else {
        _countersDate = today;
        _appOpenToday = 0;
        _interstitialToday = 0;
      }
    } catch (_) {
      // Non-fatal — caps degrade to per-session only.
    }
  }

  /// Roll the counters over if the day changed mid-session.
  void _rollCountersIfNeeded() {
    final today = _todayStr();
    if (_countersDate == today) return;
    _countersDate = today;
    _appOpenToday = 0;
    _interstitialToday = 0;
  }

  bool get _appOpenUnderDailyCap {
    _rollCountersIfNeeded();
    return _appOpenToday < _maxAppOpenPerDay;
  }

  bool get _interstitialUnderDailyCap {
    _rollCountersIfNeeded();
    return _interstitialToday < _maxInterstitialsPerDay;
  }

  void _recordShown({required bool appOpen}) {
    _rollCountersIfNeeded();
    if (appOpen) {
      _appOpenToday++;
    } else {
      _interstitialToday++;
    }
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setString(_kCountersDate, _countersDate);
    prefs.setInt(_kAppOpenCount, _appOpenToday);
    prefs.setInt(_kInterstitialCount, _interstitialToday);
  }

  void _onBackground() {
    // Record when the app truly went to the background so a quick return
    // (< _minAppOpenGap) is treated as the same session and skips the app-open
    // ad. Ignore background events triggered by our own full-screen ad — those
    // aren't the user leaving the app.
    if (_isShowingFullScreenAd) return;
    final now = DateTime.now();
    _backgroundedAt = now;
    // Mirror to disk so the next launch can tell "user came back after 10s"
    // from "user launched fresh" even if iOS killed the process in between.
    _prefs?.setInt(_kLastBackgroundAt, now.millisecondsSinceEpoch);
  }

  void _onForeground() {
    // Cold start is handled once the first app-open ad loads (see
    // _loadAppOpenAd); ignore the launch-time foreground event here.
    if (_coldStart) return;
    _showAppOpenAdIfAvailable(fromForeground: true);
  }

  // ── Interstitial: shown after a successful board share/export ───────────────

  void _loadInterstitial() {
    final id = _ids?.interstitial;
    if (id == null || _interstitial != null || _interstitialLoading) return;
    // Nothing can be shown today, so a request now is pure waste. The daily
    // counter rolls over at midnight and the next launch reloads.
    if (!_interstitialUnderDailyCap) {
      _trace(
          'interstitial load skipped: daily cap $_interstitialToday/$_maxInterstitialsPerDay');
      return;
    }
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialLoading = false;
        },
        onAdFailedToLoad: (_) {
          _interstitial = null;
          _interstitialLoading = false;
        },
      ),
    );
  }

  /// Start loading the interstitial because a share flow just began. Gives the
  /// request the several seconds the share sheet takes, so the ad is ready by
  /// the time [maybeShowInterstitial] runs — without paying for a request on
  /// every launch that never shares. No-op if one is already loaded/loading or
  /// today's cap is spent.
  void warmUpInterstitial() {
    if (!isEnabled) return;
    _loadInterstitial();
  }

  /// Show the interstitial if one is ready and we're outside the rate-limit
  /// window; otherwise just (re)load for next time. Never blocks the caller —
  /// fire-and-forget after a *successful* share. No-op on a "stage" screen.
  void maybeShowInterstitial() {
    if (!isEnabled || _suppressed) return;
    final now = DateTime.now();
    if (_lastInterstitialAt != null &&
        now.difference(_lastInterstitialAt!) < _minInterstitialGap) {
      return; // throttled — keep the loaded ad for later
    }
    if (!_interstitialUnderDailyCap) return;
    // Last gate before showing: never drop an ad under a moving finger.
    // Deferred rather than dropped — a share flow usually settles within a
    // second, and the ad stays cached either way.
    if (TapGuard.isFingerActive) {
      _trace('interstitial deferred: finger active');
      if (!_interstitialRetryPending) {
        _interstitialRetryPending = true;
        Future.delayed(TapGuard.retryDelay, () {
          _interstitialRetryPending = false;
          if (!TapGuard.isFingerActive) maybeShowInterstitial();
        });
      }
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _isShowingFullScreenAd = true;
        _lastInterstitialAt = DateTime.now();
        _recordShown(appOpen: false);
        _trace(
            'interstitial SHOWN ($_interstitialToday/$_maxInterstitialsPerDay today)');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFullScreenAd = false;
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        _isShowingFullScreenAd = false;
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }

  // ── App-open: cold start + guarded returns to the foreground ────────────────

  void _loadAppOpenAd() {
    final id = _ids?.appOpen;
    if (id == null || _appOpenLoading) return;
    // Same as the interstitial: don't request what today's cap forbids showing.
    if (!_appOpenUnderDailyCap) {
      _trace('app open load skipped: daily cap $_appOpenToday/$_maxAppOpenPerDay');
      return;
    }
    _appOpenLoading = true;
    AppOpenAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadedAt = DateTime.now();
          _appOpenLoading = false;
          if (_coldStart) {
            _coldStart = false;
            _showAppOpenAdIfAvailable(fromForeground: false);
          }
        },
        onAdFailedToLoad: (_) {
          _appOpenLoading = false;
          _coldStart = false;
        },
      ),
    );
  }

  // App-open ads expire ~4h after load; don't show a stale one.
  bool get _appOpenExpired {
    final at = _appOpenLoadedAt;
    if (at == null) return true;
    return DateTime.now().difference(at) > const Duration(hours: 4);
  }

  /// Debug-only trace of why an ad did or didn't show. Verifying the gates on
  /// a simulator (see zachs_app_base.md 4.1) is otherwise guesswork.
  static void _trace(String msg) {
    if (kDebugMode) debugPrint('[Ads] $msg');
  }

  void _showAppOpenAdIfAvailable({required bool fromForeground}) {
    if (!isEnabled || _isShowingFullScreenAd || _suppressed) {
      _trace('app open skipped: disabled/showing/suppressed');
      return;
    }
    // Gate: brand-new install — the first session stays ad-free.
    if (_isFirstLaunch) {
      _trace('app open gated: first launch');
      return;
    }
    // Gate: daily ceiling.
    if (!_appOpenUnderDailyCap) {
      _trace('app open gated: daily cap $_appOpenToday/$_maxAppOpenPerDay');
      return;
    }
    final now = DateTime.now();
    if (!fromForeground) {
      // Cold start: only show if the ad got here inside the launch window.
      // A slow load that resolves later is kept cached, not dropped into the
      // middle of an active session — that mid-session surprise is precisely
      // what generated this app family's 11.5% accidental-click rate.
      final deadline = _coldStartDeadline;
      if (deadline == null || now.isAfter(deadline)) {
        _trace('app open gated: cold-start window expired');
        return;
      }
      // iOS routinely kills backgrounded apps. To the user, reopening seconds
      // later is one continuous session; to us it looks like a cold start.
      // The in-memory _backgroundedAt is gone with the process, so consult the
      // persisted stamp.
      final lastBgMs = _prefs?.getInt(_kLastBackgroundAt);
      if (lastBgMs != null &&
          now.millisecondsSinceEpoch - lastBgMs <
              _backgroundReopenGrace.inMilliseconds) {
        _trace('app open gated: reopened within background grace');
        return;
      }
    }
    if (fromForeground) {
      // Just came back from a picker / share / sign-in flow — don't pounce.
      if (_suppressAppOpenUntil != null && now.isBefore(_suppressAppOpenUntil!)) {
        _suppressAppOpenUntil = null;
        return;
      }
      // Don't punish a quick return: if the app was only backgrounded briefly
      // (< _minAppOpenGap), reopening counts as the same session — no ad.
      if (_backgroundedAt != null &&
          now.difference(_backgroundedAt!) < _minAppOpenGap) {
        return;
      }
      // Rate-limit foreground returns so frequent app switching isn't punished.
      if (_lastAppOpenShownAt != null &&
          now.difference(_lastAppOpenShownAt!) < _minAppOpenGap) {
        return;
      }
    }
    // Last gate before showing: never drop an ad under a moving finger. In a
    // drawing app this is the gate that matters — a cold-start ad landing
    // mid-stroke is the single largest source of accidental clicks.
    if (TapGuard.isFingerActive) {
      _trace('app open deferred: finger active');
      if (!_appOpenRetryPending) {
        _appOpenRetryPending = true;
        Future.delayed(TapGuard.retryDelay, () {
          _appOpenRetryPending = false;
          // Re-runs every gate, so a retry that lands past the cold-start
          // window correctly declines to show.
          if (!TapGuard.isFingerActive) {
            _showAppOpenAdIfAvailable(fromForeground: fromForeground);
          }
        });
      }
      return;
    }
    final ad = _appOpenAd;
    if (ad == null || _appOpenExpired) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _loadAppOpenAd();
      return;
    }
    _appOpenAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _isShowingFullScreenAd = true;
        _lastAppOpenShownAt = DateTime.now();
        _recordShown(appOpen: true);
        _trace('app open SHOWN ($_appOpenToday/$_maxAppOpenPerDay today)');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFullScreenAd = false;
        ad.dispose();
        _loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        _isShowingFullScreenAd = false;
        ad.dispose();
        _loadAppOpenAd();
      },
    );
    ad.show();
  }
}
