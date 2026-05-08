import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Tracks how often the user adds each marker / element to the board so the
/// Add sheet can promote frequently-used pieces to the front of the inline
/// row and keep rarely-used ones tucked into "More". Tracks the rolling
/// 3-day window — anything older drops out and the element returns to its
/// default position.
///
/// Storage: a single JSON file `element_usage.json` in the documents
/// directory. Map of `key → list of ms-since-epoch timestamps`.
class ElementUsageService extends ChangeNotifier {
  ElementUsageService._();
  static final ElementUsageService instance = ElementUsageService._();

  static const int _windowMs = 3 * 24 * 60 * 60 * 1000;

  bool _initialized = false;
  Map<String, List<int>> _records = {};

  Future<void> _ensureInit() async {
    if (_initialized) return;
    try {
      final f = await _file();
      if (f.existsSync()) {
        final raw = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _records = raw.map((k, v) => MapEntry(
              k,
              (v as List).map((e) => (e as num).toInt()).toList(),
            ));
      }
    } catch (_) {
      _records = {};
    }
    _initialized = true;
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'element_usage.json'));
  }

  /// Synchronous read of the recent (3-day) use count. Returns 0 if the
  /// service hasn't loaded yet — the first build of the markers row may
  /// see zeros, then re-renders once `_ensureInit` finishes via
  /// notifyListeners.
  int recentCount(String key) {
    if (!_initialized) {
      // Trigger async init; consumers should listen to notifyListeners.
      _ensureInit().then((_) {
        if (_records.isNotEmpty) notifyListeners();
      });
      return 0;
    }
    final cutoff = DateTime.now().millisecondsSinceEpoch - _windowMs;
    final list = _records[key];
    if (list == null) return 0;
    return list.where((t) => t >= cutoff).length;
  }

  /// Append a usage event for [key]. Prunes timestamps outside the 3-day
  /// window and persists. Notifies listeners so the markers row re-sorts.
  Future<void> recordUse(String key) async {
    await _ensureInit();
    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - _windowMs;
    final list = _records[key] ?? <int>[];
    list.removeWhere((t) => t < cutoff);
    list.add(now);
    _records[key] = list;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(_records), flush: true);
    } catch (_) {/* best-effort */}
  }
}
