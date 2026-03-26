import 'dart:math';
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
                  // Player move arrows (below players, limited to targetStep)
                  CustomPaint(
                    painter: PlayerMovesPainter(
                      players: players,
                      targetStep: state.targetStep,
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
                  // Player icons
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
                          _showDeleteDialog(context, state, player),
                    );
                  }),
                  // Waypoint dots (hidden during animation, limited to targetStep)
                  if (!state.isDrawingMode && !state.isAnimating)
                    ...players.expand((player) {
                      final visibleMoves = state.targetStep > 0
                          ? player.moves.take(state.targetStep).toList()
                          : player.moves;
                      return visibleMoves.asMap().entries.map((entry) =>
                          _WaypointDot(
                            key: ValueKey('wp_${player.id}_${entry.key}'),
                            player: player,
                            index: entry.key,
                            position: entry.value,
                          ));
                    }),
                  // Animation driver (zero-size, drives per-frame updates)
                  _AnimationDriver(
                    isAnimating: state.isAnimating,
                    players: players,
                    targetStep: state.targetStep,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(
      BuildContext context, TacticsState state, PlayerIcon player) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text(
          'remove_player_title'.tr(args: [player.label]),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              state.removePlayer(player.id);
              Navigator.pop(ctx);
            },
            child:
                Text('remove'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
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

  const _AnimationDriver({
    required this.isAnimating,
    required this.players,
    required this.targetStep,
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
      _totalSteps = (widget.targetStep > 0 && widget.targetStep <= maxSteps)
          ? widget.targetStep
          : maxSteps;
      _step = 0;
      if (_totalSteps > 0) {
        _ctrl.forward(from: 0);
      } else {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => context.read<TacticsState>().finishAnimation());
      }
    } else if (!widget.isAnimating && old.isAnimating) {
      _ctrl.stop();
      _step = 0;
    }
  }

  void _onTick() {
    if (!widget.isAnimating) return;
    final positions = <String, Offset>{};
    for (final player in widget.players) {
      final all = [player.position, ...player.moves];
      if (_step >= all.length - 1) {
        positions[player.id] = all.last;
      } else {
        positions[player.id] =
            Offset.lerp(all[_step], all[_step + 1], _curved.value)!;
      }
    }
    context.read<TacticsState>().updateAnimatedPositions(positions);
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _step++;
    if (_step >= _totalSteps) {
      // Natural finish — keep final positions, just stop animating
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.read<TacticsState>().finishAnimation());
    } else {
      _ctrl.forward(from: 0);
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
// Waypoint dot (draggable, long-press to delete)
// ─────────────────────────────────────────────────────────────────────────────
class _WaypointDot extends StatefulWidget {
  final PlayerIcon player;
  final int index;
  final Offset position;

  const _WaypointDot({
    super.key,
    required this.player,
    required this.index,
    required this.position,
  });

  @override
  State<_WaypointDot> createState() => _WaypointDotState();
}

class _WaypointDotState extends State<_WaypointDot> {
  static const double _dotSize = 24.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - _dotSize / 2,
      top: widget.position.dy - _dotSize / 2,
      child: GestureDetector(
        onPanUpdate: (d) {
          context.read<TacticsState>().movePlayerWaypoint(
                widget.player.id,
                widget.index,
                widget.position + d.delta,
              );
        },
        onPanEnd: (_) {
          context
              .read<TacticsState>()
              .movePlayerWaypointEnd(widget.player.id);
        },
        onLongPress: () {
          context.read<TacticsState>().removePlayerWaypoint(
                widget.player.id,
                widget.index,
              );
        },
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
