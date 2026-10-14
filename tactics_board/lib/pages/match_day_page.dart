import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/match_day.dart';
import '../models/player_photo.dart';
import '../models/sport_type.dart';
import '../models/volleyball_rotation.dart' show RotationRules;
import '../services/ad_service.dart';
import '../services/match_day_service.dart';
import '../services/pdf_export_service.dart';
import '../services/photo_library_service.dart';
import '../services/purchase_service.dart';
import '../ui/adaptive.dart';
import '../ui/primitives.dart';
import '../ui/tokens.dart';
import '../widgets/playbook_sheet.dart';
import 'home_page.dart' show showPaywallSheet;

/// Match day: the substitution sheet with fair playing time.
///
/// Three screens in one page, chosen by the match's state: the setup (the
/// roster and who starts), the running sheet (the clock, the pitch, the
/// bench ordered by least time) and the summary (minutes per player and
/// the log, shareable as a PDF). The match in progress is written to disk
/// after every change, so a phone that dies in the third quarter comes
/// back with the clock and the log where they were.
///
/// Setting up is free; the clock is Pro. A coach can see what the sheet is
/// before being asked to pay for it.
class MatchDayPage extends StatefulWidget {
  final SportType sport;
  const MatchDayPage({super.key, required this.sport});

  @override
  State<MatchDayPage> createState() => _MatchDayPageState();
}

class _MatchDayPageState extends State<MatchDayPage> {
  bool _loading = true;
  MatchDay? _match;
  List<MatchDay> _history = const [];

  /// A finished match opened from the list, read-only.
  MatchDay? _viewing;

  // Setup.
  final _nameCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  late int _periods;
  late int _minutes;
  late int _onPitch;
  final List<MatchPlayer> _roster = [];
  final Set<String> _starters = {};
  final Set<String> _keepers = {};
  final Set<String> _liberos = {};
  late String _rules;
  late int _bestOf;
  int _nextId = 1;

  /// Volleyball: sets and a substitution count instead of a clock.
  bool get _setMode => widget.sport.matchDayCountsSets;

  // Running.
  Timer? _tick;
  String? _selOut;
  String? _selIn;

  @override
  void initState() {
    super.initState();
    AdService.instance.pushAdSuppression(); // a match in progress stays ad-free
    final d = widget.sport.matchDayDefaults;
    _periods = d.periods;
    _minutes = d.minutes;
    _onPitch = d.onPitch;
    _rules = RotationRules.fivb.name;
    _bestOf = 5;
    _load();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _nameCtrl.dispose();
    _newCtrl.dispose();
    AdService.instance.popAdSuppression();
    super.dispose();
  }

  Future<void> _load() async {
    final current = await MatchDayService.loadCurrent(widget.sport);
    final history = await MatchDayService.history(widget.sport);
    if (!mounted) return;
    setState(() {
      _match = current;
      _history = history;
      _loading = false;
    });
    _settleClock();
    _syncTick();
  }

  /// The clock stops by itself at the end of the period. Once it is
  /// there, hold it there — and write that down, so a phone that dies
  /// comes back stopped at the whistle too.
  void _settleClock() {
    final m = _match;
    if (m == null || !m.isRunning || !m.isPeriodOver()) return;
    m.pause();
    _save();
  }

  Future<void> _save() async {
    final m = _match;
    if (m == null) return;
    try {
      await MatchDayService.saveCurrent(widget.sport, m);
    } catch (_) {}
  }

