import 'package:flutter/material.dart';

import 'player_icon.dart';

/// Indoor volleyball rotations: who stands in which zone, and whether the
/// six of them are where the rules let them stand when the ball is served.
///
/// Everything here is in the TEAM's frame, in metres: x across the court
/// from the team's own left sideline (0) to its right (9), as its players
/// see it facing the net; d back from the net (0) to its end line (9). A
/// point behind the end line has d > 9. [TacticsState] turns canvas points
/// into this frame through SportType.fieldRect, so the same rules serve the
/// near team (facing up the screen) and the far one (facing down it).
///
/// Zones are the rulebook's: 1 right back (the server), 2 right front,
/// 3 centre front, 4 left front, 5 left back, 6 centre back.

enum RotationSystem { fiveOne, sixTwo }

enum RotationPhase { receive, serve }

/// One overlap fault: zone [a] must be ahead of (depth) or to the left of
/// (lateral) zone [b] and is not.
class OverlapFault {
  final int a;
  final int b;
  final bool depth;
  const OverlapFault(this.a, this.b, {required this.depth});

  @override
  bool operator ==(Object other) =>
      other is OverlapFault &&
      other.a == a &&
      other.b == b &&
      other.depth == depth;

  @override
  int get hashCode => Object.hash(a, b, depth);

  @override
  String toString() => 'OverlapFault($a${depth ? ' ahead of ' : ' left of '}$b)';
}

/// An [OverlapFault] on the board: the two players at fault, by id —
/// [a] the one who must be ahead of (or left of) [b].
class RotationFault {
  final String a;
  final String b;
  final OverlapFault fault;
  const RotationFault(this.a, this.b, this.fault);
}

/// A side's rotation, as the board remembers it: the system, the rotation
/// it is in, receiving or serving, whether a libero is in, and whether the
/// board is checking the overlap rules. Stored on the page as "rotation";
/// an app that does not know the key ignores it and keeps the players.
class RotationSetup {
  final PlayerTeam team;
  final RotationSystem system;

  /// 1..6. Rotation 1 has the (first) setter serving from zone 1; each
  /// rotation after it moves everyone one zone clockwise, so rotation 2 has
  /// the setter in zone 6, rotation 3 in zone 5, and so on.
  final int rotation;
  final RotationPhase phase;
  final bool libero;
  final bool check;

  const RotationSetup({
    this.team = PlayerTeam.home,
    this.system = RotationSystem.fiveOne,
    this.rotation = 1,
    this.phase = RotationPhase.receive,
    this.libero = true,
    this.check = true,
  });

  RotationSetup copyWith({
    PlayerTeam? team,
    RotationSystem? system,
    int? rotation,
    RotationPhase? phase,
    bool? libero,
    bool? check,
  }) =>
      RotationSetup(
        team: team ?? this.team,
        system: system ?? this.system,
        rotation: rotation ?? this.rotation,
        phase: phase ?? this.phase,
        libero: libero ?? this.libero,
        check: check ?? this.check,
      );

  /// [by] rotations on (negative: back), wrapping round 1..6.
  RotationSetup rotated(int by) =>
      copyWith(rotation: ((rotation - 1 + by) % 6 + 6) % 6 + 1);

  List<String> get lineup => VolleyballRotation.lineup(system);

  /// The zone [role] stands in this rotation, or null when it is not one of
  /// the six (the libero has no zone of its own — see [zoneRoles]).
  int? zoneOf(String role) {
    final i = lineup.indexOf(role);
    return i < 0 ? null : VolleyballRotation.zoneFor(i, rotation);
  }

  /// The middle the libero is in for, or null when none is: the middle
  /// blocker in the back row — except the one serving, since the libero
  /// may not serve (FIVB 19.3.1.4).
  String? get liberoReplaces {
    if (!libero) return null;
    for (final role in lineup) {
      if (!role.startsWith('MB')) continue;
      final z = zoneOf(role)!;
      if (VolleyballRotation.isFront(z)) continue;
      if (phase == RotationPhase.serve && z == 1) return null;
      return role;
    }
    return null;
  }

