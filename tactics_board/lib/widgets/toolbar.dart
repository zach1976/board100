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
                _MainRow(state: state),
                if (state.isDrawingMode) ...[
                  const Divider(color: Colors.white24, height: 1),
                  _DrawingOptionsRow(state: state),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Row — always visible, single row
// ─────────────────────────────────────────────────────────────────────────────

class _MainRow extends StatelessWidget {
  final TacticsState state;
  const _MainRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasMoves = state.hasMoves;
    final hasContent = state.players.isNotEmpty || state.strokes.isNotEmpty;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Mode segment
          _ModeSegment(state: state),

          // Add player button — move mode only
          if (!state.isDrawingMode) ...[
            const SizedBox(width: 10),
            _AddPlayerBtn(state: state),
          ],

          const SizedBox(width: 12),

          // Play + Step — only when moves exist in move mode
          if (!state.isDrawingMode && hasMoves) ...[
            _PlayButton(state: state),
            const SizedBox(width: 6),
            _StepButton(state: state),
            const SizedBox(width: 8),
            const SizedBox(height: 20, child: VerticalDivider(color: Colors.white24, width: 1)),
            const SizedBox(width: 8),
          ],

          // Delete selected player
          if (state.selectedPlayerId != null) ...[
            _IconBtn(
              icon: Icons.delete,
              color: Colors.redAccent,
              onTap: () => state.removePlayer(state.selectedPlayerId!),
            ),
            const SizedBox(width: 8),
          ],

          // Action icons — only shown when applicable
          if (state.canUndo) ...[
            _IconBtn(icon: Icons.undo, onTap: state.undo),
            const SizedBox(width: 8),
          ],
          if (state.canRedo) ...[
            _IconBtn(icon: Icons.redo, onTap: state.redo),
            const SizedBox(width: 8),
          ],
          if (state.strokes.isNotEmpty) ...[
            _IconBtn(icon: Icons.brush_outlined, onTap: state.clearStrokes),
            const SizedBox(width: 8),
          ],
          if (hasContent) ...[
            _IconBtn(icon: Icons.delete_sweep, onTap: () => _confirmClear(context, state), color: Colors.redAccent),
            const SizedBox(width: 8),
          ],

          // Share — always visible
          _IconBtn(icon: Icons.ios_share, onTap: () => _shareBoard(context), color: Colors.tealAccent),
        ],
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
      final file = File('${dir.path}/tactics_${DateTime.now().millisecondsSinceEpoch}.png');
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
        content: Text('clear_board_message'.tr(), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Mode Segment — compact pill with 移动 / 画线
// ─────────────────────────────────────────────────────────────────────────────

class _ModeSegment extends StatelessWidget {
  final TacticsState state;
  const _ModeSegment({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegTab(
            icon: Icons.open_with,
            label: 'mode_move'.tr(),
            selected: !state.isDrawingMode,
            onTap: state.isAnimating ? null : () => state.setDrawingMode(false),
          ),
          _SegTab(
            icon: Icons.edit,
            label: 'mode_draw'.tr(),
            selected: state.isDrawingMode,
            onTap: state.isAnimating ? null : () => state.setDrawingMode(true),
          ),
        ],
      ),
    );
  }
}

class _SegTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _SegTab({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1.0,
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 15),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Player Button — opens bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddPlayerBtn extends StatelessWidget {
  final TacticsState state;
  const _AddPlayerBtn({required this.state});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 15),
            const SizedBox(width: 4),
            Text('add_player_label'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddPlayerSheet(state: state, sheetCtx: ctx),
    );
  }
}

