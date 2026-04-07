import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/player_icon.dart';
import '../models/drawing_stroke.dart';
import '../models/sport_formation.dart';
import '../models/sport_type.dart';
import '../painters/ball_painter.dart';
import '../state/tactics_state.dart';
import 'player_icon_widget.dart';
import 'timeline_editor.dart';

/// Public function to show save/load bottom sheet
void showSaveLoadSheet(BuildContext context, TacticsState state) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF213E48),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _SaveLoadSheet(state: state),
  );
}

/// Public function to share the board
Future<void> shareBoardImage(BuildContext context, TacticsState state) async {
  state.resetZoom();
  await Future.delayed(const Duration(milliseconds: 200));
  final boundary = boardRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('save_error'.tr())));
    return;
  }
  try {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    Directory dir;
    try { dir = await getTemporaryDirectory(); } catch (_) { dir = Directory.systemTemp; }
    final file = File('${dir.path}/tactics_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes.buffer.asUint8List());
    if (context.mounted) {
      try {
        const channel = MethodChannel('com.zach.tacticsboard/share');
        await channel.invokeMethod('shareFile', {'path': file.path});
      } catch (_) {
        await Share.shareXFiles([XFile(file.path)]);
      }
    }
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('save_error'.tr())));
  }
}

/// Public function to confirm clear all
void confirmClearAll(BuildContext context, TacticsState state) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF213E48),
      title: Text('clear_board_title'.tr(), style: const TextStyle(color: Colors.white)),
      content: Text('clear_board_message'.tr(), style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr())),
        TextButton(onPressed: () { Navigator.pop(ctx); state.clearAll(); }, child: Text('clear'.tr(), style: const TextStyle(color: Colors.red))),
      ],
    ),
  );
}

/// Public function to show the add element bottom sheet
void showAddElementSheet(BuildContext context, TacticsState state) {
  final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF213E48),
    isScrollControlled: isLandscape,
    constraints: isLandscape ? BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9) : null,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AddPlayerSheet(state: state, sheetCtx: ctx),
  );
}

class TacticsToolbar extends StatelessWidget {
  const TacticsToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    // Subscribe to locale so toolbar rebuilds on language change
    final _ = EasyLocalization.of(context)?.currentLocale;
    return Consumer<TacticsState>(
      builder: (context, state, _) {
        return Container(
          color: const Color(0xFF213E48),
          child: _MainRow(state: state),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Row — always visible, single row
// ─────────────────────────────────────────────────────────────────────────────

class _MainRow extends StatelessWidget {
  final TacticsState state;
  const _MainRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasMoves = state.hasMoves;
    final hasContent = state.players.isNotEmpty || state.strokes.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row: Mode + Add + Clear + Save + Share
          Row(
            children: [
              _ModeSegment(state: state),
              const SizedBox(width: 6),
              _AddPlayerBtn(state: state),
              const SizedBox(width: 6),
              if (hasContent)
                _IconBtn(icon: Icons.delete_sweep, onTap: () => _confirmClear(context, state), color: Colors.redAccent),
              const Spacer(),
              _IconBtn(icon: Icons.save_outlined, onTap: () => _showSaveLoad(context), color: const Color(0xFF00E5CC)),
              _IconBtn(icon: Icons.ios_share, onTap: () => _shareBoard(context), color: Colors.tealAccent),
            ],
          ),
        ],
      ),
    );
  }

  void _showSaveLoad(BuildContext context) {
    showSaveLoadSheet(context, state);
  }


