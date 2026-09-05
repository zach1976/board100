import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/services/drill_library_service.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/drill_library_sheet.dart';

/// The release-checklist overflow sweep (zachs_app_base.md §7.1), as a test.
///
/// Twelve locales is too many to eyeball every release, and the words that
/// break a layout are never the ones you would have checked. So the check is
/// mechanical: render the screen in each one at the narrowest size the apps
/// support, and fail if Flutter reports an overflow.
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
      } else if (text.contains('dev.flutter.pigeon.in_app_purchase')) {
        // The sheet asks PurchaseService whether there is a store, and the
        // billing plugin then tries to reach a platform that is not there.
        // Environmental, not a layout problem — and swallowing only this one
        // channel keeps every other error failing the test as it should.
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

  testWidgets('the drill library survives every locale on the narrowest phone',
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
    // tester.view, not binding.setSurfaceSize: the latter left MediaQuery
    // reporting the 800x600 test default while the render surface changed
    // underneath it, so every one of these sweeps was silently running at
    // tablet size — and the mismatch produced a 122-pixel "overflow" in the
    // player edit bar that does not exist at any real size.
    tester.view.physicalSize = Size(kNarrow.width * 3, kNarrow.height * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final watch = OverflowWatch()..start();
    addTearDown(watch.stop);

    // Badminton: the most category chips whose words were overridden, and a
    // library that is nearly all families, so the variant chips get exercised.
    final state = TacticsState(sportType: SportType.badminton);
    state.setCanvasSizeSilent(const Size(320, 568));
    await tester.runAsync(
        () => DrillLibraryService.instance.forSport(SportType.badminton));

    late BuildContext ctx;
    final sheet = ValueNotifier<TacticsState>(state);
    addTearDown(sheet.dispose);
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
              home: Scaffold(
                body: ValueListenableBuilder<TacticsState>(
                  valueListenable: sheet,
                  builder: (context, s, _) =>
                      DrillLibrarySheet(key: ValueKey(s.sportType), state: s),
                ),
              ),
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
      broken.addAll(watch.drain('$locale'));

      // Scroll through the list: a chip row that fits at the top can still
      // overflow further down, where the longest family names are.
      for (var page = 0; page < 3; page++) {
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump(const Duration(milliseconds: 50));
        broken.addAll(watch.drain('$locale scrolled $page'));
      }
    }

    expect(broken, isEmpty, reason: broken.join('\n'));

    // Every other sport, at the three locales whose words run longest. The
    // chip labels come from a shared vocabulary, so badminton exercises the
    // mechanism — this is insurance against one sport owning a phrase nobody
    // thought about.
    const longWinded = [Locale('fr', 'FR'), Locale('vi', 'VN'), Locale('th', 'TH')];
    for (final sport in SportType.values) {
      if (sport == SportType.badminton) continue;
      final other = TacticsState(sportType: sport);
      other.setCanvasSizeSilent(const Size(320, 568));
      await tester.runAsync(() => DrillLibraryService.instance.forSport(sport));

      for (final locale in longWinded) {
        await ctx.setLocale(locale);
        sheet.value = other;
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        broken.addAll(watch.drain('${sport.name} $locale'));
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 50));
        broken.addAll(watch.drain('${sport.name} $locale scrolled'));
      }
    }

    debugDefaultTargetPlatformOverride = null;
    expect(broken, isEmpty, reason: broken.join('\n'));
  });
}
