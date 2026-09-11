import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../config_constants.dart';

import '../models/drill.dart';
import 'drill_detail_page.dart';
import '../models/tactic_meta.dart';
import '../models/sport_type.dart';
import '../services/drill_library_service.dart';
import '../services/drill_notes_service.dart';
import '../services/purchase_service.dart';
import '../services/recent_boards_service.dart';
import '../state/tactics_state.dart';
import '../ui_constants.dart';
import '../ui/primitives.dart';
import '../ui/tokens.dart';
import '../widgets/drill_thumbnail.dart';

/// The drill library: pick a session piece and put it on the board.
///
/// Every rival ships content; a blank board is the reason a coach opens this
/// app once and not again on Tuesday. Loading a drill is loading a tactic —
/// same JSON, same animation — so the coach can immediately edit it into
/// their own, which is the point: these are starting shapes, not a locked
/// catalogue.
class DrillLibraryPage extends StatefulWidget {
  final TacticsState state;

  /// Opens the purchase sheet. Null on builds with no store.
  final VoidCallback? onUpgrade;

  /// The category the list opens on. Used by the sport home page, whose
  /// category chips are a way INTO this list rather than a second copy of it.
  final DrillCategory? initialCategory;

  /// The level the list opens on — the home page's learning block leads
  /// here, and a coach who picked "foundation" means it.
  final DrillLevel? initialLevel;

  /// Open on the coach's own saved boards rather than the shipped library.
  /// The home page's "my boards" leads here for the full list.
  final bool openMine;

  /// Open showing only starred drills — the coach's own library within the
  /// shipped one.
  final bool starredOnly;

  /// Called after a drill has been put on the board. The sheet is opened
  /// from two places that want different things next: over the board it is
  /// already where the coach wants to be, but from the home page the board
  /// is another push away.
  final VoidCallback? onLoaded;

  const DrillLibraryPage({
    super.key,
    required this.state,
    this.onUpgrade,
    this.initialCategory,
    this.initialLevel,
    this.openMine = false,
    this.starredOnly = false,
    this.onLoaded,
  });

  /// A page, not a sheet.
  ///
  /// Six hundred drills behind a search box, two rows of filters and a
  /// scrolling list is a place you work in, and a sheet says the opposite:
  /// it covers the board, caps itself at 82% of the screen, and is dismissed
  /// by a stray swipe. On a page the list gets the whole screen and the back
  /// button means what it says.
  static Future<void> push(BuildContext context, TacticsState state,
      {VoidCallback? onUpgrade,
      DrillCategory? initialCategory,
      DrillLevel? initialLevel,
      bool openMine = false,
      bool starredOnly = false,
      VoidCallback? onLoaded}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DrillLibraryPage(
          state: state,
          onUpgrade: onUpgrade,
          initialCategory: initialCategory,
          initialLevel: initialLevel,
          openMine: openMine,
          starredOnly: starredOnly,
          onLoaded: onLoaded,
        ),
      ),
    );
  }

  @override
  State<DrillLibraryPage> createState() => _DrillLibraryPageState();
}

class _DrillLibraryPageState extends State<DrillLibraryPage> {
  late Future<List<Drill>> _drills;
  DrillCategory? _filter;
  DrillLevel? _level;
  String _query = '';
  // The coach's own saved boards, offered beside the shipped library. A
  // drill and a saved tactic are the same JSON, so "use my own" is loading,
  // not importing.
  List<TacticMeta> _mine = const [];
  bool _showMine = false;
  bool _starred = false;
  Map<String, DrillMark> _marks = const {};

  @override
  void initState() {
    super.initState();
    _filter = widget.initialCategory;
    _level = widget.initialLevel;
    _showMine = widget.openMine;
    _starred = widget.starredOnly;
    DrillNotesService.instance.all(widget.state.sportType).then((m) {
      if (mounted) setState(() => _marks = m);
    });
    _drills = DrillLibraryService.instance.forSport(widget.state.sportType);
    widget.state.listSavedTacticMetas().then((metas) {
      if (mounted) setState(() => _mine = metas);
    }).catchError((_) {
      // No saved boards is a normal state (first run, tests); the chip
      // simply does not appear.
    });
  }

