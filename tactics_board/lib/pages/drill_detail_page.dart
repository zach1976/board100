import 'dart:ui' show FontFeature;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/drill.dart';
import '../models/drill_note.dart';
import '../models/sport_type.dart';
import '../services/drill_notes_service.dart';
import '../state/tactics_state.dart';
import '../ui/primitives.dart';
import '../ui/tokens.dart';
import '../widgets/tactics_canvas.dart';
import 'drill_report_page.dart';

/// Everything a coach needs to decide whether to run this drill, on one page.
///
/// The library card can only ever be a headline: a name, a clamped note and
/// two numbers. What it cannot show is the board — and the board IS the
/// drill. So this page draws the real [TacticsCanvas] with the real drill
/// loaded, and lays the note out as what each part of it is FOR rather than
/// as seven identical grey paragraphs: the purpose leads, the ball path is a
/// chain, the sequence is a list of beats.
///
/// And the two halves talk to each other. Tapping a beat walks the board to
/// it; walking the board marks the beat it reached. Before that the page was
/// a diagram and a description side by side, and the reader had to hold one
/// against the other themselves.
///
/// The canvas runs on its own throwaway [TacticsState] (`preview: true`), so
/// stepping through here never touches the coach's live board.
class DrillDetailPage extends StatefulWidget {
  final Drill drill;
  final SportType sportType;
  final String locale;

  /// Puts the drill on the live board. Null when the drill is locked.
  final VoidCallback? onLoad;

  /// Shown instead of the load button when the drill is behind Pro.
  final VoidCallback? onUpgrade;

  const DrillDetailPage({
    super.key,
    required this.drill,
    required this.sportType,
    required this.locale,
    this.onLoad,
    this.onUpgrade,
  });

  static Future<void> push(
    BuildContext context, {
    required Drill drill,
    required SportType sportType,
    required String locale,
    VoidCallback? onLoad,
    VoidCallback? onUpgrade,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DrillDetailPage(
          drill: drill,
          sportType: sportType,
          locale: locale,
          onLoad: onLoad,
          onUpgrade: onUpgrade,
        ),
      ),
    );
  }

  @override
  State<DrillDetailPage> createState() => _DrillDetailPageState();
}

class _DrillDetailPageState extends State<DrillDetailPage> {
  late final TacticsState _preview;
  DrillMark _mark = const DrillMark();

  @override
  void initState() {
    super.initState();
    _preview = TacticsState(sportType: widget.sportType, preview: true)
      ..loadFromJson(Map<String, dynamic>.from(widget.drill.board));
    DrillNotesService.instance
        .forDrill(widget.sportType, widget.drill.id)
        .then((m) {
      if (mounted) setState(() => _mark = m);
    });
  }

  Future<void> _toggleStar() async {
    final next = !_mark.starred;
    setState(() => _mark = _mark.copyWith(starred: next));
    await DrillNotesService.instance
        .setStarred(widget.sportType, widget.drill.id, next);
  }

