import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/player_icon.dart';
import '../models/drawing_stroke.dart';
import '../models/sport_formation.dart';
import '../models/sport_type.dart';

class _BoardSnapshot {
  final List<PlayerIcon> players;
  final List<DrawingStroke> strokes;

  _BoardSnapshot({required this.players, required this.strokes});
}

/// Global key used to capture the board canvas as an image for sharing.
final GlobalKey boardRepaintKey = GlobalKey();

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

  TacticsState({SportType sportType = SportType.basketball})
      : _sportType = sportType;

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
  bool get sequentialMode => _sequentialMode;
  bool get showMoveLines => _showMoveLines;
  bool get toolbarVisible => _toolbarVisible;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get isAnimating => _isAnimating;
  Map<String, Offset> get animatedPositions =>
      Map.unmodifiable(_animatedPositions);
  bool get hasMoves => _players.any((p) => p.moves.isNotEmpty);
  int get maxMoveSteps {
    // Count distinct phases across all players
    final phases = <int>{};
    for (final p in _players) {
      p.syncPhases();
      phases.addAll(p.movePhases);
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
    _animToStep = 0;
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
    _animatedPositions = {};
    _atStep = 0;
    notifyListeners();
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
             : _canvasSize.height * 0.50;
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
    _players.add(player.copyWith(
      moveColor: PlayerIcon.moveColorForIndex(_players.length),
    ));
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
    _animatedPositions = {};
    _atStep = 0; // clear overlay when manually moving
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    _players[idx] = _players[idx].copyWith(position: newPosition);
    notifyListeners();
  }

  void updatePlayer(String id, {String? label, Color? customColor, bool clearCustomColor = false}) {
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    _saveSnapshot();
    _players[idx] = _players[idx].copyWith(
      label: label,
      customColor: customColor,
      clearCustomColor: clearCustomColor,
    );
    notifyListeners();
  }

  void removePlayer(String id) {
    _saveSnapshot();
    _players.removeWhere((p) => p.id == id);
    if (_selectedPlayerId == id) _selectedPlayerId = null;
    notifyListeners();
  }

  // Player move waypoints
  void addPlayerMove(String id, Offset position) {
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    _saveSnapshot();
    final updated = List.of(_players[idx].moves)..add(position);
    _players[idx] = _players[idx].copyWith(moves: updated);
    _players[idx].syncPhases();
    notifyListeners();
  }

  void movePlayerWaypoint(String id, int index, Offset position) {
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    final updated = List.of(_players[idx].moves);
    if (index >= updated.length) return;
    updated[index] = position;
    _players[idx] = _players[idx].copyWith(moves: updated);
    notifyListeners();
  }

  void movePlayerWaypointEnd(String id) {
    _saveSnapshot();
  }

  void removePlayerWaypoint(String id, int index) {
    final idx = _players.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    _saveSnapshot();
    final updated = List.of(_players[idx].moves)..removeAt(index);
    _players[idx] = _players[idx].copyWith(moves: updated);
    _players[idx].syncPhases();
    notifyListeners();
  }

  void setMovePhase(String playerId, int moveIndex, int phase) {
    final idx = _players.indexWhere((p) => p.id == playerId);
    if (idx < 0) return;
    _saveSnapshot();
    final phases = List.of(_players[idx].movePhases);
    if (moveIndex >= phases.length) return;
    phases[moveIndex] = phase.clamp(0, 99);
    _players[idx] = _players[idx].copyWith(movePhases: phases);
    notifyListeners();
  }

  /// Total number of distinct phases across all players
  int get maxPhase {
    int max = 0;
    for (final p in _players) {
      p.syncPhases();
      for (final ph in p.movePhases) {
        if (ph > max) max = ph;
      }
    }
    return max;
  }

  void selectPlayer(String? id) {
    _selectedPlayerId = id;
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
    _players.clear();
    _selectedPlayerId = null;
    final w = _canvasSize.width;
    final h = _canvasSize.height;
    int homeNum = 1;
    int awayNum = 1;
    int colorIdx = 0;
    for (int i = 0; i < formation.homePositions.length; i++) {
      final rel = formation.homePositions[i];
      _players.add(PlayerIcon(
        id: '${DateTime.now().microsecondsSinceEpoch}_h$homeNum',
        label: '$homeNum',
        team: PlayerTeam.home,
        gender: homeGenders != null && i < homeGenders.length ? homeGenders[i] : PlayerGender.unspecified,
        position: Offset(rel.dx * w, rel.dy * h),
        moveColor: PlayerIcon.moveColorForIndex(colorIdx++),
      ));
      homeNum++;
    }
    for (int i = 0; i < formation.awayPositions.length; i++) {
      final rel = formation.awayPositions[i];
      _players.add(PlayerIcon(
        id: '${DateTime.now().microsecondsSinceEpoch}_a$awayNum',
        label: '$awayNum',
        team: PlayerTeam.away,
        gender: awayGenders != null && i < awayGenders.length ? awayGenders[i] : PlayerGender.unspecified,
        position: Offset(rel.dx * w, rel.dy * h),
        moveColor: PlayerIcon.moveColorForIndex(colorIdx++),
      ));
      awayNum++;
    }
    notifyListeners();
  }

  /// Add players for one team only from a formation (doesn't clear existing players)
  void addTeamFromFormation(SportFormation formation, PlayerTeam team) {
    _saveSnapshot();
    final w = _canvasSize.width;
    final h = _canvasSize.height;
    final positions = team == PlayerTeam.home ? formation.homePositions : formation.awayPositions;
    final existingCount = _players.where((p) => p.team == team).length;
    int num = existingCount + 1;
    int colorIdx = _players.length;
    for (final rel in positions) {
      _players.add(PlayerIcon(
        id: '${DateTime.now().microsecondsSinceEpoch}_${team == PlayerTeam.home ? 'h' : 'a'}$num',
        label: '$num',
        team: team,
        position: Offset(rel.dx * w, rel.dy * h),
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
      _strokes.add(_currentStroke!);
    }
    _currentStroke = null;
    notifyListeners();
  }

  void clearStrokes() {
    if (_strokes.isEmpty) return;
    _saveSnapshot();
    _strokes.clear();
    notifyListeners();
  }

  void clearAll() {
    if (_players.isEmpty && _strokes.isEmpty) return;
    _saveSnapshot();
    _players.clear();
    _strokes.clear();
    _selectedPlayerId = null;
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
    _isAnimating = false;
    _animatedPositions = {};
    _atStep = 0;
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  static Future<Directory> get _tacticsDir async {
    Directory baseDir;
    try {
      baseDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      // Fallback for simulator compatibility issues
      baseDir = Directory.systemTemp;
    }
    final dir = Directory('${baseDir.path}/tactics');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> saveTactics(String name) async {
    final dir = await _tacticsDir;
    final file = File('${dir.path}/$name.json');
    await file.writeAsString(jsonEncode(toJson()));
    return file.path;
  }

  Future<void> loadTactics(String name) async {
    final dir = await _tacticsDir;
    final file = File('${dir.path}/$name.json');
    if (!await file.exists()) return;
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    loadFromJson(json);
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
  }
}
