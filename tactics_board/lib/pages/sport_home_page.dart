import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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
import '../ui/adaptive.dart';
import '../ui/tokens.dart';
import 'drill_library_page.dart';
import 'recent_page.dart';
import '../widgets/drill_thumbnail.dart';
import '../widgets/language_picker.dart';
import '../widgets/sport_glyph.dart';
import '../widgets/tactics_canvas.dart';
import 'drill_detail_page.dart';
import 'drill_primer_page.dart';
import 'home_page.dart';
import 'intro_page.dart';
import 'match_day_page.dart';
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
/// Whether there is a board to carry on with.
///
/// A first run has none: nothing named, nothing drawn, one empty page. Both
/// the home card and the tab bar ask this, because with nothing yet "open
/// the board" and "new board" would open the very same empty pitch — one of
/// them under a label promising the coach their own work.
///
/// A name counts on its own. A board the coach has just made and called
/// "Board 1" is theirs even before they have drawn on it, and answering "no"
/// there left them looking at it in "my boards" with no way back to it but
/// to make another one.
bool hasWorkingBoard(TacticsState state) =>
    state.currentTacticName != null ||
    state.players.isNotEmpty ||
    state.strokes.isNotEmpty ||
    state.pageCount > 1;

/// Ask for a name and make an empty board under it. True if one was made.
///
/// Named before it is drawn on. A board with no name is a board that cannot
/// be found again: it does not appear under "my boards", and the next blank
/// one takes its place on the home card. Cancelling makes nothing, which is
/// why the question comes first — there is no half-made board to lose.
///
/// [taken] is the names already used, when the caller is holding them; the
/// home page is, and making a coach wait on a directory read before the
/// keyboard appears is a pause with nothing behind it.
Future<bool> createNamedBoard(BuildContext context, {Set<String>? taken}) async {
  final state = context.read<TacticsState>();
  final names =
      taken ?? (await state.listSavedTacticMetas()).map((m) => m.name).toSet();
  if (!context.mounted) return false;
  // A name is offered, not demanded. The board has to be named before it
  // exists, which is right — but a coach who wants a pitch to draw on should
  // not have to invent a word first, and an empty field with a dead Apply
  // button asks them to. Numbered from what is already saved and past
  // anything that would clash, so Apply works on the first tap; the field
  // opens with it selected, so typing replaces it.
  final base = 'board_name_default_prefix'.tr();
  var n = names.length + 1;
  while (names.contains('$base $n')) {
    n++;
  }
  final name = await promptForName(
    context,
    title: 'board_name_title'.tr(),
    initial: '$base $n',
    taken: names,
    takenMessage: 'board_name_exists'.tr(),
  );
  if (name == null) return false;
  state.newDocument();
  try {
    await state.saveTactics(name);
  } catch (_) {
    // A board that cannot be written is still a board worth drawing on;
    // the toolbar's own Save will say so when they try again.
  }
  return true;
}

class SportHomePage extends StatefulWidget {
  /// Whether this page decides for itself that the intro still has to run.
  ///
  /// True when the sport picker pushes it: there is nothing above it then,
  /// so returning the intro from its build replaces the whole screen, which
  /// is what the intro wants. False inside [MainShell], which holds the same
  /// gate one level up — asked in both places, the two answers can differ for
  /// one launch (the first call is the one racing plugin start-up, and
  /// [IntroPage.shouldShow] answers "no" when prefs fail rather than showing
  /// the intro forever), and the shell's tab bar is then left sitting under
  /// an onboarding page that has nothing to switch between.
  final bool gateIntro;

  /// Bumped by [MainShell] whenever this page becomes the visible tab.
  ///
  /// The lists here are read once, in initState — and inside an IndexedStack
  /// this page is never built again, so a drill put on the board from the
  /// Drills tab, or a board saved while away, was invisible here until the
  /// app was restarted. A number that changes is the smallest thing that can
  /// say "look again"; the sport picker pushes this page on its own, where
  /// it stays 0 and nothing asks.
  final int revision;

  const SportHomePage(
      {super.key, this.gateIntro = true, this.revision = 0});

  @override
  State<SportHomePage> createState() => _SportHomePageState();
}

class _SportHomePageState extends State<SportHomePage> {
  late Future<List<Drill>> _drills;
  /// Null until the answer is known: showing the home page for one frame and
  /// then covering it with an intro is worse than a blank frame.
  bool? _intro;
  int? _drillCount;
  List<TacticMeta> _mine = const [];
  List<RecentBoard> _recent = const [];
  Map<String, DrillMark> _marks = const {};

