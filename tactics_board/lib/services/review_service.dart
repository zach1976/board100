import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Requests an App Store / Play rating at a high-satisfaction moment — right
/// after the user successfully shares a board. The OS further rate-limits the
/// actual dialog (Apple: ~3 times/year), so this only decides when it's even
/// worth asking:
///   - never on the first success (let the habit form),
///   - at most once every [_minGapBetweenAsks] per device.
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  static const _kShareCountKey = 'review_share_success_count';
  static const _kLastAskedKey = 'review_last_asked_ms';
  static const int _minSharesBeforeAsk = 2;
  static const Duration _minGapBetweenAsks = Duration(days: 60);

  // Sharing was the only moment that ever asked, and few coaches share — the
  // apps sat at one rating each while competitors had thousands. These are
  // the other moments a coach is pleased with what the app just did, and how
  // many of each it takes before asking.
  static const Map<String, int> _thresholds = {
    'share': _minSharesBeforeAsk,
    'save': 3, // third board saved by hand
    'practice': 1, // a practice plan run to the end
    'playback': 3, // a drill played through to its last step, third time
  };
  static const _kDaysKey = 'review_use_days';
  static const _kLastDayKey = 'review_last_use_day';
  static const int _minUseDays = 3;

  /// Count the distinct days the app is opened. Asking on day one is asking
  /// someone who has not formed an opinion yet.
  Future<void> recordUseDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = now.year * 10000 + now.month * 100 + now.day;
      if (prefs.getInt(_kLastDayKey) == today) return;
      await prefs.setInt(_kLastDayKey, today);
      await prefs.setInt(_kDaysKey, (prefs.getInt(_kDaysKey) ?? 0) + 1);
    } catch (_) {}
  }

  /// Record a successful share and maybe show the system rating prompt.
  /// Returns true when the prompt was requested — callers then skip the
  /// post-share interstitial so the two never stack.
  Future<bool> onShareSuccess() => onPositiveMoment('share');

  /// Record one of the moments in [_thresholds]; asks for a rating once that
  /// moment has happened often enough, the app has been used on enough days,
  /// and the last ask is long enough ago. True when the prompt was requested.
  Future<bool> onPositiveMoment(String kind) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = kind == 'share' ? _kShareCountKey : 'review_${kind}_count';
      final count = (prefs.getInt(key) ?? 0) + 1;
      await prefs.setInt(key, count);
      if (count < (_thresholds[kind] ?? 1 << 30)) return false;
      if ((prefs.getInt(_kDaysKey) ?? 0) < _minUseDays) return false;

      final lastMs = prefs.getInt(_kLastAskedKey);
      if (lastMs != null &&
          DateTime.now()
                  .difference(DateTime.fromMillisecondsSinceEpoch(lastMs)) <
              _minGapBetweenAsks) {
        return false;
      }

      final review = InAppReview.instance;
      if (!await review.isAvailable()) return false;
      // Stamp before requesting: the OS may silently swallow the prompt, and
      // retry-hammering it anyway would burn the yearly quota.
      await prefs.setInt(_kLastAskedKey, DateTime.now().millisecondsSinceEpoch);
      await review.requestReview();
      return true;
    } catch (_) {
      return false; // never let rating plumbing break a share
    }
  }
}
