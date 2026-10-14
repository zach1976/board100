import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/match_day.dart';
import '../models/sport_type.dart';

/// Where a match day lives: one file for the match in progress, so a phone
/// that dies in the third quarter comes back with the clock and the log
/// where they were; and one list of finished matches. Local only, like the
/// practice history — the phone on the touchline is the only one that
/// needs it.
class MatchDayService {
  static const int _maxHistory = 100;

  static Future<Directory> _dir() async {
    Directory base;
    try {
      base = await getApplicationDocumentsDirectory();
    } catch (_) {
      base = Directory.systemTemp;
    }
    final dir = Directory('${base.path}/match_day');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<File> _currentFile(SportType sport) async =>
      File('${(await _dir()).path}/${sport.name}_current.json');

  static Future<File> _historyFile(SportType sport) async =>
      File('${(await _dir()).path}/${sport.name}_history.json');

  /// The match in progress, or null.
  static Future<MatchDay?> loadCurrent(SportType sport) async {
    final file = await _currentFile(sport);
    if (!await file.exists()) return null;
    try {
      final data = jsonDecode(await file.readAsString());
      if (data is! Map<String, dynamic>) return null;
      return MatchDay.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveCurrent(SportType sport, MatchDay match) async {
    final file = await _currentFile(sport);
    await file.writeAsString(jsonEncode(match.toJson()));
  }

  static Future<void> clearCurrent(SportType sport) async {
    final file = await _currentFile(sport);
    if (await file.exists()) await file.delete();
  }

  /// Finished matches, newest first.
  static Future<List<MatchDay>> history(SportType sport) async {
    final file = await _historyFile(sport);
    if (!await file.exists()) return [];
    try {
      final data = jsonDecode(await file.readAsString()) as List;
      return data
          .whereType<Map<String, dynamic>>()
          .map(MatchDay.fromJson)
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    } catch (_) {
      return [];
    }
  }

  /// File a finished match and drop it as the one in progress.
  static Future<void> archive(SportType sport, MatchDay match) async {
    final all = await history(sport);
    all.insert(0, match);
    if (all.length > _maxHistory) {
      all.removeRange(_maxHistory, all.length);
    }
    final file = await _historyFile(sport);
    await file.writeAsString(jsonEncode(all.map((m) => m.toJson()).toList()));
    await clearCurrent(sport);
  }

  static Future<void> clearHistory(SportType sport) async {
    final file = await _historyFile(sport);
    if (await file.exists()) await file.delete();
  }
}
