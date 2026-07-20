import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/player_icon.dart';
import '../models/player_photo.dart';
import '../models/sport_formation.dart';
import '../models/sport_theme.dart';
import '../models/court_layout.dart';
import '../models/sport_type.dart';
import '../painters/ball_painter.dart';
import '../painters/badminton_court_painter.dart';
import '../painters/baseball_court_painter.dart';
import '../painters/basketball_court_painter.dart';
import '../painters/beach_tennis_court_painter.dart';
import '../painters/field_hockey_court_painter.dart';
import '../painters/footvolley_court_painter.dart';
import '../painters/handball_court_painter.dart';
import '../painters/pickleball_court_painter.dart';
import '../painters/rugby_court_painter.dart';
import '../painters/sepak_takraw_court_painter.dart';
import '../painters/soccer_court_painter.dart';
import '../painters/table_tennis_court_painter.dart';
import '../painters/tennis_court_painter.dart';
import '../painters/volleyball_court_painter.dart';
import '../painters/water_polo_court_painter.dart';
import '../models/tactic_meta.dart';
import '../pages/save_tactic_page.dart';
import '../services/ad_service.dart';
import '../services/element_usage_service.dart';
import '../services/pdf_export_service.dart';
import '../services/photo_library_service.dart';
import '../state/tactics_state.dart';
import '../ui_constants.dart';
import 'element_import_flow.dart';
import 'line_style_sheet.dart';
import 'marker_shape_clipper.dart';
import 'photo_crop_editor.dart';
import 'photo_import_sheet.dart';
import 'player_icon_widget.dart';
import 'timeline_editor.dart';

/// Tablet (shortestSide >= 600) gets 1.4× sizing for icons/buttons/fonts.
double uiScale(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600 ? 1.4 : 1.0;

/// Confirm dialog asking whether to add another player using a photo that
/// is already on the board. Returns true if the user pressed "Add",
/// false (or cancelled / dismissed) otherwise. Used by both face avatars
/// and custom-element tiles to guard against accidental double-adds.
Future<bool> _confirmAddDuplicate(BuildContext context, int existingCount) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF15303A),
      title: Text('photo_duplicate_title'.tr(),
          style: const TextStyle(color: Colors.white)),
      content: Text(
        'photo_duplicate_msg'.tr(args: ['$existingCount']),
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('cancel'.tr(),
              style: const TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('photo_add_another'.tr(),
              style: const TextStyle(color: Color(0xFF00C2B2))),
        ),
      ],
    ),
  );
  return ok == true;
}

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
    backgroundColor: const Color(0xFF15303A),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => scaledSheet(ctx, _SaveLoadSheet(state: state)),
  );
}

/// Public function to show the soccer pitch appearance sheet (layout + grass
/// colour). Only meaningful for the soccer board.
void showFieldSettingsSheet(BuildContext context, TacticsState state) {
  showModalBottomSheet(
    context: context,
    backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => scaledSheet(ctx, _FieldSettingsSheet(state: state)),
  );
}

class _FieldSettingsSheet extends StatelessWidget {
  final TacticsState state;
  const _FieldSettingsSheet({required this.state});

  static const _types = [
    SoccerFieldType.full,
    SoccerFieldType.half,
    SoccerFieldType.halfLeft,
    SoccerFieldType.halfRight,
    SoccerFieldType.blank,
  ];

