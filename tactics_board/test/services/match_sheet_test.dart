import 'dart:convert';
import 'dart:io' show zlib;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/match_day.dart';
import 'package:tactics_board/services/pdf_export_service.dart';

/// The match-day sheet: minutes per player and the substitution log as a
/// PDF, in any language — see lineup_sheet_test for why non-Latin words
/// arrive as pictures.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MatchSheetStrings words({bool latin = true}) => latin
      ? const MatchSheetStrings(
          heading: 'Match day',
          playingTime: 'Playing time',
          substitutions: 'Substitutions',
          noSubs: 'No substitutions',
          player: 'Player',
          minutes: 'Minutes',
          time: 'Time',
          period: 'Period',
          off: 'Off',
          on: 'On',
          starter: 'starter',
        )
      : const MatchSheetStrings(
          heading: '比赛日',
          playingTime: '上场时间',
          substitutions: '换人记录',
          noSubs: '无换人',
          player: '球员',
          minutes: '分钟',
          time: '时间',
          period: '节',
          off: '下',
          on: '上',
          starter: '首发',
        );

  /// The file's objects with every Flate stream inflated, as text.
  String inflated(Uint8List bytes) {
    final raw = latin1.decode(bytes, allowInvalid: true);
    final out = StringBuffer();
    var at = 0;
    for (final m in RegExp(r'(?<!end)stream\r?\n').allMatches(raw)) {
      final end = raw.indexOf('endstream', m.end);
      if (end < 0) break;
      out.write(raw.substring(at, m.end));
      final body = bytes.sublist(m.end, end);
      try {
        out.write(latin1.decode(zlib.decode(body), allowInvalid: true));
      } catch (_) {
        out.write(raw.substring(m.end, end));
      }
      at = end;
    }
    out.write(raw.substring(at));
    return out.toString();
  }

  MatchDay match() {
    final t0 = DateTime(2026, 10, 14, 10);
    final m = MatchDay(
      name: 'vs Tigers',
      periods: 4,
      periodSeconds: 900,
      onPitch: 2,
      players: const [
        MatchPlayer(id: 'a', name: 'Ana', number: '7'),
        MatchPlayer(id: 'b', name: 'Bo', number: '9'),
        MatchPlayer(id: 'c', name: 'Cas'),
      ],
      starters: const ['a', 'b'],
      startedAt: t0,
    );
    m.start(t0);
    m.substitute('a', 'c', t0.add(const Duration(minutes: 5)));
    m.finish(t0.add(const Duration(minutes: 15)));
    return m;
  }

  test('is a PDF with the players, their minutes and the log', () async {
    final bytes =
        await PdfExportService.buildMatchSheet(match(), words: words());
    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
    final text = inflated(bytes);
    expect(RegExp(r'/Type\s*/Page[^s]').allMatches(text).length, 1);
    for (final word in ['Tigers', 'Ana', 'Cas', 'Substitutions', '05:00', '15:00']) {
      expect(text, contains(word), reason: word);
    }
  });

  test('a language Helvetica cannot set still makes a page', () async {
    final bytes = await PdfExportService.buildMatchSheet(match(),
        words: words(latin: false));
    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
    expect(inflated(bytes), contains('/Image'));
  });

  test('lists the cards and the shoot-out', () async {
    final m = match();
    // The match is finished; the record is read back as it was logged.
    m.cards.add(const MatchCard(
        playerId: 'b', kind: MatchCardKind.green, clock: 420, period: 1,
        seconds: 120));
    m.cards.add(const MatchCard(
        playerId: 'c', kind: MatchCardKind.red, clock: 800, period: 1));
    m.shootOut.addAll(const [
      ShootOutAttempt(us: true, playerId: 'a', scored: true),
      ShootOutAttempt(us: false, taker: '#4', scored: false),
      ShootOutAttempt(us: true, playerId: 'b', scored: false),
    ]);
    final bytes = await PdfExportService.buildMatchSheet(m, words: words());
    final text = inflated(bytes);
    for (final word in ['Cards', 'Green', '07:00', 'Red', 'Shoot-out', '#4', 'Miss']) {
      expect(text, contains(word), reason: word);
    }
  });

  test('a match of sets prints the set scores, sets played and the subs',
      () async {
    final m = MatchDay(
      name: 'vs Lions',
      periods: 3,
      periodSeconds: 0,
      onPitch: 2,
      players: const [
        MatchPlayer(id: 'a', name: 'Ana', number: '7'),
        MatchPlayer(id: 'b', name: 'Bo', number: '9'),
        MatchPlayer(id: 'c', name: 'Cas'),
        MatchPlayer(id: 'l', name: 'Lib'),
      ],
      starters: const ['a', 'b'],
      startedAt: DateTime(2026, 10, 14, 10),
      countsSets: true,
      rules: 'usav',
      liberos: const ['l'],
    );
    m.point(us: true, delta: 25);
    m.point(us: false, delta: 19);
    m.substitute('a', 'c');
    m.substitute('b', 'l', null, SubstitutionKind.libero);
    m.endSet();
    m.point(us: true, delta: 25);
    m.point(us: false, delta: 23);
    m.endSet();
    expect(m.isFinished, isTrue);
    final bytes = await PdfExportService.buildMatchSheet(m, words: words());
    final text = inflated(bytes);
    for (final word in ['Lions', 'USAV', '25-19', '25-23', 'Libero', 'Cas', '1/12']) {
      expect(text, contains(word), reason: word);
    }
  });
}
