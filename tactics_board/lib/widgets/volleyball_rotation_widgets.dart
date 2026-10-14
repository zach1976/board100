import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/player_icon.dart';
import '../models/volleyball_rotation.dart';
import '../state/tactics_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Volleyball rotations: the controls in the Add sheet, and the overlap
// faults drawn on the board. The rules themselves are in
// models/volleyball_rotation.dart.
// ─────────────────────────────────────────────────────────────────────────────

/// The overlap faults, drawn on the board: a red line between the feet of
/// each pair at fault, a red ring at each one's feet, and one line saying
/// what is wrong, in the other half where it covers nobody in the rotation. Painted in the board's
/// coordinates; [counterTurns] keeps the words upright on a turned board.
class RotationFaultPainter extends CustomPainter {
  /// One (feet of a, feet of b) per fault.
  final List<(Offset, Offset)> pairs;
  final String message;
  final Offset messageAt;
  final int counterTurns;
  final double figureScale;
  final String? fontFamily;

  const RotationFaultPainter({
    required this.pairs,
    required this.message,
    required this.messageAt,
    this.counterTurns = 0,
    this.figureScale = 1.0,
    this.fontFamily,
  });

  static const Color faultRed = Color(0xFFFF3B30);

  @override
  void paint(Canvas canvas, Size size) {
    final k = figureScale;
    final line = Paint()
      ..color = faultRed
      ..strokeWidth = 3 * k
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final halo = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 6 * k
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final (a, b) in pairs) {
      canvas.drawLine(a, b, halo);
      canvas.drawLine(a, b, line);
      for (final p in [a, b]) {
        final r = Rect.fromCenter(center: p, width: 30 * k, height: 12 * k);
        canvas.drawOval(r, halo..strokeWidth = 5 * k);
        canvas.drawOval(r, line..strokeWidth = 2.5 * k);
      }
      halo.strokeWidth = 6 * k;
      line.strokeWidth = 3 * k;
    }
    if (message.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(
        text: message,
        style: TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 12 * math.max(1.0, k * 0.9),
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: math.max(120.0, size.width * 0.8));
    canvas.save();
    canvas.translate(messageAt.dx, messageAt.dy);
    canvas.rotate(counterTurns * math.pi / 2);
    final box = Rect.fromCenter(
        center: Offset.zero, width: tp.width + 20, height: tp.height + 10);
    canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(10)),
        Paint()..color = faultRed.withValues(alpha: 0.92));
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(RotationFaultPainter old) =>
      old.message != message ||
      old.messageAt != messageAt ||
      old.counterTurns != counterTurns ||
      old.figureScale != figureScale ||
      old.pairs.length != pairs.length ||
      [
        for (var i = 0; i < pairs.length; i++)
          old.pairs[i] != pairs[i]
      ].any((d) => d);
}

/// Where the player being dragged may legally stand (see
/// TacticsState.rotationLegalArea): a translucent green patch on the court
/// with a thin border — red while his feet are outside it. Painted in the
/// board's coordinates, under the people. Nothing when [rect] is inverted,
/// which is the others being at fault among themselves.
class RotationLegalAreaPainter extends CustomPainter {
  final Rect rect;
  final bool inside;
  final double figureScale;

  const RotationLegalAreaPainter({
    required this.rect,
    required this.inside,
    this.figureScale = 1.0,
  });

  static const Color legalGreen = Color(0xFF4ADE80);

