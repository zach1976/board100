import 'volleyball_rotation.dart' show RotationRules;

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

  /// The goalkeeper: the fair-time suggestions leave a keeper where they
  /// are and never send one on for an outfield player. A coach can still
  /// swap keepers by hand.
  final bool isKeeper;

  const MatchPlayer(
      {required this.id,
      required this.name,
      this.number,
      this.isKeeper = false});

  MatchPlayer copyWith({bool? isKeeper}) => MatchPlayer(
      id: id, name: name, number: number, isKeeper: isKeeper ?? this.isKeeper);

  /// The name as the sheet prints it: "7 Ana", or just the name.
  String get label =>
      (number?.trim().isNotEmpty ?? false) ? '${number!.trim()} $name' : name;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (number != null) 'number': number,
        if (isKeeper) 'gk': true,
      };

  factory MatchPlayer.fromJson(Map<String, dynamic> j) => MatchPlayer(
        id: '${j['id']}',
        name: (j['name'] as String?) ?? '',
        number: j['number'] as String?,
        isKeeper: j['gk'] == true,
      );
}

/// What a logged swap was. A plain substitution counts against a set's
/// limit (volleyball); a libero replacement and a change to the starting
/// six before the set's first point do not.
enum SubstitutionKind { sub, libero, lineup }

/// One swap: [outId] left and [inId] came on at [clock] seconds of match
/// time, in [period] (1-based).
class Substitution {
  final int clock;
  final int period;
  final String outId;
  final String inId;
  final SubstitutionKind kind;

  const Substitution({
    required this.clock,
    required this.period,
    required this.outId,
    required this.inId,
    this.kind = SubstitutionKind.sub,
  });

  /// A swap that counts: not a libero replacement, not a lineup change.
  bool get counts => kind == SubstitutionKind.sub;

  Map<String, dynamic> toJson() => {
        'clock': clock,
        'period': period,
        'out': outId,
        'in': inId,
        if (kind != SubstitutionKind.sub) 'kind': kind.name,
      };

  factory Substitution.fromJson(Map<String, dynamic> j) => Substitution(
        clock: (j['clock'] as num?)?.toInt() ?? 0,
        period: (j['period'] as num?)?.toInt() ?? 1,
        outId: '${j['out']}',
        inId: '${j['in']}',
        kind: SubstitutionKind.values.firstWhere(
            (k) => k.name == j['kind'],
            orElse: () => SubstitutionKind.sub),
      );
}

/// The cards a sport's referee can show. Which ones, and how long each
/// keeps a player off, is the sport's table: SportType.matchDayCards.
enum MatchCardKind { green, yellow, red, suspension }

/// A card shown to [playerId] at [clock] in [period]. With [seconds] the
/// player sits out that long and comes back on their own (hockey: no
/// substitution for a suspended player); a red card is out for the match;
/// a card with neither (soccer's yellow) is a booking and nothing more.
class MatchCard {
  final String playerId;
  final MatchCardKind kind;
  final int clock;
  final int period;
  final int? seconds;

  const MatchCard({
    required this.playerId,
    required this.kind,
    required this.clock,
    required this.period,
    this.seconds,
  });

  bool get isRed => kind == MatchCardKind.red;

  /// Match time the player is back, or null for a red card.
  int? get endClock => isRed ? null : (seconds == null ? clock : clock + seconds!);

  /// Whether the player is off because of this card at match time [t].
  bool suspendedAt(int t) {
    if (t < clock) return false;
    final end = endClock;
    return end == null || t < end;
  }

  Map<String, dynamic> toJson() => {
        'player': playerId,
        'kind': kind.name,
        'clock': clock,
        'period': period,
        if (seconds != null) 'seconds': seconds,
      };

  factory MatchCard.fromJson(Map<String, dynamic> j) => MatchCard(
        playerId: '${j['player']}',
        kind: MatchCardKind.values.firstWhere((k) => k.name == j['kind'],
            orElse: () => MatchCardKind.yellow),
        clock: (j['clock'] as num?)?.toInt() ?? 0,
        period: (j['period'] as num?)?.toInt() ?? 1,
        seconds: (j['seconds'] as num?)?.toInt(),
      );
}