  String _typeLabel(SoccerFieldType t) {
    switch (t) {
      case SoccerFieldType.full:
        return 'field_full'.tr();
      case SoccerFieldType.half:
        return 'field_half'.tr();
      case SoccerFieldType.halfLeft:
        return 'field_half_left'.tr();
      case SoccerFieldType.halfRight:
        return 'field_half_right'.tr();
      case SoccerFieldType.blank:
        return 'field_blank'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild on selection so highlights and the live previews stay in sync.
    return Consumer<TacticsState>(
      builder: (context, state, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // ── Field colour ──────────────────────────────────────────
                Text('field_color'.tr(),
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (int i = 0; i < kSoccerTurfs.length; i++) ...[
                      _TurfDot(
                        color: kSoccerTurfs[i].swatch,
                        selected: state.soccerTurfIndex == i,
                        onTap: () => state.setSoccerTurfIndex(i),
                      ),
                      if (i != kSoccerTurfs.length - 1)
                        const SizedBox(width: 12),
                    ],
                  ],
                ),
                const SizedBox(height: 22),
                // ── Field type ────────────────────────────────────────────
                Text('field_type'.tr(),
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final t in _types) ...[
                        SizedBox(
                          width: 88,
                          child: _FieldTypeTile(
                            type: t,
                            turf: state.soccerTurf,
                            label: _typeLabel(t),
                            selected: state.soccerFieldType == t,
                            onTap: () => state.setSoccerFieldType(t),
                          ),
                        ),
                        if (t != _types.last) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TurfDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TurfDot(
      {required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? kAccent : Colors.white24,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

class _FieldTypeTile extends StatelessWidget {
  final SoccerFieldType type;
  final SoccerTurf turf;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FieldTypeTile({
    required this.type,
    required this.turf,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 0.72,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? kAccent : Colors.white24,
                  width: selected ? 3 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomPaint(
                  painter:
                      SoccerCourtPainter(fieldType: type, turf: turf),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: selected ? kAccent : Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Public: show the generic court appearance sheet (surface colour + layout)
/// for non-soccer sports. Soccer keeps its richer [showFieldSettingsSheet].
void showCourtSettingsSheet(BuildContext context, TacticsState state) {
  showModalBottomSheet(
    context: context,
    backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => scaledSheet(ctx, _CourtSettingsSheet(state: state)),
  );
}

String _courtLayoutLabel(CourtLayout l) {
  switch (l) {
    case CourtLayout.full:
      return 'field_full'.tr();
    case CourtLayout.half:
      return 'field_half'.tr();
    case CourtLayout.halfLeft:
      return 'field_half_left'.tr();
    case CourtLayout.halfRight:
      return 'field_half_right'.tr();
    case CourtLayout.blank:
      return 'field_blank'.tr();
  }
}

/// Builds the preview/live painter for a sport's court given a layout + colour.
/// Soccer is handled separately (its own Pitch sheet / SoccerCourtPainter).
CustomPainter courtPainterFor(SportType sport, CourtLayout layout, Color color) {
  switch (sport) {
    case SportType.basketball:
      return BasketballCourtPainter(layout: layout, floor: color);
    case SportType.badminton:
      return BadmintonCourtPainter(layout: layout, surface: color);
    case SportType.tableTennis:
      return TableTennisCourtPainter(layout: layout, surface: color);
    case SportType.tennis:
      return TennisCourtPainter(layout: layout, surface: color);
    case SportType.volleyball:
      return VolleyballCourtPainter(layout: layout, surface: color);
    case SportType.pickleball:
      return PickleballCourtPainter(layout: layout, surface: color);
    case SportType.fieldHockey:
      return FieldHockeyCourtPainter(layout: layout, surface: color);
    case SportType.rugby:
      return RugbyCourtPainter(layout: layout, surface: color);
    case SportType.baseball:
      return BaseballCourtPainter(layout: layout, surface: color);
    case SportType.handball:
      return HandballCourtPainter(layout: layout, surface: color);
    case SportType.waterPolo:
      return WaterPoloCourtPainter(layout: layout, surface: color);
    case SportType.sepakTakraw:
      return SepakTakrawCourtPainter(layout: layout, surface: color);
    case SportType.beachTennis:
      return BeachTennisCourtPainter(layout: layout, surface: color);
    case SportType.footvolley:
      return FootvolleyCourtPainter(layout: layout, surface: color);
    case SportType.soccer:
      return BasketballCourtPainter(layout: layout, floor: color); // unused
  }
}

class _CourtSettingsSheet extends StatelessWidget {
  final TacticsState state;
  const _CourtSettingsSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    return Consumer<TacticsState>(
      builder: (context, state, _) {
        final sport = state.sportType;
        final surfaces = sport.courtSurfaces;
        final layouts = sport.courtLayouts;
        const headerStyle = TextStyle(
            color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (surfaces.length > 1) ...[
                  Text('field_color'.tr(), style: headerStyle),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (int i = 0; i < surfaces.length; i++) ...[
                        _TurfDot(
                          color: surfaces[i].swatch,
                          selected: state.courtColorIndex(sport) == i,
                          onTap: () => state.setCourtColorIndex(sport, i),
                        ),
                        if (i != surfaces.length - 1) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                  const SizedBox(height: 22),
                ],
                if (layouts.length > 1) ...[
                  Text('field_type'.tr(), style: headerStyle),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final l in layouts) ...[
                          SizedBox(
                            width: 88,
                            child: _CourtLayoutTile(
                              painter: courtPainterFor(
                                  sport, l, state.courtColor(sport)),
                              label: _courtLayoutLabel(l),
                              selected: state.courtLayout(sport) == l,
                              onTap: () => state.setCourtLayout(sport, l),
                            ),
                          ),
                          if (l != layouts.last) const SizedBox(width: 10),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CourtLayoutTile extends StatelessWidget {
  final CustomPainter painter;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CourtLayoutTile({
    required this.painter,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 0.72,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? kAccent : Colors.white24,
                  width: selected ? 3 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomPaint(painter: painter),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: selected ? kAccent : Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Public function to share the board — prompts for PNG or PDF format
Future<void> shareBoardImage(BuildContext context, TacticsState state) async {
  final format = await _pickShareFormat(context);
  if (format == null || !context.mounted) return;
  // Returning from the share sheet must not trigger an app-open ad.
  AdService.instance.suppressNextAppOpen();
  final shared = format == 'pdf'
      ? await _sharePdf(context, state)
      : await _sharePng(context, state);
  // Interstitial only after a real share (not a cancel), at this natural break.
  if (shared) AdService.instance.maybeShowInterstitial();
}

Future<String?> _pickShareFormat(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF15303A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => scaledSheet(ctx, SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image_outlined, color: Color(0xFF00C2B2)),
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

Future<bool> _sharePng(BuildContext context, TacticsState state) async {
  state.resetZoom();
  await Future.delayed(const Duration(milliseconds: 200));
  final boundary = boardRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('save_error'.tr())));
    return false;
  }
  try {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return false;
    Directory dir;
    try { dir = await getTemporaryDirectory(); } catch (_) { dir = Directory.systemTemp; }
    final file = File('${dir.path}/${_friendlyFileStem(state)}.png');
    await file.writeAsBytes(bytes.buffer.asUint8List());
    if (!context.mounted) return false;
    try {
      const channel = MethodChannel('com.zach.tacticsboard/share');
      await channel.invokeMethod('shareFile', {'path': file.path});
      return true; // native share sheet presented
    } catch (_) {
      final result =
          await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      return result.status == ShareResultStatus.success;
    }
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('save_error'.tr())));
    return false;
  }
}

Future<bool> _sharePdf(BuildContext context, TacticsState state) async {
  state.resetZoom();
  await Future.delayed(const Duration(milliseconds: 200));
  try {
    // Returns true only when the document was actually shared (not cancelled).
    return await PdfExportService.exportCurrentFrame(
      title: state.currentTacticName?.trim().isNotEmpty == true
          ? state.currentTacticName!.trim()
          : state.sportType.displayName,
      filename: '${_friendlyFileStem(state)}.pdf',
    );
  } catch (e) {
    debugPrint('PDF export error: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('save_error'.tr())),
      );
    }
    return false;
  }
}

/// Public function to clear the board — offers two scopes so a coach can
/// wipe just this play's drawings while keeping the formation, which is the
/// single most common between-plays workflow.
void confirmClearAll(BuildContext context, TacticsState state) {
  final hasStrokes = state.strokes.isNotEmpty;
  showModalBottomSheet(
    context: context,
    backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => scaledSheet(ctx, SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasStrokes)
            ListTile(
              leading: const Icon(Icons.gesture, color: kAccent),
              title: Text('clear_lines'.tr(),
                  style: const TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); state.clearStrokes(); },
            ),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: kDanger),
            title: Text('clear_all'.tr(),
                style: const TextStyle(color: Colors.white)),
            subtitle: Text('clear_board_message'.tr(),
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () { Navigator.pop(ctx); state.clearAll(); },
          ),
          const SizedBox(height: 8),
        ],
      ),
    )),
  );
}

/// Public function to show the add element bottom sheet
void showAddElementSheet(BuildContext context, TacticsState state) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF15303A),
    // Scroll-controlled so the sheet sizes to its content — which varies by
    // sport — instead of being capped at ~50% and forcing an inner scroll.
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
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
    final hasContent = state.players.isNotEmpty || state.strokes.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row: Mode + Add + Clear on the left, Save + Share on the right.
          // The left group sits in a FittedBox(scaleDown) so it shrinks to
          // fit instead of triggering a RenderFlex overflow when the Clear
          // button appears — a single row keeps the toolbar from reflowing
          // onto a second line, and avoids the yellow/black overflow stripes
          // that Apple App Preview reviewers reject.
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ModeSegment(state: state),
                      const SizedBox(width: 6),
                      _AddPlayerBtn(state: state),
                      if (hasContent) ...[
                        const SizedBox(width: 6),
                        _IconBtn(icon: Icons.delete_sweep, onTap: () => confirmClearAll(context, state), color: kDanger),
                      ],
                    ],
                  ),
                ),
              ),
              // Undo / Redo — always reachable, even while only placing
              // players (before any move/stroke exists). Previously these
              // lived in the play-controls bar, which is hidden during setup.
              _IconBtn(
                icon: Icons.undo,
                onTap: state.canUndo ? state.undo : () {},
                color: state.canUndo ? Colors.white : Colors.white24,
              ),
              _IconBtn(
                icon: Icons.redo,
                onTap: state.canRedo ? state.redo : () {},
                color: state.canRedo ? Colors.white : Colors.white24,
              ),
              _IconBtn(icon: Icons.save_outlined, onTap: () => _showSaveLoad(context), color: kAccent),
              // Share moved to the ⋯ menu — keeps this row from over-packing.
            ],
          ),
        ],
      ),
    );
  }

  void _showSaveLoad(BuildContext context) {
    showSaveLoadSheet(context, state);
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
  List<TacticMeta> _metas = [];

  List<String> get _saved => _metas.map((m) => m.name).toList();

  /// Boards bucketed by folder, default folder ('') first then alphabetical.
  List<MapEntry<String, List<TacticMeta>>> get _grouped {
    final byFolder = <String, List<TacticMeta>>{};
    for (final m in _metas) {
      byFolder.putIfAbsent(m.folder, () => []).add(m);
    }
    final keys = byFolder.keys.toList()
      ..sort((a, b) {
        if (a.isEmpty) return -1;
        if (b.isEmpty) return 1;
        return a.compareTo(b);
      });
    return [for (final k in keys) MapEntry(k, byFolder[k]!)];
  }

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    final metas = await widget.state.listSavedTacticMetas();
    if (mounted) setState(() => _metas = metas);
  }

  /// Opens the full-page save form, then persists what it returns.
  Future<void> _openSavePage() async {
    final existing = widget.state.currentTacticName;
    final initial =
        existing == null ? null : await widget.state.readTacticMeta(existing);
    if (!mounted) return;

    final meta = await Navigator.of(context).push<TacticMeta>(
      MaterialPageRoute(
        builder: (_) => SaveTacticPage(
            state: widget.state, initial: initial, knownMetas: _metas),
      ),
    );
    if (meta == null || !mounted) return;

    // Saving under a name that already belongs to a different board replaces
    // it — make the user say so.
    if (meta.name != existing && _saved.contains(meta.name)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: kSurface,
          title: Text('save'.tr(), style: const TextStyle(color: Colors.white)),
          content: Text(meta.name,
              style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('cancel'.tr())),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('confirm'.tr(),
                  style: const TextStyle(color: Color(0xFF00C2B2))),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await widget.state.saveTactics(meta.name, meta: meta);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('${'save_success'.tr()}: ${meta.name}')),
      );
    } catch (e) {
      debugPrint('Save error: $e');
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _renameTactic(String oldName) async {
    final ctrl = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF15303A),
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
            child: Text('confirm'.tr(), style: const TextStyle(color: Color(0xFF00C2B2))),
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
        backgroundColor: const Color(0xFF15303A),
        title: Text('save'.tr(), style: const TextStyle(color: Colors.white)),
        content: Text(name, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('confirm'.tr(), style: const TextStyle(color: Color(0xFF00C2B2))),
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
                const Icon(Icons.save_outlined, color: const Color(0xFF00C2B2), size: 20),
                const SizedBox(width: 8),
                Text('save'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
          ),
          // Save new — opens the full-page form (name / folder / description).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _openSavePage,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text('save'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Saved list, grouped by folder
          if (_metas.isNotEmpty) ...[
            const Divider(color: Colors.white12),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text('load'.tr(), style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final entry in _grouped) ...[
                    _folderHeader(entry.key, entry.value.length),
                    for (final meta in entry.value) _tacticTile(meta),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _folderHeader(String folder, int count) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Row(
          children: [
            const Icon(Icons.folder_outlined, color: Colors.white38, size: 16),
            const SizedBox(width: 6),
            Text(folder.isEmpty ? 'folder_default'.tr() : folder,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Text('$count',
                style: const TextStyle(color: Colors.white30, fontSize: 12)),
          ],
        ),
      );

  Widget _tacticTile(TacticMeta meta) {
    final name = meta.name;
    return ListTile(
      dense: true,
      leading: const Icon(Icons.description, color: Colors.white38, size: 20),
      title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: meta.description.isEmpty
          ? null
          : Text(meta.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
            icon: const Icon(Icons.save_as_outlined, color: Color(0xFF00C2B2), size: 20),
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
            selected: !state.isDrawingMode && !state.multiSelectMode,
            onTap: state.isAnimating
                ? null
                : () {
                    state.setMultiSelectMode(false);
                    state.setDrawingMode(false);
                  },
          ),
          _SegTab(
            icon: Icons.edit,
            label: 'mode_draw'.tr(),
            selected: state.isDrawingMode,
            onTap: state.isAnimating ? null : () => state.setDrawingMode(true),
          ),
          _SegTab(
            icon: Icons.select_all,
            label: 'mode_select'.tr(),
            selected: state.multiSelectMode,
            onTap: state.isAnimating
                ? null
                : () => state.setMultiSelectMode(!state.multiSelectMode),
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
          color: selected ? kAccent : Colors.transparent,
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
      backgroundColor: const Color(0xFF15303A),
      // Scroll-controlled so the sheet sizes to its content — which varies by
      // sport — instead of being capped at ~50% and forcing an inner scroll.
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
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
  // My-Teams photo library is collapsed by default — it's rarely needed for
  // a quick add and keeps the sheet short. Tap the header to expand.
  bool _showPhotos = false;
  final _scrollController = ScrollController();
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

  /// Long-press-drag drop variant of `_addOneTeamPlayer` — places one
  /// numbered player on [team] at the user's exact canvas-local position.
  void _addOneTeamPlayerAt(PlayerTeam team, Offset local) {
    int max = 0;
    for (final p in state.players.where((p) => p.team == team)) {
      final n = int.tryParse(p.label) ?? 0;
      if (n > max) max = n;
    }
    state.addPlayer(PlayerIcon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: '${max + 1}',
      team: team,
      position: local,
    ));
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

  /// Build the unified list of orderable marker / neutral-player entries.
  /// Their order in the inline row vs. the More section is decided
  /// dynamically by `ElementUsageService.recentCount` — frequently-used
  /// pieces bubble to the front, rarely-used ones get tucked away.
  List<_MarkerEntry> _buildMarkerEntries() {
    Widget shapeGlyph(MarkerShape shape, Color color) => SizedBox(
          width: 28,
          height: 28,
          child: CustomPaint(painter: MarkerPainter(shape: shape, color: color)),
        );
    Widget genderGlyph(PlayerGender g) => SizedBox(
          width: 28,
          height: 28,
          child: CustomPaint(
            painter: TopDownPlayerPainter(
              color: const Color(0xFF616161),
              borderColor: Colors.white,
              borderWidth: 2,
              gender: g,
            ),
          ),
        );

    _MarkerEntry shapeEntry(
      String key,
      String label,
      MarkerShape shape,
      Color color,
      int order, {
      String labelText = '',
    }) {
      return _MarkerEntry(
        key: key,
        label: label,
        glyph: shapeGlyph(shape, color),
        defaultOrder: order,
        onTap: () {
          _addMarker(shape, color, label: labelText);
          ElementUsageService.instance.recordUse(key);
        },
        onDropAt: (globalPos) => _placeAtDropPos(globalPos, (local) {
          state.addPlayer(PlayerIcon(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            label: labelText,
            team: PlayerTeam.neutral,
            markerShape: shape,
            customColor: color,
            position: local,
          ));
          ElementUsageService.instance.recordUse(key);
        }),
      );
    }

    _MarkerEntry genderEntry(String key, String label, PlayerGender g, int order) {
      return _MarkerEntry(
        key: key,
        label: label,
        glyph: genderGlyph(g),
        defaultOrder: order,
        onTap: () {
          final c = state.canvasSize;
          state.addPlayer(PlayerIcon(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            label: '',
            team: PlayerTeam.neutral,
            position: Offset(c.width * 0.5, state.spawnY(PlayerTeam.neutral)),
            gender: g,
          ));
          ElementUsageService.instance.recordUse(key);
          Navigator.pop(sheetCtx);
        },
        onDropAt: (globalPos) => _placeAtDropPos(globalPos, (local) {
          state.addPlayer(PlayerIcon(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            label: '',
            team: PlayerTeam.neutral,
            position: local,
            gender: g,
          ));
          ElementUsageService.instance.recordUse(key);
        }),
      );
    }

    return [
      shapeEntry('marker_circle', '○', MarkerShape.circle, Colors.amber, 0),
      shapeEntry('marker_square', '□', MarkerShape.square, Colors.teal, 1),
      shapeEntry('marker_triangle', '△', MarkerShape.triangle, Colors.orange, 2),
      shapeEntry('marker_diamond', '◇', MarkerShape.diamond, Colors.purple, 3),
      genderEntry('neutral_male', 'neutral_male'.tr(), PlayerGender.male, 4),
      genderEntry('neutral_female', 'neutral_female'.tr(), PlayerGender.female, 5),
      shapeEntry('marker_cone', 'marker_cone'.tr(), MarkerShape.cone, Colors.orange, 6),
      shapeEntry('marker_text', 'marker_text'.tr(), MarkerShape.text, Colors.blueGrey, 7, labelText: 'T'),
      shapeEntry('marker_zone', 'marker_zone'.tr(), MarkerShape.zone, Colors.yellow, 8),
      shapeEntry('marker_referee', 'marker_referee'.tr(), MarkerShape.referee, Colors.black, 9),
      shapeEntry('marker_coach', 'marker_coach'.tr(), MarkerShape.coach, const Color(0xFF37474F), 10),
      shapeEntry('marker_ladder', 'marker_ladder'.tr(), MarkerShape.ladder, Colors.lime, 11),
      shapeEntry('marker_hurdle', 'marker_hurdle'.tr(), MarkerShape.hurdle, Colors.red, 12),
      shapeEntry('marker_arrow', 'marker_arrow'.tr(), MarkerShape.arrowMark, Colors.green, 13),
    ];
  }

  /// Returns the markers ordered by 3-day usage (DESC), tied items by
  /// their default order. Caller gets one flat list; usually we slice
  /// the first N for the inline row and the rest go into "More".
  List<_MarkerEntry> _sortedMarkerEntries() {
    final entries = _buildMarkerEntries();
    entries.sort((a, b) {
      final ca = ElementUsageService.instance.recentCount(a.key);
      final cb = ElementUsageService.instance.recentCount(b.key);
      if (ca != cb) return cb.compareTo(ca);
      return a.defaultOrder.compareTo(b.defaultOrder);
    });
    return entries;
  }

  /// Number of marker tiles shown in the always-visible inline row. The
  /// rest are tucked into the "More" expansion.
  static const int _inlineMarkerCount = 4;

  Widget _buildMarkerTile(_MarkerEntry e) {
    return Padding(
      key: ValueKey('marker_${e.key}'),
      padding: const EdgeInsets.only(right: 8),
      child: _DraggableMarkerCard(
        label: e.label,
        onTap: e.onTap,
        onDropAt: e.onDropAt,
        child: e.glyph,
      ),
    );
  }

  /// Drop a custom-element marker (user-uploaded photo, with the shape the
  /// user chose at import time) onto the board as a neutral non-team icon.
  /// Always preserves the chosen shape (including circle) so the renderer
  /// dispatches to ShapedPhotoMarker, which knows how to look up element
  /// photos. Downgrading circle → none routed it through PhotoPlayerShape
  /// whose lookup only finds face photos.
  Future<void> _addElementPhoto(PlayerPhoto photo) async {
    final existing = state.players.where((p) => p.photoId == photo.id).length;
    if (existing > 0) {
      final ok = await _confirmAddDuplicate(context, existing);
      if (!ok) return;
    }
    if (!mounted) return;
    final c = state.canvasSize;
    final shape = photo.markerShapeIndex == null
        ? MarkerShape.circle
        : MarkerShape.values[photo.markerShapeIndex!];
    state.addPlayer(PlayerIcon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: '',
      team: PlayerTeam.neutral,
      photoId: photo.id,
      markerShape: shape,
      position: Offset(c.width * 0.5, state.spawnY(PlayerTeam.neutral)),
    ));
    PhotoLibraryService.instance.recordElementUse(photo.id);
    Navigator.of(sheetCtx).maybePop();
  }

  /// Drag-drop handler for custom elements — places the marker at the
  /// user's exact drop point if it lands on the board, otherwise no-op.
  Future<void> _onElementDroppedOutside(PlayerPhoto photo, Offset globalPos) async {
    final existing = state.players.where((p) => p.photoId == photo.id).length;
    if (existing > 0) {
      final ok = await _confirmAddDuplicate(context, existing);
      if (!ok) return;
    }
    if (!mounted) return;
    final shape = photo.markerShapeIndex == null
        ? MarkerShape.circle
        : MarkerShape.values[photo.markerShapeIndex!];
    _placeAtDropPos(globalPos, (local) {
      state.addPlayer(PlayerIcon(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: '',
        team: PlayerTeam.neutral,
        photoId: photo.id,
        markerShape: shape,
        position: local,
      ));
      PhotoLibraryService.instance.recordElementUse(photo.id);
    });
  }

  /// Generic drop adapter — converts a global drop point to a canvas-local
  /// position (clamped to bounds) and runs the placement callback if the
  /// drop landed on the board. Closes the sheet on success.
  void _placeAtDropPos(Offset globalPos, void Function(Offset) place) {
    final ro = boardRepaintKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.attached) return;
    final localPos = ro.globalToLocal(globalPos);
    final size = ro.size;
    if (localPos.dx < 0 || localPos.dy < 0) return;
    if (localPos.dx > size.width || localPos.dy > size.height) return;
    final clamped = Offset(
      localPos.dx.clamp(24.0, size.width - 24.0),
      localPos.dy.clamp(24.0, size.height - 24.0),
    );
    place(clamped);
    HapticFeedback.lightImpact();
    Navigator.of(sheetCtx).maybePop();
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
                    _DraggableMarkerCard(
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
                      onDropAt: (globalPos) => _placeAtDropPos(globalPos, (local) {
                        state.addPlayer(PlayerIcon(
                          id: DateTime.now().microsecondsSinceEpoch.toString(),
                          label: '',
                          team: PlayerTeam.neutral,
                          sportType: state.sportType,
                          position: local,
                        ));
                      }),
                    ),
                    const SizedBox(width: 8),
                    if (isTeamSport) ...[
                      _DraggableMarkerCard(
                        label: 'team_home'.tr(),
                        child: _QuickAddTeamGlyph(team: PlayerTeam.home),
                        onTap: () => _addOneTeamPlayer(PlayerTeam.home),
                        onDropAt: (globalPos) => _placeAtDropPos(
                          globalPos,
                          (local) => _addOneTeamPlayerAt(PlayerTeam.home, local),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _DraggableMarkerCard(
                        label: 'team_away'.tr(),
                        child: _QuickAddTeamGlyph(team: PlayerTeam.away),
                        onTap: () => _addOneTeamPlayer(PlayerTeam.away),
                        onDropAt: (globalPos) => _placeAtDropPos(
                          globalPos,
                          (local) => _addOneTeamPlayerAt(PlayerTeam.away, local),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Dynamic markers — sorted by 3-day usage so frequently
                    // used pieces stay visible and the rest collapse into
                    // "More". ListenableBuilder rebuilds the row whenever
                    // a new use is recorded so promotion happens live.
                    ListenableBuilder(
                      listenable: ElementUsageService.instance,
                      builder: (context, _) {
                        final sorted = _sortedMarkerEntries();
                        final inline = sorted.take(_inlineMarkerCount).toList();
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [for (final e in inline) _buildMarkerTile(e)],
                        );
                      },
                    ),
                    // Custom-element tiles (live) inline with the standard
                    // marker shapes so users see all available pieces in
                    // one row instead of a separate section below.
                    _CustomElementsInline(
                      onTap: _addElementPhoto,
                      onDropOutsideTarget: _onElementDroppedOutside,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _MarkerCard(
                        label: '+',
                        child: SizedBox(
                          width: 28, height: 28,
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Colors.white70,
                            size: 22,
                          ),
                        ),
                        onTap: () => ElementImportFlow.show(context),
                      ),
                    ),
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
            // Collapsed-by-default "More" — holds the markers that didn't
            // make the inline row. Re-sorted by usage on every open so the
            // promotion order stays consistent inside and outside.
            if (_showMore)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ListenableBuilder(
                    listenable: ElementUsageService.instance,
                    builder: (context, _) {
                      final rest = _sortedMarkerEntries()
                          .skip(_inlineMarkerCount)
                          .toList();
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [for (final e in rest) _buildMarkerTile(e)],
                      );
                    },
                  ),
                ),
              ),
            const Divider(color: Colors.white12),
            // Collapsible "My Teams" — expanded only on demand.
            GestureDetector(
              onTap: () => setState(() => _showPhotos = !_showPhotos),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline, color: Colors.white60, size: 18),
                    const SizedBox(width: 8),
                    Text('photos_label'.tr(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const Spacer(),
                    Icon(_showPhotos ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white54),
                  ],
                ),
              ),
            ),
            if (_showPhotos)
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

  TacticsState get state => widget.state;

  /// Opens a roomy management dialog for the current team's roster — each
  /// photo is shown larger with explicit delete and crop-adjust buttons.
  /// The caller passes the *derived* active group id (not raw
  /// `_selectedGroupId`) so the dialog scopes correctly even before the
  /// user has explicitly tapped a tab.
  void _openManageDialog(
    BuildContext context,
    List<PlayerPhoto> initial,
    String? activeId,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _PhotosManageDialog(
        photos: initial,
        groupId: activeId,
      ),
    );
  }

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
    final n = photos.length;
    final left = c.width * 0.12;
    final right = c.width * 0.88;
    final span = right - left;
    final cx = c.width * 0.5;
    final positions = <Offset>[
      for (int i = 0; i < n; i++)
        Offset(n == 1 ? cx : left + span * i / (n - 1), spawnY),
    ];
    _placePhotoRow(photos, positions);
    HapticFeedback.lightImpact();
    Navigator.of(widget.sheetCtx).maybePop();
  }

  /// Long-press-drag variant of `_addAllInGroup`: lays the photos out in
  /// a ring around the user's drop point on the board (clamped per-player
  /// to canvas bounds). Ring radius scales with team size so 4 people
  /// huddle close and 11 people get a roomier circle. First photo lands
  /// at the top of the ring (12 o'clock) and the rest go clockwise.
  void _addAllInGroupAt(List<PlayerPhoto> photos, Offset globalDropPos) {
    if (photos.isEmpty) return;
    final ro = boardRepaintKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.attached) return;
    final localPos = ro.globalToLocal(globalDropPos);
    final size = ro.size;
    if (localPos.dx < 0 || localPos.dy < 0 ||
        localPos.dx > size.width || localPos.dy > size.height) {
      return;
    }
    final n = photos.length;
    // Pick a radius that keeps adjacent markers ~50 px apart along the
    // arc — circumference 2πr ≈ n × 50 → r ≈ n × 8. Floor it to a
    // visible minimum and cap so the ring stays inside the board.
    final maxRadius =
        (math.min(size.width, size.height) / 2 - 30).clamp(40.0, 200.0);
    final radius = (n <= 1)
        ? 0.0
        : (n * 8.0).clamp(50.0, maxRadius).toDouble();
    final positions = <Offset>[
      for (int i = 0; i < n; i++) _ringPoint(localPos, radius, i, n, size),
    ];
    _placePhotoRow(photos, positions);
    HapticFeedback.lightImpact();
    Navigator.of(widget.sheetCtx).maybePop();
  }

  Offset _ringPoint(Offset center, double radius, int i, int n, Size canvas) {
    if (n == 1 || radius == 0.0) {
      return Offset(
        center.dx.clamp(24.0, canvas.width - 24.0),
        center.dy.clamp(24.0, canvas.height - 24.0),
      );
    }
    final angle = 2 * math.pi * i / n - math.pi / 2; // start at top
    return Offset(
      (center.dx + radius * math.cos(angle)).clamp(24.0, canvas.width - 24.0),
      (center.dy + radius * math.sin(angle)).clamp(24.0, canvas.height - 24.0),
    );
  }

  /// Shared placement: stamps each photo as a numbered player on the
  /// current team at the supplied positions.
  void _placePhotoRow(List<PlayerPhoto> photos, List<Offset> positions) {
    // Photo-avatar players don't get jersey numbers by default — the face
    // already identifies them. A label is added only when a *second* (or
    // later) instance of the same photo lands on the board, so the user
    // can tell duplicates apart. addPlayer mutates the players list
    // synchronously, so reading the dup count inside the loop reflects
    // earlier iterations of this batch.
    final addedIds = <String>[];
    for (int i = 0; i < photos.length; i++) {
      final dup =
          state.players.where((p) => p.photoId == photos[i].id).length;
      final id = '${DateTime.now().microsecondsSinceEpoch}_$i';
      state.addPlayer(PlayerIcon(
        id: id,
        label: dup == 0 ? '' : '${dup + 1}',
        team: _team,
        position: positions[i],
        photoId: photos[i].id,
      ));
      addedIds.add(id);
    }
    // Group-add: leave the whole batch multi-selected so the user can
    // drag the cluster into place. Single-add paths (drop-one) keep the
    // default single-select behaviour from addPlayer.
    if (addedIds.length > 1) {
      state.enterMultiSelectWith(addedIds);
    }
  }

  /// User finished a long-press drag whose drop wasn't claimed by a
  /// DragTarget (the modal sheet's barrier always intercepts hits, so this
  /// is the normal path). If the global drop point is over the board, pop
  /// the sheet and add a player at that exact spot.
  Future<void> _onDropOutsideTarget(PlayerPhoto photo, Offset globalPos) async {
    final ro = boardRepaintKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.attached) return;
    final localPos = ro.globalToLocal(globalPos);
    final size = ro.size;
    if (localPos.dx < 0 || localPos.dy < 0) return;
    if (localPos.dx > size.width || localPos.dy > size.height) return;
    final existing = state.players.where((p) => p.photoId == photo.id).length;
    if (existing > 0) {
      final ok = await _confirmAddDuplicate(context, existing);
      if (!ok) return;
    }
    if (!mounted) return;
    final clamped = Offset(
      localPos.dx.clamp(24.0, size.width - 24.0),
      localPos.dy.clamp(24.0, size.height - 24.0),
    );
    state.addPlayer(PlayerIcon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: existing == 0 ? '' : '${existing + 1}',
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
          backgroundColor: const Color(0xFF15303A),
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
                  style: const TextStyle(color: Color(0xFF00C2B2))),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    final c = state.canvasSize;
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
      label: existing == 0 ? '' : '${existing + 1}',
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
        backgroundColor: const Color(0xFF15303A),
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
        backgroundColor: const Color(0xFF15303A),
        title: Text('photo_group_name'.tr(), style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'photo_group_name'.tr(),
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C2B2))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr(), style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop([controller.text]),
            child: Text('confirm'.tr(), style: const TextStyle(color: Color(0xFF00C2B2))),
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
      backgroundColor: const Color(0xFF15303A),
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
          backgroundColor: const Color(0xFF15303A),
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
                                editing: false,
                                onTap: () => _openManageDialog(context, photos, activeId),
                              ),
                              const SizedBox(width: 8),
                              _AddAllTile(
                                count: photos.length,
                                onTap: () => _addAllInGroup(photos),
                                onDropAt: (globalPos) =>
                                    _addAllInGroupAt(photos, globalPos),
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
                                onTap: (tapPos) => _addPlayerWithPhoto(photo, tapPos),
                                onDropOutsideTarget: (globalPos) =>
                                    _onDropOutsideTarget(photo, globalPos),
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
              ? const Color(0xFF00C2B2).withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF00C2B2)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF00C2B2) : Colors.white70,
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

