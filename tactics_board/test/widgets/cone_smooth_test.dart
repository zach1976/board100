import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';

/// Equipment must not twitch while a run goes past it.
///
/// The lift that keeps a cone clear of a player's head used to be a switch:
/// inside a box behind the head it jumped the whole way, outside it dropped
/// back. During playback that read as the cone moving on a beat where
/// nothing about the cone had changed — reported from a field hockey board
/// on 2026-09-28. Measured then at 64pt of cone travel for 1pt of player
/// movement.
void main() {
  test('a cone lifts smoothly as a player walks onto it', () {
    final cone = PlayerIcon(
        id: 'c',
        label: '',
        team: PlayerTeam.neutral,
        markerShape: MarkerShape.cone,
        position: const Offset(200, 200));

    var previous = Offset.zero;
    var worst = 0.0;
    for (var gap = 80.0; gap >= -10; gap -= 1) {
      final player = PlayerIcon(
          id: 'p',
          label: 'A',
          team: PlayerTeam.home,
          position: Offset(200, 200 + gap));
      final lift =
          markerClearOffsets([cone, player], (x) => x.position)['c'] ??
              Offset.zero;
      if (gap < 80) {
        final step = (lift - previous).distance;
        if (step > worst) worst = step;
      }
      previous = lift;
    }

    // One point of player movement may not move the cone further than a
    // couple of points, or the eye catches it.
    expect(worst, lessThan(6.0),
        reason: 'cone jumped ${worst.toStringAsFixed(1)}pt in one step');
  });

  test('a cone nobody is near is not moved at all', () {
    final cone = PlayerIcon(
        id: 'c',
        label: '',
        team: PlayerTeam.neutral,
        markerShape: MarkerShape.cone,
        position: const Offset(200, 200));
    final far = PlayerIcon(
        id: 'p',
        label: 'A',
        team: PlayerTeam.home,
        position: const Offset(200, 400));
    expect(markerClearOffsets([cone, far], (x) => x.position), isEmpty);
  });
}
