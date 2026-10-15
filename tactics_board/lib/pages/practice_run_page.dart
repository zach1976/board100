import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../ui/adaptive.dart';
import '../ui/tokens.dart';
import '../widgets/tactics_canvas.dart';
import 'package:flutter/services.dart';
import '../models/practice.dart';
import '../models/practice_session.dart';
import '../services/ad_service.dart';
import '../services/practice_history_service.dart';
import '../services/review_service.dart';
import '../widgets/attendance_sheet.dart';
import '../services/photo_library_service.dart';
import '../state/tactics_state.dart';
import 'home_page.dart' show TacticsBoardHomePage;

Color get _kBg => T.bg1;
Color get _kCard => T.surface;
Color get _kAccent => T.accent;

class PracticeRunPage extends StatefulWidget {
  final TacticsState state;
  final Practice practice;
  final int initialIndex;
  const PracticeRunPage({
    super.key,
    required this.state,
    required this.practice,
    this.initialIndex = 0,
  });

  @override
  State<PracticeRunPage> createState() => _PracticeRunPageState();
}

class _PracticeRunPageState extends State<PracticeRunPage> {
  int _idx = 0;
  int _secLeft = 0;
  bool _running = false;
  Timer? _timer;

  late final DateTime _startedAt;
  int _itemsCompleted = 0;
  int _totalSecondsSpent = 0;
  bool _sessionRecorded = false;
  PracticeSession? _recorded;

  /// The current item's board, drawn on a tablet in the space a phone
  /// leaves empty above the timer. Its own throwaway state, as the drill
  /// page's is: the coach's live board is not touched until "Open on
  /// board". Null until read, and for a board whose file is gone.
  TacticsState? _preview;
  String? _previewOf;

  @override
  void initState() {
    super.initState();
    AdService.instance.pushAdSuppression(); // live practice run stays ad-free
    _idx = widget.initialIndex.clamp(0, widget.practice.items.length - 1);
    // Not cleared here any more: the board clears it before it pops back to
    // this page, and notifying listeners from initState would rebuild the
    // board's back button in the middle of this build.
    _startedAt = DateTime.now();
    _resetItem();
  }

  /// Reads the current item's saved board into [_preview]. Straight from
  /// its file rather than through TacticsState.loadTactics, which would
  /// also log it as a board the coach opened.
  Future<void> _loadPreview() async {
    final name = _current?.tacticName;
    if (name == null || name == _previewOf) return;
    _previewOf = name;
    Map<String, dynamic>? json;
    try {
      // Where TacticsState keeps them, with its same fallback.
      Directory docs;
      try {
        docs = await getApplicationDocumentsDirectory();
      } catch (_) {
        docs = Directory.systemTemp;
      }
      final f = File(
          '${docs.path}/tactics/${widget.state.sportType.name}/$name.json');
      if (await f.exists()) {
        json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      }
    } catch (_) {
      // An unreadable file: no picture, and the run page is still a timer.
    }
    if (!mounted || _previewOf != name) return;
    final old = _preview;
    setState(() {
      _preview = json == null
          ? null
          : (TacticsState(sportType: widget.state.sportType, preview: true)
            ..loadFromJson(json));
    });
    old?.dispose();
  }

  @override
  void dispose() {
    _preview?.dispose();
    _timer?.cancel();
    AdService.instance.popAdSuppression();
    _recordSession(completed: false);
    super.dispose();
  }

  Future<void> _recordSession({required bool completed}) async {
    if (_sessionRecorded) return;
    if (_itemsCompleted == 0 && _totalSecondsSpent < 10) return;
    _sessionRecorded = true;
    final session = PracticeSession(
      planName: widget.practice.name,
      startedAt: _startedAt,
      completedAt: DateTime.now(),
      itemsCompleted: _itemsCompleted,
      plannedItems: widget.practice.items.length,
      totalSecondsSpent: _totalSecondsSpent,
      completed: completed,
    );
    try {
      await PracticeHistoryService.add(widget.state.sportType, session);
      _recorded = session;
    } catch (_) {}
  }