  Future<void> _shareBoard(BuildContext context) async {
    // Reset zoom so capture gets full unzoomed canvas
    state.resetZoom();
    await Future.delayed(const Duration(milliseconds: 200));

    final boundary =
        boardRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      debugPrint('Share: RepaintBoundary not found');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('save_error'.tr())),
        );
      }
      return;
    }
    try {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      Directory dir;
      try {
        dir = await getTemporaryDirectory();
      } catch (_) {
        dir = Directory.systemTemp;
      }
      final file = File('${dir.path}/tactics_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      // Use native MethodChannel for reliable sharing on iOS
      try {
        const channel = MethodChannel('com.zach.tacticsboard/share');
        await channel.invokeMethod('shareFile', {'path': file.path});
      } catch (e) {
        debugPrint('Native share failed: $e, trying share_plus');
        try {
          await Share.shareXFiles([XFile(file.path)], subject: 'Tactics Board');
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('save_success'.tr()), backgroundColor: Colors.green),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Share error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('save_error'.tr())),
        );
      }
    }
  }

  void _confirmClear(BuildContext context, TacticsState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF213E48),
        title: Text('clear_board_title'.tr(), style: const TextStyle(color: Colors.white)),
        content: Text('clear_board_message'.tr(), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              state.clearAll();
              Navigator.pop(ctx);
            },
            child: Text('clear'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Save / Load tactics sheet
// ─────────────────────────────────────────────────────────────────────────────
class _SaveLoadSheet extends StatefulWidget {
  final TacticsState state;
  const _SaveLoadSheet({required this.state});

  @override
  State<_SaveLoadSheet> createState() => _SaveLoadSheetState();
}

class _SaveLoadSheetState extends State<_SaveLoadSheet> {
  final _nameCtrl = TextEditingController();
  List<String> _saved = [];

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    final list = await widget.state.listSavedTactics();
    if (mounted) setState(() => _saved = list);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.save_outlined, color: const Color(0xFF00E5CC), size: 20),
                const SizedBox(width: 8),
                Text('save'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
          ),
          // Save new
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'tactics_name'.tr(),
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    final name = _nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('tactics_name'.tr())),
                      );
                      return;
                    }
                    try {
                      await widget.state.saveTactics(name);
                      _nameCtrl.clear();
                      await _loadList();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${'save_success'.tr()}: $name')),
                        );
                      }
                    } catch (e) {
                      debugPrint('Save error: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Save failed: $e')),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                    child: Text('save'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
          // Saved list
          if (_saved.isNotEmpty) ...[
            const Divider(color: Colors.white12),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text('load'.tr(), style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _saved.length,
                itemBuilder: (ctx, i) {
                  final name = _saved[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.description, color: Colors.white38, size: 20),
                    title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await widget.state.loadTactics(name);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                            child: Text('load'.tr(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            await widget.state.deleteTactics(name);
                            await _loadList();
                          },
                          child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mode Segment — compact pill with 移动 / 画线
// ─────────────────────────────────────────────────────────────────────────────

class _ModeSegment extends StatelessWidget {
  final TacticsState state;
  const _ModeSegment({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegTab(
            icon: Icons.open_with,
            label: 'mode_move'.tr(),
            selected: !state.isDrawingMode,
            onTap: state.isAnimating ? null : () => state.setDrawingMode(false),
          ),
          _SegTab(
            icon: Icons.edit,
            label: 'mode_draw'.tr(),
            selected: state.isDrawingMode,
            onTap: state.isAnimating ? null : () => state.setDrawingMode(true),
          ),
        ],
      ),
    );
  }
}

class _SegTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _SegTab({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1.0,
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 15),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Player Button — opens bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddPlayerBtn extends StatelessWidget {
  final TacticsState state;
  const _AddPlayerBtn({required this.state});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 15),
            const SizedBox(width: 4),
            Text('add_label'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showAddSheet(context, state);
  }

  static void showAddSheet(BuildContext context, TacticsState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF213E48),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddPlayerSheet(state: state, sheetCtx: ctx),
    );
  }
}

class _AddPlayerSheet extends StatefulWidget {
  final TacticsState state;
  final BuildContext sheetCtx;
  const _AddPlayerSheet({required this.state, required this.sheetCtx});

  @override
  State<_AddPlayerSheet> createState() => _AddPlayerSheetState();
}

class _AddPlayerSheetState extends State<_AddPlayerSheet> {
  bool _showMore = false;
  final _scrollController = ScrollController();
  final _moreKey = GlobalKey();
  TacticsState get state => widget.state;
  BuildContext get sheetCtx => widget.sheetCtx;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addMarker(MarkerShape shape, Color color, {String label = ''}) {
    final c = state.canvasSize;
    state.addPlayer(PlayerIcon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: label,
      team: PlayerTeam.neutral,
      markerShape: shape,
      customColor: color,
      position: Offset(c.width * 0.5, state.spawnY(PlayerTeam.neutral)),
    ));
    Navigator.pop(sheetCtx);
  }

  @override
  Widget build(BuildContext context) {
    final isTeamSport = !state.sportType.hasDoubles;
    return SafeArea(
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'add_label'.tr(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
            if (isTeamSport) ...[
              _TeamSportSetup(state: state, sheetCtx: sheetCtx),
            ] else ...[
              _QuickFormationRow(state: state, sheetCtx: sheetCtx),
              const Divider(color: Colors.white12),
              _SectionHeader(label: 'team_home'.tr(), color: const Color(0xFF1565C0)),
              _PlayerAddRow(state: state, team: PlayerTeam.home, sheetCtx: sheetCtx),
              const SizedBox(height: 4),
              _SectionHeader(label: 'team_away'.tr(), color: const Color(0xFFC62828)),
              _PlayerAddRow(state: state, team: PlayerTeam.away, sheetCtx: sheetCtx),
            ],
            // Ball + basic shapes + More button inline
            const Divider(color: Colors.white12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _MarkerCard(
                      label: 'team_ball'.tr(),
                      child: ClipOval(
                        child: SizedBox(
                          width: 28, height: 28,
                          child: CustomPaint(painter: BallPainter.forSport(state.sportType)),
                        ),
                      ),
                      onTap: () {
                        final c = state.canvasSize;
                        state.addPlayer(PlayerIcon(
                          id: DateTime.now().microsecondsSinceEpoch.toString(),
                          label: '',
                          team: PlayerTeam.neutral,
                          sportType: state.sportType,
                          position: Offset(c.width * 0.5, state.spawnY(PlayerTeam.neutral)),
                        ));
                        Navigator.pop(sheetCtx);
                      },
                    ),
                    const SizedBox(width: 8),
                    ...[
                      (MarkerShape.circle, '○', Colors.amber),
                      (MarkerShape.square, '□', Colors.teal),
                      (MarkerShape.triangle, '△', Colors.orange),
                      (MarkerShape.diamond, '◇', Colors.purple),
                    ].map((e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _MarkerCard(
                        label: e.$2,
                        child: SizedBox(width: 28, height: 28, child: CustomPaint(painter: MarkerPainter(shape: e.$1, color: e.$3))),
                        onTap: () => _addMarker(e.$1, e.$3),
                      ),
                    )),
                    // "More" button inline
                    GestureDetector(
                      onTap: () {
                        setState(() => _showMore = !_showMore);
                        if (_showMore) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          });
                        }
                      },
                      child: Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: _showMore ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_showMore ? Icons.expand_less : Icons.more_horiz, color: Colors.white54, size: 18),
                            Text(_showMore ? 'less'.tr() : 'more'.tr(),
                                style: const TextStyle(color: Colors.white54, fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Expanded more items
            if (_showMore)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _MarkerCard(label: 'marker_cone'.tr(), child: SizedBox(width: 28, height: 28, child: CustomPaint(painter: MarkerPainter(shape: MarkerShape.cone, color: Colors.orange))), onTap: () => _addMarker(MarkerShape.cone, Colors.orange)),
                      const SizedBox(width: 8),
                      _MarkerCard(label: 'marker_text'.tr(), child: SizedBox(width: 28, height: 28, child: CustomPaint(painter: MarkerPainter(shape: MarkerShape.text, color: Colors.blueGrey))), onTap: () => _addMarker(MarkerShape.text, Colors.blueGrey, label: 'T')),
                      const SizedBox(width: 8),
                      _MarkerCard(label: 'marker_zone'.tr(), child: SizedBox(width: 28, height: 28, child: CustomPaint(painter: MarkerPainter(shape: MarkerShape.zone, color: Colors.yellow))), onTap: () => _addMarker(MarkerShape.zone, Colors.yellow)),
                      const SizedBox(width: 8),
                      _MarkerCard(label: 'marker_referee'.tr(), child: SizedBox(width: 28, height: 28, child: CustomPaint(painter: MarkerPainter(shape: MarkerShape.referee, color: Colors.black))), onTap: () => _addMarker(MarkerShape.referee, Colors.black)),
                      const SizedBox(width: 8),
                      _MarkerCard(label: 'marker_coach'.tr(), child: SizedBox(width: 28, height: 28, child: CustomPaint(painter: MarkerPainter(shape: MarkerShape.coach, color: const Color(0xFF37474F)))), onTap: () => _addMarker(MarkerShape.coach, const Color(0xFF37474F))),
                      const SizedBox(width: 8),
                      _MarkerCard(label: 'marker_ladder'.tr(), child: SizedBox(width: 28, height: 28, child: CustomPaint(painter: MarkerPainter(shape: MarkerShape.ladder, color: Colors.lime))), onTap: () => _addMarker(MarkerShape.ladder, Colors.lime)),
                      const SizedBox(width: 8),
                      _MarkerCard(label: 'marker_hurdle'.tr(), child: SizedBox(width: 28, height: 28, child: CustomPaint(painter: MarkerPainter(shape: MarkerShape.hurdle, color: Colors.red))), onTap: () => _addMarker(MarkerShape.hurdle, Colors.red)),
                      const SizedBox(width: 8),
                      _MarkerCard(label: 'marker_arrow'.tr(), child: SizedBox(width: 28, height: 28, child: CustomPaint(painter: MarkerPainter(shape: MarkerShape.arrowMark, color: Colors.green))), onTap: () => _addMarker(MarkerShape.arrowMark, Colors.green)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header for add-player sheet
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Row of add buttons: 男, 女, 男双, 女双, 混双
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerAddRow extends StatelessWidget {
  final TacticsState state;
  final PlayerTeam team;
  final BuildContext sheetCtx;
  const _PlayerAddRow({required this.state, required this.team, required this.sheetCtx});

  int get _nextNum {
    int max = 0;
    for (final p in state.players.where((p) => p.team == team)) {
      final n = int.tryParse(p.label) ?? 0;
      if (n > max) max = n;
    }
    return max + 1;
  }
  bool get _hasDoubles => state.sportType.hasDoubles;

  void _add(PlayerGender gender, {Offset offset = Offset.zero}) {
    final c = state.canvasSize;
    final n = _nextNum;
    final baseY = state.spawnY(team);
    var pos = Offset(c.width * 0.5 + offset.dx, baseY + offset.dy);
    pos = _avoidOverlap(pos, c);
    state.addPlayer(PlayerIcon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: '$n',
      team: team,
      gender: gender,
      position: pos,
    ));
  }

  Offset _avoidOverlap(Offset pos, Size canvasSize) {
    const minDist = 48.0;
    var result = pos;
    for (int attempt = 0; attempt < 20; attempt++) {
      final overlap = state.players.any((p) => (p.position - result).distance < minDist);
      if (!overlap) return result;
      // Nudge right, then down, spiral out
      result = Offset(
        result.dx + 32 * ((attempt % 4 < 2) ? 1 : -1),
        result.dy + (attempt ~/ 2) * 20.0 * ((attempt % 2 == 0) ? 1 : -1),
      );
      // Clamp within canvas
      result = Offset(
        result.dx.clamp(24.0, canvasSize.width - 24.0),
        result.dy.clamp(24.0, canvasSize.height - 24.0),
      );
    }
    return result;
  }

  void _addPair(PlayerGender g1, PlayerGender g2) {
    _add(g1, offset: const Offset(-28, 0));
    _add(g2, offset: const Offset(28, 0));
    Navigator.pop(sheetCtx);
  }

  @override
  Widget build(BuildContext context) {
    final color = PlayerIcon.teamColor(team);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _PlayerCard(
              label: _hasDoubles ? 'male_single'.tr() : 'male'.tr(),
              color: color,
              genders: const [PlayerGender.male],
              onTap: () { _add(PlayerGender.male); Navigator.pop(sheetCtx); },
            ),
            const SizedBox(width: 8),
            _PlayerCard(
              label: _hasDoubles ? 'female_single'.tr() : 'female'.tr(),
              color: color,
              genders: const [PlayerGender.female],
              onTap: () { _add(PlayerGender.female); Navigator.pop(sheetCtx); },
            ),
            if (_hasDoubles) ...[
              const SizedBox(width: 8),
              _PlayerCard(
                label: 'male_doubles'.tr(),
                color: color,
                genders: const [PlayerGender.male, PlayerGender.male],
                onTap: () => _addPair(PlayerGender.male, PlayerGender.male),
              ),
              const SizedBox(width: 8),
              _PlayerCard(
                label: 'female_doubles'.tr(),
                color: color,
                genders: const [PlayerGender.female, PlayerGender.female],
                onTap: () => _addPair(PlayerGender.female, PlayerGender.female),
              ),
              const SizedBox(width: 8),
              _PlayerCard(
                label: 'mixed_doubles'.tr(),
                color: color,
                genders: const [PlayerGender.male, PlayerGender.female],
                onTap: () => _addPair(PlayerGender.male, PlayerGender.female),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Team formation row — for team sports (basketball, volleyball, soccer)
// Shows: team label + formation cards for single team + individual add
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// Team sport setup — step-by-step: count → formation → team
// ─────────────────────────────────────────────────────────────────────────────
enum _TeamOption { home, away, both }

class _TeamSportSetup extends StatefulWidget {
  final TacticsState state;
  final BuildContext sheetCtx;
  const _TeamSportSetup({required this.state, required this.sheetCtx});

  @override
  State<_TeamSportSetup> createState() => _TeamSportSetupState();
}

class _TeamSportSetupState extends State<_TeamSportSetup> {
  int? _selectedCount;
  SportFormation? _selectedFormation;
  _TeamOption _teamOption = _TeamOption.both;

  List<int> get _distinctCounts {
    final counts = <int>{};
    for (final f in widget.state.sportType.formations) {
      counts.add(f.homeCount);
    }
    return counts.toList()..sort((a, b) => b.compareTo(a));
  }

  List<SportFormation> get _formationsForCount {
    if (_selectedCount == null) return [];
    return widget.state.sportType.formations
        .where((f) => f.homeCount == _selectedCount)
        .toList();
  }

  void _apply() {
    if (_selectedFormation == null) return;
    final f = _selectedFormation!;
    switch (_teamOption) {
      case _TeamOption.both:
        widget.state.applyFormation(f);
      case _TeamOption.home:
        widget.state.addTeamFromFormation(f, PlayerTeam.home);
      case _TeamOption.away:
        widget.state.addTeamFromFormation(f, PlayerTeam.away);
    }
    Navigator.pop(widget.sheetCtx);
  }

  @override
  Widget build(BuildContext context) {
    final formations = _formationsForCount;
    // Auto-select if only one formation for this count
    if (_selectedCount != null && formations.length == 1 && _selectedFormation == null) {
      _selectedFormation = formations.first;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Player count
          Text('player_count'.tr(), style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: _distinctCounts.map((count) {
              final selected = _selectedCount == count;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedCount = count;
                    _selectedFormation = null; // reset
                  }),
                  child: Container(
                    width: 56,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? Colors.blue : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? Colors.blue : Colors.white24,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${count}v$count',
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Row 2: Formation (only if multiple formations for selected count)
          if (_selectedCount != null && formations.length > 1) ...[
            const SizedBox(height: 12),
            Text('formation_label'.tr(), style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: formations.map((f) {
                  final selected = _selectedFormation == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFormation = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? Colors.blue : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? Colors.blue : Colors.white24,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          f.nameKey.tr(),
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Row 3: Team selection
          if (_selectedFormation != null || (_selectedCount != null && formations.length == 1)) ...[
            const SizedBox(height: 12),
            Text('team_label'.tr(), style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildTeamChip('both_teams'.tr(), _TeamOption.both, Colors.purple),
                const SizedBox(width: 8),
                _buildTeamChip('team_home'.tr(), _TeamOption.home, const Color(0xFF1565C0)),
                const SizedBox(width: 8),
                _buildTeamChip('team_away'.tr(), _TeamOption.away, const Color(0xFFC62828)),
                const Spacer(),
                // Apply button
                GestureDetector(
                  onTap: _apply,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'confirm'.tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTeamChip(String label, _TeamOption option, Color activeColor) {
    final selected = _teamOption == option;
    return GestureDetector(
      onTap: () => setState(() => _teamOption = option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? activeColor : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TeamFormationRow extends StatelessWidget {
  final TacticsState state;
  final PlayerTeam team;
  final BuildContext sheetCtx;
  const _TeamFormationRow({required this.state, required this.team, required this.sheetCtx});

  @override
  Widget build(BuildContext context) {
    final color = PlayerIcon.teamColor(team);
    final label = team == PlayerTeam.home ? 'team_home'.tr() : 'team_away'.tr();
    // Get distinct player counts from formations
    final formations = state.sportType.formations;
    final countMap = <int, SportFormation>{};
    for (final f in formations) {
      final count = team == PlayerTeam.home ? f.homeCount : f.awayCount;
      countMap.putIfAbsent(count, () => f);
    }
    final counts = countMap.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: label, color: color),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...counts.map((count) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      state.addTeamFromFormation(countMap[count]!, team);
                      Navigator.pop(sheetCtx);
                    },
                    child: Container(
                      width: 56,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '${'count_suffix'.tr()}',
                          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                )),
                // Individual add
                _PlayerCard(
                  label: 'male'.tr(),
                  color: color,
                  genders: const [PlayerGender.male],
                  onTap: () {
                    final c = state.canvasSize;
                    final n = state.players.where((p) => p.team == team).length + 1;
                    final baseY = state.spawnY(team);
                    state.addPlayer(PlayerIcon(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      label: '$n', team: team, gender: PlayerGender.male,
                      position: Offset(c.width * 0.5, baseY),
                    ));
                    Navigator.pop(sheetCtx);
                  },
                ),
                const SizedBox(width: 8),
                _PlayerCard(
                  label: 'female'.tr(),
                  color: color,
                  genders: const [PlayerGender.female],
                  onTap: () {
                    final c = state.canvasSize;
                    final n = state.players.where((p) => p.team == team).length + 1;
                    final baseY = state.spawnY(team);
                    state.addPlayer(PlayerIcon(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      label: '$n', team: team, gender: PlayerGender.female,
                      position: Offset(c.width * 0.5, baseY),
                    ));
                    Navigator.pop(sheetCtx);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String label;
  final Color color;
  final List<PlayerGender> genders;
  final VoidCallback onTap;
  const _PlayerCard({required this.label, required this.color, required this.genders, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double iconSize = genders.length > 1 ? 24.0 : 38.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: genders.map((g) => SizedBox(
                width: iconSize,
                height: iconSize,
                child: CustomPaint(
                  painter: TopDownPlayerPainter(
                    color: color,
                    borderColor: Colors.white,
                    borderWidth: 1.5,
                    gender: g,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick formation row — shown directly in add sheet
// ─────────────────────────────────────────────────────────────────────────────
class _QuickFormationRow extends StatelessWidget {
  final TacticsState state;
  final BuildContext sheetCtx;
  const _QuickFormationRow({required this.state, required this.sheetCtx});

  @override
  Widget build(BuildContext context) {
    final formations = state.sportType.formations;
    final hasDoubles = formations.any((f) => f.nameKey == 'formation_doubles');
    final homeColor = PlayerIcon.teamColor(PlayerTeam.home);
    final awayColor = PlayerIcon.teamColor(PlayerTeam.away);

    final cards = <Widget>[];
    for (final f in formations) {
      final homeDots = List.generate(f.homeCount, (_) => (homeColor, PlayerGender.unspecified));
      final awayDots = List.generate(f.awayCount, (_) => (awayColor, PlayerGender.unspecified));
      cards.add(_FormationCard(
        label: f.nameKey.tr(),
        homeDots: homeDots,
        awayDots: awayDots,
        onTap: () => _apply(context, f),
      ));
      cards.add(const SizedBox(width: 8));
    }
    if (hasDoubles) {
      final doubles = formations.firstWhere((f) => f.nameKey == 'formation_doubles');
      cards.add(_FormationCard(
        label: 'mixed_doubles'.tr(),
        homeDots: [(homeColor, PlayerGender.male), (homeColor, PlayerGender.female)],
        awayDots: [(awayColor, PlayerGender.male), (awayColor, PlayerGender.female)],
        onTap: () => _apply(context, doubles,
          homeGenders: [PlayerGender.male, PlayerGender.female],
          awayGenders: [PlayerGender.male, PlayerGender.female]),
      ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: cards),
      ),
    );
  }

  void _apply(BuildContext context, SportFormation formation,
      {List<PlayerGender>? homeGenders, List<PlayerGender>? awayGenders}) {
    void doApply() {
      state.applyFormation(formation, homeGenders: homeGenders, awayGenders: awayGenders);
      Navigator.pop(sheetCtx);
    }
    if (state.players.isNotEmpty) {
      showDialog(
        context: context,
        builder: (dCtx) => AlertDialog(
          backgroundColor: const Color(0xFF213E48),
          title: Text('formation_replace_title'.tr(), style: const TextStyle(color: Colors.white)),
          content: Text('formation_replace_message'.tr(), style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: Text('cancel'.tr())),
            TextButton(
              onPressed: () { Navigator.pop(dCtx); doApply(); },
              child: Text('formation_apply'.tr(), style: const TextStyle(color: Colors.purple)),
            ),
          ],
        ),
      );
    } else {
      doApply();
    }
  }
}

class _FormationCard extends StatelessWidget {
  final String label;
  final List<(Color, PlayerGender)> homeDots;
  final List<(Color, PlayerGender)> awayDots;
  final VoidCallback onTap;
  const _FormationCard({required this.label, required this.homeDots, required this.awayDots, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._dots(homeDots),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text('vs', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ),
                ..._dots(awayDots),
              ],
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  List<Widget> _dots(List<(Color, PlayerGender)> dots) => dots.map((d) => Padding(
    padding: const EdgeInsets.only(right: 2),
    child: SizedBox(
      width: 22, height: 22,
      child: CustomPaint(
        painter: TopDownPlayerPainter(color: d.$1, borderColor: Colors.white, borderWidth: 1.5, gender: d.$2),
      ),
    ),
  )).toList();
}

class _MarkerCard extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback onTap;
  const _MarkerCard({required this.label, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final Widget? iconWidget;
  final IconData? icon;
  final Color? iconColor;
  final Color? bgColor;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _SheetTile({
    this.iconWidget,
    this.icon,
    this.iconColor,
    this.bgColor,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final leading = iconWidget ??
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? Colors.white, size: 22),
        );

    return ListTile(
      leading: SizedBox(width: 40, height: 40, child: leading),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: Colors.white54, fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      onTap: onTap,
    );
  }
}

// Small circular player preview for the sheet
class _PlayerDot extends StatelessWidget {
  final PlayerTeam team;
  final SportType sportType;
  final int number;
  const _PlayerDot({required this.team, required this.sportType, required this.number});

  @override
  Widget build(BuildContext context) {
    final color = PlayerIcon.teamColor(team);
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        children: [
          CustomPaint(
            painter: TopDownPlayerPainter(color: color, borderColor: Colors.white, borderWidth: 1.5),
            size: const Size(36, 36),
          ),
          Align(
            alignment: const Alignment(0, 0.3),
            child: Text(
              '$number',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drawing Options Row — single compact row (draw mode only)
// ─────────────────────────────────────────────────────────────────────────────

class DrawingOptionsBar extends StatelessWidget {
  final TacticsState state;
  const DrawingOptionsBar({super.key, required this.state});

  static const _colors = [
    Color(0xFFFFD600),
    Colors.white,
    Color(0xFFE53935),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFFFF6F00),
  ];

  @override
  Widget build(BuildContext context) {
    final sel = state.selectedStroke;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selected stroke actions
        if (sel != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
            child: Row(
              children: [
                Icon(Icons.gesture, color: sel.color, size: 16),
                const SizedBox(width: 6),
                Text('Line ${state.strokes.indexOf(sel) + 1}', style: TextStyle(color: sel.color, fontSize: 12, fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () { state.deleteStroke(sel.id); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete, color: Colors.redAccent, size: 14),
                        const SizedBox(width: 4),
                        Text('remove'.tr(), style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => state.selectStroke(null),
                  child: const Icon(Icons.close, color: Colors.white54, size: 18),
                ),
              ],
            ),
          ),
        // Row 1: line style + arrow
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ToggleChip(
                  label: 'line_solid'.tr(),
                  selected: state.strokeStyle == StrokeStyle.solid,
                  onTap: () => state.setStrokeStyle(StrokeStyle.solid),
                ),
                const SizedBox(width: 6),
                _ToggleChip(
                  label: 'line_dashed'.tr(),
                  selected: state.strokeStyle == StrokeStyle.dashed,
                  onTap: () => state.setStrokeStyle(StrokeStyle.dashed),
                ),
                const SizedBox(width: 14),
                const SizedBox(height: 18, child: VerticalDivider(color: Colors.white24, width: 1)),
                const SizedBox(width: 14),
                _ToggleChip(
                  label: 'arrow_none'.tr(),
                  selected: state.arrowStyle == ArrowStyle.none,
                  onTap: () => state.setArrowStyle(ArrowStyle.none),
                ),
                const SizedBox(width: 6),
                _ToggleChip(
                  label: '→',
                  selected: state.arrowStyle == ArrowStyle.end,
                  onTap: () => state.setArrowStyle(ArrowStyle.end),
                ),
                const SizedBox(width: 6),
                _ToggleChip(
                  label: '↔',
                  selected: state.arrowStyle == ArrowStyle.both,
                  onTap: () => state.setArrowStyle(ArrowStyle.both),
                ),
              ],
            ),
          ),
        ),
        // Row 2: color dots + width slider
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              ..._colors.map((c) => _ColorDot(
                    color: c,
                    selected: state.strokeColor == c,
                    onTap: () => state.setStrokeColor(c),
                  )),
              const SizedBox(width: 8),
              const SizedBox(height: 18, child: VerticalDivider(color: Colors.white24, width: 1)),
              Expanded(
                child: Slider(
                  value: state.strokeWidth,
                  min: 1,
                  max: 8,
                  divisions: 7,
                  activeColor: Colors.blue,
                  inactiveColor: Colors.white24,
                  onChanged: (v) => state.setStrokeWidth(v),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
            width: selected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _IconBtn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: color ?? Colors.white70, size: 24),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formation Tile
// ─────────────────────────────────────────────────────────────────────────────

class _FormationTile extends StatelessWidget {
  final SportFormation formation;
  final VoidCallback onTap;
  const _FormationTile({required this.formation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(
            '${formation.homeCount}v${formation.awayCount}',
            style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
      title: Text(formation.nameKey.tr(), style: const TextStyle(color: Colors.white, fontSize: 15)),
      subtitle: Text(
        '${'formation_home'.tr()} ${formation.homeCount}  ·  ${'formation_away'.tr()} ${formation.awayCount}',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Play / Stop button
// ─────────────────────────────────────────────────────────────────────────────

class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SmallIconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final TacticsState state;
  const _PlayButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final isPlaying = state.isAnimating;
    final canPlay = state.hasMoves && !isPlaying;

    return GestureDetector(
      onTap: isPlaying ? state.stopAnimation : canPlay ? state.startAnimation : null,
      child: Opacity(
        opacity: (!isPlaying && !canPlay) ? 0.35 : 1.0,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: isPlaying ? Colors.red.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: isPlaying ? Colors.red : Colors.lightGreenAccent, width: 1.5),
          ),
          child: Icon(isPlaying ? Icons.stop : Icons.play_arrow,
              color: isPlaying ? Colors.red : Colors.lightGreenAccent, size: 24),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step controls — back, indicator, forward
// ─────────────────────────────────────────────────────────────────────────────

class _LinesToggle extends StatelessWidget {
  final TacticsState state;
  const _LinesToggle({required this.state});

  @override
  Widget build(BuildContext context) {
    final show = state.showMoveLines;
    return GestureDetector(
      onTap: state.toggleShowMoveLines,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: show ? Colors.white10 : Colors.red.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          show ? Icons.timeline : Icons.visibility_off,
          color: show ? Colors.white54 : Colors.redAccent,
          size: 20,
        ),
      ),
    );
  }
}

class _TimelineBtn extends StatelessWidget {
  final TacticsState state;
  const _TimelineBtn({required this.state});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTimeline(context),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.view_timeline, color: Colors.purpleAccent, size: 20),
      ),
    );
  }

  void _showTimeline(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF213E48),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TimelineEditor(state: state),
    );
  }
}

class _ResetButton extends StatelessWidget {
  final TacticsState state;
  const _ResetButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final canReset = !state.isAnimating && state.atStep > 0;
    return GestureDetector(
      onTap: canReset ? state.clearAnimatedPositions : null,
      child: Opacity(
        opacity: canReset ? 1.0 : 0.35,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.replay, color: Colors.orange, size: 22),
        ),
      ),
    );
  }
}

class _StepBackButton extends StatelessWidget {
  final TacticsState state;
  const _StepBackButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final canStep = !state.isAnimating && state.atStep > 0;
    return GestureDetector(
      onTap: canStep ? state.stepBackward : null,
      child: Opacity(
        opacity: canStep ? 1.0 : 0.35,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.skip_previous, color: const Color(0xFF00E5CC), size: 22),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final TacticsState state;
  const _StepIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${state.atStep}/${state.maxMoveSteps}',
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class _StepForwardButton extends StatelessWidget {
  final TacticsState state;
  const _StepForwardButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final canStep = !state.isAnimating && state.atStep < state.maxMoveSteps;
    return GestureDetector(
      onTap: canStep ? state.stepForward : null,
      child: Opacity(
        opacity: canStep ? 1.0 : 0.35,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.skip_next, color: const Color(0xFF00E5CC), size: 22),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Play controls bar — floating overlay on canvas
// ─────────────────────────────────────────────────────────────────────────────
class PlayControlsBar extends StatelessWidget {
  final TacticsState state;
  const PlayControlsBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A4D58),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (state.selectedPlayerId != null) ...[
            _SmallIconBtn(icon: Icons.delete, color: Colors.redAccent, onTap: () => state.removePlayer(state.selectedPlayerId!)),
            const SizedBox(width: 6),
          ],
          if (state.canUndo) ...[
            _SmallIconBtn(icon: Icons.undo, color: Colors.white54, onTap: state.undo),
            const SizedBox(width: 6),
          ],
          if (state.canRedo) ...[
            _SmallIconBtn(icon: Icons.redo, color: Colors.white54, onTap: state.redo),
            const SizedBox(width: 6),
          ],
          _ResetButton(state: state),
          const SizedBox(width: 6),
          _StepBackButton(state: state),
          const SizedBox(width: 8),
          _StepIndicator(state: state),
          const SizedBox(width: 8),
          _StepForwardButton(state: state),
          const SizedBox(width: 6),
          _PlayButton(state: state),
          const SizedBox(width: 6),
          _LinesToggle(state: state),
          const SizedBox(width: 6),
          _TimelineBtn(state: state),
        ],
      ),
    );
  }
}
