import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sport_type.dart';
import '../state/tactics_state.dart';
import '../ui/primitives.dart';
import '../ui/tokens.dart';
import 'tactics_canvas.dart';
import 'toolbar.dart' show scaledSheet;

/// The match-day playbook: the saved boards a coach marked for the touchline
/// (TacticMeta.playbook), as a grid of pictures. Tapping one opens
/// [PlaybookPlayPage], where the board plays and the next one is a swipe
/// away. Offered wherever the match-day sheet is (SportType.hasMatchDay).
Future<void> showPlaybookSheet(BuildContext context, SportType sport) {
  return TacticalSheet.show<void>(
    context,
    builder: (ctx) => scaledSheet(ctx, PlaybookSheet(sport: sport)),
  );
}

/// One board of the playbook: its name and its file, read once.
class PlaybookBoard {
  final String name;
  final Map<String, dynamic> json;
  const PlaybookBoard(this.name, this.json);
}

class PlaybookSheet extends StatefulWidget {
  final SportType sport;
  const PlaybookSheet({super.key, required this.sport});

  @override
  State<PlaybookSheet> createState() => _PlaybookSheetState();
}

class _PlaybookSheetState extends State<PlaybookSheet> {
  /// Reads the sport's files; never shown on a canvas.
  late final TacticsState _store =
      TacticsState(sportType: widget.sport, preview: true);
  List<PlaybookBoard>? _boards;
  final List<TacticsState> _previews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final metas = await _store.listSavedTacticMetas();
    final boards = <PlaybookBoard>[];
    for (final m in metas) {
      if (!m.playbook) continue;
      final json = await _store.readTacticJson(m.name);
      if (json != null) boards.add(PlaybookBoard(m.name, json));
    }
    if (!mounted) return;
    setState(() {
      _boards = boards;
      for (final b in boards) {
        _previews.add(TacticsState(sportType: widget.sport, preview: true)
          ..loadFromJson(Map<String, dynamic>.from(b.json)));
      }
    });
  }

  @override
  void dispose() {
    for (final p in _previews) {
      p.dispose();
    }
    _store.dispose();
    super.dispose();
  }

  void _open(int index) {
    final boards = _boards!;
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PlaybookPlayPage(
          sport: widget.sport, boards: boards, initialIndex: index),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final boards = _boards;
    return TacticalSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TacticalSheetHeader(
            title: 'playbook_title'.tr(),
            onClose: () => Navigator.of(context).pop(),
          ),
          if (boards == null)
            const Padding(
              padding: EdgeInsets.all(T.s24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (boards.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: T.s8),
              child: Text('playbook_empty'.tr(), style: T.body),
            )
          else
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: T.s12,
                  crossAxisSpacing: T.s12,
                  childAspectRatio: 0.72,
                ),
                itemCount: boards.length,
                itemBuilder: (context, i) => _PlaybookCard(
                  name: boards[i].name,
                  preview: _previews[i],
                  onTap: () => _open(i),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A board's picture with its name under it.
class _PlaybookCard extends StatelessWidget {
  final String name;
  final TacticsState preview;
  final VoidCallback onTap;
  const _PlaybookCard(
      {required this.name, required this.preview, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: T.surfaceHi, borderRadius: T.brMd),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(T.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: T.brSm,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: kBoardRefWidth,
                    height: kBoardRefHeight,
                    child: ChangeNotifierProvider<TacticsState>.value(
                      value: preview,
                      child: const IgnorePointer(
                          child: TacticsCanvas(preview: true)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: T.s8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: T.text, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// One playbook board full screen, read-only: play runs its timeline, a
/// swipe goes to the next or previous board of the playbook.
class PlaybookPlayPage extends StatefulWidget {
  final SportType sport;
  final List<PlaybookBoard> boards;
  final int initialIndex;
  const PlaybookPlayPage(
      {super.key,
      required this.sport,
      required this.boards,
      this.initialIndex = 0});

  @override
  State<PlaybookPlayPage> createState() => _PlaybookPlayPageState();
}

class _PlaybookPlayPageState extends State<PlaybookPlayPage> {
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);
  late final List<TacticsState> _states = [
    for (final b in widget.boards)
      TacticsState(sportType: widget.sport, preview: true)
        ..loadFromJson(Map<String, dynamic>.from(b.json)),
  ];
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    for (final s in _states) {
      s.dispose();
    }
    super.dispose();
  }

  void _onPage(int i) {
    // The board swiped away stops where it is; the one arriving starts
    // from its setup when play is pressed.
    final old = _states[_index];
    if (old.isAnimating) old.stopAnimation();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.boards[_index].name;
    return Scaffold(
      backgroundColor: T.bg0,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(T.s8, T.s8, T.s16, 0),
              child: Row(
                children: [
                  TacticalIconButton(
                    icon: Icons.arrow_back_rounded,
                    size: T.iLg,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: T.s8),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: T.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: T.s8),
                  Text('${_index + 1} / ${widget.boards.length}',
                      style: T.meta),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                onPageChanged: _onPage,
                itemCount: _states.length,
                itemBuilder: (context, i) => _PlayBoard(state: _states[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The board, fitted to its page, with one play button under it.
class _PlayBoard extends StatelessWidget {
  final TacticsState state;
  const _PlayBoard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(T.s16, T.s8, T.s16, T.s16),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              // Drawn sideways when the space is, as the run page does.
              final sideways = c.maxWidth > c.maxHeight;
              final board = SizedBox(
                width: kBoardRefWidth,
                height: kBoardRefHeight,
                child: IgnorePointer(
                  child: ChangeNotifierProvider<TacticsState>.value(
                    value: state,
                    child: TacticsCanvas(
                        preview: true, boardTurns: sideways ? 1 : 0),
                  ),
                ),
              );
              return Center(
                child: ClipRRect(
                  borderRadius: T.brLg,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: sideways
                        ? RotatedBox(quarterTurns: 1, child: board)
                        : board,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: T.s12),
          ListenableBuilder(
            listenable: state,
            builder: (context, _) => TacticalButton(
              label: 'playbook_play'.tr(),
              icon: Icons.play_arrow_rounded,
              onTap: state.hasMoves && !state.isAnimating
                  ? state.startAnimation
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
