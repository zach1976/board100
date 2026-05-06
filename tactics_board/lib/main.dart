import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/sport_type.dart';
import 'state/tactics_state.dart';
import 'pages/sport_selection_page.dart';
import 'pages/home_page.dart';

/// Read at compile time: --dart-define=SPORT=badminton
const sportFlavorName = String.fromEnvironment('SPORT');

/// Non-null when app is built for a single sport
SportType? get fixedSport {
  if (sportFlavorName.isEmpty) return null;
  for (final s in SportType.values) {
    if (s.name == sportFlavorName) return s;
  }
  return null;
}

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      path: 'assets/translations',
      startLocale: _resolveEnglishStartLocale(),
      fallbackLocale: const Locale('en', 'US'),
      child: const TacticsBoardApp(),
    ),
  );
}

class TacticsBoardApp extends StatelessWidget {
  const TacticsBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = fixedSport;
    return ChangeNotifierProvider(
      lazy: false,
      create: (_) => TacticsState(sportType: fs ?? SportType.basketball),
      child: MaterialApp(
        title: 'Tactics Board',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00BFA5), // teal/emerald
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF1A3A4A),
          appBarTheme: const AppBarTheme(
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          sliderTheme: const SliderThemeData(
            thumbColor: Color(0xFF00BFA5),
            activeTrackColor: Color(0xFF00BFA5),
            inactiveTrackColor: Colors.white24,
          ),
        ),
        home: fs != null
            ? const TacticsBoardHomePage()
            : const SportSelectionPage(),
      ),
    );
  }
}
