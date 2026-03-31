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
      create: (_) => TacticsState(sportType: fs ?? SportType.basketball),
      child: MaterialApp(
        title: 'Tactics Board',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0D0D1A),
          appBarTheme: const AppBarTheme(
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          sliderTheme: const SliderThemeData(
            thumbColor: Colors.blue,
            activeTrackColor: Colors.blue,
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
