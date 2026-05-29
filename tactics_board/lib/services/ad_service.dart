import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../main.dart' show fixedSport;
import '../models/sport_type.dart';

class _AdUnitIds {
  final String appOpen;
  final String interstitial;
  const _AdUnitIds({required this.appOpen, required this.interstitial});
}

/// Live iOS ad unit IDs, keyed by sport. Only sports listed here serve ads;
/// any sport absent from this map — and every Android build, and the
/// multi-sport dev build — runs ad-free (see [AdService.isEnabled]).
///
/// To turn ads on for another sport: create its AdMob app + ad units, add a
/// row here, and wire its AdMob App ID into tool/build_sport.sh.
const Map<SportType, _AdUnitIds> _liveIosAdUnits = {
  SportType.basketball: _AdUnitIds(
    appOpen: 'ca-app-pub-4247621509300508/7826798940',
    interstitial: 'ca-app-pub-4247621509300508/2933868834',
  ),
};

/// Google's official iOS test ad units — always used in debug builds so
/// development traffic never hits the live units (which would risk AdMob
/// policy strikes for invalid traffic).
const _AdUnitIds _testIosAdUnits = _AdUnitIds(
  appOpen: 'ca-app-pub-3940256099942544/5575463023',
  interstitial: 'ca-app-pub-3940256099942544/4411468910',
);

/// Owns AdMob SDK init and the two ad formats used by the single-sport iOS
/// apps: an interstitial shown after the user successfully shares/exports a
/// board, and an app-open ad shown on cold start and on returns to the
/// foreground.
///
/// Every entry point is a no-op unless [isEnabled] — so the shared codebase
/// keeps building ad-free for Android, the multi-sport dev build, and any
/// sport without configured ad units.
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
  static const Duration _minInterstitialGap = Duration(minutes: 3);
  static const Duration _minAppOpenGap = Duration(minutes: 4);
  // How long a suppressNextAppOpen() request stays armed (covers the round
  // trip out to a picker/share/auth flow and back).
  static const Duration _suppressWindow = Duration(seconds: 60);

  bool _initialized = false;

  InterstitialAd? _interstitial;
  bool _interstitialLoading = false;
  DateTime? _lastInterstitialAt;

  AppOpenAd? _appOpenAd;
  bool _appOpenLoading = false;
  DateTime? _appOpenLoadedAt;
  DateTime? _lastAppOpenShownAt;

  bool _isShowingFullScreenAd = false;
  bool _coldStart = true;

  DateTime? _suppressAppOpenUntil; // set before flows that background the app
  int _suppressDepth = 0; // >0 while on a "stage" screen (presentation/run)

  /// Ad units for the current build, or null when ads are off.
  _AdUnitIds? get _ids {
    if (!Platform.isIOS) return null; // iOS-only for now
    final sport = fixedSport;
    if (sport == null) return null; // multi-sport dev build: no ads
    final live = _liveIosAdUnits[sport];
    if (live == null) return null; // sport has no AdMob app yet
    return kDebugMode ? _testIosAdUnits : live;
  }

  bool get isEnabled => _ids != null;

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
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _loadAppOpenAd();
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream.listen((state) {
      if (state == AppState.foreground) _onForeground();
    });
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

  void _showAppOpenAdIfAvailable({required bool fromForeground}) {
    if (!isEnabled || _isShowingFullScreenAd || _suppressed) return;
    final now = DateTime.now();
    if (fromForeground) {
      // Just came back from a picker / share / sign-in flow — don't pounce.
      if (_suppressAppOpenUntil != null && now.isBefore(_suppressAppOpenUntil!)) {
        _suppressAppOpenUntil = null;
        return;
      }
      // Rate-limit foreground returns so frequent app switching isn't punished.
      if (_lastAppOpenShownAt != null &&
          now.difference(_lastAppOpenShownAt!) < _minAppOpenGap) {
        return;
      }
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
