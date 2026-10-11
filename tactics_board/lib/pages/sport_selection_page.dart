import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sport_type.dart';
import '../painters/badminton_court_painter.dart';
import '../painters/basketball_court_painter.dart';
import '../painters/tennis_court_painter.dart';
import '../painters/table_tennis_court_painter.dart';
import '../painters/volleyball_court_painter.dart';
import '../painters/pickleball_court_painter.dart';
import '../painters/soccer_court_painter.dart';
import '../painters/field_hockey_court_painter.dart';
import '../painters/rugby_court_painter.dart';
import '../painters/baseball_court_painter.dart';
import '../painters/handball_court_painter.dart';
import '../painters/water_polo_court_painter.dart';
import '../painters/sepak_takraw_court_painter.dart';
import '../painters/beach_tennis_court_painter.dart';
import '../painters/footvolley_court_painter.dart';
import '../services/drill_library_service.dart';
import '../state/tactics_state.dart';
import '../ui/tokens.dart';
import '../widgets/language_picker.dart';
import '../models/court_layout.dart';
import '../widgets/sport_glyph.dart';
import '../widgets/toolbar.dart' as board show courtPainterFor;
import 'intro_page.dart';
import 'sport_home_page.dart';

/// The hub's front door: which sport are we coaching today.
///
/// It was fifteen equal cards, eight of them blue courts, with no memory of
/// which one you picked yesterday. A coach runs one sport, so the sport they
/// ran last is the first thing on the page, with what is waiting in it — how
/// many drills, how many of their own boards. The rest is shelved the way a
/// sports shop shelves it, and every card says how much is behind it.
class SportSelectionPage extends StatefulWidget {
  const SportSelectionPage({super.key});

  /// Most recent first, sport names. Written on every pick.
  static const recentPrefsKey = 'hub_recent_sports';

  @override
  State<SportSelectionPage> createState() => _SportSelectionPageState();
}

class _SportSelectionPageState extends State<SportSelectionPage> {
  SportType? _recent;
  Map<SportType, int> _drills = const {};
  int? _recentBoards;

  /// Null until the preference is read; true on a first run.
  ///
  /// The hub's intro is this page's: it runs once, here, before any sport
  /// is picked, and the sport page it then pushes is told not to run one of
  /// its own. A coach who has just read what the app is should not be told
  /// again the moment they choose a sport.
  bool? _intro;

  /// The grid's scroll, so a rotation can keep the coach where they were.
  ///
  /// The offset is in points, and turning an iPad changes how many points
  /// each row of cards is: the same 600pt that was the third row upright is
  /// the middle of the net sports on its side, so the header and Continue
  /// went off the top. Held as a share of the scroll instead, and put back
  /// after the new layout.
  final _scroll = ScrollController();
  Orientation? _orientation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final o = MediaQuery.orientationOf(context);
    final was = _orientation;
    _orientation = o;
    if (was == null || was == o || !_scroll.hasClients) return;
    final pos = _scroll.position;
    final share =
        pos.maxScrollExtent <= 0 ? 0.0 : pos.pixels / pos.maxScrollExtent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final p = _scroll.position;
      _scroll.jumpTo((share * p.maxScrollExtent)
          .clamp(p.minScrollExtent, p.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    IntroPage.shouldShow().then((show) {
      if (mounted) setState(() => _intro = show);
    });
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(SportSelectionPage.recentPrefsKey) ?? [];
    SportType? recent;
    for (final n in names) {
      for (final s in SportType.values) {
        if (s.name == n) recent = s;
      }
      if (recent != null) break;
    }
    final drills = await DrillLibraryService.instance.bundledCounts();
    if (!mounted) return;
    setState(() {
      _recent = recent;
      _drills = drills;
    });
    // The board count comes off the documents directory, a platform call
    // that is slower than an asset read and, under the test binding, never
    // answers at all. The card does not wait for it: it shows the sport and
    // its drills at once and adds the boards when they are counted.
    if (recent == null) return;
    final boards = await _savedBoardCount(recent);
    if (!mounted) return;
    setState(() => _recentBoards = boards);
  }

  /// The coach's own saved boards for a sport, counted where TacticsState
  /// keeps them, without standing up a TacticsState for a sport that is
  /// not open.
  static Future<int> _savedBoardCount(SportType sport) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/tactics/${sport.name}');
      if (!await dir.exists()) return 0;
      return await dir.list().where((f) => f.path.endsWith('.json')).length;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> _remember(SportType sport) async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(SportSelectionPage.recentPrefsKey) ?? [];
    names
      ..remove(sport.name)
      ..insert(0, sport.name);
    await prefs.setStringList(
        SportSelectionPage.recentPrefsKey, names.take(3).toList());
  }

