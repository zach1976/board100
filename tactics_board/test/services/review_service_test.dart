import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/services/review_service.dart';

/// When the app asks for a rating. Sharing was the only trigger and few
/// coaches share, so the apps sat at one rating each; saves, a finished
/// practice and a drill watched to the end now count too — but never on
/// someone who has used the app on fewer than three days.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.britannio.in_app_review');
  var asked = 0;

  setUp(() {
    asked = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'isAvailable') return true;
      if (call.method == 'requestReview') asked++;
      return null;
    });
  });

  Future<void> useDays(int n) async {
    SharedPreferences.setMockInitialValues({'review_use_days': n});
  }

  test('a third save asks, once the app has been used on three days', () async {
    await useDays(3);
    final r = ReviewService.instance;
    expect(await r.onPositiveMoment('save'), isFalse);
    expect(await r.onPositiveMoment('save'), isFalse);
    expect(await r.onPositiveMoment('save'), isTrue);
    expect(asked, 1);
    // Sixty days between asks: a fourth save is not a fifth prompt.
    expect(await r.onPositiveMoment('save'), isFalse);
    expect(asked, 1);
  });

  test('a first-day user is never asked, however pleased', () async {
    await useDays(1);
    final r = ReviewService.instance;
    for (var i = 0; i < 5; i++) {
      expect(await r.onPositiveMoment('save'), isFalse);
    }
    expect(await r.onPositiveMoment('practice'), isFalse);
    expect(asked, 0);
  });

  test('one finished practice is enough; sharing keeps its own count', () async {
    await useDays(4);
    expect(await ReviewService.instance.onPositiveMoment('practice'), isTrue);
    await useDays(4);
    expect(await ReviewService.instance.onShareSuccess(), isFalse);
    expect(await ReviewService.instance.onShareSuccess(), isTrue);
  });

  test('use days count distinct days only', () async {
    SharedPreferences.setMockInitialValues({});
    await ReviewService.instance.recordUseDay();
    await ReviewService.instance.recordUseDay();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('review_use_days'), 1);
  });
}
