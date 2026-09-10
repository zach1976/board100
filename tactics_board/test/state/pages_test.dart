import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// A board is a document of pages, and the two things that would hurt most if
/// they broke: one page reaching into another, and an older build choking on
/// a file it has never seen.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  TacticsState board() =>
      TacticsState(sportType: SportType.fieldHockey, preview: true)
        ..setCanvasSizeSilent(const Size(402, 730));

  void put(TacticsState s, String id) => s.addPlayer(PlayerIcon(
        id: id,
        label: id,
        team: PlayerTeam.home,
        position: const Offset(100, 100),
      ));

  List<String> labels(TacticsState s) =>
      s.players.map((p) => p.label).toList()..sort();

  test('a fresh board is one page', () {
    final s = board();
    expect(s.pageCount, 1);
    expect(s.pageIndex, 0);
  });

  test('pages do not reach into each other', () {
    final s = board();
    put(s, 'a');
    s.addPage();
    expect(s.pageIndex, 1);
    expect(s.players, isEmpty, reason: 'a blank page is blank');

    put(s, 'b');
    s.goToPage(0);
    expect(labels(s), ['a']);
    s.goToPage(1);
    expect(labels(s), ['b']);
  });

  test('duplicating copies the page and then leaves the original alone', () {
    final s = board();
    put(s, 'a');
    s.addPage(copyCurrent: true);
    expect(labels(s), ['a'], reason: 'the copy starts identical');

    put(s, 'b');
    s.goToPage(0);
    expect(labels(s), ['a'], reason: 'editing the copy must not touch page 1');
  });

  test('undo on one page cannot reach the other', () {
    // The risk the plan called out: undo is per page, or a coach fixing a
    // slip on page 2 silently rewrites page 1.
    final s = board();
    put(s, 'a');
    s.addPage();
    put(s, 'b');
    put(s, 'c');
    s.undo();
    expect(labels(s), ['b'], reason: 'undo took back the last thing here');

    s.goToPage(0);
    expect(labels(s), ['a'], reason: 'page 1 is untouched');
  });

  test('the last page cannot be deleted', () {
    final s = board();
    s.deletePage(0);
    expect(s.pageCount, 1, reason: 'a document with no pages is a crash');
  });

  test('deleting a page keeps the others', () {
    final s = board();
    put(s, 'a');
    s.addPage();
    put(s, 'b');
    s.addPage();
    put(s, 'c');
    expect(s.pageCount, 3);

    s.deletePage(1);
    expect(s.pageCount, 2);
    s.goToPage(0);
    expect(labels(s), ['a']);
    s.goToPage(1);
    expect(labels(s), ['c']);
  });

  test('pages survive a save and load', () {
    final s = board();
    put(s, 'a');
    s.addPage();
    put(s, 'b');
    final saved = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;

    final back = board()..loadFromJson(saved);
    expect(back.pageCount, 2);
    expect(back.pageIndex, 1, reason: 'it reopens on the page you left');
    expect(labels(back), ['b']);
    back.goToPage(0);
    expect(labels(back), ['a']);
  });

  test('a build that has never heard of pages reads page one', () {
    // Page 1 stays at the top level where a one-page board has always kept
    // it, so an older app opens this file and shows the first page rather
    // than failing. This is the compatibility promise, tested by reading the
    // file the way that build would.
    final s = board();
    put(s, 'a');
    s.addPage();
    put(s, 'b');
    final saved = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;

    final asOldBuildSeesIt = Map<String, dynamic>.from(saved)
      ..remove('pages')
      ..remove('pageIndex');
    final back = board()..loadFromJson(asOldBuildSeesIt);
    expect(back.pageCount, 1);
    expect(labels(back), ['a'], reason: 'the first page, not the last one');
  });

  test('a board saved before pages existed opens as one page', () {
    final one = board();
    put(one, 'a');
    final legacy = jsonDecode(jsonEncode(one.toJson())) as Map<String, dynamic>;
    expect(legacy.containsKey('pages'), isFalse,
        reason: 'a one-page board writes no page list at all');

    final back = board()..loadFromJson(legacy);
    expect(back.pageCount, 1);
    expect(labels(back), ['a']);
  });
}
