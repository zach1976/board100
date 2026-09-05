import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/services/drill_library_service.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/drill_library_sheet.dart';

/// The overflow sweep again at the largest text size people really use.
///
/// Its own file, not another test in overflow_test.dart: only the first
/// EasyLocalization widget in a file renders anything, so a second
/// pumpWidget there would render an empty tree and pass without checking.
///
const kLocales = [
  Locale('en', 'US'), Locale('en', 'GB'), Locale('zh', 'CN'),
  Locale('zh', 'TW'), Locale('ja', 'JP'), Locale('ko', 'KR'),
  Locale('es', 'ES'), Locale('fr', 'FR'), Locale('id', 'ID'),
  Locale('ms', 'MY'), Locale('th', 'TH'), Locale('vi', 'VN'),
];

/// iPhone SE — the narrowest screen the apps still support.
const kNarrow = Size(320, 568);

/// Collects overflow reports for the length of a test.
///
/// Not tester.takeException(): a RenderFlex overflow is reported during paint
/// and does not surface there, so the first version of this test printed
/// pages of overflow warnings and still passed. Hooking FlutterError.onError
/// is what actually catches them.
class OverflowWatch {
  final List<String> hits = [];
  FlutterExceptionHandler? _previous;

  void start() {
    _previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('overflowed by')) {
        hits.add(text.split('\n').first);
      } else {
        _previous?.call(details);
      }
    };
  }

  void stop() => FlutterError.onError = _previous;

  /// What overflowed since the last call, tagged with where we were.
  List<String> drain(String where) {
    final out = hits.toSet().map((h) => '$where — $h').toList();
    hits.clear();
    return out;
  }
}

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('and again at the largest accessibility text size',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    // The sheet asks PurchaseService whether there is a store, which builds
    // InAppPurchase.instance. On the default test platform that is the
    // Android plugin, and it immediately opens a billing connection that
    // fails asynchronously — an uncaught error the binding then blames on
    // this test. Pointing at iOS picks the StoreKit plugin, which does not
    // connect until asked.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await EasyLocalization.ensureInitialized();
    await tester.binding.setSurfaceSize(kNarrow);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final watch = OverflowWatch()..start();
    addTearDown(watch.stop);

    final state = TacticsState(sportType: SportType.badminton);
    state.setCanvasSizeSilent(const Size(320, 568));
    await tester.runAsync(
        () => DrillLibraryService.instance.forSport(SportType.badminton));

    late BuildContext ctx;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: kLocales,
        path: 'assets/translations',
        saveLocale: false,
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(
          builder: (context) {
            ctx = context;
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              builder: (context, child) => MediaQuery(
                // iOS "Larger Text" tops out around 3.1x; 2.0 is the setting
                // people actually run all day, and is where a layout that
                // merely fits stops fitting.
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2.0)),
                child: child!,
              ),
              home: Scaffold(body: DrillLibrarySheet(state: state)),
            );
          },
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final broken = <String>[];
    for (final locale in kLocales) {
      await ctx.setLocale(locale);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      broken.addAll(watch.drain('$locale @2x'));
    }

    debugDefaultTargetPlatformOverride = null;
    expect(broken, isEmpty, reason: broken.join('\n'));
  });
}