  Future<void> _loadMine(TacticMeta meta) async {
    await widget.state.loadTactics(meta.name);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(meta.name)),
    );
  }

  /// Locked drills exist only where there is a store to unlock them in: on a
  /// build with no IAP, showing a lock nobody can open would just be a wall.
  bool _unlocked(Drill d) =>
      d.free ||
      !PurchaseService.instance.isStoreEnabled ||
      PurchaseService.instance.hasPro;

  String get _locale {
    final l = context.locale;
    return l.countryCode == null ? l.languageCode : '${l.languageCode}-${l.countryCode}';
  }

  void _load(Drill drill) {
    if (!_unlocked(drill)) {
      Navigator.of(context).pop();
      widget.onUpgrade?.call();
      return;
    }
    // A drill is a starting shape the coach edits, so it lands as an unsaved
    // board rather than overwriting whatever they had saved.
    widget.state.loadFromJson(Map<String, dynamic>.from(drill.board));
    widget.state.currentTacticName = null;
    widget.state.currentTacticMeta = null;
    // A drill is never saved — it is a starting shape the coach edits — so
    // without this the thing they most recently had on the board is exactly
    // the thing the home page cannot offer them again.
    RecentBoardsService.instance.record(
      widget.state.sportType,
      RecentBoard(
        kind: RecentBoardKind.drill,
        id: drill.id,
        label: drill.localizedName(_locale),
        openedAt: DateTime.now(),
      ),
    );
    // Whether the library gets out of the way depends on where the board
    // is. Opened FROM the board it is a layer on top of it, so it closes and
    // the coach is back on the board they were looking at. Opened from the
    // home page the board is pushed ON TOP of the library (onLoaded), so
    // closing it here would drop the coach back to the home page — and going
    // back from the board should return them to the list they were browsing.
    if (widget.onLoaded == null) Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(drill.localizedName(_locale))),
    );
    widget.onLoaded?.call();
  }

  /// The whole drill on its own page: the board it makes, stepped through,
  /// and the note laid out section by section. The card can only ever show a
  /// headline, and a coach deciding what to run on Tuesday needs the shape.
  Future<void> _openDetail(Drill drill) async {
    final unlocked = _unlocked(drill);
    await DrillDetailPage.push(
      context,
      drill: drill,
      sportType: widget.state.sportType,
      locale: _locale,
      onLoad: unlocked
          ? () {
              // Out of the drill's page, then onto the board. The library
              // itself stays where it is — see _load.
              Navigator.of(context).pop();
              _load(drill);
            }
          : null,
      onUpgrade: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        widget.onUpgrade?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.bg0,
      body: SafeArea(
        child: Padding(
      padding: const EdgeInsets.fromLTRB(T.screenX, T.s4, T.screenX, T.s8),
      child: FutureBuilder<List<Drill>>(
        future: _drills,
        builder: (context, snap) {
          final all = snap.data ?? const <Drill>[];
          final q = _query.trim().toLowerCase();
          final shown = all
              .where((d) => !_starred || (_marks[d.id]?.starred ?? false))
              .where((d) => _filter == null || d.category == _filter)
              .where((d) => _level == null || d.level == _level)
              .where((d) =>
                  q.isEmpty ||
                  d.localizedName(_locale).toLowerCase().contains(q) ||
                  d.localizedNote(_locale).toLowerCase().contains(q))
              .toList();
          // Variants of a family share their note word for word, so a flat
          // list shows the same paragraph five times over. Group them: one
          // card per family, the coaching point once, the variants beside it.
          final groups = <List<Drill>>[];
          final byFamily = <String, int>{};
          for (final d in shown) {
            final fam = d.family;
            if (fam == null) {
              groups.add([d]);
              continue;
            }
            final at = byFamily[fam];
            if (at == null) {
              byFamily[fam] = groups.length;
              groups.add([d]);
            } else {
              groups[at].add(d);
            }
          }
          final categories = <DrillCategory>{for (final d in all) d.category}.toList()
            ..sort((a, b) => a.index.compareTo(b.index));

          // What each chip would give you if you tapped it: the search and
          // the OTHER axis still apply, its own does not. A "热身 0" is worth
          // reading; a count that ignored the level filter would lie.
          bool matchesQuery(Drill d) =>
              q.isEmpty ||
              d.localizedName(_locale).toLowerCase().contains(q) ||
              d.localizedNote(_locale).toLowerCase().contains(q);
          bool starredOk(Drill d) =>
              !_starred || (_marks[d.id]?.starred ?? false);
          int countForCategory(DrillCategory? c) => all
              .where(starredOk)
              .where(matchesQuery)
              .where((d) => _level == null || d.level == _level)
              .where((d) => c == null || d.category == c)
              .length;
          int countForLevel(DrillLevel? l) => all
              .where(starredOk)
              .where(matchesQuery)
              .where((d) => _filter == null || d.category == _filter)
              .where((d) => l == null || d.level == l)
              .length;
          final starredCount = all
              .where((d) => _marks[d.id]?.starred ?? false)
              .where(matchesQuery)
              .length;

          // Padding now lives on TacticalSheet, so this is only the column.
          return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title, subtitle and close, in the shape every sheet uses.
                // Back, title and subtitle — a page's header, not a sheet's.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: T.s4),
                      child: TacticalIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('drills_title'.tr(),
                              style: const TextStyle(
                                  color: T.text,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('drills_hint'.tr(),
                              style: const TextStyle(
                                  color: T.textDim, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                // Say what's free up front. A lock the user only meets by
                // tapping reads as a trap; a count reads as an offer.
                if (all.any((d) => !_unlocked(d))) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onUpgrade?.call();
                    },
                    child: Text(
                      'drills_free_count'.tr(args: [
                        '${all.where((d) => d.free).length}',
                        '${all.length}',
                      ]),
                      style: const TextStyle(
                          color: kAccent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                if (snap.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: kAccent, strokeWidth: 3),
                    ),
                  )
                else if (all.isEmpty)
                  // §23: the one empty state, not a grey sentence. A search
                  // that finds nothing should look like the other dead ends
                  // in the app, not like a label someone forgot to style.
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: T.s32),
                    child: TacticalEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'drills_empty'.tr(),
                    ),
                  )
                else ...[
                  // A hundred-plus drills is a list you hunt in, not one you
                  // scroll. Search reads the localised name and note, so
                  // "corner" and "角球" both find the same rows.
                  SizedBox(
                    height: 38,
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      cursorColor: kAccent,
                      decoration: InputDecoration(
                        hintText: 'drills_search'.tr(),
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13.5),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 34, minHeight: 34),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Starred is always offered: it is how a coach picks
                        // twenty drills out of six hundred, and hiding it
                        // until they have saved a board hides the very thing
                        // that makes the library theirs.
                        _CategoryChip(
                          label: 'drills_starred'.tr(),
                          count: starredCount,
                          selected: _starred,
                          onTap: () => setState(() {
                            _starred = !_starred;
                            _showMine = false;
                          }),
                        ),
                        const SizedBox(width: 6),
                        if (_mine.isNotEmpty) ...[
                          _CategoryChip(
                            label: 'drills_mine'.tr(),
                            selected: _showMine,
                            onTap: () =>
                                setState(() => _showMine = !_showMine),
                          ),
                          const SizedBox(width: 6),
                        ],
                        _CategoryChip(
                          label: 'drill_cat_all'.tr(),
                          count: countForCategory(null),
                          selected: !_showMine && _filter == null,
                          onTap: () => setState(() {
                            _showMine = false;
                            _starred = false;
                            _filter = null;
                          }),
                        ),
                        for (final c in categories) ...[
                          const SizedBox(width: 6),
                          _CategoryChip(
                            label: c.labelKeyFor(widget.state.sportType.drillVocabulary).tr(),
                            count: countForCategory(c),
                            selected: _filter == c,
                            onTap: () => setState(() => _filter = c),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // The second axis: how much the drill asks of the players.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _CategoryChip(
                          label: 'drill_cat_all'.tr(),
                          count: countForLevel(null),
                          selected: _level == null,
                          onTap: () => setState(() => _level = null),
                        ),
                        for (final l in DrillLevel.values) ...[
                          const SizedBox(width: 6),
                          _CategoryChip(
                            label: l.labelKey.tr(),
                            count: countForLevel(l),
                            selected: _level == l,
                            onTap: () => setState(() => _level = l),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_showMine)
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _mine.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _MineRow(
                          meta: _mine[i],
                          onTap: () => _loadMine(_mine[i]),
                        ),
                      ),
                    )
                  else if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 26),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                                packageAsset('assets/icon/empty_search.png'),
                                width: 96),
                            const SizedBox(height: 10),
                            Text('drills_no_match'.tr(args: [_query.trim()]),
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: groups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _DrillRow(
                          variants: groups[i],
                          locale: _locale,
                          isLocked: (d) => !_unlocked(d),
                          onLoad: _load,
                          onOpen: _openDetail,
                        ),
                      ),
                    ),
                ],
              ],
          );
        },
      ),
        ),
      ),
    );
  }
}

