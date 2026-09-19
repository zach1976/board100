import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sport_type.dart';

/// The board as the coach left it, kept across launches.
///
/// Everything else the app remembers is a thing that was named: a saved
/// tactic, a starred drill, a plan. The board itself was not — close the app
/// mid-session and the pitch came back empty, which made "open the board"
/// a lie on the home page and left its thumbnail showing bare grass forever.
/// A coach who put nine players out during a match does not expect to do it
/// twice.
///
/// One board per sport, in prefs rather than a file: it is small, it is
/// written often, and losing it is a nuisance rather than a loss — the named
/// boards are the ones that live in files.
class WorkingBoardService {
  WorkingBoardService._();
  static final instance = WorkingBoardService._();

  static String _key(SportType sport) => 'working_board_${sport.name}';

  Future<void> save(SportType sport, Map<String, dynamic> board) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(sport), jsonEncode(board));
    } catch (_) {
      // Storage full, or a board that will not encode. Losing the restore is
      // not worth interrupting whatever the coach is drawing.
    }
  }

  Future<Map<String, dynamic>?> load(SportType sport) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(sport));
      if (raw == null) return null;
      return Map<String, dynamic>.from(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Written by a newer build, or half-written. An empty board is the
      // right fallback: it is what the app did before this existed.
      return null;
    }
  }

  Future<void> clear(SportType sport) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(sport));
    } catch (_) {
      // Nothing to do: the next save overwrites it anyway.
    }
  }
}
