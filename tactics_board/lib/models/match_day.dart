/// A match day: the substitution sheet with fair playing time.
///
/// What the 2026 field-hockey apps all have — a table of who is on, who is
/// waiting and how long each has played, with the bench ordered so the
/// fair choice is the top row. Nothing here knows which sport it is: the
/// periods, their length and the number on the pitch come from the sport
/// (SportType.matchDayDefaults) and are stored with the match, so the same
/// sheet serves soccer or handball when they turn it on.
///
/// The clock is one number, [clock], in seconds of match time; a period
/// boundary moves [periodStartClock] forward. Playing time is never stored
/// per player — it is derived from the starters and the log by
/// [playingTime], so the sheet can never disagree with its own log.
class MatchPlayer {
  final String id;
  final String name;

  /// Shirt number when the roster came from a squad. Shown before the name.
  final String? number;

  const MatchPlayer({required this.id, required this.name, this.number});

  /// The name as the sheet prints it: "7 Ana", or just the name.
  String get label =>
      (number?.trim().isNotEmpty ?? false) ? '${number!.trim()} $name' : name;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (number != null) 'number': number,
      };

  factory MatchPlayer.fromJson(Map<String, dynamic> j) => MatchPlayer(
        id: '${j['id']}',
        name: (j['name'] as String?) ?? '',
        number: j['number'] as String?,
      );
}

/// One swap: [outId] left and [inId] came on at [clock] seconds of match
/// time, in [period] (1-based).
class Substitution {
  final int clock;
  final int period;
  final String outId;
  final String inId;

  const Substitution({
    required this.clock,
    required this.period,
    required this.outId,
    required this.inId,
  });

  Map<String, dynamic> toJson() => {
        'clock': clock,
        'period': period,
        'out': outId,
        'in': inId,
      };

  factory Substitution.fromJson(Map<String, dynamic> j) => Substitution(
        clock: (j['clock'] as num?)?.toInt() ?? 0,
        period: (j['period'] as num?)?.toInt() ?? 1,
        outId: '${j['out']}',
        inId: '${j['in']}',
      );
}

/// A proposed swap from [MatchDay.suggest]: the player to take off and the
/// one to send on, with how far apart their playing time is.
class SwapSuggestion {
  final String outId;
  final String inId;
  final int gapSeconds;
  const SwapSuggestion(
      {required this.outId, required this.inId, required this.gapSeconds});
}

class MatchDay {
  String name;
  final int periods;
  final int periodSeconds;
  final int onPitch;
  final List<MatchPlayer> players;
  final List<String> starters;
  final List<Substitution> subs;
  final DateTime startedAt;
  DateTime? finishedAt;

  /// Which period is on (1-based).
  int period;

  /// Match time when the current period began, in seconds.
  int periodStartClock;

  /// Match time accumulated while the clock was stopped, in seconds. While
  /// it runs, [clock] adds the wall time since [runningSince] — so the
  /// match survives a restart with the clock where it would have been, and
  /// nothing needs writing every second.
  int clockBase;
  DateTime? runningSince;

  MatchDay({
    this.name = '',
    required this.periods,
    required this.periodSeconds,
    required this.onPitch,
    required this.players,
    required this.starters,
    List<Substitution>? subs,
    DateTime? startedAt,
    this.finishedAt,
    this.period = 1,
    this.periodStartClock = 0,
    this.clockBase = 0,
    this.runningSince,
  })  : subs = subs ?? [],
        startedAt = startedAt ?? DateTime.now();

  bool get isRunning => runningSince != null && finishedAt == null;
  bool get isFinished => finishedAt != null;

  /// Seconds of match time so far.
  int clock([DateTime? now]) {
    final since = runningSince;
    if (since == null) return clockBase;
    final secs = (now ?? DateTime.now()).difference(since).inSeconds;
    return clockBase + (secs < 0 ? 0 : secs);
  }

  /// Seconds into the current period.
  int periodClock([DateTime? now]) => clock(now) - periodStartClock;

