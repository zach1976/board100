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
            minimum: const EdgeInsets.only(bottom: 4),
            child: _MainRow(state: state),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Single row: Mode + Add + Actions
          Row(
            children: [
              _ModeSegment(state: state),
              const SizedBox(width: 10),
              _AddPlayerBtn(state: state),
              const SizedBox(width: 10),
              if (state.selectedPlayerId != null) ...[
                _IconBtn(icon: Icons.delete, color: Colors.redAccent, onTap: () => state.removePlayer(state.selectedPlayerId!)),
                const SizedBox(width: 10),
              ],
              if (state.canUndo) ...[
                _IconBtn(icon: Icons.undo, onTap: state.undo),
                const SizedBox(width: 10),
              ],
              if (state.canRedo) ...[
                _IconBtn(icon: Icons.redo, onTap: state.redo),
                const SizedBox(width: 10),
              ],
              if (state.strokes.isNotEmpty) ...[
                _IconBtn(icon: Icons.brush_outlined, onTap: state.clearStrokes),
                const SizedBox(width: 10),
              ],
              const Spacer(),
              if (hasContent) ...[
                _IconBtn(icon: Icons.delete_sweep, onTap: () => _confirmClear(context, state), color: Colors.redAccent),
                const SizedBox(width: 10),
              ],
              _IconBtn(icon: Icons.ios_share, onTap: () => _shareBoard(context), color: Colors.tealAccent),
            ],
          ),
        ],
      ),
    );
  }


  Future<void> _shareBoard(BuildContext context) async {
    // Reset zoom so capture gets full unzoomed canvas
    state.resetZoom();
    await Future.delayed(const Duration(milliseconds: 100));

    final boundary =
        boardRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      debugPrint('Share: RepaintBoundary not found');
      return;
    }
    try {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tactics_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      debugPrint('Share error: $e');
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
          // Inline formation cards
          _QuickFormationRow(state: state, sheetCtx: sheetCtx),
          const Divider(color: Colors.white12),
          // Home team — gender & doubles
          _SectionHeader(label: 'team_home'.tr(), color: const Color(0xFF1565C0)),
          _PlayerAddRow(state: state, team: PlayerTeam.home, sheetCtx: sheetCtx),
          const SizedBox(height: 4),
          // Away team — gender & doubles
          _SectionHeader(label: 'team_away'.tr(), color: const Color(0xFFC62828)),
          _PlayerAddRow(state: state, team: PlayerTeam.away, sheetCtx: sheetCtx),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header for add-player sheet
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Row of add buttons: 男, 女, 男双, 女双, 混双
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerAddRow extends StatelessWidget {
  final TacticsState state;
  final PlayerTeam team;
  final BuildContext sheetCtx;
  const _PlayerAddRow({required this.state, required this.team, required this.sheetCtx});

  int get _nextNum => state.players.where((p) => p.team == team).length + 1;

  void _add(PlayerGender gender, {Offset offset = Offset.zero}) {
    final c = state.canvasSize;
    final n = _nextNum;
    final baseY = team == PlayerTeam.home ? c.height * 0.75 : c.height * 0.25;
    var pos = Offset(c.width * 0.5 + offset.dx, baseY + offset.dy);
    pos = _avoidOverlap(pos, c);
    state.addPlayer(PlayerIcon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: '$n',
      team: team,
      gender: gender,
      position: pos,
    ));
  }

  Offset _avoidOverlap(Offset pos, Size canvasSize) {
    const minDist = 48.0;
    var result = pos;
    for (int attempt = 0; attempt < 20; attempt++) {
      final overlap = state.players.any((p) => (p.position - result).distance < minDist);
      if (!overlap) return result;
      // Nudge right, then down, spiral out
      result = Offset(
        result.dx + 32 * ((attempt % 4 < 2) ? 1 : -1),
        result.dy + (attempt ~/ 2) * 20.0 * ((attempt % 2 == 0) ? 1 : -1),
      );
      // Clamp within canvas
      result = Offset(
        result.dx.clamp(24.0, canvasSize.width - 24.0),
        result.dy.clamp(24.0, canvasSize.height - 24.0),
      );
    }
    return result;
  }

  void _addPair(PlayerGender g1, PlayerGender g2) {
    _add(g1, offset: const Offset(-28, 0));
    _add(g2, offset: const Offset(28, 0));
    Navigator.pop(sheetCtx);
  }

  @override
  Widget build(BuildContext context) {
    final color = PlayerIcon.teamColor(team);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _PlayerCard(
              label: '男单',
              color: color,
              genders: const [PlayerGender.male],
              onTap: () { _add(PlayerGender.male); Navigator.pop(sheetCtx); },
            ),
            const SizedBox(width: 8),
            _PlayerCard(
              label: '女单',
              color: color,
              genders: const [PlayerGender.female],
              onTap: () { _add(PlayerGender.female); Navigator.pop(sheetCtx); },
            ),
            const SizedBox(width: 8),
            _PlayerCard(
              label: '男双',
              color: color,
              genders: const [PlayerGender.male, PlayerGender.male],
              onTap: () => _addPair(PlayerGender.male, PlayerGender.male),
            ),
            const SizedBox(width: 8),
            _PlayerCard(
              label: '女双',
              color: color,
              genders: const [PlayerGender.female, PlayerGender.female],
              onTap: () => _addPair(PlayerGender.female, PlayerGender.female),
            ),
            const SizedBox(width: 8),
            _PlayerCard(
              label: '混双',
              color: color,
              genders: const [PlayerGender.male, PlayerGender.female],
              onTap: () => _addPair(PlayerGender.male, PlayerGender.female),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String label;
  final Color color;
  final List<PlayerGender> genders;
  final VoidCallback onTap;
  const _PlayerCard({required this.label, required this.color, required this.genders, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double iconSize = genders.length > 1 ? 24.0 : 38.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: genders.map((g) => SizedBox(
                width: iconSize,
                height: iconSize,
                child: CustomPaint(
                  painter: TopDownPlayerPainter(
                    color: color,
                    borderColor: Colors.white,
                    borderWidth: 1.5,
                    gender: g,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick formation row — shown directly in add sheet
// ─────────────────────────────────────────────────────────────────────────────
class _QuickFormationRow extends StatelessWidget {
  final TacticsState state;
  final BuildContext sheetCtx;
  const _QuickFormationRow({required this.state, required this.sheetCtx});

  @override
  Widget build(BuildContext context) {
    final formations = state.sportType.formations;
    final hasDoubles = formations.any((f) => f.nameKey == 'formation_doubles');
    final homeColor = PlayerIcon.teamColor(PlayerTeam.home);
    final awayColor = PlayerIcon.teamColor(PlayerTeam.away);

    final cards = <Widget>[];
    for (final f in formations) {
      final homeDots = List.generate(f.homeCount, (_) => (homeColor, PlayerGender.unspecified));
      final awayDots = List.generate(f.awayCount, (_) => (awayColor, PlayerGender.unspecified));
      cards.add(_FormationCard(
        label: f.nameKey.tr(),
        homeDots: homeDots,
        awayDots: awayDots,
        onTap: () => _apply(context, f),
      ));
      cards.add(const SizedBox(width: 8));
    }
    if (hasDoubles) {
      final doubles = formations.firstWhere((f) => f.nameKey == 'formation_doubles');
      cards.add(_FormationCard(
        label: '混双',
        homeDots: [(homeColor, PlayerGender.male), (homeColor, PlayerGender.female)],
        awayDots: [(awayColor, PlayerGender.male), (awayColor, PlayerGender.female)],
        onTap: () => _apply(context, doubles,
          homeGenders: [PlayerGender.male, PlayerGender.female],
          awayGenders: [PlayerGender.male, PlayerGender.female]),
      ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: cards),
      ),
    );
  }

  void _apply(BuildContext context, SportFormation formation,
      {List<PlayerGender>? homeGenders, List<PlayerGender>? awayGenders}) {
    void doApply() {
      state.applyFormation(formation, homeGenders: homeGenders, awayGenders: awayGenders);
      Navigator.pop(sheetCtx);
    }
    if (state.players.isNotEmpty) {
      showDialog(
        context: context,
        builder: (dCtx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: Text('formation_replace_title'.tr(), style: const TextStyle(color: Colors.white)),
          content: Text('formation_replace_message'.tr(), style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: Text('cancel'.tr())),
            TextButton(
              onPressed: () { Navigator.pop(dCtx); doApply(); },
              child: Text('formation_apply'.tr(), style: const TextStyle(color: Colors.purple)),
            ),
          ],
        ),
      );
    } else {
      doApply();
    }
  }
}

class _FormationCard extends StatelessWidget {
  final String label;
  final List<(Color, PlayerGender)> homeDots;
  final List<(Color, PlayerGender)> awayDots;
  final VoidCallback onTap;
  const _FormationCard({required this.label, required this.homeDots, required this.awayDots, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._dots(homeDots),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text('vs', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ),
                ..._dots(awayDots),
              ],
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  List<Widget> _dots(List<(Color, PlayerGender)> dots) => dots.map((d) => Padding(
    padding: const EdgeInsets.only(right: 2),
    child: SizedBox(
      width: 22, height: 22,
      child: CustomPaint(
        painter: TopDownPlayerPainter(color: d.$1, borderColor: Colors.white, borderWidth: 1.5, gender: d.$2),
      ),
    ),
  )).toList();
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

class DrawingOptionsBar extends StatelessWidget {
  final TacticsState state;
  const DrawingOptionsBar({super.key, required this.state});

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
// Step controls — back, indicator, forward
// ─────────────────────────────────────────────────────────────────────────────

class _ResetButton extends StatelessWidget {
  final TacticsState state;
  const _ResetButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final canReset = !state.isAnimating && state.atStep > 0;
    return GestureDetector(
      onTap: canReset ? state.clearAnimatedPositions : null,
      child: Opacity(
        opacity: canReset ? 1.0 : 0.3,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.replay, color: Colors.orange, size: 18),
        ),
      ),
    );
  }
}

class _StepBackButton extends StatelessWidget {
  final TacticsState state;
  const _StepBackButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final canStep = !state.isAnimating && state.atStep > 0;
    return GestureDetector(
      onTap: canStep ? state.stepBackward : null,
      child: Opacity(
        opacity: canStep ? 1.0 : 0.3,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.skip_previous, color: Colors.blue, size: 18),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final TacticsState state;
  const _StepIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${state.atStep}/${state.maxMoveSteps}',
      style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w600),
    );
  }
}

class _StepForwardButton extends StatelessWidget {
  final TacticsState state;
  const _StepForwardButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final canStep = !state.isAnimating && state.atStep < state.maxMoveSteps;
    return GestureDetector(
      onTap: canStep ? state.stepForward : null,
      child: Opacity(
        opacity: canStep ? 1.0 : 0.3,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.skip_next, color: Colors.blue, size: 18),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Play controls bar — floating overlay on canvas
// ─────────────────────────────────────────────────────────────────────────────
class PlayControlsBar extends StatelessWidget {
  final TacticsState state;
  const PlayControlsBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xDD1E1E2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ResetButton(state: state),
          const SizedBox(width: 8),
          _StepBackButton(state: state),
          const SizedBox(width: 10),
          _StepIndicator(state: state),
          const SizedBox(width: 10),
          _StepForwardButton(state: state),
          const SizedBox(width: 12),
          _PlayButton(state: state),
        ],
      ),
    );
  }
}