/// Drag payload for a custom-element tile — the receiving canvas needs the
/// photo + the user-chosen shape so it can clip the avatar correctly.
class ElementDragData {
  final PlayerPhoto photo;
  final String? path;
  const ElementDragData({required this.photo, this.path});
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
    // Re-resolve when either the photo identity changes (state recycled
    // after a delete) or the filename changes (overwriteBytes rotates the
    // filename to bust Flutter's FileImage cache).
    if (oldWidget.photo.id != widget.photo.id ||
        oldWidget.photo.filename != widget.photo.filename) {
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

/// Strip of user-defined custom-element markers (kind=element) plus a
/// "+ 自定义" tile that picks a photo, opens the crop dialog, and saves
/// the result as a new element. Tapping a tile drops a neutral marker
/// using that photo onto the board.
/// Inline custom-element tiles for the markers row — same _MarkerCard
/// chrome as the standard ○ □ △ ◇ shapes so user-imported elements blend
/// in. Tap = quick add at sheet centre; long-press = drag to a precise
/// drop point on the board.
class _CustomElementsInline extends StatelessWidget {
  final void Function(PlayerPhoto) onTap;
  /// Drop handler invoked when the user releases a long-press drag whose
  /// drop wasn't claimed by a DragTarget — typically because the modal
  /// sheet's barrier intercepts. Caller decides whether the drop landed on
  /// the board area and handles placement.
  final void Function(PlayerPhoto, Offset)? onDropOutsideTarget;
  const _CustomElementsInline({required this.onTap, this.onDropOutsideTarget});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PhotoLibraryService.instance,
      builder: (context, _) {
        return FutureBuilder<List<PlayerPhoto>>(
          future: PhotoLibraryService.instance.listElements(),
          builder: (context, snap) {
            final elements = snap.data ?? const <PlayerPhoto>[];
            if (elements.isEmpty) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final e in elements)
                  Padding(
                    key: ValueKey('elem_pad_${e.id}'),
                    padding: const EdgeInsets.only(right: 8),
                    child: _DraggableElementTile(
                      key: ValueKey(e.id),
                      photo: e,
                      onTap: () => onTap(e),
                      onDropOutsideTarget: (pos) =>
                          onDropOutsideTarget?.call(e, pos),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Tile + LongPressDraggable wrapper. Tap fires onTap (quick add); a
/// long-press starts a drag whose feedback is the shape-clipped photo
/// scaled up slightly with a glow.
class _DraggableElementTile extends StatefulWidget {
  final PlayerPhoto photo;
  final VoidCallback onTap;
  final void Function(Offset globalDropPos)? onDropOutsideTarget;
  const _DraggableElementTile({
    super.key,
    required this.photo,
    required this.onTap,
    this.onDropOutsideTarget,
  });

  @override
  State<_DraggableElementTile> createState() => _DraggableElementTileState();
}

class _DraggableElementTileState extends State<_DraggableElementTile> {
  String? _path;

  @override
  void initState() {
    super.initState();
    _resolve();
    PhotoLibraryService.instance.addListener(_onLibraryChanged);
  }

  @override
  void dispose() {
    PhotoLibraryService.instance.removeListener(_onLibraryChanged);
    super.dispose();
  }

  void _onLibraryChanged() {
    if (mounted) _resolve();
  }

  @override
  void didUpdateWidget(_DraggableElementTile old) {
    super.didUpdateWidget(old);
    if (old.photo.filename != widget.photo.filename) {
      setState(() => _path = null);
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final p = await PhotoLibraryService.instance.resolvePath(widget.photo);
    if (mounted) setState(() => _path = p);
  }

  MarkerShape get _shape {
    final idx = widget.photo.markerShapeIndex;
    if (idx == null || idx == MarkerShape.circle.index) return MarkerShape.circle;
    return MarkerShape.values[idx];
  }

  @override
  Widget build(BuildContext context) {
    final shape = _shape;
    final tile = _MarkerCard(
      label: '',
      child: SizedBox(
        width: 28, height: 28,
        child: ClipPath(
          clipper: MarkerShapeClipper(shape),
          child: _path != null
              ? Image.file(File(_path!), fit: BoxFit.cover)
              : Container(color: Colors.white12),
        ),
      ),
      onTap: widget.onTap,
    );
    final feedback = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 60, height: 60,
        child: Stack(
          children: [
            ClipPath(
              clipper: MarkerShapeClipper(shape),
              child: _path != null
                  ? Image.file(File(_path!), fit: BoxFit.cover, width: 60, height: 60)
                  : Container(color: Colors.white24),
            ),
            IgnorePointer(
              child: ClipPath(
                clipper: MarkerShapeClipper(shape),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFFD166),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return LongPressDraggable<ElementDragData>(
      data: ElementDragData(photo: widget.photo, path: _path),
      feedback: feedback,
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      onDragEnd: (details) {
        if (details.wasAccepted) return;
        widget.onDropOutsideTarget?.call(details.offset);
      },
      child: tile,
    );
  }
}

class _CustomElementContent extends StatefulWidget {
  final PlayerPhoto photo;
  const _CustomElementContent({super.key, required this.photo});

  @override
  State<_CustomElementContent> createState() => _CustomElementContentState();
}

class _CustomElementContentState extends State<_CustomElementContent> {
  String? _path;

  @override
  void initState() {
    super.initState();
    _resolve();
    PhotoLibraryService.instance.addListener(_onLibraryChanged);
  }

  @override
  void dispose() {
    PhotoLibraryService.instance.removeListener(_onLibraryChanged);
    super.dispose();
  }

  void _onLibraryChanged() {
    if (mounted) _resolve();
  }

  @override
  void didUpdateWidget(_CustomElementContent old) {
    super.didUpdateWidget(old);
    if (old.photo.filename != widget.photo.filename) {
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
    final shapeIdx = widget.photo.markerShapeIndex;
    final shape = (shapeIdx == null || shapeIdx == MarkerShape.circle.index)
        ? MarkerShape.circle
        : MarkerShape.values[shapeIdx];
    return ClipPath(
      clipper: MarkerShapeClipper(shape),
      child: _path != null
          ? Image.file(File(_path!), fit: BoxFit.cover)
          : Container(color: Colors.white12),
    );
  }
}

/// Roomy management dialog for a team's roster — shows every saved photo
/// in a grid with explicit delete + crop-adjust actions next to each. The
/// strip's "edit" tile opens this so users don't fight tiny X badges.
class _PhotosManageDialog extends StatelessWidget {
  final List<PlayerPhoto> photos;
  final String? groupId;
  const _PhotosManageDialog({required this.photos, required this.groupId});

  Future<void> _confirmDelete(BuildContext context, PlayerPhoto photo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF15303A),
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF20424C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_outlined, color: Color(0xFFFFD166)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'photo_manage_title'.tr(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'photo_manage_hint'.tr(),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListenableBuilder(
                  listenable: PhotoLibraryService.instance,
                  builder: (context, _) {
                    return FutureBuilder<List<PlayerPhoto>>(
                      future: PhotoLibraryService.instance.list(),
                      builder: (context, snap) {
                        final all = snap.data ?? photos;
                        final list = groupId == null
                            ? all
                            : all.where((p) => p.groupId == groupId).toList();
                        if (list.isEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          });
                          return const SizedBox.shrink();
                        }
                        return GridView.builder(
                          shrinkWrap: true,
                          itemCount: list.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemBuilder: (context, i) => _ManageTile(
                            key: ValueKey(list[i].id),
                            photo: list[i],
                            onDelete: () => _confirmDelete(context, list[i]),
                            onAdjust: () => PhotoCropEditor.show(
                              context, photoId: list[i].id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManageTile extends StatefulWidget {
  final PlayerPhoto photo;
  final VoidCallback onDelete;
  final VoidCallback onAdjust;
  const _ManageTile({
    super.key,
    required this.photo,
    required this.onDelete,
    required this.onAdjust,
  });

  @override
  State<_ManageTile> createState() => _ManageTileState();
}

class _ManageTileState extends State<_ManageTile> {
  String? _path;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(_ManageTile old) {
    super.didUpdateWidget(old);
    if (old.photo.id != widget.photo.id ||
        old.photo.filename != widget.photo.filename) {
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: widget.onAdjust,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
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
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ManageAction(
              icon: Icons.crop,
              color: const Color(0xFF00C2B2),
              onTap: widget.onAdjust,
            ),
            _ManageAction(
              icon: Icons.delete_outline,
              color: Colors.redAccent,
              onTap: widget.onDelete,
            ),
          ],
        ),
      ],
    );
  }
}

class _ManageAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ManageAction({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
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
  /// Long-press-drag drop handler — receives the global drop position so
  /// the parent can lay the whole roster out centred at the release point.
  final void Function(Offset globalDropPos)? onDropAt;
  const _AddAllTile({
    required this.count,
    required this.onTap,
    this.onDropAt,
  });

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    final tile = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52 * s, height: 52 * s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF00C2B2).withValues(alpha: 0.16),
          border: Border.all(color: const Color(0xFF00C2B2), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_add_outlined,
                color: const Color(0xFF00C2B2), size: 18 * s),
            SizedBox(height: 1 * s),
            Text(
              '+$count',
              style: TextStyle(
                color: const Color(0xFF00C2B2),
                fontSize: 9 * s,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
    if (onDropAt == null) return tile;
    final feedback = Material(
      color: Colors.transparent,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF00C2B2).withValues(alpha: 0.25),
          border: Border.all(color: const Color(0xFF00C2B2), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD166).withValues(alpha: 0.55),
              blurRadius: 14, spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_add,
                color: Color(0xFF00C2B2), size: 22),
            const SizedBox(height: 1),
            Text(
              '+$count',
              style: const TextStyle(
                color: Color(0xFF00C2B2),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
    return LongPressDraggable<Object>(
      data: const Object(),
      feedback: feedback,
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      onDragEnd: (details) {
        if (details.wasAccepted) return;
        onDropAt!(details.offset);
      },
      child: tile,
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
    // All three options append to the existing players. Previously the
    // "both" branch called applyFormation, which clears the board and
    // wiped any individually-added players that were already there —
    // unwanted: a user adding a couple of pieces and then 7v7 expected
    // both groups to end up on the board.
    // Clear any stale multi-select first so addTeamFromFormation's
    // "select just-added" behaviour only ends up with the new players.
    widget.state.clearMultiSelect();
    switch (_teamOption) {
      case _TeamOption.both:
        widget.state.addTeamFromFormation(f, PlayerTeam.home);
        widget.state.addTeamFromFormation(f, PlayerTeam.away);
      case _TeamOption.home:
        widget.state.addTeamFromFormation(f, PlayerTeam.home);
      case _TeamOption.away:
        widget.state.addTeamFromFormation(f, PlayerTeam.away);
    }
    Navigator.pop(widget.sheetCtx);
  }

  /// Long-press-drag variant of `_apply` — applies the formation, then
  /// translates every just-added player so the team's centroid lands at
  /// the user's drop point on the board (clamped per-player to canvas
  /// bounds). For the "both teams" option, both halves are translated by
  /// the same offset so their relative layout is preserved.
  void _applyAtDrop(Offset globalDropPos) {
    if (_selectedFormation == null) return;
    final ro = boardRepaintKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.attached) {
      _apply();
      return;
    }
    final localPos = ro.globalToLocal(globalDropPos);
    final size = ro.size;
    if (localPos.dx < 0 || localPos.dy < 0 ||
        localPos.dx > size.width || localPos.dy > size.height) {
      _apply();
      return;
    }

    final beforeIds = widget.state.players.map((p) => p.id).toSet();
    final f = _selectedFormation!;
    // Same additive-only behaviour as `_apply` — never clear the board.
    // Clear stale multi-select so addTeamFromFormation's auto-select
    // ends up with only the newly-added players.
    widget.state.clearMultiSelect();
    switch (_teamOption) {
      case _TeamOption.both:
        widget.state.addTeamFromFormation(f, PlayerTeam.home);
        widget.state.addTeamFromFormation(f, PlayerTeam.away);
      case _TeamOption.home:
        widget.state.addTeamFromFormation(f, PlayerTeam.home);
      case _TeamOption.away:
        widget.state.addTeamFromFormation(f, PlayerTeam.away);
    }
    final added = widget.state.players
        .where((p) => !beforeIds.contains(p.id))
        .toList();
    if (added.isNotEmpty) {
      double cx = 0, cy = 0;
      for (final p in added) { cx += p.position.dx; cy += p.position.dy; }
      cx /= added.length; cy /= added.length;
      final dx = localPos.dx - cx;
      final dy = localPos.dy - cy;
      for (final p in added) {
        widget.state.movePlayer(
          p.id,
          Offset(
            (p.position.dx + dx).clamp(24.0, size.width - 24.0),
            (p.position.dy + dy).clamp(24.0, size.height - 24.0),
          ),
        );
      }
    }
    HapticFeedback.lightImpact();
    Navigator.of(widget.sheetCtx).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final formations = _formationsForCount;
    // Auto-select if only one formation for this count
    if (_selectedCount != null && formations.length == 1 && _selectedFormation == null) {
      _selectedFormation = formations.first;
    }
    // A single-half pitch shows one goal, so formations add one team attacking
    // it — the "both teams" option doesn't apply. Force single-team selection.
    final halfPitch = widget.state.isSoccerHalfPitch;
    if (halfPitch && _teamOption == _TeamOption.both) {
      _teamOption = _TeamOption.home;
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
                if (!halfPitch) ...[
                  _buildTeamChip('both_teams'.tr(), _TeamOption.both, Colors.purple),
                  const SizedBox(width: 8),
                ],
                _buildTeamChip('team_home'.tr(), _TeamOption.home, const Color(0xFF3A7DFF)),
                const SizedBox(width: 8),
                _buildTeamChip('team_away'.tr(), _TeamOption.away, const Color(0xFFFF5A5F)),
                const Spacer(),
                // Apply tile — same drag UX as the +1 home / +1 away marker
                // cards: tap to apply at the formation's default coordinates,
                // long-press-drag to translate the team(s) so the centroid
                // lands at the drop point.
                _DraggableMarkerCard(
                  label: 'confirm'.tr(),
                  child: const Icon(Icons.groups,
                      color: Color(0xFF4ADE80), size: 26),
                  onTap: _apply,
                  onDropAt: _applyAtDrop,
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
          backgroundColor: const Color(0xFF15303A),
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

/// _MarkerCard with optional long-press drag-to-board. Tap fires onTap
/// (default-position add); long-press starts a drag whose feedback follows
/// the finger, and on release the parent's [onDropAt] decides whether the
/// drop landed on the board.
/// One entry in the dynamic markers row (a shape/marker or neutral player).
/// `_AddPlayerSheetState` builds these and sorts by recent-3-day usage so
/// frequently-used pieces stay visible inline and the rest collapse into
/// the "More" panel.
class _MarkerEntry {
  final String key;
  final String label;
  final Widget glyph;
  final VoidCallback onTap;
  final void Function(Offset globalPos) onDropAt;
  final int defaultOrder;
  const _MarkerEntry({
    required this.key,
    required this.label,
    required this.glyph,
    required this.onTap,
    required this.onDropAt,
    required this.defaultOrder,
  });
}

class _DraggableMarkerCard extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback onTap;
  final void Function(Offset globalPos)? onDropAt;
  const _DraggableMarkerCard({
    required this.label,
    required this.child,
    required this.onTap,
    this.onDropAt,
  });

  @override
  Widget build(BuildContext context) {
    final card = _MarkerCard(label: label, child: child, onTap: onTap);
    if (onDropAt == null) return card;
    final feedback = Material(
      color: Colors.transparent,
      child: Container(
        width: 60, height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD166).withValues(alpha: 0.55),
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
        child: child,
      ),
    );
    return LongPressDraggable<Object>(
      data: const Object(),
      feedback: feedback,
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      onDragEnd: (details) {
        if (details.wasAccepted) return;
        onDropAt!(details.offset);
      },
      child: card,
    );
  }
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
        // Row 1: line style picker + eraser
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Opens the full grid of body × dash × terminator combinations.
                GestureDetector(
                  onTap: () => showLineStyleSheet(context, state),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('line_label'.tr(),
                            style: TextStyle(color: Colors.white70, fontSize: 12 * s)),
                        SizedBox(width: 6 * s),
                        CustomPaint(
                          size: Size(56 * s, 22 * s),
                          painter: LineStylePreviewPainter(
                            shape: state.lineShape,
                            dash: state.strokeStyle,
                            arrow: state.arrowStyle,
                            color: state.strokeColor,
                          ),
                        ),
                        SizedBox(width: 4 * s),
                        Icon(Icons.expand_more, color: Colors.white54, size: 16 * s),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const SizedBox(height: 18, child: VerticalDivider(color: Colors.white24, width: 1)),
                const SizedBox(width: 14),
                // Eraser sub-mode — drag/tap over a stroke to delete it.
                _ToggleChip(
                  label: '⌫ ${'eraser'.tr()}',
                  selected: state.eraserMode,
                  onTap: () => state.setEraserMode(!state.eraserMode),
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
                ...kStrokeColors.map((c) => _ColorDot(
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
          color: selected ? kAccent : Colors.white10,
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
    // Guarantee a ≥44pt hit area even though the glyph stays 24pt — the
    // toolbar buttons were ~36pt, small enough to mis-tap mid-game.
    final hit = (36.0 * s).clamp(44.0, 60.0).toDouble();
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: hit,
        height: hit,
        alignment: Alignment.center,
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
      backgroundColor: const Color(0xFF15303A),
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
          child: Icon(Icons.skip_previous, color: const Color(0xFF00C2B2), size: 22 * s),
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
          child: Icon(Icons.skip_next, color: const Color(0xFF00C2B2), size: 22 * s),
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
    // Listen directly to state — the outer Selector only rebuilds on a
    // handful of properties, but the step indicator, play/stop icon and
    // step-back/forward enabled state all need to track every change
    // (otherwise editing phases in the timeline leaves "0/1" stale here
    // while the timeline scrubber shows the real count).
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Container(
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
      ),
    );
  }
}
