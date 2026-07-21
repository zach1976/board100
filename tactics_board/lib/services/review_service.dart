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

  /// Record a successful share and maybe show the system rating prompt.
  /// Returns true when the prompt was requested — callers then skip the
  /// post-share interstitial so the two never stack.
  Future<bool> onShareSuccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt(_kShareCountKey) ?? 0) + 1;
      await prefs.setInt(_kShareCountKey, count);
      if (count < _minSharesBeforeAsk) return false;

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
