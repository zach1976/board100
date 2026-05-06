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
import '../models/player_photo.dart';
import '../models/sport_formation.dart';
import '../models/sport_theme.dart';
import '../models/sport_type.dart';
import '../painters/ball_painter.dart';
import '../services/pdf_export_service.dart';
import '../services/photo_library_service.dart';
import '../state/tactics_state.dart';
import 'photo_import_sheet.dart';
import 'player_icon_widget.dart';
import 'timeline_editor.dart';

/// Tablet (shortestSide >= 600) gets 1.4× sizing for icons/buttons/fonts.
double uiScale(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600 ? 1.4 : 1.0;

/// Wraps a bottom-sheet / dialog child so all Text inside scales on tablets.
/// Hardcoded icon/container sizes still need to be multiplied by uiScale(ctx).
Widget scaledSheet(BuildContext ctx, Widget child) {
  final s = uiScale(ctx);
  if (s == 1.0) return child;
  return MediaQuery(
    data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(s)),
    child: child,
  );
}

/// Public function to show save/load bottom sheet
void showSaveLoadSheet(BuildContext context, TacticsState state) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF213E48),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => scaledSheet(ctx, _SaveLoadSheet(state: state)),
  );
}

/// Public function to share the board — prompts for PNG or PDF format
Future<void> shareBoardImage(BuildContext context, TacticsState state) async {
  final format = await _pickShareFormat(context);
  if (format == null || !context.mounted) return;
  if (format == 'pdf') {
    await _sharePdf(context, state);
  } else {
    await _sharePng(context, state);
  }
}

Future<String?> _pickShareFormat(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF213E48),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => scaledSheet(ctx, SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image_outlined, color: Color(0xFF00E5CC)),
            title: const Text('PNG', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(ctx, 'png'),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined, color: Colors.amberAccent),
            title: const Text('PDF', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(ctx, 'pdf'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    )),
  );
}

String _friendlyFileStem(TacticsState state) {
  final name = state.currentTacticName?.trim();
  final base = (name != null && name.isNotEmpty) ? name : state.sportType.displayName;
  final sanitized = base.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final stamp = '${now.year}-${two(now.month)}-${two(now.day)}_${two(now.hour)}${two(now.minute)}';
  return '${sanitized.isEmpty ? 'Tactics' : sanitized}_$stamp';
}