  /// The clock redraws once a second while it runs, and not at all when
  /// it does not — the match's own time comes from wall time, so a missed
  /// tick costs nothing.
  void _syncTick() {
    final running = _match?.isRunning ?? false;
    if (running && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        _settleClock();
        _syncTick();
        setState(() {});
      });
    } else if (!running) {
      _tick?.cancel();
      _tick = null;
    }
  }

  bool get _gated =>
      PurchaseService.instance.isStoreEnabled &&
      !PurchaseService.instance.hasPro;

  static String mmss(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Setup ──────────────────────────────────────────────────────────────

  void _addPlayer() {
    final name = _newCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _roster.add(MatchPlayer(id: 'p${_nextId++}', name: name));
      _newCtrl.clear();
    });
  }

  void _removePlayer(MatchPlayer p) {
    setState(() {
      _roster.remove(p);
      _starters.remove(p.id);
      _keepers.remove(p.id);
      _liberos.remove(p.id);
    });
  }

  void _toggleStarter(MatchPlayer p) {
    if (_liberos.contains(p.id)) return;
    setState(() {
      if (!_starters.remove(p.id)) {
        if (_starters.length < _onPitch) _starters.add(p.id);
      }
    });
  }

  void _toggleKeeper(MatchPlayer p) {
    setState(() {
      if (!_keepers.remove(p.id)) _keepers.add(p.id);
    });
  }

  /// A libero starts on the bench and comes on for a back-row player
  /// without a substitution, so they cannot be one of the six.
  void _toggleLibero(MatchPlayer p) {
    setState(() {
      if (!_liberos.remove(p.id)) {
        _liberos.add(p.id);
        _starters.remove(p.id);
      }
    });
  }

  /// Fill the roster from one of the coach's saved squads (My Teams).
  Future<void> _loadTeam() async {
    final groups = await PhotoLibraryService.instance.listGroups();
    if (!mounted) return;
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('matchday_no_teams'.tr())));
      return;
    }
    PhotoGroup? group = groups.length == 1 ? groups.first : null;
    group ??= await TacticalSheet.show<PhotoGroup>(
      context,
      builder: (ctx) => TacticalSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TacticalSheetHeader(title: 'matchday_pick_team'.tr()),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final g in groups)
                    ListTile(
                      title: Text(g.name,
                          style: const TextStyle(color: T.text)),
                      onTap: () => Navigator.pop(ctx, g),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (group == null || !mounted) return;
    final squad = await PhotoLibraryService.instance.squad(group.id);
    if (!mounted) return;
    setState(() {
      _roster.clear();
      _starters.clear();
      _keepers.clear();
      _liberos.clear();
      for (final m in squad) {
        final name = m.playerName?.trim() ?? '';
        final number = m.jerseyNumber?.trim();
        if (name.isEmpty && (number == null || number.isEmpty)) continue;
        _roster.add(MatchPlayer(
            id: m.id, name: name.isEmpty ? number! : name, number: number));
      }
    });
  }

  bool get _canStart =>
      _roster.length >= _onPitch && _starters.length == _onPitch;

  Future<void> _startMatch() async {
    if (!_canStart) return;
    if (_gated) {
      showPaywallSheet(context);
      return;
    }
    final match = MatchDay(
      name: _nameCtrl.text.trim(),
      periods: _setMode ? _bestOf : _periods,
      periodSeconds: _setMode ? 0 : _minutes * 60,
      onPitch: _onPitch,
      players: [
        for (final p in _roster)
          _keepers.contains(p.id) ? p.copyWith(isKeeper: true) : p,
      ],
      starters: [for (final p in _roster) if (_starters.contains(p.id)) p.id],
      countsSets: _setMode,
      rules: _rules,
      liberos: [for (final p in _roster) if (_liberos.contains(p.id)) p.id],
    );
    setState(() {
      _match = match;
      _selOut = null;
      _selIn = null;
    });
    await _save();
  }

  // ── Running ────────────────────────────────────────────────────────────

  Future<void> _toggleClock() async {
    final m = _match;
    if (m == null) return;
    setState(() {
      if (m.isRunning) {
        m.pause();
      } else {
        m.start();
      }
    });
    _syncTick();
    await _save();
  }

  /// Added time: the clock stopped at the period's length; let it run on.
  Future<void> _addTime() async {
    final m = _match;
    if (m == null) return;
    setState(() => m.addTime(60));
    _syncTick();
    await _save();
  }

  Future<void> _nextPeriod() async {
    final m = _match;
    if (m == null) return;
    if (m.period >= m.periods) {
      final ok = await _confirm('matchday_end_confirm'.tr(),
          action: 'matchday_end_match'.tr());
      if (ok != true || !mounted) return;
    }
    setState(() => m.nextPeriod());
    _syncTick();
    await _save();
  }

  Future<void> _endMatch() async {
    final m = _match;
    if (m == null) return;
    final ok = await _confirm('matchday_end_confirm'.tr(),
        action: 'matchday_end_match'.tr());
    if (ok != true || !mounted) return;
    setState(() {
      // A set with points in it is filed before the whistle.
      if (m.countsSets && m.scoreUs + m.scoreThem > 0) m.endSet();
      if (!m.isFinished) m.finish();
    });
    _syncTick();
    await _save();
  }

  // ── Sets ───────────────────────────────────────────────────────────────

  Future<void> _point({required bool us, int delta = 1}) async {
    final m = _match;
    if (m == null) return;
    setState(() => m.point(us: us, delta: delta));
    await _save();
  }

  Future<void> _timeout({required bool us}) async {
    final m = _match;
    if (m == null) return;
    setState(() => m.timeout(us: us));
    await _save();
  }

  Future<void> _endSet() async {
    final m = _match;
    if (m == null) return;
    final ok = await _confirm(
        'matchday_end_set_confirm'
            .tr(namedArgs: {'us': '${m.scoreUs}', 'them': '${m.scoreThem}'}),
        action: 'matchday_end_set'.tr());
    if (ok != true || !mounted) return;
    setState(() {
      m.endSet();
      _selOut = null;
      _selIn = null;
    });
    await _save();
  }

  // ── Cards ──────────────────────────────────────────────────────────────

  String _cardLabel(MatchCardKind kind) {
    switch (kind) {
      case MatchCardKind.green:
        return 'matchday_card_green'.tr();
      case MatchCardKind.yellow:
        return 'matchday_card_yellow'.tr();
      case MatchCardKind.red:
        return 'matchday_card_red'.tr();
      case MatchCardKind.suspension:
        return 'matchday_card_suspension'.tr();
    }
  }

  Color _cardColor(MatchCardKind kind) {
    switch (kind) {
      case MatchCardKind.green:
        return T.success;
      case MatchCardKind.yellow:
        return T.warning;
      case MatchCardKind.red:
        return T.danger;
      case MatchCardKind.suspension:
        return T.textDim;
    }
  }

  /// The card and its time on one line: "Yellow card · 5 min".
  String _cardText(MatchCardKind kind, int? seconds) {
    final name = _cardLabel(kind);
    if (seconds == null || kind == MatchCardKind.suspension) return name;
    return '$name · ${'matchday_card_minutes'.tr(namedArgs: {
          'n': '${seconds ~/ 60}'
        })}';
  }

  Future<void> _pickCard(String id) async {
    final m = _match;
    if (m == null) return;
    final cards = widget.sport.matchDayCards;
    if (cards.isEmpty) return;
    final picked = await TacticalSheet.show<int>(
      context,
      builder: (ctx) => TacticalSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TacticalSheetHeader(
                title: 'matchday_card_title'
                    .tr(namedArgs: {'name': m.player(id)?.label ?? id})),
            for (var i = 0; i < cards.length; i++)
              ListTile(
                leading: Icon(Icons.style_rounded,
                    color: _cardColor(cards[i].kind)),
                title: Text(_cardText(cards[i].kind, cards[i].seconds),
                    style: const TextStyle(color: T.text)),
                onTap: () => Navigator.pop(ctx, i),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final c = cards[picked];
    setState(() {
      m.giveCard(id, c.kind, seconds: c.seconds);
      _selOut = null;
    });
    await _save();
  }

  // ── Shoot-out ──────────────────────────────────────────────────────────

  String _attemptLabel(MatchDay m, ShootOutAttempt a) {
    final who = a.playerId != null
        ? (m.player(a.playerId!)?.label ?? a.playerId!)
        : (a.taker ?? '');
    final side = a.us ? 'matchday_shootout_us'.tr() : 'matchday_shootout_them'.tr();
    return who.isEmpty ? side : '$side · $who';
  }

  Future<void> _shootOut() async {
    final m = _match;
    if (m == null) return;
    await TacticalSheet.show<void>(
      context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) {
        final sc = m.shootOutScore;
        Future<void> add(bool us, bool scored) async {
          String? playerId;
          String? taker;
          if (us) {
            playerId = await TacticalSheet.show<String>(
              ctx,
              builder: (c2) => TacticalSheet(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TacticalSheetHeader(title: 'matchday_player'.tr()),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final p in m.players)
                            ListTile(
                              title: Text(p.label,
                                  style: const TextStyle(color: T.text)),
                              onTap: () => Navigator.pop(c2, p.id),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
            if (playerId == null) return;
          } else {
            final ctrl = TextEditingController();
            taker = await showDialog<String>(
              context: ctx,
              builder: (c2) => AlertDialog(
                backgroundColor: T.surface,
                title: Text('matchday_shootout_them'.tr(), style: T.dialogTitle),
                content: TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: const TextStyle(color: T.text),
                  decoration: InputDecoration(
                    hintText: 'matchday_shootout_taker_hint'.tr(),
                    hintStyle: const TextStyle(color: T.textOff),
                  ),
                  onSubmitted: (v) => Navigator.pop(c2, v),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c2),
                      child: Text('cancel'.tr())),
                  TextButton(
                      onPressed: () => Navigator.pop(c2, ctrl.text),
                      child: Text(scored ? 'matchday_goal'.tr() : 'matchday_miss'.tr(),
                          style: const TextStyle(color: T.accent))),
                ],
              ),
            );
            ctrl.dispose();
            if (taker == null) return;
            taker = taker.trim();
          }
          m.addShootOutAttempt(ShootOutAttempt(
              us: us, playerId: playerId, taker: taker, scored: scored));
          refresh(() {});
          await _save();
        }

        return TacticalSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TacticalSheetHeader(
                title: 'matchday_shootout'.tr(),
                subtitle: '${'matchday_shootout_us'.tr()} ${sc.us} – '
                    '${sc.them} ${'matchday_shootout_them'.tr()}',
              ),
              Flexible(
                child: m.shootOut.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: T.s8),
                        child: Text('matchday_shootout_empty'.tr(),
                            style: T.caption),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (var i = 0; i < m.shootOut.length; i++)
                            _PlayerRow(
                              label: '${i + 1}.  '
                                  '${_attemptLabel(m, m.shootOut[i])}',
                              value: m.shootOut[i].scored
                                  ? 'matchday_goal'.tr()
                                  : 'matchday_miss'.tr(),
                              leading: Icon(
                                m.shootOut[i].scored
                                    ? Icons.sports_score_rounded
                                    : Icons.close_rounded,
                                size: 18,
                                color: m.shootOut[i].scored
                                    ? T.success
                                    : T.textOff,
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: T.s8),
              Text('matchday_shootout_us'.tr().toUpperCase(), style: T.label),
              const SizedBox(height: T.s4),
              Row(children: [
                Expanded(
                    child: TacticalButton(
                        label: 'matchday_goal'.tr(),
                        icon: Icons.sports_score_rounded,
                        onTap: () => add(true, true))),
                const SizedBox(width: T.s8),
                Expanded(
                    child: TacticalButton(
                        label: 'matchday_miss'.tr(),
                        icon: Icons.close_rounded,
                        quiet: true,
                        onTap: () => add(true, false))),
              ]),
              const SizedBox(height: T.s8),
              Text('matchday_shootout_them'.tr().toUpperCase(), style: T.label),
              const SizedBox(height: T.s4),
              Row(children: [
                Expanded(
                    child: TacticalButton(
                        label: 'matchday_goal'.tr(),
                        icon: Icons.sports_score_rounded,
                        onTap: () => add(false, true))),
                const SizedBox(width: T.s8),
                Expanded(
                    child: TacticalButton(
                        label: 'matchday_miss'.tr(),
                        icon: Icons.close_rounded,
                        quiet: true,
                        onTap: () => add(false, false))),
              ]),
              const SizedBox(height: T.s8),
              TacticalButton(
                label: 'matchday_shootout_undo'.tr(),
                icon: Icons.undo_rounded,
                quiet: true,
                onTap: m.shootOut.isEmpty
                    ? null
                    : () {
                        m.removeLastShootOutAttempt();
                        refresh(() {});
                        _save();
                      },
              ),
            ],
          ),
        );
      }),
    );
    if (mounted) setState(() {});
  }

  Future<void> _discard() async {
    final ok = await _confirm('matchday_discard_confirm'.tr(),
        action: 'matchday_discard'.tr(), danger: true);
    if (ok != true || !mounted) return;
    await MatchDayService.clearCurrent(widget.sport);
    if (!mounted) return;
    setState(() {
      _match = null;
      _selOut = null;
      _selIn = null;
    });
    _syncTick();
  }

  /// One question, one named answer: "End match", not "Apply".
  Future<bool?> _confirm(String title,
      {required String action, bool danger = false}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: T.surface,
        title: Text(title, style: T.dialogTitle),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action,
                style: TextStyle(color: danger ? T.danger : T.accent)),
          ),
        ],
      ),
    );
  }

  void _tapPitch(String id) {
    setState(() => _selOut = _selOut == id ? null : id);
    _trySwap();
  }

  void _tapBench(String id) {
    setState(() => _selIn = _selIn == id ? null : id);
    _trySwap();
  }

  Future<void> _trySwap() async {
    final m = _match;
    final out = _selOut, inn = _selIn;
    if (m == null || out == null || inn == null) return;
    var exhausted = false;
    setState(() {
      // In a match of sets a libero goes on and off free of the count,
      // and the six can be changed free until the set's first point.
      var kind = SubstitutionKind.sub;
      if (m.countsSets) {
        if (m.isLibero(out) || m.isLibero(inn)) {
          kind = SubstitutionKind.libero;
        } else if (m.scoreUs + m.scoreThem == 0) {
          kind = SubstitutionKind.lineup;
        }
      }
      final ok = m.substitute(out, inn, null, kind);
      exhausted = !ok && kind == SubstitutionKind.sub && m.subsLeft <= 0;
      _selOut = null;
      _selIn = null;
    });
    if (exhausted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('matchday_subs_exhausted'.tr())));
    }
    await _save();
  }

  Future<void> _suggest() async {
    final m = _match;
    if (m == null) return;
    final swaps = m.suggest();
    if (swaps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('matchday_suggest_none'.tr())));
      return;
    }
    final apply = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: T.surface,
        title: Text('matchday_suggest_title'.tr(), style: T.dialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final s in swaps)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${m.player(s.outId)?.label ?? ''} → '
                        '${m.player(s.inId)?.label ?? ''}',
                        style: const TextStyle(color: T.text, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: T.s8),
                    Text(mmss(s.gapSeconds), style: T.meta),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr())),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('matchday_apply'.tr(),
                  style: const TextStyle(color: T.accent))),
        ],
      ),
    );
    if (apply != true || !mounted) return;
    setState(() {
      for (final s in swaps) {
        m.substitute(s.outId, s.inId);
      }
      _selOut = null;
      _selIn = null;
    });
    await _save();
  }

  // ── Summary ────────────────────────────────────────────────────────────

  Future<void> _share(MatchDay m) async {
    try {
      await PdfExportService.exportMatchSheet(
        m,
        words: MatchSheetStrings(
          heading: 'matchday_title'.tr(),
          playingTime: 'matchday_playing_time'.tr(),
          substitutions: 'matchday_substitutions'.tr(),
          noSubs: 'matchday_no_subs'.tr(),
          player: 'matchday_player'.tr(),
          minutes: 'matchday_minutes'.tr(),
          time: 'matchday_time'.tr(),
          period: 'matchday_period'.tr(),
          off: 'matchday_off'.tr(),
          on: 'matchday_on'.tr(),
          starter: 'matchday_starter'.tr(),
          cards: 'matchday_cards'.tr(),
          card: 'matchday_card'.tr(),
          cardGreen: 'matchday_card_green'.tr(),
          cardYellow: 'matchday_card_yellow'.tr(),
          cardRed: 'matchday_card_red'.tr(),
          cardSuspension: 'matchday_card_suspension'.tr(),
          shootOut: 'matchday_shootout'.tr(),
          goal: 'matchday_goal'.tr(),
          miss: 'matchday_miss'.tr(),
          us: 'matchday_shootout_us'.tr(),
          them: 'matchday_shootout_them'.tr(),
          sets: 'matchday_sets'.tr(),
          set: 'matchday_set'.tr(),
          score: 'matchday_score'.tr(),
          subsIn: 'matchday_subs_in'.tr(),
          subsOut: 'matchday_subs_out'.tr(),
          libero: 'matchday_libero'.tr(),
          lineup: 'matchday_lineup'.tr(),
          timeouts: 'matchday_timeouts'.tr(),
          keeper: 'matchday_keeper'.tr(),
        ),
        filename: 'match_${m.startedAt.toIso8601String().split('T').first}.pdf',
      );
    } catch (e) {
      debugPrint('Match sheet export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('save_error'.tr())));
      }
    }
  }

  Future<void> _done() async {
    final m = _match;
    if (m == null) return;
    await MatchDayService.archive(widget.sport, m);
    final history = await MatchDayService.history(widget.sport);
    if (!mounted) return;
    setState(() {
      _match = null;
      _history = history;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final m = _match;
    final viewing = _viewing;
    final Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator(color: T.accent));
    } else if (viewing != null) {
      body = _summary(viewing, current: false);
    } else if (m == null) {
      body = _setup();
    } else if (m.isFinished) {
      body = _summary(m, current: true);
    } else {
      body = _running(m);
    }
    return Scaffold(
      backgroundColor: T.bg1,
      appBar: AppBar(
        backgroundColor: T.bg1,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: T.text, size: 22),
        leading: viewing != null
            ? IconButton(
                icon: const BackButtonIcon(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => setState(() => _viewing = null))
            : null,
        title: Text('matchday_title'.tr(), style: T.section),
        actions: [
          if (m != null && viewing == null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: T.danger),
              tooltip: 'matchday_discard'.tr(),
              onPressed: _discard,
            ),
        ],
      ),
      body: SafeArea(child: tabletColumn(context, body)),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(T.panelPad),
        decoration: BoxDecoration(color: T.surface, borderRadius: T.brMd),
        child: child,
      );

  Widget _setup() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(T.s16, T.s8, T.s16, T.s32),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: T.text),
                decoration: InputDecoration(
                  labelText: 'matchday_name'.tr(),
                  labelStyle: const TextStyle(color: T.textDim),
                  hintText: 'matchday_name_hint'.tr(),
                  hintStyle: const TextStyle(color: T.textOff),
                ),
              ),
              const SizedBox(height: T.s12),
              if (_setMode) ...[
                Text('matchday_rules'.tr(), style: T.body),
                const SizedBox(height: T.s8),
                Wrap(
                  spacing: T.s8,
                  runSpacing: T.s8,
                  children: [
                    for (final r in RotationRules.values)
                      TacticalChip(
                        label: r.label,
                        selected: _rules == r.name,
                        onTap: () => setState(() => _rules = r.name),
                      ),
                  ],
                ),
                const SizedBox(height: T.s12),
                Wrap(
                  spacing: T.s8,
                  runSpacing: T.s8,
                  children: [
                    for (final n in const [3, 5])
                      TacticalChip(
                        label: 'matchday_best_of'.tr(namedArgs: {'n': '$n'}),
                        selected: _bestOf == n,
                        onTap: () => setState(() => _bestOf = n),
                      ),
                  ],
                ),
                const SizedBox(height: T.s8),
              ] else ...[
                _Stepper(
                  label: 'matchday_periods'.tr(),
                  value: _periods,
                  min: 1,
                  max: 8,
                  onChanged: (v) => setState(() => _periods = v),
                ),
                _Stepper(
                  label: 'matchday_period_minutes'.tr(),
                  value: _minutes,
                  min: 1,
                  max: 90,
                  onChanged: (v) => setState(() => _minutes = v),
                ),
              ],
              _Stepper(
                label: 'matchday_on_pitch'.tr(),
                value: _onPitch,
                min: 1,
                max: 20,
                onChanged: (v) => setState(() {
                  _onPitch = v;
                  while (_starters.length > v) {
                    _starters.remove(_starters.last);
                  }
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: T.s16),
        // A Wrap, not a Row: on a narrow phone in a long-worded language
        // the button drops under the heading instead of running off it.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('matchday_roster'.tr().toUpperCase(), style: T.label),
            TextButton.icon(
              onPressed: _loadTeam,
              icon: const Icon(Icons.groups_outlined, size: 18, color: T.accent),
              label: Text('matchday_load_team'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: T.accent, fontSize: 13.5)),
            ),
          ],
        ),
        Text(
          'matchday_starters_count'.tr(namedArgs: {
            'n': '${_starters.length}',
            'total': '$_onPitch',
          }),
          style: T.caption,
        ),
        const SizedBox(height: T.s8),
        for (final p in _roster)
          _PlayerRow(
            label: p.label,
            selected: _starters.contains(p.id),
            leading: Icon(
              _starters.contains(p.id)
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              color: _starters.contains(p.id) ? T.accent : T.textOff,
              size: 22,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Volleyball marks its liberos, everyone else a keeper.
                if (_setMode)
                  _Tag(
                    label: 'matchday_libero_short'.tr(),
                    selected: _liberos.contains(p.id),
                    onTap: () => _toggleLibero(p),
                  )
                else
                  _Tag(
                    label: 'matchday_keeper'.tr(),
                    selected: _keepers.contains(p.id),
                    onTap: () => _toggleKeeper(p),
                  ),
                const SizedBox(width: T.s4),
                TacticalIconButton(
                  icon: Icons.close_rounded,
                  size: 18,
                  onTap: () => _removePlayer(p),
                ),
              ],
            ),
            onTap: () => _toggleStarter(p),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newCtrl,
                style: const TextStyle(color: T.text),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addPlayer(),
                decoration: InputDecoration(
                  hintText: 'matchday_add_player_hint'.tr(),
                  hintStyle: const TextStyle(color: T.textOff),
                ),
              ),
            ),
            const SizedBox(width: T.s8),
            TacticalIconButton(
                icon: Icons.add_circle_outline, onTap: _addPlayer),
          ],
        ),
        const SizedBox(height: T.s24),
        TacticalButton(
          label: 'matchday_start'.tr(),
          icon: _gated ? Icons.lock_outline : Icons.play_arrow_rounded,
          large: true,
          onTap: _canStart ? _startMatch : null,
        ),
        if (!_canStart) ...[
          const SizedBox(height: T.s8),
          Text(
            'matchday_need_players'.tr(namedArgs: {'n': '$_onPitch'}),
            textAlign: TextAlign.center,
            style: T.caption,
          ),
        ],
        if (_history.isNotEmpty) ...[
          const SizedBox(height: T.s32),
          Text('matchday_history'.tr().toUpperCase(), style: T.label),
          const SizedBox(height: T.s8),
          for (final h in _history)
            _PlayerRow(
              label: h.name.trim().isEmpty ? 'matchday_title'.tr() : h.name,
              value: h.startedAt.toIso8601String().split('T').first,
              onTap: () => setState(() => _viewing = h),
            ),
        ],
      ],
    );
  }

  /// The GK or libero mark beside a name, or nothing.
  Widget? _mark(MatchDay m, String id) {
    final p = m.player(id);
    if (p == null) return null;
    if (m.countsSets && m.isLibero(id)) {
      return _Tag(label: 'matchday_libero_short'.tr(), selected: true);
    }
    if (p.isKeeper) return _Tag(label: 'matchday_keeper'.tr(), selected: true);
    return null;
  }

  /// The set-piece boards the coach marked for the touchline.
  Widget _playbookButton() => TacticalButton(
        label: 'playbook_title'.tr(),
        icon: Icons.menu_book_outlined,
        quiet: true,
        onTap: () => showPlaybookSheet(context, widget.sport),
      );

  Widget _running(MatchDay m) {
    if (m.countsSets) return _runningSets(m);
    final times = m.playingTime();
    final pitch = m.onPitchIds;
    final bench = m.benchIds
      ..sort((a, b) => (times[a] ?? 0).compareTo(times[b] ?? 0));
    final clock = m.clock();
    final suspended = [
      for (final id in m.lineupIds)
        if (m.suspension(id, clock) != null) id
    ];
    final over = m.isPeriodOver();
    final last = m.period >= m.periods;
    final hasCards = widget.sport.matchDayCards.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(T.s16, T.s8, T.s16, T.s32),
      children: [
        _card(
          child: Column(
            children: [
              Text(
                'matchday_period_n'.tr(namedArgs: {
                  'n': '${m.period}',
                  'total': '${m.periods}',
                }),
                style: T.meta,
              ),
              Text(
                mmss(m.periodClock()),
                style: TextStyle(
                  color: over ? T.warning : T.accent,
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (over)
                Padding(
                  padding: const EdgeInsets.only(bottom: T.s8),
                  child: Text('matchday_period_over'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: T.warning,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: T.s8),
              Row(
                children: [
                  Expanded(
                    child: TacticalButton(
                      label: m.isRunning
                          ? 'matchday_clock_pause'.tr()
                          : 'matchday_clock_start'.tr(),
                      icon: m.isRunning ? Icons.pause : Icons.play_arrow_rounded,
                      onTap: over ? null : _toggleClock,
                    ),
                  ),
                  const SizedBox(width: T.s8),
                  Expanded(
                    child: TacticalButton(
                      label: last
                          ? 'matchday_end_match'.tr()
                          : 'matchday_next_period'.tr(),
                      icon: Icons.skip_next_rounded,
                      quiet: !over,
                      onTap: last ? _endMatch : _nextPeriod,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: T.s8),
              Row(
                children: [
                  Expanded(
                    child: TacticalButton(
                      label: 'matchday_suggest'.tr(),
                      icon: Icons.balance_outlined,
                      quiet: true,
                      onTap: _suggest,
                    ),
                  ),
                  const SizedBox(width: T.s8),
                  // Added time: the clock holds at the period's length
                  // until the coach says there is more to play.
                  Expanded(
                    child: TacticalButton(
                      label: 'matchday_add_minute'.tr(),
                      icon: Icons.more_time_rounded,
                      quiet: true,
                      onTap: _addTime,
                    ),
                  ),
                ],
              ),
              if (widget.sport.hasShootOut) ...[
                const SizedBox(height: T.s8),
                TacticalButton(
                  label: 'matchday_shootout'.tr(),
                  icon: Icons.sports_score_rounded,
                  quiet: true,
                  onTap: _shootOut,
                ),
              ],
              const SizedBox(height: T.s8),
              _playbookButton(),
            ],
          ),
        ),
        const SizedBox(height: T.s12),
        Text('matchday_swap_hint'.tr(), style: T.caption),
        const SizedBox(height: T.s16),
        Text('${'matchday_pitch'.tr().toUpperCase()}  ${pitch.length}',
            style: T.label),
        const SizedBox(height: T.s8),
        for (final id in pitch)
          _PlayerRow(
            label: m.player(id)?.label ?? id,
            value: mmss(times[id] ?? 0),
            selected: _selOut == id,
            leading: _mark(m, id),
            trailing: hasCards
                ? TacticalIconButton(
                    icon: Icons.style_outlined,
                    size: 18,
                    semanticLabel: 'matchday_card'.tr(),
                    onTap: () => _pickCard(id),
                  )
                : null,
            onTap: () => _tapPitch(id),
          ),
        if (suspended.isNotEmpty) ...[
          const SizedBox(height: T.s16),
          Text('${'matchday_suspended'.tr().toUpperCase()}  ${suspended.length}',
              style: T.label),
          const SizedBox(height: T.s8),
          for (final id in suspended)
            _PlayerRow(
              label: m.player(id)?.label ?? id,
              // A countdown to their return, or that there is none.
              value: m.suspension(id, clock)!.endClock == null
                  ? 'matchday_sent_off'.tr()
                  : mmss(m.suspension(id, clock)!.endClock! - clock),
              leading: Icon(Icons.style_rounded,
                  size: 18, color: _cardColor(m.suspension(id, clock)!.kind)),
            ),
        ],
        const SizedBox(height: T.s16),
        Text('${'matchday_bench'.tr().toUpperCase()}  ${bench.length}',
            style: T.label),
        const SizedBox(height: T.s8),
        for (final id in bench)
          _PlayerRow(
            label: m.player(id)?.label ?? id,
            value: mmss(times[id] ?? 0),
            selected: _selIn == id,
            leading: _mark(m, id),
            onTap: () => _tapBench(id),
          ),
      ],
    );
  }

  /// A match of sets: the score of the set, the substitutions against the
  /// rule set's limit, the timeouts — and no clock.
  Widget _runningSets(MatchDay m) {
    final pitch = m.onPitchIds;
    final bench = m.benchIds;
    final played = m.setsPlayed();
    final exhausted = m.subsLeft <= 0;
    final fresh = m.scoreUs + m.scoreThem == 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(T.s16, T.s8, T.s16, T.s32),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${'matchday_set_n'.tr(namedArgs: {
                      'n': '${m.period}',
                      'total': '${m.periods}',
                    })}  ·  ${'matchday_sets_won'.tr(namedArgs: {
                      'us': '${m.setsWonUs}',
                      'them': '${m.setsWonThem}',
                    })}',
                textAlign: TextAlign.center,
                style: T.meta,
              ),
              const SizedBox(height: T.s4),
              Text(
                '${m.scoreUs} : ${m.scoreThem}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: T.accent,
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              _Stepper(
                label: 'matchday_shootout_us'.tr(),
                value: m.scoreUs,
                min: 0,
                max: 999,
                onChanged: (v) => _point(us: true, delta: v - m.scoreUs),
              ),
              _Stepper(
                label: 'matchday_shootout_them'.tr(),
                value: m.scoreThem,
                min: 0,
                max: 999,
                onChanged: (v) => _point(us: false, delta: v - m.scoreThem),
              ),
              const SizedBox(height: T.s8),
              Wrap(
                spacing: T.s16,
                runSpacing: T.s4,
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    'matchday_subs_count'.tr(namedArgs: {
                      'n': '${m.subsInSet()}',
                      'limit': '${m.subLimit}',
                    }),
                    style: TextStyle(
                        color: exhausted ? T.warning : T.textDim,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'matchday_timeouts_count'.tr(namedArgs: {
                      'n': '${m.timeoutsUs}',
                      'limit': '${MatchDay.timeoutsPerSet}',
                    }),
                    style: const TextStyle(
                        color: T.textDim,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (exhausted)
                Padding(
                  padding: const EdgeInsets.only(top: T.s4),
                  child: Text('matchday_subs_exhausted'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: T.warning, fontSize: 13)),
                ),
              const SizedBox(height: T.s8),
              Row(
                children: [
                  Expanded(
                    child: TacticalButton(
                      label: 'matchday_timeout'.tr(),
                      icon: Icons.timer_outlined,
                      quiet: true,
                      onTap: m.timeoutsUs >= MatchDay.timeoutsPerSet
                          ? null
                          : () => _timeout(us: true),
                    ),
                  ),
                  const SizedBox(width: T.s8),
                  Expanded(
                    child: TacticalButton(
                      label: 'matchday_end_set'.tr(),
                      icon: Icons.skip_next_rounded,
                      onTap: _endSet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: T.s8),
              _playbookButton(),
              const SizedBox(height: T.s8),
              TacticalButton(
                label: 'matchday_end_match'.tr(),
                icon: Icons.flag_outlined,
                quiet: true,
                onTap: _endMatch,
              ),
            ],
          ),
        ),
        const SizedBox(height: T.s12),
        Text(fresh ? 'matchday_lineup_hint'.tr() : 'matchday_swap_hint'.tr(),
            style: T.caption),
        const SizedBox(height: T.s16),
        Text('${'matchday_on_court'.tr().toUpperCase()}  ${pitch.length}',
            style: T.label),
        const SizedBox(height: T.s8),
        for (final id in pitch)
          _PlayerRow(
            label: m.player(id)?.label ?? id,
            value: '${played[id] ?? 0}',
            selected: _selOut == id,
            leading: _mark(m, id),
            onTap: () => _tapPitch(id),
          ),
        const SizedBox(height: T.s16),
        Text('${'matchday_bench'.tr().toUpperCase()}  ${bench.length}',
            style: T.label),
        const SizedBox(height: T.s8),
        for (final id in bench)
          _PlayerRow(
            label: m.player(id)?.label ?? id,
            value: '${played[id] ?? 0}',
            selected: _selIn == id,
            leading: _mark(m, id),
            onTap: () => _tapBench(id),
          ),
      ],
    );
  }

  Widget _summary(MatchDay m, {required bool current}) {
    final times = m.playingTime(m.clock());
    final played = m.setsPlayed();
    final counts = m.subCounts();
    final order = [...m.players]
      ..sort((a, b) => m.countsSets
          ? (played[b.id] ?? 0).compareTo(played[a.id] ?? 0)
          : (times[b.id] ?? 0).compareTo(times[a.id] ?? 0));
    final starters = m.starters.toSet();
    final shoot = m.shootOutScore;
    String subKind(Substitution s) {
      switch (s.kind) {
        case SubstitutionKind.libero:
          return 'matchday_libero'.tr();
        case SubstitutionKind.lineup:
          return 'matchday_lineup'.tr();
        case SubstitutionKind.sub:
          return m.countsSets ? '' : mmss(s.clock);
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(T.s16, T.s8, T.s16, T.s32),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.name.trim().isEmpty ? 'matchday_finished'.tr() : m.name,
                  style: T.section),
              const SizedBox(height: T.s4),
              Text(
                m.countsSets
                    ? '${m.startedAt.toIso8601String().split('T').first}  ·  '
                        '${m.rules.toUpperCase()}  ·  '
                        '${'matchday_sets_won'.tr(namedArgs: {
                            'us': '${m.setsWonUs}',
                            'them': '${m.setsWonThem}',
                          })}'
                    : '${m.startedAt.toIso8601String().split('T').first}  ·  '
                        '${m.periods} × ${m.periodSeconds ~/ 60} min  ·  '
                        '${m.onPitch} v ${m.onPitch}',
                style: T.caption,
              ),
            ],
          ),
        ),
        if (m.countsSets) ...[
          const SizedBox(height: T.s16),
          Text('matchday_sets'.tr().toUpperCase(), style: T.label),
          const SizedBox(height: T.s8),
          for (var i = 0; i < m.setScores.length; i++)
            _PlayerRow(
              label: 'matchday_set_n'.tr(namedArgs: {
                'n': '${i + 1}',
                'total': '${m.periods}',
              }),
              value: '${m.setScores[i].us} : ${m.setScores[i].them}',
            ),
          const SizedBox(height: T.s16),
          Text(
              '${'matchday_sets_played'.tr().toUpperCase()}  ·  '
              '${'matchday_subs_in'.tr()} / ${'matchday_subs_out'.tr()}',
              style: T.label),
          const SizedBox(height: T.s8),
          for (final p in order)
            _PlayerRow(
              label: p.label,
              value: '${played[p.id] ?? 0}  ·  '
                  '${counts[p.id]?.inn ?? 0} / ${counts[p.id]?.out ?? 0}',
              leading: Icon(
                starters.contains(p.id)
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: starters.contains(p.id) ? T.accent : T.textOff,
                size: 18,
              ),
            ),
        ] else ...[
          const SizedBox(height: T.s16),
          Text('matchday_playing_time'.tr().toUpperCase(), style: T.label),
          const SizedBox(height: T.s8),
          for (final p in order)
            _PlayerRow(
              label: p.label,
              value: mmss(times[p.id] ?? 0),
              leading: Icon(
                starters.contains(p.id)
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: starters.contains(p.id) ? T.accent : T.textOff,
                size: 18,
              ),
            ),
        ],
        const SizedBox(height: T.s16),
        Text('matchday_substitutions'.tr().toUpperCase(), style: T.label),
        const SizedBox(height: T.s8),
        if (m.subs.isEmpty)
          Text('matchday_no_subs'.tr(), style: T.caption)
        else
          // Under the period they were made in, so each row is a pair and
          // a clock — the way the log is read back at half time.
          for (var i = 0; i < m.subs.length; i++) ...[
            if (i == 0 || m.subs[i].period != m.subs[i - 1].period)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : T.s8, bottom: T.s4),
                child: Text(
                  (m.countsSets ? 'matchday_set_n' : 'matchday_period_n')
                      .tr(namedArgs: {
                    'n': '${m.subs[i].period}',
                    'total': '${m.periods}',
                  }),
                  style: T.caption,
                ),
              ),
            _PlayerRow(
              label: '${m.player(m.subs[i].outId)?.label ?? m.subs[i].outId} → '
                  '${m.player(m.subs[i].inId)?.label ?? m.subs[i].inId}',
              value: subKind(m.subs[i]),
            ),
          ],
        if (m.cards.isNotEmpty) ...[
          const SizedBox(height: T.s16),
          Text('matchday_cards'.tr().toUpperCase(), style: T.label),
          const SizedBox(height: T.s8),
          for (final c in m.cards)
            _PlayerRow(
              label: '${m.player(c.playerId)?.label ?? c.playerId} · '
                  '${_cardText(c.kind, c.seconds)}',
              value: mmss(c.clock),
              leading:
                  Icon(Icons.style_rounded, size: 18, color: _cardColor(c.kind)),
            ),
        ],
        if (m.shootOut.isNotEmpty) ...[
          const SizedBox(height: T.s16),
          Text(
              '${'matchday_shootout'.tr().toUpperCase()}  '
              '${shoot.us} – ${shoot.them}',
              style: T.label),
          const SizedBox(height: T.s8),
          for (var i = 0; i < m.shootOut.length; i++)
            _PlayerRow(
              label: '${i + 1}.  ${_attemptLabel(m, m.shootOut[i])}',
              value: m.shootOut[i].scored
                  ? 'matchday_goal'.tr()
                  : 'matchday_miss'.tr(),
              leading: Icon(
                m.shootOut[i].scored
                    ? Icons.sports_score_rounded
                    : Icons.close_rounded,
                size: 18,
                color: m.shootOut[i].scored ? T.success : T.textOff,
              ),
            ),
        ],
        const SizedBox(height: T.s24),
        if (current && widget.sport.hasShootOut) ...[
          TacticalButton(
            label: 'matchday_shootout'.tr(),
            icon: Icons.sports_score_rounded,
            quiet: true,
            onTap: _shootOut,
          ),
          const SizedBox(height: T.s8),
        ],
        TacticalButton(
          label: 'matchday_share_pdf'.tr(),
          icon: Icons.ios_share,
          quiet: current,
          onTap: () => _share(m),
        ),
        if (current) ...[
          const SizedBox(height: T.s8),
          TacticalButton(
            label: 'matchday_done'.tr(),
            icon: Icons.check,
            large: true,
            onTap: _done,
          ),
        ],
      ],
    );
  }
}