/// One attempt of a shoot-out: ours or theirs, who took it (a rostered
/// player for us, a name or number typed in for them), goal or miss.
class ShootOutAttempt {
  final bool us;
  final String? playerId;
  final String? taker;
  final bool scored;

  const ShootOutAttempt({
    required this.us,
    this.playerId,
    this.taker,
    required this.scored,
  });

  Map<String, dynamic> toJson() => {
        'us': us,
        if (playerId != null) 'player': playerId,
        if (taker != null) 'taker': taker,
        'goal': scored,
      };

  factory ShootOutAttempt.fromJson(Map<String, dynamic> j) => ShootOutAttempt(
        us: j['us'] == true,
        playerId: j['player'] as String?,
        taker: j['taker'] as String?,
        scored: j['goal'] == true,
      );
}

/// A finished set of a match counted per set: the score, and how many
/// substitutions and timeouts each side used in it.
class SetScore {
  final int us;
  final int them;
  final int subs;
  final int timeoutsUs;
  final int timeoutsThem;

  const SetScore({
    required this.us,
    required this.them,
    this.subs = 0,
    this.timeoutsUs = 0,
    this.timeoutsThem = 0,
  });

  Map<String, dynamic> toJson() => {
        'us': us,
        'them': them,
        'subs': subs,
        'toUs': timeoutsUs,
        'toThem': timeoutsThem,
      };

