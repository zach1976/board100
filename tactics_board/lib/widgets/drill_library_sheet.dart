import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/drill.dart';
import '../models/sport_type.dart';
import '../services/drill_library_service.dart';
import '../services/purchase_service.dart';
import '../state/tactics_state.dart';
import '../ui_constants.dart';
import 'toolbar.dart' show sheetConstraints, scaledSheet;

/// The drill library: pick a session piece and put it on the board.
///
/// Every rival ships content; a blank board is the reason a coach opens this
/// app once and not again on Tuesday. Loading a drill is loading a tactic —
/// same JSON, same animation — so the coach can immediately edit it into
/// their own, which is the point: these are starting shapes, not a locked
/// catalogue.
class DrillLibrarySheet extends StatefulWidget {
  final TacticsState state;

  /// Opens the purchase sheet. Null on builds with no store.
  final VoidCallback? onUpgrade;
  const DrillLibrarySheet({super.key, required this.state, this.onUpgrade});

  static Future<void> show(BuildContext context, TacticsState state,
      {VoidCallback? onUpgrade}) {
    return showModalBottomSheet<void>(
      context: context,
      constraints: sheetConstraints(context),
      backgroundColor: kSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) =>
          scaledSheet(ctx, DrillLibrarySheet(state: state, onUpgrade: onUpgrade)),
    );
  }

  @override
  State<DrillLibrarySheet> createState() => _DrillLibrarySheetState();
}

class _DrillLibrarySheetState extends State<DrillLibrarySheet> {
  late Future<List<Drill>> _drills;
  DrillCategory? _filter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _drills = DrillLibraryService.instance.forSport(widget.state.sportType);
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
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(drill.localizedName(_locale))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Drill>>(
        future: _drills,
        builder: (context, snap) {
          final all = snap.data ?? const <Drill>[];
          final q = _query.trim().toLowerCase();
          final shown = all
              .where((d) => _filter == null || d.category == _filter)
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

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, color: kAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'drills_title'.tr(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('drills_hint'.tr(),
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 34),
                    child: Center(
                      child: Text('drills_empty'.tr(),
                          style: const TextStyle(color: Colors.white38, fontSize: 13)),
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
                        prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
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
                        _CategoryChip(
                          label: 'drill_cat_all'.tr(),
                          selected: _filter == null,
                          onTap: () => setState(() => _filter = null),
                        ),
                        for (final c in categories) ...[
                          const SizedBox(width: 6),
                          _CategoryChip(
                            label: c.labelKeyFor(widget.state.sportType.drillVocabulary).tr(),
                            selected: _filter == c,
                            onTap: () => setState(() => _filter = c),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 34),
                      child: Center(
                        child: Text('drills_no_match'.tr(args: [_query.trim()]),
                            style: const TextStyle(color: Colors.white38, fontSize: 13)),
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
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? kAccent : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: selected ? kAccent : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// One card. A family shows its heading, its coaching point once, and a chip
/// per variant; a drill that stands alone shows its own name and note and is
/// tappable as a whole.
class _DrillRow extends StatelessWidget {
  final List<Drill> variants;
  final String locale;
  final bool Function(Drill) isLocked;
  final void Function(Drill) onLoad;
  const _DrillRow({
    required this.variants,
    required this.locale,
    required this.isLocked,
    required this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    final first = variants.first;
    final grouped = variants.length > 1;
    // A family is locked only when every variant is: the free tier deliberately
    // opens one size of a rondo, not none of it.
    final allLocked = variants.every(isLocked);

    final card = Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grouped
                          ? first.localizedFamilyName(locale)
                          : first.localizedName(locale),
                      style: TextStyle(
                          color: allLocked ? Colors.white70 : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      first.localizedNote(locale),
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12, height: 1.35),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Flexible(
                          child: _Fact(
                              icon: Icons.schedule,
                              text: 'drills_minutes'.tr(args: [_span((d) => d.minutes)])),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: _Fact(
                              icon: Icons.groups_outlined,
                              text: _span((d) => d.players)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!grouped)
                Icon(allLocked ? Icons.lock_outline : Icons.play_circle_outline,
                    color: allLocked ? Colors.white38 : kAccent, size: 26),
            ],
          ),
          if (grouped) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final v in variants)
                  _VariantChip(
                    // The variant half of "<family> <variant>" is what the
                    // chip is for; showing the family name again on every
                    // chip is the repetition this grouping exists to remove.
                    label: _variantLabel(v),
                    locked: isLocked(v),
                    onTap: () => onLoad(v),
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    if (grouped) return card;
    return GestureDetector(
      onTap: () => onLoad(first),
      behavior: HitTestBehavior.opaque,
      child: card,
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
            Icon(locked ? Icons.lock_outline : Icons.play_arrow_rounded,
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

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Fact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white38),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 11.5)),
        ),
      ],
    );
  }
}