  /// The library keyed by id, for the recent row's thumbnails. A recent
  /// entry holds a name, not a board — the picture has to be looked up.
  Map<String, Drill> _byId = const {};
  /// Whether this app ships the home screen's photography.
  ///
  /// The hero behind the title and the nine drill-category covers are the
  /// shell's own — one sport's pitch is not another's — so the hub and any
  /// shell whose art has not been shot yet fall back to flat panels. One
  /// probe, not ten: the set is generated, converted and declared together,
  /// so the hero answers for all of it.
  bool _hasArt = false;

  static const String _heroAsset = 'assets/hero.webp';
  static String _coverAsset(DrillCategory c) => 'assets/cover/${c.name}.webp';

  @override
  void initState() {
    super.initState();
    _probeArt();
    final state = context.read<TacticsState>();
    _drills = DrillLibraryService.instance.forSport(state.sportType);
    _refreshMine();
    if (widget.gateIntro) {
      IntroPage.shouldShow().then((show) {
        if (mounted) setState(() => _intro = show);
      });
    } else {
      _intro = false; // MainShell has already run it
    }
    _drills.then((all) {
      if (mounted) {
        setState(() {
          _drillCount = all.length;
          _byId = {for (final d in all) d.id: d};
        });
      }
    }).catchError((Object _) {
      // No library is not a reason to fail the page: the count stays null
      // and the intro keeps its countless wording. The old handler returned
      // an empty List<Drill> from a Future<void>, which is a type error the
      // moment it actually fires.
    });
  }

