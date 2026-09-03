import 'package:flutter/widgets.dart';

/// Tracks whether the user is touching the screen, so full-screen ads never pop
/// while a finger is mid-gesture.
///
/// Why this exists: AdMob reporting for the tactics-board apps showed an 11.5%
/// app-open CTR (2026-07, vs 2.5% for the flashcard-style apps sharing the same
/// ad stack). The difference isn't frequency capping — it's that this app's core
/// interaction is *dragging players and drawing arrows*, so a finger is on the
/// glass almost continuously. An ad that appears under a descending finger gets
/// "clicked" by accident. Those clicks are worthless to advertisers, so Google
/// discounts the inventory, and a sustained CTR that high risks an invalid-traffic
/// strike against the whole publisher account.
///
/// Flutter can't intercept touches inside the native ad overlay, so the only
/// lever is *when we choose to show*. Callers ask [isFingerActive] first and
/// defer if the user is mid-interaction.
class TapGuard {
  TapGuard._();

  /// How long after the last finger lifts the screen is still considered "hot".
  /// Covers the gap between a finger lifting and the next tap in a drag/tap
  /// sequence.
  static const Duration _guardWindow = Duration(milliseconds: 900);

  /// How long to wait before the single retry a deferred ad gets.
  static const Duration retryDelay = Duration(milliseconds: 1200);

  /// A pointer that has been down this long with no further events is assumed
  /// lost (an up/cancel dropped across a background transition, say). Without
  /// it the guard could latch on for the rest of the session and suppress
  /// every ad.
  static const Duration _staleTouch = Duration(seconds: 30);

  /// Pointers currently down. Tracked by id rather than by "time of the last
  /// pointer-down", because a drag or a long press sends *one* down and then
  /// only moves — a time-since-down window expires mid-gesture and lets an ad
  /// through under the finger, which is the exact case this guard exists for.
  static final Set<int> _downPointers = <int>{};
  static DateTime? _lastTouchAt;

  static void notePointerDown(int pointer) {
    _downPointers.add(pointer);
    _lastTouchAt = DateTime.now();
  }

  /// Also used for pointer-cancel — either way that pointer is off the glass.
  static void notePointerUp(int pointer) {
    _downPointers.remove(pointer);
    _lastTouchAt = DateTime.now();
  }

  /// Keeps a long drag from ageing into [_staleTouch] while it is still going.
  static void notePointerMove() => _lastTouchAt = DateTime.now();

  /// True while a finger is on the screen, and for [_guardWindow] after the
  /// last one lifts — showing a full-screen ad now would very likely be
  /// mis-clicked.
  static bool get isFingerActive {
    final t = _lastTouchAt;
    if (t == null) return false;
    final since = DateTime.now().difference(t);
    if (_downPointers.isNotEmpty) return since < _staleTouch;
    return since < _guardWindow;
  }

  /// Wrap the app root so every pointer anywhere is observed. Purely
  /// observational — [Listener] doesn't consume events, so gesture handling
  /// below is unaffected.
  static Widget wrap(Widget child) => Listener(
        onPointerDown: (e) => notePointerDown(e.pointer),
        onPointerMove: (_) => notePointerMove(),
        onPointerUp: (e) => notePointerUp(e.pointer),
        onPointerCancel: (e) => notePointerUp(e.pointer),
        child: child,
      );

  /// Whether the guard currently believes a finger is on the glass.
  @visibleForTesting
  static bool get hasPointerDownForTest => _downPointers.isNotEmpty;

  @visibleForTesting
  static void resetForTest() {
    _downPointers.clear();
    _lastTouchAt = null;
  }

  /// Simulates elapsed time: [t] is when the last pointer event happened, and
  /// [fingerDown] whether a pointer is still on the glass at that moment.
  @visibleForTesting
  static void setLastTouchForTest(DateTime? t, {bool fingerDown = false}) {
    _lastTouchAt = t;
    _downPointers.clear();
    if (fingerDown) _downPointers.add(1);
  }
}
