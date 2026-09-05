import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/player_photo.dart';
import 'package:tactics_board/models/practice.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/practice_history_page.dart';
import 'package:tactics_board/pages/practice_plan_page.dart';
import 'package:tactics_board/pages/practice_run_page.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/attendance_sheet.dart';

import 'overflow_test.dart' show kLocales, kNarrow;

/// The overflow sweep for the practice screens.
///
/// These are constructed directly rather than navigated to, because they are
/// public and take everything they need — and because reaching the run page
/// through the UI would mean building a plan by hand in every locale.
///
/// Content is deliberately awkward: a long plan name, a long drill name and a
/// long player name, since a screen only overflows when something in it is
/// longer than whoever laid it out expected.
///
/// Like overflow_screens_test.dart, no OverflowWatch — Flutter's own handling
/// fails the test and names the widget and line.
void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('the practice screens survive every locale on a small phone',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = Size(kNarrow.width * 3, kNarrow.height * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = TacticsState(sportType: SportType.badminton);
    state.setCanvasSizeSilent(kNarrow);

    final practice = Practice(
      name: 'Tuesday evening, full squad',
      notes: 'Bring the spare shuttles and the cones from the shed.',
      items: [
        PracticeItem(
            tacticName: 'Footwork to the forehand net',
            durationMinutes: 12,
            note: 'Split step before the opponent hits, not after.'),
        PracticeItem(tacticName: 'Clear cross-court', durationMinutes: 8),
        PracticeItem(tacticName: 'Conditioned game 2v1', durationMinutes: 20),
      ],
    );

    final squad = [
      for (var i = 0; i < 8; i++)
        PlayerPhoto(
          id: 'p$i',
          filename: '',
          createdAtMs: 0,
          playerName: i.isEven ? 'Alexandrine' : 'Bo',
          jerseyNumber: '${i + 1}',
        ),
    ];

    final screen = ValueNotifier<Widget>(PracticePlanPage(state: state));
    addTearDown(screen.dispose);

    late BuildContext ctx;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: kLocales,
        path: 'assets/translations',
        saveLocale: false,
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(builder: (context) {
          ctx = context;
          return ChangeNotifierProvider<TacticsState>.value(
            value: state,
            child: MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: ValueListenableBuilder<Widget>(
                valueListenable: screen,
                builder: (context, w, _) => w,
              ),
            ),
          );
        }),
      ),
    );

    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await settle();

    final shown = <String>[];
    for (final locale in kLocales) {
      await ctx.setLocale(locale);
      await settle();
      final tag = '${locale.languageCode}-${locale.countryCode}';

      for (final entry in <(String, Widget)>[
        ('practice plan', PracticePlanPage(state: state)),
        ('practice run', PracticeRunPage(state: state, practice: practice)),
        ('practice history', const PracticeHistoryPage(
            sport: SportType.badminton)),
        ('attendance', Scaffold(body: AttendanceSheet(squad: squad))),
      ]) {
        screen.value = entry.$2;
        await settle();
        shown.add('$tag ${entry.$1}');
        // Back to something inert so the next locale switch does not tear a
        // page down mid-layout.
        screen.value = const SizedBox.shrink();
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    debugDefaultTargetPlatformOverride = null;
    expect(shown.length, kLocales.length * 4,
        reason: 'the sweep rendered fewer screens than it should have:\n'
            '${shown.join('\n')}');
  });
}
