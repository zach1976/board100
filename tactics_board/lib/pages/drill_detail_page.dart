import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/drill.dart';
import '../models/drill_note.dart';
import '../models/sport_type.dart';
import '../state/tactics_state.dart';
import '../ui/primitives.dart';
import '../ui/tokens.dart';
import '../widgets/tactics_canvas.dart';

/// Everything a coach needs to decide whether to run this drill, on one page.
///
/// The library card can only ever be a headline: a name, a clamped note and
/// two numbers. What it cannot show is the board — and the board IS the
/// drill. So this page draws the real [TacticsCanvas] with the real drill
/// loaded and a stepper under it, then lays the note out as the sections the
/// generator wrote it in, with the sequence numbered so it can be read beat
/// for beat against that stepper.
///
/// The canvas runs on its own throwaway [TacticsState] (`preview: true`), so
/// walking through the steps here never touches whatever the coach has on
/// the live board behind the sheet.
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

  @override
  void initState() {
    super.initState();
    _preview = TacticsState(sportType: widget.sportType, preview: true)
      ..loadFromJson(Map<String, dynamic>.from(widget.drill.board));
  }

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.drill;
    final note = DrillNote.parse(d.localizedNote(widget.locale));
    final mistake = d.localizedMistake(widget.locale);
    return Scaffold(
      backgroundColor: T.bg0,
      body: SafeArea(
        child: Column(
          children: [
            _header(context, d),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    T.screenX, 0, T.screenX, T.s24),
                children: [
                  _BoardPreview(state: _preview),
                  const SizedBox(height: T.s16),
                  _facts(d),
                  const SizedBox(height: T.s16),
                  for (final s in note.sections) ...[
                    _Section(section: s),
                    const SizedBox(height: T.s12),
                  ],
                  if (mistake != null) _mistakeBlock(mistake),
                ],
              ),
            ),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Drill d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(T.s8, T.s8, T.screenX, T.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TacticalIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: T.s4),
          Expanded(
            child: Text(
              d.localizedName(widget.locale),
              style: const TextStyle(
                  color: T.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _facts(Drill d) {
    return Wrap(
      spacing: T.s8,
      runSpacing: T.s8,
      children: [
        _Pill(icon: Icons.schedule_outlined,
            text: 'drills_minutes'.tr(args: ['${d.minutes}'])),
        _Pill(icon: Icons.groups_outlined, text: '${d.players}'),
        _Pill(text: d.category
            .labelKeyFor(widget.sportType.drillVocabulary)
            .tr()),
        _Pill(text: d.level.labelKey.tr()),
      ],
    );
  }

  Widget _mistakeBlock(String mistake) {
    return Container(
      padding: const EdgeInsets.all(T.s12),
      decoration: BoxDecoration(
        color: T.warning.withValues(alpha: 0.10),
        borderRadius: T.brMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.warning_amber_rounded,
                size: 16, color: T.warning),
          ),
          const SizedBox(width: T.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('drills_common_mistake'.tr(),
                    style: TextStyle(
                        color: T.warning.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6)),
                const SizedBox(height: 3),
                Text(mistake,
                    style: const TextStyle(
                        color: T.text, fontSize: 14, height: 1.45)),
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
          label: locked
              ? 'drills_unlock'.tr()
              : 'drills_put_on_board'.tr(),
          icon: locked ? Icons.lock_outline : Icons.add_circle_outline,
          onTap: locked ? widget.onUpgrade : widget.onLoad,
        ),
      ),
    );
  }
}

/// The drill on the real canvas, with the stepper that walks it.
///
/// Sized to the board's own aspect ratio so the shapes are the shapes a coach
/// will see when they load it — a preview at some other proportion is a
/// different diagram. Pointer events are swallowed: this is a picture you
/// step through, not a board you edit.
class _BoardPreview extends StatelessWidget {
  final TacticsState state;
  const _BoardPreview({required this.state});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TacticsState>.value(
      value: state,
      child: Consumer<TacticsState>(
        builder: (context, s, _) {
          final steps = s.maxMoveSteps;
          return Column(
            children: [
              ClipRRect(
                borderRadius: T.brMd,
                child: AspectRatio(
                  aspectRatio: 402 / 730,
                  // The canvas takes its own size from the box it is given.
                  child: const IgnorePointer(
                      child: TacticsCanvas(preview: true)),
                ),
              ),
              if (steps > 0) ...[
                const SizedBox(height: T.s8),
                _Stepper(state: s, steps: steps),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final TacticsState state;
  final int steps;
  const _Stepper({required this.state, required this.steps});

  @override
  Widget build(BuildContext context) {
    final at = state.atStep;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TacticalIconButton(
          icon: Icons.chevron_left,
          onTap: at > 0 ? state.stepBackward : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: T.s12),
          child: Text(
            '$at/$steps',
            style: const TextStyle(
                color: T.textDim,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()]),
          ),
        ),
        TacticalIconButton(
          icon: Icons.chevron_right,
          onTap: at < steps ? state.stepForward : null,
        ),
      ],
    );
  }
}

/// One labelled block of the note. The sequence gets numbered rows so it can
/// be read beat for beat against the stepper above; everything else is a
/// paragraph, which is what it is.
class _Section extends StatelessWidget {
  final DrillSection section;
  const _Section({required this.section});

  @override
  Widget build(BuildContext context) {
    final beats = section.beats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.label != null) ...[
          Text(
            section.label!,
            style: const TextStyle(
                color: T.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 5),
        ],
        if (beats.isEmpty)
          Text(section.body,
              style: const TextStyle(
                  color: T.text, fontSize: 15, height: 1.5))
        else
          for (var i = 0; i < beats.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == beats.length - 1 ? 0 : 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 2),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: T.surfaceHi, shape: BoxShape.circle),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: T.textDim,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: T.s8),
                  Expanded(
                    child: Text(beats[i],
                        style: const TextStyle(
                            color: T.text, fontSize: 15, height: 1.45)),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData? icon;
  final String text;
  const _Pill({this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(color: T.surface, borderRadius: T.brSm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: T.textDim),
            const SizedBox(width: 5),
          ],
          Text(text,
              style: const TextStyle(color: T.textDim, fontSize: 12.5)),
        ],
      ),
    );
  }
}
