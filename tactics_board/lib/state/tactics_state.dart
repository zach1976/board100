import 'package:flutter/material.dart';
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

  TacticsState({SportType sportType = SportType.basketball})
      : _sportType = sportType;

  // Getters
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
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get isAnimating => _isAnimating;
  Map<String, Offset> get animatedPositions =>
      Map.unmodifiable(_animatedPositions);
  bool get hasMoves => _players.any((p) => p.moves.isNotEmpty);
  int get maxMoveSteps =>
      _players.fold(0, (m, p) => p.moves.length > m ? p.moves.length : m);
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

  // Called as each animation step completes (to reveal lines incrementally)
  void advanceAtStep(int step) {
    _atStep = step;
    notifyListeners();
  }

  // Called when animation finishes naturally — keep final positions
  void finishAnimation() {
    _isAnimating = false;
    _atStep = _animToStep > 0 ? _animToStep : maxMoveSteps;
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
    notifyListeners();
  }

  void selectPlayer(String? id) {
    _selectedPlayerId = id;
    notifyListeners();
  }

  void setCanvasSize(Size size) {
    _canvasSize = size;
  }

  void applyFormation(SportFormation formation) {
    _saveSnapshot();
    _players.clear();
    _selectedPlayerId = null;
    final w = _canvasSize.width;
    final h = _canvasSize.height;
    int homeNum = 1;
    int awayNum = 1;
    int colorIdx = 0;
    for (final rel in formation.homePositions) {
      _players.add(PlayerIcon(
        id: '${DateTime.now().microsecondsSinceEpoch}_h$homeNum',
        label: '$homeNum',
        team: PlayerTeam.home,
        position: Offset(rel.dx * w, rel.dy * h),
        moveColor: PlayerIcon.moveColorForIndex(colorIdx++),
      ));
      homeNum++;
    }
    for (final rel in formation.awayPositions) {
      _players.add(PlayerIcon(
        id: '${DateTime.now().microsecondsSinceEpoch}_a$awayNum',
        label: '$awayNum',
        team: PlayerTeam.away,
        position: Offset(rel.dx * w, rel.dy * h),
        moveColor: PlayerIcon.moveColorForIndex(colorIdx++),
      ));
      awayNum++;
    }
    if (formation.addBall) {
      _players.add(PlayerIcon(
        id: '${DateTime.now().microsecondsSinceEpoch}_ball',
        label: '',
        team: PlayerTeam.neutral,
        sportType: _sportType,
        position: Offset(w * 0.5, h * 0.5),
      ));
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
}
