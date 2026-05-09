import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sport_type.dart';
import '../models/player_icon.dart';
import '../models/drawing_stroke.dart';
import '../painters/drawing_painter.dart';
import '../painters/ball_painter.dart';
import '../painters/player_moves_painter.dart';
import '../painters/badminton_court_painter.dart';
import '../painters/basketball_court_painter.dart';
import '../painters/tennis_court_painter.dart';
import '../painters/table_tennis_court_painter.dart';
import '../painters/volleyball_court_painter.dart';
import '../painters/pickleball_court_painter.dart';
import '../painters/soccer_court_painter.dart';
import '../painters/field_hockey_court_painter.dart';
import '../painters/rugby_court_painter.dart';
import '../painters/baseball_court_painter.dart';
import '../painters/handball_court_painter.dart';
import '../painters/water_polo_court_painter.dart';
import '../painters/sepak_takraw_court_painter.dart';
import '../painters/beach_tennis_court_painter.dart';
import '../painters/footvolley_court_painter.dart';
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
  /// True while a multi-select pan is moving the group (started on a
  /// selected stroke). When false, multi-select pans draw the lasso rect.
  bool _multiSelectStrokeDragging = false;

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
      case SportType.fieldHockey:
        return const FieldHockeyCourtPainter();
      case SportType.rugby:
        return const RugbyCourtPainter();
      case SportType.baseball:
        return const BaseballCourtPainter();
      case SportType.handball:
        return const HandballCourtPainter();
      case SportType.waterPolo:
        return const WaterPoloCourtPainter();
      case SportType.sepakTakraw:
        return const SepakTakrawCourtPainter();
      case SportType.beachTennis:
        return const BeachTennisCourtPainter();
      case SportType.footvolley:
        return const FootvolleyCourtPainter();
    }
  }

  /// Transform portrait canvas offset to landscape canvas offset.
  /// Home team (portrait bottom) → landscape left.
  static Offset _txl(Offset p, double sw, double sh, double lw, double lh) {
    return Offset((sh - p.dy) / sh * lw, p.dx / sw * lh);
  }

  static List<PlayerIcon> _landscapePlayers(
      List<PlayerIcon> players, double sw, double sh, double lw, double lh) {
    return players.map((p) => p.copyWith(
          position: _txl(p.position, sw, sh, lw, lh),
          moves: p.moves.map((m) => _txl(m, sw, sh, lw, lh)).toList(),
        )).toList();
  }

  static List<DrawingStroke> _landscapeStrokes(
      List<DrawingStroke> strokes, double sw, double sh, double lw, double lh) {
    return strokes.map((s) => s.copyWith(
          points: s.points.map((p) => _txl(p, sw, sh, lw, lh)).toList(),
        )).toList();
  }

  Widget _buildExternalContent() {
    const pw = 540.0;
    const ph = 960.0;
    final sw = _state.canvasSize.width;
    final sh = _state.canvasSize.height;
    if (sw <= 0 || sh <= 0) return const SizedBox(width: 960, height: 540);
    Offset sc(Offset p) => Offset(p.dx / sw * pw, p.dy / sh * ph);
    final players = _state.players.toList();
    final sPlayers = players.map((p) => p.copyWith(
      position: sc(p.position),
      moves: p.moves.map(sc).toList(),
    )).toList();
    final sStrokes = _visibleStrokes(_state, players).map((s) => s.copyWith(
      points: s.points.map(sc).toList(),
    )).toList();
    // RotatedBox(quarterTurns: 3) = 90° CCW: portrait bottom → landscape left (home side)
    return RotatedBox(
      quarterTurns: 3,
      child: SizedBox(
        width: pw,
        height: ph,
        child: Stack(
          children: [
            CustomPaint(
              painter: _courtPainter(_state.sportType),
              size: const Size(pw, ph),
              child: const SizedBox(width: pw, height: ph),
            ),
            CustomPaint(
              painter: DrawingPainter(
                strokes: sStrokes,
                currentStroke: null,
                selectedStrokeId: null,
              ),
              size: const Size(pw, ph),
            ),
            // Ghost icons at starting positions
            if (_state.showMoveLines)
              ...sPlayers.where((p) => p.moves.isNotEmpty).map((player) {
                final size = kPlayerIconSize * player.scale;
                return Positioned(
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
            // Waypoint dots
            if (!_state.isAnimating && _state.showMoveLines)
              ...sPlayers.expand((player) {
                return player.moves.asMap().entries.map((entry) {
                  final isLast = entry.key == player.moves.length - 1;
                  final pos = entry.value;
                  if (isLast) {
                    return Positioned(
                      left: pos.dx - kPlayerIconSize / 2,
                      top: pos.dy - kPlayerIconSize / 2,
                      child: IgnorePointer(
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: SizedBox(
                            width: kPlayerIconSize,
                            height: kPlayerIconSize,
                            child: player.photoId != null && !player.isMarker && !player.isBall
                                ? PhotoPlayerShape(player: player, isSelected: false)
                                : CustomPaint(
                              painter: player.isMarker
                                  ? MarkerPainter(shape: player.markerShape, color: player.color)
                                  : player.isBall
                                  ? BallPainter.forSport(player.sportType!)
                                  : TopDownPlayerPainter(
                                      color: player.color,
                                      borderColor: player.moveColor,
                                      borderWidth: 2.5,
                                      gender: player.gender,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  const dotSize = 28.0;
                  return Positioned(
                    left: pos.dx - dotSize / 2,
                    top: pos.dy - dotSize / 2,
                    child: IgnorePointer(
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: player.moveColor,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                });
              }),
            ...sPlayers.map((player) {
              Offset pos = player.position;
              final animSrc = _state.animatedPositions[player.id];
              if (animSrc != null) pos = sc(animSrc);
              final size = kPlayerIconSize * player.scale;
              return Positioned(
                left: pos.dx - size / 2,
                top: pos.dy - size / 2,
                child: IgnorePointer(
                  child: RotatedBox(
                    quarterTurns: 1, // counter-rotate: canvas is 90° CCW, so icons need 90° CW
                    child: PlayerIconWidget(player: player),
                  ),
                ),
              );
            }),
            if (_state.showMoveLines)
              CustomPaint(
                painter: PlayerMovesPainter(
                  players: sPlayers,
                  targetStep: _state.atStep > 0 ? _state.atStep : _state.targetStep,
                  completedSteps: _state.isAnimating ? _state.atStep : null,
                ),
                size: const Size(pw, ph),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_stateOrNull == null) {
      return Container(color: const Color(0xFF213E48));
    }
    final state = _state;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Offscreen landscape canvas for external display
        Positioned(
          left: -20000,
          top: 0,
          child: RepaintBoundary(
            key: externalRepaintKey,
            child: SizedBox(
              width: 960,
              height: 540,
              child: _buildExternalContent(),
            ),
          ),
        ),
        LayoutBuilder(
      builder: (context, constraints) {
            final canvasW = constraints.maxWidth;
            final canvasH = constraints.maxHeight;
            final newSize = Size(canvasW, canvasH);
            if (state.canvasSize != newSize) {
              state.setCanvasSizeSilent(newSize);
            }

            final players = state.players.toList();

            final draggingStroke = state.isDrawingMode && state.selectedStrokeId != null;

            final pannable = state.isDrawingMode || state.multiSelectMode;
            return GestureDetector(
              onPanStart: pannable
                  ? (d) {
                      if (state.isDrawingMode) {
                        if (draggingStroke) {
                          final hitId = state.hitTestStroke(d.localPosition);
                          if (hitId == state.selectedStrokeId) return;
                          state.selectStroke(null);
                        }
                        state.startStroke(d.localPosition);
                      } else if (state.multiSelectMode) {
                        // Pan started on a stroke that's already in the
                        // multi-select set → drag the whole group instead
                        // of starting a new lasso. Otherwise, lasso.
                        final hitId = state.hitTestStroke(d.localPosition);
                        if (hitId != null &&
                            state.multiSelectStrokeIds.contains(hitId)) {
                          _multiSelectStrokeDragging = true;
                        } else {
                          _multiSelectStrokeDragging = false;
                          state.beginMultiSelectRect(d.localPosition);
                        }
                      }
                    }
                  : null,
              onPanUpdate: pannable
                  ? (d) {
                      if (state.isDrawingMode) {
                        if (draggingStroke) {
                          state.moveStroke(state.selectedStrokeId!, d.delta);
                        } else {
                          state.addPoint(d.localPosition);
                        }
                      } else if (state.multiSelectMode) {
                        if (_multiSelectStrokeDragging) {
                          state.moveMultiSelectBy(d.delta);
                        } else {
                          state.updateMultiSelectRect(d.localPosition);
                        }
                      }
                    }
                  : null,
              onPanEnd: pannable
                  ? (_) {
                      if (state.isDrawingMode) {
                        if (draggingStroke) {
                          state.moveStrokeEnd(state.selectedStrokeId!);
                        } else {
                          state.endStroke();
                        }
                      } else if (state.multiSelectMode) {
                        if (_multiSelectStrokeDragging) {
                          state.moveMultiSelectEnd();
                          _multiSelectStrokeDragging = false;
                        } else {
                          state.endMultiSelectRect();
                        }
                      }
                    }
                  : null,
              onTapUp: (!state.isAnimating)
                  ? (d) {
                      if (state.multiSelectMode) {
                        // Tap on empty canvas in select mode: if a stroke is
                        // hit, toggle its membership in the stroke set.
                        // Player taps go through the per-player onTap.
                        final hitId = state.hitTestStroke(d.localPosition);
                        if (hitId != null) {
                          state.toggleMultiSelectStroke(hitId);
                        }
                      } else if (state.isDrawingMode) {
                        final hitId = state.hitTestStroke(d.localPosition);
                        state.selectStroke(hitId);
                      } else if (state.selectedPlayerId != null) {
                        state.addPlayerMove(state.selectedPlayerId!, d.localPosition);
                      } else {
                        final hitId = state.hitTestStroke(d.localPosition);
                        state.selectStroke(hitId);
                      }
                    }
                  : null,
              child: RepaintBoundary(
                key: boardRepaintKey,
                child: _buildCanvasContent(state, players, canvasW, canvasH),
              ),
            );
      },
    ),
      ],
    );
  }

  Widget _buildCanvasContent(TacticsState state, List<PlayerIcon> players, double canvasW, double canvasH) {
    return Stack(
                children: [
                  // Court background
                  CustomPaint(
                    painter: _courtPainter(state.sportType),
                    size: Size(canvasW, canvasH),
                    child: SizedBox(
                      width: canvasW,
                      height: canvasH,
                    ),
                  ),
                  // Drawing layer (filter by phase during step playback)
                  CustomPaint(
                    painter: DrawingPainter(
                      strokes: _visibleStrokes(state, players),
                      currentStroke: state.currentStroke,
                      selectedStrokeId: state.selectedStrokeId,
                      multiSelectStrokeIds: state.multiSelectStrokeIds,
                    ),
                    size: Size(canvasW, canvasH),
                  ),
                  // Waypoint dots (hidden during animation, limited to atStep/targetStep)
                  if (!state.isAnimating && state.showMoveLines)
                    ...players.expand((player) {
                      final phaseLimit = state.atStep > 0 ? state.atStep : (state.targetStep > 0 ? state.targetStep : 0);
                      List<Offset> visibleMoves;
                      if (phaseLimit > 0) {
                        player.syncPhases();
                        final sortedPhases = _allSortedPhases(players);
                        int count = 0;
                        for (int i = 0; i < player.moves.length; i++) {
                          final ph = i < player.movePhases.length ? player.movePhases[i] : i;
                          final idx = sortedPhases.indexOf(ph);
                          if (idx >= 0 && idx < phaseLimit) count = i + 1;
                        }
                        visibleMoves = player.moves.take(count).toList();
                      } else {
                        visibleMoves = player.moves;
                      }
                      final atStartTime =
                          state.atStep == 0 && state.targetStep == 0;
                      return visibleMoves.asMap().entries.map((entry) {
                        final isLast = entry.key == visibleMoves.length - 1;
                        final chainSelected = state.selectedPlayerId == player.id;
                        return _WaypointDot(
                          key: ValueKey('wp_${player.id}_${entry.key}'),
                          player: player,
                          index: entry.key,
                          position: entry.value,
                          isLast: isLast,
                          isSelected: chainSelected,
                          isPrimary: chainSelected && state.selectedWaypointIndex == entry.key,
                          isAtCurrentStep: isLast ? !atStartTime : true,
                          onLongPress: isLast
                              ? () => _showEditDialog(context, state, player)
                              : null,
                        );
                      });
                    }),
                  // Ghost icons at initial positions for players with moves
                  if (state.showMoveLines)
                    ...players.where((p) => p.moves.isNotEmpty).map((player) {
                      final size = kPlayerIconSize * player.scale;
                      return Positioned(
                        key: ValueKey('ghost_${player.id}'),
                        left: player.position.dx - size / 2,
                        top: player.position.dy - size / 2,
                        child: SizedBox(
                          width: size,
                          height: size,
                          child: Stack(
                            children: [
                              CustomPaint(
                                painter: TopDownPlayerPainter(
                                  color: player.color,
                                  borderColor: Colors.white,
                                  borderWidth: 2,
                                  gender: player.gender,
                                  isGhost: true,
                                ),
                                size: Size.infinite,
                              ),
                              if (player.label.isNotEmpty &&
                                  player.label.length <= 2)
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    player.label,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13 * player.scale,
                                      height: 1,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  // Player icons
                  ...players.map((player) {
                    final animPos = state.animatedPositions[player.id];
                    final inMulti =
                        state.multiSelectMode &&
                        state.multiSelectIds.contains(player.id);
                    final selected =
                        state.selectedPlayerId == player.id || inMulti;
                    final atStartTime =
                        state.atStep == 0 && state.targetStep == 0;
                    return _PlayerOnBoard(
                      key: ValueKey(player.id),
                      player: player,
                      renderPosition: animPos,
                      isSelected: selected,
                      isPrimary: selected &&
                          !state.multiSelectMode &&
                          state.selectedWaypointIndex == null,
                      isAtCurrentStep: atStartTime,
                      isDrawingMode: state.isDrawingMode || state.isAnimating,
                      isMultiSelectMode: state.multiSelectMode,
                      isInMultiSelect: inMulti,
                      onTap: () {
                        if (state.multiSelectMode) {
                          state.toggleMultiSelectId(player.id);
                        } else {
                          state.selectPlayer(selected ? null : player.id);
                        }
                      },
                      onLongPress: state.multiSelectMode
                          ? null
                          : () => _showEditDialog(context, state, player),
                    );
                  }),
                  // Player move arrows — on top so arrowheads are never covered
                  if (state.showMoveLines)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: PlayerMovesPainter(
                          players: players,
                          targetStep: state.atStep > 0 ? state.atStep : state.targetStep,
                          completedSteps: state.isAnimating ? state.atStep : null,
                        ),
                        size: Size(canvasW, canvasH),
                      ),
                    ),
                  // Animation driver (zero-size, drives per-frame updates)
                  _AnimationDriver(
                    isAnimating: state.isAnimating,
                    players: players,
                    targetStep: state.targetStep,
                    fromStep: state.animFromStep,
                    toStep: state.animToStep,
                    sequentialMode: state.sequentialMode,
                  ),
                  // Lasso overlay — drawn while the user is rectangle-selecting
                  // in multi-select mode.
                  if (state.multiSelectDragRect != null)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _LassoRectPainter(state.multiSelectDragRect!),
                        size: Size(canvasW, canvasH),
                      ),
                    ),
                ],
    );
  }

  static List<int> _allSortedPhases(List<PlayerIcon> players) {
    final phases = <int>{};
    for (final p in players) {
      p.syncPhases();
      phases.addAll(p.movePhases);
    }
    return phases.toList()..sort();
  }

  /// Return strokes visible at the current playback step.
  /// Strokes with isFullSpan are always visible.
  /// During step playback, show strokes whose phase range overlaps current step.
  static List<DrawingStroke> _visibleStrokes(TacticsState state, List<PlayerIcon> players) {
    final phaseLimit = state.atStep > 0 ? state.atStep : (state.targetStep > 0 ? state.targetStep : 0);
    if (phaseLimit == 0) return state.strokes; // show all
    final sortedPhases = _allSortedPhases(players);
    // Include stroke phases
    for (final s in state.strokes) {
      if (!s.isFullSpan) {
        for (int i = s.startPhase; i <= s.endPhase; i++) {
          if (!sortedPhases.contains(i)) sortedPhases.add(i);
        }
      }
    }
    sortedPhases.sort();
    return state.strokes.where((s) {
      if (s.isFullSpan) return true;
      // Check if any phase in stroke range is within the visible limit
      for (int ph = s.startPhase; ph <= s.endPhase; ph++) {
        final idx = sortedPhases.indexOf(ph);
        if (idx >= 0 && idx < phaseLimit) return true;
      }
      return false;
    }).toList();
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

  /// For a player at a given phaseIdx (index into _sortedPhases),
  /// find the position index in [position, ...moves] they should be at.
  /// This is the position AFTER all moves whose phase comes before phaseIdx.
  int _playerPosAtPhase(PlayerIcon player, int phaseIdx) {
    int lastCompleted = -1; // -1 means at initial position (index 0 in 'all')
    for (int i = 0; i < player.moves.length; i++) {
      final ph = i < player.movePhases.length ? player.movePhases[i] : i;
      final phaseOrderIdx = _sortedPhases.indexOf(ph);
      // A move is "completed" if its phase order index is strictly before current phaseIdx
      if (phaseOrderIdx >= 0 && phaseOrderIdx < phaseIdx) {
        if (i > lastCompleted) lastCompleted = i;
      }
    }
    // lastCompleted = -1 means no moves done → position index 0 (initial)
    // lastCompleted = 0 means move[0] done → position index 1 (at moves[0])
    return lastCompleted + 1;
  }

  /// For a player AFTER phaseIdx completes (including current phase),
  /// find the position index.
  int _playerPosAfterPhase(PlayerIcon player, int phaseIdx) {
    int lastCompleted = -1;
    for (int i = 0; i < player.moves.length; i++) {
      final ph = i < player.movePhases.length ? player.movePhases[i] : i;
      final phaseOrderIdx = _sortedPhases.indexOf(ph);
      if (phaseOrderIdx >= 0 && phaseOrderIdx <= phaseIdx) {
        if (i > lastCompleted) lastCompleted = i;
      }
    }
    return lastCompleted + 1;
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
      if (player.moves.isEmpty) continue; // no moves at all, skip
      final all = [player.position, ...player.moves];

      // Check if this player has a move in the current phase
      final activeEntry = activeGroup.where((e) => e.player.id == player.id).toList();

      if (activeEntry.isNotEmpty) {
        // This player IS moving in this phase
        final moveIdx = activeEntry.first.moveIdx;
        final fromIdx = moveIdx.clamp(0, all.length - 1);
        final toIdx = (moveIdx + 1).clamp(0, all.length - 1);
        if (_isBackward) {
          positions[player.id] = Offset.lerp(all[toIdx], all[fromIdx], t)!;
        } else {
          positions[player.id] = Offset.lerp(all[fromIdx], all[toIdx], t)!;
        }
      } else {
        // This player is NOT moving in this phase
        // Only set position if they have completed at least one move before this phase
        final restIdx = _isBackward
            ? _playerPosAfterPhase(player, _phaseIdx)
            : _playerPosAtPhase(player, _phaseIdx);
        if (restIdx > 0) {
          // Player has moved before — hold at their resting position
          positions[player.id] = all[restIdx.clamp(0, all.length - 1)];
        }
        // else: restIdx==0 means player hasn't moved yet, don't set animated position
        // so the player renders at their original player.position naturally
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
  final bool isPrimary;
  final bool isAtCurrentStep; // start position is the current timeline step
  final bool isDrawingMode;
  /// True when the board is in the multi-select mode (taps toggle set
  /// membership instead of opening the edit panel). Controls the gesture
  /// dispatch in [_PlayerOnBoardState].
  final bool isMultiSelectMode;
  /// True when this player is currently in the multi-select set. Drives
  /// group drag — panning a member translates the whole set.
  final bool isInMultiSelect;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _PlayerOnBoard({
    super.key,
    required this.player,
    this.renderPosition,
    required this.isSelected,
    this.isPrimary = false,
    this.isAtCurrentStep = true,
    required this.isDrawingMode,
    this.isMultiSelectMode = false,
    this.isInMultiSelect = false,
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
    // Start-of-chain icons (player has moves, not animating) render as a
    // faded ghost when the timeline is past step 0 — because the player's
    // "current" position is somewhere along the chain, not at the start.
    // At step 0 the start IS current, so show it solid. Primary tap always
    // reveals the full icon.
    final isStartWithMoves =
        widget.renderPosition == null && player.moves.isNotEmpty;
    final showGhostForStart = isStartWithMoves &&
        !widget.isPrimary &&
        !widget.isAtCurrentStep;
    // In multi-select mode a non-member player must NOT register a pan
    // recognizer at all — otherwise it would claim drags that started on
    // top of the player and the user couldn't lasso through it. Members
    // keep the pan so they can drag the whole set as a unit. Outside
    // multi-select mode, pan is always available (single-player drag).
    final canPan = !widget.isMultiSelectMode || widget.isInMultiSelect;
    final iconWidget = PlayerIconWidget(
      player: player,
      isSelected: widget.isSelected,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onScaleStart: canPan
          ? (d) {
              _baseScale = player.scale;
            }
          : null,
      onScaleUpdate: canPan
          ? (d) {
              final state = context.read<TacticsState>();
              if (widget.isInMultiSelect) {
                state.moveMultiSelectBy(d.focalPointDelta);
                return;
              }
              state.movePlayer(player.id, player.position + d.focalPointDelta);
              if (d.pointerCount >= 2) {
                state.resizePlayer(player.id, _baseScale * d.scale);
              }
            }
          : null,
      onScaleEnd: canPan
          ? (d) {
              final state = context.read<TacticsState>();
              if (widget.isInMultiSelect) {
                state.moveMultiSelectEnd();
                return;
              }
              state.movePlayerEnd(player.id, player.position);
              if (d.pointerCount >= 2) {
                state.resizePlayerEnd(player.id);
              }
            }
          : null,
    );
    // Hide the full icon entirely when start is not at the current step —
    // the dashed ghost (TopDownPlayerPainter isGhost:true) drawn at the same
    // position in the layer below will show through, giving a dashed outline.
    final visibleIcon = showGhostForStart
        ? Opacity(opacity: 0.0, child: iconWidget)
        : iconWidget;
    // Primary cyan glow only when the full icon is shown — a glow around an
    // invisible ghost reads as a stray blob. Chain selection on the start
    // position is implied by the glowing waypoints/end of the chain.
    final BoxShadow? glow = widget.isPrimary
        ? BoxShadow(
            color: const Color(0xFF00E5CC).withValues(alpha: 0.85),
            blurRadius: 16,
            spreadRadius: 3,
          )
        : null;
    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      child: glow != null
          ? DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [glow],
              ),
              child: visibleIcon,
            )
          : visibleIcon,
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
  final bool isSelected;
  final bool isPrimary;
  final bool isAtCurrentStep;
  final VoidCallback? onLongPress;

  const _WaypointDot({
    super.key,
    required this.player,
    required this.index,
    required this.position,
    this.isLast = false,
    this.isSelected = false,
    this.isPrimary = false,
    this.isAtCurrentStep = true,
    this.onLongPress,
  });

  @override
  State<_WaypointDot> createState() => _WaypointDotState();
}

class _WaypointDotState extends State<_WaypointDot> {
  static const double _dotSize = 28.0;

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

  void _onTap() {
    context
        .read<TacticsState>()
        .selectPlayerWaypoint(widget.player.id, widget.index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLast) {
      // End icon is "current" when the timeline has advanced past step 0.
      // When still at step 0 the end is a future destination — render the
      // normal player shape as a dashed ghost outline (same style as the
      // start ghost) so start/end use consistent "not current" styling.
      final fadeEnd = !widget.isAtCurrentStep && !widget.isPrimary;
      final hasPhoto = widget.player.photoId != null
          && !widget.player.isMarker
          && !widget.player.isBall;
      final Widget endIcon = SizedBox(
        width: kPlayerIconSize,
        height: kPlayerIconSize,
        child: Stack(
          children: [
            if (hasPhoto)
              Opacity(
                opacity: fadeEnd ? 0.55 : 1.0,
                child: PhotoPlayerShape(
                  player: widget.player,
                  isSelected: widget.isSelected,
                ),
              )
            else
              CustomPaint(
                painter: widget.player.isMarker
                    ? MarkerPainter(
                        shape: widget.player.markerShape,
                        color: widget.player.color,
                        isSelected: widget.isSelected,
                      )
                    : widget.player.isBall
                    ? BallPainter.forSport(widget.player.sportType!)
                    : TopDownPlayerPainter(
                        color: widget.player.color,
                        borderColor: widget.isPrimary
                            ? const Color(0xFF00E5CC)
                            : (widget.isSelected ? Colors.yellow : widget.player.moveColor),
                        borderWidth: widget.isPrimary ? 3.5 : (widget.isSelected ? 3 : 2.5),
                        isSelected: widget.isSelected && !fadeEnd,
                        isGhost: fadeEnd,
                        gender: widget.player.gender,
                      ),
                size: Size.infinite,
              ),
            if (widget.player.label.isNotEmpty &&
                !widget.player.isMarker &&
                !widget.player.isBall &&
                !hasPhoto)
              Align(
                alignment: Alignment.center,
                child: Text(
                  widget.player.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                  ),
                ),
              ),
          ],
        ),
      );
      return Positioned(
        left: widget.position.dx - kPlayerIconSize / 2,
        top: widget.position.dy - kPlayerIconSize / 2,
        child: GestureDetector(
          onTap: _onTap,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onLongPress: widget.onLongPress,
          child: endIcon,
        ),
      );
    }

    // Larger hit area for easier dragging
    const hitSize = 40.0;
    return Positioned(
      left: widget.position.dx - hitSize / 2,
      top: widget.position.dy - hitSize / 2,
      child: GestureDetector(
        onTap: _onTap,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onLongPress: _onDefaultLongPress,
        child: SizedBox(
          width: hitSize,
          height: hitSize,
          child: Center(
            child: Container(
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.player.moveColor,
                border: Border.all(
                  color: widget.isPrimary
                      ? const Color(0xFF00E5CC)
                      : (widget.isSelected ? Colors.yellow : Colors.white),
                  width: widget.isPrimary ? 3.5 : (widget.isSelected ? 3 : 2),
                ),
                boxShadow: [
                  if (widget.isPrimary)
                    BoxShadow(
                      color: const Color(0xFF00E5CC).withValues(alpha: 0.85),
                      blurRadius: 14,
                      spreadRadius: 2,
                    )
                  else if (widget.isSelected)
                    BoxShadow(
                      color: Colors.yellow.withValues(alpha: 0.7),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${widget.index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1),
                ),
              ),
            ),
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
  late double _scale;

  static const _swatches = <Color?>[
    null,
    Color(0xFF3A7DFF),
    Color(0xFFFF5A5F),
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
    _scale = widget.player.scale;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  /// Title key follows the element kind — markers and balls aren't
  /// "players" and the older blanket 编辑球员 wording read incorrectly.
  String _titleKey() {
    if (widget.player.isBall) return 'edit_ball';
    if (widget.player.isMarker) return 'edit_marker';
    return 'edit_player';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF213E48),
      title: Text(_titleKey().tr(),
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
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.photo_size_select_small, color: Colors.white60, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _scale,
                  min: 0.5,
                  max: 3.0,
                  divisions: 10,
                  activeColor: const Color(0xFF00E5CC),
                  inactiveColor: Colors.white24,
                  onChanged: (v) => setState(() => _scale = v),
                ),
              ),
              Text('${(_scale * 100).round()}%',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
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
              scale: _scale,
            );
            Navigator.pop(context);
          },
          child: Text('save'.tr(),
              style:
                  const TextStyle(color: const Color(0xFF00E5CC))),
        ),
      ],
    );
  }
}

/// Dashed selection rectangle drawn while the user lassos in multi-select
/// mode. Filled with a faint highlight color and outlined with dashes so
/// it reads as transient UI, not part of the board content.
class _LassoRectPainter extends CustomPainter {
  final Rect rect;
  const _LassoRectPainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF6EE7B7).withValues(alpha: 0.10);
    canvas.drawRect(rect, fill);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF6EE7B7);

    // Manual dashed outline.
    const dashOn = 6.0;
    const dashOff = 4.0;
    void dashedLine(Offset a, Offset b) {
      final dx = b.dx - a.dx, dy = b.dy - a.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len == 0) return;
      final ux = dx / len, uy = dy / len;
      double t = 0;
      while (t < len) {
        final segEnd = (t + dashOn).clamp(0, len).toDouble();
        canvas.drawLine(
          Offset(a.dx + ux * t, a.dy + uy * t),
          Offset(a.dx + ux * segEnd, a.dy + uy * segEnd),
          stroke,
        );
        t = segEnd + dashOff;
      }
    }

    dashedLine(rect.topLeft, rect.topRight);
    dashedLine(rect.topRight, rect.bottomRight);
    dashedLine(rect.bottomRight, rect.bottomLeft);
    dashedLine(rect.bottomLeft, rect.topLeft);
  }

  @override
  bool shouldRepaint(_LassoRectPainter old) => old.rect != rect;
}
