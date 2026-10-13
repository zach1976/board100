import 'dart:async';

import '../services/review_service.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../painters/soccer_court_painter.dart';
import '../models/court_layout.dart';
import '../models/player_icon.dart';
import '../models/player_photo.dart';
import '../models/player_role.dart';
import '../models/drawing_stroke.dart';
import '../models/sport_formation.dart';
import '../models/sport_type.dart';
import '../models/tactic_meta.dart';
import '../services/ad_service.dart';
import '../services/working_board_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/practice_service.dart';
import '../services/recent_boards_service.dart';
import '../services/drill_library_service.dart';
import '../models/drill_note.dart';
import '../services/sync_service.dart';
import '../widgets/player_icon_widget.dart'
    show
        boardFigureScaleFor,
        gTightFigureScale,
        kFigureScale,
        kPlayerIconBase,
        kPlayerIconSize;

class _BoardSnapshot {
  final List<PlayerIcon> players;
  final List<DrawingStroke> strokes;

  _BoardSnapshot({required this.players, required this.strokes});
}

/// Global key used to capture the board canvas as an image for sharing.
final GlobalKey boardRepaintKey = GlobalKey();

/// Global key for the offscreen landscape canvas used by external display.
final GlobalKey externalRepaintKey = GlobalKey();

class TacticsState extends ChangeNotifier {
  SportType _sportType;
  List<PlayerIcon> _players = [];
  List<DrawingStroke> _strokes = [];
  DrawingStroke? _currentStroke;

  // Undo / Redo stacks
  /// A board is a document of pages. The page being edited lives in
  /// [_players] / [_strokes] as it always has; the others sit here as the
  /// same JSON a saved board uses, and are swapped in and out on a page
  /// change. A routine is variations of one shape, which is what pages are
  /// for — a practice plan sequences whole drills across a session, and the
  /// two are different jobs.
  final List<Map<String, dynamic>> _otherPages = [];

  /// Where the live page sits among them. 0 on every board that has one page,
  /// which is every board saved before pages existed.
  int _pageIndex = 0;

  /// Undo history belongs to a page: undoing on page 2 must not reach into
  /// page 1. Parked here while another page is being edited.
  final Map<int, List<_BoardSnapshot>> _parkedUndo = {};
  final Map<int, List<_BoardSnapshot>> _parkedRedo = {};

  final List<_BoardSnapshot> _undoStack = [];
  final List<_BoardSnapshot> _redoStack = [];
  static const int _maxHistory = 50;

  // Drawing mode
  bool _isDrawingMode = false;
  StrokeStyle _strokeStyle = StrokeStyle.solid;
  ArrowStyle _arrowStyle = ArrowStyle.end;
  // Straight by default: a tactics board is mostly clean straight passing/run
  // arrows. Freehand/wavy stay one tap away in the line-style sheet.
  LineShape _lineShape = LineShape.straight;
  Color _strokeColor = const Color(0xFFFFD600);
  double _strokeWidth = 3.0;

  // Selected player
  String? _selectedPlayerId;
  // Specifically tapped waypoint index inside selected player's move chain.
  // null means the player body itself is the primary target (not a waypoint).
  int? _selectedWaypointIndex;

  // Multi-select — when on, taps on board players toggle membership in
  // [_multiSelectIds] instead of opening the per-player edit panel, and
  // panning any selected player drags the whole set as a unit. Mutually
  // exclusive with drawing mode.
  bool _multiSelectMode = false;
  final Set<String> _multiSelectIds = <String>{};
  // Strokes (drawn lines / arrows) selected via the same mode. Tracked
  // separately from player IDs to keep namespaces clean — both use
  // microsecond timestamps so a single set could collide.
  final Set<String> _multiSelectStrokeIds = <String>{};
  // Live rectangle drawn while the user lassos on empty canvas in
  // multi-select mode. Stored as start/end points (rather than a Rect)
  // so the drag direction is preserved if needed for the painter.
  Offset? _multiSelectRectStart;
  Offset? _multiSelectRectEnd;

  // Selected stroke
  String? _selectedStrokeId;

  // Canvas size — updated by TacticsCanvas via LayoutBuilder
  Size _canvasSize = const Size(400, 700);

  // Animation
  bool _isAnimating = false;
  Map<String, Offset> _animatedPositions = {};
  int _targetStep = 0; // 0 = all steps
  int _animFromStep = 0;
  int _animToStep = 0;
  int _atStep = 0; // which step players are currently at

  // Animation mode
  bool _sequentialMode = false;
  bool _showMoveLines = true;

  // UI state
  bool _toolbarVisible = true;
  final TransformationController transformationController = TransformationController();

  // Presentation mode — locks all editing, keeps playback. For showing the
  // board to players during a timeout without risking accidental edits.
  bool _presentationMode = false;

  // Explicit "add run" sub-mode — when on, taps on the board append move
  // waypoints to the selected player. Off by default so a stray tap on
  // empty canvas only deselects (never silently draws a run).
  bool _isAddingMove = false;

  // Eraser sub-mode (drawing mode only) — taps/drags delete strokes.
  bool _eraserMode = false;

  // Soccer-only pitch appearance (layout + grass colour). Persisted across
  // launches via SharedPreferences; a sticky visual preference, not part of a
  // saved tactic.
  SoccerFieldType _soccerFieldType = SoccerFieldType.full;
  int _soccerTurfIndex = 0;

  // Generic per-sport court appearance (non-soccer): surface colour index and
  // layout, keyed by SportType.index. Sticky visual prefs, persisted like the
  // soccer pitch settings; absent keys fall back to the defaults.
  final Map<int, int> _courtColorIndex = {};
  final Map<int, int> _courtLayoutIndex = {};

  // Free-form zoom/pan mode. While on, the board content is locked and the
  // InteractiveViewer owns every gesture — so its scale recogniser can never
  // fight a single-finger player drag. While off, the board carries no
  // InteractiveViewer at all (any existing zoom is applied statically).
  bool _zoomMode = false;

  // Animation playback options.
  double _animSpeed = 1.0; // 0.5 / 1.0 / 2.0
  bool _loopAnimation = false;

  // External display
  static const _extChannel = MethodChannel('com.zach.tacticsboard/externalDisplay');
  bool _externalConnected = false;
  bool _externalDirty = false;
  int _lastExtCaptureMs = 0;
  bool get externalDisplayConnected => _externalConnected;

  /// [preview] builds a throwaway board — a drill's detail page showing the
  /// real canvas rather than a picture of it. It must NOT claim the external
  /// display: the channel handler is static, so a second state registering
  /// one silently takes it off the live board and never gives it back.
  TacticsState({SportType sportType = SportType.basketball,
                bool preview = false})
      : _preview = preview,
        _sportType = sportType {
    if (!preview) _initExternalDisplay();
    _loadFieldPrefs();
  }

