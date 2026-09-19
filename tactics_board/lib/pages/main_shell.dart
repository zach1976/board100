import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tactic_meta.dart';
import '../services/recent_boards_service.dart';
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

/// The coach's own things: the boards they saved, and the app's settings.
///
/// Both were reachable already — the boards through the home page, the
/// settings through a ⋯ menu in its corner — which is exactly the problem a
/// tab bar exists to fix: a menu hides what an app can do behind a glyph
/// that says nothing.
class _MinePage extends StatefulWidget {
  final VoidCallback onOpenBoard;
  const _MinePage({required this.onOpenBoard});

  @override
  State<_MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<_MinePage> {
  List<TacticMeta> _mine = const [];
  List<RecentBoard> _recent = const [];

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
    RecentBoardsService.instance.list(state.sportType).then((r) {
      if (mounted) setState(() => _recent = r);
    }).catchError((_) {});
  }

  String _subtitle(TacticMeta m) {
    for (final r in _recent) {
      if (r.kind == RecentBoardKind.tactic && r.id == m.name) {
        return DateFormat.yMd().format(r.openedAt);
      }
    }
    return DateFormat.yMd().format(m.updatedAt);
  }

  Future<void> _open(TacticMeta m) async {
    final state = context.read<TacticsState>();
    await state.loadTactics(m.name);
    widget.onOpenBoard();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<TacticsState>();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(T.screenX, T.s16, T.screenX, T.s32),
        children: [
          Text('tab_mine'.tr(),
              style: const TextStyle(
                  color: T.text, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: T.s24),
          Text('home_mine'.tr(),
              style: const TextStyle(
                  color: T.text, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: T.s12),
          if (_mine.isEmpty)
            Text('home_mine_empty'.tr(),
                style: const TextStyle(color: T.textOff, fontSize: 13.5))
          else
            for (final m in _mine)
              _Entry(
                icon: Icons.dashboard_outlined,
                label: m.name,
                trailing: _subtitle(m),
                onTap: () => _open(m),
              ),
          const SizedBox(height: T.s24),
          _Entry(
            icon: Icons.event_note_outlined,
            label: 'practice_plan'.tr(),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => PracticePlanPage(state: state),
            )),
          ),
          _Entry(
            icon: Icons.language_rounded,
            label: 'menu_language'.tr(),
            onTap: () => LanguagePicker.show(context),
          ),
          _Entry(
            icon: Icons.mail_outline_rounded,
            label: 'menu_contact'.tr(),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ContactPage())),
          ),
          _Entry(
            icon: Icons.person_outline_rounded,
            label: 'menu_login'.tr(),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LoginPage())),
          ),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  const _Entry(
      {required this.icon,
      required this.label,
      this.trailing,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: T.s12),
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
              Text(trailing!,
                  style: const TextStyle(color: T.textOff, fontSize: 12.5)),
            ],
            const SizedBox(width: T.s4),
            const Icon(Icons.chevron_right, size: 18, color: T.textOff),
          ],
        ),
      ),
    );
  }
}