/// The library's filter chip is the app's filter chip. It used to be a solid
/// accent block with a white border when selected, so a row of them read as
/// a row of buttons rather than a state.
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  const _CategoryChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.count});

  @override
  Widget build(BuildContext context) => TacticalChip(
      label: label, selected: selected, onTap: onTap, count: count);
}

/// One card. A family shows its heading, its coaching point once, and a chip
/// The drill's note, three lines until tapped.
///
/// Notes grew from one coaching sentence into setup / ball path / steps /
/// point, and the card's three-line clamp cut everything after the setup —
/// the full instruction existed nowhere in the app a coach could read it.
/// The card stays a card; the note opens under a tap and closes under
/// another.
class _ExpandableNote extends StatefulWidget {
  final String text;
  const _ExpandableNote({required this.text});

  @override
  State<_ExpandableNote> createState() => _ExpandableNoteState();
}

class _ExpandableNoteState extends State<_ExpandableNote> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _open = !_open),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              widget.text,
              maxLines: _open ? null : 3,
              overflow: _open ? null : TextOverflow.ellipsis,
              style: const TextStyle(
                  color: T.textDim, fontSize: 13.5, height: 1.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: Icon(
              _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 16,
              color: T.textOff,
            ),
          ),
        ],
      ),
    );
  }
}

