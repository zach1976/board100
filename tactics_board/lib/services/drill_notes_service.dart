import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sport_type.dart';

/// What the coach has added to a shipped drill: a star, and their own note.
///
/// The library is 600-odd drills written for everybody. A coach uses maybe
/// twenty of them, runs them their own way, and remembers things about them
/// that are true of their group and of nobody else's — "our under-11s need
/// the square 2 m bigger". None of that can live in the shipped file, so it
/// lives here, keyed by drill id, on this device.
///
/// Stored per sport because the ids only have to be unique within one.
class DrillNotesService {
  DrillNotesService._();
  static final instance = DrillNotesService._();

  static String _key(SportType sport) => 'drill_marks_${sport.name}';

  Map<String, DrillMark>? _cache;
  SportType? _cachedSport;

  Future<Map<String, DrillMark>> _load(SportType sport) async {
    if (_cache != null && _cachedSport == sport) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(sport));
    final out = <String, DrillMark>{};
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((id, v) {
          out[id] = DrillMark.fromJson(Map<String, dynamic>.from(v as Map));
        });
      } catch (_) {
        // Written by a newer build, or half-written. Losing the marks is bad
        // but losing the library behind them would be worse.
      }
    }
    _cache = out;
    _cachedSport = sport;
    return out;
  }

  Future<Map<String, DrillMark>> all(SportType sport) => _load(sport);

  Future<DrillMark> forDrill(SportType sport, String id) async =>
      (await _load(sport))[id] ?? const DrillMark();

  Future<void> setStarred(SportType sport, String id, bool starred) async {
    final marks = await _load(sport);
    final next = (marks[id] ?? const DrillMark()).copyWith(starred: starred);
    await _write(sport, marks, id, next);
  }

  Future<void> setNote(SportType sport, String id, String note) async {
    final marks = await _load(sport);
    final next = (marks[id] ?? const DrillMark()).copyWith(note: note.trim());
    await _write(sport, marks, id, next);
  }

  Future<void> _write(SportType sport, Map<String, DrillMark> marks, String id,
      DrillMark next) async {
    // An empty mark is not worth a row: it would keep every drill the coach
    // ever glanced at in a file that is meant to be the few they use.
    if (next.isEmpty) {
      marks.remove(id);
    } else {
      marks[id] = next;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(sport),
      jsonEncode({for (final e in marks.entries) e.key: e.value.toJson()}),
    );
  }
}

class DrillMark {
  final bool starred;
  final String note;
  const DrillMark({this.starred = false, this.note = ''});

  bool get isEmpty => !starred && note.isEmpty;
  bool get hasNote => note.isNotEmpty;

  DrillMark copyWith({bool? starred, String? note}) =>
      DrillMark(starred: starred ?? this.starred, note: note ?? this.note);

  Map<String, dynamic> toJson() => {
        if (starred) 'starred': true,
        if (note.isNotEmpty) 'note': note,
      };

  factory DrillMark.fromJson(Map<String, dynamic> json) => DrillMark(
        starred: json['starred'] == true,
        note: json['note'] as String? ?? '',
      );
}
