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

class TacticsCanvas extends StatelessWidget {
  const TacticsCanvas({super.key});

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
    return Consumer<TacticsState>(
      builder: (context, state, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              state.setCanvasSize(
                  Size(constraints.maxWidth, constraints.maxHeight));
            });

            final players = state.players.toList();

            return InteractiveViewer(
              transformationController: state.transformationController,
              panEnabled: !state.isDrawingMode && !state.isAnimating,
              scaleEnabled: !state.isDrawingMode,
              constrained: false,
              boundaryMargin: EdgeInsets.all(double.infinity),
              minScale: 0.5,
              maxScale: 4.0,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: GestureDetector(
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
                  if (!state.isDrawingMode && !state.isAnimating)
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
                  if (!state.isDrawingMode)
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
                  ),
                ],
                ),
              ),
            ),
              ),
            );
          },
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

  const _AnimationDriver({
    required this.isAnimating,
    required this.players,
    required this.targetStep,
    this.fromStep = 0,
    this.toStep = 0,
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
      final maxSteps = widget.players.fold(
          0, (m, p) => p.moves.length > m ? p.moves.length : m);
      _step = widget.fromStep;
      _isBackward = widget.toStep < widget.fromStep;
      if (_isBackward) {
        _totalSteps = widget.toStep;
        _ctrl.forward(from: 0);
      } else if (widget.toStep > 0) {
        _totalSteps = widget.toStep;
        if (_totalSteps > _step) {
          _ctrl.forward(from: 0);
        } else {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => context.read<TacticsState>().finishAnimation());
        }
      } else {
        _totalSteps = (widget.targetStep > 0 && widget.targetStep <= maxSteps)
            ? widget.targetStep
            : maxSteps;
        if (_totalSteps > _step) {
          _ctrl.forward(from: 0);
        } else {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => context.read<TacticsState>().finishAnimation());
        }
      }
    } else if (!widget.isAnimating && old.isAnimating) {
      _ctrl.stop();
      _step = 0;
      _isBackward = false;
    }
  }

  void _onTick() {
    if (!widget.isAnimating) return;
    final t = _curved.value;
    final positions = <String, Offset>{};
    for (final player in widget.players) {
      final all = [player.position, ...player.moves];
      if (_isBackward) {
        // Animate from _step back to _step - 1
        final from = _step.clamp(0, all.length - 1);
        final to = (_step - 1).clamp(0, all.length - 1);
        positions[player.id] = Offset.lerp(all[from], all[to], t)!;
      } else {
        if (_step >= all.length - 1) {
          positions[player.id] = all.last;
        } else {
          positions[player.id] =
              Offset.lerp(all[_step], all[_step + 1], t)!;
        }
      }
    }
    context.read<TacticsState>().updateAnimatedPositions(positions);
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_isBackward) {
      _step--;
      context.read<TacticsState>().advanceAtStep(_step);
      if (_step <= _totalSteps) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => context.read<TacticsState>().finishAnimation());
      } else {
        _ctrl.forward(from: 0);
      }
    } else {
      _step++;
      context.read<TacticsState>().advanceAtStep(_step);
      if (_step >= _totalSteps) {
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
