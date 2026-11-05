import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/session_template.dart';

void main() {
  test('every bundled pack carries six sessions made of its own drills', () {
    final dir = Directory('assets/drills');
    final packs = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json') && !f.path.endsWith('index.json'));
    expect(packs, isNotEmpty);
    for (final f in packs) {
      final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final ids = {for (final d in json['drills'] as List) (d as Map)['id']};
      final plans = (json['plans'] as List)
          .map(SessionTemplate.fromJson)
          .whereType<SessionTemplate>()
          .toList();
      expect(plans.length, 6, reason: f.path);
      for (final p in plans) {
        expect(p.items.length, greaterThanOrEqualTo(4), reason: '${f.path} ${p.id}');
        expect(p.items.map((i) => i.drillId).toSet().length, p.items.length,
            reason: '${f.path} ${p.id} repeats a drill');
        for (final it in p.items) {
          expect(ids, contains(it.drillId), reason: '${f.path} ${p.id}');
          expect(it.minutes, greaterThan(0));
        }
        expect(p.totalMinutes, greaterThanOrEqualTo(30), reason: '${f.path} ${p.id}');
        for (final loc in const ['en', 'zh-CN', 'de-DE', 'nl-NL', 'ja-JP']) {
          expect(p.name[loc], isNotEmpty, reason: '${f.path} ${p.id} $loc');
        }
      }
    }
  });

  test('a name falls back by language, then English', () {
    final t = SessionTemplate.fromJson({
      'id': 'x',
      'name': {'en': 'Match week', 'zh-CN': '赛前一周'},
      'items': [
        {'drill': 'a', 'minutes': 10},
      ],
    })!;
    expect(t.nameFor('zh-CN'), '赛前一周');
    expect(t.nameFor('zh-TW'), '赛前一周');
    expect(t.nameFor('fr-FR'), 'Match week');
  });

  test('a plan with no usable item is dropped', () {
    expect(SessionTemplate.fromJson({'id': 'x', 'name': {}, 'items': []}), isNull);
    expect(SessionTemplate.fromJson({'id': 'x', 'name': {}, 'items': [{'minutes': 5}]}), isNull);
    expect(SessionTemplate.fromJson('nonsense'), isNull);
  });
}
