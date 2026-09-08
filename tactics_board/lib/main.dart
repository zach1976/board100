import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'ui/tokens.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config_constants.dart';
import 'models/sport_type.dart';
import 'services/ad_service.dart';
import 'services/purchase_service.dart';
import 'services/tap_guard.dart';
import 'state/tactics_state.dart';
import 'pages/sport_selection_page.dart';
import 'pages/home_page.dart';

/// Non-null when the app is built for a single sport. Set by a shell app's
/// `main()` via [ConfigConstants.fixedSportType]; defaults to the legacy
/// --dart-define=SPORT=badminton build path.
SportType? get fixedSport => ConfigConstants.fixedSportType;

/// True when this is a single-sport flavor (no sport selection page)
bool get isSingleSportApp => fixedSport != null;

/// Decide which English variant to default a device to on first launch.
/// Countries listed below say "Soccer"; everywhere else en-XX defaults to
/// British English (en-GB) which uses "Football". Returns null for non-English
/// devices so EasyLocalization handles them with its normal resolution.
Locale? _resolveEnglishStartLocale() {
  final device = WidgetsBinding.instance.platformDispatcher.locale;
  if (device.languageCode != 'en') return null;
  const soccerCountries = {'US', 'CA', 'AU', 'NZ', 'ZA', 'PH'};
  return soccerCountries.contains(device.countryCode)
      ? const Locale('en', 'US')
      : const Locale('en', 'GB');
}

/// Entry point of the multi-sport hub app. A single-sport shell app does not
/// call this — it fills in [ConfigConstants] and calls [mainReal] instead.
void main() => mainReal();

/// The real startup, shared by the hub and every single-sport shell. Callers
/// must have finished writing [ConfigConstants] before calling it.
Future<void> mainReal() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Before anything awaited: the app-open ad's cold-start window is measured
  // from here, not from AdService.init() further down. See AdService.
  AdService.markLaunch();
  await EasyLocalization.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
        Locale('en', 'US'),
        Locale('en', 'GB'),
        Locale('ja', 'JP'),
        Locale('ko', 'KR'),
        Locale('fr', 'FR'),
        Locale('es', 'ES'),
        Locale('vi', 'VN'),
        Locale('th', 'TH'),
        Locale('id', 'ID'),
        Locale('ms', 'MY'),
      ],
      path: packageAsset('assets/translations'),
      startLocale: _resolveEnglishStartLocale(),
      fallbackLocale: const Locale('en', 'US'),
      child: const TacticsBoardApp(),
    ),
  );
  // Resolve the Pro (ad-removal) entitlement before ads decide what to load, so
  // a Pro user never even preloads an ad. No-op unless a RevenueCat key was
  // injected for this build. See PurchaseService.
  await PurchaseService.instance.init();
  // Fire-and-forget: no-op unless this is an iOS single-sport build with
  // configured ad units (currently only Basketball). See AdService.
  AdService.instance.init();
}

class TacticsBoardApp extends StatelessWidget {
  const TacticsBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = fixedSport;
    return ChangeNotifierProvider(
      lazy: false,
      create: (_) => TacticsState(sportType: fs ?? SportType.basketball),
      // Records every pointer-down so AdService can refuse to show a
      // full-screen ad under a finger that's mid-drag. See TapGuard.
      child: TapGuard.wrap(
        MaterialApp(
          title: 'Tactics Board',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: T.accent, // teal/emerald
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: T.surfaceHi,
            appBarTheme: const AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle.light,
            ),
            sliderTheme: const SliderThemeData(
              thumbColor: T.accent,
              activeTrackColor: T.accent,
              inactiveTrackColor: T.surfaceHi,
              overlayColor: T.accentFill,
            ),
            // One shape and one type scale for all twenty-three dialogs.
            // They each used to set their own background, corner radius and
            // title style, so a confirm looked different depending on which
            // screen raised it.
            dialogTheme: const DialogThemeData(
              backgroundColor: T.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 16,
              shape: RoundedRectangleBorder(borderRadius: T.brLg),
              titleTextStyle: T.section,
              contentTextStyle: T.body,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: T.accent,
                minimumSize: const Size(64, T.tap),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: T.surfaceHi,
              contentTextStyle: T.body,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: T.brMd),
              // A floating SnackBar defaults to sitting 8pt off the bottom,
              // which on the board puts it under the home indicator and on
              // top of the toolbar capsule — a drill's name arrived half cut
              // off, covering the controls it was telling you to use. Lift it
              // clear of the capsule (60 tall, 12 up) instead.
              insetPadding: EdgeInsets.fromLTRB(T.s16, T.s8, T.s16, 96),
            ),
          ),
          home: fs != null
              ? const TacticsBoardHomePage()
              : const SportSelectionPage(),
        ),
      ),
    );
  }
}
