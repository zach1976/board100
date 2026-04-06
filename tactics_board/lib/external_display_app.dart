import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:external_display/external_display.dart';
import 'models/sport_type.dart';
import 'models/player_icon.dart';
import 'models/drawing_stroke.dart';
import 'painters/badminton_court_painter.dart';
import 'painters/basketball_court_painter.dart';
import 'painters/tennis_court_painter.dart';
import 'painters/table_tennis_court_painter.dart';
import 'painters/volleyball_court_painter.dart';
import 'painters/pickleball_court_painter.dart';
import 'painters/soccer_court_painter.dart';
import 'painters/drawing_painter.dart';
import 'painters/player_moves_painter.dart';
import 'widgets/player_icon_widget.dart';

/// Entry point for external display — renders court only, no toolbar.
@pragma('vm:entry-point')
void externalDisplayMain() {
  runApp(const ExternalDisplayApp());
}

class ExternalDisplayApp extends StatefulWidget {
  const ExternalDisplayApp({super.key});

  @override
  State<ExternalDisplayApp> createState() => _ExternalDisplayAppState();
}

class _ExternalDisplayAppState extends State<ExternalDisplayApp> {
  SportType _sport = SportType.basketball;
  List<PlayerIcon> _players = [];
  List<DrawingStroke> _strokes = [];
  int _atStep = 0;
  bool _showMoveLines = true;

  @override
  void initState() {
    super.initState();
    ExternalDisplay.transferParameters.addListener(_onData);
  }

  void _onData() {
    final params = ExternalDisplay.transferParameters.value;
    if (params == null) return;

    final action = params.action;
    final value = params.value;

    if (action == 'updateState' && value != null) {
      try {
        final data = jsonDecode(value) as Map<String, dynamic>;
        setState(() {
          _sport = SportType.values.firstWhere(
            (s) => s.name == data['sport'],
            orElse: () => SportType.basketball,
          );
          _players = (data['players'] as List?)
              ?.map((p) => PlayerIcon.fromJson(p as Map<String, dynamic>))
              .toList() ?? [];
          _strokes = (data['strokes'] as List?)
              ?.map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
              .toList() ?? [];
          _atStep = (data['atStep'] as int?) ?? 0;
          _showMoveLines = (data['showMoveLines'] as bool?) ?? true;
        });
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    ExternalDisplay.transferParameters.removeListener(_onData);
    super.dispose();
  }

  CustomPainter _courtPainter() {
    switch (_sport) {
      case SportType.badminton:    return const BadmintonCourtPainter();
      case SportType.basketball:   return const BasketballCourtPainter();
      case SportType.tennis:       return const TennisCourtPainter();
      case SportType.tableTennis:  return const TableTennisCourtPainter();
      case SportType.volleyball:   return const VolleyballCourtPainter();
      case SportType.pickleball:   return const PickleballCourtPainter();
      case SportType.soccer:       return const SoccerCourtPainter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF121826),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Court
                CustomPaint(
                  painter: _courtPainter(),
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                  ),
                ),
                // Move lines
                if (_showMoveLines)
                  CustomPaint(
                    painter: PlayerMovesPainter(
                      players: _players,
                      targetStep: _atStep > 0 ? _atStep : 0,
                      completedSteps: null,
                    ),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                // Drawing strokes
                CustomPaint(
                  painter: DrawingPainter(
                    strokes: _strokes,
                    currentStroke: null,
                  ),
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                ),
                // Players
                ..._players.map((player) {
                  final size = kPlayerIconSize * player.scale;
                  return Positioned(
                    left: player.position.dx - size / 2,
                    top: player.position.dy - size / 2,
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: player.isMarker
                          ? CustomPaint(painter: MarkerPainter(shape: player.markerShape, color: player.color), size: Size.infinite)
                          : CustomPaint(
                              painter: TopDownPlayerPainter(
                                color: player.color,
                                borderColor: Colors.white,
                                borderWidth: 2,
                                gender: player.gender,
                              ),
                              size: Size.infinite,
                            ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
