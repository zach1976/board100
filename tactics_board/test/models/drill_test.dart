import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/drill.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// The shipped library, read straight off disk — these tests are about the
/// content being loadable and coherent, not about a hand-built fixture.
List<Drill> loadShipped(String sport) {
  final file = File('assets/drills/$sport.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return (json['drills'] as List)
      .map((d) => Drill.fromJson(d as Map<String, dynamic>))
      .toList();
}

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('the shipped soccer library', () {
    late List<Drill> drills;
    setUpAll(() => drills = loadShipped('soccer'));

    test('is not empty and has unique ids', () {
      expect(drills, isNotEmpty);
      expect(drills.map((d) => d.id).toSet().length, drills.length);
    });

    test('covers every category a session is built from', () {
      final covered = drills.map((d) => d.category).toSet();
      for (final needed in [
        DrillCategory.warmup,
        DrillCategory.possession,
        DrillCategory.attacking,
        DrillCategory.finishing,
        DrillCategory.defending,
        DrillCategory.setpiece,
        DrillCategory.ssg,
      ]) {
        expect(covered, contains(needed), reason: 'no $needed drill to plan with');
      }
    });

    test('every drill is named in all 12 shipped locales', () {
      const locales = ['en-US', 'en-GB', 'zh-CN', 'zh-TW', 'ja-JP', 'ko-KR',
                       'es-ES', 'fr-FR', 'id-ID', 'ms-MY', 'th-TH', 'vi-VN'];
      for (final d in drills) {
        for (final loc in locales) {
          expect(d.localizedName(loc), isNotEmpty, reason: '${d.id} has no name for $loc');
          expect(d.localizedNote(loc), isNotEmpty, reason: '${d.id} has no note for $loc');
        }
      }
    });

    test('every drill carries a runnable board', () {
      for (final d in drills) {
        expect(d.minutes, greaterThan(0), reason: d.id);
        expect(d.players, greaterThan(0), reason: d.id);
        final players = d.board['players'] as List;
        expect(players, isNotEmpty, reason: d.id);
        expect(d.board['canvasWidth'], greaterThan(0));
        expect(d.board['sportType'], SportType.soccer.index, reason: d.id);
      }
    });

    test('most drills animate — a still shape is a diagram, not a drill', () {
      final animated = drills.where((d) => (d.board['players'] as List)
          .any((p) => ((p as Map)['moves'] as List).isNotEmpty));
      expect(animated.length / drills.length, greaterThan(0.8));
    });

    test('phases are contiguous from zero, so playback has no dead steps', () {
      for (final d in drills) {
        final phases = <int>{};
        for (final p in d.board['players'] as List) {
          phases.addAll(((p as Map)['movePhases'] as List).cast<int>());
        }
        if (phases.isEmpty) continue;
        final sorted = phases.toList()..sort();
        expect(sorted.first, 0, reason: '${d.id} starts at phase ${sorted.first}');
        for (var i = 1; i < sorted.length; i++) {
          expect(sorted[i] - sorted[i - 1], 1,
              reason: '${d.id} skips a phase between ${sorted[i - 1]} and ${sorted[i]}');
        }
      }
    });

    test('a ball attached to a player names a player that exists', () {
      for (final d in drills) {
        final players = (d.board['players'] as List).cast<Map>();
        final ids = players.map((p) => p['id']).toSet();
        for (final p in players) {
          if (p['attachedTo'] != null) {
            expect(ids, contains(p['attachedTo']), reason: '${d.id} ball points at nobody');
          }
        }
      }
    });

    test('loads onto a board exactly like a saved tactic', () {
      final state = TacticsState(sportType: SportType.soccer);
      state.setCanvasSizeSilent(const Size(400, 800));
      final drill = drills.firstWhere((d) => d.id == 'rondo_4v2');

      state.loadFromJson(Map<String, dynamic>.from(drill.board));

      expect(state.players, isNotEmpty);
      expect(state.players.where((p) => p.team == PlayerTeam.home).length, 4);
      expect(state.players.where((p) => p.team == PlayerTeam.away).length, 2);
      expect(state.hasMoves, isTrue, reason: 'the rondo has to animate');
      // Positions were authored on a 1000x1500 canvas and must be rescaled.
      for (final p in state.players) {
        expect(p.position.dx, inInclusiveRange(0, 400));
        expect(p.position.dy, inInclusiveRange(0, 800));
      }
    });
  });

  group('Drill localisation', () {
    final drill = Drill(
      id: 'x', category: DrillCategory.warmup, minutes: 5, players: 2,
      name: const {'en': 'Rondo', 'zh-CN': '抢圈'},
      note: const {'en': 'Two touches'},
      board: const {'players': []},
    );

    test('exact locale wins', () => expect(drill.localizedName('zh-CN'), '抢圈'));

    test('falls back to the same language', () {
      expect(drill.localizedName('zh-SG'), '抢圈');
    });

    test('falls back to English rather than showing nothing', () {
      expect(drill.localizedName('th-TH'), 'Rondo');
      expect(drill.localizedNote('zh-CN'), 'Two touches');
    });
  });
}