  /// Ask who was here, right after the session ends — the only moment the
  /// coach still remembers and still has the phone out. Skipping is fine:
  /// the log is worth more half-filled than abandoned.
  Future<void> _askAttendance() async {
    final session = _recorded;
    if (session == null) return;
    final groups = await PhotoLibraryService.instance.listGroups();
    if (groups.isEmpty || !mounted) return;
    final squad = await PhotoLibraryService.instance.squad(groups.first.id);
    if (squad.isEmpty || !mounted) return;

    final present = await AttendanceSheet.show(
      context,
      squad: squad,
      squadId: groups.first.id,
    );
    if (present == null) return; // skipped
    try {
      await PracticeHistoryService.replace(
        widget.state.sportType,
        session,
        session.withAttendance(present, groups.first.id),
      );
    } catch (_) {}
  }

  PracticeItem? get _current =>
      _idx < widget.practice.items.length ? widget.practice.items[_idx] : null;

  Future<void> _playFinishCue() async {
    HapticFeedback.heavyImpact();
    for (var i = 0; i < 3; i++) {
      SystemSound.play(SystemSoundType.click);
      await Future.delayed(const Duration(milliseconds: 160));
      HapticFeedback.mediumImpact();
    }
  }

  void _resetItem() {
    final it = _current;
    setState(() {
      _secLeft = (it?.durationMinutes ?? 0) * 60;
      _running = false;
    });
    _timer?.cancel();
    _loadPreview();
  }

