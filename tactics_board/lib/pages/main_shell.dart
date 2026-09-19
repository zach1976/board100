import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sport_type.dart';
import '../models/tactic_meta.dart';
import '../services/auth_service.dart';
import '../services/drill_library_service.dart';
import '../services/drill_notes_service.dart';
import '../services/practice_service.dart';
import '../state/tactics_state.dart';
import '../ui/tokens.dart';
import '../widgets/language_picker.dart';
import 'drill_library_page.dart';
import 'home_page.dart';
import 'practice_plan_page.dart';
import 'sport_home_page.dart';

/// The four places the app is, with a bar to move between them.
///
/// Everything used to be reached by pushing: the home page pushed the board,
/// the library, the plan, and a coach three pages deep had to walk back out
/// the way they came. A bar says what the app contains before anything is
/// tapped, which is the one thing a stack of routes can never do.
///
/// The board is the exception and stays a pushed route. It is a full-screen
/// editor with its own chrome — a back button, plan mode, the external
/// display — all of it built around being something you enter and leave, and
/// hosting it in a tab would leave a back button on screen with nothing
/// behind it. Tapping 战术板 opens it; closing it drops you back on the tab
/// you came from.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  Future<void> _openBoard() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TacticsBoardHomePage()),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TacticsState>();
    return Scaffold(
      backgroundColor: T.bg0,
      body: IndexedStack(
        index: _tab,
        children: [
          const SportHomePage(),
          // Built once, kept alive: the library holds a search box, a scroll
          // position and a set of filters, and a coach who taps away to check
          // a board expects to come back to the list they had, not to the top
          // of an unfiltered one.
          DrillLibraryPage(state: state, onLoaded: _openBoard),
          _MinePage(onOpenBoard: _openBoard),
        ],
      ),
      bottomNavigationBar: _TabBar(
        current: _tab,
        onTap: (i) {
          // The board is an action, not a destination — see the note above.
          if (i == 1) {
            _openBoard();
            return;
          }
          setState(() => _tab = i > 1 ? i - 1 : i);
        },
      ),
    );
  }
}

/// The bar itself.
///
/// Drawn rather than taken from BottomNavigationBar: that widget brings
/// Material 3's own surface colour, its own ripple and its own idea of how
/// much a selected label should grow, and undoing all three came to more
/// code than drawing four columns.
class _TabBar extends StatelessWidget {
  /// The index into the four items, where 1 is the board — which is not a
  /// tab and therefore never stays selected.
  final int current;
  final void Function(int) onTap;
  const _TabBar({required this.current, required this.onTap});

  static const _items = [
    (Icons.home_rounded, 'tab_home'),
    (Icons.dashboard_outlined, 'tab_board'),
    (Icons.fitness_center, 'tab_drills'),
    (Icons.person_outline_rounded, 'tab_mine'),
  ];

  /// The bar's index for the tab showing: 0 → 0, 1 → 2, 2 → 3, because the
  /// board sits at 1 in the bar and nowhere in the stack.
  int get _selected => current == 0 ? 0 : current + 1;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: T.surface,
        border: Border(top: BorderSide(color: T.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _TabButton(
                    icon: _items[i].$1,
                    label: _items[i].$2.tr(),
                    selected: i == _selected,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? T.accent : T.textOff;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 3),
          // One line, shrinking rather than wrapping: "Ejercicios" under a
          // quarter of a 320pt screen has 80pt to live in.
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        ],
      ),
    );
  }
}

/// The coach's own things: what they have made, and what the app is set to.
///
/// Both were reachable already — the boards through the home page, the
/// settings through a ⋯ menu in its corner — which is exactly the problem a
/// tab bar exists to fix: a menu hides what an app can do behind a glyph
/// that says nothing. Gathering them is not enough on its own, though: four
/// naked rows under a title is a page that looks unfinished however finished
/// it is. So it opens with who you are, says what you have made in numbers
/// before it says it in a list, and groups the rest into the two things a
/// settings page is actually made of — your content, and your preferences.
class _MinePage extends StatefulWidget {
  final VoidCallback onOpenBoard;
  const _MinePage({required this.onOpenBoard});

  @override
  State<_MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<_MinePage> {
  List<TacticMeta> _mine = const [];
  int _plans = 0;
  int _starred = 0;
  int _drills = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final state = context.read<TacticsState>();
    state.listSavedTacticMetas().then((m) {
      m.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (mounted) setState(() => _mine = m);
    }).catchError((_) {});
    PracticeService.listNames(state.sportType).then((n) {
      if (mounted) setState(() => _plans = n.length);
    }).catchError((_) {});
    DrillNotesService.instance.all(state.sportType).then((m) {
      final n = m.values.where((e) => e.starred).length;
      if (mounted) setState(() => _starred = n);
    }).catchError((_) {});
    DrillLibraryService.instance.forSport(state.sportType).then((d) {
      if (mounted) setState(() => _drills = d.length);
    }).catchError((_) {});
  }

