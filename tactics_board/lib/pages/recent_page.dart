import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/drill.dart';
import '../models/sport_type.dart';
import '../services/recent_boards_service.dart';
import '../ui/primitives.dart';
import '../ui/tokens.dart';
import '../widgets/drill_thumbnail.dart';

/// "今天", "昨天", "3 天前" — how long ago a board was open.
///
/// Shared with the home page's own lists: the same board can appear on both
/// and reading two different answers for one date is a bug a coach would
/// notice before anybody else.
String relativeDay(DateTime t) {
  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(t.year, t.month, t.day))
      .inDays;
  if (days <= 0) return 'home_today_word'.tr();
  if (days == 1) return 'home_yesterday'.tr();
  return 'home_days_ago'.tr(args: ['$days']);
}

/// Everything opened lately, newest first.
///
/// The home page's recent row is a shortcut back to the last few; this is
/// the list behind it — a hundred deep, drills and the coach's own boards
/// together, because "what did I look at on Tuesday" does not care which of
/// the two it was.
///
/// It returns the row that was tapped rather than opening it: loading a
/// board and pushing the editor is the home page's job, and it already
/// knows how to drop a shortcut whose drill the library no longer has.
class RecentPage extends StatelessWidget {
  final List<RecentBoard> items;
  final SportType sport;

  /// The library keyed by id, for the drills' thumbnails. A board of the
  /// coach's own is not in it and gets the board glyph instead.
  final Map<String, Drill> byId;

  const RecentPage({
    super.key,
    required this.items,
    required this.sport,
    required this.byId,
  });

  static Future<RecentBoard?> push(
    BuildContext context, {
    required List<RecentBoard> items,
    required SportType sport,
    required Map<String, Drill> byId,
  }) {
    return Navigator.of(context).push<RecentBoard>(
      MaterialPageRoute<RecentBoard>(
        builder: (_) => RecentPage(items: items, sport: sport, byId: byId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.bg0,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TacticalNavBar(title: 'home_recent'.tr()),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    T.screenX, T.s4, T.screenX, T.s32),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: T.s8),
                itemBuilder: (context, i) {
                  final r = items[i];
                  final drill = byId[r.id];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(r),
                    child: Container(
                      padding: const EdgeInsets.all(T.s12),
                      decoration: const BoxDecoration(
                          color: T.surface, borderRadius: T.brSm),
                      child: Row(
                        children: [
                          if (drill != null)
                            DrillThumbnail(
                                drill: drill, sport: sport, height: 56)
                          else
                            const SizedBox(
                              width: 36,
                              height: 56,
                              child: Icon(Icons.dashboard_outlined,
                                  color: T.textOff, size: 22),
                            ),
                          const SizedBox(width: T.s12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: T.text,
                                      fontSize: 14.5,
                                      height: 1.3,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  relativeDay(r.openedAt),
                                  style: const TextStyle(
                                      color: T.textDim, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: T.textOff, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