  @override
  void didUpdateWidget(SportHomePage old) {
    super.didUpdateWidget(old);
    if (widget.revision != old.revision) _refreshMine();
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

  /// Everything opened lately, and back to whichever row was tapped.
  Future<void> _openAllRecent() async {
    final picked = await RecentPage.push(
      context,
      items: _recent,
      sport: context.read<TacticsState>().sportType,
      byId: _byId,
    );
    if (picked != null && mounted) await _openRecent(picked);
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
    final state = context.read<TacticsState>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TacticsBoardHomePage()),
    );
    // Walking back to the home page is not a decision to throw the edit
    // away — see TacticsState.autosave. Awaited, so "my boards" is re-read
    // after the file is on disk and not before it.
    await state.autosave();
    if (mounted) {
      _refreshMine();
      setState(() {}); // the hero thumbnail is whatever they left behind
    }
  }

  Future<void> _newBoard() async {
    final made = await createNamedBoard(context,
        taken: _mine.map((m) => m.name).toSet());
    if (!made || !mounted) return;
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
              // See drill_library_page: the board prints its own steps.
              state.openedDrill(
                  DrillNote.parse(drill.localizedNote(_locale)).beats,
                  beatsFor: (l) =>
                      DrillNote.parse(drill.localizedNote(l)).beats,
                  name: drill.displayName(_locale),
                  nameFor: drill.displayName,
                  id: drill.id,
                  frame: drill.frame);
              RecentBoardsService.instance.record(
                state.sportType,
                RecentBoard(
                  kind: RecentBoardKind.drill,
                  id: drill.id,
                  label: drill.displayName(_locale),
                  openedAt: DateTime.now(),
                ),
              );
              Navigator.of(context).pop();
              _openBoard();
            }
          : null,
    );
  }

  /// A Mac window or a phone on its side is not a tall narrow column.
  ///
  /// The page was laid out for a 402pt phone: on a 1700pt window the three
  /// buttons on the board card stretched right across it, the two rows of
  /// cards sat in the left third with a field of empty dark beside them,
  /// and "what to run today" still offered three drills. Wide means: cap
  /// the column so a line of text is readable, and spend what is left on
  /// more cards rather than on wider ones.
  static const double _kMaxColumn = 1040;
  bool _isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 700;

  /// The page's one content column, centred once the window is wider than
  /// [_kMaxColumn]. The photograph behind the title still bleeds.
  Widget _column(Widget child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxColumn),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TacticsState>();
    // The language is switched from this page's menu: the drill note on the
    // board follows it, as the Recent row's name does.
    final tag = _locale;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) state.localizeDrill(tag);
    });
    if (_intro == null) {
      return Scaffold(backgroundColor: T.bg0, body: const SizedBox.shrink());
    }
    if (_intro == true) {
      // The count is this app's own library — right in the hub and in each of
      // the fifteen shells — but the intro is not held back for it.
      return IntroPage(
        sportType: state.sportType,
        drillCount: _drillCount,
        onDone: () => setState(() => _intro = false),
      );
    }
    return Scaffold(
      backgroundColor: T.bg0,
      // top: false — the hero runs up under the status bar. Everything below
      // it carries the screen margin itself.
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: T.s32),
          children: [
            _hero(state.sportType),
            // The header already ends in T.bg0 across its fade band; this is
            // the gap before the first card, not a seam to hide.
            const SizedBox(height: T.s8),
            // One margin for the whole column below the photograph. The hero
            // is the only child that bleeds, so the padding belongs here
            // rather than on the ListView.
            _column(Padding(
              padding: const EdgeInsets.symmetric(horizontal: T.screenX),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            _BoardCard(
              state: state,
              onOpen: _openBoard,
              onNew: _newBoard,
              onPlan: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => PracticePlanPage(state: state),
                ));
              },
              onMatchDay: state.sportType.hasMatchDay
                  ? () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) =>
                            MatchDayPage(sport: state.sportType),
                      ));
                    }
                  : null,
            ),
            const SizedBox(height: T.s24),
            // Back to what was open. Every route onto the board already
            // records what it put there — the library, the home row, loading
            // a saved board — and until now nothing read the drills back, so
            // the shortcut existed with nowhere to appear.
            if (_recentDrills.isNotEmpty) ...[
              _sectionHead('home_recent'.tr(),
                  // Only when there is more than the row already shows.
                  action: _recent.length > _recentDrills.length
                      ? 'home_recent_all'.tr(args: ['${_recent.length}'])
                      : null,
                  onAction: _openAllRecent),
              const SizedBox(height: T.s12),
              _RecentRow(
                items: [
                  for (final r in _recentDrills) (r, _byId[r.id]),
                ],
                sport: context.read<TacticsState>().sportType,
                onTap: _openRecent,
              ),
              const SizedBox(height: T.s24),
            ],
            // The coach's own boards come before the shelf. What they made
            // themselves is what they came back for; a suggestion of what to
            // run today is worth offering under it, not over it.
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
                    _sectionHead('home_today'.tr(),
                        action: 'home_all_drills'.tr(args: ['${all.length}']),
                        onAction: _openLibrary),
                    const SizedBox(height: T.s12),
                    _TodayRow(
                      drills: _pickToday(all, _isWide(context) ? 6 : 3),
                      locale: _locale,
                      onTap: _openDrill,
                      cover: _hasArt ? _coverAsset : null,
                    ),
                    const SizedBox(height: T.s24),
                  ],
                );
              },
            ),
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
                        cover: _hasArt ? _coverAsset : null,
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
                ],
              ),
            )),
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

  /// The drills the coach opened lately, newest first.
  ///
  /// Drills only. Their own saved boards have a section of their own below,
  /// and a drill is the half of "recent" that has nowhere else to be found:
  /// it is never saved — it is a starting shape to edit — so without this
  /// the only way back to the one you ran on Tuesday is to remember its
  /// name and search for it.
  List<RecentBoard> get _recentDrills => _recent
      .where((r) => r.kind == RecentBoardKind.drill)
      .take(6)
      .toList();

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
  /// See [relativeDay] — the recent list shows the same dates.
  String _when(DateTime t) => relativeDay(t);

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

  /// Ask the bundle once. Image.asset's errorBuilder would answer the same
  /// question, but it answers it by throwing on every build of every app
  /// that has no artwork — fifteen of the sixteen, today.
  Future<void> _probeArt() async {
    try {
      await rootBundle.load(_heroAsset);
      if (mounted) setState(() => _hasArt = true);
    } catch (_) {
      // No artwork in this shell; the flat header is not a failure state.
    }
  }

  /// The photograph behind the title, and the page's own name laid over it.
  ///
  /// Full-bleed, up under the status bar: the picture is the first thing a
  /// coach sees, and a 16pt margin around it turns a photograph into a
  /// thumbnail. The art is shot for this — its left half is empty and dark
  /// so the title can sit there, and its top corners are clear for the two
  /// buttons — but the scrim is drawn anyway, because a gradient that is
  /// only needed when the picture is wrong costs nothing when it is right.
  Widget _hero(SportType sport) {
    // The inset itself (viewPadding), not only what is left of it after
    // whatever stands between the window and this page has taken its
    // share: a route or a scroll view that consumes the top padding left
    // the title under the Dynamic Island (reported 2026-10-16).
    final mq = MediaQuery.of(context);
    final top = math.max(mq.padding.top, mq.viewPadding.top);
    // In the same centred column as the page below it, so on a window wider
    // than [_kMaxColumn] the title starts where the cards start rather than
    // 150pt to their left. Only the photograph bleeds.
    final content = _column(Padding(
      // The bottom is not a margin: it is the band the photograph fades out
      // over, so the page begins under a gradient rather than at an edge.
      // Nothing is drawn in it — the scrim below reaches T.bg0 across it.
      // top is the status bar and the island above it; the row has to
      // start BELOW that, not four points into it. Merging the title
      // into the button row moved it up by a whole row, which put it
      // straight under the Dynamic Island on a Pro.
      padding: EdgeInsets.fromLTRB(T.screenX, top + T.s12, T.screenX, T.s28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The title and the buttons share one row, so the name starts at
          // the same height the menu sits at. They used to be stacked — a
          // row of buttons, then the title under it — which read as the
          // title having been pushed down for no reason.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SportGlyph(sport: sport, size: 26),
              const SizedBox(width: T.s8),
              // Shrunk to fit rather than cut: "Table Tennis Bo…" and
              // "Sepak Takraw B…" lost the one word that says what the app is.
              Expanded(
                child: FittedBox(
                 fit: BoxFit.scaleDown,
                 alignment: Alignment.centerLeft,
                 child: Text(
                  // The app's own name, not the sport's: this is the home
                  // page of 足球战术板 / Soccer Board, which is what the
                  // store calls it and what the icon on the phone says.
                  'home_board_title'.tr(args: [sport.displayName]),
                  maxLines: 1,
                  style: TextStyle(
                      color: _hasArt ? Colors.white : T.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      shadows: _hasArt ? const [
                        Shadow(color: Colors.black87, blurRadius: 8),
                      ] : null),
                 ),
                ),
              ),
              const SizedBox(width: T.s8),
              if (!isSingleSportApp)
                TacticalIconButton(
                  icon: Icons.grid_view_rounded,
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                        builder: (_) => const SportSelectionPage()),
                  ),
                ),
              if (!isSingleSportApp) const SizedBox(width: T.s4),
              _HomeMenu(
                onLanguage: () => LanguagePicker.show(context),
                onContact: () =>
                    pushFormSheet<void>(context, const ContactPage()),
                onLogin: () => pushFormSheet<void>(context, const LoginPage()),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'home_tagline'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: _hasArt ? Colors.white70 : T.textDim,
                fontSize: 13,
                shadows: _hasArt ? const [
                  Shadow(color: Colors.black87, blurRadius: 6),
                ] : null),
          ),
        ],
      ),
    ));

    if (!_hasArt) return content;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(_heroAsset,
              fit: BoxFit.cover, alignment: Alignment.centerRight),
        ),
        // Down into the page, not stopping at an edge: a photograph that
        // ends on a hard line reads as a banner pasted on top of the app.
        //
        // Four stops, not three. With one ramp from 13% black to opaque
        // T.bg0, the alpha climbs evenly the whole way and the picture is
        // still half there twenty points from the bottom — so it vanished in
        // the last stretch and the eye read a line anyway. The third stop
        // puts the photograph 70% under the page colour by the time the
        // tagline ends, and leaves the rest of the way to finish the fade:
        // it goes out over about a third of the header instead of over its
        // last centimetre.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0x73000000),
                  const Color(0x1F000000),
                  T.bg0.withAlpha(0xB3),
                  T.bg0,
                ],
                stops: const [0, .38, .80, 1],
              ),
            ),
          ),
        ),
        // And a second one from the left, where the title and the tagline
        // are. The art is briefed to keep that side in shade, but a sunny
        // morning is the point of the picture and the sun does not always
        // land where the brief asked — a shot that is right in every other
        // way should not be unusable because the grass under the title came
        // out bright. Free on a photograph that is already dark there.
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x8C000000), Color(0x40000000), Color(0x00000000)],
                stops: [0, .45, .78],
              ),
            ),
          ),
        ),
        content,
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
                  style: TextStyle(
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
  List<Drill> _pickToday(List<Drill> all, int count) {
    // A session in order: warm up, work on the ball, finish on a game. A
    // wide screen asks for more, so the three repeat — a second warm-up, a
    // second piece of technical work — rather than trailing off into
    // whatever the library happens to list next.
    final wanted = [
      for (var i = 0; i < count; i++)
        [
          DrillCategory.warmup,
          DrillCategory.possession,
          DrillCategory.ssg,
        ][i % 3],
    ];
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day)
        .difference(DateTime(2026, 1, 1))
        .inDays;
    final out = <Drill>[];
    for (var i = 0; i < wanted.length; i++) {
      final pool = all.where((d) => d.category == wanted[i]).toList();
      if (pool.isEmpty) continue;
      // i * 7 walks each slot a different way through its own pool; the
      // second pass over the same three categories has to start somewhere
      // else again or a wide screen shows the same drill twice.
      final pick = pool[(day + i * 7) % pool.length];
      if (!out.contains(pick)) out.add(pick);
    }
    // A library without those categories still gets a row rather than a gap.
    for (final d in all) {
      if (out.length >= count) break;
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
class _BoardCard extends StatefulWidget {
  final TacticsState state;
  final VoidCallback onOpen;
  final VoidCallback onNew;
  final VoidCallback onPlan;

  /// The match-day sheet, for the sports that have one (SportType.hasMatchDay).
  final VoidCallback? onMatchDay;
  const _BoardCard(
      {required this.state,
      required this.onOpen,
      required this.onNew,
      required this.onPlan,
      this.onMatchDay});

  @override
  State<_BoardCard> createState() => _BoardCardState();
}

class _BoardCardState extends State<_BoardCard> {
  /// One throwaway board, kept for the life of the card.
  ///
  /// It used to be built afresh on every rebuild and handed to the canvas
  /// under a ValueKey made of the board's JSON — which meant serialising the
  /// whole board to a string and tearing down the canvas on every frame the
  /// home page rebuilt, and it rebuilds on every notification, including
  /// each frame of a drag happening on the board route above it.
  ///
  /// Holding one object instead is what the live board already does: the
  /// canvas reads its state once and listens to it, so refreshing this one
  /// in place updates the picture with no key and no rebuild.
  late final TacticsState _preview =
      TacticsState(sportType: widget.state.sportType, preview: true);
  int _sig = 0;

  /// Cheap stand-in for "is this a different board than the one drawn".
  ///
  /// Not the JSON: this runs on every rebuild, and it has to cost nothing
  /// when the answer is no — which it is, nearly always.
  static int _signature(TacticsState s) => Object.hash(
        s.sportType,
        s.pageCount,
        Object.hashAll([
          for (final p in s.players)
            Object.hash(p.id, p.position, p.label, p.moves.length,
                p.moves.isEmpty ? 0 : p.moves.last, p.color.toARGB32()),
        ]),
        Object.hashAll([
          for (final st in s.strokes)
            Object.hash(st.id, st.points.length,
                st.points.isEmpty ? 0 : st.points.last),
        ]),
      );

  @override
  void initState() {
    super.initState();
    // Eagerly, so the first frame already shows the board rather than an
    // empty pitch that fills in a frame later.
    _preview.loadFromJson(widget.state.toJson());
    _sig = _signature(widget.state);
  }

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final onOpen = widget.onOpen;
    final onNew = widget.onNew;
    final onPlan = widget.onPlan;
    final sig = _signature(state);
    if (sig != _sig) {
      _sig = sig;
      // After this frame: loadFromJson notifies, and notifying a listener
      // that is being built is an error.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _preview.loadFromJson(state.toJson());
      });
    }
    // With nothing drawn yet the card does not offer to open a board; making
    // one becomes its main action. See hasWorkingBoard.
    final hasBoard = hasWorkingBoard(state);
    final sideways =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final previewBoard = SizedBox(
      width: kBoardRefWidth,
      height: kBoardRefHeight,
      child: ChangeNotifierProvider<TacticsState>.value(
        value: _preview,
        child: IgnorePointer(
            child: TacticsCanvas(preview: true, boardTurns: sideways ? 1 : 0)),
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: hasBoard ? onOpen : onNew,
      child: Container(
        decoration: BoxDecoration(
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
              //
              // Turned sideways — a tablet, a Mac window, a phone on its
              // side — the board page draws the board landscape, so a
              // portrait thumbnail here was a picture of a board the coach
              // would not recognise when he opened it. The preview takes the
              // same quarter turn, and the card gives it width instead of
              // height.
              child: SizedBox(
                height: sideways ? null : 190,
                width: sideways ? 260 : null,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: sideways
                      ? RotatedBox(quarterTurns: 1, child: previewBoard)
                      : previewBoard,
                ),
              ),
            ),
            const SizedBox(width: T.s16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasBoard) ...[
                    // Which board it is. "Open the board" is the action; the
                    // name is the answer to "which one am I going back to",
                    // and a coach with four boards saved cannot tell that
                    // from a button. Absent for a drill put on the board,
                    // which has no name by design.
                    if (state.currentTacticName case final n?
                        when n.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 6),
                        child: Text(
                          n,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: T.textDim,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    TacticalButton(
                      label: 'home_open_board'.tr(),
                      icon: Icons.edit_outlined,
                      onTap: onOpen,
                    ),
                    const SizedBox(height: T.s8),
                  ],
                  TacticalButton(
                    label: 'home_new_board'.tr(),
                    icon: Icons.add,
                    quiet: hasBoard,
                    onTap: onNew,
                  ),
                  const SizedBox(height: T.s8),
                  // Beside the board rather than in a row of its own under
                  // it: the three things a coach opens the app to do are one
                  // group — carry on with a board, start a blank one, or line
                  // up a Tuesday — and a separate card made the third read as
                  // a different kind of thing.
                  TacticalButton(
                    label: 'practice_plan'.tr(),
                    icon: Icons.event_note_outlined,
                    quiet: true,
                    onTap: onPlan,
                  ),
                  if (widget.onMatchDay != null) ...[
                    const SizedBox(height: T.s8),
                    TacticalButton(
                      label: 'matchday_title'.tr(),
                      icon: Icons.swap_horiz_rounded,
                      quiet: true,
                      onTap: widget.onMatchDay,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What was open last, with a picture of it.
///
/// A row of names told a coach nothing they could not have got from the
/// library's search box; the board is what they recognise. The picture is
/// [DrillThumbnail] — the chalk diagram the library list uses, not a live
/// canvas, because six canvases on the home page is six boards' worth of
/// sprites and gesture recognisers for six pictures nobody touches.
///
/// A drill the library no longer has keeps its name and loses its picture,
/// rather than disappearing: tapping it is what clears the shortcut, and it
/// says so by being there. See SportHomePage._openRecent.
class _RecentRow extends StatelessWidget {
  final List<(RecentBoard, Drill?)> items;
  final SportType sport;
  final void Function(RecentBoard) onTap;
  const _RecentRow(
      {required this.items, required this.sport, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const thumb = 64.0;
    final h = thumb + T.s12 * 2;
    return LayoutBuilder(builder: (context, c) {
      // Wide enough for two: lay them across the width. A scroller in a
      // 1700pt window put three cards in the left eighth of it.
      if (c.maxWidth >= 560) {
        const gap = T.s8;
        final columns = (c.maxWidth / 260).floor().clamp(2, 5);
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(width: w, height: h, child: _card(context, i, thumb)),
          ],
        );
      }
      return SizedBox(
        height: h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: T.s8),
          itemBuilder: (context, i) =>
              SizedBox(width: 196, child: _card(context, i, thumb)),
        ),
      );
    });
  }

  Widget _card(BuildContext context, int i, double thumb) {
    {
      {
          final (recent, drill) = items[i];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(recent),
            child: Container(
              padding: const EdgeInsets.all(T.s12),
              decoration: BoxDecoration(
                  color: T.surfaceHi, borderRadius: T.brSm),
              child: Row(
                children: [
                  if (drill != null)
                    DrillThumbnail(
                        drill: drill, sport: sport, height: thumb)
                  else
                    SizedBox(
                      width: thumb * 0.62,
                      height: thumb,
                      child: const Icon(Icons.history_rounded,
                          color: T.textOff, size: 20),
                    ),
                  const SizedBox(width: T.s12),
                  Expanded(
                    child: Text(
                      // The drill's name in the language the app is in
                      // now, not the one it was opened in: the stored label
                      // is only for a drill the library no longer has.
                      drill != null
                          ? drill.displayName(_localeTag(context))
                          : recent.label,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: T.text,
                          fontSize: 13.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
      }
    }
  }
}

class _TodayRow extends StatelessWidget {
  final List<Drill> drills;
  final String locale;
  final void Function(Drill) onTap;
  /// A cover photograph per drill category, when the shell ships them. The
  /// card is the same card either way — the picture sits behind the words
  /// instead of beside them, which is why the covers are shot with their
  /// bottom third dark and empty.
  final String? Function(DrillCategory)? cover;
  const _TodayRow(
      {required this.drills,
      required this.locale,
      required this.onTap,
      this.cover});

  @override
  Widget build(BuildContext context) {
    final art = cover != null;
    // Taller without art: the badge above the name needs the room the
    // photograph used to fill.
    final h = 150.0;
    // Wide enough for two cards and a gap: lay them out across the width
    // instead of running them off the side of a window with room to spare.
    // A phone keeps the scroller — six cards wrapped onto a phone would be
    // three screenfuls of drills before the coach's own boards.
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 560) {
        const gap = T.s8;
        final columns = (c.maxWidth / 300).floor().clamp(2, 4);
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < drills.length; i++)
              SizedBox(width: w, height: h, child: _card(context, i, art)),
          ],
        );
      }
      return SizedBox(
        height: h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: drills.length,
          separatorBuilder: (_, _) => const SizedBox(width: T.s8),
          itemBuilder: (context, i) => SizedBox(
              width: art ? 232 : 210, child: _card(context, i, art)),
        ),
      );
    });
  }

  Widget _card(BuildContext context, int i, bool art) {
    {
      {
          final d = drills[i];
          final path = art ? cover!(d.category) : null;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(d),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                  color: T.surfaceHi, borderRadius: T.brMd),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (path != null) ...[
                    Image.asset(path, fit: BoxFit.cover),
                    // The bottom of the card was never the problem — the
                    // covers were shot dark there and the scrim only made it
                    // certain. The top is: the drill's name sits at y=12, and
                    // once the covers were reshot into sunlight it landed on
                    // bright sky. Measured over the nine soccer covers, white
                    // on the brightest of them came out at 3.0:1. 0x59 buys
                    // the 4.5:1 back and still leaves the picture sunlit;
                    // going further starts turning the photograph off.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x59000000), Color(0x8C000000), Color(0xE6000000)],
                          stops: [0, .45, 1],
                        ),
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.all(T.s12),
                    child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Without a photograph the card was four lines of grey
                  // text and nothing to catch the eye. The category's own
                  // glyph and tint are already defined for the grid below —
                  // the same ones, so a warm-up reads as a warm-up in both
                  // places. A shell that ships covers keeps the photograph
                  // and needs no badge on top of it.
                  if (path == null) ...[
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _CategoryTile._tint(d.category)
                            .withValues(alpha: 0.14),
                        borderRadius: T.brSm,
                      ),
                      child: Icon(_CategoryTile._icon(d.category),
                          size: 17, color: _CategoryTile._tint(d.category)),
                    ),
                    const SizedBox(height: T.s8),
                  ],
                  Text(
                    d.displayName(locale),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: path != null ? Colors.white : T.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        shadows: path != null
                            ? const [Shadow(color: Colors.black87, blurRadius: 6)]
                            : null),
                  ),
                  const SizedBox(height: 6),
                  // As many whole lines as the room left under the title.
                  // A fixed count did not know a title had wrapped onto a
                  // second line, and the last line of the purpose was cut
                  // through the middle of its letters and ran into the
                  // minutes underneath.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final line = 12.5 *
                            1.35 *
                            MediaQuery.textScalerOf(context).scale(1);
                        final fit = (box.maxHeight / line).floor();
                        final lines =
                            math.min(fit, path != null ? 3 : 2);
                        if (lines < 1) return const SizedBox.shrink();
                        return ClipRect(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              _firstLine(d.localizedNote(locale)),
                              maxLines: lines,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: path != null
                                      ? Colors.white70
                                      : T.textDim,
                                  fontSize: 12.5,
                                  height: 1.35),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.schedule_outlined,
                          size: 13, color: path != null ? Colors.white70 : T.textOff),
                      const SizedBox(width: 4),
                      Text('drills_minutes'.tr(args: ['${d.minutes}']),
                          style: TextStyle(
                              color: path != null ? Colors.white70 : T.textOff,
                              fontSize: 11.5)),
                    ],
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
            _CategoryTile(
              category: c,
              sport: sport,
              label: DrillLibraryService.instance.label(context, c.labelKeyFor(sport.drillVocabulary)),
              // How much is behind the door, before opening it.
              count: counts[c]!,
              onTap: () => onTap(c),
            ),
      ],
    );
  }
}