/// A number with − and + beside it: periods, minutes, players.
class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              maxLines: 2, overflow: TextOverflow.ellipsis, style: T.body),
        ),
        TacticalIconButton(
          icon: Icons.remove_circle_outline,
          onTap: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: T.text,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()]),
          ),
        ),
        TacticalIconButton(
          icon: Icons.add_circle_outline,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

/// A two-letter mark beside a name — GK, L — that is a toggle in the
/// setup and a plain mark on the sheet.
class _Tag extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _Tag({required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      constraints: const BoxConstraints(minWidth: 28, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? T.accentFill : T.surfaceHi,
        borderRadius: T.brSm,
        border: Border.all(color: selected ? T.accent : T.border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            color: selected ? T.accent : T.textOff,
            fontSize: 11.5,
            fontWeight: FontWeight.w700),
      ),
    );
    if (onTap == null) return child;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(onTap: onTap, borderRadius: T.brSm, child: child),
    );
  }
}

/// One line of the sheet: a player and, on the right, their time.
class _PlayerRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool selected;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _PlayerRow({
    required this.label,
    this.value,
    this.selected = false,
    this.leading,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: T.s4),
      child: TacticalCard(
        selected: selected,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s8),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: T.s12)],
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: T.text, fontSize: 15.5)),
            ),
            if (value != null) ...[
              const SizedBox(width: T.s8),
              Text(value!,
                  style: const TextStyle(
                      color: T.textDim,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ],
            if (trailing != null) ...[const SizedBox(width: T.s4), trailing!],
          ],
        ),
      ),
    );
  }
}