  void _open(SportType sport) {
    _remember(sport);
    context.read<TacticsState>().setSportType(sport);
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      // gateIntro: false — the hub ran its own intro above; see _intro.
      pageBuilder: (ctx, anim, sec) => const SportHomePage(gateIntro: false),
      transitionsBuilder: (ctx, anim, sec, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_intro == null) {
      return Scaffold(backgroundColor: T.bg0, body: const SizedBox.shrink());
    }
    if (_intro == true) {
      // The count is every sport's library together, the hub's own; the
      // intro is not held back for it.
      final total = _drills.values.fold(0, (a, b) => a + b);
      return IntroPage(
        sportType: null,
        drillCount: _drills.isEmpty ? null : total,
        onDone: () => setState(() => _intro = false),
      );
    }
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide > 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final crossCount = isLandscape ? 4 : isTablet ? 3 : 2;
    // A tablet on its side shelves each group in as many columns as leave
    // no card on its own: five team sports in four columns put Handball
    // alone on a row beside 1000pt of nothing. Four or five, whichever
    // leaves the last row fullest (ties keep four).
    int columnsFor(int n) {
      if (!(isLandscape && isTablet)) return crossCount;
      int gap(int c) => (c - n % c) % c;
      return gap(5) < gap(4) ? 5 : 4;
    }
    final topPad = MediaQuery.of(context).padding.top;
    // 12pt was a phone-on-its-side margin; on an iPad it put the cards
    // against the glass.
    final sideX = isLandscape
        ? (isTablet ? 24.0 : 12.0)
        : isTablet
            ? 24.0
            : T.screenX;
    final order = sportDisplayOrderFor(context.locale);
    final recent = _recent;

    return Scaffold(
      backgroundColor: T.bg0,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(sideX, topPad + T.s16, sideX, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('app_title'.tr(), style: T.display),
                        const SizedBox(height: T.s4),
                        Text('choose_sport'.tr(), style: T.secondary),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: T.surfaceHi, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.language_rounded,
                          color: T.textDim, size: 18),
                      onPressed: () => LanguagePicker.show(context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (recent != null)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(sideX, T.s24, sideX, 0),
              sliver: SliverToBoxAdapter(
                child: _ContinueCard(
                  sport: recent,
                  drills: _drills[recent] ?? 0,
                  boards: _recentBoards,
                  onTap: () => _open(recent),
                ),
              ),
            ),
          for (final group in SportGroup.values) ...[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(sideX, T.sectionGap, sideX, T.s12),
              sliver: SliverToBoxAdapter(
                child: Text(_groupKey(group).tr().toUpperCase(),
                    style: T.label),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: sideX),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnsFor(
                      order.where((s) => s.group == group).length),
                  crossAxisSpacing: T.s12,
                  mainAxisSpacing: T.s12,
                  childAspectRatio: isLandscape ? 1.3 : 1.05,
                ),
                delegate: SliverChildListDelegate([
                  for (final sport in order)
                    if (sport.group == group)
                      _SportCard(
                        sport: sport,
                        drills: _drills[sport],
                        onTap: () => _open(sport),
                      ),
                ]),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: T.s40)),
        ],
      ),
    );
  }

  static String _groupKey(SportGroup g) => switch (g) {
        SportGroup.pitch => 'hub_group_pitch',
        SportGroup.net => 'hub_group_net',
        SportGroup.other => 'hub_group_other',
      };
}

CustomPainter courtPainterFor(SportType sport) {
  switch (sport) {
    case SportType.badminton:    return const BadmintonCourtPainter();
    case SportType.tableTennis:  return const TableTennisCourtPainter();
    case SportType.tennis:       return const TennisCourtPainter();
    case SportType.basketball:   return const BasketballCourtPainter();
    case SportType.volleyball:   return const VolleyballCourtPainter();
    case SportType.pickleball:   return const PickleballCourtPainter();
    case SportType.soccer:       return SoccerCourtPainter();
    case SportType.fieldHockey:  return const FieldHockeyCourtPainter();
    case SportType.rugby:        return const RugbyCourtPainter();
    case SportType.baseball:     return const BaseballCourtPainter();
    case SportType.handball:     return const HandballCourtPainter();
    case SportType.waterPolo:    return const WaterPoloCourtPainter();
    case SportType.sepakTakraw:  return const SepakTakrawCourtPainter();
    case SportType.beachTennis:  return const BeachTennisCourtPainter();
    case SportType.footvolley:   return const FootvolleyCourtPainter();
  }
}

