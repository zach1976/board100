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

/// The sports with a library on disk, in a stable order.
List<String> shippedSports() =>
    (Directory('assets/drills').listSync().whereType<File>().toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
        .where((f) => f.path.endsWith('.json'))
        .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
        .toList();

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  // Every library that ships gets the same contract, found rather than
  // listed — a new sport must not be able to skip the checks by not being
  // added here.
  for (final sport in shippedSports()) {
    _libraryTests(sport);
  }

  group('category labels speak the sport\'s language', () {
    test('a net sport calls it a rally and a serve, not possession', () {
      const net = DrillVocabulary.net;
      expect(DrillCategory.possession.labelKeyFor(net),
          'drill_cat_possession_net');
      expect(DrillCategory.setpiece.labelKeyFor(net), 'drill_cat_setpiece_net');
      expect(DrillCategory.ssg.labelKeyFor(net), 'drill_cat_ssg_net');
    });

    test('words that are already right are not overridden', () {
      // Nothing is gained by translating "Warm-up" twice, and every override
      // is a key that has to exist in twelve files.
      for (final vocab in DrillVocabulary.values) {
        expect(DrillCategory.warmup.labelKeyFor(vocab), 'drill_cat_warmup');
        expect(DrillCategory.defending.labelKeyFor(vocab), 'drill_cat_defending');
      }
      for (final c in DrillCategory.values) {
        expect(c.labelKeyFor(DrillVocabulary.pitch), c.labelKey,
            reason: 'the default labels were written for invasion sports');
      }
    });

    test('every sport has a vocabulary and every key it needs exists', () {
      final en = jsonDecode(
              File('assets/translations/en-US.json').readAsStringSync())
          as Map<String, dynamic>;
      for (final sport in SportType.values) {
        for (final c in DrillCategory.values) {
          final key = c.labelKeyFor(sport.drillVocabulary);
          expect(en.containsKey(key), isTrue,
              reason: '${sport.name} needs \'$key\' and it is not translated');
        }
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

/// The same contract for every sport that ships a library: a drill nobody can
/// run, or one that only exists in English, is not shippable content.
void _libraryTests(String sport) {
  group('the shipped $sport library', () {
    late List<Drill> drills;
    setUpAll(() => drills = loadShipped(sport));

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

    test('a CJK or Thai name is not half English', () {
      // Family names compose as "<family> <variant>", and the variant used to
      // be appended in English for every locale — a Chinese coach read
      // "步法 the forehand net". The generator now translates the variant, and
      // this is the check that keeps it that way. Terms a coach genuinely
      // writes in the Latin alphabet are listed rather than guessed at.
      const borrowed = {
        'falkenberg', 'ernie', 'australia', 'stack', 'stacking', 'drive',
        'flick', 'blitz', 'jackal', 'scrum', 'lineout', 'pivot', 'block',
        'slice', 'drop', 'dropshot', 'lob', 'net', 'kick', 'switch', 'loop',
        'rondo', 'pepper', 'perimeter', 'payung', 'touch', 'rugby',
      };
      final latin = RegExp(r'[A-Za-z]{3,}');
      for (final d in drills) {
        for (final loc in ['zh-CN', 'zh-TW', 'ja-JP', 'ko-KR', 'th-TH']) {
          final name = d.localizedName(loc);
          for (final word in latin.allMatches(name).map((m) => m[0]!)) {
            expect(borrowed, contains(word.toLowerCase()),
                reason: '${d.id} reads "$name" in $loc');
          }
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
        expect(d.board['sportType'],
            SportType.values.firstWhere((s) => s.name == sport).index,
            reason: d.id);
      }
    });

    test('the free set can run a whole session on its own', () {
      // A starter library that can't start anything is an advert. The free
      // drills have to span warm-up through a game.
      final free = drills.where((d) => d.free).toList();
      expect(free.length, greaterThanOrEqualTo(10));
      final freeCategories = free.map((d) => d.category).toSet();
      for (final needed in DrillCategory.values) {
        expect(freeCategories, contains(needed),
            reason: 'nothing free in $needed — the free session has a hole');
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

    test('every drill loads onto a board and lands inside it', () {
      final sportType = SportType.values.firstWhere((s) => s.name == sport);
      for (final drill in drills) {
        final state = TacticsState(sportType: sportType);
        state.setCanvasSizeSilent(const Size(400, 800));

        state.loadFromJson(Map<String, dynamic>.from(drill.board));

        expect(state.players, isNotEmpty, reason: drill.id);
        // Authored on a 1000x1500 canvas; loading rescales.
        for (final p in state.players) {
          expect(p.position.dx, inInclusiveRange(0, 400), reason: drill.id);
          expect(p.position.dy, inInclusiveRange(0, 800), reason: drill.id);
        }
      }
    });

    test('players stand on the playing surface, not in the margin', () {
      // A basketball court leaves 14% of the canvas empty at each side; a
      // player standing there is off the floor. Two exemptions, both real:
      // drills flagged offSurface (a throw-in taker is behind the touchline
      // by the rules), and equipment — cones mark channels and gates that sit
      // outside the lines on purpose.
      final sportType = SportType.values.firstWhere((s) => s.name == sport);
      final field = sportType.fieldRect(const Size(1000, 1500));
      for (final d in drills) {
        if (d.offSurface) continue;
        for (final p in (d.board['players'] as List).cast<Map>()) {
          if ((p['markerShape'] as int? ?? 0) != 0) continue; // equipment
          final pos = (p['position'] as List).cast<num>();
          expect(pos[0], inInclusiveRange(field.left - 12, field.right + 12),
              reason: '${d.id}/${p['id']} is off the surface');
          expect(pos[1], inInclusiveRange(field.top - 12, field.bottom + 12),
              reason: '${d.id}/${p['id']} is off the surface');
        }
      }
    });
  });
}
