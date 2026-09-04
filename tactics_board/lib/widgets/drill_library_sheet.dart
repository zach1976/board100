import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/drill.dart';
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
          final shown =
              _filter == null ? all : all.where((d) => d.category == _filter).toList();
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
                            label: c.labelKey.tr(),
                            selected: _filter == c,
                            onTap: () => setState(() => _filter = c),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: shown.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _DrillRow(
                        drill: shown[i],
                        locale: _locale,
                        locked: !_unlocked(shown[i]),
                        onTap: () => _load(shown[i]),
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

class _DrillRow extends StatelessWidget {
  final Drill drill;
  final String locale;
  final bool locked;
  final VoidCallback onTap;
  const _DrillRow({
    required this.drill,
    required this.locale,
    required this.locked,
    required this.onTap,
  });

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drill.localizedName(locale),
                    style: TextStyle(
                        color: locked ? Colors.white70 : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    drill.localizedNote(locale),
                    style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.35),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      _Fact(icon: Icons.schedule, text: 'drills_minutes'.tr(args: ['${drill.minutes}'])),
                      const SizedBox(width: 12),
                      _Fact(icon: Icons.groups_outlined, text: '${drill.players}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(locked ? Icons.lock_outline : Icons.play_circle_outline,
                color: locked ? Colors.white38 : kAccent, size: 26),
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
        Text(text, style: const TextStyle(color: Colors.white38, fontSize: 11.5)),
      ],
    );
  }
}