  Future<void> _push(Widget page) async {
    await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) _refresh();
  }

  Future<void> _openLibrary({bool mine = false, bool starred = false}) async {
    final state = context.read<TacticsState>();
    await DrillLibraryPage.push(
      context,
      state,
      openMine: mine,
      starredOnly: starred,
      onLoaded: widget.onOpenBoard,
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<TacticsState>();
    final auth = AuthService.instance;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(T.screenX, T.s16, T.screenX, T.s32),
        children: [
          Text('tab_mine'.tr(),
              style: const TextStyle(
                  color: T.text, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: T.s16),

          // Who you are, or the offer to become someone. The account is the
          // one thing on this page that is about the coach rather than about
          // the app, so it goes first and looks different from the rest.
          _AccountCard(
            name: auth.isLoggedIn ? (auth.userName ?? 'menu_login'.tr()) : null,
            email: auth.userEmail,
            onTap: () => _push(const LoginPage()).then((_) {
              if (mounted) setState(() {});
            }),
          ),
          const SizedBox(height: T.s16),

          // What the coach has made, in one line. A settings page that opens
          // with an empty list says "you have nothing"; three numbers say
          // what there is to come back to.
          Row(
            children: [
              Expanded(
                  child: _Stat(
                      value: '${_mine.length}', label: 'home_mine'.tr())),
              const SizedBox(width: T.s8),
              Expanded(
                  child: _Stat(
                      value: '$_starred', label: 'home_starred'.tr())),
              const SizedBox(width: T.s8),
              Expanded(
                  child: _Stat(
                      value: '$_drills', label: 'tab_drills'.tr())),
            ],
          ),
          const SizedBox(height: T.s24),

          _SectionLabel('mine_content'.tr()),
          _Card(children: [
            _Row(
              icon: Icons.dashboard_outlined,
              label: 'home_mine'.tr(),
              trailing: _mine.isEmpty ? 'mine_none'.tr() : '${_mine.length}',
              onTap: () => _openLibrary(mine: true),
            ),
            _Row(
              icon: Icons.star_outline_rounded,
              label: 'home_starred'.tr(),
              trailing: _starred == 0 ? 'mine_none'.tr() : '$_starred',
              onTap: () => _openLibrary(starred: true),
            ),
            _Row(
              icon: Icons.event_note_outlined,
              label: 'practice_plan'.tr(),
              trailing: _plans == 0 ? 'mine_none'.tr() : '$_plans',
              onTap: () => _push(PracticePlanPage(state: state)),
              last: true,
            ),
          ]),
          const SizedBox(height: T.s24),

          _SectionLabel('mine_settings'.tr()),
          _Card(children: [
            _Row(
              icon: Icons.language_rounded,
              label: 'menu_language'.tr(),
              // The language names itself: a coach looking for Thai is
              // looking for ภาษาไทย, not for "th_TH".
              trailing: LanguagePicker.nameOf(context.locale),
              onTap: () => LanguagePicker.show(context),
            ),
            _Row(
              icon: Icons.mail_outline_rounded,
              label: 'menu_contact'.tr(),
              onTap: () => _push(const ContactPage()),
              last: true,
            ),
          ]),

          const SizedBox(height: T.s32),
          // The version, small and grey at the bottom, where a support email
          // can ask for it and the coach can find it without being told how.
          Center(
            child: Text(
              '${'home_board_title'.tr(args: [state.sportType.displayName])}  ·  $kAppVersion',
              style: const TextStyle(color: T.textOff, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// The app's own version, shown at the foot of the settings page.
///
/// A constant rather than package_info_plus: the number is already written
/// in pubspec.yaml and nowhere else, one more plugin to read it back at
/// runtime is a dependency for a string, and a wrong version here is a
/// support email that goes one round longer than it had to.
const String kAppVersion = '2.0.0';

class _AccountCard extends StatelessWidget {
  final String? name;
  final String? email;
  final VoidCallback onTap;
  const _AccountCard({this.name, this.email, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final signedIn = name != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(T.s16),
        decoration: BoxDecoration(
          borderRadius: T.brLg,
          border: Border.all(color: T.border),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF16302A), T.surface],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: T.accent.withValues(alpha: 0.14),
                border: Border.all(color: T.accent.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.person_outline_rounded,
                  color: T.accent, size: 24),
            ),
            const SizedBox(width: T.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(signedIn ? name! : 'menu_login'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: T.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(signedIn ? (email ?? '') : 'login_subtitle'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: T.textDim, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: T.textOff),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: T.s12, horizontal: T.s8),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: T.brMd,
        border: Border.all(color: T.border),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: T.accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()])),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: T.textDim, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: T.s8),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              color: T.textOff,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8)),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: T.brMd,
        border: Border.all(color: T.border),
      ),
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  /// No hairline under the last row: a divider against the card's own edge
  /// reads as a line that failed to line up with something.
  final bool last;
  const _Row(
      {required this.icon,
      required this.label,
      this.trailing,
      required this.onTap,
      this.last = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(T.s12, T.s12, T.s12, T.s12),
        decoration: last
            ? null
            : const BoxDecoration(
                border: Border(bottom: BorderSide(color: T.border))),
        child: Row(
          children: [
            Icon(icon, size: 19, color: T.textDim),
            const SizedBox(width: T.s12),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: T.text, fontSize: 15)),
            ),
            if (trailing != null) ...[
              const SizedBox(width: T.s8),
              Flexible(
                child: Text(trailing!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: T.textOff, fontSize: 13)),
              ),
            ],
            const SizedBox(width: T.s4),
            const Icon(Icons.chevron_right, size: 18, color: T.textOff),
          ],
        ),
      ),
    );
  }
}
