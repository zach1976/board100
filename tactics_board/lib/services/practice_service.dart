import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/practice.dart';
import '../models/sport_type.dart';

class PracticeService {
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

  static Future<void> save(SportType sport, Practice p) async {
    final dir = await _dir(sport);
    p.updatedAt = DateTime.now();
    final file = File('${dir.path}/${p.name}.json');
    await file.writeAsString(jsonEncode(p.toJson()));
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
  }

  static Future<void> rename(SportType sport, String oldName, String newName) async {
    if (oldName == newName) return;
    final dir = await _dir(sport);
    final oldFile = File('${dir.path}/$oldName.json');
    if (!await oldFile.exists()) return;
    await oldFile.rename('${dir.path}/$newName.json');
  }
}