Future<void> _sharePng(BuildContext context, TacticsState state) async {
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
    final file = File('${dir.path}/${_friendlyFileStem(state)}.png');
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

Future<void> _sharePdf(BuildContext context, TacticsState state) async {
  state.resetZoom();
  await Future.delayed(const Duration(milliseconds: 200));
  try {
    final ok = await PdfExportService.exportCurrentFrame(
      title: state.currentTacticName?.trim().isNotEmpty == true
          ? state.currentTacticName!.trim()
          : state.sportType.displayName,
      filename: '${_friendlyFileStem(state)}.pdf',
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('save_error'.tr())),
      );
    }
  } catch (e) {
    debugPrint('PDF export error: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('save_error'.tr())),
      );
    }
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
    builder: (ctx) => scaledSheet(ctx, _AddPlayerSheet(state: state, sheetCtx: ctx)),
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
          color: state.sportType.theme.panelColor,
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
              _IconBtn(icon: Icons.ios_share, onTap: () => shareBoardImage(context, state), color: Colors.tealAccent),
            ],
          ),
        ],
      ),
    );
  }

  void _showSaveLoad(BuildContext context) {
    showSaveLoadSheet(context, state);
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
  late final _nameCtrl = TextEditingController(text: widget.state.currentTacticName ?? '');
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

  Future<void> _renameTactic(String oldName) async {
    final ctrl = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF213E48),
        title: const Text('Rename', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'tactics_name'.tr(),
            hintStyle: const TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('confirm'.tr(), style: const TextStyle(color: Color(0xFF00E5CC))),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == oldName) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.state.renameTactics(oldName, newName);
      await _loadList();
      messenger.showSnackBar(SnackBar(content: Text('$oldName → $newName')));
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('practice_name_exists'.tr())),
      );
    }
  }

  Future<void> _overwriteTactic(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF213E48),
        title: Text('save'.tr(), style: const TextStyle(color: Colors.white)),
        content: Text(name, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('confirm'.tr(), style: const TextStyle(color: Color(0xFF00E5CC))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await widget.state.saveTactics(name);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('${'save_success'.tr()}: $name')),
    );
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
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    if (name.isEmpty) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('tactics_name'.tr())),
                      );
                      return;
                    }
                    try {
                      await widget.state.saveTactics(name);
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(content: Text('${'save_success'.tr()}: $name')),
                      );
                    } catch (e) {
                      debugPrint('Save error: $e');
                      messenger.showSnackBar(
                        SnackBar(content: Text('Save failed: $e')),
                      );
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
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.drive_file_rename_outline, color: Colors.white54, size: 20),
                          onPressed: () => _renameTactic(name),
                          tooltip: 'Rename',
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.save_as_outlined, color: Color(0xFF00E5CC), size: 20),
                          onPressed: () => _overwriteTactic(name),
                          tooltip: 'Update',
                        ),
                        const SizedBox(width: 2),
                        GestureDetector(
                          onTap: () async {
                            await widget.state.loadTactics(name);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                            child: Text('load'.tr(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () async {
                            await widget.state.deleteTactics(name);
                            await _loadList();
                          },
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
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
    final s = uiScale(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3A7DFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1.0,
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 15 * s),
              SizedBox(width: 4 * s),
              Text(label, style: TextStyle(color: Colors.white, fontSize: 12 * s, fontWeight: FontWeight.w500)),
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
    final s = uiScale(context);
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 15 * s),
            SizedBox(width: 4 * s),
            Text('add_label'.tr(),
                style: TextStyle(color: Colors.white, fontSize: 12 * s, fontWeight: FontWeight.w500)),
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
      builder: (ctx) => scaledSheet(ctx, _AddPlayerSheet(state: state, sheetCtx: ctx)),
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

  /// Drop a single player onto the given team's spawn area, nudging to
  /// avoid overlapping any existing icons. Closes the sheet.
  void _addOneTeamPlayer(PlayerTeam team) {
    final c = state.canvasSize;
    int max = 0;
    for (final p in state.players.where((p) => p.team == team)) {
      final n = int.tryParse(p.label) ?? 0;
      if (n > max) max = n;
    }
    var pos = Offset(c.width * 0.5, state.spawnY(team));
    const minDist = 48.0;
    for (int attempt = 0; attempt < 20; attempt++) {
      final overlap = state.players.any((p) => (p.position - pos).distance < minDist);
      if (!overlap) break;
      pos = Offset(
        pos.dx + 32 * ((attempt % 4 < 2) ? 1 : -1),
        pos.dy + (attempt ~/ 2) * 20.0 * ((attempt % 2 == 0) ? 1 : -1),
      );
      pos = Offset(
        pos.dx.clamp(24.0, c.width - 24.0),
        pos.dy.clamp(24.0, c.height - 24.0),
      );
    }
    state.addPlayer(PlayerIcon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: '${max + 1}',
      team: team,
      position: pos,
    ));
    Navigator.pop(sheetCtx);
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
              _SectionHeader(label: 'team_home'.tr(), color: const Color(0xFF3A7DFF)),
              _PlayerAddRow(state: state, team: PlayerTeam.home, sheetCtx: sheetCtx),
              const SizedBox(height: 4),
              _SectionHeader(label: 'team_away'.tr(), color: const Color(0xFFFF5A5F)),
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
                    if (isTeamSport) ...[
                      _MarkerCard(
                        label: 'team_home'.tr(),
                        child: _QuickAddTeamGlyph(team: PlayerTeam.home),
                        onTap: () => _addOneTeamPlayer(PlayerTeam.home),
                      ),
                      const SizedBox(width: 8),
                      _MarkerCard(
                        label: 'team_away'.tr(),
                        child: _QuickAddTeamGlyph(team: PlayerTeam.away),
                        onTap: () => _addOneTeamPlayer(PlayerTeam.away),
                      ),
                      const SizedBox(width: 8),
                    ],
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
                      child: Builder(builder: (ctx) {
                        final s = uiScale(ctx);
                        return Container(
                          width: 52 * s, height: 52 * s,
                          decoration: BoxDecoration(
                            color: _showMore ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_showMore ? Icons.expand_less : Icons.more_horiz, color: Colors.white54, size: 18 * s),
                              Text(_showMore ? 'less'.tr() : 'more'.tr(),
                                  style: const TextStyle(color: Colors.white54, fontSize: 9)),
                            ],
                          ),
                        );
                      }),
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
                      _MarkerCard(
                        label: 'neutral_male'.tr(),
                        child: SizedBox(width: 28, height: 28, child: CustomPaint(painter: TopDownPlayerPainter(color: const Color(0xFF616161), borderColor: Colors.white, borderWidth: 2, gender: PlayerGender.male))),
                        onTap: () {
                          final c = state.canvasSize;
                          state.addPlayer(PlayerIcon(
                            id: DateTime.now().microsecondsSinceEpoch.toString(),
                            label: '',
                            team: PlayerTeam.neutral,
                            position: Offset(c.width * 0.5, state.spawnY(PlayerTeam.neutral)),
                            gender: PlayerGender.male,
                          ));
                          Navigator.pop(sheetCtx);
                        },
                      ),
                      const SizedBox(width: 8),
                      _MarkerCard(
                        label: 'neutral_female'.tr(),
                        child: SizedBox(width: 28, height: 28, child: CustomPaint(painter: TopDownPlayerPainter(color: const Color(0xFF616161), borderColor: Colors.white, borderWidth: 2, gender: PlayerGender.female))),
                        onTap: () {
                          final c = state.canvasSize;
                          state.addPlayer(PlayerIcon(
                            id: DateTime.now().microsecondsSinceEpoch.toString(),
                            label: '',
                            team: PlayerTeam.neutral,
                            position: Offset(c.width * 0.5, state.spawnY(PlayerTeam.neutral)),
                            gender: PlayerGender.female,
                          ));
                          Navigator.pop(sheetCtx);
                        },
                      ),
                      const SizedBox(width: 8),
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
            const Divider(color: Colors.white12),
            _MyPhotosSection(state: state, sheetCtx: sheetCtx),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Photos — face-avatar tiles. Tap to add a player using that face (sheet
// stays open so the user can keep tapping for batch adds). Long-press a tile
// to delete that photo from the library. The leading "+" tile starts the
// pick-and-detect import flow.
// ─────────────────────────────────────────────────────────────────────────────
class _MyPhotosSection extends StatefulWidget {
  final TacticsState state;
  final BuildContext sheetCtx;
  const _MyPhotosSection({required this.state, required this.sheetCtx});

  @override
  State<_MyPhotosSection> createState() => _MyPhotosSectionState();
}

class _MyPhotosSectionState extends State<_MyPhotosSection> {
  PlayerTeam _team = PlayerTeam.home;
  String? _selectedGroupId;
  bool _editing = false;

  TacticsState get state => widget.state;

  /// Add every photo in the current group to the board, lined up in a row
  /// at the chosen team's spawn area. Closes the sheet when done so the
  /// user can see the result.
  void _addAllInGroup(List<PlayerPhoto> photos) {
    if (photos.isEmpty) return;
    final c = state.canvasSize;
    if (c.isEmpty) return;
    // Use the visible-half spawn rule (sheet hides the bottom half) so all
    // newly-placed players land in the visible part of the board.
    final spawnY = _team == PlayerTeam.away ? c.height * 0.20 : c.height * 0.55;
    int max = 0;
    for (final p in state.players.where((p) => p.team == _team)) {
      final n = int.tryParse(p.label) ?? 0;
      if (n > max) max = n;
    }
    final n = photos.length;
    final left = c.width * 0.12;
    final right = c.width * 0.88;
    final span = right - left;
    for (int i = 0; i < n; i++) {
      final x = n == 1 ? c.width * 0.5 : left + span * i / (n - 1);
      state.addPlayer(PlayerIcon(
        id: '${DateTime.now().microsecondsSinceEpoch}_$i',
        label: '${max + i + 1}',
        team: _team,
        position: Offset(x, spawnY),
        photoId: photos[i].id,
      ));
    }
    HapticFeedback.lightImpact();
    Navigator.of(widget.sheetCtx).maybePop();
  }

  /// User finished a long-press drag whose drop wasn't claimed by a
  /// DragTarget (the modal sheet's barrier always intercepts hits, so this
  /// is the normal path). If the global drop point is over the board, pop
  /// the sheet and add a player at that exact spot.
  void _onDropOutsideTarget(PlayerPhoto photo, Offset globalPos) {
    final ro = boardRepaintKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.attached) return;
    final localPos = ro.globalToLocal(globalPos);
    final size = ro.size;
    if (localPos.dx < 0 || localPos.dy < 0) return;
    if (localPos.dx > size.width || localPos.dy > size.height) return;
    int max = 0;
    for (final p in state.players.where((p) => p.team == _team)) {
      final n = int.tryParse(p.label) ?? 0;
      if (n > max) max = n;
    }
    final clamped = Offset(
      localPos.dx.clamp(24.0, size.width - 24.0),
      localPos.dy.clamp(24.0, size.height - 24.0),
    );
    state.addPlayer(PlayerIcon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: '${max + 1}',
      team: _team,
      position: clamped,
      photoId: photo.id,
    ));
    HapticFeedback.lightImpact();
    Navigator.of(widget.sheetCtx).maybePop();
  }

  Future<void> _addPlayerWithPhoto(PlayerPhoto photo, Offset tapPos) async {
    // Duplicate confirmation: if any player already uses this photo, ask
    // before adding another.
    final existing = state.players.where((p) => p.photoId == photo.id).length;
    if (existing > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF14302A),
          title: Text('photo_duplicate_title'.tr(),
              style: const TextStyle(color: Colors.white)),
          content: Text(
            'photo_duplicate_msg'.tr(args: ['$existing']),
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('cancel'.tr(), style: const TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('photo_add_another'.tr(),
                  style: const TextStyle(color: Color(0xFF6EE7B7))),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    final c = state.canvasSize;
    int max = 0;
    for (final p in state.players.where((p) => p.team == _team)) {
      final n = int.tryParse(p.label) ?? 0;
      if (n > max) max = n;
    }
    // The Add sheet covers the bottom of the screen, so the home half of
    // the canvas (y≈0.75) is hidden. Spawn photo-avatar players into the
    // visible upper portion regardless of team — user can drag to position
    // afterwards.
    final spawnY = _team == PlayerTeam.away
        ? c.height * 0.20
        : c.height * 0.55;
    var pos = Offset(c.width * 0.5, spawnY);
    const minDist = 48.0;
    for (int attempt = 0; attempt < 20; attempt++) {
      final overlap = state.players.any((p) => (p.position - pos).distance < minDist);
      if (!overlap) break;
      pos = Offset(
        pos.dx + 32 * ((attempt % 4 < 2) ? 1 : -1),
        pos.dy + (attempt ~/ 2) * 20.0 * ((attempt % 2 == 0) ? 1 : -1),
      );
      pos = Offset(
        pos.dx.clamp(24.0, c.width - 24.0),
        pos.dy.clamp(24.0, c.height - 24.0),
      );
    }
    state.addPlayer(PlayerIcon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: '${max + 1}',
      team: _team,
      position: pos,
      photoId: photo.id,
    ));
    HapticFeedback.lightImpact();
    if (mounted) _flyToBoard(tapPos, photo, pos);
  }

  /// Spawn a transient overlay that flies a circular avatar from [start]
  /// (the user's finger position on the thumbnail) to the actual canvas
  /// landing spot of the new player, projected through the board's RenderBox
  /// so the avatar lands exactly where the marker appears.
  Future<void> _flyToBoard(Offset start, PlayerPhoto photo, Offset finalCanvasPos) async {
    final path = await PhotoLibraryService.instance.resolvePath(photo);
    if (!mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    const tile = 52.0;

    // Project the canvas-local final position into global screen coords so
    // the animation endpoint matches the rendered marker. Fall back to a
    // visible-half heuristic if the canvas RenderBox isn't ready.
    Offset endGlobal;
    final renderObj = boardRepaintKey.currentContext?.findRenderObject();
    if (renderObj is RenderBox && renderObj.attached) {
      endGlobal = renderObj.localToGlobal(finalCanvasPos);
    } else {
      final size = MediaQuery.of(context).size;
      endGlobal = Offset(
        size.width * 0.5,
        _team == PlayerTeam.away ? size.height * 0.18 : size.height * 0.45,
      );
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        onEnd: () => entry.remove(),
        builder: (_, t, __) {
          // Fly toward the actual landing spot.
          final cy = start.dy + (endGlobal.dy - start.dy) * t;
          final cx = start.dx + (endGlobal.dx - start.dx) * t;
          // Slight scale-down + fade as it lands so it visually merges into
          // the marker that's already rendered on the board.
          final scale = 1.0 - 0.4 * t;
          final opacity = (1.0 - t * 0.6).clamp(0.0, 1.0);
          return Positioned(
            left: cx - tile / 2,
            top: cy - tile / 2,
            child: IgnorePointer(
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: tile,
                    height: tile,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: FileImage(File(path)),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: PlayerIcon.teamColor(_team),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: PlayerIcon.teamColor(_team).withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    overlay.insert(entry);
  }

  Future<void> _confirmDelete(BuildContext context, PlayerPhoto photo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14302A),
        title: Text('photo_delete_confirm'.tr(), style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr(), style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('remove'.tr(), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await PhotoLibraryService.instance.delete(photo.id);
    }
  }

  /// Returns the user-confirmed name (may be empty if they applied an empty
  /// field — the caller is expected to fall back to a default), or `null`
  /// if the user cancelled / dismissed the dialog.
  Future<String?> _promptGroupName(BuildContext context, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    // Wrap the value in a 1-element list so we can distinguish "apply with
    // empty text" (`['']`) from "cancel/dismiss" (`null`).
    final box = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14302A),
        title: Text('photo_group_name'.tr(), style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'photo_group_name'.tr(),
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6EE7B7))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr(), style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop([controller.text]),
            child: Text('confirm'.tr(), style: const TextStyle(color: Color(0xFF6EE7B7))),
          ),
        ],
      ),
    );
    if (box == null) return null; // cancelled
    return box.first.trim();
  }

  Future<void> _onGroupLongPress(BuildContext context, PhotoGroup group) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF14302A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.white),
              title: Text('photo_group_rename'.tr(), style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(ctx).pop('rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text('photo_group_delete'.tr(), style: const TextStyle(color: Colors.redAccent)),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'rename') {
      final name = await _promptGroupName(context, initial: group.name);
      if (name == null) return;
      // Empty Apply → keep current name unchanged.
      if (name.isNotEmpty) {
        await PhotoLibraryService.instance.renameGroup(group.id, name);
      }
    } else if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF14302A),
          title: Text('photo_group_delete'.tr(), style: const TextStyle(color: Colors.white)),
          content: Text('photo_group_delete_confirm'.tr(), style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('cancel'.tr(), style: const TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('remove'.tr(), style: const TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );
      if (ok == true) {
        await PhotoLibraryService.instance.deleteGroup(group.id);
        if (mounted) setState(() => _selectedGroupId = null);
      }
    }
  }

  Future<void> _newGroup(BuildContext context) async {
    // Pre-fill the dialog with a default like "球队 3" / "Team 3" so empty
    // Apply still produces a usable name. Picks the next number that
    // doesn't collide with an existing default-named group.
    final existingGroups = await PhotoLibraryService.instance.listGroups();
    final defaultBase = 'photo_group_default_prefix'.tr();
    int n = existingGroups.length + 1;
    String defaultName;
    while (true) {
      defaultName = '$defaultBase $n';
      if (!existingGroups.any((g) => g.name == defaultName)) break;
      n++;
    }
    if (!mounted) return;
    final name = await _promptGroupName(context, initial: defaultName);
    if (name == null) return; // user cancelled
    // Empty Apply → use the default we pre-filled.
    final finalName = name.isEmpty ? defaultName : name;
    final group = await PhotoLibraryService.instance.createGroup(finalName);
    if (mounted) setState(() => _selectedGroupId = group.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PhotoLibraryService.instance,
      builder: (context, _) {
        return FutureBuilder<List<PhotoGroup>>(
          future: PhotoLibraryService.instance.listGroups(),
          builder: (context, gsnap) {
            final groups = gsnap.data ?? const <PhotoGroup>[];
            // Default selection: first group.
            String? activeId = _selectedGroupId;
            if (groups.isNotEmpty &&
                (activeId == null || !groups.any((g) => g.id == activeId))) {
              activeId = groups.first.id;
            }
            return FutureBuilder<List<PlayerPhoto>>(
              future: PhotoLibraryService.instance.list(),
              builder: (context, psnap) {
                final all = psnap.data ?? const <PlayerPhoto>[];
                final photos = activeId == null
                    ? const <PlayerPhoto>[]
                    : all.where((p) => p.groupId == activeId).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header: title + match-side picker.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      child: Row(
                        children: [
                          Text(
                            'photos_label'.tr(),
                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const Spacer(),
                          _PhotoTeamChip(
                            label: 'team_home'.tr(),
                            color: PlayerIcon.teamColor(PlayerTeam.home),
                            selected: _team == PlayerTeam.home,
                            onTap: () => setState(() => _team = PlayerTeam.home),
                          ),
                          const SizedBox(width: 6),
                          _PhotoTeamChip(
                            label: 'team_away'.tr(),
                            color: PlayerIcon.teamColor(PlayerTeam.away),
                            selected: _team == PlayerTeam.away,
                            onTap: () => setState(() => _team = PlayerTeam.away),
                          ),
                        ],
                      ),
                    ),
                    // Group tabs (scrollable). Tap to select; long-press for
                    // rename/delete. Trailing "+" creates a new group.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...groups.map((g) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _GroupTab(
                                label: g.name,
                                selected: g.id == activeId,
                                onTap: () => setState(() => _selectedGroupId = g.id),
                                onLongPress: () => _onGroupLongPress(context, g),
                              ),
                            )),
                            _GroupTab(
                              label: '+',
                              selected: false,
                              onTap: () => _newGroup(context),
                              onLongPress: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Photo strip for the selected group.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _AddPhotoTile(
                              onTap: activeId == null
                                  ? () => _newGroup(context)
                                  : () => PhotoImportSheet.showWithSourcePicker(
                                        context,
                                        groupId: activeId!,
                                      ),
                            ),
                            const SizedBox(width: 8),
                            if (photos.isNotEmpty) ...[
                              _EditModeTile(
                                editing: _editing,
                                onTap: () => setState(() => _editing = !_editing),
                              ),
                              const SizedBox(width: 8),
                              _AddAllTile(
                                count: photos.length,
                                onTap: () => _addAllInGroup(photos),
                              ),
                              const SizedBox(width: 8),
                            ],
                            ...photos.map((photo) => Padding(
                              key: ValueKey('photo_pad_${photo.id}'),
                              padding: const EdgeInsets.only(right: 8),
                              child: _PhotoTile(
                                key: ValueKey(photo.id),
                                photo: photo,
                                currentTeam: _team,
                                showDeleteBadge: _editing,
                                onTap: (tapPos) => _addPlayerWithPhoto(photo, tapPos),
                                onDropOutsideTarget: (globalPos) =>
                                    _onDropOutsideTarget(photo, globalPos),
                                onDeleteRequested: () =>
                                    _confirmDelete(context, photo),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _GroupTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _GroupTab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6EE7B7).withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF6EE7B7)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF6EE7B7) : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// What the strip hands to the canvas when the user drags a photo onto
/// the board. Carries the team the player should join (current toggle).
class PhotoDragData {
  final PlayerPhoto photo;
  final String? path;
  final PlayerTeam team;
  const PhotoDragData({required this.photo, this.path, required this.team});
}

class _PhotoTile extends StatefulWidget {
  final PlayerPhoto photo;
  final PlayerTeam currentTeam;
  /// Receives the global tap position so the parent can launch a flight
  /// animation starting from the user's finger.
  final void Function(Offset globalPosition) onTap;
  /// Called when the user releases a drag whose drop wasn't claimed by any
  /// DragTarget (which is always the case while the modal Add sheet is up,
  /// because its barrier sits on top of the board). The parent then decides
  /// whether the drop landed on the board area and handles placement.
  final void Function(Offset globalDropPos)? onDropOutsideTarget;
  /// True when the section is in edit mode — the tile shows a small red X
  /// badge and tapping it triggers [onDeleteRequested].
  final bool showDeleteBadge;
  final VoidCallback? onDeleteRequested;
  const _PhotoTile({
    super.key,
    required this.photo,
    required this.currentTeam,
    required this.onTap,
    this.onDropOutsideTarget,
    this.showDeleteBadge = false,
    this.onDeleteRequested,
  });

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  String? _path;
  Offset _tapDownPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(_PhotoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the State was recycled for a different photo (e.g. after a delete
    // shifts the rest of the strip), drop the stale cached path and re-resolve.
    if (oldWidget.photo.id != widget.photo.id) {
      setState(() => _path = null);
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final p = await PhotoLibraryService.instance.resolvePath(widget.photo);
    if (mounted) setState(() => _path = p);
  }

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    final dim = 52 * s;
    final tile = Container(
      width: dim, height: dim,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        image: _path != null
            ? DecorationImage(
                image: FileImage(File(_path!)),
                fit: BoxFit.cover,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
    final dragData = PhotoDragData(
      photo: widget.photo,
      path: _path,
      team: widget.currentTeam,
    );
    final feedback = Material(
      color: Colors.transparent,
      child: Container(
        width: dim * 1.15,
        height: dim * 1.15,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          image: _path != null
              ? DecorationImage(
                  image: FileImage(File(_path!)),
                  fit: BoxFit.cover,
                )
              : null,
          border: Border.all(
            color: PlayerIcon.teamColor(widget.currentTeam),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: PlayerIcon.teamColor(widget.currentTeam)
                  .withValues(alpha: 0.55),
              blurRadius: 14,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
    final draggable = LongPressDraggable<PhotoDragData>(
      data: dragData,
      feedback: feedback,
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      onDragEnd: (details) {
        if (details.wasAccepted) return;
        widget.onDropOutsideTarget?.call(details.offset);
      },
      child: GestureDetector(
        onTapDown: (d) => _tapDownPos = d.globalPosition,
        onTap: () => widget.onTap(_tapDownPos),
        child: tile,
      ),
    );
    if (!widget.showDeleteBadge) return draggable;
    // Edit mode — overlay an X badge in the top-right that fires the
    // delete handler when tapped, so the user has an explicit way to
    // remove an avatar (long-press is busy with drag).
    return Stack(
      clipBehavior: Clip.none,
      children: [
        draggable,
        Positioned(
          top: -4, right: -4,
          child: GestureDetector(
            onTap: widget.onDeleteRequested,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52 * s, height: 52 * s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white24, style: BorderStyle.solid, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: Colors.white70, size: 18 * s),
            SizedBox(height: 2 * s),
            Text('photo_add_label'.tr(),
                style: TextStyle(color: Colors.white54, fontSize: 9 * s)),
          ],
        ),
      ),
    );
  }
}

/// Team-coloured "+1" glyph used inside a [_MarkerCard] tile so the
/// quick-add buttons match the visual rhythm of the ball / shape row.
class _QuickAddTeamGlyph extends StatelessWidget {
  final PlayerTeam team;
  const _QuickAddTeamGlyph({required this.team});

  @override
  Widget build(BuildContext context) {
    final color = PlayerIcon.teamColor(team);
    return SizedBox(
      width: 28, height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const Positioned.fill(
            child: Center(
              child: Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

/// Edit-mode toggle styled like a strip tile — sits right next to "+ Add"
/// so the edit affordance is one tap away from the add affordance.
class _EditModeTile extends StatelessWidget {
  final bool editing;
  final VoidCallback onTap;
  const _EditModeTile({required this.editing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    final accent = editing ? const Color(0xFFFFD166) : Colors.white54;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52 * s, height: 52 * s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: editing
              ? const Color(0xFFFFD166).withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              editing ? Icons.check_circle : Icons.edit_outlined,
              color: accent,
              size: 18 * s,
            ),
            SizedBox(height: 1 * s),
            Text(
              editing ? '完成' : '编辑',
              style: TextStyle(color: accent, fontSize: 9 * s, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Add the whole team" tile — taps once and every photo in the current
/// group joins the board, lined up at the team's spawn area.
class _AddAllTile extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _AddAllTile({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52 * s, height: 52 * s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF6EE7B7).withValues(alpha: 0.16),
          border: Border.all(color: const Color(0xFF6EE7B7), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_add_outlined,
                color: const Color(0xFF6EE7B7), size: 18 * s),
            SizedBox(height: 1 * s),
            Text(
              '+$count',
              style: TextStyle(
                color: const Color(0xFF6EE7B7),
                fontSize: 9 * s,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTeamChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _PhotoTeamChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
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

  int _nextNum(PlayerTeam team) {
    int max = 0;
    for (final p in widget.state.players.where((p) => p.team == team)) {
      final n = int.tryParse(p.label) ?? 0;
      if (n > max) max = n;
    }
    return max + 1;
  }

  /// Add a single player to the given team at a sensible default position,
  /// nudged to avoid overlapping existing icons. Closes the sheet.
  void _addOnePlayer(PlayerTeam team) {
    final state = widget.state;
    final c = state.canvasSize;
    final baseY = state.spawnY(team);
    var pos = Offset(c.width * 0.5, baseY);
    const minDist = 48.0;
    for (int attempt = 0; attempt < 20; attempt++) {
      final overlap = state.players.any((p) => (p.position - pos).distance < minDist);
      if (!overlap) break;
      pos = Offset(
        pos.dx + 32 * ((attempt % 4 < 2) ? 1 : -1),
        pos.dy + (attempt ~/ 2) * 20.0 * ((attempt % 2 == 0) ? 1 : -1),
      );
      pos = Offset(
        pos.dx.clamp(24.0, c.width - 24.0),
        pos.dy.clamp(24.0, c.height - 24.0),
      );
    }
    state.addPlayer(PlayerIcon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: '${_nextNum(team)}',
      team: team,
      position: pos,
    ));
    Navigator.pop(widget.sheetCtx);
  }

  Widget _quickAddChip(PlayerTeam team) {
    final color = PlayerIcon.teamColor(team);
    final label = team == PlayerTeam.home ? 'team_home'.tr() : 'team_away'.tr();
    return GestureDetector(
      onTap: () => _addOnePlayer(team),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.add, color: Colors.white, size: 12),
            ),
            const SizedBox(width: 6),
            Text(
              '+1 $label',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

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

    final s = uiScale(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Player count
          // (Quick +1 home/away has moved to the markers row, next to the
          //  ball, so it's reachable without scrolling past the formation
          //  picker.)
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
                    width: 56 * s,
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
                _buildTeamChip('team_home'.tr(), _TeamOption.home, const Color(0xFF3A7DFF)),
                const SizedBox(width: 8),
                _buildTeamChip('team_away'.tr(), _TeamOption.away, const Color(0xFFFF5A5F)),
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
                      width: 56 * uiScale(context),
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
    final s = uiScale(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60 * s,
        padding: EdgeInsets.symmetric(vertical: 8 * s, horizontal: 4 * s),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            SizedBox(height: 4 * s),
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
    final s = uiScale(context);
    final leading = iconWidget ??
        Container(
          width: 40 * s,
          height: 40 * s,
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? Colors.white, size: 22 * s),
        );

    return ListTile(
      leading: SizedBox(width: 40 * s, height: 40 * s, child: leading),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: Colors.white54, fontSize: 12))
          : null,
      trailing: Icon(Icons.chevron_right, color: Colors.white24, size: 20 * s),
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
  /// When false, hides the colour swatches + width slider row (default).
  /// Toggled by the outer collapsible panel's More/Less header.
  final bool showOptions;
  const DrawingOptionsBar({super.key, required this.state, this.showOptions = false});

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
    final s = uiScale(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selected stroke actions
        if (sel != null)
          Padding(
            padding: EdgeInsets.fromLTRB(12 * s, 6 * s, 12 * s, 2 * s),
            child: Row(
              children: [
                Icon(Icons.gesture, color: sel.color, size: 16 * s),
                SizedBox(width: 6 * s),
                Text('Line ${state.strokes.indexOf(sel) + 1}', style: TextStyle(color: sel.color, fontSize: 12 * s, fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () { state.deleteStroke(sel.id); },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete, color: Colors.redAccent, size: 14 * s),
                        SizedBox(width: 4 * s),
                        Text('remove'.tr(), style: TextStyle(color: Colors.redAccent, fontSize: 12 * s)),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8 * s),
                GestureDetector(
                  onTap: () => state.selectStroke(null),
                  child: Icon(Icons.close, color: Colors.white54, size: 18 * s),
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
        // Row 2: color dots + width slider — hidden by default; appears
        // only when the user expands the More panel.
        if (showOptions)
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
    final s = uiScale(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 6 * s),
        width: 24 * s,
        height: 24 * s,
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
    final s = uiScale(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(color: Colors.white, fontSize: 13 * s, fontWeight: FontWeight.w500)),
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
    final s = uiScale(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(6 * s),
        child: Icon(icon, color: color ?? Colors.white70, size: 24 * s),
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
  final VoidCallback? onTap;
  const _SmallIconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3 * s),
        child: Icon(icon, color: color, size: 20 * s),
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

    final s = uiScale(context);
    return GestureDetector(
      onTap: isPlaying ? state.stopAnimation : canPlay ? state.startAnimation : null,
      child: Opacity(
        opacity: (!isPlaying && !canPlay) ? 0.35 : 1.0,
        child: Container(
          width: 38 * s, height: 38 * s,
          decoration: BoxDecoration(
            color: isPlaying ? Colors.red.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: isPlaying ? Colors.red : Colors.lightGreenAccent, width: 1.5),
          ),
          child: Icon(isPlaying ? Icons.stop : Icons.play_arrow,
              color: isPlaying ? Colors.red : Colors.lightGreenAccent, size: 24 * s),
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
    final s = uiScale(context);
    final show = state.showMoveLines;
    return GestureDetector(
      onTap: state.toggleShowMoveLines,
      child: Container(
        width: 36 * s, height: 36 * s,
        decoration: BoxDecoration(
          color: show ? Colors.white10 : Colors.red.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          show ? Icons.timeline : Icons.visibility_off,
          color: show ? Colors.white54 : Colors.redAccent,
          size: 20 * s,
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
    final s = uiScale(context);
    return GestureDetector(
      onTap: () => _showTimeline(context),
      child: Container(
        width: 36 * s, height: 36 * s,
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.view_timeline, color: Colors.purpleAccent, size: 20 * s),
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
      builder: (ctx) => scaledSheet(ctx, TimelineEditor(state: state)),
    );
  }
}

class _ResetButton extends StatelessWidget {
  final TacticsState state;
  const _ResetButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    final canReset = !state.isAnimating && state.atStep > 0;
    return GestureDetector(
      onTap: canReset ? state.clearAnimatedPositions : null,
      child: Opacity(
        opacity: canReset ? 1.0 : 0.35,
        child: Container(
          width: 36 * s, height: 36 * s,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.replay, color: Colors.orange, size: 22 * s),
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
    final s = uiScale(context);
    final canStep = !state.isAnimating && state.atStep > 0;
    return GestureDetector(
      onTap: canStep ? state.stepBackward : null,
      child: Opacity(
        opacity: canStep ? 1.0 : 0.35,
        child: Container(
          width: 36 * s, height: 36 * s,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.skip_previous, color: const Color(0xFF00E5CC), size: 22 * s),
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
    final s = uiScale(context);
    return Text(
      '${state.atStep}/${state.maxMoveSteps}',
      style: TextStyle(color: Colors.white, fontSize: 16 * s, fontWeight: FontWeight.bold),
    );
  }
}

class _StepForwardButton extends StatelessWidget {
  final TacticsState state;
  const _StepForwardButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    final canStep = !state.isAnimating && state.atStep < state.maxMoveSteps;
    return GestureDetector(
      onTap: canStep ? state.stepForward : null,
      child: Opacity(
        opacity: canStep ? 1.0 : 0.35,
        child: Container(
          width: 36 * s, height: 36 * s,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.skip_next, color: const Color(0xFF00E5CC), size: 22 * s),
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
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (state.selectedPlayerId != null) ...[
            _SmallIconBtn(icon: Icons.delete, color: Colors.redAccent, onTap: () => state.removePlayer(state.selectedPlayerId!)),
            const SizedBox(width: 6),
          ],
          _SmallIconBtn(
            icon: Icons.undo,
            color: state.canUndo ? Colors.white : Colors.white24,
            onTap: state.canUndo ? state.undo : null,
          ),
          const SizedBox(width: 6),
          _SmallIconBtn(
            icon: Icons.redo,
            color: state.canRedo ? Colors.white : Colors.white24,
            onTap: state.canRedo ? state.redo : null,
          ),
          const SizedBox(width: 6),
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
