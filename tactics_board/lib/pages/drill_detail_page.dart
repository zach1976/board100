
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/drill.dart';
import '../widgets/add_to_plan_sheet.dart';
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
    _scroll.dispose();
    _preview.dispose();
    super.dispose();
  }

  /// The page's own scroll, so tapping a beat can bring the board back.
  final _scroll = ScrollController();

  /// Walk the board to the beat that was tapped. Beat n is step n+1 — step 0
  /// is the setup, before anything has happened.
  ///
  /// Scrolls the board back on screen first, and not only so the coach can
  /// watch: animateToStep sets a target, and the thing that actually advances
  /// the step is the animation controller inside the canvas. Scrolled far
  /// enough down the page the canvas is unmounted, nothing drives it, and the
  /// tap silently does nothing at all.
  Future<void> _goToBeat(int beat) async {
    // By offset, not by Scrollable.ensureVisible on the board's own key:
    // scrolled this far the board is off the viewport and the list has
    // unmounted it, so there is no context left to make visible. The board
    // sits at the top of the stream, so the top IS the board.
    if (_scroll.hasClients && _scroll.offset > 0) {
      await _scroll.animateTo(0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic);
    }
    if (!mounted) return;
    _preview.animateToStep((beat + 1).clamp(0, _preview.maxMoveSteps));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.drill;
    final note = DrillNote.parse(d.localizedNote(widget.locale));
    final mistake = d.localizedMistake(widget.locale);
    final lead = note.sections
        .where((s) => s.kind == DrillSectionKind.lead)
        .map((s) => s.body)
        .firstOrNull;
    // For the caption under the board: the sequence's beats, and the set-up
    // line — the section whose icon is the group, whatever its language.
    final beats = note.sections
        .where((s) => s.kind == DrillSectionKind.sequence)
        .map((s) => s.beats)
        .firstOrNull ?? const <String>[];
    final setup = note.sections
        .where((s) =>
            s.label != null && _sectionIcon(s.label!) == Icons.groups_outlined)
        .map((s) => s.body)
        .firstOrNull;

    return Scaffold(
      backgroundColor: T.bg0,
      body: SafeArea(
        child: Column(
          children: [
            TacticalNavBar(
              actions: [
                TacticalIconButton(
                  icon: _mark.starred
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  onTap: _toggleStar,
                  color: _mark.starred ? T.warning : null,
                ),
              ],
            ),
            Expanded(
              // One stream: the name, the facts, the board and the reading
              // all scroll together. The board used to be pinned so that
              // tapping beat 5 could not push it off screen — but a board
              // nailed to the top costs 40% of every screenful on a page
              // whose job is to be read, and the strip that walks it is
              // right beside the beats anyway.
              child: ChangeNotifierProvider<TacticsState>.value(
                value: _preview,
                child: ListView(
                  controller: _scroll,
                  padding:
                      const EdgeInsets.fromLTRB(0, 0, 0, T.s24),
                  children: [
                    _header(context, d),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: T.screenX),
                      child: _BoardCard(
                          state: _preview, beats: beats, setup: setup),
                    ),
                    const SizedBox(height: T.s24),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: T.screenX),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        if (lead != null) ...[
                          CoachNote(text: lead),
                          const SizedBox(height: T.sectionGap),
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

  /// The nav row, the drill's name, and the facts a coach filters on.
  ///
  /// The name is the page's DISPLAY heading and is not repeated in the bar:
  /// a title in both places is the same words twice, and it costs the pitch
  /// the room it needs to be the hero of this page.
  Widget _header(BuildContext context, Drill d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(T.screenX, T.s4, T.screenX, T.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.localizedName(widget.locale), style: T.display),
              const SizedBox(height: T.s12),
              Wrap(
                spacing: T.s16,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  MetaItem(
                      icon: Icons.schedule_outlined,
                      label: 'drills_minutes'.tr(args: ['${d.minutes}'])),
                  MetaItem(
                      icon: Icons.groups_outlined, label: '${d.players}'),
                  MetaItem(
                      icon: Icons.local_fire_department_outlined,
                      label: d.category
                          .labelKeyFor(widget.sportType.drillVocabulary)
                          .tr()),
                  MetaItem(
                      icon: Icons.bar_chart_rounded,
                      label: d.level.labelKey.tr()),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

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

  Future<void> _addToPlan() async {
    await AddToPlanSheet.show(
      context,
      sport: widget.sportType,
      drill: widget.drill,
      locale: widget.locale,
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
      child: Row(
        children: [
          // Not shown on a locked drill: there is nothing to put in a plan
          // until it is unlocked, and offering it would be a dead end.
          if (!locked) ...[
            // 2:3 — the primary keeps enough width for its own label in
            // every locale. At an even split French truncated it to
            // "Mettre sur le t…", which is the main action losing its name.
            Expanded(
              flex: 2,
              child: TacticalButton(
                label: 'practice_add_short'.tr(),
                large: true,
                // No icon on this one. The 32px it costs is the difference
                // between "Add to plan" and "Add to pl…" in most locales,
                // and the filled primary beside it already carries one.
                quiet: true,
                onTap: _addToPlan,
              ),
            ),
            const SizedBox(width: T.s8),
          ],
          Expanded(
            flex: 3,
            child: TacticalButton(
              label: locked ? 'drills_unlock'.tr() : 'drills_put_on_board'.tr(),
              icon: locked ? Icons.lock_outline : Icons.add_circle_outline,
              large: true,
              onTap: locked ? widget.onUpgrade : widget.onLoad,
            ),
          ),
        ],
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

  /// The sequence's sentences, one per beat, and the set-up line, so the
  /// board can say what the step it is showing is.
  final List<String> beats;
  final String? setup;
  const _BoardCard({required this.state, this.beats = const [], this.setup});

  @override
  Widget build(BuildContext context) {
    return Consumer<TacticsState>(
      builder: (context, s, _) {
        final steps = s.maxMoveSteps;
        return Column(
          children: [
            ClipRRect(
              borderRadius: T.brLg,
              // Drawn at the size the board is really drawn at, then scaled
              // as one picture. A token is a fixed size whatever box the
              // canvas is given, so a preview laid out small got full-size
              // players on a shrunken pitch — three of them covering the
              // centre circle. Scaling the finished board instead makes the
              // preview exactly the board, smaller.
              child: Center(
                child: SizedBox(
                  // Taller than it was: with the card gone this is the
                  // hero of the page, and the pitch gets the width the
                  // screen can give it.
                  height: MediaQuery.of(context).size.height * 0.42,
                  child: const FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: kBoardRefWidth,
                      height: kBoardRefHeight,
                      child:
                          IgnorePointer(child: TacticsCanvas(preview: true)),
                    ),
                  ),
                ),
              ),
            ),
            if (steps > 0) ...[
              const SizedBox(height: T.s4),
              _StepBar(state: s, steps: steps, at: s.atStep),
              // What this step is, in words, right under the picture of it.
              // The full list further down lights the same beat, but a coach
              // stepping the board should not have to scroll to read what
              // just happened.
              _BeatCaption(
                text: s.atStep == 0
                    ? setup
                    : (s.atStep - 1 < beats.length ? beats[s.atStep - 1] : null),
                label: s.atStep == 0 ? 'anim_setup'.tr() : null,
              ),
            ],
          ],
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
    // The setup frame shows the setup: where everybody stands, and nothing
    // about where they are going. The board draws every planned run at step
    // 0 — right for an author laying a drill out, wrong for a coach reading
    // one, who then meets nine arrows before a single thing has happened.
    // Done here rather than in the canvas so the board itself keeps the
    // behaviour its own learn page describes.
    //
    // After the frame, not during it: setShowMoveLines notifies, and
    // notifying a listener while it is building is how you get "setState()
    // called during build". It no-ops when the value is unchanged, so this
    // settles after one frame rather than looping.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => state.setShowMoveLines(at > 0));

    // The board's own numbering goes straight through: step 0 is the setup
    // and StepStrip names it rather than counting it.
    return StepStrip(
      index: at,
      beats: steps,
      onPrev: state.stepBackward,
      onNext: state.stepForward,
    );
  }
}

/// The sentence for the step the board is on, under the stepper.
class _BeatCaption extends StatelessWidget {
  final String? text;
  final String? label;
  const _BeatCaption({this.text, this.label});

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.isEmpty) return const SizedBox(height: T.s8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(T.s4, T.s8, T.s4, T.s4),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: SizedBox(
          key: ValueKey(text),
          width: double.infinity,
          child: Text(
            label != null ? '$label · $text' : text!,
            style: T.body,
          ),
        ),
      ),
    );
  }
}

/// Frequency, origin, setup: a heading and the standing fact under it.
///
/// This used to be a 10.5pt all-caps scrap over 14.5pt dim body, which read
/// as a form field rather than as something to read. Structure now comes from
/// the type scale.
class _InfoRow extends StatelessWidget {
  final DrillSection section;
  const _InfoRow({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: T.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.label != null) ...[
            SectionTitle(
                title: section.label!, icon: _sectionIcon(section.label!)),
            const SizedBox(height: T.s8),
          ],
          Text(section.body, style: T.body),
        ],
      ),
    );
  }
}

/// A small line icon per section, matched on the section's own label.
///
/// Matched on the CJK and English labels the generator writes; anything it
/// does not recognise gets no icon rather than a wrong one, which is why the
/// return type is nullable and [SectionTitle] treats null as "text only".
IconData? _sectionIcon(String label) {
  const table = <String, IconData>{
    '组织': Icons.groups_outlined,
    '組織': Icons.groups_outlined,
    'Setup': Icons.groups_outlined,
    '球路': Icons.sports_soccer_outlined,
    'Ball path': Icons.sports_soccer_outlined,
    '变化': Icons.shuffle_rounded,
    '變化': Icons.shuffle_rounded,
    'Variations': Icons.shuffle_rounded,
    '频度': Icons.repeat_rounded,
    '頻度': Icons.repeat_rounded,
    'Frequency': Icons.repeat_rounded,
    '教练提示': Icons.sports_outlined,
    '教練提示': Icons.sports_outlined,
    'Coaching point': Icons.sports_outlined,
    '顺序': Icons.format_list_numbered_rounded,
    '順序': Icons.format_list_numbered_rounded,
    'Sequence': Icons.format_list_numbered_rounded,
    '规则': Icons.rule_rounded,
    '規則': Icons.rule_rounded,
    'Rules': Icons.rule_rounded,
  };
  return table[label.trim()];
}

/// The ball path as the chain it is: 1 → 2 → 3 → goal.
class _RouteRow extends StatelessWidget {
  final DrillSection section;
  const _RouteRow({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: T.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.label != null) ...[
            SectionTitle(
                title: section.label!, icon: _sectionIcon(section.label!)),
            const SizedBox(height: T.s12),
          ],
          SequenceView(stops: section.stops),
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
          padding: const EdgeInsets.only(bottom: T.sectionGap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (section.label != null) ...[
                SectionTitle(
                    title: section.label!, icon: _sectionIcon(section.label!)),
                const SizedBox(height: T.s12),
              ],
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
                      fontSize: 16,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: T.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.label != null) ...[
            SectionTitle(
                title: section.label!, icon: _sectionIcon(section.label!)),
            const SizedBox(height: T.s8),
          ],
          // Set apart by a rule rather than by a tinted, outlined box: it is
          // the line a coach says out loud, not a warning.
          CoachNote(text: section.body),
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
