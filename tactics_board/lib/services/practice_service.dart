import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/practice.dart';
import '../models/sport_type.dart';
import 'auth_service.dart';
import 'cloud_sync_service.dart';
import 'sync_service.dart';

class PracticeService {
  static const String bundleKind = 'tactics_board.practice_bundle';
  static const int bundleVersion = 1;

  static Future<Directory> _dir(SportType sport) async {
    Directory base;
    try {
      base = await getApplicationDocumentsDirectory();
    } catch (_) {
      base = Directory.systemTemp;
    }
    final d = Directory('${base.path}/practices/${sport.name}');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<Directory> _tacticsDir(SportType sport) async {
    Directory base;
    try {
      base = await getApplicationDocumentsDirectory();
    } catch (_) {
      base = Directory.systemTemp;
    }
    final d = Directory('${base.path}/tactics/${sport.name}');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<void> save(SportType sport, Practice p) async {
    final dir = await _dir(sport);
    p.updatedAt = DateTime.now();
    final file = File('${dir.path}/${p.name}.json');
    await file.writeAsString(jsonEncode(p.toJson()));
    CloudSyncService.markLocalChange();
    if (AuthService.instance.isLoggedIn) {
      // Fire-and-forget cloud push
      SyncService.instance.pushPractice(p.name, sport.name, p.toJson());
    }
  }

  static Future<Practice?> load(SportType sport, String name) async {
    final dir = await _dir(sport);
    final file = File('${dir.path}/$name.json');
    if (!await file.exists()) return null;
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return Practice.fromJson(json);
  }

  static Future<List<String>> listNames(SportType sport) async {
    final dir = await _dir(sport);
    final files = await dir.list().where((f) => f.path.endsWith('.json')).toList();
    final names = files
        .map((f) => f.path.split('/').last.replaceAll('.json', ''))
        .toList()
      ..sort();
    return names;
  }

  static Future<void> delete(SportType sport, String name) async {
    final dir = await _dir(sport);
    final file = File('${dir.path}/$name.json');
    if (await file.exists()) await file.delete();
    CloudSyncService.markLocalChange();
    if (AuthService.instance.isLoggedIn) {
      SyncService.instance.deletePracticeByName(name, sport.name);
    }
  }

  static Future<void> rename(SportType sport, String oldName, String newName) async {
    if (oldName == newName) return;
    final dir = await _dir(sport);
    final oldFile = File('${dir.path}/$oldName.json');
    if (!await oldFile.exists()) return;
    await oldFile.rename('${dir.path}/$newName.json');
    CloudSyncService.markLocalChange();
    if (AuthService.instance.isLoggedIn) {
      // Cloud: delete old name; next save() will push the new one
      SyncService.instance.deletePracticeByName(oldName, sport.name);
    }
  }

  /// Remove all plan items referencing the given tactic name across plans
  /// of the given sport. Called after a tactic is deleted.
  static Future<void> purgeTacticReferences(
      SportType sport, String tacticName) async {
    final names = await listNames(sport);
    for (final planName in names) {
      final plan = await load(sport, planName);
      if (plan == null) continue;
      final before = plan.items.length;
      plan.items.removeWhere((it) => it.tacticName == tacticName);
      if (plan.items.length != before) {
        await save(sport, plan);
      }
    }
  }

  /// Rename all plan item references to a tactic when the tactic itself is renamed.
  static Future<void> renameTacticReferences(
      SportType sport, String oldName, String newName) async {
    if (oldName == newName) return;
    final names = await listNames(sport);
    for (final planName in names) {
      final plan = await load(sport, planName);
      if (plan == null) continue;
      var changed = false;
      final updated = plan.items.map((it) {
        if (it.tacticName == oldName) {
          changed = true;
          return PracticeItem(
            tacticName: newName,
            durationMinutes: it.durationMinutes,
            note: it.note,
          );
        }
        return it;
      }).toList();
      if (changed) {
        plan.items
          ..clear()
          ..addAll(updated);
        await save(sport, plan);
      }
    }
  }

  /// Build a self-contained JSON bundle for a plan: plan metadata + all
  /// referenced tactics' raw JSON. Recipient can import without needing
  /// the tactics to already exist.
  static Future<Map<String, dynamic>?> exportBundle(
      SportType sport, String planName) async {
    final plan = await load(sport, planName);
    if (plan == null) return null;
    final tacticsDir = await _tacticsDir(sport);
    final seen = <String>{};
    final tactics = <Map<String, dynamic>>[];
    for (final it in plan.items) {
      if (!seen.add(it.tacticName)) continue;
      final f = File('${tacticsDir.path}/${it.tacticName}.json');
      if (!await f.exists()) continue;
      try {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        tactics.add({'name': it.tacticName, 'data': data});
      } catch (_) {}
    }
    return {
      'kind': bundleKind,
      'version': bundleVersion,
      'sport': sport.name,
      'plan': plan.toJson(),
      'tactics': tactics,
    };
  }

  /// Import a bundle previously produced by [exportBundle]. Returns the
  /// name the plan was saved as, or throws on malformed / sport mismatch.
  /// If [overwrite] is false (default), name collisions are resolved by
  /// appending a numeric suffix.
  static Future<String> importBundle(
    SportType sport,
    Map<String, dynamic> bundle, {
    bool overwrite = false,
  }) async {
    if (bundle['kind'] != bundleKind) {
      throw const FormatException('not a practice bundle');
    }
    final bundleSport = bundle['sport'] as String?;
    if (bundleSport != null && bundleSport != sport.name) {
      throw FormatException('sport mismatch: $bundleSport vs ${sport.name}');
    }
    final planJson = bundle['plan'] as Map<String, dynamic>?;
    if (planJson == null) throw const FormatException('missing plan');
    final plan = Practice.fromJson(planJson);

    // Write referenced tactics that are missing (never overwrite existing
    // tactics — user's own work wins).
    final tacticsDir = await _tacticsDir(sport);
    final rawTactics = (bundle['tactics'] as List?) ?? const [];
    for (final t in rawTactics) {
      if (t is! Map) continue;
      final tName = t['name'] as String?;
      final tData = t['data'];
      if (tName == null || tName.isEmpty || tData == null) continue;
      final f = File('${tacticsDir.path}/$tName.json');
      if (await f.exists()) continue;
      await f.writeAsString(jsonEncode(tData));
    }

    // Pick a non-colliding plan name if not overwriting.
    var name = plan.name;
    if (!overwrite) {
      final existing = await listNames(sport);
      var n = 2;
      while (existing.contains(name)) {
        name = '${plan.name} ($n)';
        n++;
      }
    }
    plan.name = name;
    await save(sport, plan);
    return name;
  }
}
