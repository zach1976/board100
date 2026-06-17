import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Last finger position while laying a run by dragging in add-move mode.
  Offset? _addMovePanPos;

  /// Erase any stroke under [p] (drawing-mode eraser sub-mode).
  void _eraseAt(TacticsState state, Offset p) {
    final hit = state.hitTestStroke(p);
    if (hit != null) {
      state.deleteStroke(hit);
      HapticFeedback.selectionClick();
    }
  }

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
    final layout = _state.courtLayout(sport);
    final surface = _state.courtColor(sport);
    switch (sport) {
      case SportType.badminton:
        return BadmintonCourtPainter(layout: layout, surface: surface);
      case SportType.basketball:
        return BasketballCourtPainter(layout: layout, floor: surface);
      case SportType.tennis:
        return TennisCourtPainter(layout: layout, surface: surface);
      case SportType.tableTennis:
        return TableTennisCourtPainter(layout: layout, surface: surface);
      case SportType.volleyball:
        return VolleyballCourtPainter(layout: layout, surface: surface);
      case SportType.pickleball:
        return PickleballCourtPainter(layout: layout, surface: surface);
      case SportType.soccer:
        return SoccerCourtPainter(
          fieldType: _state.soccerFieldType,
          turf: _state.soccerTurf,
        );
      case SportType.fieldHockey:
        return FieldHockeyCourtPainter(layout: layout, surface: surface);
      case SportType.rugby:
        return RugbyCourtPainter(layout: layout, surface: surface);
      case SportType.baseball:
        return BaseballCourtPainter(layout: layout, surface: surface);
      case SportType.handball:
        return HandballCourtPainter(layout: layout, surface: surface);
      case SportType.waterPolo:
        return WaterPoloCourtPainter(layout: layout, surface: surface);
      case SportType.sepakTakraw:
        return SepakTakrawCourtPainter(layout: layout, surface: surface);
      case SportType.beachTennis:
        return BeachTennisCourtPainter(layout: layout, surface: surface);
      case SportType.footvolley:
        return FootvolleyCourtPainter(layout: layout, surface: surface);
    }
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
                final hasPhoto = player.photoId != null &&
                    !player.isMarker &&
                    !player.isBall;
                return Positioned(
                  left: player.position.dx - size / 2,
                  top: player.position.dy - size / 2,
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: hasPhoto
                        ? PhotoPlayerShape(
                            player: player,
                            isSelected: false,
                            isGhost: true,
                          )
                        : CustomPaint(
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
      return Container(color: const Color(0xFF15303A));
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

            final eraser = state.isDrawingMode && state.eraserMode;
            final draggingStroke = state.isDrawingMode &&
                state.selectedStrokeId != null && !eraser;
            final isAddMove =
                state.isAddingMove && state.selectedPlayerId != null;
            final locked = state.presentationMode;
            // Zoom mode + presentation both lock the board content and hand
            // every gesture to the InteractiveViewer. In normal editing the
            // board carries NO InteractiveViewer, so its scale recogniser can
            // never fight a single-finger player drag.
            final useViewer = locked || state.zoomMode;

            // Canvas-level single-finger gestures: drawing, erasing,
            // multi-select lasso, or laying a run. All off while the board
            // is locked (presentation) or being zoomed.
            final pannable = !useViewer &&
                (state.isDrawingMode || state.multiSelectMode || isAddMove);

            final board = GestureDetector(
              onPanStart: pannable
                  ? (d) {
                      if (eraser) {
                        _eraseAt(state, d.localPosition);
                      } else if (state.isDrawingMode) {
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
                      } else if (isAddMove) {
                        _addMovePanPos = d.localPosition;
                      }
                    }
                  : null,
              onPanUpdate: pannable
                  ? (d) {
                      if (eraser) {
                        _eraseAt(state, d.localPosition);
                      } else if (state.isDrawingMode) {
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
                      } else if (isAddMove) {
                        _addMovePanPos = d.localPosition;
                      }
                    }
                  : null,
              onPanEnd: pannable
                  ? (_) {
                      if (eraser) {
                        return;
                      } else if (state.isDrawingMode) {
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
                      } else if (isAddMove && _addMovePanPos != null) {
                        state.addPlayerMove(
                            state.selectedPlayerId!, _addMovePanPos!);
                        HapticFeedback.selectionClick();
                        _addMovePanPos = null;
                      }
                    }
                  : null,
              onTapUp: (!state.isAnimating && !useViewer)
                  ? (d) {
                      if (state.multiSelectMode) {
                        // In select mode: hit a stroke → toggle its membership;
                        // hit truly empty canvas → clear the whole selection.
                        // Player taps go through the per-player onTap, so they
                        // don't reach here.
                        final hitId = state.hitTestStroke(d.localPosition);
                        if (hitId != null) {
                          state.toggleMultiSelectStroke(hitId);
                        } else if (state.hasMultiSelection) {
                          state.clearMultiSelect();
                        }
                      } else if (state.isDrawingMode) {
                        if (eraser) {
                          _eraseAt(state, d.localPosition);
                        } else {
                          final hitId = state.hitTestStroke(d.localPosition);
                          state.selectStroke(hitId);
                        }
                      } else if (isAddMove) {
                        // Explicit add-run sub-mode: a tap appends a waypoint.
                        state.addPlayerMove(
                            state.selectedPlayerId!, d.localPosition);
                        HapticFeedback.selectionClick();
                      } else {
                        // Plain move mode: tapping a stroke selects it;
                        // tapping truly empty canvas clears any selection
                        // (it never silently creates content).
                        final hitId = state.hitTestStroke(d.localPosition);
                        if (hitId != null) {
                          state.selectStroke(hitId);
                        } else {
                          state.selectPlayer(null);
                          state.selectStroke(null);
                        }
                      }
                    }
                  : null,
              child: IgnorePointer(
                ignoring: useViewer,
                child: _buildCanvasContent(state, players, canvasW, canvasH),
              ),
            );

            final wrapped = RepaintBoundary(
              key: boardRepaintKey,
              child: SizedBox(
                width: canvasW,
                height: canvasH,
                child: board,
              ),
            );
            // Only mount the InteractiveViewer while zooming/presenting; in
            // normal editing apply any existing zoom statically (no gesture
            // recogniser) so player drags are never intercepted. The static
            // wrapper listens to the controller so a half-court / reset tap
            // repaints the board immediately, not on the next rebuild.
            return useViewer
                ? InteractiveViewer(
                    transformationController: state.transformationController,
                    panEnabled: true,
                    scaleEnabled: true,
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: wrapped,
                  )
                : ValueListenableBuilder<Matrix4>(
                    valueListenable: state.transformationController,
                    builder: (_, matrix, child) => Transform(
                      transform: matrix,
                      transformHitTests: true,
                      child: child,
                    ),
                    child: wrapped,
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
                  // Waypoint dots — stay visible through animation so each
                  // step-forward tap doesn't flash every middle dot off and
                  // back on. The phaseLimit filter (driven by atStep) still
                  // hides phases that haven't started yet.
                  if (state.showMoveLines)
                    ...players.expand((player) {
                      final phaseLimit = state.atStep > 0 ? state.atStep : (state.targetStep > 0 ? state.targetStep : 0);
                      List<Offset> visibleMoves;
                      if (phaseLimit > 0) {
                        player.syncPhases();
                        int count = 0;
                        for (int i = 0; i < player.moves.length; i++) {
                          final ph = i < player.movePhases.length ? player.movePhases[i] : i;
                          if (ph < phaseLimit) count = i + 1;
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
                              ? () => state.selectPlayer(player.id)
                              : null,
                        );
                      });
                    }),
                  // Ghost icons at initial positions for players with moves
                  if (state.showMoveLines)
                    ...players.where((p) => p.moves.isNotEmpty).map((player) {
                      final size = kPlayerIconSize * player.scale;
                      final hasPhoto = player.photoId != null &&
                          !player.isMarker &&
                          !player.isBall;
                      return Positioned(
                        key: ValueKey('ghost_${player.id}'),
                        left: player.position.dx - size / 2,
                        top: player.position.dy - size / 2,
                        child: SizedBox(
                          width: size,
                          height: size,
                          child: hasPhoto
                              ? PhotoPlayerShape(
                                  player: player,
                                  isSelected: false,
                                  isGhost: true,
                                )
                              : Stack(
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
                    // A player whose phases start AFTER the current step
                    // hasn't moved yet — their start position is still their
                    // current position, so don't hide the icon as a "past
                    // ghost". Without this, players whose first phase is
                    // later than atStep silently disappear from the board.
                    bool hasStartedMoving = false;
                    final phaseLimit = state.atStep > 0
                        ? state.atStep
                        : (state.targetStep > 0 ? state.targetStep : 0);
                    if (phaseLimit > 0 && player.moves.isNotEmpty) {
                      player.syncPhases();
                      for (int i = 0; i < player.moves.length; i++) {
                        final ph = i < player.movePhases.length
                            ? player.movePhases[i]
                            : i;
                        if (ph < phaseLimit) {
                          hasStartedMoving = true;
                          break;
                        }
                      }
                    }
                    return _PlayerOnBoard(
                      key: ValueKey(player.id),
                      player: player,
                      renderPosition: animPos,
                      isSelected: selected,
                      isPrimary: selected &&
                          !state.multiSelectMode &&
                          state.selectedWaypointIndex == null,
                      isAtCurrentStep: atStartTime || !hasStartedMoving,
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
                      // Tapping a player selects it — the floating edit bar
                      // then appears, so a separate long-press dialog is no
                      // longer needed (one unified edit surface).
                      onLongPress: null,
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
                    speed: state.animSpeed,
                    loop: state.loopAnimation,
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

  /// Return strokes visible at the current playback step.
  /// Strokes with isFullSpan are always visible.
  /// During step playback, show strokes whose phase range overlaps current step.
  static List<DrawingStroke> _visibleStrokes(TacticsState state, List<PlayerIcon> players) {
    final phaseLimit = state.atStep > 0 ? state.atStep : (state.targetStep > 0 ? state.targetStep : 0);
    if (phaseLimit == 0) return state.strokes; // show all
    // phaseLimit is the number of beats elapsed (atStep). A stroke whose
    // phase value is strictly less than phaseLimit has already begun.
    return state.strokes.where((s) {
      if (s.isFullSpan) return true;
      for (int ph = s.startPhase; ph <= s.endPhase; ph++) {
        if (ph < phaseLimit) return true;
      }
      return false;
    }).toList();
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
  final double speed; // playback speed multiplier (0.5 / 1 / 2)
  final bool loop; // restart from phase 0 when the run finishes

  const _AnimationDriver({
    required this.isAnimating,
    required this.players,
    required this.targetStep,
    this.fromStep = 0,
    this.toStep = 0,
    this.sequentialMode = false,
    this.speed = 1.0,
    this.loop = false,
  });

  @override
  State<_AnimationDriver> createState() => _AnimationDriverState();
}

class _AnimationDriverState extends State<_AnimationDriver>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final CurvedAnimation _curved;
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
      // Per-phase duration scales inversely with the chosen playback speed.
      _ctrl.duration = Duration(
          milliseconds: (700 / widget.speed).clamp(120, 4000).round());
      _isBackward = widget.toStep < widget.fromStep;
      // Single step if toStep is exactly 1 away from fromStep
      _singleStep = (widget.toStep - widget.fromStep).abs() == 1;

      if (_maxPhase < 0) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => context.read<TacticsState>().finishAnimation());
        return;
      }

      if (_isBackward) {
        // _phaseIdx = phase value to rewind on this leg.
        _phaseIdx = widget.fromStep - 1;
        if (_phaseIdx < 0 || _phaseIdx < widget.toStep) {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => context.read<TacticsState>().finishAnimation());
        } else {
          _ctrl.forward(from: 0);
        }
      } else {
        // _phaseIdx = phase value to animate on this leg.
        _phaseIdx = widget.fromStep;
        final endIdx =
            widget.toStep > 0 ? widget.toStep : (_maxPhase + 1);
        if (_phaseIdx > _maxPhase || _phaseIdx >= endIdx) {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => context.read<TacticsState>().finishAnimation());
        } else {
          _ctrl.forward(from: 0);
        }
      }
    } else if (!widget.isAnimating && old.isAnimating) {
      _ctrl.stop();
      _phaseIdx = 0;
      _singleStep = false;
      _isBackward = false;
    }
  }

  // Phase-based animation: collect all (player, moveIndex) grouped by phase.
  // _phaseIdx is the phase VALUE currently animating (not an index into
  // distinct used phases) — so empty phases in the middle of the range
  // still get a beat in continuous playback.
  Map<int, List<({PlayerIcon player, int moveIdx})>> _phaseGroups = {};
  int _maxPhase = -1;
  int _phaseIdx = 0;

  void _buildPhaseGroups() {
    _phaseGroups = {};
    _maxPhase = -1;
    for (final player in widget.players) {
      player.syncPhases();
      for (int i = 0; i < player.moves.length; i++) {
        final phase = i < player.movePhases.length ? player.movePhases[i] : i;
        _phaseGroups.putIfAbsent(phase, () => []).add((player: player, moveIdx: i));
        if (phase > _maxPhase) _maxPhase = phase;
      }
    }
  }

  /// Resting position index in [position, ...moves] for a player at the
  /// START of phase value [phaseValue] — i.e. only moves whose phase is
  /// strictly less than phaseValue have completed.
  int _playerPosAtPhase(PlayerIcon player, int phaseValue) {
    int lastCompleted = -1;
    for (int i = 0; i < player.moves.length; i++) {
      final ph = i < player.movePhases.length ? player.movePhases[i] : i;
      if (ph < phaseValue) {
        if (i > lastCompleted) lastCompleted = i;
      }
    }
    return lastCompleted + 1;
  }

  /// Resting position index AFTER phase value [phaseValue] completes
  /// (used while rewinding so the player snaps to its end-of-phase pose).
  int _playerPosAfterPhase(PlayerIcon player, int phaseValue) {
    int lastCompleted = -1;
    for (int i = 0; i < player.moves.length; i++) {
      final ph = i < player.movePhases.length ? player.movePhases[i] : i;
      if (ph <= phaseValue) {
        if (i > lastCompleted) lastCompleted = i;
      }
    }
    return lastCompleted + 1;
  }

  void _onTick() {
    if (!widget.isAnimating) return;
    final t = _curved.value;
    final positions = <String, Offset>{};

    if (_maxPhase < 0) {
      context.read<TacticsState>().updateAnimatedPositions(positions);
      return;
    }

    // _phaseIdx is the phase value currently animating. Empty phase = no
    // active group → all players hold their resting positions for the beat.
    final activeGroup = _phaseGroups[_phaseIdx] ?? const [];

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
        // Sequential mode: stagger players within the phase so each runs
        // its leg one after another instead of all moving together.
        double mt = t;
        if (widget.sequentialMode && activeGroup.length > 1) {
          final j = activeGroup.indexWhere((e) => e.player.id == player.id);
          final k = activeGroup.length;
          mt = (t * k - j).clamp(0.0, 1.0);
        }
        if (_isBackward) {
          positions[player.id] = Offset.lerp(all[toIdx], all[fromIdx], mt)!;
        } else {
          positions[player.id] = Offset.lerp(all[fromIdx], all[toIdx], mt)!;
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
      // Stop once the scrubber's target step is reached (toStep), not just
      // at phase 0 — so a multi-step rewind lands where the user dragged.
      if (_singleStep || _phaseIdx < widget.toStep || _phaseIdx < 0) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => context.read<TacticsState>().finishAnimation());
      } else {
        _ctrl.forward(from: 0);
      }
    } else {
      _phaseIdx++;
      context.read<TacticsState>().advanceAtStep(_phaseIdx);
      // Forward runs stop at toStep (the scrubber target / maxMoveSteps).
      final endIdx =
          widget.toStep > 0 ? widget.toStep : (_maxPhase + 1);
      if (!_singleStep && _phaseIdx >= endIdx && widget.loop) {
        // Loop: jump back to the first phase and keep playing.
        _phaseIdx = 0;
        context.read<TacticsState>().advanceAtStep(0);
        _ctrl.forward(from: 0);
      } else if (_singleStep || _phaseIdx >= endIdx) {
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
            color: const Color(0xFF00C2B2).withValues(alpha: 0.85),
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
                            ? const Color(0xFF00C2B2)
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
                      ? const Color(0xFF00C2B2)
                      : (widget.isSelected ? Colors.yellow : Colors.white),
                  width: widget.isPrimary ? 3.5 : (widget.isSelected ? 3 : 2),
                ),
                boxShadow: [
                  if (widget.isPrimary)
                    BoxShadow(
                      color: const Color(0xFF00C2B2).withValues(alpha: 0.85),
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
      ..color = const Color(0xFF00C2B2).withValues(alpha: 0.10);
    canvas.drawRect(rect, fill);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF00C2B2);

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