class _AddPlayerSheet extends StatelessWidget {
  final TacticsState state;
  final BuildContext sheetCtx;
  const _AddPlayerSheet({required this.state, required this.sheetCtx});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              'add_player_label'.tr(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
          const Divider(color: Colors.white12),
          // Formation
          _SheetTile(
            icon: Icons.groups,
            iconColor: const Color(0xFFCE93D8),
            bgColor: Colors.purple.withValues(alpha: 0.15),
            label: 'formation_btn'.tr(),
            subtitle: 'formation_title'.tr(),
            onTap: () {
              Navigator.pop(sheetCtx);
              _showFormationPicker(context);
            },
          ),
          // Home team
          _SheetTile(
            iconWidget: _PlayerDot(team: PlayerTeam.home, sportType: state.sportType, number: _nextNum(PlayerTeam.home)),
            label: 'team_home'.tr(),
            onTap: () {
              final c = state.canvasSize;
              state.addPlayer(PlayerIcon(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                label: '${_nextNum(PlayerTeam.home)}',
                team: PlayerTeam.home,
                position: Offset(c.width * 0.5, c.height * 0.5),
              ));
              Navigator.pop(sheetCtx);
            },
          ),
          // Away team
          _SheetTile(
            iconWidget: _PlayerDot(team: PlayerTeam.away, sportType: state.sportType, number: _nextNum(PlayerTeam.away)),
            label: 'team_away'.tr(),
            onTap: () {
              final c = state.canvasSize;
              state.addPlayer(PlayerIcon(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                label: '${_nextNum(PlayerTeam.away)}',
                team: PlayerTeam.away,
                position: Offset(c.width * 0.5, c.height * 0.5),
              ));
              Navigator.pop(sheetCtx);
            },
          ),
          // Ball
          _SheetTile(
            iconWidget: ClipOval(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CustomPaint(painter: BallPainter.forSport(state.sportType)),
              ),
            ),
            label: 'team_ball'.tr(),
            onTap: () {
              final c = state.canvasSize;
              state.addPlayer(PlayerIcon(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                label: '',
                team: PlayerTeam.neutral,
                sportType: state.sportType,
                position: Offset(c.width * 0.5, c.height * 0.5),
              ));
              Navigator.pop(sheetCtx);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  int _nextNum(PlayerTeam team) => state.players.where((p) => p.team == team).length + 1;

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
              child: Text('formation_title'.tr(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
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
          title: Text('formation_replace_title'.tr(), style: const TextStyle(color: Colors.white)),
          content: Text('formation_replace_message'.tr(), style: const TextStyle(color: Colors.white70)),
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
              child: Text('formation_apply'.tr(), style: const TextStyle(color: Colors.purple)),
            ),
          ],
        ),
      );
    } else {
      state.applyFormation(formation);
    }
  }
}

class _SheetTile extends StatelessWidget {
  final Widget? iconWidget;
  final IconData? icon;
  final Color? iconColor;
  final Color? bgColor;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _SheetTile({
    this.iconWidget,
    this.icon,
    this.iconColor,
    this.bgColor,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final leading = iconWidget ??
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? Colors.white, size: 22),
        );

    return ListTile(
      leading: SizedBox(width: 40, height: 40, child: leading),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: Colors.white54, fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      onTap: onTap,
    );
  }
}

// Small circular player preview for the sheet
class _PlayerDot extends StatelessWidget {
  final PlayerTeam team;
  final SportType sportType;
  final int number;
  const _PlayerDot({required this.team, required this.sportType, required this.number});

  @override
  Widget build(BuildContext context) {
    final color = PlayerIcon.teamColor(team);
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        children: [
          CustomPaint(
            painter: TopDownPlayerPainter(color: color, borderColor: Colors.white, borderWidth: 1.5),
            size: const Size(36, 36),
          ),
          Align(
            alignment: const Alignment(0, 0.3),
            child: Text(
              '$number',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drawing Options Row — single compact row (draw mode only)
// ─────────────────────────────────────────────────────────────────────────────

class _DrawingOptionsRow extends StatelessWidget {
  final TacticsState state;
  const _DrawingOptionsRow({required this.state});

  static const _colors = [
    Color(0xFFFFD600),
    Colors.white,
    Color(0xFFE53935),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFFFF6F00),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: line style + arrow
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
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
                const SizedBox(width: 14),
                const SizedBox(height: 18, child: VerticalDivider(color: Colors.white24, width: 1)),
                const SizedBox(width: 14),
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
        ),
        // Row 2: color dots + width slider
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              ..._colors.map((c) => _ColorDot(
                    color: c,
                    selected: state.strokeColor == c,
                    onTap: () => state.setStrokeColor(c),
                  )),
              const SizedBox(width: 8),
              const SizedBox(height: 18, child: VerticalDivider(color: Colors.white24, width: 1)),
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
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

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

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
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

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _IconBtn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color ?? Colors.white70, size: 21),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formation Tile
// ─────────────────────────────────────────────────────────────────────────────

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
            style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
      title: Text(formation.nameKey.tr(), style: const TextStyle(color: Colors.white, fontSize: 15)),
      subtitle: Text(
        '${'formation_home'.tr()} ${formation.homeCount}  ·  ${'formation_away'.tr()} ${formation.awayCount}',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Play / Stop button
// ─────────────────────────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  final TacticsState state;
  const _PlayButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final isPlaying = state.isAnimating;
    final canPlay = state.hasMoves && !isPlaying;

    return GestureDetector(
      onTap: isPlaying ? state.stopAnimation : canPlay ? state.startAnimation : null,
      child: Opacity(
        opacity: (!isPlaying && !canPlay) ? 0.35 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPlaying ? Colors.red.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isPlaying ? Colors.red : Colors.lightGreenAccent, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(isPlaying ? Icons.stop : Icons.play_arrow,
                  color: isPlaying ? Colors.red : Colors.lightGreenAccent, size: 18),
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