  /// A throwaway board — a thumbnail, a drill's detail page. It must never
  /// write over the coach's own board, which is exactly what it would do:
  /// the home page builds one of these from the real board every time it
  /// rebuilds.
  final bool _preview;
  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);
  bool _restoring = false;

  /// Put back the board the coach left, if there is one.
  ///
  /// Called once at startup. Silent when there is nothing stored, which is
  /// every first run and every sport the coach has not opened yet.
  Future<void> restoreWorkingBoard() async {
    final json = await WorkingBoardService.instance.load(_sportType);
    if (json == null) return;
    _restoring = true;
    try {
      loadFromJson(json);
      // Which board it is, not only what is on it. Without the name a board
      // the coach made and left empty came back as "no board" on the next
      // launch, and the home card stopped offering to open it.
      final name = json['currentName'];
      if (name is String && name.isNotEmpty) currentTacticName = name;
    } catch (_) {
      // A board from an older schema. Starting empty is the old behaviour,
      // and better than a crash on launch.
    } finally {
      _restoring = false;
    }
    notifyListeners();
  }

  void saveWorkingBoard() {
    if (_preview) return;
    _lastSave = DateTime.now();
    final payload = toJson();
    final name = currentTacticName;
    // Carried beside the board rather than inside toJson(): a saved .json is
    // named by its file, and writing the name into the document too would
    // give "save as" two answers to disagree about.
    if (name != null && name.isNotEmpty) payload['currentName'] = name;
    unawaited(WorkingBoardService.instance.save(_sportType, payload));
  }

  /// Write the board down on the way out.
  ///
  /// Two records, because they answer different questions. The working board
  /// is "what was on the screen", kept per sport so the app reopens where the
  /// coach left it — it is rate-limited while they draw, and this is the
  /// flush that the last second of dragging would otherwise miss, since
  /// walking back to the home page is not a pause and the pause handler
  /// never runs.
  ///
  /// The named file is "Board 1", and is written only when this board has a
  /// name. A drill loaded from the library clears that name on purpose, so
  /// leaving cannot write a drill's shape over a board the coach saved.
  Future<void> autosave() async {
    saveWorkingBoard();
    final name = currentTacticName;
    if (name == null || name.isEmpty) return;
    try {
      await saveTactics(name);
    } catch (_) {
      // A board that will not write is not a reason to block the way back to
      // the home page. The toolbar's own Save says so when they try there.
    }
  }

  void _initExternalDisplay() {
    _extChannel.setMethodCallHandler((call) async {
      if (call.method == 'externalDisplayStatus') {
        final args = call.arguments as Map?;
        _externalConnected = args?['connected'] == true;
        _externalDirty = true;
        notifyListeners();
      } else if (call.method == 'captureCanvas') {
        if (!_externalDirty) return null;
        // Throttle to ~15 fps — encoding a 2× PNG on every animation tick
        // is needlessly heavy for the external display.
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        if (nowMs - _lastExtCaptureMs < 66) return null;
        _lastExtCaptureMs = nowMs;
        try {
          await WidgetsBinding.instance.endOfFrame;
          _externalDirty = false;
          final boundary = externalRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
          if (boundary == null) return null;
          final image = await boundary.toImage(pixelRatio: 2.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          return byteData?.buffer.asUint8List();
        } catch (_) {
          return null;
        }
      }
    });
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _externalDirty = true;
    // Rate-limited rather than debounced: dragging a player notifies on
    // every frame, and a write a second is the difference between one and
    // sixty. A trailing timer would have been tidier, but a pending timer
    // fails every widget test that so much as builds this state — and the
    // board is written again when the app goes to the background, which is
    // the edit a rate limit would otherwise drop.
    if (_preview || _restoring) return;
    final now = DateTime.now();
    if (now.difference(_lastSave) < const Duration(seconds: 1)) return;
    saveWorkingBoard();
  }

  @override
  void dispose() {
    transformationController.dispose();
    super.dispose();
  }

  // Getters
  Size get canvasSize => _canvasSize;
  SportType get sportType => _sportType;
  List<PlayerIcon> get players => List.unmodifiable(_players);
  List<DrawingStroke> get strokes => List.unmodifiable(_strokes);
  DrawingStroke? get currentStroke => _currentStroke;
  bool get isDrawingMode => _isDrawingMode;
  StrokeStyle get strokeStyle => _strokeStyle;
  ArrowStyle get arrowStyle => _arrowStyle;
  LineShape get lineShape => _lineShape;
  Color get strokeColor => _strokeColor;
  double get strokeWidth => _strokeWidth;
  String? get selectedPlayerId => _selectedPlayerId;
  int? get selectedWaypointIndex => _selectedWaypointIndex;
  String? get selectedStrokeId => _selectedStrokeId;
  DrawingStroke? get selectedStroke => _selectedStrokeId == null ? null : _strokes.cast<DrawingStroke?>().firstWhere((s) => s?.id == _selectedStrokeId, orElse: () => null);
  bool get sequentialMode => _sequentialMode;
  bool get showMoveLines => _showMoveLines;
  bool get toolbarVisible => _toolbarVisible;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get isAnimating => _isAnimating;
  Map<String, Offset> get animatedPositions =>
      Map.unmodifiable(_animatedPositions);
  bool get hasMoves => _players.any((p) => p.moves.isNotEmpty) || _strokes.isNotEmpty;
  int get maxMoveSteps {
    // Range-based count: phases 0..maxPhase inclusive, so a gap in the
    // middle (e.g. {0,1,2,4,5,6} → max=6) still counts as 7 beats — the
    // empty slot is a deliberate "rest" in the timeline.
    int maxPhase = -1;
    for (final p in _players) {
      p.syncPhases();
      for (final ph in p.movePhases) {
        if (ph > maxPhase) maxPhase = ph;
      }
    }
    for (final s in _strokes) {
      if (!s.isFullSpan && s.endPhase > maxPhase) maxPhase = s.endPhase;
    }
    return maxPhase + 1;
  }
  int get targetStep => _targetStep;
  int get animFromStep => _animFromStep;
  int get animToStep => _animToStep;
  int get atStep => _atStep;

  void setTargetStep(int step) {
    _targetStep = step;
    notifyListeners();
  }

  // Animation
  void startAnimation() {
    if (_isAnimating) return;
    _animFromStep = 0;
    _animToStep = maxMoveSteps;
    _atStep = 0;
    _isAnimating = true;
    _animatedPositions = {};
    notifyListeners();
  }

  void stepForward() {
    if (_isAnimating) return;
    if (_atStep >= maxMoveSteps) return;
    _animFromStep = _atStep;
    _animToStep = _atStep + 1;
    _isAnimating = true;
    notifyListeners();
  }

  void stepBackward() {
    if (_isAnimating) return;
    if (_atStep <= 0) return;
    _animFromStep = _atStep;
    _animToStep = _atStep - 1;
    _isAnimating = true;
    notifyListeners();
  }

  /// Animate straight from the current step to [target] — used by the
  /// timeline scrubber. Plays through every intermediate phase.
  void animateToStep(int target) {
    if (_isAnimating) return;
    final t = target.clamp(0, maxMoveSteps);
    if (t == _atStep) return;
    _animFromStep = _atStep;
    _animToStep = t;
    _isAnimating = true;
    notifyListeners();
  }

  // Called as each animation step completes (to reveal lines incrementally)
  void advanceAtStep(int step) {
    _atStep = step;
    _syncDrillNote();
    notifyListeners();
  }

  // Called when animation finishes naturally — keep final positions
  void finishAnimation() {
    _isAnimating = false;
    _atStep = _animToStep >= 0 ? _animToStep : maxMoveSteps;
    _syncDrillNote();
    notifyListeners();
    // A play watched to its last step is a coach getting what he came for.
    if (!_preview && maxMoveSteps > 0 && _atStep >= maxMoveSteps) {
      unawaited(ReviewService.instance.onPositiveMoment('playback'));
    }
  }

  // Called by Stop button — also keep current positions
  void stopAnimation() {
    _isAnimating = false;
    notifyListeners();
  }

  // Clears the animated overlay (e.g. after user edits)
  void clearAnimatedPositions() {
    _resetAnimationState();
    notifyListeners();
  }

  /// Reset animation state silently (called before edit operations)
  void _resetAnimationState() {
    if (_isAnimating || _animatedPositions.isNotEmpty || _atStep > 0) {
      _isAnimating = false;
      _animatedPositions = {};
      _atStep = 0;
      // Back at the set-up, the note reads the first beat again. Without
      // this a drag that rewound the board left it saying beat three over
      // a board showing beat zero.
      _syncDrillNote();
    }
  }

  void updateAnimatedPositions(Map<String, Offset> positions) {
    _animatedPositions = positions;
    notifyListeners();
  }

  // ── Video export: precomputed animation frames ─────────────────────────────
  // Mirrors the on-screen forward interpolation (see _AnimationDriver._onTick)
  // as a pure function of the players' moves/phases, so the video export can
  // render deterministic frames without a live ticker.

  int get _animMaxPhase {
    int mx = -1;
    for (final p in _players) {
      p.syncPhases();
      for (int i = 0; i < p.moves.length; i++) {
        final ph = i < p.movePhases.length ? p.movePhases[i] : i;
        if (ph > mx) mx = ph;
      }
    }
    return mx;
  }

  /// Index into [position, ...moves] where a player rests at the start of
  /// [phaseValue] — only moves with a strictly-earlier phase have completed.
  int _restIndexAtPhase(PlayerIcon player, int phaseValue) {
    int last = -1;
    for (int i = 0; i < player.moves.length; i++) {
      final ph = i < player.movePhases.length ? player.movePhases[i] : i;
      if (ph < phaseValue && i > last) last = i;
    }
    return last + 1;
  }

  /// Every player/ball's position at animation phase [phaseIdx], progress [t].
  Map<String, Offset> animationPositionsAt(int phaseIdx, double t) {
    final positions = <String, Offset>{};
    for (final player in _players) {
      if (player.moves.isEmpty) continue;
      final all = [player.position, ...player.moves];
      int? moveIdx;
      for (int i = 0; i < player.moves.length; i++) {
        final ph = i < player.movePhases.length ? player.movePhases[i] : i;
        if (ph == phaseIdx) {
          moveIdx = i;
          break;
        }
      }
      if (moveIdx != null) {
        final fromIdx = moveIdx.clamp(0, all.length - 1);
        final toIdx = (moveIdx + 1).clamp(0, all.length - 1);
        positions[player.id] = Offset.lerp(all[fromIdx], all[toIdx], t)!;
      } else {
        final restIdx = _restIndexAtPhase(player, phaseIdx);
        if (restIdx > 0) positions[player.id] = all[restIdx.clamp(0, all.length - 1)];
      }
    }
    // Carried balls glue to their holder's live position.
    for (final ball in _players) {
      if (!ball.isBall || ball.attachedTo == null) continue;
      final hIdx = _players.indexWhere((p) => p.id == ball.attachedTo);
      if (hIdx < 0) continue;
      final holder = _players[hIdx];
      final hPos = positions[holder.id] ?? holder.position;
      positions[ball.id] = hPos + (ball.position - holder.position);
    }
    return positions;
  }

  /// The full forward animation as one position-map per frame — for video
  /// export. Empty when there are no moves to animate.
  List<Map<String, Offset>> computeAnimationFrames(
      {int fps = 30, double phaseSeconds = 0.8}) {
    final maxPhase = _animMaxPhase;
    if (maxPhase < 0) return const [];
    final perPhase = (phaseSeconds * fps).round().clamp(2, 240);
    final frames = <Map<String, Offset>>[];
    for (int phase = 0; phase <= maxPhase; phase++) {
      for (int f = 0; f < perPhase; f++) {
        final raw = perPhase == 1 ? 1.0 : f / (perPhase - 1);
        final t = Curves.easeInOut.transform(raw.clamp(0.0, 1.0));
        frames.add(animationPositionsAt(phase, t));
      }
    }
    return frames;
  }

  // Sport switching
  void setSportType(SportType type) {
    // The hub keeps one working board per sport. Switching used to clear the
    // players but keep the NAME, so the next sport's empty board autosaved
    // over the previous sport's saved board of that name. Park this sport's
    // board under its own key first, forget which board it was, and bring
    // back the new sport's own.
    final switching = type != _sportType;
    if (switching) saveWorkingBoard();
    currentTacticName = null;
    currentTacticMeta = null;
    drillBeats = const [];
    drillSetup = null;
    _figureScale = 1.0;
    gTightFigureScale = 1.0;
    _clearViewFrame();
    _isAnimating = false;
    _animatedPositions = {};
    _targetStep = 0;
    _atStep = 0;
    _animFromStep = 0;
    _animToStep = 0;
    _sportType = type;
    _players.clear();
    _strokes.clear();
    _undoStack.clear();
    _redoStack.clear();
    _selectedPlayerId = null;
    _selectedWaypointIndex = null;
    _isAddingMove = false;
    _zoomMode = false;
    notifyListeners();
    if (switching) unawaited(restoreWorkingBoard());
  }

  /// Default spawn Y position for a team, avoids court/table area
  double spawnY(PlayerTeam team) {
    switch (_sportType) {
      case SportType.tableTennis:
        return team == PlayerTeam.home ? _canvasSize.height * 0.90
             : team == PlayerTeam.away ? _canvasSize.height * 0.10
             : _canvasSize.height * 0.90;
      default:
        return team == PlayerTeam.home ? _canvasSize.height * 0.75
             : team == PlayerTeam.away ? _canvasSize.height * 0.25
             : _canvasSize.height * 0.60;
    }
  }

  /// Whether beat zero draws the whole plan. Off by default.
  ///
  /// The same reasoning setShowMoveLines already records for the drill page,
  /// applied to the board itself: beat zero showing every planned run at
  /// once is what an author wants while laying a drill out, and the opposite
  /// of what a reader wants — the first thing they see should be where
  /// everybody stands, not where everybody is going. Eight players' arrows
  /// crossing the centre circle is a knot, and it was the board's opening
  /// picture. The button turns it on; so does selecting one element, which
  /// draws that element's route and nobody else's.
  ///
  /// View state, not the document: it is not saved with the board, because
  /// it is about what this coach is looking at now.
  bool _showPlanAtStart = false;
  bool get showPlanAtStart => _showPlanAtStart;

  /// What the routes button is showing, which depends on the beat.
  ///
  /// Every control that draws this button has to ask the same question the
  /// button answers when tapped, or it lights up for a state it is not in.
  bool get routesOn =>
      (atStep == 0 && targetStep == 0) ? _showPlanAtStart : _showMoveLines;

  void toggleShowMoveLines() {
    // One button, one word — "routes" — and what that means depends on what
    // the board is showing. On beat zero the routes are the whole plan; on
    // any other beat they are that beat's legs, which is the beat itself and
    // stays on by default.
    if (atStep == 0 && targetStep == 0) {
      _showPlanAtStart = !_showPlanAtStart;
    } else {
      _showMoveLines = !_showMoveLines;
    }
    notifyListeners();
  }

  /// Show or hide the planned runs without it being a toggle the coach threw.
  ///
  /// The drill page uses this to keep the setup frame clean: the board shows
  /// every planned move at step 0, which is what an author wants when laying
  /// a drill out and the opposite of what a reader wants — the first thing
  /// they see should be where everybody stands, not where everybody is going.
  void setShowMoveLines(bool show) {
    if (_showMoveLines == show) return;
    _showMoveLines = show;
    notifyListeners();
  }

  void toggleSequentialMode() {
    _sequentialMode = !_sequentialMode;
    notifyListeners();
  }

  void toggleToolbar() {
    _toolbarVisible = !_toolbarVisible;
    notifyListeners();
  }

  // ── Presentation / sub-modes ─────────────────────────────────────────────
  bool get presentationMode => _presentationMode;
  void togglePresentationMode() {
    _presentationMode = !_presentationMode;
    // Keep presentation mode ad-free (the coach's "stage").
    if (_presentationMode) {
      AdService.instance.pushAdSuppression();
    } else {
      AdService.instance.popAdSuppression();
    }
    if (_presentationMode) {
      _isDrawingMode = false;
      _multiSelectMode = false;
      _multiSelectIds.clear();
      _multiSelectStrokeIds.clear();
      _isAddingMove = false;
      _eraserMode = false;
      _zoomMode = false;
      _selectedPlayerId = null;
      _selectedWaypointIndex = null;
      _selectedStrokeId = null;
    }
    notifyListeners();
  }

  bool get isAddingMove => _isAddingMove;
  void setAddingMove(bool v) {
    // Only meaningful with a player selected.
    if (v && _selectedPlayerId == null) return;
    if (_isAddingMove == v) return;
    _isAddingMove = v;
    notifyListeners();
  }

  bool get eraserMode => _eraserMode;
  void setEraserMode(bool v) {
    if (_eraserMode == v) return;
    _eraserMode = v;
    notifyListeners();
  }

  // ── Soccer pitch appearance ──────────────────────────────────────────────
  static const String _kSoccerFieldTypeKey = 'soccer_field_type';
  static const String _kSoccerTurfKey = 'soccer_turf_index';
  static const String _kCourtColorKey = 'court_color_index'; // "sportIdx:colorIdx,..."
  static const String _kCourtLayoutKey = 'court_layout_index';

  SoccerFieldType get soccerFieldType => _soccerFieldType;
  void setSoccerFieldType(SoccerFieldType type) {
    if (_soccerFieldType == type) return;
    _soccerFieldType = type;
    notifyListeners();
    _persistFieldPrefs();
  }

  int get soccerTurfIndex => _soccerTurfIndex;
  void setSoccerTurfIndex(int index) {
    if (index < 0 || index >= kSoccerTurfs.length || _soccerTurfIndex == index) {
      return;
    }
    _soccerTurfIndex = index;
    notifyListeners();
    _persistFieldPrefs();
  }

  SoccerTurf get soccerTurf => kSoccerTurfs[_soccerTurfIndex];

  /// True when the soccer board is showing a single-half layout, which lays
  /// out formations as one team attacking the lone goal (see [addTeamFromFormation]).
  bool get isSoccerHalfPitch =>
      _sportType == SportType.soccer && isSoccerHalfFieldType(_soccerFieldType);

  // ── Generic court appearance (non-soccer) ────────────────────────────────
  /// Selected surface-colour index for [sport] (clamped to its palette).
  int courtColorIndex(SportType sport) {
    final i = _courtColorIndex[sport.index] ?? 0;
    final n = sport.courtSurfaces.length;
    return n == 0 ? 0 : i.clamp(0, n - 1);
  }

  /// Resolved surface colour for [sport], or its painter default when the
  /// sport offers no colour choice.
  Color courtColor(SportType sport) {
    final surfaces = sport.courtSurfaces;
    return surfaces.isEmpty ? sport.courtColor : surfaces[courtColorIndex(sport)].color;
  }

  void setCourtColorIndex(SportType sport, int index) {
    if (courtColorIndex(sport) == index) return;
    _courtColorIndex[sport.index] = index;
    notifyListeners();
    _persistFieldPrefs();
  }

  /// Selected layout for [sport] (defaults to full, clamped to supported set).
  CourtLayout courtLayout(SportType sport) {
    final i = _courtLayoutIndex[sport.index];
    if (i == null || i < 0 || i >= CourtLayout.values.length) return CourtLayout.full;
    final layout = CourtLayout.values[i];
    return sport.courtLayouts.contains(layout) ? layout : CourtLayout.full;
  }

  void setCourtLayout(SportType sport, CourtLayout layout) {
    if (courtLayout(sport) == layout) return;
    _courtLayoutIndex[sport.index] = layout.index;
    notifyListeners();
    _persistFieldPrefs();
  }

  Future<void> _loadFieldPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ti = prefs.getInt(_kSoccerFieldTypeKey);
      if (ti != null && ti >= 0 && ti < SoccerFieldType.values.length) {
        _soccerFieldType = SoccerFieldType.values[ti];
      }
      final turf = prefs.getInt(_kSoccerTurfKey);
      if (turf != null && turf >= 0 && turf < kSoccerTurfs.length) {
        _soccerTurfIndex = turf;
      }
      _decodeIntMap(prefs.getString(_kCourtColorKey), _courtColorIndex);
      _decodeIntMap(prefs.getString(_kCourtLayoutKey), _courtLayoutIndex);
      notifyListeners();
    } catch (_) {
      // Prefs unavailable — keep defaults.
    }
  }

  Future<void> _persistFieldPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kSoccerFieldTypeKey, _soccerFieldType.index);
      await prefs.setInt(_kSoccerTurfKey, _soccerTurfIndex);
      await prefs.setString(_kCourtColorKey, _encodeIntMap(_courtColorIndex));
      await prefs.setString(_kCourtLayoutKey, _encodeIntMap(_courtLayoutIndex));
    } catch (_) {
      // Best-effort persistence.
    }
  }

  // Compact "k:v,k:v" encoding for the small per-sport int maps above.
  static String _encodeIntMap(Map<int, int> m) =>
      m.entries.map((e) => '${e.key}:${e.value}').join(',');

  static void _decodeIntMap(String? s, Map<int, int> into) {
    if (s == null || s.isEmpty) return;
    for (final pair in s.split(',')) {
      final kv = pair.split(':');
      if (kv.length != 2) continue;
      final k = int.tryParse(kv[0]), v = int.tryParse(kv[1]);
      if (k != null && v != null) into[k] = v;
    }
  }

  bool get zoomMode => _zoomMode;
  void toggleZoomMode() {
    _zoomMode = !_zoomMode;
    notifyListeners();
  }

  // ── Animation playback options ───────────────────────────────────────────
  double get animSpeed => _animSpeed;
  void setAnimSpeed(double v) {
    if (_animSpeed == v) return;
    _animSpeed = v;
    notifyListeners();
  }

  bool get loopAnimation => _loopAnimation;
  void toggleLoop() {
    _loopAnimation = !_loopAnimation;
    notifyListeners();
  }

  void resetZoom() {
    transformationController.value = Matrix4.identity();
    // Back to the full court is for good: a drill's half is not put back
    // on the next rotation once the coach has asked for the whole pitch.
    if (_viewFrame != null || _viewWindow != null || _frameZoom != 1.0) {
      // A note shrunk to read at the window's zoom is put back to its own
      // size, and — if nobody has moved it — under the court again.
      if (_viewWindow != null) {
        final i = _players.indexWhere((p) => p.id == kDrillNoteId);
        if (i >= 0 && _players[i].scale < 1.0) {
          _players[i] = _players[i].copyWith(scale: 1.0);
          if (notePlacedSideways != null) noteWanted = true;
        }
      }
      _viewFrame = null;
      _viewWindow = null;
      _frameZoom = 1.0;
      _frameAppliedFor = null;
      notifyListeners();
    }
  }

  // ── A drill's half ───────────────────────────────────────────────────────
  //
  // A free kick, a corner, a keeper's session: everything happens in one
  // half and the other is empty grass. The pack says which half ("frame",
  // tools/drills/engine.py frame_of) and the board opens zoomed to it — a
  // view only, through the same transform the zoom button uses, so the
  // coordinates are untouched and the zoom-reset circle is the one tap back
  // to the full court.

  /// "top", "bottom" or null.
  String? get viewFrame => _viewFrame;
  String? _viewFrame;

  /// How much the half is magnified. The figures are drawn this much
  /// smaller on the canvas so that on the screen they keep their size and
  /// the court around them is what grows (see TacticsCanvas).
  double get frameZoom => _frameZoom;
  double _frameZoom = 1.0;
  Size? _frameAppliedFor;

  /// A drill's own close-up ("viewWindow" in the board JSON: a lineout drawn
  /// at Law 18's spacing, which at the whole pitch's scale is one row of
  /// figures on top of each other). Kept as fractions of the court, so it
  /// follows the court onto any canvas the way the players do.
  Rect? get viewWindow => _viewWindow;
  Rect? _viewWindow;

  /// The half (or the window) has not been laid out for this canvas yet.
  bool get frameNeedsApply =>
      (_viewFrame != null || _viewWindow != null) &&
      _frameAppliedFor != _canvasSize;

  /// The canvas rectangle the half occupies — the share of the generator's
  /// 400x700 canvas engine.FRAME_VIEW (0.60) names, carried onto this
  /// canvas through the court the way a drill's coordinates are.
  Rect? viewFrameWindow() {
    final vw = _viewWindow;
    if (vw != null && !_canvasSize.isEmpty) {
      final c = _sportType.fieldRect(_canvasSize);
      if (c.isEmpty) return null;
      return Rect.fromLTRB(
              c.left + vw.left * c.width,
              c.top + vw.top * c.height,
              c.left + vw.right * c.width,
              c.top + vw.bottom * c.height)
          .intersect(Offset.zero & _canvasSize);
    }
    final f = _viewFrame;
    if (f == null || _canvasSize.isEmpty) return null;
    const ref = Size(400, 700);
    const share = 0.60;
    final from = _sportType.fieldRect(ref);
    final to = _sportType.fieldRect(_canvasSize);
    if (from.isEmpty || to.isEmpty) return null;
    final sx = to.width / from.width, sy = to.height / from.height;
    Offset map(Offset p) => Offset(
        to.left + (p.dx - from.left) * sx, to.top + (p.dy - from.top) * sy);
    final win = f == 'bottom'
        ? Rect.fromPoints(map(Offset(0, ref.height * (1 - share))),
            map(Offset(ref.width, ref.height)))
        : Rect.fromPoints(map(Offset.zero), map(Offset(ref.width, ref.height * share)));
    return win.intersect(Offset.zero & _canvasSize);
  }

  /// Zoom the view to the drill's half, keeping the step note in it.
  void applyViewFrame() {
    final win0 = viewFrameWindow();
    if (win0 == null) return;
    _frameAppliedFor = _canvasSize;
    var win = win0;
    final note = _players.where((p) => p.id == kDrillNoteId).firstOrNull;
    // A window's note is placed inside the view at the window's zoom (see
    // placeDrillNote), so it does not widen the window.
    if (note != null && _viewWindow == null) {
      // Its chip, generously: the note is the one thing on the board that
      // must be readable at every beat.
      win = win.expandToInclude(Rect.fromCenter(
          center: note.position,
          width: _noteExtent.width + 12,
          height: _noteExtent.height + 12));
    }
    final w = _canvasSize.width, h = _canvasSize.height;
    final z = _frameZoomFor(win);
    if (z < 1.05) {
      _frameZoom = 1.0;
      transformationController.value = Matrix4.identity();
      notifyListeners();
      return;
    }
    // The window's middle in the middle of the screen, but never past the
    // canvas's edge: no blank beyond the board.
    final tx = (w / 2 - z * win.center.dx).clamp(w - z * w, 0.0);
    final ty = (h / 2 - z * win.center.dy).clamp(h - z * h, 0.0);
    _frameZoom = z.toDouble();
    transformationController.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(_frameZoom, _frameZoom, 1, 1);
    notifyListeners();
  }

  /// How far [win] can be magnified and still fit the canvas. Under 1.05
  /// — a pitch on a phone, fitted by its width, whose half cannot grow
  /// without losing its touchlines — the board is left as it is.
  ///
  /// A drill's own window may be magnified further than a half: it is
  /// drawn for it (tools/drills/engine.py VIEW_ZOOM_MAX — keep the two equal).
  double _frameZoomFor(Rect win) => math
      .min(_canvasSize.width / win.width, _canvasSize.height / win.height)
      .clamp(1.0, _viewWindow != null ? 8.0 : 3.0)
      .toDouble();

  /// The part of the canvas the screen shows at zoom [z] centred on [win] —
  /// the translation [applyViewFrame] sets, read back.
  Rect _visibleFor(Rect win, double z) {
    final w = _canvasSize.width, h = _canvasSize.height;
    final tx = (w / 2 - z * win.center.dx).clamp(w - z * w, 0.0);
    final ty = (h / 2 - z * win.center.dy).clamp(h - z * h, 0.0);
    return Rect.fromLTWH(-tx / z, -ty / z, w / z, h / z);
  }

  /// The note chip's size on the canvas, as [placeDrillNote] measured it.
  Size _noteExtent = const Size(60, 60);

  /// Drop any half the last board was zoomed to, quietly (from a load).
  void _clearViewFrame() {
    if (_viewFrame == null && _viewWindow == null && _frameZoom == 1.0) return;
    _viewFrame = null;
    _viewWindow = null;
    _frameZoom = 1.0;
    _frameAppliedFor = null;
    transformationController.value = Matrix4.identity();
  }

  /// The board's own figure size: 1.0, or the generator's tight figure for
  /// a scrum, a wall, a lineout ("figureScale" in the board JSON — see
  /// TIGHT_FIGURE_SCALE in tools/drills/engine.py). Kept with the board.
  double get figureScale => _figureScale;
  double _figureScale = 1.0;

  // Drawing mode
  void setDrawingMode(bool enabled) {
    _isDrawingMode = enabled;
    _selectedPlayerId = null;
    _selectedWaypointIndex = null;
    _isAddingMove = false;
    if (enabled) {
      _multiSelectMode = false;
      _multiSelectIds.clear();
    } else {
      _eraserMode = false;
    }
    notifyListeners();
  }

  // Multi-select mode — toggleable from the top mode segment. When on,
  // tapping a player toggles its inclusion in [_multiSelectIds] (and the
  // edit panel does not open), and panning any included player translates
  // every member of the set together.
  bool get multiSelectMode => _multiSelectMode;
  Set<String> get multiSelectIds => Set.unmodifiable(_multiSelectIds);
  Set<String> get multiSelectStrokeIds =>
      Set.unmodifiable(_multiSelectStrokeIds);
  bool get hasMultiSelection =>
      _multiSelectIds.isNotEmpty || _multiSelectStrokeIds.isNotEmpty;

  void setMultiSelectMode(bool enabled) {
    if (_multiSelectMode == enabled) return;
    _multiSelectMode = enabled;
    if (enabled) {
      _isDrawingMode = false;
      _selectedPlayerId = null;
      _selectedWaypointIndex = null;
      _isAddingMove = false;
    } else {
      _multiSelectIds.clear();
      _multiSelectStrokeIds.clear();
    }
    notifyListeners();
  }

  void toggleMultiSelectId(String id) {
    if (_multiSelectIds.contains(id)) {
      _multiSelectIds.remove(id);
    } else {
      _multiSelectIds.add(id);
    }
    notifyListeners();
  }

  void toggleMultiSelectStroke(String id) {
    if (_multiSelectStrokeIds.contains(id)) {
      _multiSelectStrokeIds.remove(id);
    } else {
      _multiSelectStrokeIds.add(id);
    }
    notifyListeners();
  }

  void clearMultiSelect() {
    if (_multiSelectIds.isEmpty && _multiSelectStrokeIds.isEmpty) return;
    _multiSelectIds.clear();
    _multiSelectStrokeIds.clear();
    notifyListeners();
  }

  /// Bulk-set the multi-select to exactly [playerIds] and enter multi-
  /// select mode. Used after batch-adds (formation / photo group) so the
  /// just-added players can be dragged as a group without re-selecting.
  void enterMultiSelectWith(Iterable<String> playerIds) {
    _multiSelectMode = true;
    _selectedPlayerId = null;
    _selectedWaypointIndex = null;
    _multiSelectIds
      ..clear()
      ..addAll(playerIds);
    _multiSelectStrokeIds.clear();
    notifyListeners();
  }

  /// Translate every member of the multi-select set by [delta], clamped
  /// per-player to the canvas bounds. Strokes (arrows / drawings) in the
  /// set are translated by the same delta so the whole selection moves
  /// as one. Caller invokes [moveMultiSelectEnd] when the gesture
  /// finishes so the snapshot is pushed once for the whole drag.
  void moveMultiSelectBy(Offset delta) {
    if (_multiSelectIds.isEmpty && _multiSelectStrokeIds.isEmpty) return;
    final w = _canvasSize.width;
    final h = _canvasSize.height;
    bool changed = false;
    for (int i = 0; i < _players.length; i++) {
      if (!_multiSelectIds.contains(_players[i].id)) continue;
      final p = _players[i];
      final next = Offset(
        (p.position.dx + delta.dx).clamp(0.0, w),
        (p.position.dy + delta.dy).clamp(0.0, h),
      );
      _players[i] = p.copyWith(position: next);
      changed = true;
    }
    for (int i = 0; i < _strokes.length; i++) {
      if (!_multiSelectStrokeIds.contains(_strokes[i].id)) continue;
      final s = _strokes[i];
      _strokes[i] = s.copyWith(
        points: s.points.map((p) => p + delta).toList(),
      );
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void moveMultiSelectEnd() {
    if (_multiSelectIds.isEmpty && _multiSelectStrokeIds.isEmpty) return;
    _saveSnapshot();
    _resetAnimationState();
  }

  /// Live rectangle being drawn for the lasso (null while no drag is in
  /// progress). Canvas painter reads this and renders the dashed outline.
  Rect? get multiSelectDragRect {
    if (_multiSelectRectStart == null || _multiSelectRectEnd == null) {
      return null;
    }
    return Rect.fromPoints(_multiSelectRectStart!, _multiSelectRectEnd!);
  }

  void beginMultiSelectRect(Offset start) {
    _multiSelectRectStart = start;
    _multiSelectRectEnd = start;
    notifyListeners();
  }

  void updateMultiSelectRect(Offset cur) {
    if (_multiSelectRectStart == null) return;
    _multiSelectRectEnd = cur;
    notifyListeners();
  }

  /// Commit the lasso: union every player whose position falls inside
  /// the live rectangle, AND every drawing stroke (arrow / freehand)
  /// that intersects it, into the multi-select sets, then clear the
  /// rect. A degenerate (essentially zero-area) drag clears the rect
  /// without changing the sets, so the user can abort by releasing in
  /// place.
  void endMultiSelectRect() {
    final rect = multiSelectDragRect;
    _multiSelectRectStart = null;
    _multiSelectRectEnd = null;
    if (rect == null) return;
    if (rect.width < 4 && rect.height < 4) {
      notifyListeners();
      return;
    }
    for (final p in _players) {
      if (rect.contains(p.position)) _multiSelectIds.add(p.id);
    }
    // Strokes — include if any of their points falls inside the rect.
    // "Any point in" is more forgiving than "all in" for long arrows
    // that the user partly lassos; matches typical drawing-app behaviour.
    for (final s in _strokes) {
      for (final pt in s.points) {
        if (rect.contains(pt)) {
          _multiSelectStrokeIds.add(s.id);
          break;
        }
      }
    }
    notifyListeners();
  }

  void setStrokeStyle(StrokeStyle style) {
    _strokeStyle = style;
    notifyListeners();
  }

  void setArrowStyle(ArrowStyle style) {
    _arrowStyle = style;
    notifyListeners();
  }

  void setLineShape(LineShape shape) {
    _lineShape = shape;
    notifyListeners();
  }

  void setStrokeColor(Color color) {
    _strokeColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  // Player management
  /// The last element copied off the board, whole: its kit and number, its
  /// size, the way it faces, and the run it was given.
  ///
  /// Held on the state, not on a page, because across pages is what it is
  /// for — a coach builds the next beat of a move by putting the same
  /// player, with the same path, on the next page.
  PlayerIcon? _copied;
  PlayerIcon? get copied => _copied;

  void copyPlayer(String id) {
    final p = _players.where((x) => x.id == id).firstOrNull;
    if (p == null) return;
    // copyWith copies the move lists rather than sharing them: editing the
    // original's run afterwards must not rewrite what was copied.
    _copied = p.copyWith();
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  /// Put the copy on the board and return its new id, or null with nothing
  /// copied.
  ///
  /// It lands where it was taken from — on another page that spot is empty
  /// and it is exactly where the coach wants it. Only when something is
  /// already standing there does it step aside, which is what makes
  /// pasting twice on one page read as two players.
  String? pastePlayer() {
    final src = _copied;
    if (src == null) return null;
    var pos = src.position;
    const minDist = 31.0; // a token is 36pt: closer than this is a pile
    for (var i = 0; i < 12; i++) {
      final taken = _players.any((p) => (p.position - pos).distance < minDist);
      if (!taken) break;
      pos += const Offset(22, 22);
    }
    final c = canvasSize;
    if (c.width > 0 && c.height > 0) {
      pos = Offset(pos.dx.clamp(18.0, c.width - 18.0),
          pos.dy.clamp(18.0, c.height - 18.0));
    }
    final shift = pos - src.position;
    final id = 'p${DateTime.now().microsecondsSinceEpoch}';
    addPlayer(src.copyWith(
      id: id,
      position: pos,
      moves: [for (final m in src.moves) m + shift],
      movePhases: List.of(src.movePhases),
      // Whoever was carrying it is on the page it came from. A ball that
      // arrives still attached to an id nothing on this board has would
      // follow nobody and sit there for good.
      clearAttachedTo: true,
    ));
    return id;
  }

  void addPlayer(PlayerIcon player) {
    _saveSnapshot();
    _resetAnimationState();
    _players.add(player.copyWith(
      moveColor: PlayerIcon.moveColorForIndex(_players.length),
    ));
    // Auto-switch to move mode and select the new player
    _isDrawingMode = false;
    _selectedPlayerId = _players.last.id;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void movePlayer(String id, Offset newPosition) {
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    final delta = newPosition - _players[idx].position;
    _players[idx] = _players[idx].copyWith(position: newPosition);
    // A carried ball rides along with its holder, keeping its relative offset.
    if (!_players[idx].isBall) {
      for (int i = 0; i < _players.length; i++) {
        if (_players[i].attachedTo == id) {
          _players[i] = _players[i].copyWith(position: _players[i].position + delta);
        }
      }
    }
    notifyListeners();
  }

  /// Nearest real player (not a ball or marker) within [radius] px of [point],
  /// used to decide which player a dropped ball attaches to.
  PlayerIcon? _nearestPlayerTo(Offset point, {required String excludeId, double radius = 50}) {
    PlayerIcon? best;
    double bestDist = radius;
    for (final p in _players) {
      if (p.id == excludeId || p.isBall || p.isMarker) continue;
      final d = (p.position - point).distance;
      if (d <= bestDist) {
        bestDist = d;
        best = p;
      }
    }
    return best;
  }

  void resizePlayer(String id, double newScale) {
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    _players[idx] = _players[idx].copyWith(scale: newScale.clamp(0.5, 3.0));
    notifyListeners();
  }

  void resizePlayerEnd(String id) {
    _saveSnapshot();
  }

  /// Turn an element. [radians] is absolute, clockwise from as-drawn.
  ///
  /// Snapped to 15 degrees while it is being turned: a diagram with a
  /// hurdle three degrees off does not read as three degrees off, it reads
  /// as drawn carelessly. Within three degrees of a quarter turn it snaps
  /// there exactly, because square to the pitch is the answer most of the
  /// time.
  void rotatePlayer(String id, double radians) {
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    final p = _players[idx];
    // A person is drawn from eight pictures, so a turn between two of them
    // shows nothing; snap to the one it will show. Markers turn freely.
    // The referee and the coach are drawn as people, and turn as people.
    final picture = p.isBall || (p.isMarker && !p.isPersonMarker);
    final snapped = picture ? snapAngle(radians) : snapFacing(radians);
    // Turning a person by hand is a decision about where they look, and it
    // has to survive the board's own facing rule — which otherwise recomputes
    // a heading every beat and throws the turn away. Back at zero the coach
    // has taken the decision back: the bar's reset lands here, and the board
    // takes over again.
    _players[idx] = p.copyWith(
        rotation: snapped,
        facingLocked: picture ? false : snapped != 0);
    notifyListeners();
  }

  /// Nearest eighth of a turn — the headings a figure has pictures for.
  static double snapFacing(double radians) {
    const step = math.pi / 4;
    return (radians / step).roundToDouble() * step;
  }

  void rotatePlayerEnd(String id) {
    _saveSnapshot();
  }

  /// Nearest 15 degrees, and exactly square when it is close to square.
  static double snapAngle(double radians) {
    const step = math.pi / 12; // 15 degrees
    const quarter = math.pi / 2;
    final toQuarter = (radians / quarter).roundToDouble() * quarter;
    if ((radians - toQuarter).abs() < 0.052) return toQuarter; // ~3 degrees
    return (radians / step).roundToDouble() * step;
  }

  void movePlayerEnd(String id, Offset newPosition) {
    _saveSnapshot();
    // Moving the note is not a change to the play; see updatePlayer.
    if (id != kDrillNoteId) _resetAnimationState();
    // Where the coach put it is where it stays, whichever way up.
    if (id == kDrillNoteId) notePlacedSideways = null;
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    var updated = _players[idx].copyWith(position: newPosition);
    // Dropping a ball onto a player gives that player possession; dropping it
    // in open space releases it.
    if (updated.isBall) {
      final holder = _nearestPlayerTo(newPosition, excludeId: id);
      updated = holder != null
          ? updated.copyWith(attachedTo: holder.id)
          : updated.copyWith(clearAttachedTo: true);
    }
    _players[idx] = updated;
    notifyListeners();
  }

  void updatePlayer(String id, {String? label, Color? customColor, bool clearCustomColor = false, double? scale, PlayerTeam? team, PlayerGender? gender, bool? holdsImplement, bool clearHolds = false, String? photoId, bool clearPhotoId = false, String? font, bool clearFont = false, MarkerShape? markerShape}) {
    // The note is not part of the play, so writing on it does not throw the
    // board back to the set-up the way every other edit does — and the beat
    // it is standing on is the beat the new words belong to.
    final note = id == kDrillNoteId;
    if (!note) _resetAnimationState();
    if (note && label != null && drillBeats.isNotEmpty) {
      final step = (_atStep < 1 ? 1 : _atStep).clamp(1, drillBeats.length);
      final next = [...drillBeats];
      next[step - 1] = label;
      drillBeats = next;
    }
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    _saveSnapshot();
    _players[idx] = _players[idx].copyWith(
      label: label,
      team: team,
      customColor: customColor,
      clearCustomColor: clearCustomColor,
      scale: scale,
      gender: gender,
      holdsImplement: holdsImplement,
      clearHolds: clearHolds,
      photoId: photoId,
      font: font,
      clearFont: clearFont,
      clearPhotoId: clearPhotoId,
      markerShape: markerShape,
    );
    notifyListeners();
  }

  /// A tap has asked for an element's words to be edited.
  ///
  /// The dialog belongs to the edit bar, which is a different widget from
  /// the board the tap landed on, so the request is left here for it to
  /// pick up and clear. Tapping a text element that is already selected is
  /// what sets it: the alternative — a second tap putting the selection
  /// away again — closed the very panel the coach had just dragged into
  /// place.
  String? labelEditRequest;

  void requestLabelEdit(String id) {
    labelEditRequest = id;
    notifyListeners();
  }

  void clearLabelEditRequest() => labelEditRequest = null;

  void removePlayer(String id) {
    _saveSnapshot();
    _resetAnimationState();
    _players.removeWhere((p) => p.id == id);
    // Release any ball that was carried by the removed player.
    for (int i = 0; i < _players.length; i++) {
      if (_players[i].attachedTo == id) {
        _players[i] = _players[i].copyWith(clearAttachedTo: true);
      }
    }
    if (_selectedPlayerId == id) {
      _selectedPlayerId = null;
      _selectedWaypointIndex = null;
    }
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  // Player move waypoints
  void addPlayerMove(String id, Offset position) {
    _resetAnimationState();
    _showMoveLines = true;
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    _saveSnapshot();
    final clamped = _clampToCanvas(_clampToSide(_players[idx], position));
    final updated = List.of(_players[idx].moves)..add(clamped);
    _players[idx] = _players[idx].copyWith(moves: updated);
    // Default: each player's phases run 0,1,2… independently. So multiple
    // players each laying a single run start TOGETHER on phase 0; the
    // timeline editor is where the user manually pulls them apart.
    _players[idx].syncPhases();
    notifyListeners();
  }

  void movePlayerWaypoint(String id, int index, Offset position) {
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    final updated = List.of(_players[idx].moves);
    if (index >= updated.length) return;
    updated[index] = _clampToCanvas(_clampToSide(_players[idx], position));
    _players[idx] = _players[idx].copyWith(moves: updated);
    notifyListeners();
  }

  /// Keep a point inside the canvas so it always remains reachable/editable.
  Offset _clampToCanvas(Offset position) {
    if (_canvasSize.width <= 0 || _canvasSize.height <= 0) return position;
    const margin = 8.0;
    return Offset(
      position.dx.clamp(margin, _canvasSize.width - margin),
      position.dy.clamp(margin, _canvasSize.height - margin),
    );
  }

  /// For net sports, clamp move position so players stay on their side of the net.
  Offset _clampToSide(PlayerIcon player, Offset position) {
    if (!_sportType.hasNet) return position;
    // Table tennis players move freely around the table — no side restriction.
    if (_sportType == SportType.tableTennis) return position;
    if (player.team == PlayerTeam.neutral) return position;
    final netPixelY = _sportType.netY * _canvasSize.height;
    const margin = 16.0; // keep a small gap from the net
    if (player.team == PlayerTeam.home) {
      // Home team is on the bottom half
      return Offset(position.dx, position.dy.clamp(netPixelY + margin, _canvasSize.height));
    } else {
      // Away team is on the top half
      return Offset(position.dx, position.dy.clamp(0.0, netPixelY - margin));
    }
  }

  void movePlayerWaypointEnd(String id) {
    _saveSnapshot();
    _resetAnimationState();
  }

  void removePlayerWaypoint(String id, int index) {
    _resetAnimationState();
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    _saveSnapshot();
    final updatedMoves = List.of(_players[idx].moves)..removeAt(index);
    final updatedPhases = List.of(_players[idx].movePhases);
    if (index < updatedPhases.length) updatedPhases.removeAt(index);
    _players[idx] = _players[idx].copyWith(moves: updatedMoves, movePhases: updatedPhases);
    // Don't call syncPhases — preserve original phase numbers
    notifyListeners();
  }

  void setMovePhase(String playerId, int moveIndex, int phase) {
    final idx = _players.indexWhere((p) => p.id == playerId);
    if (idx < 0) return;
    final phases = List.of(_players[idx].movePhases);
    if (moveIndex >= phases.length) return;
    int newPhase = phase.clamp(0, 99).toInt();
    // Same-player waypoints must stay in path order — moveIdx 0 → 1 → 2 in
    // time. Clamp so a block can never jump past its neighbours on the
    // same player's chain (otherwise "2" could land after "3", which is
    // physically impossible).
    if (moveIndex > 0) {
      final lower = phases[moveIndex - 1] + 1;
      if (newPhase < lower) newPhase = lower;
    }
    if (moveIndex < phases.length - 1) {
      final upper = phases[moveIndex + 1] - 1;
      if (newPhase > upper) newPhase = upper;
    }
    if (phases[moveIndex] == newPhase) return; // no-op
    _resetAnimationState();
    _saveSnapshot();
    phases[moveIndex] = newPhase;
    _players[idx] = _players[idx].copyWith(movePhases: phases);
    notifyListeners();
  }

  /// Apply many phase changes in a single snapshot. Rejects the whole bulk
  /// if applying it would put any player's waypoints out of path order.
  void setMovePhasesBulk(
      List<({String playerId, int moveIndex, int phase})> changes) {
    if (changes.isEmpty) return;
    // Build the proposed final phases per affected player.
    final byPlayer = <String, List<int>>{};
    for (final c in changes) {
      final idx = _players.indexWhere((p) => p.id == c.playerId);
      if (idx < 0) continue;
      byPlayer.putIfAbsent(c.playerId, () => List.of(_players[idx].movePhases));
    }
    for (final c in changes) {
      final p = byPlayer[c.playerId];
      if (p == null || c.moveIndex >= p.length) continue;
      p[c.moveIndex] = c.phase.clamp(0, 99).toInt();
    }
    // Validate: same-player phases must be strictly increasing (path order).
    for (final p in byPlayer.values) {
      for (int i = 1; i < p.length; i++) {
        if (p[i] <= p[i - 1]) return; // reject — would cross neighbours
      }
    }
    _resetAnimationState();
    _saveSnapshot();
    for (final entry in byPlayer.entries) {
      final idx = _players.indexWhere((p) => p.id == entry.key);
      if (idx < 0) continue;
      _players[idx] = _players[idx].copyWith(movePhases: entry.value);
    }
    notifyListeners();
  }

  /// Total number of distinct phases across all players and strokes
  int get maxPhase {
    int max = 0;
    for (final p in _players) {
      p.syncPhases();
      for (final ph in p.movePhases) {
        if (ph > max) max = ph;
      }
    }
    for (final s in _strokes) {
      if (s.endPhase > max) max = s.endPhase;
    }
    return max;
  }

  void selectPlayer(String? id) {
    final changed = _selectedPlayerId != id;
    _selectedPlayerId = id;
    // A request to edit some OTHER element's words is stale the moment the
    // selection moves off it; left behind, it would pop the dialog open
    // the next time that element was selected.
    if (labelEditRequest != null && labelEditRequest != id) {
      labelEditRequest = null;
    }
    _selectedWaypointIndex = null;
    if (id != null) _selectedStrokeId = null;
    // Leaving a player always exits the explicit add-run sub-mode, so a
    // later tap on empty canvas can't append a stray waypoint.
    if (id == null) _isAddingMove = false;
    if (id != null && changed) HapticFeedback.selectionClick();
    notifyListeners();
  }

  /// Primary-select a specific waypoint within a player's move chain.
  /// Pass index=null to clear waypoint-level selection (player body is primary).
  void selectPlayerWaypoint(String id, int? index) {
    _selectedPlayerId = id;
    _selectedWaypointIndex = index;
    _selectedStrokeId = null;
    notifyListeners();
  }

  void setCanvasSize(Size size) {
    if (_canvasSize == size) return;
    _rescalePlayers(size);
    _canvasSize = size;
    notifyListeners();
  }

  /// Update canvas size without notifying listeners (avoids rebuild loops)
  void setCanvasSizeSilent(Size size) {
    if (_canvasSize == size) return;
    _rescalePlayers(size);
    _canvasSize = size;
  }

  /// Carry everything on the board to the same place on the COURT when the
  /// canvas changes shape.
  ///
  /// Scaling by the canvas was right only while every canvas had roughly the
  /// authored shape. The court is centred inside the canvas at its own fixed
  /// aspect (see [SportType.fieldRect]), so how much of the canvas it takes
  /// depends on the canvas: a basketball board is fitted by height on a phone
  /// and by width in a Mac window turned sideways, where the baseline sits a
  /// tenth of the way down instead of a twentieth. Scaling the men by the
  /// canvas moved them with the window and left the lines where they were —
  /// a layup finished with the ball past the end line and the shooter
  /// standing on the rim.
  void _rescalePlayers(Size size) {
    if (_canvasSize.width > 0 && _canvasSize.height > 0 && _players.isNotEmpty) {
      final from = _sportType.fieldRect(_canvasSize);
      final to = _sportType.fieldRect(size);
      if (from.width <= 0 || from.height <= 0) return;
      final sx = to.width / from.width;
      final sy = to.height / from.height;
      Offset map(Offset p) => Offset(
          to.left + (p.dx - from.left) * sx, to.top + (p.dy - from.top) * sy);
      for (final p in _players) {
        p.position = map(p.position);
        p.moves = p.moves.map(map).toList();
      }
      // The step the board is stopped on is drawn from here, not from
      // p.position — so a board turned sideways in the middle of a drill
      // rescaled the arrows and left the men standing at their old canvas
      // coordinates, which on a volleyball court put three of them on the
      // net with their arrows ending short of their feet.
      if (_animatedPositions.isNotEmpty) {
        _animatedPositions =
            _animatedPositions.map((id, at) => MapEntry(id, map(at)));
      }
      // The drill's note is a chip of a fixed size, not a point on the
      // court. Everything else grows with the court; the note's margin
      // SHRINKS as the court takes the card, and at full screen it went off
      // the edge with its last line cut off. Keep it on the card.
      final n = _players.indexWhere((p) => p.id == kDrillNoteId);
      if (n >= 0) {
        const edge = 26.0;
        final at = _players[n].position;
        _players[n].position = Offset(
          at.dx.clamp(edge, math.max(edge, size.width - edge)),
          at.dy.clamp(edge, math.max(edge, size.height - edge)),
        );
      }
    }
  }

  void applyFormation(SportFormation formation, {List<PlayerGender>? homeGenders, List<PlayerGender>? awayGenders}) {
    _saveSnapshot();
    _resetAnimationState();
    _players.clear();
    _selectedPlayerId = null;
    _selectedWaypointIndex = null;
    // Map formation coords against the painted field rect so players stay
    // inside the sidelines on any canvas aspect (iPad portrait in particular).
    final field = _sportType.fieldRect(_canvasSize);
    Offset toPos(Offset rel) =>
        Offset(field.left + rel.dx * field.width, field.top + rel.dy * field.height);
    int homeNum = 1;
    int awayNum = 1;
    int colorIdx = 0;
    for (int i = 0; i < formation.homePositions.length; i++) {
      _players.add(PlayerIcon(
        id: '${DateTime.now().microsecondsSinceEpoch}_h$homeNum',
        label: '$homeNum',
        team: PlayerTeam.home,
        gender: homeGenders != null && i < homeGenders.length ? homeGenders[i] : PlayerGender.unspecified,
        position: toPos(formation.homePositions[i]),
        moveColor: PlayerIcon.moveColorForIndex(colorIdx++),
      ));
      homeNum++;
    }
    for (int i = 0; i < formation.awayPositions.length; i++) {
      _players.add(PlayerIcon(
        id: '${DateTime.now().microsecondsSinceEpoch}_a$awayNum',
        label: '$awayNum',
        team: PlayerTeam.away,
        gender: awayGenders != null && i < awayGenders.length ? awayGenders[i] : PlayerGender.unspecified,
        position: toPos(formation.awayPositions[i]),
        moveColor: PlayerIcon.moveColorForIndex(colorIdx++),
      ));
      awayNum++;
    }
    _isDrawingMode = false;
    // Auto-enter multi-select with every just-added player, so the user
    // can drag the whole formation as one to position it on the field
    // without re-selecting.
    _multiSelectMode = true;
    _multiSelectIds
      ..clear()
      ..addAll(_players.map((p) => p.id));
    _multiSelectStrokeIds.clear();
    notifyListeners();
  }

  /// Maps a formation's relative slot coordinates onto the canvas for [team].
  ///
  /// On a single-half soccer pitch the formation is laid out as one team
  /// attacking the lone goal: goalkeeper by the goal end, the most advanced
  /// player by the halfway line. Depth is normalised across the team so the
  /// shape fills the visible half regardless of its full-pitch coordinates.
  Offset Function(Offset) _slotMapper(
      List<Offset> positions, PlayerTeam team, Rect field) {
    final half = isSoccerHalfPitch;
    double minDy = double.infinity, maxDy = -double.infinity;
    if (half) {
      for (final r in positions) {
        if (r.dy < minDy) minDy = r.dy;
        if (r.dy > maxDy) maxDy = r.dy;
      }
    }
    final span = (maxDy - minDy).abs() < 1e-6 ? 1.0 : (maxDy - minDy);
    return (Offset rel) {
      if (half) {
        // Distance from the team's own goal, normalised to [0,1] (0 = goal).
        // Home defends the larger-dy end; away the smaller-dy end.
        final goalDist =
            team == PlayerTeam.home ? (maxDy - rel.dy) : (rel.dy - minDy);
        const topPad = 0.07, bottomPad = 0.05;
        final tDepth = topPad + (goalDist / span) * (1 - topPad - bottomPad);
        final p = soccerHalfBoardPos(_canvasSize, _soccerFieldType, tDepth, rel.dx);
        if (p != null) return p;
      }
      return Offset(
          field.left + rel.dx * field.width, field.top + rel.dy * field.height);
    };
  }

  /// Put a squad on the pitch in [formation]: one member per slot, each
  /// keeping the number, name, photo and position that belong to the person.
  ///
  /// Members are matched to slots by position code first, so a squad with
  /// roles lands as the coach's actual XI — the goalkeeper in goal — and only
  /// unassigned members fall through to slot order. Slots left over after the
  /// squad runs out get plain numbered players; members left over after the
  /// slots run out are the bench and are not placed. Returns how many were.
  int addSquadFromFormation(
      SportFormation formation, PlayerTeam team, List<PlayerPhoto> squad) {
    _saveSnapshot();
    _resetAnimationState();
    final field = _sportType.fieldRect(_canvasSize);
    final positions =
        team == PlayerTeam.home ? formation.homePositions : formation.awayPositions;
    final toPos = _slotMapper(positions, team, field);
    final roles = [
      for (int i = 0; i < positions.length; i++)
        PlayerRoles.roleForSlot(_sportType, team, i, positions[i]),
    ];

    // Same-team players are replaced: applying a squad is "this is my XI",
    // not "add eleven more".
    _players.removeWhere((p) => p.team == team);

    final pool = List<PlayerPhoto>.from(squad);
    final assigned = List<PlayerPhoto?>.filled(positions.length, null);
    // Pass 1: exact position code.
    for (int i = 0; i < positions.length; i++) {
      if (roles[i].isEmpty) continue;
      final k = pool.indexWhere((m) => m.role == roles[i]);
      if (k >= 0) assigned[i] = pool.removeAt(k);
    }
    // Pass 2: whoever is left, in team-sheet order.
    for (int i = 0; i < positions.length && pool.isNotEmpty; i++) {
      assigned[i] ??= pool.removeAt(0);
    }

    int colorIdx = _players.length;
    int num = 1;
    final addedIds = <String>[];
    for (int i = 0; i < positions.length; i++) {
      final member = assigned[i];
      final id =
          '${DateTime.now().microsecondsSinceEpoch}_${team == PlayerTeam.home ? 'h' : 'a'}${i + 1}';
      final label = member?.boardLabel ?? '';
      _players.add(PlayerIcon(
        id: id,
        label: label.isEmpty ? '$num' : label,
        team: team,
        position: toPos(positions[i]),
        moveColor: PlayerIcon.moveColorForIndex(colorIdx++),
        photoId: member?.filename.isNotEmpty == true ? member!.id : null,
        // An unassigned member inherits its slot's role, so the next
        // formation change keeps them in the same position.
        role: (member?.role?.isNotEmpty ?? false)
            ? member!.role
            : (roles[i].isEmpty ? null : roles[i]),
      ));
      addedIds.add(id);
      num++;
    }

    _isDrawingMode = false;
    _multiSelectMode = true;
    _selectedPlayerId = null;
    _selectedWaypointIndex = null;
    _multiSelectIds
      ..clear()
      ..addAll(addedIds);
    notifyListeners();
    return squad.length - pool.length;
  }

  /// Add players for one team only from a formation (doesn't clear existing players)  /// Add players for one team only from a formation (doesn't clear existing players)
  /// The drawn person's box, which is what two figures must not share.
  ///
  /// The same numbers the drill generator spaces boards by — FIGURE_PT in
  /// tools/drills/engine.py. A token's cell is [kPlayerIconSize]; the person
  /// inked inside it is narrower and taller than the cell, so spacing by the
  /// cell leaves heads overlapping and shoulders apart.
  static const double _figureW = 26.0;
  static const double _figureH = 52.0;

  /// Push the just-placed figures off anybody they landed inside.
  ///
  /// Every full-squad preset puts people on top of each other: a 4-3-3
  /// against a 4-3-3 lands the two centre forwards on the same point, and
  /// 4-2-3-1 does it to its own striker and attacking midfielder — 21 points
  /// apart where the figure is 52 tall. So a coach's very first board opened
  /// with figures standing inside each other, the thing the drill library was
  /// just re-spaced to stop doing.
  ///
  /// Who gives way is the whole problem. A plain "push both apart" sends the
  /// away striker forward into the home half, where the home back four shoves
  /// him on until he is standing in the home goalmouth. So the rule is the
  /// one a coach would use:
  ///
  ///   * two players of the same team — the DEEPER one drops back, and the
  ///     line in front of him keeps the ground it was drawn on. The squeeze
  ///     travels backwards, into the space in front of the keeper, which is
  ///     where the room is.
  ///   * two opponents, which is what meets at the halfway line — each
  ///     retreats into his own half.
  ///   * shoulder to shoulder in the same row — sideways, splitting it.
  ///
  /// Only the ids passed in may move, so adding the away team leaves the home
  /// team exactly where the coach put it.
  void _spaceOutPlaced(Iterable<String> ids) {
    final movable = ids.toSet();
    if (movable.isEmpty) return;
    final field = _sportType.fieldRect(_canvasSize);
    final people = _players
        .where((p) => !p.isMarker && !p.isBall)
        .toList(growable: false);
    if (people.length < 2) return;
    // Home defends the bottom of the board, away the top — see spawnY. "Back"
    // is toward your own goal.
    double back(PlayerTeam t) => t == PlayerTeam.away ? -1.0 : 1.0;
    // Generous, because giving way travels: a keeper with his heels on the
    // line makes the man in front of him step up, and that one the next.
    // A column of eleven resolves one collision per pass. It runs once, when
    // a formation is dropped on the board, so the budget costs nothing.
    for (var pass = 0; pass < 200; pass++) {
      var moved = false;
      final preferFront = pass >= 100;
      for (var i = 0; i < people.length; i++) {
        for (var j = i + 1; j < people.length; j++) {
          final a = people[i], b = people[j];
          final aFree = movable.contains(a.id), bFree = movable.contains(b.id);
          if (!aFree && !bFree) continue;
          final w = _figureW * kFigureScale * (a.scale + b.scale) / 2;
          final h = _figureH * kFigureScale * (a.scale + b.scale) / 2;
          final dx = b.position.dx - a.position.dx;
          final dy = b.position.dy - a.position.dy;
          final ox = w - dx.abs();
          final oy = h - dy.abs();
          if (ox <= 0 || oy <= 0) continue;
          // A point and a half of daylight, not a hair: a pair settled to
          // exactly the box touches again the moment a third figure leans on
          // one of them, and the pass then spends itself oscillating.
          final byY = oy / h <= ox / w;
          if (!byY) {
            final push = ox + 1.5;
            final sign = dx >= 0 ? 1.0 : -1.0;
            if (aFree && bFree) {
              a.position = _clampToField(
                  a.position - Offset(push * sign / 2, 0), field);
              b.position = _clampToField(
                  b.position + Offset(push * sign / 2, 0), field);
            } else if (bFree) {
              b.position = _clampToField(b.position + Offset(push * sign, 0), field);
            } else {
              a.position = _clampToField(a.position - Offset(push * sign, 0), field);
            }
            moved = true;
            continue;
          }
          final push = oy + 1.5;
          if (a.team != b.team) {
            // Opponents: each retreats into his own half — and if one of
            // them is already placed and may not be moved, the other backs
            // off the whole way rather than half of it, which is how the
            // away team gives ground to a home team the coach has set.
            final share = (aFree && bFree) ? 0.5 : 1.0;
            if (aFree) {
              a.position = _clampToField(
                  a.position + Offset(0, back(a.team) * push * share), field);
            }
            if (bFree) {
              b.position = _clampToField(
                  b.position + Offset(0, back(b.team) * push * share), field);
            }
          } else {
            // Team-mates: the deeper one drops back and the one in front
            // keeps his ground.
            final aDeeper = back(a.team) > 0
                ? a.position.dy >= b.position.dy
                : a.position.dy <= b.position.dy;
            final deeper = aDeeper ? a : b;
            final front = aDeeper ? b : a;
            // The man behind gives way — unless he cannot, because he is the
            // keeper with his heels on the goal line. Then the man in front
            // steps up instead; somebody has to, and there is grass that way.
            //
            // "Could not" means the touchline held him, and the clamp then
            // nudges him the OTHER way — which closes the gap rather than
            // opening it. So a move only counts if it went the way it was
            // asked to go.
            //
            // Halfway through the budget the preference flips. A man caught
            // between a keeper who cannot move and a team-mate behind him is
            // pushed back by one and forward by the other, a point and a half
            // each way, for ever; letting the man IN FRONT give way instead
            // unpicks it, and the whole column slides up the pitch together.
            var gave = false;
            final d = back(deeper.team);
            if (preferFront && movable.contains(front.id)) {
              final was = front.position;
              final to = _clampToField(was - Offset(0, d * push), field);
              if ((to.dy - was.dy) * d < 0) {
                front.position = to;
                gave = true;
              }
            }
            if (!gave && movable.contains(deeper.id)) {
              final was = deeper.position;
              final to = _clampToField(was + Offset(0, d * push), field);
              if ((to.dy - was.dy) * d > 0) {
                deeper.position = to;
                gave = true;
              }
            }
            if (!gave && movable.contains(front.id)) {
              final was = front.position;
              final to = _clampToField(was - Offset(0, d * push), field);
              if ((to.dy - was.dy) * d < 0) {
                front.position = to;
                gave = true;
              }
            }
            if (!gave) continue;
          }
          moved = true;
        }
      }
      if (!moved) return;
    }
  }

  Offset _clampToField(Offset p, Rect field) => Offset(
        p.dx.clamp(field.left + _figureW / 2, field.right - _figureW / 2),
        p.dy.clamp(field.top + _figureH / 2, field.bottom - _figureH / 2),
      );

  void addTeamFromFormation(SportFormation formation, PlayerTeam team) {
    _saveSnapshot();
    _resetAnimationState();
    final field = _sportType.fieldRect(_canvasSize);
    final positions = team == PlayerTeam.home ? formation.homePositions : formation.awayPositions;

    final toPos = _slotMapper(positions, team, field);
    final roles = [
      for (int i = 0; i < positions.length; i++)
        PlayerRoles.roleForSlot(_sportType, team, i, positions[i]),
    ];
    final existing = _players.where((p) => p.team == team).toList();

    // Same-count formation change on a team that already exists: relocate the
    // existing players onto the new slots by role (preserving their identity)
    // rather than appending a duplicate set. Different counts keep the
    // additive behaviour below.
    if (existing.length == positions.length && PlayerRoles.supports(_sportType)) {
      _relocateTeamByRole(existing, positions, roles, toPos);
      _spaceOutPlaced(existing.map((p) => p.id));
      _isDrawingMode = false;
      // Add (don't clear) so the "both teams" caller, which relocates home then
      // away, ends up with both selected — matching the additive path.
      _multiSelectMode = true;
      _selectedPlayerId = null;
      _selectedWaypointIndex = null;
      _multiSelectIds.addAll(existing.map((p) => p.id));
      notifyListeners();
      return;
    }

    int num = existing.length + 1;
    int colorIdx = _players.length;
    final addedIds = <String>[];
    for (int i = 0; i < positions.length; i++) {
      final id = '${DateTime.now().microsecondsSinceEpoch}_${team == PlayerTeam.home ? 'h' : 'a'}$num';
      _players.add(PlayerIcon(
        id: id,
        label: '$num',
        team: team,
        position: toPos(positions[i]),
        moveColor: PlayerIcon.moveColorForIndex(colorIdx++),
        role: roles[i].isEmpty ? null : roles[i],
      ));
      addedIds.add(id);
      num++;
    }
    _spaceOutPlaced(addedIds);
    // Auto-select the just-added team so the user can drag them as a
    // group. Append rather than replace so the "both teams" caller,
    // which invokes this twice, ends up with both teams selected — the
    // caller is responsible for clearing the multi-select set first.
    _multiSelectMode = true;
    _selectedPlayerId = null;
    _selectedWaypointIndex = null;
    _multiSelectIds.addAll(addedIds);
    notifyListeners();
  }

  /// Move [existing] team players onto the [positions]/[roles] slots, matching
  /// by exact role first, then by line (nearest lateral preference), then by
  /// leftover order. Players keep their id / label / photo / assigned role; an
  /// unassigned player inherits its slot's role so identity sticks from then on.
  void _relocateTeamByRole(List<PlayerIcon> existing, List<Offset> positions,
      List<String> roles, Offset Function(Offset) toPos) {
    final n = positions.length;
    final slotPlayer = List<PlayerIcon?>.filled(n, null);
    final used = <String>{};

    // Pass 1: exact role.
    for (int i = 0; i < n; i++) {
      for (final p in existing) {
        if (!used.contains(p.id) && p.role == roles[i] && roles[i].isNotEmpty) {
          slotPlayer[i] = p;
          used.add(p.id);
          break;
        }
      }
    }
    // Pass 2: same line, nearest lateral preference.
    for (int i = 0; i < n; i++) {
      if (slotPlayer[i] != null) continue;
      final line = PlayerRoles.lineOf(roles[i]);
      if (line == null) continue;
      final xp = PlayerRoles.xPrefOf(roles[i]);
      PlayerIcon? best;
      double bestD = double.infinity;
      for (final p in existing) {
        if (used.contains(p.id) || p.role == null) continue;
        if (PlayerRoles.lineOf(p.role!) != line) continue;
        final dd = (PlayerRoles.xPrefOf(p.role!) - xp).abs();
        if (dd < bestD) {
          bestD = dd;
          best = p;
        }
      }
      if (best != null) {
        used.add(best.id);
        slotPlayer[i] = best;
      }
    }
    // Pass 3: leftover players to remaining slots in order.
    final leftover = [for (final p in existing) if (!used.contains(p.id)) p];
    int li = 0;
    for (int i = 0; i < n; i++) {
      if (slotPlayer[i] == null && li < leftover.length) {
        slotPlayer[i] = leftover[li++];
      }
    }
    // Apply: reposition each, and give an unassigned player its slot role.
    for (int i = 0; i < n; i++) {
      final p = slotPlayer[i];
      if (p == null) continue;
      p.position = toPos(positions[i]);
      if ((p.role == null || p.role!.isEmpty) && roles[i].isNotEmpty) {
        final idx = _players.indexWhere((q) => q.id == p.id);
        if (idx >= 0) _players[idx] = _players[idx].copyWith(role: roles[i]);
      }
    }
  }

  /// Assign (or clear, with null) a player's fixed position/role.
  void setPlayerRole(String playerId, String? role) {
    final idx = _players.indexWhere((p) => p.id == playerId);
    if (idx < 0 || _players[idx].role == role) return;
    _saveSnapshot();
    _players[idx] = _players[idx].copyWith(role: role, clearRole: role == null);
    notifyListeners();
  }

  // Drawing
  void startStroke(Offset point) {
    _currentStroke = DrawingStroke(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      points: [point],
      color: _strokeColor,
      width: _strokeWidth,
      style: _strokeStyle,
      arrow: _arrowStyle,
      shape: _lineShape,
    );
    notifyListeners();
  }

  void addPoint(Offset point) {
    if (_currentStroke == null) return;
    _currentStroke = _currentStroke!.copyWith(
      points: [..._currentStroke!.points, point],
    );
    notifyListeners();
  }

  /// Drop the stroke being drawn without keeping it — a palm that touched
  /// down before the Pencil did.
  void cancelStroke() {
    if (_currentStroke == null) return;
    _currentStroke = null;
    notifyListeners();
  }

  void endStroke() {
    if (_currentStroke == null) return;
    if (_currentStroke!.points.length > 1) {
      _saveSnapshot();
      // phase defaults to -1 (always visible)
      _strokes.add(_finalizeStroke(_currentStroke!));
    }
    _currentStroke = null;
    notifyListeners();
  }

  /// Clean up a just-drawn stroke before storing it.
  ///
  /// - straight: drop to first→last, so it renders (and hit-tests) as the
  ///   clean line the user expects.
  /// - freehand/wavy: run Ramer–Douglas–Peucker to strip hand jitter, so a
  ///   drag the user meant to be straight actually reads straight instead of a
  ///   wobbly curve, while deliberate curves keep their shape. hitTestStroke
  ///   walks these same points, so it stays in sync with what is drawn.
  DrawingStroke _finalizeStroke(DrawingStroke s) {
    if (s.points.length <= 2) return s;
    if (s.shape == LineShape.straight) {
      return s.copyWith(points: [s.points.first, s.points.last]);
    }
    return s.copyWith(points: _simplify(s.points, 3.0));
  }

  /// Ramer–Douglas–Peucker: keep only the points that make the polyline
  /// deviate from its chord by more than [epsilon] px.
  List<Offset> _simplify(List<Offset> pts, double epsilon) {
    if (pts.length < 3) return pts;
    double maxDist = 0;
    int index = 0;
    for (int i = 1; i < pts.length - 1; i++) {
      final d = _perpDistance(pts[i], pts.first, pts.last);
      if (d > maxDist) {
        maxDist = d;
        index = i;
      }
    }
    if (maxDist <= epsilon) return [pts.first, pts.last];
    final left = _simplify(pts.sublist(0, index + 1), epsilon);
    final right = _simplify(pts.sublist(index), epsilon);
    return [...left.sublist(0, left.length - 1), ...right];
  }

  /// Perpendicular distance from [p] to the line through [a] and [b].
  double _perpDistance(Offset p, Offset a, Offset b) {
    final len = (b - a).distance;
    if (len == 0) return (p - a).distance;
    return ((p.dx - a.dx) * (b.dy - a.dy) - (p.dy - a.dy) * (b.dx - a.dx)).abs() /
        len;
  }

  void selectStroke(String? id) {
    _selectedStrokeId = id;
    if (id != null) {
      _selectedPlayerId = null;
      _selectedWaypointIndex = null;
    }
    notifyListeners();
  }

  void deleteStroke(String id) {
    _saveSnapshot();
    _strokes.removeWhere((s) => s.id == id);
    if (_selectedStrokeId == id) _selectedStrokeId = null;
    notifyListeners();
  }

  void moveStroke(String id, Offset delta) {
    final idx = _strokes.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    _strokes[idx] = _strokes[idx].copyWith(
      points: _strokes[idx].points.map((p) => p + delta).toList(),
    );
    notifyListeners();
  }

  void moveStrokeEnd(String id) {
    _saveSnapshot();
  }

  // Note: no `shape` parameter. Switching an existing stroke to
  // LineShape.straight would have to discard its interior points (see
  // _finalizeStroke), which is unrecoverable. Shape is chosen before the
  // stroke is drawn.
  ///
  /// [snapshot] is what undo steps back to. A slider drag calls this once per
  /// division, so it passes false for every step after the first: otherwise
  /// one drag of the thickness slider costs seven taps of undo.
  void updateStroke(String id, {Color? color, double? width, StrokeStyle? style, ArrowStyle? arrow, bool snapshot = true}) {
    final idx = _strokes.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    if (snapshot) _saveSnapshot();
    _strokes[idx] = _strokes[idx].copyWith(
      color: color,
      width: width,
      style: style,
      arrow: arrow,
    );
    notifyListeners();
  }

  /// Find the stroke closest to a tap point (within threshold)
  String? hitTestStroke(Offset point, {double threshold = 20.0}) {
    for (int i = _strokes.length - 1; i >= 0; i--) {
      final stroke = _strokes[i];
      for (int j = 0; j < stroke.points.length - 1; j++) {
        final dist = _distToSegment(point, stroke.points[j], stroke.points[j + 1]);
        if (dist < threshold) return stroke.id;
      }
    }
    return null;
  }

  static double _distToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lenSq == 0) return (p - a).distance;
    final t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / lenSq;
    final clamped = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + clamped * ab.dx, a.dy + clamped * ab.dy);
    return (p - proj).distance;
  }

  void setStrokePhaseRange(String strokeId, int startPhase, int endPhase, {bool save = true}) {
    _resetAnimationState();
    final idx = _strokes.indexWhere((s) => s.id == strokeId);
    if (idx < 0) return;
    if (save) _saveSnapshot();
    _strokes[idx] = _strokes[idx].copyWith(
      startPhase: startPhase.clamp(-1, 99),
      endPhase: endPhase.clamp(-1, 99),
    );
    notifyListeners();
  }

  void clearStrokes() {
    if (_strokes.isEmpty) return;
    _saveSnapshot();
    _resetAnimationState();
    _strokes.clear();
    notifyListeners();
  }

  /// Start over: one empty page, no history, nothing named.
  ///
  /// Distinct from [clearAll], which empties the page you are looking at —
  /// that is what a coach pressing Clear on the board means, and it must not
  /// silently take the rest of the routine with it.
  void newDocument() {
    _otherPages.clear();
    _parkedUndo.clear();
    _parkedRedo.clear();
    _pageIndex = 0;
    _players.clear();
    _strokes.clear();
    _selectedPlayerId = null;
    _selectedWaypointIndex = null;
    _selectedStrokeId = null;
    _resetAnimationState();
    _atStep = 0;
    _targetStep = 0;
    _undoStack.clear();
    _redoStack.clear();
    currentTacticName = null;
    currentTacticMeta = null;
    notifyListeners();
  }

  void clearAll() {
    if (_players.isEmpty && _strokes.isEmpty) return;
    _saveSnapshot();
    _resetAnimationState();
    _players.clear();
    _strokes.clear();
    // And it stops being "Board 1". The same rule loading a drill follows,
    // for the same reason: leaving the board autosaves whatever has a name,
    // so a board emptied and walked away from would be written over the
    // file it was emptied out of — eleven players' work gone with no prompt
    // and an undo stack that dies with the page.
    currentTacticName = null;
    currentTacticMeta = null;
    drillBeats = const [];
    drillSetup = null;
    _figureScale = 1.0;
    gTightFigureScale = 1.0;
    _clearViewFrame();
    _selectedPlayerId = null;
    _selectedWaypointIndex = null;
    _isAnimating = false;
    _animatedPositions = {};
    _atStep = 0;
    notifyListeners();
  }

  // Undo / Redo
  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_currentSnapshot());
    final snap = _undoStack.removeLast();
    _restoreSnapshot(snap);
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_currentSnapshot());
    final snap = _redoStack.removeLast();
    _restoreSnapshot(snap);
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  /// Bring a page's coordinates onto the canvas it is being shown at.
  ///
  /// Through the COURT, for the reason [_rescalePlayers] gives: a board
  /// written on a 1000x1500 canvas has the baseline a twentieth of the way
  /// down, and in a window turned sideways the court is fitted by width and
  /// the baseline is a tenth of the way down. Scaling by the canvas put a
  /// drill's shot past the end line the moment it was opened onto a board
  /// that was already the window's shape.
  void _rescaleFromSaved(Map<String, dynamic> page) {
    final savedW = (page['canvasWidth'] as num?)?.toDouble() ?? _canvasSize.width;
    final savedH = (page['canvasHeight'] as num?)?.toDouble() ?? _canvasSize.height;
    if (savedW <= 0 || savedH <= 0) return;
    _fromLegacyPool(page, Size(savedW, savedH));
    _fromLegacyCourt(page, Size(savedW, savedH));
    if (savedW == _canvasSize.width && savedH == _canvasSize.height) return;
    final from = _sportType.fieldRect(Size(savedW, savedH));
    final to = _sportType.fieldRect(_canvasSize);
    if (from.width <= 0 || from.height <= 0) return;
    final sx = to.width / from.width;
    final sy = to.height / from.height;
    Offset map(Offset p) => Offset(
        to.left + (p.dx - from.left) * sx, to.top + (p.dy - from.top) * sy);
    for (final p in _players) {
      p.position = map(p.position);
      p.moves = p.moves.map(map).toList();
    }
  }

  /// The water polo pool's length between the goal lines, in metres. Every
  /// water polo page written since it changed says so (`poolLength`); a page
  /// without it was drawn on the old 30 m pool.
  static const int kWaterPoloPoolLength = 25;

  /// A water polo page saved on the 30 m pool, carried onto the 25 m one.
  ///
  /// World Aquatics' 2025 regulations put the goal lines 25 m apart, and the
  /// pool was redrawn to match. Saved positions are canvas points against
  /// the court the app drew, so a board from the long pool, read against the
  /// short one, would put a centre forward on the 2 m line at 1.7 m and the
  /// halfway line's players in the other team's half. Each point is moved
  /// line for line instead: in metres from its goal line it stays on the
  /// same mark — goal, 2 m, 5 m, 6 m, halfway — and between two marks keeps
  /// its share of the gap. Across the pool (20 m both times) nothing moves.
  void _fromLegacyPool(Map<String, dynamic> page, Size saved) {
    if (_sportType != SportType.waterPolo) return;
    if (page['poolLength'] != null) return;
    final to = _sportType.fieldRect(saved);
    // SportType.fieldRect as it was for the 30 m pool.
    const aspect = 20 / 30;
    double cw, ch;
    if (saved.width / saved.height > aspect) {
      ch = saved.height * 0.88;
      cw = ch * aspect;
    } else {
      cw = saved.width * 0.88;
      ch = cw / aspect;
    }
    final from = Rect.fromLTWH(
        (saved.width - cw) / 2, (saved.height - ch) / 2, cw, ch);
    if (from.width <= 0 || to.width <= 0) return;
    Offset map(Offset p) {
      final x = (p.dx - from.left) / from.width;
      final y = legacyPoolMetres((p.dy - from.top) / from.height * 30);
      return Offset(to.left + x * to.width,
          to.top + y / kWaterPoloPoolLength * to.height);
    }
    for (final p in _players) {
      if (p.id == kDrillNoteId) continue;
      p.position = map(p.position);
      p.moves = p.moves.map(map).toList();
    }
    _strokes = [
      for (final s in _strokes) s.copyWith(points: s.points.map(map).toList())
    ];
  }

  /// Courts redrawn smaller, so a man can stand with his feet behind the
  /// far baseline and still be on the board: the key every page of that
  /// sport written since carries, its value, and the scale of the court
  /// before (SportType.fieldRect's; tools/drills/engine.py COURT_REDRAW).
  /// A page without the key was drawn on the old, larger court.
  static const Map<SportType, (String, int, double)> kCourtRedraws = {
    SportType.pickleball: ('pbCourt', 2, 0.88),   // → 0.82
    SportType.tennis: ('court', 2, 0.85),         // → 0.84
    SportType.beachTennis: ('court', 2, 0.85),    // → 0.84
    SportType.volleyball: ('court', 2, 0.85),     // → 0.84
  };

  /// A page saved on a sport's old court, carried onto the redrawn one
  /// ([kCourtRedraws]).
  ///
  /// Saved positions are canvas points against the court the app drew, so
  /// each point — players, their runs, drawn strokes — keeps its place
  /// relative to the court lines: same fraction of the court, or the same
  /// distance past a line in court units.
  void _fromLegacyCourt(Map<String, dynamic> page, Size saved) {
    final redraw = kCourtRedraws[_sportType];
    if (redraw == null) return;
    if (page[redraw.$1] != null) return;
    final to = _sportType.fieldRect(saved);
    if (to.height <= 0) return;
    // SportType.fieldRect as it was for the old court: same aspect, the
    // old scale.
    final aspect = to.width / to.height;
    final scale = redraw.$3;
    double cw, ch;
    if (saved.width / saved.height > aspect) {
      ch = saved.height * scale;
      cw = ch * aspect;
    } else {
      cw = saved.width * scale;
      ch = cw / aspect;
    }
    final from = Rect.fromLTWH(
        (saved.width - cw) / 2, (saved.height - ch) / 2, cw, ch);
    if (from.width <= 0 || to.width <= 0) return;
    Offset map(Offset p) => Offset(
        to.left + (p.dx - from.left) / from.width * to.width,
        to.top + (p.dy - from.top) / from.height * to.height);
    for (final p in _players) {
      if (p.id == kDrillNoteId) continue;
      p.position = map(p.position);
      p.moves = p.moves.map(map).toList();
    }
    _strokes = [
      for (final s in _strokes) s.copyWith(points: s.points.map(map).toList())
    ];
  }

  /// Metres down the old 30 m pool → metres down the 25 m pool, keeping
  /// every line: the marks at each end stay where they are from their own
  /// goal line, the stretch between the 6 m lines (18 m → 13 m) is shared
  /// out evenly, and anything past a goal line keeps its distance from it.
  @visibleForTesting
  static double legacyPoolMetres(double y) {
    const old = [0.0, 2.0, 5.0, 6.0, 15.0, 24.0, 25.0, 28.0, 30.0];
    const now = [0.0, 2.0, 5.0, 6.0, 12.5, 19.0, 20.0, 23.0, 25.0];
    if (y <= 0) return y;
    if (y >= 30) return y - 5;
    for (var i = 0; i < old.length - 1; i++) {
      if (y <= old[i + 1]) {
        return now[i] +
            (y - old[i]) * (now[i + 1] - now[i]) / (old[i + 1] - old[i]);
      }
    }
    return y - 5;
  }

  void _saveSnapshot() {
    _undoStack.add(_currentSnapshot());
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  _BoardSnapshot _currentSnapshot() => _BoardSnapshot(
        players: _players.map((p) => p.copyWith()).toList(),
        strokes: _strokes.map((s) => s.copyWith()).toList(),
      );

  void _restoreSnapshot(_BoardSnapshot snap) {
    _players = snap.players;
    _strokes = snap.strokes;
  }

  // ── Save / Load tactics ──────────────────────────────────────────────────

  int get pageCount => _otherPages.length + 1;
  int get pageIndex => _pageIndex;

  /// The live page as JSON, without the page list — one page's worth.
  Map<String, dynamic> _pageJson() => {
        'sportType': _sportType.index,
        'players': _players.map((p) => p.toJson()).toList(),
        'strokes': _strokes.map((s) => s.toJson()).toList(),
        'canvasWidth': _canvasSize.width,
        'canvasHeight': _canvasSize.height,
        if (_sportType == SportType.waterPolo)
          'poolLength': kWaterPoloPoolLength,
        if (kCourtRedraws[_sportType] case final r?) r.$1: r.$2,
      };

  /// Every page in order, with the live one written back into its slot.
  List<Map<String, dynamic>> _allPages() {
    final out = List<Map<String, dynamic>>.from(_otherPages);
    out.insert(_pageIndex, _pageJson());
    return out;
  }

  void _loadPage(Map<String, dynamic> page) {
    _players = (page['players'] as List)
        .map((p) => PlayerIcon.fromJson(p as Map<String, dynamic>))
        .toList();
    _strokes = (page['strokes'] as List)
        .map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
        .toList();
    _rescaleFromSaved(page);
    _selectedPlayerId = null;
    _selectedWaypointIndex = null;
    _selectedStrokeId = null;
    _resetAnimationState();
    _atStep = 0;
    _targetStep = 0;
  }

  /// Switch to page [i], keeping everything about the page being left.
  void goToPage(int i) {
    if (i == _pageIndex || i < 0 || i >= pageCount) return;
    final pages = _allPages();
    _parkedUndo[_pageIndex] = List.of(_undoStack);
    _parkedRedo[_pageIndex] = List.of(_redoStack);
    _pageIndex = i;
    _loadPage(pages[i]);
    _otherPages
      ..clear()
      ..addAll([
        for (var k = 0; k < pages.length; k++)
          if (k != i) pages[k]
      ]);
    _undoStack
      ..clear()
      ..addAll(_parkedUndo[i] ?? const []);
    _redoStack
      ..clear()
      ..addAll(_parkedRedo[i] ?? const []);
    notifyListeners();
  }

  /// A new page after the current one. [copyCurrent] is the common case: a
  /// routine is the same shape with one thing changed, and drawing the second
  /// page from nothing is why nobody makes a second page.
  void addPage({bool copyCurrent = false}) {
    final pages = _allPages();
    final blank = <String, dynamic>{
      'sportType': _sportType.index,
      'players': <dynamic>[],
      'strokes': <dynamic>[],
      'canvasWidth': _canvasSize.width,
      'canvasHeight': _canvasSize.height,
      if (_sportType == SportType.waterPolo)
        'poolLength': kWaterPoloPoolLength,
      if (kCourtRedraws[_sportType] case final r?) r.$1: r.$2,
    };
    pages.insert(_pageIndex + 1,
        copyCurrent ? jsonDecode(jsonEncode(_pageJson())) as Map<String, dynamic> : blank);
    _parkedUndo.clear();
    _parkedRedo.clear();
    _pageIndex += 1;
    _loadPage(pages[_pageIndex]);
    _otherPages
      ..clear()
      ..addAll([
        for (var k = 0; k < pages.length; k++)
          if (k != _pageIndex) pages[k]
      ]);
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  /// Remove page [i]. The last page cannot be removed — a document with no
  /// pages is not a document, it is a crash.
  void deletePage(int i) {
    if (pageCount <= 1 || i < 0 || i >= pageCount) return;
    final pages = _allPages()..removeAt(i);
    _parkedUndo.clear();
    _parkedRedo.clear();
    _pageIndex = i.clamp(0, pages.length - 1);
    _loadPage(pages[_pageIndex]);
    _otherPages
      ..clear()
      ..addAll([
        for (var k = 0; k < pages.length; k++)
          if (k != _pageIndex) pages[k]
      ]);
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  /// The document: page one at the top level, the rest alongside it.
  ///
  /// Page ONE, not the page being edited — a build that predates pages reads
  /// only the top level, and it must open such a file at the beginning of the
  /// routine rather than wherever the last person happened to stop. This
  /// build reads `pages` and lands back on `pageIndex`.
  Map<String, dynamic> toJson() {
    final pages = _allPages();
    return {
      ...pages.first,
      if (pages.length > 1) 'pages': pages,
      if (pages.length > 1) 'pageIndex': _pageIndex,
      // The drill's own words travel with the board. Without this they last
      // only as long as the page that opened it: the board is autosaved and
      // read back on the next launch, and a drill restored that way came
      // back as a shape with no caption under it.
      if (drillBeats.isNotEmpty) 'drillBeats': drillBeats,
      // And which drill they came from, so a board read back after a
      // restart can still put them into a newly chosen language.
      if (drillBeats.isNotEmpty && _drillId != null) 'drillId': _drillId,
      // A note not placed yet (the board is laid out a frame after the
      // drill lands) is still owed on the board read back.
      if (drillBeats.isNotEmpty && noteWanted) 'noteWanted': true,
      // A tight drill's figure size, and the half it is zoomed to, so the
      // board reads back the way it was left.
      if (_figureScale != 1.0) 'figureScale': _figureScale,
      if (_viewFrame != null) 'viewFrame': _viewFrame,
      // In this canvas's points, beside this canvas's size, like the players.
      if (_viewWindow != null && !_canvasSize.isEmpty)
        'viewWindow': () {
          final c = _sportType.fieldRect(_canvasSize);
          final vw = _viewWindow!;
          return [
            c.left + vw.left * c.width,
            c.top + vw.top * c.height,
            c.left + vw.right * c.width,
            c.top + vw.bottom * c.height,
          ];
        }(),
    };
  }

  void loadFromJson(Map<String, dynamic> json) {
    _drillName = null;
    _nameFor = null;
    _beatsFor = null;
    _drillId = json['drillId'] as String?;
    final carried = json['drillBeats'];
    drillBeats = carried is List
        ? carried.map((b) => b.toString()).toList(growable: false)
        : const [];
    drillSetup = null;
    // A board read back from disk already has whatever note it kept —
    // unless it was written before the note was placed.
    noteWanted = json['noteWanted'] == true && drillBeats.isNotEmpty;
    _sportType = SportType.values[json['sportType'] as int];
    _figureScale = ((json['figureScale'] as num?)?.toDouble() ?? 1.0)
        .clamp(0.4, 1.0)
        .toDouble();
    gTightFigureScale = _figureScale;
    _clearViewFrame();
    final frame = json['viewFrame'];
    _viewFrame = frame == 'top' || frame == 'bottom' ? frame as String : null;
    _viewWindow = _windowFrom(json);
    final raw = json['pages'];
    final pages = raw is List && raw.isNotEmpty
        ? raw.map((p) => Map<String, dynamic>.from(p as Map)).toList()
        : <Map<String, dynamic>>[Map<String, dynamic>.from(json)];
    _pageIndex = ((json['pageIndex'] as num?)?.toInt() ?? 0)
        .clamp(0, pages.length - 1);
    _parkedUndo.clear();
    _parkedRedo.clear();
    final live = pages[_pageIndex];
    _players = (live['players'] as List).map((p) => PlayerIcon.fromJson(p as Map<String, dynamic>)).toList();
    // Boards saved before text counter-turned with the board kept a note
    // placed sideways at -90°, which now reads as -90° on every screen.
    for (final p in _players) {
      if (p.id == kDrillNoteId && (p.rotation + math.pi / 2).abs() < 0.01) {
        p.rotation = 0;
      }
    }
    notePlacedSideways = null;
    _strokes = (live['strokes'] as List).map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>)).toList();
    _rescaleFromSaved(live);
    _otherPages
      ..clear()
      ..addAll([
        for (var k = 0; k < pages.length; k++)
          if (k != _pageIndex) pages[k]
      ]);
    _selectedPlayerId = null;
    _selectedWaypointIndex = null;
    _isAnimating = false;
    _animatedPositions = {};
    _atStep = 0;
    // A board read back opens at its set-up: its note reads that step, not
    // whichever beat was showing when it was written.
    _syncDrillNote();
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  /// The board's "viewWindow" — [left, top, right, bottom] in the points of
  /// the canvas it says it was drawn on — as fractions of that canvas's
  /// court. Null when absent or malformed.
  Rect? _windowFrom(Map<String, dynamic> json) {
    final v = json['viewWindow'];
    final cw = (json['canvasWidth'] as num?)?.toDouble() ?? 0;
    final ch = (json['canvasHeight'] as num?)?.toDouble() ?? 0;
    if (v is! List || v.length != 4 || v.any((e) => e is! num)) return null;
    if (cw <= 0 || ch <= 0) return null;
    final c = _sportType.fieldRect(Size(cw, ch));
    if (c.isEmpty) return null;
    final n = [for (final e in v) (e as num).toDouble()];
    final r = Rect.fromLTRB((n[0] - c.left) / c.width, (n[1] - c.top) / c.height,
        (n[2] - c.left) / c.width, (n[3] - c.top) / c.height);
    return r.width > 0 && r.height > 0 ? r : null;
  }

  Future<Directory> get _tacticsDir async {
    Directory baseDir;
    try {
      baseDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      // Fallback for simulator compatibility issues
      baseDir = Directory.systemTemp;
    }
    final dir = Directory('${baseDir.path}/tactics/${_sportType.name}');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// What the drill that is on the board says about each of its beats, and
  /// its set-up line — so the board can print the step it is standing on
  /// under the court instead of making a coach leave the board to read it.
  ///
  /// Empty for anything that is not a drill: a saved tactic, a blank board,
  /// a formation. [loadFromJson] clears it, so a load that does not set it
  /// cannot inherit the last drill's words.
  List<String> drillBeats = const [];
  String? drillSetup;

  /// The id of the text element a drill's step note is placed as.
  ///
  /// It is an ordinary element from the moment it lands — drag it, recolour
  /// it, resize it, turn it, delete it — with one thing added: its words are
  /// the beat the board is standing on, and editing them edits that beat.
  /// The caption it replaces was chrome painted over the board and could be
  /// none of those things.
  static const String kDrillNoteId = 'drill_note';

  /// A drill has been opened and its note has not been placed yet.
  ///
  /// Placing it needs the board's own size and which way round it is drawn,
  /// and neither is known until the board has been laid out — so the page
  /// does it on the first frame after. Once placed this goes false and
  /// stays false: deleting the note is meant to be final.
  bool noteWanted = false;

  /// Which way round the board was drawn when the note was placed — null
  /// once the coach has moved it (or for a board read back from disk), when
  /// where it stands is theirs. Turning the device moves a note still where
  /// it was put, to the new "under the court" (see [reorientDrillNote]).
  bool? notePlacedSideways;

  /// The board has turned between portrait and landscape: put an unmoved
  /// note under the court again, which sideways is a different side of the
  /// canvas. It keeps its colour, size and words.
  void reorientDrillNote({required bool sideways, double maxWidth = 320}) {
    final was = notePlacedSideways;
    if (was == null || was == sideways || noteWanted) return;
    if (!_players.any((p) => p.id == kDrillNoteId)) {
      notePlacedSideways = null;
      return;
    }
    noteWanted = true;
    placeDrillNote(sideways: sideways, maxWidth: maxWidth);
  }

  /// A drill has just landed on the board: these are its beats, and it
  /// wants its note.
  void openedDrill(List<String> beats,
      {List<String> Function(String locale)? beatsFor,
      String? name,
      String Function(String locale)? nameFor,
      String? id,
      String? frame}) {
    // The half the drill lives in (Drill.frame): the board opens zoomed to
    // it once it knows its size — see applyViewFrame.
    if (frame == 'top' || frame == 'bottom') {
      _viewFrame = frame;
      _frameAppliedFor = null;
    }
    drillBeats = beats;
    noteWanted = beats.isNotEmpty;
    _beatsFor = beatsFor;
    _beatsAsOpened = beats;
    _drillName = name;
    _nameFor = nameFor;
    _drillId = id;
    // The load before this autosaved a board with no words and no note;
    // write it again with its beats and the note still owed (toJson).
    saveWorkingBoard();
  }

  String Function(String locale)? _nameFor;

  /// The library id of the drill on the board, kept with the board.
  String? _drillId;

  /// The name of the drill on the board, while what is on the board is still
  /// that drill and not yet a board of the coach's own — what "Save" offers
  /// as the name, instead of an empty field.
  String? get openedDrillName =>
      drillBeats.isNotEmpty && currentTacticName == null ? _drillName : null;
  String? _drillName;

  /// The drill's steps in another language, and the steps as the library
  /// wrote them when it was opened — so a language switch can put the note
  /// on the board into the new language, and leave alone any the coach has
  /// rewritten. Before this the sentence under the court stayed in the
  /// language the drill was opened in ("Dink cross-court" under zh-CN).
  List<String> Function(String locale)? _beatsFor;
  List<String> _beatsAsOpened = const [];

  /// Put the drill's steps into [locale], when they are still the library's
  /// own words. A board loaded from disk, a blank one, or one whose steps
  /// the coach has edited, keeps what it has.
  Future<void> localizeDrill(String locale) async {
    if (drillBeats.isEmpty) return;
    // Read back from disk: find the drill again, and take its steps as the
    // library's own only if they still read as the library wrote them in
    // one of its languages — anything else is the coach's.
    if (_beatsFor == null && _drillId != null) {
      final id = _drillId!, sport = _sportType, before = drillBeats;
      final all = await DrillLibraryService.instance.forSport(sport);
      final d = all.where((x) => x.id == id).firstOrNull;
      if (d == null || _drillId != id || !identical(drillBeats, before)) {
        return;
      }
      List<String> parse(String l) => DrillNote.parse(d.localizedNote(l)).beats;
      _beatsFor = parse;
      _nameFor = d.displayName;
      final unedited = d.note.keys.any((l) {
        final b = parse(l);
        if (b.length != before.length) return false;
        for (var i = 0; i < b.length; i++) {
          if (b[i] != before[i]) return false;
        }
        return true;
      });
      if (unedited) _beatsAsOpened = drillBeats;
    }
    // The name "Save" offers follows the language too.
    if (_nameFor != null) _drillName = _nameFor!(locale);
    final f = _beatsFor;
    if (f == null) return;
    if (!identical(drillBeats, _beatsAsOpened)) return;
    final next = f(locale);
    if (next.length != drillBeats.length) return;
    var same = true;
    for (var i = 0; i < next.length; i++) {
      if (next[i] != drillBeats[i]) same = false;
    }
    if (same) return;
    drillBeats = next;
    _beatsAsOpened = next;
    _syncDrillNote();
    notifyListeners();
  }

  /// Put the drill's step note on the board, under the court.
  ///
  /// [sideways] is the board turned a quarter, which is how a phone or a
  /// tablet draws it in landscape: the canvas itself is laid out upright
  /// inside a RotatedBox, so the screen's "below the court" is the canvas's
  /// right-hand margin, and the note is turned a quarter back to read level.
  void placeDrillNote({required bool sideways, double maxWidth = 320}) {
    if (!noteWanted) return;
    if (drillBeats.isEmpty || _canvasSize.isEmpty) return;
    noteWanted = false;
    final kept = _players.where((p) => p.id == kDrillNoteId).firstOrNull;
    _players.removeWhere((p) => p.id == kDrillNoteId);
    final court = _sportType.fieldRect(_canvasSize);
    final w = _canvasSize.width, h = _canvasSize.height;
    // Under the court by default — and over it when someone stands under
    // it. A volleyball serve is taken from behind the end line, which is
    // exactly that band, and the sentence printed over the server hid both.
    // Each band is scored by how many of the board's figures, at any beat
    // (where they start and every point they run to), would be under the
    // note; the far band is taken only when it is strictly emptier.
    //
    // Sideways the canvas is drawn a quarter turn round, so the screen's
    // "under the court" is the canvas's right-hand margin and "over" its
    // left-hand one.
    final under = sideways
        ? Rect.fromLTRB(court.right, 0, w, h)
        : Rect.fromLTRB(0, court.bottom, w, h);
    final over = sideways
        ? Rect.fromLTRB(0, 0, court.left, h)
        : Rect.fromLTRB(0, 0, w, court.top);
    int crowd(Rect band) {
      // The note's own extent: the middle of the band, not its whole
      // length — a figure out by the side line is clear of the words.
      final note = sideways
          ? Rect.fromLTRB(band.left, h * 0.1, band.right, h * 0.9)
          : Rect.fromLTRB(w * 0.1, band.top, w * 0.9, band.bottom);
      // A figure stands taller than its point (36 is the icon cell, see
      // kPlayerIconSize): head above it, feet below.
      final cell = kPlayerIconSize;
      var n = 0;
      for (final p in _players) {
        if (p.id == kDrillNoteId || p.markerShape == MarkerShape.text) {
          continue;
        }
        for (final at in [p.position, ...p.moves]) {
          final box = Rect.fromCenter(
            center: at,
            width: cell * 1.2 * p.scale,
            height: cell * 1.8 * p.scale,
          );
          if (box.overlaps(note)) n++;
        }
      }
      return n;
    }

    final flip = crowd(over) < crowd(under);
    final band = flip ? over : under;
    // Kept on the board, whole. The band under a rugby pitch or a pool is a
    // sliver, and a chip centred in it hung over the board's edge, its last
    // line cut off by the frame. The chip's size is measured for the
    // longest of the drill's steps (the note changes words at every beat),
    // the way TextElementChip lays it out: 13pt semibold, 1.25 line height,
    // three lines at most, 8 by 4.5 of padding and a 1pt border.
    var chipW = 0.0, chipH = 0.0;
    for (final b in drillBeats) {
      final tp = TextPainter(
        text: TextSpan(
          text: b,
          style: const TextStyle(
              fontSize: 13, height: 1.25, fontWeight: FontWeight.w600),
        ),
        maxLines: 3,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth - 18);
      chipW = math.max(chipW, tp.width + 18);
      chipH = math.max(chipH, tp.height + 11);
      tp.dispose();
    }
    // Sideways the chip lies on its side: its height runs across the canvas.
    final extentX = sideways ? chipH : chipW;
    final extentY = sideways ? chipW : chipH;
    _noteExtent = Size(extentX, extentY);
    const margin = 6.0;
    double fit(double c, double extent, double size) {
      final lo = extent / 2 + margin, hi = size - extent / 2 - margin;
      return lo > hi ? size / 2 : c.clamp(lo, hi);
    }

    // Where in the band. Its middle, unless that still covers someone — a
    // table-tennis receiver standing in the band over the table had the
    // sentence across his head — or the goal, which stands in the band
    // under a pitch (audit 2026-10-11 #16). Then the place in the band that
    // covers least: its outer edge, its court edge, or along it to either
    // end. The band itself is still chosen as above; the middle wins every
    // tie, so a
    // board with nothing in the way keeps the note exactly where it was.
    final keepOut = <Rect>[];
    for (final p in _players) {
      if (p.id == kDrillNoteId || p.markerShape == MarkerShape.text) continue;
      for (final pt in [p.position, ...p.moves]) {
        keepOut.add(Rect.fromCenter(
            center: pt,
            width: kPlayerIconSize * 1.2 * p.scale,
            height: kPlayerIconSize * 1.8 * p.scale));
      }
    }
    const goalSports = {
      SportType.soccer,
      SportType.fieldHockey,
      SportType.handball,
      SportType.waterPolo,
    };
    if (!sideways && goalSports.contains(_sportType)) {
      final gw = court.width * 0.16, gd = court.height * 0.035 + 6;
      keepOut
        ..add(Rect.fromLTRB(court.center.dx - gw / 2, court.top - gd,
            court.center.dx + gw / 2, court.top + 2))
        ..add(Rect.fromLTRB(court.center.dx - gw / 2, court.bottom - 2,
            court.center.dx + gw / 2, court.bottom + gd));
    }
    double covers(Offset c) {
      final r = Rect.fromCenter(center: c, width: extentX, height: extentY);
      var a = 0.0;
      for (final k in keepOut) {
        final x = r.intersect(k);
        if (!x.isEmpty && x.width > 0 && x.height > 0) a += x.width * x.height;
      }
      return a;
    }

    List<Offset> spots(Rect b) {
      // Across the band (its short side) and along it (its long side).
      final across = sideways
          ? [b.center.dx, b.right - extentX / 2 - margin, b.left + extentX / 2 + margin]
          : [b.center.dy, b.bottom - extentY / 2 - margin, b.top + extentY / 2 + margin];
      final along = sideways
          ? [h / 2, extentY / 2 + margin, h - extentY / 2 - margin]
          : [w / 2, extentX / 2 + margin, w - extentX / 2 - margin];
      return [
        for (final l in along)
          for (final c in across)
            sideways
                ? Offset(fit(c, extentX, w), fit(l, extentY, h))
                : Offset(fit(l, extentX, w), fit(c, extentY, h)),
      ];
    }

    var at = Offset(
      fit(band.center.dx, extentX, w),
      fit(band.center.dy, extentY, h),
    );
    var best = covers(at);
    if (best > 0) {
      for (final c in spots(band)) {
        final v = covers(c);
        if (v < best - 0.5) {
          best = v;
          at = c;
        }
      }
      // The band under a pitch on a tablet is a few points deeper than the
      // chip, and the goal stands in it. Rather than print the sentence
      // over the goal, lay it just inside the end line — over the goal
      // area's markings, if no one stands there.
      if (best > 0.5 && !sideways && goalSports.contains(_sportType)) {
        final inside = flip
            ? court.top + 4 + extentY / 2
            : court.bottom - 4 - extentY / 2;
        final c = Offset(fit(w / 2, extentX, w), inside);
        if (covers(c) < best - 0.5) at = c;
      }
    }
    // A drill zoomed to one half (only where the zoom is worth having —
    // see applyViewFrame) keeps its note on show. Upright: just past the
    // half's own edge, over the empty half, where nobody stands (that is
    // what makes it a one-half drill). Sideways the bands run the canvas's
    // whole length: slide the note along its band into the half.
    final win = viewFrameWindow();
    double? noteScale;
    if (_viewWindow != null && win != null && _frameZoomFor(win) >= 1.05) {
      // A drill's own close-up (a lineout at Law 18's spacing). The note is
      // drawn at 1/zoom, so on the screen it is its usual size, and laid
      // inside what the screen shows: at its foot, or its head when the
      // foot is where the players are.
      final z = _frameZoomFor(win);
      noteScale = 1 / z;
      final vis = _visibleFor(win, z);
      final ex = extentX / z, ey = extentY / z, m = margin / z;
      final cands = sideways
          ? [
              Offset(vis.right - ex / 2 - m, vis.center.dy),
              Offset(vis.left + ex / 2 + m, vis.center.dy),
            ]
          : [
              Offset(vis.center.dx, vis.bottom - ey / 2 - m),
              Offset(vis.center.dx, vis.top + ey / 2 + m),
            ];
      final cell =
          kPlayerIconBase *
              boardFigureScaleFor(_canvasSize,
                  sport: _sportType, sideways: sideways) *
              _figureScale /
              z;
      double hits(Offset c) {
        final r = Rect.fromCenter(center: c, width: ex, height: ey);
        var a = 0.0;
        for (final p in _players) {
          if (p.id == kDrillNoteId || p.markerShape == MarkerShape.text) {
            continue;
          }
          for (final pt in [p.position, ...p.moves]) {
            final x = r.intersect(Rect.fromCenter(
                center: pt, width: cell * 1.2, height: cell * 1.8));
            if (x.width > 0 && x.height > 0) a += x.width * x.height;
          }
        }
        return a;
      }

      at = hits(cands[1]) < hits(cands[0]) - 0.01 ? cands[1] : cands[0];
    } else if (win != null &&
        _frameZoomFor(win) >= 1.05 &&
        !Rect.fromCenter(center: at, width: extentX, height: extentY)
            .intersect(win)
            .size
            .contains(Offset(extentX - 0.5, extentY - 0.5))) {
      if (sideways) {
        at = Offset(at.dx, fit(win.center.dy, extentY, h));
        final lo = win.top + extentY / 2 + margin;
        final hi = win.bottom - extentY / 2 - margin;
        if (lo <= hi) at = Offset(at.dx, at.dy.clamp(lo, hi));
      } else {
        at = Offset(
            fit(w / 2, extentX, w),
            fit(
                _viewFrame == 'bottom'
                    ? win.top - extentY / 2 - margin
                    : win.bottom + extentY / 2 + margin,
                extentY,
                h));
      }
    }
    // Upright either way: a text element counter-turns with the board
    // (turnedForText), so sideways it already reads level on the screen.
    _players.add(kept != null
        ? kept.copyWith(position: at, rotation: 0, scale: noteScale)
        : PlayerIcon(
            id: kDrillNoteId,
            label: drillBeats.first,
            team: PlayerTeam.neutral,
            markerShape: MarkerShape.text,
            customColor: const Color(0xFF263238),
            position: at,
            rotation: 0,
            scale: noteScale ?? 1.0,
          ));
    notePlacedSideways = sideways;
    _syncDrillNote();
    // Written now, not at the next rate-limited notify: the load that put
    // the drill here autosaved a moment ago, so this one would be skipped,
    // and a board killed before the next edit came back without its note.
    saveWorkingBoard();
    // The zoom takes the note in, so it is laid out again now that the
    // note has a place.
    if (_viewFrame != null) {
      applyViewFrame();
      return;
    }
    notifyListeners();
  }

  /// Keep the note reading the beat the board is on. Step 0 is the set-up,
  /// which the board is already showing, so it keeps the first beat's words
  /// rather than going blank and leaving an empty chip behind.
  void _syncDrillNote() {
    if (drillBeats.isEmpty) return;
    final i = _players.indexWhere((p) => p.id == kDrillNoteId);
    if (i < 0) return;
    final step = (_atStep < 1 ? 1 : _atStep);
    if (step > drillBeats.length) return;
    final text = drillBeats[step - 1];
    if (_players[i].label == text) return;
    _players[i] = _players[i].copyWith(label: text);
  }

  /// Rewrite — or empty, which is how one is deleted — the sentence under
  /// the court for one beat. The coach's words from then on, saved with the
  /// board like everything else on it.
  void setDrillBeat(int step, String text) {
    if (step < 1 || step > drillBeats.length) return;
    final next = [...drillBeats];
    next[step - 1] = text.trim();
    drillBeats = next;
    notifyListeners();
  }

  String? currentTacticName;

  /// Metadata of the board currently on the canvas, when it came from (or was
  /// last written to) disk. Lets a quick-save preserve description/folder.
  TacticMeta? currentTacticMeta;

  String? _editingFromPlan;
  String? get editingFromPlan => _editingFromPlan;
  set editingFromPlan(String? v) {
    if (_editingFromPlan == v) return;
    _editingFromPlan = v;
    notifyListeners();
  }

  /// The plan being run while its board is open. Notifies: the board's back
  /// button reads it through a Selector, and as a bare field a cleared name
  /// never reached it — every Back pushed one more run page, endlessly.
  String? _runningPlanName;
  String? get runningPlanName => _runningPlanName;
  set runningPlanName(String? v) {
    if (_runningPlanName == v) return;
    _runningPlanName = v;
    notifyListeners();
  }

  int runningItemIndex = 0;

  /// Persist the board as `<name>.json`.
  ///
  /// [meta] carries the folder/description/coaching points. When omitted (the
  /// quick-save path, which has no form to fill in) the metadata already on
  /// disk is preserved and only `updatedAt` moves forward.
  Future<String> saveTactics(String name, {TacticMeta? meta}) async {
    final dir = await _tacticsDir;
    final file = File('${dir.path}/$name.json');
    final onDisk = await readTacticMeta(name);
    // Only fall back to the in-memory meta when it describes *this* board:
    // "save current board as a new tactic" must not inherit the previous
    // board's folder and description. But when readTacticMeta comes back null
    // because the file failed to parse, it keeps a quick-save from wiping the
    // folder and notes of the board the user is looking at.
    final inMemory = name == currentTacticName ? currentTacticMeta : null;
    final base = meta ?? onDisk ?? inMemory ?? TacticMeta.initial(name);
    final resolved = TacticMeta(
      name: name,
      folder: base.folder,
      description: base.description,
      coachingPoints: base.coachingPoints,
      // A board keeps its own birthday. Saving board A's canvas over board B
      // must not stamp A's createdAt onto B.
      createdAt: onDisk?.createdAt ?? base.createdAt,
      updatedAt: DateTime.now(),
    );
    final payload = toJson()..['meta'] = resolved.toJson();
    await file.writeAsString(jsonEncode(payload));
    currentTacticName = name;
    currentTacticMeta = resolved;
    await _registerFolder(resolved.folder);
    CloudSyncService.markLocalChange();
    if (AuthService.instance.isLoggedIn) {
      SyncService.instance.pushTactic(name, _sportType.name, payload);
    }
    return file.path;
  }

  Future<void> loadTactics(String name) async {
    final dir = await _tacticsDir;
    final file = File('${dir.path}/$name.json');
    if (!await file.exists()) return;
    // Recorded here rather than at the call sites: a saved board is opened
    // from the library sheet, the home page and the plan runner, and a
    // "recent" list that misses one of them is worse than none.
    unawaited(RecentBoardsService.instance.record(
      _sportType,
      RecentBoard(
        kind: RecentBoardKind.tactic,
        id: name,
        label: name,
        openedAt: DateTime.now(),
      ),
    ));
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    loadFromJson(json);
    currentTacticName = name;
    currentTacticMeta = _metaFromPayload(json, name);
  }

  Future<List<String>> listSavedTactics() async {
    final dir = await _tacticsDir;
    final files = await dir.list().where((f) => f.path.endsWith('.json')).toList();
    return files.map((f) => f.path.split('/').last.replaceAll('.json', '')).toList()..sort();
  }

  TacticMeta? _metaFromPayload(Map<String, dynamic> json, String name) {
    final raw = json['meta'];
    if (raw is! Map) return null;
    return TacticMeta.fromJson(Map<String, dynamic>.from(raw), name: name);
  }

  /// Metadata for a saved board, or null when the file is missing or predates
  /// the metadata format.
  Future<TacticMeta?> readTacticMeta(String name) async {
    final dir = await _tacticsDir;
    final file = File('${dir.path}/$name.json');
    if (!await file.exists()) return null;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return _metaFromPayload(json, name);
    } catch (_) {
      return null;
    }
  }

  /// Every saved board with its metadata, sorted by name. Boards saved before
  /// the metadata format get defaults so they still list and group.
  Future<List<TacticMeta>> listSavedTacticMetas() async {
    final names = await listSavedTactics();
    final metas = <TacticMeta>[];
    for (final name in names) {
      metas.add(await readTacticMeta(name) ?? TacticMeta.initial(name));
    }
    return metas;
  }

  // ── Folders ──────────────────────────────────────────────────────────────
  // Folders are a label on the board, not a directory: SyncService keys tactics
  // by bare name, so nesting the files would break cloud sync. The user's
  // folder names persist in prefs so an empty folder survives.

  String get _folderPrefsKey => 'tactic_folders_${_sportType.name}';

  Future<void> _registerFolder(String folder) async {
    if (folder.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_folderPrefsKey) ?? [];
    if (saved.contains(folder)) return;
    await prefs.setStringList(_folderPrefsKey, [...saved, folder]);
  }

  Future<void> createFolder(String folder) => _registerFolder(folder.trim());

  /// User-created folders unioned with folders actually in use, sorted.
  ///
  /// [knownMetas] lets a caller that already listed the boards skip a second
  /// full read-and-decode of every saved file. The scan is only needed for
  /// folders that never passed through [_registerFolder] locally — boards
  /// pulled down from another device.
  Future<List<String>> listFolders({List<TacticMeta>? knownMetas}) async {
    final prefs = await SharedPreferences.getInstance();
    final folders = <String>{...?prefs.getStringList(_folderPrefsKey)};
    for (final meta in knownMetas ?? await listSavedTacticMetas()) {
      if (meta.folder.isNotEmpty) folders.add(meta.folder);
    }
    return folders.toList()..sort();
  }

  Future<void> deleteTactics(String name) async {
    final dir = await _tacticsDir;
    final file = File('${dir.path}/$name.json');
    if (await file.exists()) await file.delete();
    if (currentTacticName == name) currentTacticName = null;
    await PracticeService.purgeTacticReferences(_sportType, name);
    CloudSyncService.markLocalChange();
    if (AuthService.instance.isLoggedIn) {
      SyncService.instance.deleteTacticByName(name, _sportType.name);
    }
  }

  Future<void> renameTactics(String oldName, String newName) async {
    final dir = await _tacticsDir;
    final oldFile = File('${dir.path}/$oldName.json');
    final newFile = File('${dir.path}/$newName.json');
    if (!await oldFile.exists()) return;
    if (await newFile.exists()) throw Exception('name_exists');
    await oldFile.rename(newFile.path);
    if (currentTacticName == oldName) currentTacticName = newName;
    await PracticeService.renameTacticReferences(_sportType, oldName, newName);
    CloudSyncService.markLocalChange();
    if (AuthService.instance.isLoggedIn) {
      // Cloud: remove old; next save will push the new name
      SyncService.instance.deleteTacticByName(oldName, _sportType.name);
      try {
        final payload = jsonDecode(await newFile.readAsString()) as Map<String, dynamic>;
        SyncService.instance.pushTactic(newName, _sportType.name, payload);
      } catch (_) {}
    }
  }
}
