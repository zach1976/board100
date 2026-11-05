/// A ready session from the drill pack: a named sequence of the library's
/// own drills with minutes, that becomes a practice plan with one tap.
///
/// Packs carry them under `plans` (tools/drills/plans.py). A coach who
/// never built a plan gets six to start from — foundation, attacking,
/// defending, set pieces, match week, pre-season — and edits from there.
class SessionTemplate {
  final String id;
  final Map<String, String> name;
  final List<SessionTemplateItem> items;

  const SessionTemplate(
      {required this.id, required this.name, required this.items});

  int get totalMinutes => items.fold(0, (sum, it) => sum + it.minutes);

  /// The name in [locale] ("zh-CN", "en-GB"), falling back to the
  /// language alone and then to English, the way drill text does.
  String nameFor(String locale) {
    final exact = name[locale];
    if (exact != null && exact.isNotEmpty) return exact;
    final lang = locale.split('-').first;
    for (final e in name.entries) {
      if (e.key.split('-').first == lang && e.value.isNotEmpty) return e.value;
    }
    return name['en'] ?? name.values.firstOrNull ?? id;
  }

  static SessionTemplate? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'];
    final rawName = j['name'];
    final rawItems = j['items'];
    if (id is! String || rawName is! Map || rawItems is! List) return null;
    final items = <SessionTemplateItem>[];
    for (final it in rawItems) {
      if (it is! Map) continue;
      final drill = it['drill'];
      final minutes = it['minutes'];
      if (drill is String && drill.isNotEmpty) {
        items.add(SessionTemplateItem(
            drillId: drill, minutes: minutes is num ? minutes.toInt() : 10));
      }
    }
    if (items.isEmpty) return null;
    return SessionTemplate(
      id: id,
      name: {
        for (final e in rawName.entries)
          if (e.key is String && e.value is String)
            e.key as String: e.value as String,
      },
      items: items,
    );
  }
}

class SessionTemplateItem {
  final String drillId;
  final int minutes;
  const SessionTemplateItem({required this.drillId, required this.minutes});
}