  MatchPlayer? player(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Who is on the pitch now: the starters, with every logged swap applied
  /// in order. In starting order, so the list does not reshuffle under a
  /// coach's thumb after every change.
  List<String> get onPitchIds {
    final on = [...starters];
    for (final s in subs) {
      final i = on.indexOf(s.outId);
      if (i < 0) continue;
      on[i] = s.inId;
    }
    return on;
  }

  List<String> get benchIds {
    final on = onPitchIds.toSet();
    return [for (final p in players) if (!on.contains(p.id)) p.id];
  }

  /// Seconds each player has been on the pitch at [at] (match time;
  /// defaults to now). Every rostered player has an entry, bench-only ones
  /// at zero.
  Map<String, int> playingTime([int? at]) {
    final t = at ?? clock();
    final total = {for (final p in players) p.id: 0};
    final onSince = {for (final id in starters) id: 0};
    for (final s in subs) {
      final since = onSince.remove(s.outId);
      if (since != null) total[s.outId] = (total[s.outId] ?? 0) + (s.clock - since);
      onSince[s.inId] = s.clock;
    }
    for (final e in onSince.entries) {
      total[e.key] = (total[e.key] ?? 0) + (t - e.value);
    }
    return total;
  }

  void start([DateTime? now]) {
    if (isFinished || runningSince != null) return;
    runningSince = now ?? DateTime.now();
  }

  void pause([DateTime? now]) {
    final since = runningSince;
    if (since == null) return;
    clockBase = clock(now);
    runningSince = null;
  }

  /// Close the period: the clock stops and the next period waits on the
  /// start button. The last period ends the match instead.
  void nextPeriod([DateTime? now]) {
    pause(now);
    if (period >= periods) {
      finish(now);
      return;
    }
    period += 1;
    periodStartClock = clockBase;
  }

  void finish([DateTime? now]) {
    pause(now);
    finishedAt = now ?? DateTime.now();
  }

  /// Log a swap at the current clock. Nothing happens unless [outId] is on
  /// and [inId] is off, so a double tap cannot put one player on twice.
  bool substitute(String outId, String inId, [DateTime? now]) {
    if (isFinished) return false;
    final on = onPitchIds;
    if (!on.contains(outId) || on.contains(inId)) return false;
    if (player(inId) == null) return false;
    subs.add(Substitution(
        clock: clock(now), period: period, outId: outId, inId: inId));
    return true;
  }

  /// The swaps that most even out playing time: the most-played on the
  /// pitch for the least-played on the bench, pair by pair, while the pair
  /// is at least [minGapSeconds] apart. Greedy, and good enough for a
  /// touchline — the coach sees the pairs before they happen.
  List<SwapSuggestion> suggest(
      {int minGapSeconds = 60, int max = 3, int? at}) {
    final times = playingTime(at);
    return suggestSwaps(times, onPitchIds, benchIds,
        minGapSeconds: minGapSeconds, max: max);
  }

  static List<SwapSuggestion> suggestSwaps(
    Map<String, int> times,
    List<String> onPitch,
    List<String> bench, {
    int minGapSeconds = 60,
    int max = 3,
  }) {
    final on = [...onPitch]
      ..sort((a, b) => (times[b] ?? 0).compareTo(times[a] ?? 0));
    final off = [...bench]
      ..sort((a, b) => (times[a] ?? 0).compareTo(times[b] ?? 0));
    final out = <SwapSuggestion>[];
    for (var i = 0; i < on.length && i < off.length && out.length < max; i++) {
      final gap = (times[on[i]] ?? 0) - (times[off[i]] ?? 0);
      if (gap < minGapSeconds) break;
      out.add(SwapSuggestion(outId: on[i], inId: off[i], gapSeconds: gap));
    }
    return out;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'periods': periods,
        'periodSeconds': periodSeconds,
        'onPitch': onPitch,
        'players': players.map((p) => p.toJson()).toList(),
        'starters': starters,
        'subs': subs.map((s) => s.toJson()).toList(),
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'period': period,
        'periodStartClock': periodStartClock,
        'clockBase': clockBase,
        'runningSince': runningSince?.toIso8601String(),
      };

  factory MatchDay.fromJson(Map<String, dynamic> j) => MatchDay(
        name: (j['name'] as String?) ?? '',
        periods: (j['periods'] as num?)?.toInt() ?? 2,
        periodSeconds: (j['periodSeconds'] as num?)?.toInt() ?? 1800,
        onPitch: (j['onPitch'] as num?)?.toInt() ?? 11,
        players: ((j['players'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => MatchPlayer.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        starters:
            ((j['starters'] as List?) ?? const []).map((e) => '$e').toList(),
        subs: ((j['subs'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Substitution.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        startedAt: DateTime.tryParse(j['startedAt'] as String? ?? ''),
        finishedAt: DateTime.tryParse(j['finishedAt'] as String? ?? ''),
        period: (j['period'] as num?)?.toInt() ?? 1,
        periodStartClock: (j['periodStartClock'] as num?)?.toInt() ?? 0,
        clockBase: (j['clockBase'] as num?)?.toInt() ?? 0,
        runningSince: DateTime.tryParse(j['runningSince'] as String? ?? ''),
      );
}