  /// The coach's own note on a shipped drill — what is true of THEIR group.
  Future<void> _editNote() async {
    var text = _mark.note;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: T.surfaceHi,
        title: Text('drill_note_title'.tr(),
            style: const TextStyle(color: T.text)),
        content: TextFormField(
          initialValue: text,
          autofocus: true,
          maxLines: 4,
          maxLength: 300,
          style: const TextStyle(color: T.text),
          decoration: InputDecoration(
            hintText: 'drill_note_hint'.tr(),
            hintStyle: const TextStyle(color: T.textOff),
            counterStyle: const TextStyle(color: T.textOff, fontSize: 11),
          ),
          onChanged: (v) => text = v,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr())),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('confirm'.tr())),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _mark = _mark.copyWith(note: text.trim()));
    await DrillNotesService.instance
        .setNote(widget.sportType, widget.drill.id, text);
  }

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  /// Walk the board to the beat that was tapped. Beat n is step n+1 — step 0
  /// is the setup, before anything has happened.
  void _goToBeat(int beat) =>
      _preview.animateToStep((beat + 1).clamp(0, _preview.maxMoveSteps));

  @override
  Widget build(BuildContext context) {
    final d = widget.drill;
    final note = DrillNote.parse(d.localizedNote(widget.locale));
    final mistake = d.localizedMistake(widget.locale);
    final lead = note.sections
        .where((s) => s.kind == DrillSectionKind.lead)
        .map((s) => s.body)
        .firstOrNull;

    return Scaffold(
      backgroundColor: T.bg0,
      body: SafeArea(
        child: Column(
          children: [
            _header(context, d),
            // The board stays put while the note scrolls under it. Tapping
            // beat 5 walks the board to beat 5 — which is worth nothing if
            // scrolling to beat 5 has pushed the board off the screen.
            ChangeNotifierProvider<TacticsState>.value(
              value: _preview,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: T.screenX),
                child: _BoardCard(state: _preview),
              ),
            ),
            const SizedBox(height: T.s16),
            Expanded(
              child: ChangeNotifierProvider<TacticsState>.value(
                value: _preview,
                child: ListView(
                  padding:
                      const EdgeInsets.fromLTRB(T.screenX, 0, T.screenX, T.s24),
                  children: [
                    if (lead != null) ...[
                      Text(
                        lead,
                        style: const TextStyle(
                            color: T.text, fontSize: 16, height: 1.55),
                      ),
                      const SizedBox(height: T.s16),
                    ],
                    for (final s in note.sections)
                      if (s.kind != DrillSectionKind.lead) _sectionWidget(s),
                    if (mistake != null) ...[
                      const SizedBox(height: T.s4),
                      _mistakeBlock(mistake),
                    ],
                    const SizedBox(height: T.s16),
                    _MyNote(mark: _mark, onEdit: _editNote),
                    const SizedBox(height: T.s16),
                    // Quiet, at the bottom, where you land after finding
                    // something wrong rather than before reading it.
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => DrillReportPage.push(
                        context,
                        drill: d,
                        sportType: widget.sportType,
                        locale: widget.locale,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: T.s8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.flag_outlined,
                                size: 14, color: T.textOff),
                            const SizedBox(width: 6),
                            Text('report_title'.tr(),
                                style: const TextStyle(
                                    color: T.textOff, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _sectionWidget(DrillSection s) {
    switch (s.kind) {
      case DrillSectionKind.route:
        return _RouteRow(section: s);
      case DrillSectionKind.sequence:
        return _Beats(section: s, onTap: _goToBeat);
      case DrillSectionKind.point:
        return _PointCard(section: s);
      case DrillSectionKind.lead:
      case DrillSectionKind.info:
        return _InfoRow(section: s);
    }
  }

  /// The name, and under it the numbers a coach filters on. A row of pills
  /// for four facts was four boxes doing the work of one line.
  Widget _header(BuildContext context, Drill d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(T.s8, T.s4, T.screenX, T.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: TacticalIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: T.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.localizedName(widget.locale),
                  style: const TextStyle(
                      color: T.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.2),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _meta(Icons.schedule_outlined,
                        'drills_minutes'.tr(args: ['${d.minutes}'])),
                    _meta(Icons.groups_outlined, '${d.players}'),
                    _dot(),
                    Text(
                      d.category
                          .labelKeyFor(widget.sportType.drillVocabulary)
                          .tr(),
                      style: const TextStyle(color: T.textDim, fontSize: 12.5),
                    ),
                    _dot(),
                    Text(d.level.labelKey.tr(),
                        style:
                            const TextStyle(color: T.textDim, fontSize: 12.5)),
                  ],
                ),
              ],
            ),
          ),
          // The star is the whole of "my library": a coach uses maybe twenty
          // of six hundred, and this is how those twenty are named.
          TacticalIconButton(
            icon: _mark.starred ? Icons.star_rounded : Icons.star_border_rounded,
            onTap: _toggleStar,
            color: _mark.starred ? T.warning : null,
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: T.textOff),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: T.textDim, fontSize: 12.5)),
        ],
      );

  Widget _dot() => Container(
        width: 3,
        height: 3,
        decoration:
            const BoxDecoration(color: T.textOff, shape: BoxShape.circle),
      );

  Widget _mistakeBlock(String mistake) {
    return Container(
      padding: const EdgeInsets.all(T.s12),
      decoration: BoxDecoration(
        color: T.warning.withValues(alpha: 0.09),
        borderRadius: T.brMd,
        border: Border.all(color: T.warning.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child:
                Icon(Icons.warning_amber_rounded, size: 16, color: T.warning),
          ),
          const SizedBox(width: T.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('drills_common_mistake'.tr(),
                    style: TextStyle(
                        color: T.warning.withValues(alpha: 0.9),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(mistake,
                    style: const TextStyle(
                        color: T.text, fontSize: 14.5, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final locked = widget.onLoad == null;
    return Container(
      padding: const EdgeInsets.fromLTRB(T.screenX, T.s12, T.screenX, T.s12),
      decoration: const BoxDecoration(
        color: T.bg1,
        border: Border(top: BorderSide(color: T.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: TacticalButton(
          label: locked ? 'drills_unlock'.tr() : 'drills_put_on_board'.tr(),
          icon: locked ? Icons.lock_outline : Icons.add_circle_outline,
          onTap: locked ? widget.onUpgrade : widget.onLoad,
        ),
      ),
    );
  }
}

/// The board and the control that walks it, as one object.
///
/// They used to be a picture with a stepper floating underneath, reading as
/// two unrelated things — and the board given the full width came out 1.8
/// screens tall, pushing the note under the fold on every phone.
class _BoardCard extends StatelessWidget {
  final TacticsState state;
  const _BoardCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Consumer<TacticsState>(
      builder: (context, s, _) {
        final steps = s.maxMoveSteps;
        return Container(
          decoration:
              const BoxDecoration(color: T.surface, borderRadius: T.brLg),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(T.s12, T.s12, T.s12, 0),
                child: ClipRRect(
                  borderRadius: T.brMd,
                  // Drawn at the size the board is really drawn at, then
                  // scaled as one picture. A token is a fixed 44pt whatever
                  // box the canvas is given, so a preview laid out small got
                  // full-size players on a shrunken pitch — three of them
                  // covering the centre circle. Scaling the finished board
                  // instead makes the preview exactly the board, smaller.
                  child: Center(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.32,
                      child: const FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: kBoardRefWidth,
                          height: kBoardRefHeight,
                          child: IgnorePointer(
                              child: TacticsCanvas(preview: true)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (steps > 0)
                _StepBar(state: s, steps: steps, at: s.atStep)
              else
                const SizedBox(height: T.s12),
            ],
          ),
        );
      },
    );
  }
}

class _StepBar extends StatelessWidget {
  final TacticsState state;
  final int steps;
  final int at;
  const _StepBar({required this.state, required this.steps, required this.at});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(T.s8, T.s4, T.s8, T.s4),
      child: Row(
        children: [
          TacticalIconButton(
            icon: Icons.chevron_left,
            onTap: at > 0 ? state.stepBackward : null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: T.s8),
              // A track, not just a number: how far through the drill this is
              // at a glance, without counting.
              child: Row(
                children: [
                  for (var i = 0; i <= steps; i++) ...[
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: i <= at ? T.accent : T.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (i != steps) const SizedBox(width: 3),
                  ],
                ],
              ),
            ),
          ),
          Text('$at/$steps',
              style: const TextStyle(
                  color: T.textDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()])),
          const SizedBox(width: T.s8),
          TacticalIconButton(
            icon: Icons.chevron_right,
            onTap: at < steps ? state.stepForward : null,
          ),
        ],
      ),
    );
  }
}

/// Frequency, origin, setup: a label and a standing fact.
class _InfoRow extends StatelessWidget {
  final DrillSection section;
  const _InfoRow({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: T.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.label != null)
            Text(section.label!,
                style: const TextStyle(
                    color: T.textOff,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
          const SizedBox(height: 3),
          Text(section.body,
              style: const TextStyle(
                  color: T.textDim, fontSize: 14.5, height: 1.5)),
        ],
      ),
    );
  }
}

/// The ball path as the chain it is: 1 → 2 → 3 → goal.
class _RouteRow extends StatelessWidget {
  final DrillSection section;
  const _RouteRow({required this.section});

  @override
  Widget build(BuildContext context) {
    final stops = section.stops;
    return Padding(
      padding: const EdgeInsets.only(bottom: T.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.label != null)
            Text(section.label!,
                style: const TextStyle(
                    color: T.textOff,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < stops.length; i++) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: T.surfaceHi,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(stops[i],
                      style: const TextStyle(
                          color: T.text,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600)),
                ),
                if (i != stops.length - 1)
                  const Icon(Icons.arrow_forward, size: 13, color: T.textOff),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The beats, and the board's remote control.
///
/// Tapping one walks the board to it, and the board walking marks the beat it
/// reached — so reading the drill and watching it are the same act.
class _Beats extends StatelessWidget {
  final DrillSection section;
  final void Function(int) onTap;
  const _Beats({required this.section, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final beats = section.beats;
    if (beats.isEmpty) return _InfoRow(section: section);
    return Consumer<TacticsState>(
      builder: (context, s, _) {
        // The board counts the setup as step 0, so beat i is step i + 1.
        final live = s.atStep - 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: T.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (section.label != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(section.label!,
                      style: const TextStyle(
                          color: T.textOff,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                ),
              for (var i = 0; i < beats.length; i++)
                _BeatRow(
                  index: i,
                  text: beats[i],
                  current: i == live,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BeatRow extends StatelessWidget {
  final int index;
  final String text;
  final bool current;
  final VoidCallback onTap;
  const _BeatRow({
    required this.index,
    required this.text,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: current ? T.accentFill : Colors.transparent,
          borderRadius: T.brSm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 21,
              height: 21,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: current ? T.accent : T.surfaceHi,
                shape: BoxShape.circle,
              ),
              child: Text('${index + 1}',
                  style: TextStyle(
                      color: current ? const Color(0xFF04231F) : T.textDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: T.s8),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: current ? T.text : T.textDim,
                      fontSize: 14.5,
                      height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The one thing to say out loud, given the weight that deserves.
class _PointCard extends StatelessWidget {
  final DrillSection section;
  const _PointCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: T.s12),
      padding: const EdgeInsets.all(T.s12),
      decoration: BoxDecoration(
        color: T.accentFill,
        borderRadius: T.brMd,
        border: Border.all(color: T.accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.campaign_outlined, size: 16, color: T.accent),
          ),
          const SizedBox(width: T.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (section.label != null)
                  Text(section.label!,
                      style: const TextStyle(
                          color: T.accent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(section.body,
                    style: const TextStyle(
                        color: T.text, fontSize: 15, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The coach's own note on a shipped drill.
///
/// The library's words are written for everybody; this is the line that is
/// true of one group and nobody else's — "ours need the square 2 m bigger".
class _MyNote extends StatelessWidget {
  final DrillMark mark;
  final VoidCallback onEdit;
  const _MyNote({required this.mark, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final empty = !mark.hasNote;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(T.s12),
        decoration: BoxDecoration(
          color: empty ? Colors.transparent : T.surface,
          borderRadius: T.brMd,
          border: Border.all(
              color: empty ? T.border : Colors.transparent,
              style: BorderStyle.solid),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(empty ? Icons.edit_note : Icons.sticky_note_2_outlined,
                size: 16, color: empty ? T.textOff : T.accent),
            const SizedBox(width: T.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('drill_note_title'.tr(),
                      style: TextStyle(
                          color: empty ? T.textOff : T.accent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text(empty ? 'drill_note_empty'.tr() : mark.note,
                      style: TextStyle(
                          color: empty ? T.textOff : T.text,
                          fontSize: 14.5,
                          height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
