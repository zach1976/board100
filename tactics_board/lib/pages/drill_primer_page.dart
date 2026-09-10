import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sport_type.dart';
import '../state/tactics_state.dart';
import '../ui/primitives.dart';
import '../ui/tokens.dart';
import '../widgets/tactics_canvas.dart';

/// How to read a drill board — the one thing the library never says.
///
/// Every drill ships a diagram whose marks a coach has to decode before the
/// drill is worth anything: which token is where a player WAS, which ring is
/// a stop on his run, why the ball sits beside a player rather than on him,
/// and what the steps count. None of that is written down anywhere, so a
/// coach either works it out or quietly stops trusting the pictures.
///
/// The examples are the real canvas with a real little board loaded, not
/// drawings of it, so what this page teaches cannot drift from what the
/// library shows.
class DrillPrimerPage extends StatefulWidget {
  final SportType sportType;
  const DrillPrimerPage({super.key, required this.sportType});

  static Future<void> push(BuildContext context, SportType sportType) {
    return Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => DrillPrimerPage(sportType: sportType),
    ));
  }

  @override
  State<DrillPrimerPage> createState() => _DrillPrimerPageState();
}

class _DrillPrimerPageState extends State<DrillPrimerPage> {
  late final TacticsState _run;
  late final TacticsState _ball;

  @override
  void initState() {
    super.initState();
    _run = _board(_runExample());
    _ball = _board(_passExample());
  }

  TacticsState _board(List<Map<String, dynamic>> players) {
    return TacticsState(sportType: widget.sportType, preview: true)
      ..loadFromJson({
        'sportType': widget.sportType.index,
        'players': players,
        'strokes': const [],
        'canvasWidth': 1000.0,
        'canvasHeight': 1500.0,
      });
  }

  @override
  void dispose() {
    _run.dispose();
    _ball.dispose();
    super.dispose();
  }

  Map<String, dynamic> _player(String id, String label, int team, double x,
          double y, {List<List<double>> moves = const [],
          List<int> phases = const [], int? ball}) =>
      {
        'id': id,
        'label': label,
        'team': team,
        'sportType': ball,
        'position': [x, y],
        'scale': 1.0,
        'moves': moves,
        'movePhases': phases,
        'moveColor': 4282434815,
        'customColor': null,
        'gender': 2,
        'markerShape': 0,
        'photoId': null,
        'role': null,
        'attachedTo': null,
      };

  /// One player with two legs — a start, a stop, an end — and beside him one
  /// whose shift is shorter than a token, so every mark the captions name has
  /// something on the board to point at.
  List<Map<String, dynamic>> _runExample() => [
        _player('d0', '7', 0, 300, 1050,
            moves: [
              [300, 700],
              [640, 420]
            ],
            phases: [0, 1]),
        _player('d1', '3', 0, 760, 900,
            moves: [
              [790, 830]
            ],
            phases: [0]),
      ];

  /// A pass: two players and a ball that leaves one and arrives at the other.
  List<Map<String, dynamic>> _passExample() => [
        _player('d0', '4', 0, 280, 1000),
        _player('d1', '9', 0, 700, 560),
        _player('b0', '', 2, 320, 1070,
            moves: [
              [740, 630]
            ],
            phases: [0],
            ball: widget.sportType.index),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.bg0,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(T.s8, T.s8, T.screenX, T.s8),
              child: Row(
                children: [
                  TacticalIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: T.s4),
                  Expanded(
                    child: Text('learn_primer_title'.tr(),
                        style: const TextStyle(
                            color: T.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    T.screenX, 0, T.screenX, T.s32),
                children: [
                  Text('learn_primer_intro'.tr(),
                      style: const TextStyle(
                          color: T.textDim, fontSize: 14.5, height: 1.5)),
                  const SizedBox(height: T.s20),
                  _Example(
                    state: _run,
                    title: 'learn_run_title'.tr(),
                    lines: [
                      'learn_run_1'.tr(),
                      'learn_run_2'.tr(),
                      'learn_run_3'.tr(),
                      'learn_run_4'.tr(),
                    ],
                  ),
                  const SizedBox(height: T.s24),
                  _Example(
                    state: _ball,
                    title: 'learn_ball_title'.tr(),
                    lines: [
                      'learn_ball_1'.tr(),
                      'learn_ball_2'.tr(),
                      'learn_ball_3'.tr(),
                    ],
                  ),
                  const SizedBox(height: T.s24),
                  _Block(
                    title: 'learn_steps_title'.tr(),
                    lines: ['learn_steps_1'.tr(), 'learn_steps_2'.tr()],
                  ),
                  const SizedBox(height: T.s24),
                  _Block(
                    title: 'learn_note_title'.tr(),
                    lines: [
                      'learn_note_purpose'.tr(),
                      'learn_note_freq'.tr(),
                      'learn_note_origin'.tr(),
                      'learn_note_setup'.tr(),
                      'learn_note_route'.tr(),
                      'learn_note_seq'.tr(),
                      'learn_note_point'.tr(),
                      'learn_note_mistake'.tr(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A caption beside the thing it describes, on the real canvas.
class _Example extends StatelessWidget {
  final TacticsState state;
  final String title;
  final List<String> lines;
  const _Example(
      {required this.state, required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: T.text, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: T.s12),
        // Full width, captions underneath. A token is a fixed 44pt whatever
        // size the board is drawn at, so in a thumbnail beside the text it
        // covers 38% of the pitch instead of 11% and the marks stop looking
        // like the marks — the ball drawn "beside" a player buried his
        // number, on the very line that says it does not. At the width the
        // library is read at, they are the same picture.
        ClipRRect(
          borderRadius: T.brSm,
          child: AspectRatio(
            aspectRatio: 402 / 730,
            child: ChangeNotifierProvider<TacticsState>.value(
              value: state,
              child: const IgnorePointer(child: TacticsCanvas(preview: true)),
            ),
          ),
        ),
        const SizedBox(height: T.s12),
        for (final l in lines) ...[
          _Bullet(text: l),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _Block extends StatelessWidget {
  final String title;
  final List<String> lines;
  const _Block({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: T.text, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: T.s12),
        for (final l in lines) ...[
          _Bullet(text: l),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    // "Label — meaning" splits so the label can carry the weight; a line with
    // no dash is just a sentence.
    final dash = text.indexOf(' — ');
    final head = dash > 0 ? text.substring(0, dash) : null;
    final body = dash > 0 ? text.substring(dash + 3) : text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(top: 7, right: 8),
          decoration: const BoxDecoration(
              color: T.accent, shape: BoxShape.circle),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              if (head != null)
                TextSpan(
                    text: '$head — ',
                    style: const TextStyle(
                        color: T.text, fontWeight: FontWeight.w600)),
              TextSpan(text: body, style: const TextStyle(color: T.textDim)),
            ]),
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }
}