  /// Who is on court in each zone, the libero in for the middle he replaces.
  Map<int, String> get zoneRoles {
    final out = <int, String>{};
    final replaced = liberoReplaces;
    for (final role in lineup) {
      out[zoneOf(role)!] = role == replaced ? VolleyballRotation.liberoRole : role;
    }
    return out;
  }

  /// The setter running the offence this rotation: the 5-1's one setter;
  /// in a 6-2 whichever of the two is in the back row.
  String get activeSetter {
    if (system == RotationSystem.fiveOne) return 'S';
    return VolleyballRotation.isFront(zoneOf('S1')!) ? 'S2' : 'S1';
  }

  Map<String, dynamic> toJson() => {
        'team': team.index,
        'system': system == RotationSystem.fiveOne ? '5-1' : '6-2',
        'rot': rotation,
        'phase': phase.name,
        'libero': libero,
        'check': check,
      };

  /// Null for anything that is not a rotation this build understands.
  static RotationSetup? fromJson(Object? json) {
    if (json is! Map) return null;
    final team = json['team'];
    final rot = json['rot'];
    return RotationSetup(
      team: team is int && team == PlayerTeam.away.index
          ? PlayerTeam.away
          : PlayerTeam.home,
      system: json['system'] == '6-2'
          ? RotationSystem.sixTwo
          : RotationSystem.fiveOne,
      rotation: rot is int && rot >= 1 && rot <= 6 ? rot : 1,
      phase: json['phase'] == 'serve'
          ? RotationPhase.serve
          : RotationPhase.receive,
      libero: json['libero'] != false,
      check: json['check'] != false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RotationSetup &&
      other.team == team &&
      other.system == system &&
      other.rotation == rotation &&
      other.phase == phase &&
      other.libero == libero &&
      other.check == check;

  @override
  int get hashCode =>
      Object.hash(team, system, rotation, phase, libero, check);
}

class VolleyballRotation {
  VolleyballRotation._();

  static const String liberoRole = 'L';

  /// The serving order, by the zone each stands in at rotation 1: index 0
  /// in zone 1, index 1 in zone 2 ... Opposites are three apart — the
  /// setter and the opposite (or the two setters), the outsides, the
  /// middles — so one of each pair is always in the front row.
  static const List<String> fiveOne = ['S', 'OH1', 'MB1', 'OPP', 'OH2', 'MB2'];
  static const List<String> sixTwo = ['S1', 'OH1', 'MB1', 'S2', 'OH2', 'MB2'];

  static List<String> lineup(RotationSystem s) =>
      s == RotationSystem.fiveOne ? fiveOne : sixTwo;

  /// Every role a rotation board tags a player with.
  static const Set<String> allRoles = {
    'S', 'OH1', 'MB1', 'OPP', 'OH2', 'MB2', 'S1', 'S2', liberoRole,
  };

  /// The zone lineup slot [index] is in at [rotation]: one zone clockwise
  /// per rotation — 2 to 1, 1 to 6, 6 to 5.
  static int zoneFor(int index, int rotation) =>
      ((index - (rotation - 1)) % 6 + 6) % 6 + 1;

  static bool isFront(int zone) => zone >= 2 && zone <= 4;

  /// What a player tagged [role] is called on the board: "OH", not "OH1".
  static String displayLabel(String role) =>
      role.replaceAll(RegExp(r'\d'), '');

  /// FIVB 7.4.3 / 7.5: each front-row player ahead of the back-row player
  /// behind him (front, back) ...
  static const List<(int, int)> depthPairs = [(4, 5), (3, 6), (2, 1)];

  /// ... and in each row the left player left of the centre, the centre
  /// left of the right (left, right).
  static const List<(int, int)> lateralPairs = [(4, 3), (3, 2), (5, 6), (6, 1)];

  /// The overlap faults among [feet] (zone → feet, team frame) at the
  /// moment of the serve. A pair is judged only when both zones are given;
  /// [exemptZone] — the server, on the serving side — is judged with no one.
  ///
  /// The rule asks for part of a foot to be closer to the net (sideline)
  /// than the other player's feet; a figure has one point of feet here, so
  /// level is a fault, as it would be with both feet side by side.
  static List<OverlapFault> faults(Map<int, Offset> feet, {int? exemptZone}) {
    final out = <OverlapFault>[];
    for (final (f, b) in depthPairs) {
      if (f == exemptZone || b == exemptZone) continue;
      final pf = feet[f], pb = feet[b];
      if (pf == null || pb == null) continue;
      if (!(pf.dy < pb.dy)) out.add(OverlapFault(f, b, depth: true));
    }
    for (final (l, r) in lateralPairs) {
      if (l == exemptZone || r == exemptZone) continue;
      final pl = feet[l], pr = feet[r];
      if (pl == null || pr == null) continue;
      if (!(pl.dx < pr.dx)) out.add(OverlapFault(l, r, depth: false));
    }
    return out;
  }

  /// Zones, by how the six stand: the three nearest the net are the front
  /// row, read left to right as 4, 3, 2; the other three 5, 6, 1. For a
  /// board drawn freehand that the coach then asks to have checked.
  static Map<int, T> inferZones<T>(Map<T, Offset> at) {
    if (at.length != 6) return const {};
    final byDepth = at.keys.toList()
      ..sort((a, b) => at[a]!.dy.compareTo(at[b]!.dy));
    final front = byDepth.take(3).toList()
      ..sort((a, b) => at[a]!.dx.compareTo(at[b]!.dx));
    final back = byDepth.skip(3).toList()
      ..sort((a, b) => at[a]!.dx.compareTo(at[b]!.dx));
    return {
      4: front[0], 3: front[1], 2: front[2],
      5: back[0], 6: back[1], 1: back[2],
    };
  }

  static const double _depthGap = 1.0;
  static const double _sideGap = 1.1;

  /// Move the players in [at] (zone → spot, team frame) the least it takes
  /// to make the six legal, with [_depthGap] / [_sideGap] metres to spare;
  /// [exemptZone] is not moved for anyone. Spots stay inside the court.
  static Map<int, Offset> legalize(Map<int, Offset> at, {int? exemptZone}) {
    final p = Map<int, Offset>.from(at);
    Offset inCourt(Offset o) =>
        Offset(o.dx.clamp(0.5, 8.5).toDouble(), o.dy.clamp(0.6, 8.6).toDouble());
    for (final z in p.keys.toList()) {
      if (z != exemptZone) p[z] = inCourt(p[z]!);
    }
    for (var iter = 0; iter < 200; iter++) {
      var moved = false;
      for (final (f, b) in depthPairs) {
        if (f == exemptZone || b == exemptZone) continue;
        final pf = p[f], pb = p[b];
        if (pf == null || pb == null) continue;
        if (pb.dy - pf.dy >= _depthGap - 1e-9) continue;
        final mid = (pf.dy + pb.dy) / 2;
        p[f] = inCourt(Offset(pf.dx, mid - _depthGap / 2));
        p[b] = inCourt(Offset(pb.dx, mid + _depthGap / 2));
        moved = true;
      }
      for (final (l, r) in lateralPairs) {
        if (l == exemptZone || r == exemptZone) continue;
        final pl = p[l], pr = p[r];
        if (pl == null || pr == null) continue;
        if (pr.dx - pl.dx >= _sideGap - 1e-9) continue;
        final mid = (pl.dx + pr.dx) / 2;
        p[l] = inCourt(Offset(mid - _sideGap / 2, pl.dy));
        p[r] = inCourt(Offset(mid + _sideGap / 2, pr.dy));
        moved = true;
      }
      if (!moved) break;
    }
    return p;
  }

  static double _columnX(int zone) => switch (zone) {
        4 || 5 => 1.5,
        3 || 6 => 4.5,
        _ => 7.5,
      };

  /// Where the server stands: behind the end line, right of centre.
  static const Offset serverSpot = Offset(7.2, 9.0);

  /// The six's starting spots for [s] (zone → spot, team frame), legal by
  /// construction. Serving: the base — three at the net, three back, the
  /// server behind the end line at [serverSpot]. Receiving: a three-man
  /// passing line of the outsides and the libero (or the back-row middle
  /// when there is no libero), hitters at the net, the setter as close to
  /// his target as the rules let him stand.
  static Map<int, Offset> basePositions(RotationSetup s) {
    final roles = s.zoneRoles;
    final spot = <int, Offset>{};
    if (s.phase == RotationPhase.serve) {
      for (final z in roles.keys) {
        spot[z] = isFront(z)
            ? Offset(_columnX(z), 1.6)
            : Offset(_columnX(z), z == 6 ? 6.6 : 6.0);
      }
      final legal = legalize(spot, exemptZone: 1);
      legal[1] = serverSpot;
      return legal;
    }

    final setter = s.activeSetter;
    bool passes(String role) =>
        role.startsWith('OH') ||
        role == liberoRole ||
        (role.startsWith('MB') && s.liberoReplaces == null &&
            !isFront(s.zoneOf(role)!));
    final passers = roles.keys.where((z) => passes(roles[z]!)).toList()
      ..sort((a, b) {
        final c = _columnX(a).compareTo(_columnX(b));
        if (c != 0) return c;
        // Same column: the front-row one drops back on the outside of it.
        final fa = isFront(a), fb = isFront(b);
        if (fa == fb) return 0;
        return (a == 4 || a == 5) == fa ? -1 : 1;
      });
    const lanes = [Offset(1.6, 6.0), Offset(4.5, 6.5), Offset(7.4, 6.0)];
    for (var i = 0; i < passers.length && i < lanes.length; i++) {
      spot[passers[i]] = lanes[i];
    }
    int partner(int z) => switch (z) {
          1 => 2, 2 => 1, 3 => 6, 6 => 3, 4 => 5, _ => 4,
        };
    for (final z in roles.keys) {
      if (spot.containsKey(z)) continue;
      final role = roles[z]!;
      if (isFront(z)) {
        // At the net: the setter towards his target right of centre.
        spot[z] = role == setter
            ? Offset(switch (z) { 2 => 6.6, 3 => 5.4, _ => 3.0 }, 1.0)
            : Offset(_columnX(z) + (z == 4 ? -0.3 : z == 2 ? 0.3 : 0), 1.2);
      }
    }
    for (final z in roles.keys) {
      if (spot.containsKey(z)) continue;
      final role = roles[z]!;
      final front = spot[partner(z)];
      final frontPasses = front != null && front.dy > 3;
      if (role == setter) {
        // Released: up behind the hitter in front of him, or tucked in
        // just behind the passer who is.
        spot[z] = frontPasses
            ? Offset(front.dx + (z == 5 ? -1.0 : 1.0), front.dy + 1.2)
            : Offset(switch (z) { 1 => 7.0, 6 => 5.6, _ => 2.6 }, 2.4);
      } else {
        // A back-row hitter out of the reception: deep, out of the lanes.
        spot[z] = frontPasses
            ? Offset(front.dx + (z == 5 ? -1.0 : 1.0), front.dy + 1.4)
            : Offset(_columnX(z) + (z == 1 ? 0.8 : z == 5 ? -0.8 : 0), 7.8);
      }
    }
    return legalize(spot);
  }

  /// The libero's spot while off court with the middle he replaced in:
  /// his replacement zone beside the court, between the attack line and
  /// the end line, on the team's right. Also where the middle waits.
  static const Offset benchSpot = Offset(9.7, 5.2);
}