/// One category, as a tile with its own mark and colour.
///
/// These were the app's filter chips, which is what they are NOT: a filter
/// chip is one of a set you switch between, and nine identical grey pills
/// read as a wall of text a coach has to parse word by word. A door into
/// finishing drills should be recognisable before it is read — so each
/// carries a glyph and a colour of its own, and after a week the coach is
/// tapping the orange one rather than reading nine labels.
class _CategoryTile extends StatelessWidget {
  final DrillCategory category;
  final SportType sport;
  final String label;
  final int count;
  final VoidCallback onTap;
  const _CategoryTile(
      {required this.category,
      required this.sport,
      required this.label,
      required this.count,
      required this.onTap});

  /// Material's own glyphs rather than drawn artwork: they are vector, they
  /// take the tile's colour, they scale with the text size, and they cost
  /// nothing in the bundle — which a generated icon sheet does on all four
  /// counts.
  static IconData _icon(DrillCategory c) => switch (c) {
        DrillCategory.warmup => Icons.directions_run,
        DrillCategory.possession => Icons.hub_outlined,
        DrillCategory.attacking => Icons.bolt,
        DrillCategory.finishing => Icons.sports_score,
        DrillCategory.defending => Icons.shield_outlined,
        DrillCategory.setpiece => Icons.groups_outlined,
        DrillCategory.ssg => Icons.grid_view_rounded,
        DrillCategory.goalkeeping => Icons.back_hand_outlined,
        DrillCategory.conditioning => Icons.fitness_center,
      };