/// Accent colour for each sport card.
Color sportAccentFor(SportType sport) => sport.accent;

/// The court, upright, in a rounded frame — the one picture that tells the
/// sports apart at a glance.
class _Court extends StatelessWidget {
  final SportType sport;
  const _Court({required this.sport});

  @override
  Widget build(BuildContext context) {
    // In the colour the board itself is drawn in. Each painter's own default
    // is not always its sport's first surface: the pickleball court was blue
    // here and on the Continue card, and green the moment it was opened.
    final color =
        context.select<TacticsState, Color>((s) => s.courtColor(sport));
    final painter = sport.courtSurfaces.isEmpty || sport == SportType.soccer
        ? courtPainterFor(sport)
        : board.courtPainterFor(sport, CourtLayout.full, color);
    final paint = CustomPaint(painter: painter, child: const SizedBox.expand());
    return ClipRRect(
      borderRadius: T.brSm,
      child: sport.isLandscapeCourt
          ? paint
          : RotatedBox(quarterTurns: 1, child: paint),
    );
  }
}

/// Where the coach left off: their sport, and what is waiting in it.
class _ContinueCard extends StatelessWidget {
  final SportType sport;
  final int drills;
  /// Null until counted; the line then names the drills alone.
  final int? boards;
  final VoidCallback onTap;
  const _ContinueCard(
      {required this.sport,
      required this.drills,
      required this.boards,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = sportAccentFor(sport);
    return Semantics(
      button: true,
      label: '${'hub_continue'.tr()} ${sport.displayName}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: T.brMd,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: T.brMd,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent.withValues(alpha: 0.28), T.surfaceHi],
              ),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            padding: const EdgeInsets.all(T.s12),
            child: Row(
              children: [
                SizedBox(width: 96, height: 72, child: _Court(sport: sport)),
                const SizedBox(width: T.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('hub_continue'.tr().toUpperCase(),
                          style: T.label.copyWith(color: T.accent)),
                      const SizedBox(height: T.s4),
                      Row(children: [
                        SportGlyph(sport: sport, size: 20),
                        const SizedBox(width: T.s8),
                        Expanded(
                          child: Text(sport.displayName,
                              style: T.section,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      const SizedBox(height: T.s4),
                      Text(
                        boards == null
                            ? _drillsN(drills)
                            : '${_drillsN(drills)} · ${_boardsN(boards!)}',
                        style: T.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: T.s8),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: T.textOff, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SportCard extends StatelessWidget {
  final SportType sport;
  /// Null until the index has loaded; the card draws without the line
  /// rather than flashing a zero.
  final int? drills;
  final VoidCallback onTap;
  const _SportCard(
      {required this.sport, required this.drills, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = sportAccentFor(sport);
    return Semantics(
      button: true,
      label: sport.displayName,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: T.brMd,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: T.brMd,
              color: T.surfaceHi,
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            padding: const EdgeInsets.all(T.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Court(sport: sport)),
                const SizedBox(height: T.s8),
                Row(children: [
                  SportGlyph(sport: sport, size: 18),
                  const SizedBox(width: T.s8),
                  // Two lines before it gives up: "Hockey sobre césped" on a
                  // 375pt Slide Over card lost the one word that says which
                  // hockey.
                  Expanded(
                    child: Text(sport.displayName,
                        style: T.body.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                if (drills != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 26, top: 2),
                    child: Text(_drillsN(drills!),
                        style: T.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "1 board", not "1 boards": the counts on the picker's cards, singular
/// when there is one.
String _drillsN(int n) =>
    n == 1 ? 'hub_drills_one'.tr() : 'hub_drills_n'.tr(args: ['$n']);
String _boardsN(int n) =>
    n == 1 ? 'hub_boards_one'.tr() : 'hub_boards_n'.tr(args: ['$n']);