  factory SetScore.fromJson(Map<String, dynamic> j) => SetScore(
        us: (j['us'] as num?)?.toInt() ?? 0,
        them: (j['them'] as num?)?.toInt() ?? 0,
        subs: (j['subs'] as num?)?.toInt() ?? 0,
        timeoutsUs: (j['toUs'] as num?)?.toInt() ?? 0,
        timeoutsThem: (j['toThem'] as num?)?.toInt() ?? 0,
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
  /// Stable across devices, so a match synced twice is still one match.
  final String id;
  String name;
  final int periods;
  final int periodSeconds;
  final int onPitch;
  final List<MatchPlayer> players;
  final List<String> starters;
  final List<Substitution> subs;
  final List<MatchCard> cards;
  final List<ShootOutAttempt> shootOut;
  final DateTime startedAt;
  DateTime? finishedAt;

  /// When the match was last written; the newer copy wins on sync.
  DateTime updatedAt;

  /// Which period is on (1-based). In a match counted per set, the set.
  int period;

  /// Match time when the current period began, in seconds.
  int periodStartClock;

  /// Added time granted to the current period, in seconds. The clock
  /// stops by itself at the period's length; the coach's "+1 min" moves
  /// that line out and lets it run on. Reset by the next period.
  int extraSeconds;

  /// Match time accumulated while the clock was stopped, in seconds. While
  /// it runs, [clock] adds the wall time since [runningSince] — so the
  /// match survives a restart with the clock where it would have been, and
  /// nothing needs writing every second.
  int clockBase;
  DateTime? runningSince;

  // ── Counted per set (volleyball) instead of by the clock ──────────────

  /// True for a match of sets: no clock, [periods] is the best-of, the
  /// substitutions of each set are counted against [subLimit].
  final bool countsSets;

  /// Whose rulebook: a RotationRules name ("fivb" ...). Only in set mode.
  final String rules;

  /// The liberos, who replace a back-row player without a substitution.
  final List<String> liberos;

  /// The sets already played.
  final List<SetScore> setScores;

  /// The set in progress.
  int scoreUs;
  int scoreThem;
  int timeoutsUs;
  int timeoutsThem;

  static const int timeoutsPerSet = 2;

  MatchDay({
    String? id,
    this.name = '',
    required this.periods,
    required this.periodSeconds,
    required this.onPitch,
    required this.players,
    required this.starters,
    List<Substitution>? subs,
    List<MatchCard>? cards,
    List<ShootOutAttempt>? shootOut,
    DateTime? startedAt,
    this.finishedAt,
    DateTime? updatedAt,
    this.period = 1,
    this.periodStartClock = 0,
    this.extraSeconds = 0,
    this.clockBase = 0,
    this.runningSince,
    this.countsSets = false,
    this.rules = 'fivb',
    List<String>? liberos,
    List<SetScore>? setScores,
    this.scoreUs = 0,
    this.scoreThem = 0,
    this.timeoutsUs = 0,
    this.timeoutsThem = 0,
  })  : subs = subs ?? [],
        cards = cards ?? [],
        shootOut = shootOut ?? [],
        liberos = liberos ?? [],
        setScores = setScores ?? [],
        startedAt = startedAt ?? DateTime.now(),
        id = id ?? 'm${(startedAt ?? DateTime.now()).microsecondsSinceEpoch}',
        updatedAt = updatedAt ?? startedAt ?? DateTime.now();

  bool get isRunning => runningSince != null && finishedAt == null;
  bool get isFinished => finishedAt != null;

  /// Match time at which the current period ends, added time included.
  int get periodEndClock => periodStartClock + periodSeconds + extraSeconds;

  /// Seconds of match time so far. Never past the end of the period: the
  /// clock stops there by itself, and stays there through a restart.
  int clock([DateTime? now]) {
    final since = runningSince;
    if (since == null) return clockBase;
    final secs = (now ?? DateTime.now()).difference(since).inSeconds;
    final raw = clockBase + (secs < 0 ? 0 : secs);
    return raw > periodEndClock ? periodEndClock : raw;
  }

  /// Seconds into the current period.
  int periodClock([DateTime? now]) => clock(now) - periodStartClock;

  /// The period has run its length: the clock holds until the coach adds
  /// time or moves to the next period.
  bool isPeriodOver([DateTime? now]) =>
      !countsSets && !isFinished && clock(now) >= periodEndClock;

  /// Grant added time to the current period and let the clock run on.
  void addTime(int seconds, [DateTime? now]) {
    if (isFinished || seconds <= 0) return;
    if (runningSince != null) clockBase = clock(now);
    extraSeconds += seconds;
    runningSince = now ?? DateTime.now();
  }

  MatchPlayer? player(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Who holds a place in the side now: the starters, with every logged
  /// swap applied in order. In starting order, so the list does not
  /// reshuffle under a coach's thumb after every change. A suspended
  /// player keeps their place — nobody comes on for them — so this is not
  /// quite who is on the pitch: see [onPitchIds].
  List<String> get lineupIds {
    final on = [...starters];
    for (final s in subs) {
      final i = on.indexOf(s.outId);
      if (i < 0) continue;
      on[i] = s.inId;
    }
    return on;
  }

  /// Who is on the pitch now: the side less anyone sitting out a card.
  List<String> get onPitchIds {
    final off = suspendedIds();
    return [for (final id in lineupIds) if (!off.contains(id)) id];
  }

  List<String> get benchIds {
    final on = lineupIds.toSet();
    return [for (final p in players) if (!on.contains(p.id)) p.id];
  }

  /// Players off the pitch on a card at match time [at] (defaults to now):
  /// serving a suspension, or sent off.
  Set<String> suspendedIds([int? at]) {
    final t = at ?? clock();
    return {for (final c in cards) if (c.suspendedAt(t)) c.playerId};
  }

  /// The card keeping [id] off at [at], if any — the one that ends last.
  MatchCard? suspension(String id, [int? at]) {
    final t = at ?? clock();
    MatchCard? best;
    for (final c in cards) {
      if (c.playerId != id || !c.suspendedAt(t)) continue;
      if (best == null || c.endClock == null) {
        best = c;
      } else if (best.endClock != null && c.endClock! > best.endClock!) {
        best = c;
      }
    }
    return best;
  }

  /// Seconds each player has been on the pitch at [at] (match time;
  /// defaults to now). Every rostered player has an entry, bench-only ones
  /// at zero. Time sat out on a card is not playing time.
  Map<String, int> playingTime([int? at]) {
    final t = at ?? clock();
    final total = {for (final p in players) p.id: 0};
    final onSince = {for (final id in starters) id: 0};
    void played(String id, int from, int to) {
      var secs = to - from;
      for (final (a, b) in _suspendedSpans(id, t)) {
        final lo = a > from ? a : from;
        final hi = b < to ? b : to;
        if (hi > lo) secs -= hi - lo;
      }
      total[id] = (total[id] ?? 0) + secs;
    }

    for (final s in subs) {
      final since = onSince.remove(s.outId);
      if (since != null) played(s.outId, since, s.clock);
      onSince[s.inId] = s.clock;
    }
    for (final e in onSince.entries) {
      played(e.key, e.value, t);
    }
    return total;
  }

  /// The spans of match time [id] sat out, up to [t], merged so two cards
  /// that overlap are not counted twice.
  List<(int, int)> _suspendedSpans(String id, int t) {
    final spans = <(int, int)>[];
    for (final c in cards) {
      if (c.playerId != id) continue;
      final end = c.endClock ?? t;
      final b = end < t ? end : t;
      if (b > c.clock) spans.add((c.clock, b));
    }
    if (spans.length < 2) return spans;
    spans.sort((x, y) => x.$1.compareTo(y.$1));
    final merged = <(int, int)>[spans.first];
    for (final sp in spans.skip(1)) {
      final last = merged.last;
      if (sp.$1 <= last.$2) {
        merged[merged.length - 1] = (last.$1, sp.$2 > last.$2 ? sp.$2 : last.$2);
      } else {
        merged.add(sp);
      }
    }
    return merged;
  }

  void start([DateTime? now]) {
    if (isFinished || runningSince != null || countsSets) return;
    if (isPeriodOver(now)) return;
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
    extraSeconds = 0;
  }

  void finish([DateTime? now]) {
    pause(now);
    finishedAt = now ?? DateTime.now();
  }

  // ── Cards ──────────────────────────────────────────────────────────────

  /// Show [playerId] a card at the current clock. Refused once the player
  /// has been sent off — there is nothing left to show them.
  bool giveCard(String playerId, MatchCardKind kind,
      {int? seconds, DateTime? now}) {
    if (isFinished || player(playerId) == null) return false;
    if (cards.any((c) => c.playerId == playerId && c.isRed)) return false;
    cards.add(MatchCard(
      playerId: playerId,
      kind: kind,
      clock: clock(now),
      period: period,
      seconds: kind == MatchCardKind.red ? null : seconds,
    ));
    return true;
  }

  // ── Shoot-out ──────────────────────────────────────────────────────────

  /// Goals so far in the shoot-out, ours and theirs.
  ({int us, int them}) get shootOutScore {
    var us = 0, them = 0;
    for (final a in shootOut) {
      if (!a.scored) continue;
      if (a.us) {
        us++;
      } else {
        them++;
      }
    }
    return (us: us, them: them);
  }

  void addShootOutAttempt(ShootOutAttempt attempt) => shootOut.add(attempt);

  void removeLastShootOutAttempt() {
    if (shootOut.isNotEmpty) shootOut.removeLast();
  }

  // ── Sets ───────────────────────────────────────────────────────────────

  /// Substitutions a set allows under [rules] (6 FIVB, 12 USAV, 18 NFHS,
  /// 15 NCAA); unlimited when the match is not counted per set.
  int get subLimit {
    if (!countsSets) return 1 << 30;
    return RotationRules.values
        .firstWhere((r) => r.name == rules, orElse: () => RotationRules.fivb)
        .substitutions;
  }

  /// Counted substitutions made in set [n] (the current set by default).
  int subsInSet([int? n]) {
    final set = n ?? period;
    return subs.where((s) => s.period == set && s.counts).length;
  }

  int get subsLeft => subLimit - subsInSet();

  bool isLibero(String id) => liberos.contains(id);

  /// A point for us or for them; [delta] -1 takes one back.
  void point({required bool us, int delta = 1}) {
    if (isFinished) return;
    if (us) {
      scoreUs = (scoreUs + delta).clamp(0, 999);
    } else {
      scoreThem = (scoreThem + delta).clamp(0, 999);
    }
  }

  /// A timeout for us or for them; refused past the set's two.
  bool timeout({required bool us}) {
    if (isFinished) return false;
    if (us) {
      if (timeoutsUs >= timeoutsPerSet) return false;
      timeoutsUs++;
    } else {
      if (timeoutsThem >= timeoutsPerSet) return false;
      timeoutsThem++;
    }
    return true;
  }

  int get setsWonUs => setScores.where((s) => s.us > s.them).length;
  int get setsWonThem => setScores.where((s) => s.them > s.us).length;

  /// File the set in progress and open the next: substitutions and
  /// timeouts start from nothing again. Once a side has the majority of
  /// the best-of, or the last set is played, the match is over.
  void endSet([DateTime? now]) {
    if (isFinished) return;
    setScores.add(SetScore(
      us: scoreUs,
      them: scoreThem,
      subs: subsInSet(),
      timeoutsUs: timeoutsUs,
      timeoutsThem: timeoutsThem,
    ));
    scoreUs = 0;
    scoreThem = 0;
    timeoutsUs = 0;
    timeoutsThem = 0;
    final need = periods ~/ 2 + 1;
    if (setsWonUs >= need || setsWonThem >= need || period >= periods) {
      finish(now);
      return;
    }
    period += 1;
  }

  /// How many sets each player was on court in: on at the start of the
  /// set or came on during it.
  Map<String, int> setsPlayed() {
    final out = {for (final p in players) p.id: 0};
    final lastSet = isFinished ? setScores.length : period;
    var on = [...starters];
    var i = 0;
    for (var set = 1; set <= lastSet; set++) {
      final seen = <String>{};
      // Lineup changes come before the set's first point: whoever they
      // take off never played the set.
      final pending = <Substitution>[];
      while (i < subs.length && subs[i].period <= set) {
        pending.add(subs[i]);
        i++;
      }
      final lineupOut = {
        for (final s in pending)
          if (s.kind == SubstitutionKind.lineup) s.outId
      };
      seen.addAll(on.where((id) => !lineupOut.contains(id)));
      for (final s in pending) {
        final k = on.indexOf(s.outId);
        if (k >= 0) on[k] = s.inId;
        seen.add(s.inId);
      }
      for (final id in seen) {
        out[id] = (out[id] ?? 0) + 1;
      }
    }
    return out;
  }

  /// Counted substitutions per player: times they came on and went off.
  Map<String, ({int inn, int out})> subCounts() {
    final res = {for (final p in players) p.id: (inn: 0, out: 0)};
    for (final s in subs) {
      if (!s.counts) continue;
      final a = res[s.inId] ?? (inn: 0, out: 0);
      res[s.inId] = (inn: a.inn + 1, out: a.out);
      final b = res[s.outId] ?? (inn: 0, out: 0);
      res[s.outId] = (inn: b.inn, out: b.out + 1);
    }
    return res;
  }

  /// Log a swap at the current clock. Nothing happens unless [outId] is on
  /// and [inId] is off, so a double tap cannot put one player on twice; nor
  /// for a player sitting out a card. In set mode a counted swap is refused
  /// once the set's limit is used up, a lineup change only before the
  /// set's first point, a libero replacement only with a libero in it.
  bool substitute(String outId, String inId,
      [DateTime? now, SubstitutionKind kind = SubstitutionKind.sub]) {
    if (isFinished) return false;
    final t = clock(now);
    final off = suspendedIds(t);
    final side = lineupIds;
    if (!side.contains(outId) || off.contains(outId)) return false;
    if (side.contains(inId) || off.contains(inId)) return false;
    if (player(inId) == null) return false;
    if (countsSets) {
      switch (kind) {
        case SubstitutionKind.sub:
          if (subsLeft <= 0) return false;
        case SubstitutionKind.lineup:
          if (scoreUs + scoreThem > 0) return false;
        case SubstitutionKind.libero:
          if (!isLibero(outId) && !isLibero(inId)) return false;
      }
    }
    subs.add(Substitution(
        clock: t, period: period, outId: outId, inId: inId, kind: kind));
    return true;
  }

  /// The swaps that most even out playing time: the most-played on the
  /// pitch for the least-played on the bench, pair by pair, while the pair
  /// is at least [minGapSeconds] apart. Greedy, and good enough for a
  /// touchline — the coach sees the pairs before they happen. Keepers stay
  /// out of it, as does anyone sitting out a card.
  List<SwapSuggestion> suggest(
      {int minGapSeconds = 60, int max = 3, int? at}) {
    final times = playingTime(at);
    final off = suspendedIds(at);
    bool outfield(String id) =>
        !(player(id)?.isKeeper ?? false) && !off.contains(id);
    return suggestSwaps(times, onPitchIds.where(outfield).toList(),
        benchIds.where(outfield).toList(),
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
        'id': id,
        'name': name,
        'periods': periods,
        'periodSeconds': periodSeconds,
        'onPitch': onPitch,
        'players': players.map((p) => p.toJson()).toList(),
        'starters': starters,
        'subs': subs.map((s) => s.toJson()).toList(),
        if (cards.isNotEmpty) 'cards': cards.map((c) => c.toJson()).toList(),
        if (shootOut.isNotEmpty)
          'shootOut': shootOut.map((a) => a.toJson()).toList(),
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'period': period,
        'periodStartClock': periodStartClock,
        if (extraSeconds != 0) 'extraSeconds': extraSeconds,
        'clockBase': clockBase,
        'runningSince': runningSince?.toIso8601String(),
        if (countsSets) ...{
          'countsSets': true,
          'rules': rules,
          'liberos': liberos,
          'setScores': setScores.map((s) => s.toJson()).toList(),
          'scoreUs': scoreUs,
          'scoreThem': scoreThem,
          'timeoutsUs': timeoutsUs,
          'timeoutsThem': timeoutsThem,
        },
      };

  factory MatchDay.fromJson(Map<String, dynamic> j) => MatchDay(
        id: j['id'] as String?,
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
        cards: ((j['cards'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => MatchCard.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        shootOut: ((j['shootOut'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) =>
                ShootOutAttempt.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        startedAt: DateTime.tryParse(j['startedAt'] as String? ?? ''),
        finishedAt: DateTime.tryParse(j['finishedAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ??
            DateTime.tryParse(j['finishedAt'] as String? ?? '') ??
            DateTime.tryParse(j['startedAt'] as String? ?? ''),
        period: (j['period'] as num?)?.toInt() ?? 1,
        periodStartClock: (j['periodStartClock'] as num?)?.toInt() ?? 0,
        extraSeconds: (j['extraSeconds'] as num?)?.toInt() ?? 0,
        clockBase: (j['clockBase'] as num?)?.toInt() ?? 0,
        runningSince: DateTime.tryParse(j['runningSince'] as String? ?? ''),
        countsSets: j['countsSets'] == true,
        rules: (j['rules'] as String?) ?? 'fivb',
        liberos: ((j['liberos'] as List?) ?? const []).map((e) => '$e').toList(),
        setScores: ((j['setScores'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => SetScore.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        scoreUs: (j['scoreUs'] as num?)?.toInt() ?? 0,
        scoreThem: (j['scoreThem'] as num?)?.toInt() ?? 0,
        timeoutsUs: (j['timeoutsUs'] as num?)?.toInt() ?? 0,
        timeoutsThem: (j['timeoutsThem'] as num?)?.toInt() ?? 0,
      );
}
