import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/volleyball_rotation.dart';

/// The overlap rules (FIVB 7.4 / 7.5), the order of rotation, and the
/// libero — judged in the team's frame: x from the team's left sideline,
/// d back from the net, in metres.
void main() {
  // A legal base: front row at the net, back row deep, left to right
  // 4-3-2 and 5-6-1.
  Map<int, Offset> base() => {
        4: const Offset(1.5, 2), 3: const Offset(4.5, 2), 2: const Offset(7.5, 2),
        5: const Offset(1.5, 6), 6: const Offset(4.5, 6), 1: const Offset(7.5, 6),
      };

  group('overlap', () {
    test('a legal base has no fault', () {
      expect(VolleyballRotation.faults(base()), isEmpty);
    });

    for (final (front, back) in VolleyballRotation.depthPairs) {
      test('back-row $back ahead of front-row $front is a fault', () {
        final at = base();
        at[back] = Offset(at[back]!.dx, at[front]!.dy - 0.5);
        expect(VolleyballRotation.faults(at),
            [OverlapFault(front, back, depth: true)]);
      });
    }

    for (final (left, right) in VolleyballRotation.lateralPairs) {
      test('$left right of $right is a fault', () {
        final at = base();
        at[left] = Offset(at[right]!.dx + 0.4, at[left]!.dy);
        final faults = VolleyballRotation.faults(at);
        expect(faults, contains(OverlapFault(left, right, depth: false)));
        expect(faults.where((f) => f.depth), isEmpty);
      });
    }

    test('level is a fault: neither is ahead', () {
      final at = base();
      at[5] = Offset(at[5]!.dx, at[4]!.dy);
      expect(VolleyballRotation.faults(at),
          [const OverlapFault(4, 5, depth: true)]);
    });

    test('the centre need not be between the outsides of the other row', () {
      // 6 well left of 4 in depth terms is not a rule; only rows and
      // columns are.
      final at = base();
      at[6] = const Offset(2.5, 6);
      expect(VolleyballRotation.faults(at), isEmpty);
    });

    test('the server is exempt', () {
      final at = base();
      // Zone 1 in front of zone 2 and left of zone 6: two faults ...
      at[1] = const Offset(3.0, 1.0);
      expect(VolleyballRotation.faults(at), hasLength(2));
      // ... and none when he is the server.
      expect(VolleyballRotation.faults(at, exemptZone: 1), isEmpty);
      // The exemption is his alone.
      at[5] = const Offset(1.5, 1.0);
      expect(VolleyballRotation.faults(at, exemptZone: 1),
          [const OverlapFault(4, 5, depth: true)]);
    });

    test('a missing zone is not judged', () {
      final at = base()..remove(6);
      at[1] = const Offset(0.5, 6); // left of nobody now that 6 is gone
      expect(VolleyballRotation.faults(at), isEmpty);
    });
  });

  group('rotation order', () {
    test('one rotation on: 2 to 1, 1 to 6, 6 to 5 ...', () {
      const s = RotationSetup();
      final next = s.rotated(1);
      for (final role in s.lineup) {
        final z = s.zoneOf(role)!;
        final expected = z == 1 ? 6 : z - 1;
        expect(next.zoneOf(role), expected, reason: role);
      }
    });

    test('the setter goes 1, 6, 5, 4, 3, 2 and back to 1', () {
      var s = const RotationSetup();
      final zones = <int>[];
      for (var i = 0; i < 7; i++) {
        zones.add(s.zoneOf('S')!);
        s = s.rotated(1);
      }
      expect(zones, [1, 6, 5, 4, 3, 2, 1]);
      expect(s.rotation, 2);
    });

    test('back from rotation 1 is rotation 6', () {
      expect(const RotationSetup().rotated(-1).rotation, 6);
      expect(const RotationSetup(rotation: 6).rotated(1).rotation, 1);
    });

    test('opposites are three zones apart in both systems', () {
      for (final sys in RotationSystem.values) {
        for (var r = 1; r <= 6; r++) {
          final s = RotationSetup(system: sys, rotation: r);
          final l = s.lineup;
          for (var i = 0; i < 3; i++) {
            final a = s.zoneOf(l[i])!, b = s.zoneOf(l[i + 3])!;
            expect(VolleyballRotation.isFront(a) != VolleyballRotation.isFront(b),
                isTrue, reason: '${l[i]} / ${l[i + 3]} in R$r');
          }
        }
      }
    });

    test('6-2: the back-row setter runs the offence', () {
      for (var r = 1; r <= 6; r++) {
        final s = RotationSetup(system: RotationSystem.sixTwo, rotation: r);
        expect(VolleyballRotation.isFront(s.zoneOf(s.activeSetter)!), isFalse);
      }
    });
  });

  group('libero', () {
    test('replaces the back-row middle', () {
      // Rotation 1 of a 5-1: MB1 in 3 (front), MB2 in 6 (back).
      const s = RotationSetup();
      expect(s.zoneOf('MB2'), 6);
      expect(s.liberoReplaces, 'MB2');
      expect(s.zoneRoles[6], VolleyballRotation.liberoRole);
      expect(s.zoneRoles.values, isNot(contains('MB2')));
      expect(s.zoneRoles[3], 'MB1');
    });

    test('follows the middles round: always the one in the back row', () {
      for (var r = 1; r <= 6; r++) {
        final s = RotationSetup(rotation: r);
        final mb = s.liberoReplaces!;
        expect(VolleyballRotation.isFront(s.zoneOf(mb)!), isFalse,
            reason: 'R$r');
      }
    });

    test('does not serve: the middle serves for himself', () {
      // Rotation 3 of a 5-1 has MB1 in zone 1.
      const receive = RotationSetup(rotation: 3);
      expect(receive.zoneOf('MB1'), 1);
      expect(receive.liberoReplaces, 'MB1');
      final serve = receive.copyWith(phase: RotationPhase.serve);
      expect(serve.liberoReplaces, isNull);
      expect(serve.zoneRoles[1], 'MB1');
    });

    test('none when switched off', () {
      const s = RotationSetup(libero: false);
      expect(s.liberoReplaces, isNull);
      expect(s.zoneRoles[6], 'MB2');
    });
  });

  group('rule set', () {
    test('each allows its own number of substitutions a set', () {
      expect(RotationRules.fivb.substitutions, 6);
      expect(RotationRules.usav.substitutions, 12);
      expect(RotationRules.nfhs.substitutions, 18);
      expect(RotationRules.ncaa.substitutions, 15);
      expect(const RotationSetup().rules, RotationRules.fivb);
    });

    test('FIVB: the libero never serves', () {
      // Rotation 3 of a 5-1 has MB1 in zone 1, rotation 6 MB2.
      for (final r in [3, 6]) {
        final s = RotationSetup(rotation: r, phase: RotationPhase.serve);
        expect(s.liberoServing, isFalse, reason: 'R$r');
        expect(s.zoneRoles[1], startsWith('MB'), reason: 'R$r');
      }
    });

    for (final rules in [
      RotationRules.usav,
      RotationRules.nfhs,
      RotationRules.ncaa,
    ]) {
      test('${rules.label}: the libero serves in one rotation position', () {
        final r3 = RotationSetup(
            rotation: 3, phase: RotationPhase.serve, rules: rules);
        expect(r3.zoneOf('MB1'), 1);
        expect(r3.liberoReplaces, 'MB1');
        expect(r3.zoneRoles[1], VolleyballRotation.liberoRole);
        expect(r3.liberoServing, isTrue);
        // One position a set: the second middle serves for himself.
        final r6 = r3.copyWith(rotation: 6);
        expect(r6.zoneOf('MB2'), 1);
        expect(r6.liberoReplaces, isNull);
        expect(r6.zoneRoles[1], 'MB2');
        expect(r6.liberoServing, isFalse);
        // Receiving, the libero is in for the back-row middle as ever.
        expect(r3.copyWith(phase: RotationPhase.receive).liberoReplaces, 'MB1');
      });
    }

    test('the overlap rules are the same under every rule set', () {
      final at = base();
      at[5] = Offset(at[5]!.dx, at[4]!.dy - 0.5);
      for (final rules in RotationRules.values) {
        final s = RotationSetup(rules: rules);
        expect(VolleyballRotation.faults(at),
            [const OverlapFault(4, 5, depth: true)],
            reason: s.rules.label);
        for (var r = 1; r <= 6; r++) {
          expect(
              VolleyballRotation.faults(VolleyballRotation.basePositions(
                  s.copyWith(rotation: r, phase: RotationPhase.serve)),
                  exemptZone: 1),
              isEmpty,
              reason: '${rules.label} R$r');
        }
      }
    });

    test('the role in each zone, the libero aside', () {
      const s = RotationSetup(rotation: 3);
      expect([for (var z = 1; z <= 6; z++) s.roleInZone(z)],
          ['MB1', 'OPP', 'OH2', 'MB2', 'S', 'OH1']);
    });
  });

  group('base positions', () {
    test('every rotation, both systems, both phases is legal and on court',
        () {
      for (final sys in RotationSystem.values) {
        for (final ph in RotationPhase.values) {
          for (final lib in [true, false]) {
            for (var r = 1; r <= 6; r++) {
              final s = RotationSetup(
                  system: sys, rotation: r, phase: ph, libero: lib);
              final at = VolleyballRotation.basePositions(s);
              final serving = ph == RotationPhase.serve;
              expect(at.keys.toSet(), {1, 2, 3, 4, 5, 6});
              expect(
                  VolleyballRotation.faults(at,
                      exemptZone: serving ? 1 : null),
                  isEmpty,
                  reason: '$sys $ph libero=$lib R$r: $at');
              for (final e in at.entries) {
                if (serving && e.key == 1) {
                  expect(e.value.dy, greaterThanOrEqualTo(9),
                      reason: 'the server is behind the end line');
                  continue;
                }
                expect(e.value.dx, inInclusiveRange(0, 9));
                expect(e.value.dy, inInclusiveRange(0, 9));
              }
            }
          }
        }
      }
    });

    test('a legal layout is left where it is', () {
      expect(VolleyballRotation.legalize(base()), base());
    });

    test('legalize mends every fault', () {
      final at = base();
      at[5] = const Offset(1.5, 1.0);
      at[3] = const Offset(8.0, 2.0);
      expect(VolleyballRotation.faults(VolleyballRotation.legalize(at)),
          isEmpty);
    });

    test('legal rect: zone 3 between 4 and 2, net to zone 6', () {
      final at = base();
      final r = VolleyballRotation.legalRect(3, at)!;
      expect(r.left, at[4]!.dx);
      expect(r.right, at[2]!.dx);
      expect(r.top, 0);
      expect(r.bottom, at[6]!.dy);
    });

    test('legal rect: a back-row corner is bounded by the court', () {
      final at = base();
      final r = VolleyballRotation.legalRect(1, at)!;
      expect(r.left, at[6]!.dx);
      expect(r.right, 9);
      expect(r.top, at[2]!.dy);
      expect(r.bottom, 9);
    });

    test('legal rect: a pair with the server is no constraint', () {
      final at = base();
      expect(VolleyballRotation.legalRect(1, at, exemptZone: 1), isNull);
      final r = VolleyballRotation.legalRect(6, at, exemptZone: 1)!;
      expect(r.right, 9);
      expect(r.left, at[5]!.dx);
      expect(VolleyballRotation.legalRect(2, at, exemptZone: 1)!.bottom, 9);
    });

    test('legal rect: only the zones placed cut it down', () {
      final r = VolleyballRotation.legalRect(3, {4: const Offset(2, 1)})!;
      expect([r.left, r.top, r.right, r.bottom], [2, 0, 9, 9]);
    });

    test('legal rect agrees with the faults', () {
      final at = base();
      for (final z in at.keys) {
        final r = VolleyballRotation.legalRect(z, at)!;
        expect(r.contains(at[z]!), isTrue, reason: 'zone $z in base');
        // Just over each edge is a fault of that zone's; just inside none.
        for (final (dx, dy) in [(-0.1, 0.0), (0.1, 0.0), (0.0, -0.1), (0.0, 0.1)]) {
          final over = at[z]!;
          final x = dx < 0 ? r.left + dx : dx > 0 ? r.right + dx : over.dx;
          final y = dy < 0 ? r.top + dy : dy > 0 ? r.bottom + dy : over.dy;
          if (x < 0 || x > 9 || y < 0 || y > 9) continue; // off the court
          final moved = Map<int, Offset>.from(at)..[z] = Offset(x, y);
          expect(VolleyballRotation.faults(moved).where((f) => f.a == z || f.b == z),
              isNotEmpty,
              reason: 'zone $z at ($x, $y)');
        }
      }
    });

    test('zones are read from where six stand', () {
      final at = base();
      final ids = {for (final e in at.entries) 'z${e.key}': e.value};
      final zones = VolleyballRotation.inferZones(ids);
      for (final z in at.keys) {
        expect(zones[z], 'z$z');
      }
    });
  });

  group('json', () {
    test('round-trips', () {
      const s = RotationSetup(
        team: PlayerTeam.away,
        system: RotationSystem.sixTwo,
        rotation: 4,
        phase: RotationPhase.serve,
        libero: false,
        check: false,
        rules: RotationRules.nfhs,
      );
      expect(RotationSetup.fromJson(s.toJson()), s);
    });

    test('a board saved before rule sets plays to FIVB', () {
      expect(RotationSetup.fromJson({'rot': 2})!.rules, RotationRules.fivb);
      expect(RotationSetup.fromJson({'rules': 'xyz'})!.rules,
          RotationRules.fivb);
    });

    test('anything else reads as nothing, or as defaults', () {
      expect(RotationSetup.fromJson(null), isNull);
      expect(RotationSetup.fromJson('5-1'), isNull);
      expect(RotationSetup.fromJson({'rot': 9}), const RotationSetup());
    });
  });
}
