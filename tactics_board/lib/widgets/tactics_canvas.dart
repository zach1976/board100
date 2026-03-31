import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sport_type.dart';
import '../models/player_icon.dart';
import '../painters/drawing_painter.dart';
import '../painters/player_moves_painter.dart';
import '../painters/badminton_court_painter.dart';
import '../painters/basketball_court_painter.dart';
import '../painters/tennis_court_painter.dart';
import '../painters/table_tennis_court_painter.dart';
import '../painters/volleyball_court_painter.dart';
import '../painters/pickleball_court_painter.dart';
import '../painters/soccer_court_painter.dart';
import '../state/tactics_state.dart';
import 'player_icon_widget.dart';

class TacticsCanvas extends StatefulWidget {
  const TacticsCanvas({super.key});

  @override
  State<TacticsCanvas> createState() => _TacticsCanvasState();
}

class _TacticsCanvasState extends State<TacticsCanvas> {
  TacticsState? _stateOrNull;
  TacticsState get _state => _stateOrNull!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stateOrNull = context.read<TacticsState>();
      _state.addListener(_rebuild);
      _rebuild();
    });
  }

  @override
  void dispose() {
    _state.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  CustomPainter _courtPainter(SportType sport) {
    switch (sport) {
      case SportType.badminton:
        return const BadmintonCourtPainter();
      case SportType.basketball:
        return const BasketballCourtPainter();
      case SportType.tennis:
        return const TennisCourtPainter();
      case SportType.tableTennis:
        return const TableTennisCourtPainter();
      case SportType.volleyball:
        return const VolleyballCourtPainter();
      case SportType.pickleball:
        return const PickleballCourtPainter();
      case SportType.soccer:
        return const SoccerCourtPainter();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stateOrNull == null) return const SizedBox.expand();
    final state = _state;
    return LayoutBuilder(
      builder: (context, constraints) {
            final newSize = Size(constraints.maxWidth, constraints.maxHeight);
            if (state.canvasSize != newSize) {
              state.setCanvasSizeSilent(newSize);
            }

            final players = state.players.toList();

            return GestureDetector(
              onPanStart: state.isDrawingMode
                  ? (d) => state.startStroke(d.localPosition)
                  : null,
              onPanUpdate: state.isDrawingMode
                  ? (d) => state.addPoint(d.localPosition)
                  : null,
              onPanEnd: state.isDrawingMode ? (_) => state.endStroke() : null,
              onTapUp: (!state.isDrawingMode && !state.isAnimating)
                  ? (d) {
                      if (state.selectedPlayerId != null) {
                        state.addPlayerMove(
                            state.selectedPlayerId!, d.localPosition);
                      }
                    }
                  : null,
              child: RepaintBoundary(
                key: boardRepaintKey,
                child: Stack(
                children: [
                  // Court background
                  CustomPaint(
                    painter: _courtPainter(state.sportType),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    ),
                  ),
                  // Player move arrows (below players, limited to atStep)
                  if (state.showMoveLines)
                    CustomPaint(
                      painter: PlayerMovesPainter(
                        players: players,
                        targetStep: state.atStep > 0 ? state.atStep : state.targetStep,
                        completedSteps: state.isAnimating ? state.atStep : null,
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                  // Drawing layer
                  CustomPaint(
                    painter: DrawingPainter(
                      strokes: state.strokes,
                      currentStroke: state.currentStroke,
                    ),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                  // Waypoint dots (hidden during animation, limited to atStep/targetStep)
                  if (!state.isDrawingMode && !state.isAnimating && state.showMoveLines)
                    ...players.expand((player) {
                      final limit = state.atStep > 0 ? state.atStep : (state.targetStep > 0 ? state.targetStep : 0);
                      final visibleMoves = limit > 0
                          ? player.moves.take(limit).toList()
                          : player.moves;
                      return visibleMoves.asMap().entries.map((entry) {
                        final isLast = entry.key == visibleMoves.length - 1;
                        return _WaypointDot(
                          key: ValueKey('wp_${player.id}_${entry.key}'),
                          player: player,
                          index: entry.key,
                          position: entry.value,
                          isLast: isLast,
                          onLongPress: isLast
                              ? () => _showEditDialog(context, state, player)
                              : null,
                        );
                      });
                    }),
                  // Ghost icons at initial positions for players with moves
                  if (!state.isDrawingMode && state.showMoveLines)
                    ...players.where((p) => p.moves.isNotEmpty).map((player) {
                      final size = kPlayerIconSize * player.scale;
                      return Positioned(
                        key: ValueKey('ghost_${player.id}'),
                        left: player.position.dx - size / 2,
                        top: player.position.dy - size / 2,
                        child: SizedBox(
                          width: size,
                          height: size,
                          child: CustomPaint(
                            painter: TopDownPlayerPainter(
                              color: player.color,
                              borderColor: Colors.white,
                              borderWidth: 1.5,
                              gender: player.gender,
                              isGhost: true,
                            ),
                          ),
                        ),
                      );
                    }),
                  // Player icons (rendered above waypoints)
                  ...players.map((player) {
                    final animPos = state.animatedPositions[player.id];
                    return _PlayerOnBoard(
                      key: ValueKey(player.id),
                      player: player,
                      renderPosition: animPos,
                      isSelected: state.selectedPlayerId == player.id,
                      isDrawingMode: state.isDrawingMode || state.isAnimating,
                      onTap: () => state.selectPlayer(
                        state.selectedPlayerId == player.id ? null : player.id,
                      ),
                      onLongPress: () =>
                          _showEditDialog(context, state, player),
                    );
                  }),
                  // Animation driver (zero-size, drives per-frame updates)
                  _AnimationDriver(
                    isAnimating: state.isAnimating,
                    players: players,
                    targetStep: state.targetStep,
                    fromStep: state.animFromStep,
                    toStep: state.animToStep,
                    sequentialMode: state.sequentialMode,
                  ),
                ],
                ),
              ),
            );
      },
    );
  }

  void _showEditDialog(
      BuildContext context, TacticsState state, PlayerIcon player) {
    showDialog(
      context: context,
      builder: (ctx) => _PlayerEditDialog(state: state, player: player),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animation driver — zero-size, drives step-by-step move animation
// ─────────────────────────────────────────────────────────────────────────────
class _AnimationDriver extends StatefulWidget {
  final bool isAnimating;
  final List<PlayerIcon> players;
  final int targetStep; // 0 = all
  final int fromStep;
  final int toStep; // 0 = play all from fromStep
  final bool sequentialMode;

  const _AnimationDriver({
    required this.isAnimating,
    required this.players,
    required this.targetStep,
    this.fromStep = 0,
    this.toStep = 0,
    this.sequentialMode = false,
  });

  @override
  State<_AnimationDriver> createState() => _AnimationDriverState();
}

class _AnimationDriverState extends State<_AnimationDriver>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final CurvedAnimation _curved;
  int _step = 0;
  int _totalSteps = 0;
  bool _isBackward = false;
  // Sequential mode: which player index is currently animating
  bool _singleStep = false; // true = only animate one phase then stop

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.addListener(_onTick);
    _ctrl.addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(_AnimationDriver old) {
    super.didUpdateWidget(old);
    if (widget.isAnimating && !old.isAnimating) {
      _buildPhaseGroups();
      _isBackward = widget.toStep < widget.fromStep;
      // Single step if toStep is exactly 1 away from fromStep
      _singleStep = (widget.toStep - widget.fromStep).abs() == 1;

      if (_sortedPhases.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => context.read<TacticsState>().finishAnimation());
        return;
      }

      if (_isBackward) {
        _phaseIdx = (widget.fromStep - 1).clamp(0, _sortedPhases.length - 1);
        _ctrl.forward(from: 0);
      } else if (widget.fromStep == 0 && widget.toStep == 0) {
        // Play all
        _phaseIdx = 0;
        _ctrl.forward(from: 0);
      } else {
        // Step forward (single or range)
        _phaseIdx = widget.fromStep.clamp(0, _sortedPhases.length - 1);
        if (_phaseIdx < _sortedPhases.length) {
          _ctrl.forward(from: 0);
        } else {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => context.read<TacticsState>().finishAnimation());
        }
      }
    } else if (!widget.isAnimating && old.isAnimating) {
      _ctrl.stop();
      _phaseIdx = 0;
      _singleStep = false;
      _isBackward = false;
    }
  }

  // Phase-based animation: collect all (player, moveIndex) grouped by phase
  List<int> _sortedPhases = [];
  Map<int, List<({PlayerIcon player, int moveIdx})>> _phaseGroups = {};
  int _phaseIdx = 0;

  void _buildPhaseGroups() {
    _phaseGroups = {};
    for (final player in widget.players) {
      player.syncPhases();
      for (int i = 0; i < player.moves.length; i++) {
        final phase = i < player.movePhases.length ? player.movePhases[i] : i;
        _phaseGroups.putIfAbsent(phase, () => []);
        _phaseGroups[phase]!.add((player: player, moveIdx: i));
      }
    }
    _sortedPhases = _phaseGroups.keys.toList()..sort();
  }

  /// For a player at a given phase, find which move index they should be at
  int _playerPosAtPhase(PlayerIcon player, int phaseIdx) {
    int lastCompleted = -1; // -1 means at initial position
    for (int i = 0; i < player.moves.length; i++) {
      final ph = i < player.movePhases.length ? player.movePhases[i] : i;
      // Check if this move's phase has been completed
      final phaseOrderIdx = _sortedPhases.indexOf(ph);
      if (phaseOrderIdx >= 0 && phaseOrderIdx < phaseIdx) {
        lastCompleted = i;
      }
    }
    return lastCompleted + 1; // index into [position, ...moves]
  }

  void _onTick() {
    if (!widget.isAnimating) return;
    final t = _curved.value;
    final positions = <String, Offset>{};

    if (_sortedPhases.isEmpty) {
      context.read<TacticsState>().updateAnimatedPositions(positions);
      return;
    }

    final currentPhase = _phaseIdx < _sortedPhases.length ? _sortedPhases[_phaseIdx] : _sortedPhases.last;
    final activeGroup = _phaseGroups[currentPhase] ?? [];

    for (final player in widget.players) {
      final all = [player.position, ...player.moves];
      final baseIdx = _playerPosAtPhase(player, _phaseIdx);

      // Check if this player has a move in the current phase
      final activeEntry = activeGroup.where((e) => e.player.id == player.id).toList();

      if (activeEntry.isNotEmpty) {
        final moveIdx = activeEntry.first.moveIdx;
        final fromIdx = moveIdx.clamp(0, all.length - 1);
        final toIdx = (moveIdx + 1).clamp(0, all.length - 1);
        if (_isBackward) {
          positions[player.id] = Offset.lerp(all[toIdx], all[fromIdx], t)!;
        } else {
          positions[player.id] = Offset.lerp(all[fromIdx], all[toIdx], t)!;
        }
      } else {
        // Not moving in this phase — stay at current position
        positions[player.id] = all[baseIdx.clamp(0, all.length - 1)];
      }
    }
    context.read<TacticsState>().updateAnimatedPositions(positions);
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    if (_isBackward) {
      _phaseIdx--;
      context.read<TacticsState>().advanceAtStep(_phaseIdx + 1);
      if (_singleStep || _phaseIdx < 0) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => context.read<TacticsState>().finishAnimation());
      } else {
        _ctrl.forward(from: 0);
      }
    } else {
      _phaseIdx++;
      context.read<TacticsState>().advanceAtStep(_phaseIdx);
      if (_singleStep || _phaseIdx >= _sortedPhases.length) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => context.read<TacticsState>().finishAnimation());
      } else {
        _ctrl.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ─────────────────────────────────────────────────────────────────────────────
// Player on board (draggable, supports animated position override)
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerOnBoard extends StatefulWidget {
  final PlayerIcon player;
  final Offset? renderPosition; // animated override
  final bool isSelected;
  final bool isDrawingMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _PlayerOnBoard({
    super.key,
    required this.player,
    this.renderPosition,
    required this.isSelected,
    required this.isDrawingMode,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<_PlayerOnBoard> createState() => _PlayerOnBoardState();
}

class _PlayerOnBoardState extends State<_PlayerOnBoard> {
  double _baseScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final pos = widget.renderPosition ?? player.position;
    final size = kPlayerIconSize * player.scale;
    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      child: PlayerIconWidget(
        player: player,
        isSelected: widget.isSelected,
        onTap: widget.isDrawingMode ? null : widget.onTap,
        onLongPress: widget.isDrawingMode ? null : widget.onLongPress,
        onScaleStart: widget.isDrawingMode
            ? null
            : (d) {
                _baseScale = player.scale;
              },
        onScaleUpdate: widget.isDrawingMode
            ? null
            : (d) {
                final state = context.read<TacticsState>();
                state.movePlayer(
                    player.id, player.position + d.focalPointDelta);
                if (d.pointerCount >= 2) {
                  state.resizePlayer(player.id, _baseScale * d.scale);
                }
              },
        onScaleEnd: widget.isDrawingMode
            ? null
            : (d) {
                final state = context.read<TacticsState>();
                state.movePlayerEnd(player.id, player.position);
                if (d.pointerCount >= 2) {
                  state.resizePlayerEnd(player.id);
                }
              },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Waypoint dot (draggable, long-press to delete; last waypoint shows player shape)
// ─────────────────────────────────────────────────────────────────────────────
class _WaypointDot extends StatefulWidget {
  final PlayerIcon player;
  final int index;
  final Offset position;
  final bool isLast;
  final VoidCallback? onLongPress;

  const _WaypointDot({
    super.key,
    required this.player,
    required this.index,
    required this.position,
    this.isLast = false,
    this.onLongPress,
  });

  @override
  State<_WaypointDot> createState() => _WaypointDotState();
}

class _WaypointDotState extends State<_WaypointDot> {
  static const double _dotSize = 24.0;

  void _onPanUpdate(DragUpdateDetails d) {
    context.read<TacticsState>().movePlayerWaypoint(
          widget.player.id,
          widget.index,
          widget.position + d.delta,
        );
  }

  void _onPanEnd(DragEndDetails _) {
    context.read<TacticsState>().movePlayerWaypointEnd(widget.player.id);
  }

  void _onDefaultLongPress() {
    context.read<TacticsState>().removePlayerWaypoint(
          widget.player.id,
          widget.index,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLast) {
      return Positioned(
        left: widget.position.dx - kPlayerIconSize / 2,
        top: widget.position.dy - kPlayerIconSize / 2,
        child: GestureDetector(
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onLongPress: widget.onLongPress,
          child: SizedBox(
            width: kPlayerIconSize,
            height: kPlayerIconSize,
            child: Stack(
              children: [
                CustomPaint(
                  painter: TopDownPlayerPainter(
                    color: widget.player.color,
                    borderColor: widget.player.moveColor,
                    borderWidth: 2.5,
                    gender: widget.player.gender,
                  ),
                  size: Size.infinite,
                ),
                if (widget.player.label.isNotEmpty)
                  Align(
                    alignment: const Alignment(0, 0.35),
                    child: Text(
                      widget.player.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: widget.position.dx - _dotSize / 2,
      top: widget.position.dy - _dotSize / 2,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onLongPress: _onDefaultLongPress,
        child: Container(
          width: _dotSize,
          height: _dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.player.moveColor,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Player edit dialog — color swatches + name field + delete
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerEditDialog extends StatefulWidget {
  final TacticsState state;
  final PlayerIcon player;

  const _PlayerEditDialog({required this.state, required this.player});

  @override
  State<_PlayerEditDialog> createState() => _PlayerEditDialogState();
}

class _PlayerEditDialogState extends State<_PlayerEditDialog> {
  late final TextEditingController _labelCtrl;
  Color? _selectedColor; // null = use team default

  static const _swatches = <Color?>[
    null,
    Color(0xFF1565C0),
    Color(0xFFC62828),
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFFAD1457),
    Color(0xFFF9A825),
  ];

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.player.label);
    _selectedColor = widget.player.customColor;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E2E),
      title: Text('edit_player'.tr(),
          style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _labelCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'player_name'.tr(),
              labelStyle: const TextStyle(color: Colors.white60),
              enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30)),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70)),
            ),
          ),
          const SizedBox(height: 16),
          Text('player_color'.tr(),
              style:
                  const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _swatches.map((color) {
              final isSelected = color == _selectedColor;
              final displayColor = color ??
                  PlayerIcon.teamColor(widget.player.team);
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: displayColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.yellow
                          : Colors.white38,
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check,
                          size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.state.removePlayer(widget.player.id);
            Navigator.pop(context);
          },
          child: Text('remove'.tr(),
              style: const TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        TextButton(
          onPressed: () {
            widget.state.updatePlayer(
              widget.player.id,
              label: _labelCtrl.text,
              customColor: _selectedColor,
              clearCustomColor: _selectedColor == null,
            );
            Navigator.pop(context);
          },
          child: Text('save'.tr(),
              style:
                  const TextStyle(color: Colors.lightBlueAccent)),
        ),
      ],
    );
  }
}
