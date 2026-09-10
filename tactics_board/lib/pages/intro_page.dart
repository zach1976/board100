import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sport_type.dart';
import '../ui/primitives.dart';
import '../ui/tokens.dart';
import '../widgets/sport_glyph.dart';

/// What this app is, in the four seconds before the coach decides.
///
/// The home page answers "what do I do now" but never "what is this" — and
/// the one thing that separates this from every other tactics board, a
/// library of drills with the coaching written out, is the thing a new user
/// is least likely to find on their own: it is behind a card called "what to
/// run today" that they will scroll past on the way to drawing.
///
/// Three panels, skippable from the first, shown once. A fourth would be one
/// more thing between someone and the board they came for.
class IntroPage extends StatefulWidget {
  final SportType sportType;

  /// How many drills THIS app ships. Not the 624 in the repository: a
  /// single-sport build carries only its own sport's library, so the intro
  /// of Soccer Board promising six hundred drills is a promise of five
  /// hundred it does not have.
  ///
  /// Null until the library has been read. The intro does NOT wait for it —
  /// a first impression that begins with a blank frame while a file loads is
  /// a worse first impression than one without a number in it, and the
  /// reader is on the first panel long before the second one is reached.
  final int? drillCount;

  /// Runs when the intro is finished or skipped — the app carries on.
  final VoidCallback onDone;

  const IntroPage({
    super.key,
    required this.sportType,
    this.drillCount,
    required this.onDone,
  });

  static const _prefKey = 'intro_seen';

  /// Whether it still has to be shown. False forever after the first time.
  static Future<bool> shouldShow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) != true;
    } catch (_) {
      // No prefs is a first run in every way that matters, but showing the
      // intro on every launch because storage is broken would be worse than
      // never showing it.
      return false;
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    } catch (_) {}
  }

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final _pages = PageController();
  int _at = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await IntroPage.markSeen();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final panels = <_Panel>[
      _Panel(
        icon: Icons.gesture,
        title: 'intro_board_t'.tr(),
        body: 'intro_board_b'.tr(),
      ),
      _Panel(
        icon: Icons.menu_book_outlined,
        title: widget.drillCount == null
            ? 'intro_drills_t_plain'.tr()
            : 'intro_drills_t'.tr(args: ['${widget.drillCount}']),
        body: 'intro_drills_b'.tr(),
      ),
      _Panel(
        icon: Icons.event_note_outlined,
        title: 'intro_plan_t'.tr(),
        body: 'intro_plan_b'.tr(),
      ),
    ];
    final last = _at == panels.length - 1;
    return Scaffold(
      backgroundColor: T.bg0,
      body: SafeArea(
        child: Column(
          children: [
            // Skip is on every panel including the first: someone who knows
            // what a tactics board is should never have to page through an
            // explanation of one.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, T.s8, T.s12, 0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _finish,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: T.s12, vertical: T.s8),
                    child: Text('intro_skip'.tr(),
                        style: const TextStyle(
                            color: T.textDim,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _at = i),
                children: [
                  for (final p in panels)
                    _PanelView(panel: p, sport: widget.sportType),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < panels.length; i++) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _at ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _at ? T.accent : T.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  if (i != panels.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  T.screenX, T.s20, T.screenX, T.s20),
              child: SizedBox(
                width: double.infinity,
                child: TacticalButton(
                  label: last ? 'intro_start'.tr() : 'intro_next'.tr(),
                  onTap: last
                      ? _finish
                      : () => _pages.nextPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel {
  final IconData icon;
  final String title;
  final String body;
  const _Panel({required this.icon, required this.title, required this.body});
}

class _PanelView extends StatelessWidget {
  final _Panel panel;
  final SportType sport;
  const _PanelView({required this.panel, required this.sport});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: T.s32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
                color: T.accentFill, shape: BoxShape.circle),
            child: Icon(panel.icon, size: 40, color: T.accent),
          ),
          const SizedBox(height: T.s32),
          Text(
            panel.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: T.text,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.25),
          ),
          const SizedBox(height: T.s12),
          Text(
            panel.body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: T.textDim, fontSize: 15.5, height: 1.6),
          ),
          const SizedBox(height: T.s32),
          // The sport, so a coach knows which of the sixteen apps they opened.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SportGlyph(sport: sport, size: 18),
              const SizedBox(width: 6),
              Text('home_board_title'.tr(args: [sport.displayName]),
                  style: const TextStyle(color: T.textOff, fontSize: 12.5)),
            ],
          ),
        ],
      ),
    );
  }
}
