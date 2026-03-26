import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/player_icon.dart';
import '../models/drawing_stroke.dart';
import '../models/sport_formation.dart';
import '../models/sport_type.dart';
import '../painters/ball_painter.dart';
import '../state/tactics_state.dart';
import 'player_icon_widget.dart';

class TacticsToolbar extends StatelessWidget {
  const TacticsToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TacticsState>(
      builder: (context, state, _) {
        return Container(
          color: const Color(0xFF1E1E2E),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mode toggle row (includes Play/Stop button)
                _ModeToggleRow(state: state),
                const Divider(color: Colors.white24, height: 1),
                // Tool options (context-sensitive)
                if (state.isDrawingMode) _DrawingOptions(state: state),
                if (!state.isDrawingMode) _PlayerOptions(state: state),
                const Divider(color: Colors.white24, height: 1),
                // Action row
                _ActionRow(state: state),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModeToggleRow extends StatelessWidget {
  final TacticsState state;
  const _ModeToggleRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final maxSteps = state.maxMoveSteps;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text('${'mode_label'.tr()}:', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  _ModeButton(
                    label: 'mode_move'.tr(),
                    icon: Icons.open_with,
                    selected: !state.isDrawingMode,
                    onTap: state.isAnimating ? null : () => state.setDrawingMode(false),
                  ),
                  const SizedBox(width: 8),
                  _ModeButton(
                    label: 'mode_draw'.tr(),
                    icon: Icons.edit,
                    selected: state.isDrawingMode,
                    onTap: state.isAnimating ? null : () => state.setDrawingMode(true),
                  ),
                  // Step chips — only appear when moves exist
                  if (!state.isDrawingMode && maxSteps > 0) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                      height: 20,
                      child: VerticalDivider(color: Colors.white24, width: 1),
                    ),
                    const SizedBox(width: 8),
                    _StepChip(
                      label: 'All',
                      selected: state.targetStep == 0,
                      onTap: () => state.setTargetStep(0),
                    ),
                    ...List.generate(maxSteps, (i) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _StepChip(
                        label: '${i + 1}',
                        selected: state.targetStep == i + 1,
                        onTap: () => state.setTargetStep(i + 1),
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _PlayButton(state: state),
          const SizedBox(width: 6),
          _StepButton(state: state),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.blue : Colors.white10,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drawing Options
// ─────────────────────────────────────────────────────────────────────────────

class _DrawingOptions extends StatelessWidget {
  final TacticsState state;
  const _DrawingOptions({required this.state});

  static const _colors = [
    Color(0xFFFFD600), // yellow
    Colors.white,
    Color(0xFFE53935), // red
    Color(0xFF43A047), // green
    Color(0xFF1E88E5), // blue
    Color(0xFFFF6F00), // orange
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line style + arrow
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text('${"line_label".tr()}:', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                _ToggleChip(
                  label: 'line_solid'.tr(),
                  selected: state.strokeStyle == StrokeStyle.solid,
                  onTap: () => state.setStrokeStyle(StrokeStyle.solid),
                ),
                const SizedBox(width: 6),
                _ToggleChip(
                  label: 'line_dashed'.tr(),
                  selected: state.strokeStyle == StrokeStyle.dashed,
                  onTap: () => state.setStrokeStyle(StrokeStyle.dashed),
                ),
                const SizedBox(width: 16),
                Text('${"arrow_label".tr()}:', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                _ToggleChip(
                  label: 'arrow_none'.tr(),
                  selected: state.arrowStyle == ArrowStyle.none,
                  onTap: () => state.setArrowStyle(ArrowStyle.none),
                ),
                const SizedBox(width: 6),
                _ToggleChip(
                  label: '→',
                  selected: state.arrowStyle == ArrowStyle.end,
                  onTap: () => state.setArrowStyle(ArrowStyle.end),
                ),
                const SizedBox(width: 6),
                _ToggleChip(
                  label: '↔',
                  selected: state.arrowStyle == ArrowStyle.both,
                  onTap: () => state.setArrowStyle(ArrowStyle.both),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Color + width
          Row(
            children: [
              Text('${"color_label".tr()}:', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              ..._colors.map((c) => _ColorDot(
                    color: c,
                    selected: state.strokeColor == c,
                    onTap: () => state.setStrokeColor(c),
                  )),
              const SizedBox(width: 16),
              Text('${"width_label".tr()}:', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              Expanded(
                child: Slider(
                  value: state.strokeWidth,
                  min: 1,
                  max: 8,
                  divisions: 7,
                  activeColor: Colors.blue,
                  inactiveColor: Colors.white24,
                  onChanged: (v) => state.setStrokeWidth(v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
            width: selected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Player Options
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerOptions extends StatelessWidget {
  final TacticsState state;
  const _PlayerOptions({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text('${"add_player_label".tr()}:', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 10),
            _FormationButton(state: state),
            const SizedBox(width: 8),
            _AddPlayerButton(team: PlayerTeam.home, labelKey: 'team_home', state: state),
            const SizedBox(width: 8),
            _AddPlayerButton(team: PlayerTeam.away, labelKey: 'team_away', state: state),
            const SizedBox(width: 8),
            _AddPlayerButton(team: PlayerTeam.neutral, labelKey: 'team_ball', state: state, isCircle: true),
          ],
        ),
      ),
    );
  }
}

class _FormationButton extends StatelessWidget {
  final TacticsState state;
  const _FormationButton({required this.state});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFormationPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.7), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.groups, color: Color(0xFFCE93D8), size: 17),
            const SizedBox(width: 6),
            Text('formation_btn'.tr(),
                style: const TextStyle(color: Color(0xFFCE93D8), fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showFormationPicker(BuildContext context) {
    final formations = state.sportType.formations;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'formation_title'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
            ...formations.map((f) => _FormationTile(
                  formation: f,
                  onTap: () {
                    Navigator.pop(ctx);
                    _applyFormation(context, f);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _applyFormation(BuildContext context, SportFormation formation) {
    if (state.players.isNotEmpty) {
      showDialog(
        context: context,
        builder: (dCtx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: Text('formation_replace_title'.tr(),
              style: const TextStyle(color: Colors.white)),
          content: Text('formation_replace_message'.tr(),
              style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dCtx);
                state.applyFormation(formation);
              },
              child: Text('formation_apply'.tr(),
                  style: const TextStyle(color: Colors.purple)),
            ),
          ],
        ),
      );
    } else {
      state.applyFormation(formation);
    }
  }
}

class _FormationTile extends StatelessWidget {
  final SportFormation formation;
  final VoidCallback onTap;
  const _FormationTile({required this.formation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(
            '${formation.homeCount}v${formation.awayCount}',
            style: const TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
      title: Text(
        formation.nameKey.tr(),
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      subtitle: Text(
        '${'formation_home'.tr()} ${formation.homeCount}  ·  ${'formation_away'.tr()} ${formation.awayCount}',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      onTap: onTap,
    );
  }
}

class _AddPlayerButton extends StatelessWidget {
  final PlayerTeam team;
  final String labelKey;
  final TacticsState state;
  final bool isCircle;

  const _AddPlayerButton({
    required this.team,
    required this.labelKey,
    required this.state,
    this.isCircle = false,
  });

  int _nextNumber() {
    final same = state.players.where((p) => p.team == team).length;
    return same + 1;
  }

  @override
  Widget build(BuildContext context) {
    final color = PlayerIcon.teamColor(team);
    return GestureDetector(
      onTap: () {
        state.addPlayer(PlayerIcon(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          label: isCircle ? '' : '${_nextNumber()}',
          team: team,
          sportType: isCircle ? state.sportType : null,
          position: const Offset(200, 300),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: isCircle
                  ? ClipOval(
                      child: CustomPaint(
                        painter: BallPainter.forSport(state.sportType),
                      ),
                    )
                  : Stack(
                      children: [
                        CustomPaint(
                          painter: TopDownPlayerPainter(
                            color: color,
                            borderColor: Colors.white,
                            borderWidth: 1,
                          ),
                          size: const Size(22, 22),
                        ),
                        Align(
                          alignment: const Alignment(0, 0.35),
                          child: Text(
                            '${_nextNumber()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 6),
            Text(labelKey.tr(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Row
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final TacticsState state;
  const _ActionRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ActionBtn(
              icon: Icons.undo,
              label: 'undo'.tr(),
              enabled: state.canUndo,
              onTap: state.undo,
            ),
            const SizedBox(width: 8),
            _ActionBtn(
              icon: Icons.redo,
              label: 'redo'.tr(),
              enabled: state.canRedo,
              onTap: state.redo,
            ),
            const SizedBox(width: 16),
            _ActionBtn(
              icon: Icons.brush_outlined,
              label: 'clear_lines'.tr(),
              enabled: state.strokes.isNotEmpty,
              onTap: state.clearStrokes,
            ),
            const SizedBox(width: 8),
            _ActionBtn(
              icon: Icons.delete_sweep,
              label: 'clear_all'.tr(),
              enabled: state.players.isNotEmpty || state.strokes.isNotEmpty,
              onTap: () => _confirmClear(context, state),
              color: Colors.red,
            ),
            const SizedBox(width: 16),
            _ActionBtn(
              icon: Icons.ios_share,
              label: 'save_board'.tr(),
              enabled: true,
              onTap: () => _shareBoard(context),
              color: Colors.tealAccent,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareBoard(BuildContext context) async {
    final boundary =
        boardRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    try {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/tactics_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('save_error'.tr())),
        );
      }
    }
  }

  void _confirmClear(BuildContext context, TacticsState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text('clear_board_title'.tr(), style: const TextStyle(color: Colors.white)),
        content: Text(
          'clear_board_message'.tr(),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('cancel'.tr())),
          TextButton(
            onPressed: () {
              state.clearAll();
              Navigator.pop(ctx);
            },
            child: Text('clear'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final Color? color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Icon(icon, color: c, size: 17),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Play / Stop animation button
// ─────────────────────────────────────────────────────────────────────────────
class _PlayButton extends StatelessWidget {
  final TacticsState state;
  const _PlayButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final canPlay = state.hasMoves && !state.isAnimating;
    final isPlaying = state.isAnimating;

    return GestureDetector(
      onTap: isPlaying
          ? state.stopAnimation
          : canPlay
              ? state.startAnimation
              : null,
      child: Opacity(
        opacity: (!isPlaying && !canPlay) ? 0.35 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPlaying
                ? Colors.red.withValues(alpha: 0.2)
                : Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPlaying ? Colors.red : Colors.lightGreenAccent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isPlaying ? Icons.stop : Icons.play_arrow,
                color: isPlaying ? Colors.red : Colors.lightGreenAccent,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                isPlaying ? 'Stop' : 'Play',
                style: TextStyle(
                  color: isPlaying ? Colors.red : Colors.lightGreenAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step forward button
// ─────────────────────────────────────────────────────────────────────────────
class _StepButton extends StatelessWidget {
  final TacticsState state;
  const _StepButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final canStep = state.hasMoves && !state.isAnimating && state.atStep < state.maxMoveSteps;
    return GestureDetector(
      onTap: canStep ? state.stepForward : null,
      child: Opacity(
        opacity: canStep ? 1.0 : 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.skip_next, color: Colors.blue, size: 18),
              const SizedBox(width: 4),
              Text(
                '${state.atStep}/${state.maxMoveSteps}',
                style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StepChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.amber : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.amber : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