  /// Warm where the drill is about scoring, cool where it is about denying:
  /// the ordering is the session's, from warm-up through to the running that
  /// ends it, and the hues walk with it rather than being picked at random.
  static Color _tint(DrillCategory c) => switch (c) {
        DrillCategory.warmup => const Color(0xFF4ADE80),
        DrillCategory.possession => const Color(0xFF60A5FA),
        DrillCategory.attacking => const Color(0xFFF87171),
        DrillCategory.finishing => const Color(0xFFFBBF24),
        DrillCategory.defending => const Color(0xFFA78BFA),
        DrillCategory.setpiece => const Color(0xFF22D3EE),
        DrillCategory.ssg => const Color(0xFFFB923C),
        DrillCategory.goalkeeping => const Color(0xFF86EFAC),
        DrillCategory.conditioning => const Color(0xFF94A3B8),
      };

  @override
  Widget build(BuildContext context) {
    final tint = _tint(category);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.10),
          borderRadius: T.brSm,
          border: Border.all(color: tint.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The ball itself where the category IS the ball: a football in
            // a basketball app would be the one wrong note in the row.
            if (category == DrillCategory.possession)
              SportGlyph(sport: sport, size: 17)
            else
              Icon(_icon(category), size: 17, color: tint),
            const SizedBox(width: 7),
            Text(label,
                style: const TextStyle(
                    color: T.text, fontSize: 13.5, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Text('$count',
                style: const TextStyle(color: T.textOff, fontSize: 12.5)),
          ],
        ),
      ),
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
            BoxDecoration(color: T.surfaceHi, borderRadius: T.brMd),
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
                BoxDecoration(color: T.surface, borderRadius: T.brMd),
            child: Row(
              children: [
                Icon(Icons.school_outlined, size: 20, color: T.accent),
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
                    decoration: BoxDecoration(
                        color: T.surfaceHi, borderRadius: T.brMd),
                    alignment: Alignment.center,
                    child: Text(DrillLibraryService.instance.label(context, l.labelKey),
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

/// Account, help and language, behind the ellipsis in the header.
///
/// The same popover the board uses (lib/pages/home_page.dart), deliberately:
/// these three live there too, and a coach who found them under an ellipsis
/// on one screen should not have to hunt for a different shape on the other.
class _HomeMenu extends StatelessWidget {
  final VoidCallback onLanguage;
  final VoidCallback onContact;
  final VoidCallback onLogin;
  const _HomeMenu({
    required this.onLanguage,
    required this.onContact,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) {
        switch (v) {
          case 'language':
            onLanguage();
          case 'contact':
            onContact();
          case 'login':
            onLogin();
        }
      },
      color: T.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shadowColor: const Color(0x73000000),
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: T.border),
      ),
      offset: const Offset(0, 46),
      padding: EdgeInsets.zero,
      tooltip: '',
      child: const SizedBox(
        width: T.tap,
        height: T.tap,
        child: Icon(Icons.more_horiz, size: 22, color: T.textDim),
      ),
      itemBuilder: (_) => [
        _item('language', Icons.language_rounded, 'menu_language'.tr()),
        _item('contact', Icons.mail_outline_rounded, 'menu_contact'.tr()),
        _item('login', Icons.person_outline_rounded, 'menu_login'.tr()),
      ],
    );
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: T.s16),
      child: Row(
        children: [
          Icon(icon, color: T.textDim, size: 19),
          const SizedBox(width: T.s12),
          // Two lines allowed: these labels are long in French, Vietnamese
          // and Thai, and the popover is deliberately narrow.
          Expanded(
            child: Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: T.text, fontSize: 15, height: 1.25)),
          ),
        ],
      ),
    );
  }
}

/// The app's language as the drill library keys it ('zh-CN', 'en').
String _localeTag(BuildContext context) {
  final l = context.locale;
  return l.countryCode == null
      ? l.languageCode
      : '${l.languageCode}-${l.countryCode}';
}
