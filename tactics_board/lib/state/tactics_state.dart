import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../painters/soccer_court_painter.dart';
import '../models/court_layout.dart';
import '../models/player_icon.dart';
import '../models/player_role.dart';
import '../models/drawing_stroke.dart';
import '../models/sport_formation.dart';
import '../models/sport_type.dart';
import '../models/tactic_meta.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/practice_service.dart';
import '../services/sync_service.dart';

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

  TacticsState({SportType sportType = SportType.basketball})
      : _sportType = sportType {
    _initExternalDisplay();
    _loadFieldPrefs();
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
    notifyListeners();
  }

  // Called when animation finishes naturally — keep final positions
  void finishAnimation() {
    _isAnimating = false;
    _atStep = _animToStep >= 0 ? _animToStep : maxMoveSteps;
    notifyListeners();
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
    }
  }

  void updateAnimatedPositions(Map<String, Offset> positions) {
    _animatedPositions = positions;
    notifyListeners();
  }

  // Sport switching
  void setSportType(SportType type) {
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

  void toggleShowMoveLines() {
    _showMoveLines = !_showMoveLines;
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
  }

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
    _players[idx] = _players[idx].copyWith(position: newPosition);
    notifyListeners();
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

  void movePlayerEnd(String id, Offset newPosition) {
    _saveSnapshot();
    _resetAnimationState();
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    _players[idx] = _players[idx].copyWith(position: newPosition);
    notifyListeners();
  }

  void updatePlayer(String id, {String? label, Color? customColor, bool clearCustomColor = false, double? scale}) {
    _resetAnimationState();
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    _saveSnapshot();
    _players[idx] = _players[idx].copyWith(
      label: label,
      customColor: customColor,
      clearCustomColor: clearCustomColor,
      scale: scale,
    );
    notifyListeners();
  }

  void removePlayer(String id) {
    _saveSnapshot();
    _resetAnimationState();
    _players.removeWhere((p) => p.id == id);
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

  void _rescalePlayers(Size size) {
    if (_canvasSize.width > 0 && _canvasSize.height > 0 && _players.isNotEmpty) {
      final sx = size.width / _canvasSize.width;
      final sy = size.height / _canvasSize.height;
      for (final p in _players) {
        p.position = Offset(p.position.dx * sx, p.position.dy * sy);
        p.moves = p.moves.map((m) => Offset(m.dx * sx, m.dy * sy)).toList();
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

  /// Add players for one team only from a formation (doesn't clear existing players)
  void addTeamFromFormation(SportFormation formation, PlayerTeam team) {
    _saveSnapshot();
    _resetAnimationState();
    final field = _sportType.fieldRect(_canvasSize);
    final positions = team == PlayerTeam.home ? formation.homePositions : formation.awayPositions;

    // On a single-half soccer pitch the formation is laid out as one team
    // attacking the lone goal: goalkeeper by the goal end, the most advanced
    // player by the halfway line. Depth is normalised across the team so the
    // shape fills the visible half regardless of its full-pitch coordinates.
    final half = isSoccerHalfPitch;
    double minDy = double.infinity, maxDy = -double.infinity;
    if (half) {
      for (final r in positions) {
        if (r.dy < minDy) minDy = r.dy;
        if (r.dy > maxDy) maxDy = r.dy;
      }
    }
    final span = (maxDy - minDy).abs() < 1e-6 ? 1.0 : (maxDy - minDy);
    Offset toPos(Offset rel) {
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
      return Offset(field.left + rel.dx * field.width, field.top + rel.dy * field.height);
    }
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
  void updateStroke(String id, {Color? color, double? width, StrokeStyle? style, ArrowStyle? arrow}) {
    final idx = _strokes.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    _saveSnapshot();
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

  void clearAll() {
    if (_players.isEmpty && _strokes.isEmpty) return;
    _saveSnapshot();
    _resetAnimationState();
    _players.clear();
    _strokes.clear();
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

  Map<String, dynamic> toJson() => {
    'sportType': _sportType.index,
    'players': _players.map((p) => p.toJson()).toList(),
    'strokes': _strokes.map((s) => s.toJson()).toList(),
    'canvasWidth': _canvasSize.width,
    'canvasHeight': _canvasSize.height,
  };

  void loadFromJson(Map<String, dynamic> json) {
    _sportType = SportType.values[json['sportType'] as int];
    _players = (json['players'] as List).map((p) => PlayerIcon.fromJson(p as Map<String, dynamic>)).toList();
    _strokes = (json['strokes'] as List).map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>)).toList();
    // Rescale positions if canvas size differs
    final savedW = (json['canvasWidth'] as num?)?.toDouble() ?? _canvasSize.width;
    final savedH = (json['canvasHeight'] as num?)?.toDouble() ?? _canvasSize.height;
    if (savedW > 0 && savedH > 0 && (savedW != _canvasSize.width || savedH != _canvasSize.height)) {
      final sx = _canvasSize.width / savedW;
      final sy = _canvasSize.height / savedH;
      for (final p in _players) {
        p.position = Offset(p.position.dx * sx, p.position.dy * sy);
        p.moves = p.moves.map((m) => Offset(m.dx * sx, m.dy * sy)).toList();
      }
    }
    _selectedPlayerId = null;
    _selectedWaypointIndex = null;
    _isAnimating = false;
    _animatedPositions = {};
    _atStep = 0;
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
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

  String? runningPlanName;
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
