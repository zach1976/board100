import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' show isSingleSportApp;
import '../models/drill.dart';
import '../models/drill_note.dart';
import '../models/sport_type.dart';
import '../models/tactic_meta.dart';
import '../services/drill_library_service.dart';
import '../services/drill_notes_service.dart';
import '../services/purchase_service.dart';
import '../services/recent_boards_service.dart';
import '../state/tactics_state.dart';
import '../ui/primitives.dart';
import '../ui/tokens.dart';
import 'drill_library_page.dart';
import '../widgets/language_picker.dart';
import '../widgets/sport_glyph.dart';
import '../widgets/tactics_canvas.dart';
import 'drill_detail_page.dart';
import 'drill_primer_page.dart';
import 'home_page.dart';
import 'sport_selection_page.dart';
import 'practice_plan_page.dart';

/// Where a coach lands, one page per sport.
///
/// The board used to be the launch screen, which meant everything the app had
/// grown — 624 drills, session plans, saved boards — was reachable only from
/// an overflow menu on top of an empty pitch. A coach opening the app on
/// Monday night is not usually there to draw from nothing; they are there to
/// find something to run on Tuesday, or to carry on with the board they were
/// on. This page puts both of those first and keeps the board one tap away,
/// as the thing it opens rather than a menu item.
class SportHomePage extends StatefulWidget {
  const SportHomePage({super.key});

  @override
  State<SportHomePage> createState() => _SportHomePageState();
}

class _SportHomePageState extends State<SportHomePage> {
  late Future<List<Drill>> _drills;
  List<TacticMeta> _mine = const [];
  List<RecentBoard> _recent = const [];
  Map<String, DrillMark> _marks = const {};

  @override
  void initState() {
    super.initState();
    final state = context.read<TacticsState>();
    _drills = DrillLibraryService.instance.forSport(state.sportType);
    _refreshMine();
  }

  void _refreshMine() {
    final state = context.read<TacticsState>();
    state.listSavedTacticMetas().then((m) {
      // Newest first: "my boards" is a way back to the one being worked on,
      // and a list in whatever order the filesystem returned buries it.
      m.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (mounted) setState(() => _mine = m);
    }).catchError((_) {
      // No saved boards is the normal first-run state; the block just does
      // not appear.
    });
    RecentBoardsService.instance.list(state.sportType).then((r) {
      if (mounted) setState(() => _recent = r);
    }).catchError((_) {});
    DrillNotesService.instance.all(state.sportType).then((m) {
      if (mounted) setState(() => _marks = m);
    }).catchError((_) {});
  }

  /// A drill out of the shipped library, opened again from the recent list.
  Future<void> _openRecent(RecentBoard r) async {
    final state = context.read<TacticsState>();
    if (r.kind == RecentBoardKind.tactic) {
      await state.loadTactics(r.id);
      if (mounted) _openBoard();
      return;
    }
    final all = await _drills;
    final drill = all.where((d) => d.id == r.id).firstOrNull;
    if (drill == null) {
      // The library moved on and this drill is gone. Drop the shortcut rather
      // than leave a row that does nothing.
      await RecentBoardsService.instance
          .forget(state.sportType, r.kind, r.id);
      if (mounted) setState(() => _recent = _recent.where((e) => e != r).toList());
      return;
    }
    if (!mounted) return;
    await _openDrill(drill);
  }

  String get _locale {
    final l = context.locale;
    return l.countryCode == null
        ? l.languageCode
        : '${l.languageCode}-${l.countryCode}';
  }

