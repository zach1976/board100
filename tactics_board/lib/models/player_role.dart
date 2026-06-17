import 'package:flutter/material.dart';
import 'player_icon.dart';
import 'sport_type.dart';

/// Coarse line buckets used as a fallback when a player's exact role is not a
/// slot in the target formation (e.g. a 4-back RB switching into a 3-back).
enum RoleLine { gk, def, dm, mid, am, fwd }

/// Fixed position/role codes per sport, the slot→role derivation used when a
/// formation is applied, and the helpers that drive role-preserving relocation
/// (see TacticsState.addTeamFromFormation).
///
/// Basketball is purely index-based (every formation is PG, SG, SF, PF, C in
/// that order). Soccer derives a named role from a slot's depth (line) and
/// lateral position (side), so the same coordinate maps to the same role in
/// any formation.
class PlayerRoles {
  static const List<String> _basketball = ['PG', 'SG', 'SF', 'PF', 'C'];

  /// Roles offered in the picker, ordered for display (GK/back→front).
  static List<String> forSport(SportType s) {
    switch (s) {
      case SportType.basketball:
        return _basketball;
      case SportType.soccer:
        return const [
          'GK',
          'LB', 'LCB', 'CB', 'RCB', 'RB',
          'LDM', 'CDM', 'RDM',
          'LM', 'LCM', 'CM', 'RCM', 'RM',
          'LAM', 'CAM', 'RAM',
          'LW', 'LS', 'ST', 'RS', 'RW',
        ];
      default:
        return const [];
    }
  }

  static bool supports(SportType s) => forSport(s).isNotEmpty;

  /// Role for the slot at [index] (normalised [pos]) of a [sport] formation,
  /// for [team]. Used to tag players as a formation is applied.
  static String roleForSlot(
      SportType sport, PlayerTeam team, int index, Offset pos) {
    switch (sport) {
      case SportType.basketball:
        return _basketball[index % _basketball.length];
      case SportType.soccer:
        return _soccerRole(team, pos);
      default:
        return '';
    }
  }

  static RoleLine? lineOf(String role) {
    if (role == 'GK') return RoleLine.gk;
    if (role.endsWith('DM')) return RoleLine.dm;
    if (role.endsWith('AM')) return RoleLine.am;
    if (role.endsWith('B')) return RoleLine.def; // LB,RB,CB,LCB,RCB
    if (role.endsWith('M')) return RoleLine.mid; // LM,CM,RM,LCM,RCM
    if (role == 'LW' || role == 'RW' || role == 'LS' || role == 'RS' || role == 'ST') {
      return RoleLine.fwd;
    }
    return null; // basketball roles have no line fallback (index-based)
  }

  /// Lateral preference 0(left)..1(right) for ordering within a line.
  static double xPrefOf(String role) {
    if (role.startsWith('L')) return 0.15;
    if (role.startsWith('R')) return 0.85;
    return 0.5;
  }

  static String _soccerRole(PlayerTeam team, Offset pos) {
    // Depth from own goal: home defends the larger-dy end.
    final d = team == PlayerTeam.away ? (1 - pos.dy) : pos.dy;
    final RoleLine line;
    if (d >= 0.76) {
      line = RoleLine.gk;
    } else if (d >= 0.65) {
      line = RoleLine.def;
    } else if (d >= 0.605) {
      line = RoleLine.dm;
    } else if (d >= 0.555) {
      line = RoleLine.mid;
    } else if (d >= 0.525) {
      line = RoleLine.am;
    } else {
      line = RoleLine.fwd;
    }
    final x = pos.dx;
    final int s; // 0 outer-left .. 4 outer-right
    if (x < 0.22) {
      s = 0;
    } else if (x < 0.42) {
      s = 1;
    } else if (x < 0.58) {
      s = 2;
    } else if (x < 0.78) {
      s = 3;
    } else {
      s = 4;
    }
    switch (line) {
      case RoleLine.gk:
        return 'GK';
      case RoleLine.def:
        return const ['LB', 'LCB', 'CB', 'RCB', 'RB'][s];
      case RoleLine.dm:
        return const ['LDM', 'LDM', 'CDM', 'RDM', 'RDM'][s];
      case RoleLine.mid:
        return const ['LM', 'LCM', 'CM', 'RCM', 'RM'][s];
      case RoleLine.am:
        return const ['LAM', 'LAM', 'CAM', 'RAM', 'RAM'][s];
      case RoleLine.fwd:
        return const ['LW', 'LS', 'ST', 'RS', 'RW'][s];
    }
  }
}
