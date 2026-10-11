import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/sport_home_page.dart';
import 'package:tactics_board/state/tactics_state.dart';

import 'overflow_test.dart' show kLocales;

/// The board is named before it exists, so the name has to be offered.
///
/// A coach who taps 新建空白板 wants a pitch to draw on. An empty field with
/// a dead Apply button asks them to invent a word first, which is the one
/// thing standing between them and the board.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('the name field opens filled, selected and ready to apply',
      (tester) async {
    await EasyLocalization.ensureInitialized();

    late BuildContext ctx;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: kLocales,
        path: 'assets/translations',
        saveLocale: false,
        startLocale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: ChangeNotifierProvider<TacticsState>(
              create: (_) =>
                  TacticsState(sportType: SportType.soccer, preview: true),
              child: Builder(builder: (c) {
                ctx = c;
                return const Scaffold(body: SizedBox.shrink());
              }),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Two boards saved, and one of them is already called what the counter
    // would reach for first — so the suggestion has to step past it.
    // `taken` is passed so nothing touches the disk: real file I/O never
    // completes inside a widget test's fake-async zone.
    createNamedBoard(ctx, taken: {'Tuesday shape', 'Board 3'});
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Board 4',
        reason: 'three is taken, so the offer steps to four');
    expect(field.controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 7),
        reason: 'selected, so the first keystroke replaces it');

    // And Create works on the first tap, which is the whole point. (The
    // button said "Apply" until 2026-10-11; it names something new.)
    final apply = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Create'));
    expect(apply.onPressed, isNotNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