  @override
  void paint(Canvas canvas, Size size) {
    if (rect.isEmpty) return;
    canvas.drawRect(
        rect, Paint()..color = legalGreen.withValues(alpha: 0.22));
    canvas.drawRect(
        rect,
        Paint()
          ..color = inside ? legalGreen : RotationFaultPainter.faultRed
          ..strokeWidth = 1.5 * figureScale
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(RotationLegalAreaPainter old) =>
      old.rect != rect ||
      old.inside != inside ||
      old.figureScale != figureScale;
}

/// What the board says about [faults]: the first, in words, and how many
/// more. [labelOf] names a player by id.
String rotationFaultMessage(
    List<RotationFault> faults, String Function(String id) labelOf) {
  if (faults.isEmpty) return '';
  final f = faults.first;
  final args = {'a': labelOf(f.a), 'b': labelOf(f.b)};
  final first = f.fault.depth
      ? 'rotation_overlap_depth'.tr(namedArgs: args)
      : 'rotation_overlap_side'.tr(namedArgs: args);
  return faults.length == 1
      ? first
      : '$first  ${'rotation_overlap_more'.tr(namedArgs: {'n': '${faults.length - 1}'})}';
}

/// The rotation controls: system, receiving or serving, rotation 1–6 with
/// a step forward and back, libero, overlap check — and a small court
/// showing who is in which zone. Until the board has a rotation they edit
/// a draft that [onPlace] puts on it; after that every tap re-places the
/// side at once.
class VolleyballRotationControls extends StatefulWidget {
  final TacticsState state;
  final PlayerTeam team;
  final VoidCallback onPlace;
  const VolleyballRotationControls({
    super.key,
    required this.state,
    required this.onPlace,
    this.team = PlayerTeam.home,
  });

  @override
  State<VolleyballRotationControls> createState() =>
      _VolleyballRotationControlsState();
}

class _VolleyballRotationControlsState
    extends State<VolleyballRotationControls> {
  late RotationSetup _draft = RotationSetup(team: widget.team);

  RotationSetup get _current => widget.state.rotation ?? _draft;
  bool get _live => widget.state.rotation != null;

  void _set(RotationSetup s) {
    if (_live) {
      widget.state.applyRotation(s);
    } else {
      setState(() => _draft = s);
    }
  }

  /// Down the screen in the board's coordinates: the board is turned a
  /// quarter in landscape (home_page.dart), so the feet are then to the
  /// right of the figure's point.
  Offset _footward(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape
          ? const Offset(1, 0)
          : const Offset(0, 1);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final s = _current;
        final setterZone = s.zoneOf(s.activeSetter)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Segmented(
                  options: const ['5-1', '6-2'],
                  selected: s.system == RotationSystem.fiveOne ? 0 : 1,
                  onSelect: (i) => _set(s.copyWith(
                      system: i == 0
                          ? RotationSystem.fiveOne
                          : RotationSystem.sixTwo)),
                ),
                _Segmented(
                  options: [
                    'rotation_receive'.tr(),
                    'rotation_serve'.tr(),
                  ],
                  selected: s.phase == RotationPhase.receive ? 0 : 1,
                  onSelect: (i) => _set(s.copyWith(
                      phase: i == 0
                          ? RotationPhase.receive
                          : RotationPhase.serve)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StepButton(
                  key: const ValueKey('rotation-back'),
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'rotation_back'.tr(),
                  onTap: () => _set(s.rotated(-1)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'rotation_number'
                            .tr(namedArgs: {'n': '${s.rotation}'}),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'rotation_setter_zone'
                            .tr(namedArgs: {'z': '$setterZone'}),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _StepButton(
                  key: const ValueKey('rotation-forward'),
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'rotation_forward'.tr(),
                  onTap: () => _set(s.rotated(1)),
                ),
                const SizedBox(width: 10),
                _ZoneDiagram(setup: s),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Segmented(
                  key: const ValueKey('rotation-rules'),
                  options: [for (final r in RotationRules.values) r.label],
                  selected: s.rules.index,
                  onSelect: (i) =>
                      _set(s.copyWith(rules: RotationRules.values[i])),
                ),
                Text(
                  'rotation_subs'
                      .tr(namedArgs: {'n': '${s.rules.substitutions}'}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Toggle(
                  label: 'rotation_libero'.tr(),
                  on: s.libero,
                  onTap: () => _set(s.copyWith(libero: !s.libero)),
                ),
                _Toggle(
                  label: 'rotation_check'.tr(),
                  on: s.check,
                  onTap: () {
                    if (_live) {
                      widget.state.setRotationCheck(!s.check);
                    } else {
                      setState(() => _draft = s.copyWith(check: !s.check));
                    }
                  },
                ),
                if (_live &&
                    widget.state
                        .rotationFaults(footward: _footward(context))
                        .isNotEmpty)
                  GestureDetector(
                    key: const ValueKey('rotation-fix'),
                    onTap: () => widget.state
                        .legalizeRotation(footward: _footward(context)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: RotationFaultPainter.faultRed
                            .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: RotationFaultPainter.faultRed),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_fix_high_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'rotation_fix'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_live)
                  GestureDetector(
                    key: const ValueKey('rotation-place'),
                    onTap: () {
                      widget.state.applyRotation(_draft);
                      widget.onPlace();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF4ADE80)),
                      ),
                      child: Text(
                        'rotation_place'.tr(),
                        style: const TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;
  const _Segmented(
      {super.key,
      required this.options,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++)
            Flexible(
              fit: FlexFit.loose,
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: i == selected ? Colors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    options[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: i == selected ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _StepButton(
      {super.key, required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Toggle({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: on ? Colors.blue.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: on ? Colors.blue : Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(on ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 16, color: on ? Colors.white : Colors.white54),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: on ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A thumbnail of the side's half, net at the top: who is in each zone this
/// rotation, the setter in blue, the libero in his own colour, the server
/// with a ball.
class _ZoneDiagram extends StatelessWidget {
  final RotationSetup setup;
  const _ZoneDiagram({required this.setup});

  @override
  Widget build(BuildContext context) {
    final roles = setup.zoneRoles;
    Widget cell(int z) {
      final role = roles[z]!;
      final setter = role == setup.activeSetter;
      final libero = role == VolleyballRotation.liberoRole;
      final serving = setup.phase == RotationPhase.serve && z == 1;
      return Container(
        width: 30,
        height: 22,
        margin: const EdgeInsets.all(1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: libero
              ? TacticsState.kLiberoColor.withValues(alpha: 0.85)
              : setter
                  ? Colors.blue
                  : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(4),
          border: serving ? Border.all(color: Colors.amberAccent, width: 1.5) : null,
        ),
        child: Text(
          VolleyballRotation.displayLabel(role),
          style: TextStyle(
            color: libero ? Colors.black : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
      decoration: BoxDecoration(
        border: const Border(
          top: BorderSide(color: Color(0xFFFFEB3B), width: 2),
        ),
        color: const Color(0xFF2A5FA0).withValues(alpha: 0.6),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [cell(4), cell(3), cell(2)]),
          Row(mainAxisSize: MainAxisSize.min, children: [cell(5), cell(6), cell(1)]),
        ],
      ),
    );
  }
}
