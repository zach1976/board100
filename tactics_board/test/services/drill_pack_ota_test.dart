import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/services/drill_library_service.dart';

/// What lets a drill-data change reach installed apps without a release.
void main() {
  group('olderThan — the minClient gate', () {
    test('a release before the one a pack needs is refused', () {
      expect(olderThan('2.0.0', '2.1.0'), isTrue);
      expect(olderThan('1.1.25', '2.0.0'), isTrue);
      expect(olderThan('2.0.2', '2.0.10'), isTrue);
    });
    test('the same or a later release takes it', () {
      expect(olderThan('2.0.0', '2.0.0'), isFalse);
      expect(olderThan('2.2.1', '2.0.0'), isFalse);
      expect(olderThan('2.0', '2.0.0'), isFalse);
    });
    test('a build that cannot name its version is not refused everything', () {
      // An Xcode archive or `flutter run` passes no APP_VERSION; it used to
      // compare as 0.0.0 and turn down every pack.
      expect(olderThan('', '2.0.0'), isFalse);
      expect(olderThan('dev', '2.0.0'), isFalse);
    });
  });

  testWidgets('a pack\'s label words win over the app\'s own', (t) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    DrillLibraryService.instance.debugAdoptStrings({
      'strings': {
        'drill_cat_finishing': {'zh-CN': '终结', 'en': 'Scoring'},
      },
    });
    final seen = <String, String>{};
    for (final locale in const [Locale('zh', 'CN'), Locale('en', 'US'), Locale('ja', 'JP')]) {
      // Tear the tree down: a second EasyLocalization in the same slot keeps
      // the first one's locale and ignores its own startLocale.
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpWidget(EasyLocalization(
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US'), Locale('ja', 'JP')],
        path: 'assets/translations',
        saveLocale: false,
        startLocale: locale,
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(
          builder: (outer) => MaterialApp(
            localizationsDelegates: outer.localizationDelegates,
            supportedLocales: outer.supportedLocales,
            locale: outer.locale,
            home: Builder(builder: (context) {
              seen['${locale.languageCode}/cat'] = DrillLibraryService.instance
                  .label(context, 'drill_cat_finishing');
              seen['${locale.languageCode}/level'] = DrillLibraryService
                  .instance
                  .label(context, 'drill_level_foundation');
              return const SizedBox();
            }),
          ),
        ),
      ));
      // The translation files load off the asset bundle, outside fake time.
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await t.pumpAndSettle();
    }
    expect(seen['zh/cat'], '终结');
    expect(seen['en/cat'], 'Scoring');
    // No word in the pack for Japanese: the app's own translation.
    expect(seen['ja/cat'], isNot('drill_cat_finishing'));
    expect(seen['ja/cat'], isNot('Scoring'));
    // A key the pack does not mention is the app's, untouched.
    expect(seen['en/level'], isNot('drill_level_foundation'));
  });
}