  void _togglePlay() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      if (_secLeft <= 0) return;
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        _totalSecondsSpent += 1;
        if (_secLeft <= 1) {
          _timer?.cancel();
          _playFinishCue();
          _itemsCompleted += 1;
          setState(() {
            _secLeft = 0;
            _running = false;
          });
          _onItemFinished();
        } else {
          setState(() => _secLeft -= 1);
        }
      });
    }
  }

  void _onItemFinished() {
    if (_idx + 1 >= widget.practice.items.length) {
      _showCompleteDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('practice_item_done'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
      _next();
    }
  }

  void _prev() {
    if (_idx <= 0) return;
    setState(() => _idx -= 1);
    _resetItem();
  }

  void _next() {
    if (_idx + 1 >= widget.practice.items.length) return;
    setState(() => _idx += 1);
    _resetItem();
  }

  Future<void> _openOnBoard() async {
    final it = _current;
    if (it == null) return;
    _timer?.cancel();
    widget.state.runningPlanName = widget.practice.name;
    widget.state.runningItemIndex = _idx;
    widget.state.editingFromPlan = null;
    await widget.state.loadTactics(it.tacticName);
    if (!mounted) return;
    // On top of this page, not instead of it. It used to popUntil the first
    // route — which stopped being the board when the sport's home page went
    // in front of it — so "open on board" landed on the home page, and the
    // board's Back then had to rebuild a run page to return to.
    if (widget.state.hasMoves) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.state.startAnimation();
      });
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TacticsBoardHomePage()),
    );
    widget.state.runningPlanName = null;
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _showCompleteDialog() async {
    await _recordSession(completed: true);
    unawaited(ReviewService.instance.onPositiveMoment('practice'));
    if (!mounted) return;
    await _askAttendance();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        title: Text('practice_complete_title'.tr(),
            style: const TextStyle(color: T.text)),
        content: Text(widget.practice.name,
            style: const TextStyle(color: T.textDim)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('confirm'.tr(),
                style: TextStyle(color: _kAccent)),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  String _mmss(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.practice.items;
    final it = _current;
    if (items.isEmpty || it == null) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kCard,
          iconTheme: const IconThemeData(color: T.text),
          title: Text(widget.practice.name,
              style: const TextStyle(color: T.text)),
        ),
        body: Center(
          child: Text('plan_no_items'.tr(),
              style: const TextStyle(color: T.textDim)),
        ),
      );
    }
    final total = items.length;
    final counter = Text('${_idx + 1} / $total',
                  style: const TextStyle(color: T.textDim, fontSize: 16));
    final card = Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.tacticName,
                        style: const TextStyle(
                            color: T.text,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    if (it.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(it.note,
                          style: const TextStyle(
                              color: T.textDim, fontSize: 14)),
                    ],
                  ],
                ),
              );
    final timer = Text(
                _mmss(_secLeft),
                style: TextStyle(
                  color: _secLeft == 0 ? T.danger : _kAccent,
                  fontSize: 84,
                  fontWeight: FontWeight.w300,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              );
    final controls = Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RoundBtn(
                    icon: Icons.chevron_left_rounded,
                    enabled: _idx > 0,
                    onTap: _prev,
                  ),
                  _RoundBtn(
                    icon: _running ? Icons.pause : Icons.play_arrow_rounded,
                    size: 72,
                    enabled: _secLeft > 0,
                    primary: true,
                    onTap: _togglePlay,
                  ),
                  _RoundBtn(
                    icon: Icons.chevron_right_rounded,
                    enabled: _idx + 1 < total,
                    onTap: _next,
                  ),
                ],
              );
    final buttons = Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetItem,
                      icon: const Icon(Icons.refresh, color: T.textDim),
                      label: Text('timeline_reset'.tr(),
                          style: const TextStyle(color: T.textDim)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: T.textOff),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _openOnBoard,
                      icon: const Icon(Icons.open_in_full),
                      label: Text('practice_open_board'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              );
    return Scaffold(
      backgroundColor: _kBg,
      // Third of the three practice screens, and the last one still on a
      // raised bar with a centred title.
      appBar: AppBar(
        backgroundColor: T.bg1,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: T.text, size: 22),
        title: Text(widget.practice.name, style: T.section),
      ),
      body: isTabletLayout(context)
          ? SafeArea(
              child: _tabletBody(counter, card, timer, controls, buttons))
          : SafeArea(
        // Fill the screen when it fits, scroll when it does not. The timer is
        // 84pt and the two button rows are fixed, so on a 320x568 phone — or
        // any phone once the drill note runs to several lines — this column
        // was 158 to 194 pixels taller than the space it had. IntrinsicHeight
        // keeps the Spacer working in the case that does fit.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              counter,
              const SizedBox(height: 8),
              card,
              const Spacer(),
              timer,
              const SizedBox(height: 24),
              controls,
              const SizedBox(height: 20),
              buttons,
              const SizedBox(height: 8),
            ],
          ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A tablet's run page: the board the coach is about to run where a
  /// phone has empty space, and the controls kept to a column a hand can
  /// cross. Upright, the board sits between the drill and the timer;
  /// sideways, it takes the left and the controls stand down the right.
  /// The phone layout stretched across an iPad put 700pt of nothing above
  /// a timer, with the prev and next arrows 480pt apart.
  Widget _tabletBody(Widget counter, Widget card, Widget timer,
      Widget controls, Widget buttons) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final panel = <Widget>[
      timer,
      const SizedBox(height: 24),
      controls,
      const SizedBox(height: 20),
      buttons,
      const SizedBox(height: 8),
    ];
    if (landscape) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(child: _boardPreview()),
            const SizedBox(width: 32),
            SizedBox(
              width: 420,
              child: Column(
                children: [
                  counter,
                  const SizedBox(height: 8),
                  card,
                  const Spacer(),
                  ...panel,
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kFormMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              counter,
              const SizedBox(height: 8),
              card,
              const SizedBox(height: 20),
              Expanded(child: _boardPreview()),
              const SizedBox(height: 20),
              ...panel,
            ],
          ),
        ),
      ),
    );
  }

  /// The current item's board, read-only, fitted to the space it is given.
  /// A tap plays its moves, the way a coach would show them to the group.
  Widget _boardPreview() {
    final preview = _preview;
    if (preview == null) return const SizedBox.expand();
    return LayoutBuilder(builder: (context, c) {
      // Drawn sideways when the space is, as the drill page does.
      final sideways = c.maxWidth > c.maxHeight;
      final board = SizedBox(
        width: kBoardRefWidth,
        height: kBoardRefHeight,
        child: IgnorePointer(
          child: ChangeNotifierProvider<TacticsState>.value(
            value: preview,
            child: TacticsCanvas(preview: true, boardTurns: sideways ? 1 : 0),
          ),
        ),
      );
      return GestureDetector(
        key: const ValueKey('run-board-preview'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (preview.hasMoves && !preview.isAnimating) {
            preview.startAnimation();
          }
        },
        child: Center(
          child: ClipRRect(
            borderRadius: T.brLg,
            child: FittedBox(
              fit: BoxFit.contain,
              child: sideways ? RotatedBox(quarterTurns: 1, child: board) : board,
            ),
          ),
        ),
      );
    });
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool primary;
  final bool enabled;
  const _RoundBtn({
    required this.icon,
    required this.onTap,
    this.size = 56,
    this.primary = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? _kAccent : _kCard;
    final fg = primary ? Colors.black : T.text;
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: fg, size: size * 0.5),
        ),
      ),
    );
  }
}
