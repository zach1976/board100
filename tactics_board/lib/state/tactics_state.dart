import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../models/player_icon.dart';
import '../models/drawing_stroke.dart';
import '../models/sport_formation.dart';
import '../models/sport_type.dart';
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
  Color _strokeColor = const Color(0xFFFFD600);
  double _strokeWidth = 3.0;

  // Selected player
  String? _selectedPlayerId;
  // Specifically tapped waypoint index inside selected player's move chain.
  // null means the player body itself is the primary target (not a waypoint).
  int? _selectedWaypointIndex;

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

  // External display
  static const _extChannel = MethodChannel('com.zach.tacticsboard/externalDisplay');
  bool _externalConnected = false;
  bool _externalDirty = false;
  bool get externalDisplayConnected => _externalConnected;

  TacticsState({SportType sportType = SportType.basketball})
      : _sportType = sportType {
    _initExternalDisplay();
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
    // Count distinct phases across all players and strokes
    final phases = <int>{};
    for (final p in _players) {
      p.syncPhases();
      phases.addAll(p.movePhases);
    }
    for (final s in _strokes) {
      if (!s.isFullSpan) {
        for (int i = s.startPhase; i <= s.endPhase; i++) phases.add(i);
      }
    }
    return phases.length;
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

  void resetZoom() {
    transformationController.value = Matrix4.identity();
  }

  // Drawing mode
  void setDrawingMode(bool enabled) {
    _isDrawingMode = enabled;
    _selectedPlayerId = null;
    _selectedWaypointIndex = null;
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
    _resetAnimationState();
    final idx = _players.indexWhere((p) => p.id == playerId);
    if (idx < 0) return;
    _saveSnapshot();
    final phases = List.of(_players[idx].movePhases);
    if (moveIndex >= phases.length) return;
    phases[moveIndex] = phase.clamp(0, 99);
    _players[idx] = _players[idx].copyWith(movePhases: phases);
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
    _selectedPlayerId = id;
    _selectedWaypointIndex = null;
    if (id != null) _selectedStrokeId = null;
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
    notifyListeners();
  }

  /// Add players for one team only from a formation (doesn't clear existing players)
  void addTeamFromFormation(SportFormation formation, PlayerTeam team) {
    _saveSnapshot();
    _resetAnimationState();
    final field = _sportType.fieldRect(_canvasSize);
    Offset toPos(Offset rel) =>
        Offset(field.left + rel.dx * field.width, field.top + rel.dy * field.height);
    final positions = team == PlayerTeam.home ? formation.homePositions : formation.awayPositions;
    final existingCount = _players.where((p) => p.team == team).length;
    int num = existingCount + 1;
    int colorIdx = _players.length;
    for (final rel in positions) {
      _players.add(PlayerIcon(
        id: '${DateTime.now().microsecondsSinceEpoch}_${team == PlayerTeam.home ? 'h' : 'a'}$num',
        label: '$num',
        team: team,
        position: toPos(rel),
        moveColor: PlayerIcon.moveColorForIndex(colorIdx++),
      ));
      num++;
    }
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
      _strokes.add(_currentStroke!); // phase defaults to -1 (always visible)
    }
    _currentStroke = null;
    notifyListeners();
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
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_currentSnapshot());
    final snap = _redoStack.removeLast();
    _restoreSnapshot(snap);
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

  String? _editingFromPlan;
  String? get editingFromPlan => _editingFromPlan;
  set editingFromPlan(String? v) {
    if (_editingFromPlan == v) return;
    _editingFromPlan = v;
    notifyListeners();
  }

  String? runningPlanName;
  int runningItemIndex = 0;

  Future<String> saveTactics(String name) async {
    final dir = await _tacticsDir;
    final file = File('${dir.path}/$name.json');
    final payload = toJson();
    await file.writeAsString(jsonEncode(payload));
    currentTacticName = name;
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
  }

  Future<List<String>> listSavedTactics() async {
    final dir = await _tacticsDir;
    final files = await dir.list().where((f) => f.path.endsWith('.json')).toList();
    return files.map((f) => f.path.split('/').last.replaceAll('.json', '')).toList()..sort();
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