  Future<void> _openBoard() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TacticsBoardHomePage()),
    );
    if (mounted) {
      _refreshMine();
      setState(() {}); // the hero thumbnail is whatever they left behind
    }
  }

  Future<void> _newBoard() async {
    context.read<TacticsState>().newDocument();
    await _openBoard();
  }

  Future<void> _openLibrary({DrillCategory? category}) async {
    final state = context.read<TacticsState>();
    await DrillLibraryPage.push(
      context,
      state,
      initialCategory: category,
      // Loading a drill from here means "run this", so it lands on the board
      // rather than on a page that has just told the coach it is loaded.
      onLoaded: _openBoard,
      onUpgrade: () => _openBoard(),
    );
  }

  Future<void> _openDrill(Drill drill) async {
    final state = context.read<TacticsState>();
    final unlocked = drill.free ||
        !PurchaseService.instance.isStoreEnabled ||
        PurchaseService.instance.hasPro;
    await DrillDetailPage.push(
      context,
      drill: drill,
      sportType: state.sportType,
      locale: _locale,
      onLoad: unlocked
          ? () {
              state.loadFromJson(Map<String, dynamic>.from(drill.board));
              state.currentTacticName = null;
              state.currentTacticMeta = null;
              RecentBoardsService.instance.record(
                state.sportType,
                RecentBoard(
                  kind: RecentBoardKind.drill,
                  id: drill.id,
                  label: drill.localizedName(_locale),
                  openedAt: DateTime.now(),
                ),
              );
              Navigator.of(context).pop();
              _openBoard();
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TacticsState>();
    return Scaffold(
      backgroundColor: T.bg0,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(T.screenX, T.s8, T.screenX, T.s32),
          children: [
            _header(state.sportType),
            const SizedBox(height: T.s16),
            _BoardCard(
              state: state,
              onOpen: _openBoard,
              onNew: _newBoard,
            ),
            const SizedBox(height: T.s24),
            // Two builders on one cached future, so the coach's own boards can
            // sit between what to run today and the categories — their work
            // belongs above a way of browsing somebody else's.
            FutureBuilder<List<Drill>>(
              future: _drills,
              builder: (context, snap) {
                final all = snap.data ?? const <Drill>[];
                if (all.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHead('home_today'.tr(),
                        action: 'home_all_drills'.tr(args: ['${all.length}']),
                        onAction: _openLibrary),
                    const SizedBox(height: T.s12),
                    _TodayRow(
                      drills: _pickToday(all),
                      locale: _locale,
                      onTap: _openDrill,
                    ),
                    const SizedBox(height: T.s24),
                  ],
                );
              },
            ),
            _sectionHead('home_mine'.tr(),
                action: _mine.length > 4
                    ? 'home_all_boards'.tr(args: ['${_mine.length}'])
                    : null,
                onAction: _openMine),
            const SizedBox(height: T.s12),
            if (_mine.isEmpty)
              // Said plainly rather than left blank: an empty section with no
              // explanation reads as something that failed to load.
              Text('home_mine_empty'.tr(),
                  style: const TextStyle(color: T.textOff, fontSize: 13.5))
            else
              for (final row in _myBoards().take(4))
                _BoardRow(
                  label: row.$1,
                  subtitle: row.$2,
                  isDrill: false,
                  onTap: row.$3,
                ),
            const SizedBox(height: T.s24),
            FutureBuilder<List<Drill>>(
              future: _drills,
              builder: (context, snap) {
                final all = snap.data ?? const <Drill>[];
                if (all.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHead('home_browse'.tr()),
                    const SizedBox(height: T.s12),
                    _CategoryGrid(
                      sport: state.sportType,
                      drills: all,
                      onTap: (c) => _openLibrary(category: c),
                    ),
                    const SizedBox(height: T.s24),
                  ],
                );
              },
            ),
            // The coach's own library: the twenty of six hundred they use.
            // Only once there is one — an empty shelf is not a shelf.
            if (_marks.values.any((m) => m.starred)) ...[
              FutureBuilder<List<Drill>>(
                future: _drills,
                builder: (context, snap) {
                  final all = snap.data ?? const <Drill>[];
                  final starred = all
                      .where((d) => _marks[d.id]?.starred ?? false)
                      .toList();
                  if (starred.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHead('home_starred'.tr(),
                          action: starred.length > 3
                              ? 'home_all_starred'
                                  .tr(args: ['${starred.length}'])
                              : null,
                          onAction: _openStarred),
                      const SizedBox(height: T.s12),
                      _TodayRow(
                        drills: starred.take(6).toList(),
                        locale: _locale,
                        onTap: _openDrill,
                      ),
                      const SizedBox(height: T.s24),
                    ],
                  );
                },
              ),
            ],
            _sectionHead('home_learn'.tr()),
            const SizedBox(height: T.s12),
            _LearnBlock(
              onPrimer: () =>
                  DrillPrimerPage.push(context, state.sportType),
              onLevel: (l) => _openLibraryLevel(l),
            ),
            const SizedBox(height: T.s24),
            _PlanCard(onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => PracticePlanPage(state: state),
              ));
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _openLibraryLevel(DrillLevel level) async {
    final state = context.read<TacticsState>();
    await DrillLibraryPage.push(
      context,
      state,
      initialLevel: level,
      onLoaded: _openBoard,
      onUpgrade: () => _openBoard(),
    );
  }

  /// The coach's own boards, the one they touched last at the top.
  ///
  /// Ordered by whichever is later, saving it or opening it: a board they
  /// edited without saving, or reopened this morning, is the one they are
  /// working on, and sorting by file date alone buries it under whatever
  /// they happened to save most recently.
  List<(String, String, VoidCallback)> _myBoards() {
    DateTime opened(String name) {
      for (final r in _recent) {
        if (r.kind == RecentBoardKind.tactic && r.id == name) {
          return r.openedAt;
        }
      }
      return DateTime(2000);
    }

    final rows = <(DateTime, String, String, VoidCallback)>[];
    for (final m in _mine) {
      final when = m.updatedAt.isAfter(opened(m.name))
          ? m.updatedAt
          : opened(m.name);
      rows.add((when, m.name, _when(when), () async {
        await context.read<TacticsState>().loadTactics(m.name);
        if (mounted) _openBoard();
      }));
    }
    rows.sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final r in rows) (r.$2, r.$3, r.$4)];
  }

  /// "today", "yesterday", "3 days ago" — a date on a board tells a coach
  /// nothing; how long ago tells them whether it is the one they want.
  String _when(DateTime t) {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(t.year, t.month, t.day))
        .inDays;
    if (days <= 0) return 'home_today_word'.tr();
    if (days == 1) return 'home_yesterday'.tr();
    return 'home_days_ago'.tr(args: ['$days']);
  }

  Future<void> _openStarred() async {
    final state = context.read<TacticsState>();
    await DrillLibraryPage.push(
      context,
      state,
      starredOnly: true,
      onLoaded: _openBoard,
      onUpgrade: () => _openBoard(),
    );
    if (mounted) _refreshMine();
  }

  Future<void> _openMine() async {
    final state = context.read<TacticsState>();
    await DrillLibraryPage.push(
      context,
      state,
      openMine: true,
      onLoaded: _openBoard,
      onUpgrade: () => _openBoard(),
    );
    if (mounted) _refreshMine();
  }

  Widget _header(SportType sport) {
    return Row(
      children: [
        SportGlyph(sport: sport, size: 26),
        const SizedBox(width: T.s8),
        Expanded(
          child: Text(
            // The app's own name, not the sport's: this is the home page of
            // 足球战术板 / Soccer Board, which is what the store calls it and
            // what the icon on the phone says.
            'home_board_title'.tr(args: [sport.displayName]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: T.text, fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
        if (!isSingleSportApp)
          // Back to the sport grid. The grid REPLACED itself with this page,
          // so there is nothing to pop to — it has to be replaced back.
          TacticalIconButton(
            icon: Icons.grid_view_rounded,
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                  builder: (_) => const SportSelectionPage()),
            ),
          ),
        const SizedBox(width: T.s4),
        TacticalIconButton(
          icon: Icons.language,
          onTap: () => LanguagePicker.show(context),
        ),
      ],
    );
  }

  Widget _sectionHead(String title, {String? action, VoidCallback? onAction}) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  color: T.text, fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        if (action != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Text(action,
                  style: const TextStyle(
                      color: T.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }

  /// Three drills that make a session on their own — something to warm up
  /// with, something technical, and a game to finish on — rotated by the day
  /// so the page is not the same page every time it is opened.
  ///
  /// Deterministic on the date, not random: a coach who opens the app twice
  /// before training should see the drill they were looking at the first
  /// time, not a reshuffle.
  List<Drill> _pickToday(List<Drill> all) {
    const wanted = [
      DrillCategory.warmup,
      DrillCategory.possession,
      DrillCategory.ssg,
    ];
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day)
        .difference(DateTime(2026, 1, 1))
        .inDays;
    final out = <Drill>[];
    for (var i = 0; i < wanted.length; i++) {
      final pool = all.where((d) => d.category == wanted[i]).toList();
      if (pool.isEmpty) continue;
      out.add(pool[(day + i * 7) % pool.length]);
    }
    // A library without those categories still gets a row rather than a gap.
    for (final d in all) {
      if (out.length >= 3) break;
      if (!out.contains(d)) out.add(d);
    }
    return out;
  }
}

/// The board itself, as the thing it opens.
///
/// Drawn on a throwaway state built from the live board's JSON: sizing the
/// live one down to a thumbnail would rescale every player on it, and coming
/// back would scale them up again through the rounding.
class _BoardCard extends StatelessWidget {
  final TacticsState state;
  final VoidCallback onOpen;
  final VoidCallback onNew;
  const _BoardCard(
      {required this.state, required this.onOpen, required this.onNew});

  @override
  Widget build(BuildContext context) {
    final preview = TacticsState(sportType: state.sportType, preview: true)
      ..loadFromJson(state.toJson());
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Container(
        decoration: const BoxDecoration(
            color: T.surface, borderRadius: T.brLg),
        clipBehavior: Clip.antiAlias,
        // The board is portrait and the card is wide, so the thumbnail keeps
        // its own shape and the buttons take the width beside it. Given the
        // whole card the canvas drew a 109pt pitch in the middle of 361pt of
        // turf, which is a picture of a field rather than of a board.
        padding: const EdgeInsets.all(T.s12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: T.brSm,
              // Drawn at the real board size and scaled as one picture, so
              // the players are the size they are on the board rather than
              // three times it — see kBoardRefWidth.
              child: SizedBox(
                height: 190,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: kBoardRefWidth,
                    height: kBoardRefHeight,
                    child: ChangeNotifierProvider<TacticsState>.value(
                      value: preview,
                      child: const IgnorePointer(
                          child: TacticsCanvas(preview: true)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: T.s16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TacticalButton(
                    label: 'home_open_board'.tr(),
                    icon: Icons.edit_outlined,
                    onTap: onOpen,
                  ),
                  const SizedBox(height: T.s8),
                  TacticalButton(
                    label: 'home_new_board'.tr(),
                    icon: Icons.add,
                    quiet: true,
                    onTap: onNew,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayRow extends StatelessWidget {
  final List<Drill> drills;
  final String locale;
  final void Function(Drill) onTap;
  const _TodayRow(
      {required this.drills, required this.locale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: drills.length,
        separatorBuilder: (_, __) => const SizedBox(width: T.s8),
        itemBuilder: (context, i) {
          final d = drills[i];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(d),
            child: Container(
              width: 210,
              padding: const EdgeInsets.all(T.s12),
              decoration: const BoxDecoration(
                  color: T.surfaceHi, borderRadius: T.brMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.localizedName(locale),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: T.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.25),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      _firstLine(d.localizedNote(locale)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: T.textDim, fontSize: 12.5, height: 1.35),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined,
                          size: 13, color: T.textOff),
                      const SizedBox(width: 4),
                      Text('drills_minutes'.tr(args: ['${d.minutes}']),
                          style: const TextStyle(
                              color: T.textOff, fontSize: 11.5)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// The purpose line — the note's own first section, which is the one that
  /// answers "why would I run this?" on a card this size. Its label is left
  /// off: "Purpose:" on a card headed by the drill's name says nothing.
  static String _firstLine(String note) {
    final parsed = DrillNote.parse(note);
    if (parsed.isEmpty) return note.trim();
    return parsed.sections.first.body;
  }
}

class _CategoryGrid extends StatelessWidget {
  final SportType sport;
  final List<Drill> drills;
  final void Function(DrillCategory) onTap;
  const _CategoryGrid(
      {required this.sport, required this.drills, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final counts = <DrillCategory, int>{};
    for (final d in drills) {
      counts[d.category] = (counts[d.category] ?? 0) + 1;
    }
    return Wrap(
      spacing: T.s8,
      runSpacing: T.s8,
      children: [
        for (final c in DrillCategory.values)
          if (counts.containsKey(c))
            TacticalChip(
              label: c.labelKeyFor(sport.drillVocabulary).tr(),
              // How much is behind the door, before opening it.
              count: counts[c],
              selected: false,
              onTap: () => onTap(c),
            ),
      ],
    );
  }
}

class _BoardRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isDrill;
  final VoidCallback onTap;
  const _BoardRow({
    required this.label,
    required this.subtitle,
    required this.isDrill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: T.s8),
        padding: const EdgeInsets.symmetric(
            horizontal: T.s12, vertical: T.s12),
        decoration:
            const BoxDecoration(color: T.surfaceHi, borderRadius: T.brMd),
        child: Row(
          children: [
            Icon(isDrill ? Icons.menu_book_outlined : Icons.dashboard_outlined,
                size: 18, color: T.textDim),
            const SizedBox(width: T.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: T.text, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(color: T.textOff, fontSize: 11.5)),
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

/// The learning block: how to read a board, then the library by level.
///
/// The library is 600-odd diagrams whose marks a coach has to decode, and
/// three levels that answer the question they actually ask first — "is this
/// for my group?". Both were reachable only by scrolling the whole list.
class _LearnBlock extends StatelessWidget {
  final VoidCallback onPrimer;
  final void Function(DrillLevel) onLevel;
  const _LearnBlock({required this.onPrimer, required this.onLevel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPrimer,
          child: Container(
            padding: const EdgeInsets.all(T.s16),
            decoration:
                const BoxDecoration(color: T.surface, borderRadius: T.brMd),
            child: Row(
              children: [
                const Icon(Icons.school_outlined, size: 20, color: T.accent),
                const SizedBox(width: T.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('learn_primer_title'.tr(),
                          style: const TextStyle(
                              color: T.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('learn_primer_sub'.tr(),
                          style: const TextStyle(
                              color: T.textDim, fontSize: 12.5)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: T.textOff),
              ],
            ),
          ),
        ),
        const SizedBox(height: T.s8),
        Row(
          children: [
            for (final l in DrillLevel.values) ...[
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onLevel(l),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: T.s12),
                    decoration: const BoxDecoration(
                        color: T.surfaceHi, borderRadius: T.brMd),
                    alignment: Alignment.center,
                    child: Text(l.labelKey.tr(),
                        style: const TextStyle(
                            color: T.text,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              if (l != DrillLevel.values.last) const SizedBox(width: T.s8),
            ],
          ],
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PlanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(T.s16),
        decoration:
            const BoxDecoration(color: T.surface, borderRadius: T.brMd),
        child: Row(
          children: [
            const Icon(Icons.event_note_outlined, size: 20, color: T.accent),
            const SizedBox(width: T.s12),
            Expanded(
              child: Text('practice_plan'.tr(),
                  style: const TextStyle(
                      color: T.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.chevron_right, size: 18, color: T.textOff),
          ],
        ),
      ),
    );
  }
}