/// per variant; a drill that stands alone shows its own name and note and is
/// tappable as a whole.
class _DrillRow extends StatelessWidget {
  final List<Drill> variants;
  final String locale;
  final bool Function(Drill) isLocked;
  final void Function(Drill) onLoad;
  final void Function(Drill) onOpen;
  const _DrillRow({
    required this.variants,
    required this.locale,
    required this.isLocked,
    required this.onLoad,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final first = variants.first;
    final grouped = variants.length > 1;
    // A family is locked only when every variant is: the free tier
    // deliberately opens one size of a rondo, not none of it.
    final allLocked = variants.every(isLocked);

    // A row, not a card. The note used to be dumped here four lines at a
    // time, which made every entry a paragraph to read — and a library you
    // read is a library you cannot skim. The whole note is one tap away on
    // the drill page; this is for finding which drill that is.
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: T.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DrillThumbnail(drill: first),
          const SizedBox(width: T.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grouped
                      ? first.localizedFamilyName(locale)
                      : first.localizedName(locale),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: allLocked ? T.textDim : T.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3),
                ),
                const SizedBox(height: 6),
                // A bounded Row, not a Wrap: a Wrap hands each child
                // unbounded width, and on a 320pt phone the level name in a
                // long locale then overflows the line it lands on.
                Row(
                  children: [
                    Flexible(
                      child: MetaItem(
                          icon: Icons.schedule_outlined,
                          label: 'drills_minutes'
                              .tr(args: [_span((d) => d.minutes)])),
                    ),
                    const SizedBox(width: T.s12),
                    Flexible(
                      child: MetaItem(
                          icon: Icons.groups_outlined,
                          label: _span((d) => d.players)),
                    ),
                    const SizedBox(width: T.s12),
                    Flexible(
                      child: MetaItem(
                          icon: Icons.bar_chart_rounded,
                          label: first.level.labelKey.tr()),
                    ),
                  ],
                ),
                if (grouped) ...[
                  const SizedBox(height: T.s8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final v in variants)
                        _VariantChip(
                          // The variant half of "<family> <variant>" is what
                          // the chip is for; showing the family name again on
                          // every chip is the repetition this grouping exists
                          // to remove.
                          label: _variantLabel(v),
                          locked: isLocked(v),
                          onTap: () => onOpen(v),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!grouped) ...[
            const SizedBox(width: T.s8),
            // The one control on the row: put it on the board now. The row
            // itself opens the drill instead, so the two things a coach wants
            // from a list — "use this" and "what is this?" — are each one tap
            // and never the same tap.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onLoad(first),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                    allLocked ? Icons.lock_outline : Icons.add_circle_outline,
                    color: allLocked ? T.textOff : T.accent,
                    size: T.iLg),
              ),
            ),
          ],
        ],
      ),
    );

    return GestureDetector(
      onTap: () => onOpen(first),
      behavior: HitTestBehavior.opaque,
      child: row,
    );
  }

  /// "10" for a single drill, "10–20" across a family. A rondo family runs
  /// 4v2 to 8v4, and showing only the first variant's numbers told a coach
  /// the whole card needed six players when the last chip needs twelve.
  String _span(int Function(Drill) of) {
    var lo = of(variants.first), hi = lo;
    for (final v in variants) {
      final n = of(v);
      if (n < lo) lo = n;
      if (n > hi) hi = n;
    }
    return lo == hi ? '$lo' : '$lo–$hi';
  }

  /// The drill's name with the family heading taken off the front. Falls back
  /// to the whole name whenever it does not start with the heading — a
  /// language whose word order puts the variant first, for instance.
  String _variantLabel(Drill v) {
    final full = v.localizedName(locale);
    final head = v.localizedFamilyName(locale);
    if (head.isNotEmpty && full.length > head.length && full.startsWith(head)) {
      final rest = full.substring(head.length).trim();
      if (rest.isNotEmpty) return rest;
    }
    return full;
  }
}

class _VariantChip extends StatelessWidget {
  final String label;
  final bool locked;
  final VoidCallback onTap;
  const _VariantChip(
      {required this.label, required this.locked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: locked ? 0.03 : 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: locked ? Colors.white12 : kAccent.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(locked ? Icons.lock_outline : Icons.add_rounded,
                size: 14, color: locked ? Colors.white38 : kAccent),
            const SizedBox(width: 5),
            // Flexible, not bare: a Wrap gives each chip the full row width,
            // so a long variant name — "the Australian formation", or its
            // French — overflows instead of shrinking. One line, ellipsised.
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: locked ? Colors.white38 : Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the coach's own saved boards — name, folder, and a play button.
class _MineRow extends StatelessWidget {
  final TacticMeta meta;
  final VoidCallback onTap;
  const _MineRow({required this.meta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meta.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  if (meta.folder.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(meta.folder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.add_circle_outline, color: kAccent, size: 26),
          ],
        ),
      ),
    );
  }
}

