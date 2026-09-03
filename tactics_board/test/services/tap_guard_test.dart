import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/services/tap_guard.dart';

void main() {
  setUp(TapGuard.resetForTest);

  group('isFingerActive', () {
    test('is false before any touch', () {
      expect(TapGuard.isFingerActive, isFalse);
    });

    test('is true immediately after a touch', () {
      TapGuard.notePointerDown(1);
      expect(TapGuard.isFingerActive, isTrue);
    });

    test('is false once the guard window has elapsed', () {
      TapGuard.setLastTouchForTest(
        DateTime.now().subtract(const Duration(milliseconds: 950)),
      );
      expect(TapGuard.isFingerActive, isFalse);
    });

    test('is still true just inside the guard window', () {
      TapGuard.setLastTouchForTest(
        DateTime.now().subtract(const Duration(milliseconds: 500)),
      );
      expect(TapGuard.isFingerActive, isTrue);
    });

    test('stays active through a gesture longer than the guard window', () {
      // The whole point of the guard: one pointer-down, then minutes of
      // dragging. A window measured from the down event would have expired.
      TapGuard.setLastTouchForTest(
        DateTime.now().subtract(const Duration(seconds: 5)),
        fingerDown: true,
      );
      expect(TapGuard.isFingerActive, isTrue);
    });

    test('releases a pointer that never reported an up', () {
      // Defensive: an up/cancel lost across a background transition must not
      // latch the guard on for the rest of the session.
      TapGuard.setLastTouchForTest(
        DateTime.now().subtract(const Duration(seconds: 31)),
        fingerDown: true,
      );
      expect(TapGuard.isFingerActive, isFalse);
    });

    test('goes quiet once the finger lifts and the window passes', () {
      TapGuard.notePointerDown(1);
      TapGuard.notePointerUp(1);
      TapGuard.setLastTouchForTest(
        DateTime.now().subtract(const Duration(milliseconds: 950)),
      );
      expect(TapGuard.isFingerActive, isFalse);
    });
  });

  group('wrap', () {
    testWidgets('records a tap anywhere in the subtree', (tester) async {
      await tester.pumpWidget(
        TapGuard.wrap(
          const MaterialApp(home: Scaffold(body: SizedBox.expand())),
        ),
      );
      expect(TapGuard.isFingerActive, isFalse);

      await tester.tapAt(const Offset(200, 300));
      await tester.pump();

      expect(TapGuard.isFingerActive, isTrue);
    });

    testWidgets('does not swallow taps from widgets below it', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        TapGuard.wrap(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => taps++,
                  child: const Text('tap me'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap me'));
      await tester.pump();

      expect(taps, 1, reason: 'Listener must observe, not consume');
      expect(TapGuard.isFingerActive, isTrue);
    });

    testWidgets('holds while a press is still down, releases after the up',
        (tester) async {
      await tester.pumpWidget(
        TapGuard.wrap(
          const MaterialApp(home: Scaffold(body: SizedBox.expand())),
        ),
      );

      final gesture = await tester.startGesture(const Offset(120, 200));
      await tester.pump();
      expect(TapGuard.isFingerActive, isTrue);
      expect(TapGuard.hasPointerDownForTest, isTrue);

      // A drag: still one pointer down, however long it runs. (The elapsed-time
      // half of this is covered by the isFingerActive unit tests, which can
      // fake the clock; here we only assert the pointer bookkeeping.)
      await gesture.moveBy(const Offset(0, 180));
      await tester.pump();
      expect(TapGuard.hasPointerDownForTest, isTrue,
          reason: 'an ad must not appear under a finger mid-drag');

      await gesture.up();
      await tester.pump();
      expect(TapGuard.hasPointerDownForTest, isFalse,
          reason: 'the up must clear the pointer, or the guard latches on');
      // With the finger off the glass the guard expires on time again.
      TapGuard.setLastTouchForTest(
        DateTime.now().subtract(const Duration(milliseconds: 950)),
      );
      expect(TapGuard.isFingerActive, isFalse);
    });

    testWidgets('records taps that land on empty space', (tester) async {
      await tester.pumpWidget(
        TapGuard.wrap(
          const MaterialApp(
            home: Scaffold(body: Center(child: Text('content'))),
          ),
        ),
      );

      // A drag over blank canvas — the tactics-board case that generated the
      // accidental clicks in the first place.
      await tester.dragFrom(const Offset(50, 400), const Offset(250, 400));
      await tester.pump();

      expect(TapGuard.isFingerActive, isTrue);
    });
  });
}
