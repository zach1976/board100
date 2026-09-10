import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sport_type.dart';

/// What the coach had on the board last, per sport.
///
/// "Recent" cannot be read off the saved files alone: most of what goes on a
/// board is a drill out of the library, and a drill is never saved — it is a
/// starting shape the coach edits. So a board that was opened is recorded
/// here when it is opened, saved or not, and the home page can offer the
/// thing they were actually last working on rather than only the things they
/// remembered to name.
class RecentBoardsService {
  RecentBoardsService._();
  static final instance = RecentBoardsService._();

  /// Enough to fill the home page's list twice over. Older entries are
  /// dropped rather than kept forever: this is a shortcut back to what you
  /// were doing, not a history.
  static const _keep = 12;

  static String _key(SportType sport) => 'recent_boards_${sport.name}';

  Future<List<RecentBoard>> list(SportType sport) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(sport)) ?? const [];
    final out = <RecentBoard>[];
    for (final line in raw) {
      try {
        out.add(RecentBoard.fromJson(
            jsonDecode(line) as Map<String, dynamic>));
      } catch (_) {
        // A line written by a newer build, or a half-written one. Skipping it
        // is right: a broken shortcut must not cost the coach the list.
      }
    }
    return out;
  }

  /// Records [board] as the most recent, moving it up if it is already there.
  Future<void> record(SportType sport, RecentBoard board) async {
    final prefs = await SharedPreferences.getInstance();
    final kept = (await list(sport))
        .where((e) => !(e.kind == board.kind && e.id == board.id))
        .toList()
      ..insert(0, board);
    await prefs.setStringList(
      _key(sport),
      kept.take(_keep).map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  /// Drops an entry — a saved board the coach has since deleted, which would
  /// otherwise sit in the list opening nothing.
  Future<void> forget(SportType sport, RecentBoardKind kind, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final kept = (await list(sport))
        .where((e) => !(e.kind == kind && e.id == id))
        .map((e) => jsonEncode(e.toJson()))
        .toList();
    await prefs.setStringList(_key(sport), kept);
  }
}

enum RecentBoardKind {
  /// One of the coach's own saved boards, by name.
  tactic,

  /// A drill out of the shipped library, by drill id.
  drill,
}

class RecentBoard {
  final RecentBoardKind kind;

  /// The saved board's name, or the drill's id.
  final String id;

  /// What to show in the list. Held rather than looked up so a row still
  /// reads correctly for a drill whose id says nothing to anyone.
  final String label;

  final DateTime openedAt;

  const RecentBoard({
    required this.kind,
    required this.id,
    required this.label,
    required this.openedAt,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'id': id,
        'label': label,
        'at': openedAt.toIso8601String(),
      };

  factory RecentBoard.fromJson(Map<String, dynamic> json) => RecentBoard(
        kind: RecentBoardKind.values
            .firstWhere((k) => k.name == json['kind'],
                orElse: () => RecentBoardKind.tactic),
        id: json['id'] as String,
        label: json['label'] as String? ?? json['id'] as String,
        openedAt:
            DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime(2020),
      );
}
