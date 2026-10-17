import 'dart:async' show unawaited;
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/player_icon.dart';
import '../models/player_photo.dart';
import '../models/player_role.dart';
import '../models/sport_formation.dart';
import '../models/court_layout.dart';
import '../models/sport_theme.dart';
import '../models/sport_type.dart';
import '../models/volleyball_rotation.dart';
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
import '../services/review_service.dart';
import '../services/element_usage_service.dart';
import '../services/pdf_export_service.dart';
import '../services/photo_library_service.dart';
import '../services/share_link_service.dart';
import '../services/video_export_service.dart';
import '../state/tactics_state.dart';
import '../ui_constants.dart';
import '../ui/adaptive.dart';
import '../ui/primitives.dart';
import '../ui/tokens.dart';
import 'element_import_flow.dart';
import 'line_style_sheet.dart';
import 'marker_shape_clipper.dart';
import 'photo_crop_editor.dart';
import 'photo_import_sheet.dart';
import 'player_icon_widget.dart';
import 'timeline_editor.dart';
import 'volleyball_rotation_widgets.dart';

/// Tablet (shortestSide >= 600) gets 1.4× sizing for icons/buttons/fonts.
/// Long-press-drag tuning shared by the add-sheet tiles. The stock 500ms hold
/// felt sluggish for a tile whose only other gesture is a tap, and the default
/// anchor pins the feedback's top-left to the grab point — which dropped every
/// element up-left of the finger, since `onDragEnd` reports that same top-left.
/// Centring the feedback on the pointer makes the drop land where it looks.
const Duration kDragHoldDelay = Duration(milliseconds: 180);

DragAnchorStrategy _centredAnchor(double size) =>
    (_, _, _) => Offset(size / 2, size / 2);

Offset _dropCentre(DraggableDetails details, double size) =>
    details.offset + Offset(size / 2, size / 2);

double uiScale(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600 ? 1.4 : 1.0;

/// The diameter of a round button floating on the board — back, pages, menu,
/// zoom, fullscreen. One number, because five places were each writing the
/// same expression and a sixth wrote a different one.
///
/// A phone lands on the 44pt floor whatever the arithmetic says; a tablet
/// gets 53, which is what the corners of a 1366pt screen need to not read as
/// phone chrome that was left where it fell.
double chromeCircle(BuildContext context) =>
    (38 * uiScale(context)).clamp(T.tap, 60.0).toDouble();

/// The diameter of a round button inside the two docked capsules.
///
/// A phone keeps the 44pt floor. A tablet's capsule is the only chrome on a
/// 1366pt screen and at 44 it read as a phone's toolbar nobody had looked at
/// again; 56 is what the width can carry with the four tools keeping their
/// words.
double barButton(BuildContext context) =>
    (T.tap * uiScale(context)).clamp(T.tap, 56.0).toDouble();

/// Whether the tool capsule has room for zoom and fullscreen as well.
///
/// With them in, the bar holds four tools, undo, redo, the two of them and
/// two hairlines; the tools are Flexible and shrink to fit, and on a 320pt
/// phone that left each of them 17pt wide with a 20pt icon sticking out of
/// both sides. The tools keep 35pt from 390pt up — the iPhone 16 and
/// everything wider — and below that the pair goes back to floating on the
/// board, where it costs no width. Read off the screen rather than the
/// bar's own box, because the board has to make the same call to know
/// whether to show the floating pair.
bool viewButtonsInBar(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  // A phone turned sideways has no capsule at all — its tools are a rail
  // down the right — so the pair stays on the board there, whatever the
  // width. (Same two tests as the home page's isLandscape / isTablet.)
  if (size.shortestSide < 600 && size.width > size.height) return false;
  // An upright 11-inch iPad lays the playback capsule and the tool capsule
  // in one row (tightTabletRow), which leaves the tools 390pt: four icons,
  // undo and redo. The pair floats on the board there, as on a narrow
  // phone, and the boards button keeps to the ⋯ menu.
  if (tightTabletRow(context)) return false;
  return size.width >= 390;
}

/// An upright tablet wide enough for the two capsules side by side only
/// once the tools are icons alone: the 11-inch iPad and the 10th
/// generation (834 and 820pt). The 13-inch (1024) holds the view pair and
/// the boards button as well; the mini (744) and Split View stack the
/// capsules as before. The board is bounded by its height upright — the
/// court is twice as tall as it is wide — so the row given back is court.
bool tightTabletRow(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.shortestSide >= 600 &&
      size.height > size.width &&
      size.width >= 760 &&
      size.width < 1000;
}

/// How tall the playback capsule is, so the row that holds it can be that
/// tall too. It used to be a flat 48 — with the buttons sized to the screen
/// the capsule outgrew its own row on a tablet.
double playBarHeight(BuildContext context) =>
    barButton(context) * 1.14 + 10 * uiScale(context) + 4;

/// The hairline between two groups inside a capsule. The tools, the history
/// pair and the board list are three different jobs sitting in one pill, and
/// a gap alone did not say so.
class BarDivider extends StatelessWidget {
  const BarDivider({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: barButton(context) * 0.52,
        // 6, not 8: with zoom and fullscreen in the bar, three of these at
        // 8 put a 320pt phone 4.8px over. The hairline is what separates the
        // groups; the air either side of it is not.
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: T.border,
      );
}

/// Confirm dialog asking whether to add another player using a photo that
/// is already on the board. Returns true if the user pressed "Add",
/// false (or cancelled / dismissed) otherwise. Used by both face avatars
/// and custom-element tiles to guard against accidental double-adds.
Future<bool> _confirmAddDuplicate(BuildContext context, int existingCount) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('photo_duplicate_title'.tr(),
          style: const TextStyle(color: T.text)),
      content: Text(
        'photo_duplicate_msg'.tr(args: ['$existingCount']),
        style: const TextStyle(color: T.textDim),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('cancel'.tr(),
              style: const TextStyle(color: T.textOff)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('photo_add_another'.tr(),
              style: TextStyle(color: T.accent)),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Wraps a bottom-sheet / dialog child so all Text inside scales on tablets.
/// Hardcoded icon/container sizes still need to be multiplied by uiScale(ctx).
/// The widest a panel should be, whatever the screen. Past this a row of
/// controls stops reading as a group and becomes a wall — an iPad in
/// landscape is 1194pt wide, six times what any of these panels needs.
const double kPanelMaxWidth = 620;

/// Constraints for every modal sheet, so on a tablet they open as a centred
/// panel instead of spanning the whole width.
BoxConstraints sheetConstraints(BuildContext ctx) => BoxConstraints(
      maxWidth: kPanelMaxWidth,
      maxHeight: MediaQuery.sizeOf(ctx).height * 0.92,
    );

/// The docked tool capsule may run wider than [kPanelMaxWidth]: it is not a
/// panel of options but one row of seven controls, and on a tablet its
/// buttons are 56pt. Held to 620 the four tools lost their words on the one
/// screen with room to spare for them.
const double kBarMaxWidth = 820;

/// Centres a full-width bar's contents on a wide screen. The bar keeps its
/// background edge to edge; only the controls stop stretching.
Widget centeredPanel(Widget child, {double maxWidth = kPanelMaxWidth}) =>
    Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );

Widget scaledSheet(BuildContext ctx, Widget child) {
  final s = uiScale(ctx);
  if (s == 1.0) return child;
  return MediaQuery(
    data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(s)),
    child: child,
  );
}

/// Whether the board's panels — Add, Timeline, Boards, Share, the ⋯ menu's
/// sheets — open as popovers by the button that opened them. A tablet: a
/// bottom sheet there opened at the bottom centre of a 13-inch screen, far
/// from a Share that was tapped in the top-right corner, and dimmed the
/// board it was about. A phone keeps its bottom sheets.
bool boardPanelsArePopovers(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600;

/// Open a board panel: a bottom sheet on a phone ([TacticalSheet.show]), a
/// popover anchored to [anchor]'s box (or [context]'s) on a tablet. The
/// board stays lit and live under a popover; a tap outside or Esc closes it.
Future<T2?> showBoardPanel<T2>(
  BuildContext context, {
  required WidgetBuilder builder,
  BuildContext? anchor,
  double maxWidth = 460,
}) {
  if (!boardPanelsArePopovers(context)) {
    return TacticalSheet.show<T2>(context, builder: builder);
  }
  // A context as big as the page (a keyboard shortcut's) is no anchor:
  // the panel opens in the middle of the screen instead.
  var rect = anchorRectOf(anchor ?? context);
  if (rect != null && rect.height > MediaQuery.sizeOf(context).height / 2) {
    rect = null;
  }
  // The panel edits the board it was opened from: hand it that board's
  // state, whichever provider the route would otherwise find.
  TacticsState? board;
  try {
    board = Provider.of<TacticsState>(context, listen: false);
  } on ProviderNotFoundException {
    board = null;
  }
  return Navigator.of(context).push<T2>(BoardPopoverRoute<T2>(
    anchor: rect,
    builder: board == null
        ? builder
        : (ctx) => ChangeNotifierProvider<TacticsState>.value(
              value: board!,
              child: Builder(builder: builder),
            ),
    maxWidth: maxWidth,
    capturedThemes:
        InheritedTheme.capture(from: context, to: Navigator.of(context).context),
  ));
}

/// [context]'s box on the screen, or null when it has none.
Rect? anchorRectOf(BuildContext context) {
  final ro = context.findRenderObject();
  if (ro is! RenderBox || !ro.hasSize || !ro.attached) return null;
  return ro.localToGlobal(Offset.zero) & ro.size;
}

/// A panel floating next to the control that opened it, the way iPadOS
/// shows a popover: above the button when there is room (the board's
/// buttons are mostly at its foot), below it otherwise, centred on it and
/// kept on the screen. No dimming barrier — the board is what the panel is
/// about — but a tap outside dismisses it.
class BoardPopoverRoute<T2> extends PopupRoute<T2> {
  final Rect? anchor;
  final WidgetBuilder builder;
  final double maxWidth;
  final CapturedThemes capturedThemes;

  BoardPopoverRoute({
    required this.anchor,
    required this.builder,
    required this.maxWidth,
    required this.capturedThemes,
  });

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'cancel'.tr();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 160);

  /// No barrier. A tap outside the panel closes it AND lands where it was
  /// aimed: with a barrier the ⋯ menu beside an open Add panel took two
  /// taps, one to close the panel and one for the menu, and the board —
  /// which is what the panel is about — could not be touched at all. The
  /// route watches every pointer instead (see [_onPointer]).
  @override
  Iterable<OverlayEntry> createOverlayEntries() =>
      super.createOverlayEntries().skip(1).toList();

  final GlobalKey _panelKey = GlobalKey();

  @override
  void install() {
    super.install();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    super.dispose();
  }

  /// Pointers that went down outside the panel.
  final Set<int> _outside = {};

  /// Closes on the UP of a pointer that went down outside the panel. Not
  /// on the down: a route change cancels every active pointer (Navigator
  /// does that so a tap begun on one page cannot finish on the next), so
  /// closing on the down cancelled the tap on the ⋯ menu and it took a
  /// second one. By the up the menu's tap has fired — and pushed its own
  /// route, which is why this removes itself rather than popping the top.
  void _onPointer(PointerEvent e) {
    if (!isActive) return;
    if (e is PointerDownEvent) {
      final ro = _panelKey.currentContext?.findRenderObject();
      if (ro is RenderBox && ro.hasSize && ro.attached) {
        final box = ro.localToGlobal(Offset.zero) & ro.size;
        if (box.contains(e.position)) return;
      }
      _outside.add(e.pointer);
      return;
    }
    if (e is PointerCancelEvent) {
      _outside.remove(e.pointer);
      return;
    }
    if (e is! PointerUpEvent || !_outside.remove(e.pointer)) return;
    if (isCurrent) {
      navigator?.pop();
    } else {
      navigator?.removeRoute(this);
    }
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final mq = MediaQuery.of(context);
    return CustomSingleChildLayout(
      delegate: _PopoverLayout(
        anchor: anchor,
        padding: mq.padding,
        maxWidth: maxWidth,
      ),
      child: capturedThemes.wrap(
        PopoverScope(
          child: Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              key: _panelKey,
              decoration: BoxDecoration(
                color: T.surface,
                borderRadius: BorderRadius.circular(T.rDialog),
                border: Border.all(color: T.border),
                boxShadow: T.shadowFloat,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(T.rDialog),
                child: Builder(builder: builder),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}

class _PopoverLayout extends SingleChildLayoutDelegate {
  final Rect? anchor;
  final EdgeInsets padding;
  final double maxWidth;
  static const double gap = 8, edge = 12;

  _PopoverLayout(
      {required this.anchor, required this.padding, required this.maxWidth});

  Rect _anchorIn(Size size) =>
      anchor ?? Rect.fromCenter(
          center: size.center(Offset.zero), width: 0, height: 0);

  double _above(Size size) =>
      _anchorIn(size).top - gap - padding.top - edge;
  double _below(Size size) =>
      size.height - _anchorIn(size).bottom - gap - padding.bottom - edge;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final size = constraints.biggest;
    final h = anchor == null
        ? size.height - padding.vertical - edge * 2
        : math.max(_above(size), _below(size));
    return BoxConstraints(
      maxWidth: math.min(maxWidth, size.width - edge * 2),
      maxHeight: math.max(120, h),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size child) {
    final a = _anchorIn(size);
    final x = (a.center.dx - child.width / 2)
        .clamp(edge, math.max(edge, size.width - child.width - edge))
        .toDouble();
    double y;
    if (anchor == null) {
      y = (size.height - child.height) / 2;
    } else if (child.height <= _above(size) || _above(size) >= _below(size)) {
      y = a.top - gap - child.height;
    } else {
      y = a.bottom + gap;
    }
    y = y
        .clamp(padding.top + edge,
            math.max(padding.top + edge, size.height - child.height - edge))
        .toDouble();
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_PopoverLayout old) =>
      old.anchor != anchor || old.padding != padding || old.maxWidth != maxWidth;
}

/// Public function to show save/load bottom sheet
void showSaveLoadSheet(BuildContext context, TacticsState state) {
  if (boardPanelsArePopovers(context)) {
    // The full panel width: a row is a name and five controls, and at the
    // tablet's 1.4x the controls alone took 300pt of a 420pt panel —
    // "Board 1" broke over two lines. Reported off an iPad, 2026-10-16.
    showBoardPanel<void>(context,
        maxWidth: kPanelMaxWidth,
        builder: (ctx) => scaledSheet(ctx, _SaveLoadSheet(state: state)));
    return;
  }
  showModalBottomSheet(
    context: context,
    constraints: sheetConstraints(context),
    backgroundColor: T.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => scaledSheet(ctx, _SaveLoadSheet(state: state)),
  );
}

/// Public function to show the soccer pitch appearance sheet (layout + grass
/// colour). Only meaningful for the soccer board.
void showFieldSettingsSheet(BuildContext context, TacticsState state) {
  showBoardPanel(
    context,
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
        // Handle, background, radius and height cap come from the shared
        // sheet; this is the two choices it offers.
        return TacticalSheet(
          maxHeightFraction: 0.6,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TacticalSheetHeader(title: 'menu_field'.tr()),
                TacticalSectionHeader(label: 'field_color'.tr()),
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
                const SizedBox(height: T.s24),
                TacticalSectionHeader(label: 'field_type'.tr()),
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
      // A ring outside the swatch and a check inside it: the swatch used to
      // get a 3px accent border that changed the colour it was showing.
      child: SizedBox(
        width: T.tap,
        height: T.tap,
        child: Center(
          child: Container(
            width: selected ? 40 : 34,
            height: selected ? 40 : 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: selected ? Border.all(color: T.accent, width: 2) : null,
            ),
            child: Center(
              child: Container(
                width: selected ? 30 : 34,
                height: selected ? 30 : 34,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                    : null,
              ),
            ),
          ),
        ),
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
                borderRadius: T.brSm,
                // 2px teal when chosen, one hairline otherwise — the 3px
                // accent frame was thick enough to change the thumbnail's
                // apparent size as you tapped along the row.
                border: Border.all(
                  color: selected ? T.accent : T.border,
                  width: selected ? 2 : 1,
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
                  color: selected ? T.accent : T.textDim,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        ],
      ),
    );
  }
}

/// Public: show the generic court appearance sheet (surface colour + layout)
/// for non-soccer sports. Soccer keeps its richer [showFieldSettingsSheet].
void showCourtSettingsSheet(BuildContext context, TacticsState state) {
  showBoardPanel(
      context,
    builder: (ctx) => TacticalSheet(
        padding: const EdgeInsets.fromLTRB(0, T.s12, 0, 0),
        child: scaledSheet(ctx, _CourtSettingsSheet(state: state)),
      ));
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
    case CourtLayout.indoor:
      return 'field_indoor'.tr();
    case CourtLayout.hockey5s:
      return 'field_hockey5s'.tr();
    case CourtLayout.nba:
      return 'field_nba'.tr();
    case CourtLayout.ncaa:
      return 'field_ncaa'.tr();
    case CourtLayout.highSchool:
      return 'field_high_school'.tr();
    case CourtLayout.beach:
      return 'field_beach'.tr();
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
            color: T.textDim, fontSize: 13, fontWeight: FontWeight.w600);
        return SafeArea(
          // Scrollable, because the sheet is taller than a small phone once a
          // language needs two lines for a heading — it overflowed its own
          // bottom by 17px on an iPhone SE.
          child: SingleChildScrollView(
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
                      color: T.border,
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
                  color: selected ? T.selectedStroke : T.border,
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
                  color: selected ? T.accentText : T.textDim, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Public function to share the board — prompts for PNG / PDF (/ Video) format
Future<void> shareBoardImage(BuildContext context, TacticsState state) async {
  final format = await _pickShareFormat(context,
      showVideo: state.hasMoves,
      showLineup:
          state.sportType == SportType.volleyball && state.rotation != null);
  if (format == null || !context.mounted) return;
  // Returning from the share sheet must not trigger an app-open ad.
  AdService.instance.suppressNextAppOpen();
  // A share is now underway, so the post-share interstitial has a real chance
  // of being used — start loading it. (It is deliberately not preloaded at
  // launch; see AdService.warmUpInterstitial.)
  AdService.instance.warmUpInterstitial();
  final bool shared;
  switch (format) {
    case 'pdf':
      shared = await _sharePdf(context, state);
    case 'video':
      shared = await _shareVideo(context, state);
    case 'lineup':
      shared = await _shareLineup(context, state);
    case 'link':
      shared = await _shareLink(context, state);
    default:
      shared = await _sharePng(context, state);
  }
  if (shared) {
    // High-satisfaction moment: maybe ask for a rating. When the system
    // prompt was requested, skip the interstitial so the two never stack.
    final askedForReview = await ReviewService.instance.onShareSuccess();
    // Interstitial only after a real share (not a cancel), at this natural break.
    if (!askedForReview) AdService.instance.maybeShowInterstitial();
  }
}

/// Publish the play as a link and share the URL.
///
/// Uploads what the app already renders — an MP4 when the play animates, a PNG
/// when it doesn't — alongside the board JSON, so the page shows the play now
/// and can be re-rendered properly later. Falls back to sharing the file when
/// the upload fails, which at a pitch usually means no signal.
Future<bool> _shareLink(BuildContext context, TacticsState state) async {
  state.resetZoom();
  await Future.delayed(const Duration(milliseconds: 200));
  if (!context.mounted) return false;

  final animated = state.hasMoves;
  final progress = ValueNotifier<double>(0);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: Material(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 30, height: 30,
                child: CircularProgressIndicator(color: kAccent, strokeWidth: 3),
              ),
              const SizedBox(height: 14),
              Text('share_link_working'.tr(),
                  style: const TextStyle(color: T.text, fontSize: 14)),
            ],
          ),
        ),
      ),
    ),
  );

  File? media;
  try {
    if (animated) {
      final path = await VideoExportService.renderToFile(state,
          onProgress: (v) => progress.value = v);
      if (path != null) media = File(path);
    } else {
      final boundary =
          boardRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) {
          Directory dir;
          try { dir = await getTemporaryDirectory(); } catch (_) { dir = Directory.systemTemp; }
          media = File('${dir.path}/${_friendlyFileStem(state)}.png');
          await media.writeAsBytes(bytes.buffer.asUint8List());
        }
      }
    }

    final url = await ShareLinkService.instance.publish(
      sportType: state.sportType.name,
      data: state.toJson(),
      media: media,
      title: state.currentTacticName,
    );

    if (context.mounted) Navigator.of(context).maybePop(); // close progress

    if (url == null) {
      // No link, but the render is in hand — share that instead of nothing.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('share_link_failed'.tr())),
        );
      }
      if (media != null && context.mounted) {
        final result =
            await SharePlus.instance.share(ShareParams(files: [XFile(media.path)]));
        return result.status == ShareResultStatus.success;
      }
      return false;
    }

    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('share_link_copied'.tr())),
    );
    final result = await SharePlus.instance.share(ShareParams(text: url));
    return result.status == ShareResultStatus.success;
  } catch (_) {
    if (context.mounted) {
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('share_link_failed'.tr())),
      );
    }
    return false;
  }
}

/// Render the move animation to an MP4 and share it, with a progress dialog.
Future<bool> _shareVideo(BuildContext context, TacticsState state) async {
  state.resetZoom();
  await Future.delayed(const Duration(milliseconds: 200));
  if (!context.mounted) return false;

  final progress = ValueNotifier<double>(0);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: Material(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('share_video_rendering'.tr(),
                  style: const TextStyle(color: T.text, fontSize: 14)),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: ValueListenableBuilder<double>(
                  valueListenable: progress,
                  builder: (_, v, _) => Column(
                    children: [
                      LinearProgressIndicator(
                          value: v, backgroundColor: T.border, color: kAccent),
                      const SizedBox(height: 6),
                      Text('${(v * 100).round()}%',
                          style: const TextStyle(color: T.textOff, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  bool ok = false;
  try {
    ok = await VideoExportService.exportAndShare(state,
        onProgress: (p) => progress.value = p,
        filename: _friendlyFileStem(state));
  } catch (e) {
    debugPrint('Video export error: $e');
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // close dialog
    progress.dispose();
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('save_error'.tr())));
  }
  return ok;
}

Future<String?> _pickShareFormat(BuildContext context,
    {bool showVideo = false, bool showLineup = false}) {
  return showBoardPanel(
      maxWidth: 360,
      context,
    builder: (ctx) => TacticalSheet(
        padding: const EdgeInsets.fromLTRB(0, T.s12, 0, 0),
        child: scaledSheet(ctx, SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.image_outlined, color: T.accent),
              title: const Text('PNG', style: TextStyle(color: T.text)),
              onTap: () => Navigator.pop(ctx, 'png'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: T.warningIcon),
              title: const Text('PDF', style: TextStyle(color: T.text)),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
            // Video export animates the play; only meaningful when moves exist.
            if (showVideo)
              ListTile(
                leading: const Icon(Icons.videocam_outlined, color: T.info),
                title: Text('share_video'.tr(), style: const TextStyle(color: T.text)),
                subtitle: Text('share_video_hint'.tr(),
                    style: const TextStyle(color: T.textOff, fontSize: 12)),
                onTap: () => Navigator.pop(ctx, 'video'),
              ),
            // A volleyball rotation board can also go out as the paper
            // lineup sheet: zones, serving order, libero, rule set.
            if (showLineup)
              ListTile(
                leading: const Icon(Icons.grid_on_outlined, color: T.warningIcon),
                title: Text('share_lineup'.tr(), style: const TextStyle(color: T.text)),
                subtitle: Text('share_lineup_hint'.tr(),
                    style: const TextStyle(color: T.textOff, fontSize: 12)),
                onTap: () => Navigator.pop(ctx, 'lineup'),
              ),
            const Divider(color: T.border, height: 12),
            // A link opens in any browser — the receiver needs neither the app
            // nor an account, which a PNG in a group chat can't say for a play
            // that moves.
            ListTile(
              leading: Icon(Icons.link, color: kAccent),
              title: Text('share_link'.tr(), style: const TextStyle(color: T.text)),
              subtitle: Text('share_link_hint'.tr(),
                  style: const TextStyle(color: T.textOff, fontSize: 12)),
              onTap: () => Navigator.pop(ctx, 'link'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      )),
      ));
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
    final title = state.currentTacticName?.trim().isNotEmpty == true
        ? state.currentTacticName!.trim()
        : state.sportType.displayName;
    // Returns true only when the document was actually shared (not cancelled).
    if (state.pageCount <= 1) {
      return await PdfExportService.exportCurrentFrame(
        title: title,
        filename: '${_friendlyFileStem(state)}.pdf',
      );
    }
    // Walk the pages, capturing each. The board is the only thing that can
    // draw a page, so the walk happens here where there are frames to wait
    // for, and the coach is put back where they were when it is done.
    final startedOn = state.pageIndex;
    final shots = <Uint8List>[];
    for (var i = 0; i < state.pageCount; i++) {
      state.goToPage(i);
      await Future.delayed(const Duration(milliseconds: 120));
      final png = await PdfExportService.captureBoard();
      if (png != null) shots.add(png);
    }
    state.goToPage(startedOn);
    await Future.delayed(const Duration(milliseconds: 60));
    return await PdfExportService.exportFrames(
      shots,
      title: title,
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

/// The lineup sheet for the board's rotation, as a one-page PDF.
Future<bool> _shareLineup(BuildContext context, TacticsState state) async {
  final s = state.rotation;
  if (s == null) return false;
  try {
    final labels = <String, String>{
      for (final p in state.players)
        if (p.team == s.team && p.role != null) p.role!: p.label,
    };
    final name = state.currentTacticName?.trim();
    return await PdfExportService.exportLineupSheet(
      s,
      labels: labels,
      title: name != null && name.isNotEmpty ? name : null,
      words: LineupSheetStrings(
        heading: 'share_lineup'.tr(),
        team: s.team == PlayerTeam.away ? 'team_away'.tr() : 'team_home'.tr(),
        rotation: 'rotation_number'.tr(namedArgs: {'n': '${s.rotation}'}),
        system: s.system == RotationSystem.fiveOne ? '5-1' : '6-2',
        phase: s.phase == RotationPhase.serve
            ? 'rotation_serve'.tr()
            : 'rotation_receive'.tr(),
        servingOrder: 'lineup_serving_order'.tr(),
        libero: 'rotation_libero'.tr(),
        rules: 'rotation_rules'.tr(),
        subs: 'rotation_subs'.tr(namedArgs: {'n': '${s.rules.substitutions}'}),
        net: 'lineup_net'.tr(),
      ),
      filename: '${_friendlyFileStem(state)}_lineup.pdf',
    );
  } catch (e) {
    debugPrint('Lineup sheet export error: $e');
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
  showBoardPanel(
      maxWidth: 380,
      context,
    builder: (ctx) => TacticalSheet(
        padding: const EdgeInsets.fromLTRB(0, T.s12, 0, 0),
        child: scaledSheet(ctx, SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasStrokes)
              ListTile(
                leading: Icon(Icons.gesture_rounded, color: kAccent),
                title: Text('clear_lines'.tr(),
                    style: const TextStyle(color: T.text)),
                onTap: () { Navigator.pop(ctx); state.clearStrokes(); },
              ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined, color: kDanger),
              title: Text('clear_all'.tr(),
                  style: const TextStyle(color: T.text)),
              subtitle: Text('clear_board_message'.tr(),
                  style: const TextStyle(color: T.textOff, fontSize: 12)),
              onTap: () { Navigator.pop(ctx); state.clearAll(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      )),
      ));
}

/// Public function to show the add element bottom sheet
void showAddElementSheet(BuildContext context, TacticsState state) {
  showBoardPanel(
      context,
    maxWidth: kPanelMaxWidth,
    builder: (ctx) => scaledSheet(ctx, _AddPlayerSheet(state: state, sheetCtx: ctx)),
  );
}

class TacticsToolbar extends StatelessWidget {
  const TacticsToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    // Subscribe to locale so the toolbar rebuilds on a language change.
    final _ = EasyLocalization.of(context)?.currentLocale;
    return Consumer<TacticsState>(
      builder: (context, state, _) => _PrimaryToolbar(state: state),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary toolbar — one docked capsule
//
// It used to be a full-width bar painted the panel colour, carrying a
// segmented control, a pill-shaped Add button, a clear-all, undo, redo and a
// floppy disk, each with its own fill and shadow. Stacked above the play
// controls it read as two navigation bars sitting on the pitch.
//
// Now: one capsule that floats over the board, four tools on the left and
// the two history controls trailing. Clear-all moved into the ⋯ menu — it is
// destructive, rare, and does not belong a thumb's width from Undo.
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryToolbar extends StatelessWidget {
  final TacticsState state;
  const _PrimaryToolbar({required this.state});

  @override
  Widget build(BuildContext context) {
    final drawing = state.isDrawingMode;
    final selecting = state.multiSelectMode;
    // Four labelled tools plus undo, redo and boards do not fit 320pt once
    // the labels are German, French or Vietnamese. Below the threshold the
    // tools keep their icons and drop their words — the icons are the same
    // ones, in the same order, so nothing moves.
    // Whether the labels fit is decided by the room the tools actually get,
    // not by how wide the phone is: on a 402pt phone the four trailing
    // buttons leave 220px for four labelled tools, and guessing from the
    // screen width overflowed it by 87 pixels on a real device.
    final mq = MediaQuery.of(context);
    final roomy = mq.textScaler.scale(13) <= 17;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: T.s16),
      child: centeredPanel(
        maxWidth: kBarMaxWidth,
        Container(
          height: barButton(context) + 16,
          padding: const EdgeInsets.symmetric(horizontal: T.s8),
          decoration: BoxDecoration(
            // The sport's own panel colour, not the app's teal surface: on a
            // blue hockey pitch a teal-green pill was the one thing on the
            // screen that belonged to a different app.
            color: state.sportType.theme.panelColor,
            borderRadius: BorderRadius.circular(T.rLg),
            border: Border.all(color: T.border),
            boxShadow: T.shadowFloat,
          ),
          child: Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    // Four labelled tools need about eight and a half times
                    // a button's own width between them — measured when a
                    // button was 46pt and the threshold 348. A phone keeps
                    // that rule. A tablet measures its words instead: the
                    // ratio on its 1.4x button asked for 517pt and dropped
                    // every word on an iPad mini and in Split View, with
                    // ~90pt per icon to spare.
                    final tablet = uiScale(context) > 1;
                    final words = [
                      'mode_move'.tr(),
                      'mode_draw'.tr(),
                      'mode_select'.tr(),
                      'add_label'.tr(),
                    ];
                    final inline = roomy &&
                        box.maxWidth >=
                            (tablet
                                ? _labelledToolsWidth(context, words)
                                : barButton(context) * 8.4);
                    // A tablet in half Split View (678pt) has ~370pt for
                    // the four, and French or Spanish words beside their
                    // icons want 450-500. Rather than drop the words there,
                    // the word goes UNDER its icon, a step smaller: the bar
                    // is 1.4 buttons tall on a tablet, room for both, and
                    // each tool is then only as wide as its word.
                    final stacked = !inline &&
                        tablet &&
                        roomy &&
                        box.maxWidth >=
                            _labelledToolsWidth(context, words, stacked: true);
                    final wide = inline || stacked;
                    // Each tool is Flexible so the four of them share what
                    // the row has and a long word ellipsises. At their
                    // natural width they simply ran off the end: the label
                    // inside is Flexible, but an unbounded parent gives it
                    // nothing to be flexible about.
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: _Tool(
                          showLabel: wide,
                          stacked: stacked,
                          icon: Icons.open_with_rounded,
                          label: 'mode_move'.tr(),
                          selected: !drawing && !selecting,
                          onTap: state.isAnimating
                              ? null
                              : () {
                                  state.setMultiSelectMode(false);
                                  state.setDrawingMode(false);
                                },
                        )),
                        Flexible(child: _Tool(
                          showLabel: wide,
                          stacked: stacked,
                          icon: Icons.gesture_rounded,
                          label: 'mode_draw'.tr(),
                          selected: drawing,
                          onTap: state.isAnimating
                              ? null
                              : () => state.setDrawingMode(true),
                        )),
                        Flexible(child: _Tool(
                          showLabel: wide,
                          stacked: stacked,
                          icon: Icons.highlight_alt_rounded,
                          label: 'mode_select'.tr(),
                          selected: selecting,
                          onTap: state.isAnimating
                              ? null
                              : () => state.setMultiSelectMode(!selecting),
                        )),
                        // Its own context, so a tablet's popover is
                        // anchored to this button, not to the whole row.
                        Flexible(child: Builder(builder: (btn) => _Tool(
                          showLabel: wide,
                          stacked: stacked,
                          icon: Icons.add_rounded,
                          label: 'add_label'.tr(),
                          selected: false,
                          onTap: () => _AddPlayerBtn.showAddSheet(btn, state),
                        ))),
                      ],
                    );
                  },
                ),
              ),
              // History, trailing, in its own group.
              //
              // Full white, like the tools: the bar's own hairlines say which
              // group a control belongs to, so dimming no longer has to, and
              // a dimmed undo reads as an undo you cannot press.
              const BarDivider(),
              TacticalIconButton(
                icon: Icons.undo_rounded,
                onTap: state.canUndo ? state.undo : null,
                color: T.text,
                semanticLabel: 'undo'.tr(),
              ),
              TacticalIconButton(
                icon: Icons.redo_rounded,
                onTap: state.canRedo ? state.redo : null,
                color: T.text,
                semanticLabel: 'redo'.tr(),
              ),
              // The view: zoom and fullscreen. They were circles floating
              // on the board — first in the bottom corner, on the corner
              // flag; then in the top row, against the island — and they
              // are controls, so they belong in the bar with the others.
              // Where the bar is wide enough: see viewButtonsInBar.
              if (viewButtonsInBar(context)) ...[
                const BarDivider(),
                Selector<TacticsState, bool>(
                  selector: (_, s) => s.zoomMode,
                  builder: (context, on, _) => TacticalIconButton(
                    icon: Icons.pinch,
                    onTap: state.toggleZoomMode,
                    active: on,
                    color: T.text,
                    semanticLabel: 'zoom'.tr(),
                  ),
                ),
                TacticalIconButton(
                  icon: Icons.fullscreen,
                  onTap: state.toggleToolbar,
                  color: T.text,
                  semanticLabel: 'fullscreen'.tr(),
                ),
              ],
              // Not a floppy disk: this opens the saved boards, and nothing
              // in the app autosaves, so it is a library rather than a save.
              // It is also in the ⋯ menu, which is why it is the one that
              // steps aside: with the view buttons in the bar a phone's
              // width holds everything else and not this.
              if (mq.size.width >= 460 && !tightTabletRow(context)) ...[
                const BarDivider(),
                Builder(builder: (btn) => TacticalIconButton(
                  icon: Icons.folder_outlined,
                  onTap: () => showSaveLoadSheet(btn, state),
                  color: T.text,
                  semanticLabel: 'boards'.tr(),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// What four labelled [_Tool]s take side by side: padding, icon, gap and
/// the word at its selected (bold) weight.
///
/// [stacked]: the word under its icon at [_kStackedLabelSize] instead, so a
/// tool is as wide as the wider of the two plus its padding.
double _labelledToolsWidth(BuildContext context, List<String> labels,
    {bool stacked = false}) {
  final dim = barButton(context);
  final scaler = MediaQuery.textScalerOf(context);
  var w = 0.0;
  for (final l in labels) {
    final tp = TextPainter(
      text: TextSpan(
          text: l,
          // In the font the label is drawn in, not the engine's default.
          style: DefaultTextStyle.of(context).style.copyWith(
              fontSize: stacked ? _kStackedLabelSize : 13,
              fontWeight: FontWeight.w700)),
      maxLines: 1,
      textScaler: scaler,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    w = math.max(
        w,
        stacked
            ? 12 + math.max(tp.width, dim * 0.45)
            : 22 + dim * 0.45 + 6 + tp.width);
    tp.dispose();
  }
  // Four times the widest: the tools are Flexible, so each gets a quarter
  // of the row, and a word longer than its quarter was ellipsised however
  // short the other three were ("Tamb…" in Malay at 678pt).
  return w * labels.length;
}

/// The word's size when it sits under its icon (a tablet in Split View).
const double _kStackedLabelSize = 11.5;

/// One tool in the primary capsule.
///
/// The mode in use is a solid blue pill with white on it; the others are
/// white too, at the same size. They used to be dimmed, which made three of
/// the board's four verbs read as disabled — a coach looking for Draw found
/// something the colour of a greyed-out control.
class _Tool extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool showLabel;

  /// The word under the icon rather than beside it — see _PrimaryToolbar.
  final bool stacked;

  const _Tool({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
    this.showLabel = true,
    this.stacked = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = onTap == null
        ? T.textOff
        : selected
            ? T.onToolOn
            : T.text;
    final dim = barButton(context);
    final radius = BorderRadius.circular(dim * 0.42);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? T.toolOn : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            height: dim,
            constraints: BoxConstraints(minWidth: dim),
            padding: EdgeInsets.symmetric(
                horizontal: showLabel ? (stacked ? 6 : 11) : 0),
            alignment: Alignment.center,
            child: showLabel && stacked
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: dim * 0.45, color: tint),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: _kStackedLabelSize,
                          height: 1.1,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: tint,
                        ),
                      ),
                    ],
                  )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: dim * 0.45, color: tint),
                if (showLabel) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: tint,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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

    // A centred form sheet on a tablet; the usual page on a phone.
    final meta = await pushFormSheet<TacticMeta>(
      context,
      SaveTacticPage(
          state: widget.state, initial: initial, knownMetas: _metas),
    );
    if (meta == null || !mounted) return;

    // Saving under a name that already belongs to a different board replaces
    // it — make the user say so.
    if (meta.name != existing && _saved.contains(meta.name)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: kSurface,
          title: Text('save'.tr(), style: const TextStyle(color: T.text)),
          content: Text(meta.name,
              style: const TextStyle(color: T.textDim)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('cancel'.tr())),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('confirm'.tr(),
                  style: TextStyle(color: T.accent)),
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
      unawaited(ReviewService.instance.onPositiveMoment('save'));
    } catch (e) {
      debugPrint('Save error: $e');
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _renameTactic(String oldName) async {
    final messenger = ScaffoldMessenger.of(context);
    final ctrl = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename', style: TextStyle(color: T.text)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: T.text),
          decoration: InputDecoration(
            hintText: 'tactics_name'.tr(),
            hintStyle: const TextStyle(color: T.textDisabled),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('confirm'.tr(), style: TextStyle(color: T.accent)),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == oldName) return;
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
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('save'.tr(), style: const TextStyle(color: T.text)),
        content: Text(name, style: const TextStyle(color: T.textDim)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('confirm'.tr(), style: TextStyle(color: T.accent)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.state.saveTactics(name);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('${'save_success'.tr()}: $name')),
    );
    unawaited(ReviewService.instance.onPositiveMoment('save'));
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
                Icon(Icons.save_outlined, color: T.accent, size: 20),
                const SizedBox(width: 8),
                Text('save'.tr(), style: const TextStyle(color: T.text, fontWeight: FontWeight.bold, fontSize: 17)),
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
                  decoration: BoxDecoration(color: T.buttonFill, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: T.onAccent, size: 18),
                      const SizedBox(width: 6),
                      Text('save'.tr(), style: TextStyle(color: T.onAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Saved list, grouped by folder
          if (_metas.isNotEmpty) ...[
            const Divider(color: T.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text('load'.tr(), style: TextStyle(color: T.textOff, fontSize: 13)),
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
            const Icon(Icons.folder_outlined, color: T.textOff, size: 16),
            const SizedBox(width: 6),
            Text(folder.isEmpty ? 'folder_default'.tr() : folder,
                style: const TextStyle(
                    color: T.textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Text('$count',
                style: const TextStyle(color: T.textDisabled, fontSize: 12)),
          ],
        ),
      );

  Widget _tacticTile(TacticMeta meta) {
    final name = meta.name;
    return ListTile(
      dense: true,
      leading: const Icon(Icons.description_outlined, color: T.textOff, size: 20),
      title: Text(name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: T.text, fontSize: 14)),
      subtitle: meta.description.isEmpty
          ? null
          : Text(meta.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: T.textOff, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // In the match-day playbook or not. Only where there is a match
          // day to take it to.
          if (widget.state.sportType.hasMatchDay)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(
                  meta.playbook
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: meta.playbook ? T.accent : T.textOff,
                  size: 20),
              onPressed: () async {
                await widget.state.setPlaybook(name, !meta.playbook);
                await _loadList();
              },
              tooltip: (meta.playbook ? 'playbook_remove' : 'playbook_add').tr(),
            ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.drive_file_rename_outline, color: T.textOff, size: 20),
            onPressed: () => _renameTactic(name),
            tooltip: 'Rename',
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(Icons.save_as_outlined, color: T.accent, size: 20),
            onPressed: () => _overwriteTactic(name),
            tooltip: 'Update',
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: () async {
              final navigator = Navigator.of(context);
              await widget.state.loadTactics(name);
              navigator.pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: T.buttonFill, borderRadius: BorderRadius.circular(8)),
              child: Text('load'.tr(), style: TextStyle(color: T.onAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.delete_outline_rounded, color: T.danger, size: 20),
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
          color: T.surfaceHi,
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
            Icon(Icons.add_rounded, color: T.text, size: 15 * s),
            SizedBox(width: 4 * s),
            Text('add_label'.tr(),
                style: TextStyle(color: T.text, fontSize: 12 * s, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showAddSheet(context, state);
  }

  static void showAddSheet(BuildContext context, TacticsState state) {
    showBoardPanel(
      context,
      maxWidth: kPanelMaxWidth,
      builder: (ctx) =>
          scaledSheet(ctx, _AddPlayerSheet(state: state, sheetCtx: ctx)),
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

  /// Ask for the words, then put them on the board.
  ///
  /// The text tool used to drop a marker labelled "T" and leave the coach to
  /// discover that selecting it and tapping a small chip in the edit bar is
  /// where you type — which nobody did: "it is just a round shape with T in
  /// it, no easy way to actually type in text". Typing IS the tool, so it
  /// asks first and adds nothing if you change your mind.
  Future<void> _addTextMarker(MarkerShape shape, Color color,
      {Offset? at}) async {
    var text = '';
    // Face, ground and size are chosen here, where the words are typed,
    // not found afterwards in the tune panel. The field is drawn as the
    // chip will be — its colour, its face, white words on it — so what is
    // typed is what lands on the board.
    var ground = color;
    var font = '';
    var scale = 1.0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final faces = textFontFamily(font);
          return AlertDialog(
            title: Text('text_add_title'.tr(),
                style: const TextStyle(color: T.text)),
            // Scrollable for the same reason the edit dialog is: a phone
            // turned sideways leaves this box 402pt less a keyboard, and
            // the field with three rows of choices is more than that.
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: ground.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
                    child: TextFormField(
                      autofocus: true,
                      maxLength: kTextElementMaxChars,
                      minLines: 2,
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                      // The chip's own size, clamped so the smallest is
                      // still typeable and the largest still fits.
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (13 * scale).clamp(13.0, 26.0),
                        fontWeight: FontWeight.w600,
                        fontFamily: faces.isEmpty ? null : faces.first,
                        fontFamilyFallback:
                            faces.length > 1 ? faces.sublist(1) : null,
                      ),
                      decoration: InputDecoration(
                        hintText: 'text_add_hint'.tr(),
                        hintStyle: const TextStyle(color: Colors.white54),
                        counterStyle: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                        border: InputBorder.none,
                      ),
                      onChanged: (v) => text = v,
                      onFieldSubmitted: (_) => Navigator.pop(ctx, true),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // The same three rows the tune panel shows a text
                  // element, in the same order.
                  Row(
                    children: [
                      const Icon(Icons.palette_outlined,
                          color: T.textOff, size: 14),
                      const SizedBox(width: 8),
                      for (final c in kElementColors)
                        GestureDetector(
                          onTap: () => setLocal(() => ground = c),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c,
                              border: Border.all(
                                color: ground == c ? T.selectedStroke : T.border,
                                width: ground == c ? 2.5 : 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.text_fields,
                          color: T.textOff, size: 14),
                      const SizedBox(width: 8),
                      for (final f in kTextFonts)
                        TextFontChip(
                          font: f,
                          selected: font == f,
                          onTap: () => setLocal(() => font = f),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.photo_size_select_small,
                          color: T.textOff, size: 14),
                      Expanded(
                        child: Slider(
                          value: scale,
                          min: 0.5,
                          max: 3.0,
                          divisions: 10,
                          activeColor: kAccent,
                          inactiveColor: T.border,
                          onChanged: (v) => setLocal(() => scale = v),
                        ),
                      ),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${scale.toStringAsFixed(1)}×',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: T.textDim, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('cancel'.tr())),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('confirm'.tr())),
            ],
          );
        },
      ),
    );
    if (ok != true || text.trim().isEmpty) return;
    final c = state.canvasSize;
    state.addPlayer(PlayerIcon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: text.trim(),
      team: PlayerTeam.neutral,
      markerShape: shape,
      customColor: ground,
      font: font.isEmpty ? null : font,
      scale: scale,
      position: at ?? Offset(c.width * 0.5, state.spawnY(PlayerTeam.neutral)),
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

  /// The translation key and the usage key for a sport's own equipment.
  /// One name for both, so a piece that moves between sports keeps the
  /// order a coach put it in.
  static String _markerKey(MarkerShape m) => switch (m) {
        MarkerShape.hoop => 'marker_hoop',
        MarkerShape.net => 'marker_net',
        MarkerShape.antenna => 'marker_antenna',
        MarkerShape.racket => 'marker_racket',
        MarkerShape.paddle => 'marker_paddle',
        MarkerShape.shuttleTube => 'marker_shuttletube',
        MarkerShape.hopper => 'marker_hopper',
        MarkerShape.base => 'marker_base',
        MarkerShape.homePlate => 'marker_homeplate',
        MarkerShape.battingTee => 'marker_tee',
        MarkerShape.lScreen => 'marker_lscreen',
        MarkerShape.rugbyPosts => 'marker_posts',
        MarkerShape.tackleBag => 'marker_tacklebag',
        MarkerShape.hockeyStick => 'marker_stick',
        MarkerShape.floatingGoal => 'marker_floatinggoal',
        MarkerShape.laneRope => 'marker_lanerope',
        MarkerShape.chair => 'marker_chair',
        _ => 'marker_circle',
      };

  /// Build the unified list of orderable marker / neutral-player entries.
  /// Their order in the inline row vs. the More section is decided
  /// dynamically by `ElementUsageService.recentCount` — frequently-used
  /// pieces bubble to the front, rarely-used ones get tucked away.
  List<_MarkerEntry> _buildMarkerEntries() {
    // The picker shows what the board will put down. Five markers ship as
    // artwork — cone, ladder, hurdle, referee, coach — and this row drew all
    // thirteen with MarkerPainter, so a coach chose a flat orange triangle
    // and got a cone. The recolourable shapes keep their painter, because
    // their colour is the point and a sprite cannot follow it.
    Widget shapeGlyph(MarkerShape shape, Color color) {
      // The referee and the coach are drawn as people on the board, and
      // the tile shows what the board will draw: the plain figure in their
      // kit, not the top-down sprite the tile used to carry.
      if (shape == MarkerShape.referee || shape == MarkerShape.coach) {
        return SizedBox(
          width: 28,
          height: 28,
          child: CustomPaint(
            painter: TopDownPlayerPainter(
              color: color,
              borderColor: Colors.white,
              borderWidth: 2,
              gender: PlayerGender.unspecified,
              figure: PlayerFigure.plain,
              sport: state.sportType,
            ),
          ),
        );
      }
      final art = markerImageAsset(shape, state.sportType);
      return SizedBox(
        width: 28,
        height: 28,
        child: art != null
            ? Image.asset(art, fit: BoxFit.contain)
            : CustomPaint(painter: MarkerPainter(shape: shape, color: color)),
      );
    }

    _MarkerEntry shapeEntry(
      String key,
      String label,
      MarkerShape shape,
      Color color,
      int order, {
      String labelText = '',
      bool own = false,
    }) {
      return _MarkerEntry(
        key: key,
        label: label,
        glyph: shapeGlyph(shape, color),
        // The shared pieces past the four shapes make room for the sport's
        // own, which come straight after the shapes.
        defaultOrder: own || order < 4
            ? order
            : order + state.sportType.markers.length,
        onTap: () {
          if (shape == MarkerShape.text) {
            Navigator.pop(sheetCtx);
            _addTextMarker(shape, color);
          } else {
            _addMarker(shape, color, label: labelText);
          }
          ElementUsageService.instance.recordUse(key);
        },
        onDropAt: (globalPos) => _placeAtDropPos(globalPos, (local) {
          if (shape == MarkerShape.text) {
            _addTextMarker(shape, color, at: local);
            ElementUsageService.instance.recordUse(key);
            return;
          }
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

    return [
      // Named, like every other marker. These four were captioned with the
      // glyph they already draw — a teal square labelled "□" — so the four
      // most-used markers were the only ones a coach could not read.
      shapeEntry('marker_circle', 'marker_circle'.tr(), MarkerShape.circle, Colors.amber, 0),
      shapeEntry('marker_square', 'marker_square'.tr(), MarkerShape.square, Colors.teal, 1),
      shapeEntry('marker_triangle', 'marker_triangle'.tr(), MarkerShape.triangle, Colors.orange, 2),
      shapeEntry('marker_diamond', 'marker_diamond'.tr(), MarkerShape.diamond, Colors.purple, 3),
      shapeEntry('marker_cone', 'marker_cone'.tr(), MarkerShape.cone, Colors.orange, 6),
      shapeEntry('marker_text', 'marker_text'.tr(), MarkerShape.text, Colors.blueGrey, 7),
      shapeEntry('marker_zone', 'marker_zone'.tr(), MarkerShape.zone, Colors.yellow, 8),
      shapeEntry('marker_referee', 'marker_referee'.tr(), MarkerShape.referee, const Color(0xFF212121), 9),
      shapeEntry('marker_coach', 'marker_coach'.tr(), MarkerShape.coach, const Color(0xFF455A64), 10),
      shapeEntry('marker_ladder', 'marker_ladder'.tr(), MarkerShape.ladder, Colors.lime, 11),
      shapeEntry('marker_hurdle', 'marker_hurdle'.tr(), MarkerShape.hurdle, Colors.red, 12),
      shapeEntry('marker_arrow', 'marker_arrow'.tr(), MarkerShape.arrowMark, Colors.green, 13),
      // The equipment that ships as artwork. The colour is still passed —
      // shapeEntry wants one — but a sprite ignores it; it is there for the
      // day one of these falls back to the painter.
      shapeEntry('marker_goal', 'marker_goal'.tr(), MarkerShape.goal, Colors.white, 14),
      shapeEntry('marker_minigoal', 'marker_minigoal'.tr(), MarkerShape.miniGoal, Colors.lightBlue, 15),
      shapeEntry('marker_mannequin', 'marker_mannequin'.tr(), MarkerShape.mannequin, Colors.indigo, 16),
      shapeEntry('marker_pole', 'marker_pole'.tr(), MarkerShape.pole, Colors.red, 17),
      shapeEntry('marker_disc', 'marker_disc'.tr(), MarkerShape.disc, Colors.amber, 18),
      shapeEntry('marker_ring', 'marker_ring'.tr(), MarkerShape.ring, Colors.pink, 19),
      shapeEntry('marker_rebounder', 'marker_rebounder'.tr(), MarkerShape.rebounder, Colors.blueGrey, 20),
      shapeEntry('marker_bench', 'marker_bench'.tr(), MarkerShape.bench, Colors.blueGrey, 21),
      shapeEntry('marker_ballbag', 'marker_ballbag'.tr(), MarkerShape.ballBag, Colors.black54, 22),
      shapeEntry('marker_flag', 'marker_flag'.tr(), MarkerShape.cornerFlag, Colors.yellow, 23),
      // And this sport's own equipment, which no other sport's sheet shows.
      // See SportType.markers: thirty-two pieces in one list is not a list,
      // it is a search. Straight after the four shapes, not after the 24
      // shared pieces: a table-tennis net was the 19th card of the strip,
      // behind a soccer goal and a corner flag.
      for (var i = 0; i < state.sportType.markers.length; i++)
        shapeEntry(
          _markerKey(state.sportType.markers[i]),
          _markerKey(state.sportType.markers[i]).tr(),
          state.sportType.markers[i],
          Colors.white,
          4 + i,
          own: true,
        ),
    ].where((e) => !_offSport(state.sportType, e.key)).toList();
  }

  /// Shared equipment that has no place in this sport: a soccer goal, a
  /// mini goal or a corner flag on a net court or in a pool, a net bag of
  /// footballs anywhere but a football pitch (the art is footballs; racket
  /// sports have their own hopper), and floor drills — ladder, hurdle —
  /// on a table-tennis table or in the water.
  static bool _offSport(SportType sport, String key) {
    const goals = {SportType.soccer, SportType.fieldHockey, SportType.handball};
    switch (key) {
      case 'marker_goal':
      case 'marker_minigoal':
        return !goals.contains(sport);
      case 'marker_flag':
        return !{...goals, SportType.rugby}.contains(sport) ||
            sport == SportType.handball;
      case 'marker_ballbag':
        return sport != SportType.soccer;
      case 'marker_ladder':
      case 'marker_hurdle':
      case 'marker_rebounder':
        return sport == SportType.tableTennis || sport == SportType.waterPolo;
      case 'marker_mannequin':
      case 'marker_pole':
        return sport == SportType.tableTennis;
    }
    return false;
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
    // Text leads the inline row whatever has been used lately. It is the
    // one tool that labels the board rather than populating it, and a coach
    // who wants to write a word should not have to open "More" to find the
    // pen because he placed four cones this week.
    final text = entries.indexWhere((e) => e.key == 'marker_text');
    if (text > 0) entries.insert(0, entries.removeAt(text));
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
  /// A row of tiles: scrolled sideways on a phone, wrapped on a tablet,
  /// where the sheet is a 620pt popover and the strip cut its last tile in
  /// half ("Triang…") with "More" out of sight.
  Widget _strip(BuildContext context, List<Widget> children) {
    if (MediaQuery.sizeOf(context).shortestSide >= 600) {
      return Wrap(runSpacing: 8, children: children);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

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
    // The sheet's own chrome — background, radius, handle, height cap —
    // comes from TacticalSheet; this builds only what is in it. It used to
    // be an unbounded scroll view that read as a settings screen, with a
    // full-width Divider slab between every group.
    return TacticalSheet(
      // Tall enough to open showing everything. The sheet takes its content's
      // height and only scrolls past this cap, so a low one did not make a
      // compact sheet — it made a sheet that hid its last section behind a
      // swipe. With My Teams expanded there are four groups to show, and a
      // coach adding players should see all of them without scrolling.
      maxHeightFraction: 0.9,
      padding: const EdgeInsets.fromLTRB(0, T.s12, 0, T.s8),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: T.screenX),
              child: TacticalSheetHeader(title: 'add_label'.tr()),
            ),
            if (state.copied != null) _PasteRow(state: state, sheetCtx: sheetCtx),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: T.screenX),
              child: TacticalSectionHeader(label: 'players'.tr()),
            ),
            if (isTeamSport) ...[
              _TeamSportSetup(state: state, sheetCtx: sheetCtx),
            ] else ...[
              _QuickFormationRow(state: state, sheetCtx: sheetCtx),
              const SizedBox(height: T.s8),
              _SectionHeader(label: 'team_home'.tr(), color: T.home),
              _PlayerAddRow(state: state, team: PlayerTeam.home, sheetCtx: sheetCtx),
              const SizedBox(height: T.s4),
              _SectionHeader(label: 'team_away'.tr(), color: T.away),
              _PlayerAddRow(state: state, team: PlayerTeam.away, sheetCtx: sheetCtx),
            ],
            const SizedBox(height: T.s16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: T.screenX),
              child: TacticalSectionHeader(label: 'objects'.tr()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(T.panelPad, 0, T.panelPad, T.s4),
              // A strip that scrolls on a phone; on a tablet every tile
              // shows, wrapping, rather than cutting the last one off.
              // Rebuilt whenever a use is recorded, so promotion is live.
              child: ListenableBuilder(
                listenable: ElementUsageService.instance,
                builder: (context, _) => _strip(context, [
                    _DraggableMarkerCard(
                      label: 'team_ball'.tr(),
                      child: ClipOval(
                        child: SizedBox(
                          width: 28, height: 28,
                          child: ballWidget(state.sportType),
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
                    // Spread into the strip, not a row of their own, so a
                    // tablet's wrap can break between them.
                    for (final e
                        in _sortedMarkerEntries().take(_inlineMarkerCount))
                      _buildMarkerTile(e),
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
                            color: T.textDim,
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
                          width: 52 * s, height: _MarkerCard.heightFor(ctx),
                          decoration: BoxDecoration(
                            color: _showMore ? T.accentFill : T.surfaceHi,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: T.border),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_showMore ? Icons.expand_less_rounded : Icons.more_horiz, color: T.textOff, size: 18 * s),
                              Text(_showMore ? 'less'.tr() : 'more'.tr(),
                                  style: const TextStyle(color: T.textOff, fontSize: 9)),
                            ],
                          ),
                        );
                      }),
                    ),
                  ])),
            ),
            // Collapsed-by-default "More" — holds the markers that didn't
            // make the inline row. Re-sorted by usage on every open so the
            // promotion order stays consistent inside and outside.
            if (_showMore)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: ListenableBuilder(
                    listenable: ElementUsageService.instance,
                    builder: (context, _) {
                      final rest = _sortedMarkerEntries()
                          .skip(_inlineMarkerCount)
                          .toList();
                      return _strip(context,
                          [for (final e in rest) _buildMarkerTile(e)]);
                    },
                ),
              ),
            const SizedBox(height: T.s12),
            // Collapsible "My Teams" — expanded only on demand.
            GestureDetector(
              onTap: () => setState(() => _showPhotos = !_showPhotos),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline, color: T.textOff, size: 18),
                    const SizedBox(width: 8),
                    // Expanded instead of Text + Spacer: the label is long in
                    // several languages and had nothing to give, so the row
                    // ran past the edge on a narrow phone.
                    Expanded(
                      child: Text('photos_label'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: T.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ),
                    Icon(_showPhotos ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: T.textOff),
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
  /// The formation to line a squad up in: the one whose size best fits the
  /// squad without exceeding it (10 players -> 9v9, not 11v11), falling back to
  /// the smallest the sport defines.
  SportFormation? _formationForSquad(int size) {
    final all = state.formations;
    if (all.isEmpty) return null;
    final fitting = all.where((f) => f.homeCount <= size).toList()
      ..sort((a, b) => b.homeCount.compareTo(a.homeCount));
    if (fitting.isNotEmpty) return fitting.first;
    return (all.toList()..sort((a, b) => a.homeCount.compareTo(b.homeCount))).first;
  }

  void _addAllInGroup(List<PlayerPhoto> photos) {
    if (photos.isEmpty) return;
    final c = state.canvasSize;
    if (c.isEmpty) return;

    // A squad that carries positions is a team sheet, not a row of faces:
    // put it out in a formation so the keeper is in goal. Squads with no
    // identity at all keep the old line-up-in-a-row behaviour.
    final formation = _formationForSquad(photos.length);
    if (formation != null && photos.any((m) => m.hasIdentity)) {
      state.clearMultiSelect();
      state.addSquadFromFormation(formation, _team, photos);
      HapticFeedback.lightImpact();
      Navigator.of(widget.sheetCtx).maybePop();
      return;
    }
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
      // A squad member brings their shirt number and position with them; only
      // a member with no identity falls back to the duplicate counter.
      final label = photos[i].boardLabel;
      state.addPlayer(PlayerIcon(
        id: id,
        label: label.isNotEmpty ? label : (dup == 0 ? '' : '${dup + 1}'),
        team: _team,
        position: positions[i],
        photoId: photos[i].id,
        role: photos[i].role,
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
    // Taken before the duplicate check, which may await a dialog: the
    // sheet's context cannot be proven live afterwards.
    final sheetNav = Navigator.of(widget.sheetCtx);
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
    final label = photo.boardLabel;
    state.addPlayer(PlayerIcon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: label.isNotEmpty ? label : (existing == 0 ? '' : '${existing + 1}'),
      team: _team,
      position: clamped,
      photoId: photo.id,
      role: photo.role,
    ));
    HapticFeedback.lightImpact();
    sheetNav.maybePop();
  }

  Future<void> _addPlayerWithPhoto(PlayerPhoto photo, Offset tapPos) async {
    // Duplicate confirmation: if any player already uses this photo, ask
    // before adding another.
    final existing = state.players.where((p) => p.photoId == photo.id).length;
    if (existing > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('photo_duplicate_title'.tr(),
              style: const TextStyle(color: T.text)),
          content: Text(
            'photo_duplicate_msg'.tr(args: ['$existing']),
            style: const TextStyle(color: T.textDim),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('cancel'.tr(), style: const TextStyle(color: T.textOff)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('photo_add_another'.tr(),
                  style: TextStyle(color: T.accent)),
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
        builder: (_, t, _) {
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
        title: Text('photo_group_name'.tr(), style: const TextStyle(color: T.text)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: T.text),
          decoration: InputDecoration(
            hintText: 'photo_group_name'.tr(),
            hintStyle: const TextStyle(color: T.textDisabled),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: T.borderStrong)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: T.accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr(), style: const TextStyle(color: T.textOff)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop([controller.text]),
            child: Text('confirm'.tr(), style: TextStyle(color: T.accent)),
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
      constraints: sheetConstraints(context),
      backgroundColor: T.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: T.text),
              title: Text('photo_group_rename'.tr(), style: const TextStyle(color: T.text)),
              onTap: () => Navigator.of(ctx).pop('rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: T.danger),
              title: Text('photo_group_delete'.tr(), style: const TextStyle(color: T.danger)),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || !context.mounted || action == null) return;
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
          title: Text('photo_group_delete'.tr(), style: const TextStyle(color: T.text)),
          content: Text('photo_group_delete_confirm'.tr(), style: const TextStyle(color: T.textDim)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('cancel'.tr(), style: const TextStyle(color: T.textOff)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('remove'.tr(), style: const TextStyle(color: T.danger)),
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
    if (!mounted || !context.mounted) return;
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
              ? T.accentFill
              : T.surfaceHi,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? T.selectedStroke
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? T.accentText : T.textDim,
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
    // Nobody passes these today — the caller that showed a photo's delete
    // badge went with the sheet it lived in. The badge itself still works,
    // so the way back is to pass them, not to rebuild it.
    // ignore: unused_element_parameter
    this.showDeleteBadge = false,
    // ignore: unused_element_parameter
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
        color: T.surfaceHi,
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
          color: T.surfaceHi,
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
    final fbDim = dim * 1.15;
    final draggable = LongPressDraggable<PhotoDragData>(
      data: dragData,
      feedback: feedback,
      delay: kDragHoldDelay,
      dragAnchorStrategy: _centredAnchor(fbDim),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      onDragEnd: (details) {
        if (details.wasAccepted) return;
        widget.onDropOutsideTarget?.call(_dropCentre(details, fbDim));
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
                color: T.danger,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
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
          color: T.surfaceHi,
          border: Border.all(color: T.border, style: BorderStyle.solid, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: T.textDim, size: 18 * s),
            SizedBox(height: 2 * s),
            Text('photo_add_label'.tr(),
                style: TextStyle(color: T.textOff, fontSize: 9 * s)),
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
      onTap: widget.onTap,
      child: SizedBox(
        width: 28, height: 28,
        child: ClipPath(
          clipper: MarkerShapeClipper(shape),
          child: _path != null
              ? Image.file(File(_path!), fit: BoxFit.cover)
              : Container(color: T.border),
        ),
      ),
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
                  : Container(color: T.border),
            ),
            IgnorePointer(
              child: ClipPath(
                clipper: MarkerShapeClipper(shape),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: T.selectRing,
                        blurRadius: 0,
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
      delay: kDragHoldDelay,
      dragAnchorStrategy: _centredAnchor(60),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      onDragEnd: (details) {
        if (details.wasAccepted) return;
        widget.onDropOutsideTarget?.call(_dropCentre(details, 60));
      },
      child: tile,
    );
  }
}

class _CustomElementContent extends StatefulWidget {
  final PlayerPhoto photo;
  // ignore: unused_element_parameter
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
          : Container(color: T.border),
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

  /// Edit who a squad member is. These three fields belong to the person, so
  /// they follow them onto every board — and [role] is what lets a formation
  /// put the keeper in goal instead of wherever there was a free slot.
  Future<void> _editIdentity(BuildContext context, PlayerPhoto member) async {
    var name = member.playerName ?? '';
    var number = member.jerseyNumber ?? '';
    var role = member.role;
    final sport = context.read<TacticsState>().sportType;
    final roles = PlayerRoles.forSport(sport);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => AlertDialog(
          title: Text('squad_member_title'.tr(),
              style: const TextStyle(color: T.text)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 74,
                      child: TextFormField(
                        initialValue: number,
                        maxLength: 3,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: T.text),
                        decoration: InputDecoration(
                          labelText: 'squad_number'.tr(),
                          counterText: '',
                          labelStyle: const TextStyle(color: T.textOff),
                          enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: T.borderStrong)),
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: kAccent)),
                        ),
                        onChanged: (v) => number = v,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        initialValue: name,
                        maxLength: 12,
                        autofocus: true,
                        style: const TextStyle(color: T.text),
                        decoration: InputDecoration(
                          labelText: 'player_name'.tr(),
                          counterStyle:
                              const TextStyle(color: T.textDisabled, fontSize: 11),
                          labelStyle: const TextStyle(color: T.textOff),
                          enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: T.borderStrong)),
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: kAccent)),
                        ),
                        onChanged: (v) => name = v,
                      ),
                    ),
                  ],
                ),
                if (roles.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('role_title'.tr(),
                      style: const TextStyle(color: T.textOff, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final r in <String?>[null, ...roles])
                        GestureDetector(
                          onTap: () => setSheet(() => role = r),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: role == r
                                  ? kAccent
                                  : T.surfaceHi,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: role == r ? T.selectedStroke : T.border),
                            ),
                            child: Text(
                              r ?? 'role_none'.tr(),
                              style: TextStyle(
                                color: role == r ? T.onAccent : T.textDim,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('cancel'.tr(),
                  style: const TextStyle(color: T.textOff)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('confirm'.tr(),
                  style: TextStyle(color: T.accentText)),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    await PhotoLibraryService.instance.setMemberDetails(
      member.id,
      playerName: name.trim(),
      jerseyNumber: number.trim(),
      role: role,
      clearRole: role == null,
    );
  }

  Future<void> _confirmDelete(BuildContext context, PlayerPhoto photo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('photo_delete_confirm'.tr(), style: const TextStyle(color: T.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr(), style: const TextStyle(color: T.textOff)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('remove'.tr(), style: const TextStyle(color: T.danger)),
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
      backgroundColor: T.surfaceHi,
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
                  Icon(Icons.edit_outlined, color: T.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'photo_manage_title'.tr(),
                      style: const TextStyle(color: T.text, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close_rounded, color: T.textOff),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'photo_manage_hint'.tr(),
                style: const TextStyle(color: T.textOff, fontSize: 12),
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
                            childAspectRatio: 0.62,
                          ),
                          itemBuilder: (context, i) => _ManageTile(
                            key: ValueKey(list[i].id),
                            photo: list[i],
                            onDelete: () => _confirmDelete(context, list[i]),
                            onAdjust: () => PhotoCropEditor.show(
                              context, photoId: list[i].id,
                            ),
                            onEditIdentity: () =>
                                _editIdentity(context, list[i]),
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
  final VoidCallback onEditIdentity;
  const _ManageTile({
    super.key,
    required this.photo,
    required this.onDelete,
    required this.onAdjust,
    required this.onEditIdentity,
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
                  color: T.surfaceHi,
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
        const SizedBox(height: 6),
        // Who this is: shirt number, name and position travel with the player
        // onto every board. Tap to fill them in.
        GestureDetector(
          onTap: widget.onEditIdentity,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if ((widget.photo.jerseyNumber?.isNotEmpty ?? false)) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: T.accentFill,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(widget.photo.jerseyNumber!,
                            style: TextStyle(
                                color: T.accentText, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        widget.photo.playerName?.trim().isNotEmpty == true
                            ? widget.photo.playerName!
                            : 'squad_member_unnamed'.tr(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.photo.playerName?.trim().isNotEmpty == true
                              ? T.text
                              : T.textOff,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.photo.role?.isNotEmpty ?? false)
                  Text(widget.photo.role!,
                      style: const TextStyle(color: T.textOff, fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ManageAction(
              icon: Icons.badge_outlined,
              color: T.accentText,
              onTap: widget.onEditIdentity,
            ),
            _ManageAction(
              icon: Icons.crop,
              color: T.accent,
              onTap: widget.onAdjust,
            ),
            _ManageAction(
              icon: Icons.delete_outline_rounded,
              color: T.danger,
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
    // The same top-down body the board paints, so the tile previews exactly
    // what a tap or drag drops on the pitch — the old circle-with-a-plus read
    // as a different kind of element.
    return SizedBox(
      width: 28, height: 28,
      child: CustomPaint(
        painter: TopDownPlayerPainter(
          color: PlayerIcon.teamColor(team),
          borderColor: Colors.white,
          borderWidth: 1.5,
          figure: newPlayerFigure(
              context.read<TacticsState>().sportType),
          sport: context.read<TacticsState>().sportType,
        ),
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
    final accent = editing ? T.accentText : T.textOff;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52 * s, height: 52 * s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: editing
              ? T.accentFill
              : T.surfaceHi,
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              editing ? Icons.check_circle_outline_rounded : Icons.edit_outlined,
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
          color: T.accent.withValues(alpha: 0.16),
          border: Border.all(color: T.accent, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_add_outlined,
                color: T.accent, size: 18 * s),
            SizedBox(height: 1 * s),
            Text(
              '+$count',
              style: TextStyle(
                color: T.accent,
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
          color: T.accent.withValues(alpha: 0.25),
          border: Border.all(color: T.accent, width: 1.4),
          boxShadow: [
            // Picked up, not lit up: the accent bloom this used to carry is
            // the glow §33 rules out.
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_add_outlined,
                color: T.accent, size: 22),
            const SizedBox(height: 1),
            Text(
              '+$count',
              style: TextStyle(
                color: T.accent,
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
      delay: kDragHoldDelay,
      dragAnchorStrategy: _centredAnchor(60),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      onDragEnd: (details) {
        if (details.wasAccepted) return;
        onDropAt!(_dropCentre(details, 60));
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
          color: selected ? color : T.surfaceHi,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : T.textOff,
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
  /// The format picked: home and away numbers both. Keyed by the home count
  /// alone, the water-polo power play (six against five) was offered as
  /// "6v6" — and being the only formation of its count, its name was never
  /// shown either.
  (int, int)? _selectedCount;
  SportFormation? _selectedFormation;
  _TeamOption _teamOption = _TeamOption.both;

  /// Volleyball's "Rotation" chip under 6v6: the rotation controls in place
  /// of the team row. Open already on a board that is a rotation board, so
  /// rotating on is one tap.
  bool _rotationMode = false;

  /// On the full court only: the spots are laid out on its geometry.
  bool get _offersRotation =>
      widget.state.sportType == SportType.volleyball &&
      widget.state.courtLayout(SportType.volleyball) == CourtLayout.full &&
      _selectedCount == (6, 6);

  @override
  void initState() {
    super.initState();
    if (widget.state.sportType == SportType.volleyball &&
        widget.state.rotation != null) {
      _selectedCount = (6, 6);
      _rotationMode = true;
    }
  }

  static (int, int) _countOf(SportFormation f) => (f.homeCount, f.awayCount);

  List<(int, int)> get _distinctCounts {
    final counts = <(int, int)>{};
    for (final f in widget.state.formations) {
      counts.add(_countOf(f));
    }
    return counts.toList()
      ..sort((a, b) =>
          a.$1 != b.$1 ? b.$1.compareTo(a.$1) : b.$2.compareTo(a.$2));
  }

  List<SportFormation> get _formationsForCount {
    if (_selectedCount == null) return [];
    return widget.state.formations
        .where((f) => _countOf(f) == _selectedCount)
        .toList();
  }

  /// A formation whose name is only its numbers ("7v7" under the 7v7 chip)
  /// says nothing the chip above it did not; it is the standard set-up.
  static bool _plainName(SportFormation f) =>
      f.nameKey == 'formation_${f.homeCount}v${f.homeCount}' &&
      f.homeCount == f.awayCount;

  static String _formationName(SportFormation f) =>
      _plainName(f) ? 'formation_standard'.tr() : f.nameKey.tr();

  /// Volleyball: the six placed by rotation instead of a formation.
  Widget _rotationChip() =>
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          key: const ValueKey('rotation-chip'),
          onTap: () => setState(() {
            _rotationMode = true;
            _selectedFormation = null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _rotationMode ? T.accentFill : T.surfaceHi,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _rotationMode ? T.selectedStroke : T.border,
                width: _rotationMode ? 2 : 1,
              ),
            ),
            child: Text(
              'rotation_label'.tr(),
              style: TextStyle(
                color: _rotationMode ? T.accentText : T.textDim,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );

  Widget _formationChip(SportFormation f) {
    final selected = _selectedFormation == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedFormation = f;
          _rotationMode = false;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? T.accentFill : T.surfaceHi,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? T.selectedStroke : T.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            _formationName(f),
            style: TextStyle(
              color: selected ? T.accentText : T.textDim,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
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
    // The standard set-up is the default: picked the moment a count is, so
    // Apply is one tap — unless the sheet is in rotation mode. (The only
    // formation of its count is the default whatever it is called.)
    if (_selectedCount != null && _selectedFormation == null && !_rotationMode) {
      _selectedFormation = formations.length == 1
          ? formations.first
          : formations.where(_plainName).firstOrNull;
    }
    // The formation row: several to choose from, or one with a name of its
    // own (the power play) that the count chip cannot say.
    final showFormations = _selectedCount != null &&
        (formations.length > 1 ||
            (formations.length == 1 && !_plainName(formations.first)));
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
          // Row 1: Player count. No label of its own — the sheet's PLAYERS
          // section header sits directly above it and says the same word, so
          // the sheet opened reading "PLAYERS / Players / 11v11 7v7 5v5".
          // (Quick +1 home/away has moved to the markers row, next to the
          //  ball, so it's reachable without scrolling past the formation
          //  picker.)
          Row(
            children: _distinctCounts.map((count) {
              final selected = _selectedCount == count;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedCount = count;
                    _selectedFormation = null; // reset
                    _rotationMode = false;
                  }),
                  child: Container(
                    width: 56 * s,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? T.accentFill : T.surfaceHi,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? T.selectedStroke : T.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${count.$1}v${count.$2}',
                        style: TextStyle(
                          color: selected ? T.accentText : T.textDim,
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
          if (showFormations) ...[
            const SizedBox(height: 12),
            Text('formation_label'.tr(), style: TextStyle(color: T.textDim, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // The standard set-up first, as the default. Volleyball's
                  // Rotation chip comes right after it, before the named
                  // set-ups, still in view when it is the one selected.
                  for (final (i, f) in formations.indexed) ...[
                    _formationChip(f),
                    if (_offersRotation && i == 0) _rotationChip(),
                  ],
                ],
              ),
            ),
          ],

          // Row 3 (volleyball rotation): system, rotation, libero, check.
          if (_offersRotation && _rotationMode) ...[
            const SizedBox(height: 12),
            VolleyballRotationControls(
              state: widget.state,
              team: _teamOption == _TeamOption.away
                  ? PlayerTeam.away
                  : PlayerTeam.home,
              onPlace: () => Navigator.of(widget.sheetCtx).maybePop(),
            ),
          ],

          // Row 3: Team selection
          if (!_rotationMode && (_selectedFormation != null || (_selectedCount != null && formations.length == 1))) ...[
            const SizedBox(height: 12),
            Text('team_label'.tr(), style: TextStyle(color: T.textDim, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                if (!halfPitch) ...[
                  _buildTeamChip('both_teams'.tr(), _TeamOption.both, T.toolOn),
                  const SizedBox(width: 8),
                ],
                _buildTeamChip('team_home'.tr(), _TeamOption.home, T.home),
                const SizedBox(width: 8),
                _buildTeamChip('team_away'.tr(), _TeamOption.away, T.away),
                const Spacer(),
                // Apply tile — same drag UX as the +1 home / +1 away marker
                // cards: tap to apply at the formation's default coordinates,
                // long-press-drag to translate the team(s) so the centroid
                // lands at the drop point.
                _DraggableMarkerCard(
                  label: 'confirm'.tr(),
                  onTap: _apply,
                  onDropAt: _applyAtDrop,
                  child: const Icon(Icons.groups_outlined,
                      color: T.success, size: 26),
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
          color: selected ? activeColor : T.surfaceHi,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? activeColor : T.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : T.textDim,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
                    figure: newPlayerFigure(
                        context.read<TacticsState>().sportType),
                    sport: context.read<TacticsState>().sportType,
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
    final formations = state.formations;
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
          title: Text('formation_replace_title'.tr(), style: const TextStyle(color: T.text)),
          content: Text('formation_replace_message'.tr(), style: const TextStyle(color: T.textDim)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: Text('cancel'.tr())),
            TextButton(
              onPressed: () { Navigator.pop(dCtx); doApply(); },
              child: Text('formation_apply'.tr(), style: TextStyle(color: T.accentText)),
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
          color: T.surfaceHi,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: T.border),
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
                  child: Text('vs', style: TextStyle(color: T.textDisabled, fontSize: 10)),
                ),
                ..._dots(awayDots),
              ],
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: T.text, fontSize: 13, fontWeight: FontWeight.w600)),
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
    final card = _MarkerCard(label: label, onTap: onTap, child: child);
    if (onDropAt == null) return card;
    final feedback = Material(
      color: Colors.transparent,
      child: Container(
        width: 60, height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            // Picked up, not lit up: the accent bloom this used to carry is
            // the glow §33 rules out, and it read as a defect on the pitch.
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
      delay: kDragHoldDelay,
      dragAnchorStrategy: _centredAnchor(60),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      onDragEnd: (details) {
        if (details.wasAccepted) return;
        onDropAt!(_dropCentre(details, 60));
      },
      child: card,
    );
  }
}

/// Paste, at the top of the sheet, when something has been copied.
///
/// Here rather than beside the copy button on the edit bar: the + sheet is
/// where everything else comes onto the board from, and pasting is most
/// often the first thing done on a page that has just been turned to — the
/// board behind the sheet is the NEW page, and the element came from the
/// old one.
class _PasteRow extends StatelessWidget {
  final TacticsState state;
  final BuildContext sheetCtx;
  const _PasteRow({required this.state, required this.sheetCtx});

  @override
  Widget build(BuildContext context) {
    final p = state.copied;
    if (p == null) return const SizedBox.shrink();
    final runs = p.moves.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(T.screenX, 0, T.screenX, T.s12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          state.pastePlayer();
          Navigator.pop(sheetCtx);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: T.s12, vertical: T.s12),
          decoration: BoxDecoration(
            color: T.accentFill,
            borderRadius: T.brSm,
            border: Border.all(color: T.accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              // The token at its own size, scaled into the tile: a player
              // is a 36pt box plus a name badge when the label hangs below,
              // and a 34pt box cut two pixels off the bottom of every one.
              SizedBox(
                width: 40,
                height: 40,
                child: FittedBox(
                  child: SizedBox(
                    width: kPlayerIconSize * p.scale,
                    height: kPlayerIconSize * p.scale +
                        (p.label.isNotEmpty && !p.labelInside
                            ? 21 * p.scale * kFigureScale
                            : 0),
                    child: IgnorePointer(
                      child: PlayerIconWidget(
                          player: p, sport: state.sportType),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: T.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'paste_element'.tr(args: [
                        p.label.isNotEmpty ? p.label : 'add_label'.tr()
                      ]),
                      style: const TextStyle(
                          color: T.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    // What comes with it, in the words of the thing a coach
                    // would otherwise have to redraw by hand.
                    if (runs > 0)
                      Text(
                        runs == 1
                            ? 'paste_with_run_one'.tr()
                            : 'paste_with_run'.tr(args: ['$runs']),
                        style: const TextStyle(
                            color: T.textDim, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Icon(Icons.content_paste_rounded,
                  color: T.accent, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarkerCard extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback onTap;
  const _MarkerCard({required this.label, required this.child, required this.onTap});

  /// Every card is this tall: padding, the 28pt glyph, its gap and two
  /// lines of label. On one line "Water goal" and "Lane rope" came out as
  /// "Water g…" and "Lane r…". The "More" tile matches it.
  static double heightFor(BuildContext context) {
    final s = uiScale(context);
    return 16 * s +
        28 +
        4 * s +
        MediaQuery.textScalerOf(context).scale(10.5) * 1.15 * 2 + 3;
  }

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // A tablet sets the label 1.4x, and at 84pt "Hình vuông", "Tuan
        // Rumah" and "Segitiga" broke over two lines; the tiles wrap there
        // (see _strip), so the width costs nothing.
        width: s > 1 ? 100 : 60 * s,
        height: heightFor(context),
        padding: EdgeInsets.symmetric(vertical: 8 * s, horizontal: 4 * s),
        decoration: BoxDecoration(
          color: T.surfaceHi,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: T.border),
        ),
        // Centred in the card's fixed height: a one-line word used to sit
        // at the top of a two-line band, leaving the glyph and the word
        // riding high with a blank strip under them.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            child,
            SizedBox(height: 4 * s),
            // Flexible: a glyph a point taller than its box, or a font's
            // own line height, must shorten the label, not overflow.
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: T.textOff, fontSize: 10.5, height: 1.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small circular player preview for the sheet
// ─────────────────────────────────────────────────────────────────────────────
// Drawing Options Row — single compact row (draw mode only)
// ─────────────────────────────────────────────────────────────────────────────

class DrawingOptionsBar extends StatelessWidget {
  final TacticsState state;

  /// Kept for the callers that still pass it; the palette now shows its
  /// colours and thickness always, because hiding them behind a More/Less
  /// header meant the two controls a coach reaches for most were two taps
  /// away on every single line.
  final bool showOptions;

  const DrawingOptionsBar(
      {super.key, required this.state, this.showOptions = true});

  @override
  Widget build(BuildContext context) {
    final sel = state.selectedStroke;
    return Container(
      padding: const EdgeInsets.fromLTRB(T.s12, T.s12, T.s12, T.s12),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(T.rLg),
        border: Border.all(color: T.border),
        boxShadow: T.shadowFloat,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A selected stroke's actions ride above the palette rather than
          // pushing a second bar onto the board.
          if (sel != null) ...[
            Row(
              children: [
                Icon(Icons.gesture_rounded, color: sel.color, size: 16),
                const SizedBox(width: T.s8),
                Expanded(
                  child: Text('line_label'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: T.secondary),
                ),
                TacticalIconButton(
                  icon: Icons.delete_outline_rounded,
                  color: T.danger,
                  size: 20,
                  onTap: () => state.deleteStroke(sel.id),
                  semanticLabel: 'remove'.tr(),
                ),
                TacticalIconButton(
                  icon: Icons.close_rounded,
                  size: 20,
                  onTap: () => state.selectStroke(null),
                ),
              ],
            ),
            const SizedBox(height: T.s4),
          ],
          // Line style + eraser.
          Row(
            children: [
              Expanded(
                child: Material(
                  color: T.surfaceHi,
                  borderRadius: T.brSm,
                  child: InkWell(
                    onTap: () => showLineStyleSheet(context, state),
                    borderRadius: T.brSm,
                    child: Container(
                      height: T.tap,
                      padding: const EdgeInsets.symmetric(horizontal: T.s12),
                      child: Row(
                        children: [
                          Text('line_label'.tr(), style: T.secondary),
                          const SizedBox(width: T.s8),
                          Expanded(
                            child: CustomPaint(
                              size: const Size(56, 20),
                              // The picked-out line's own style when there
                              // is one: the pen's showed a wavy plain line
                              // over a straight arrow (2026-10-17).
                              painter: LineStylePreviewPainter(
                                shape: sel?.shape ?? state.lineShape,
                                dash: sel?.style ?? state.strokeStyle,
                                arrow: sel?.arrow ?? state.arrowStyle,
                                color: sel?.color ?? state.strokeColor,
                              ),
                            ),
                          ),
                          const Icon(Icons.expand_more_rounded,
                              color: T.textOff, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: T.s8),
              _EraserToggle(
                on: state.eraserMode,
                onTap: () => state.setEraserMode(!state.eraserMode),
              ),
              // A way out that is not the toolbar. Closing the pen's panel
              // puts the pen down: the bottom bar goes back to Move, which
              // is what a coach is about to do next. With a line picked
              // out the row above has its own close, which only lets go of
              // the line.
              if (sel == null) ...[
                const SizedBox(width: T.s4),
                TacticalIconButton(
                  icon: Icons.close_rounded,
                  size: 20,
                  onTap: () => state.setDrawingMode(false),
                ),
              ],
            ],
          ),
          const SizedBox(height: T.s12),
          // Colours and thickness on one line.
          Row(
            children: [
              // A colour or a thickness is the pen's from here on — and,
              // when a line is picked out, that line's too. Without the
              // second half a drawn line could only be deleted and drawn
              // again: updateStroke existed and nothing ever called it.
              ...kStrokeColors.map((c) => _ColorDot(
                    color: c,
                    selected: (sel?.color ?? state.strokeColor) == c,
                    onTap: () {
                      state.setStrokeColor(c);
                      if (sel != null) state.updateStroke(sel.id, color: c);
                    },
                  )),
              const SizedBox(width: T.s8),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    activeTrackColor: T.accent,
                    inactiveTrackColor: T.surfaceHi,
                    thumbColor: T.accent,
                    overlayColor: T.accentFill,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 18),
                    tickMarkShape: SliderTickMarkShape.noTickMark,
                  ),
                  child: Slider(
                    value: (sel?.width ?? state.strokeWidth).clamp(1.0, 8.0).toDouble(),
                    min: 1,
                    max: 8,
                    divisions: 7,
                    // The first touch is the undo point; the steps after it
                    // ride on top of that one snapshot.
                    onChangeStart: sel == null
                        ? null
                        : (v) => state.updateStroke(sel.id, width: v),
                    onChanged: (v) {
                      state.setStrokeWidth(v);
                      if (sel != null) {
                        state.updateStroke(sel.id, width: v, snapshot: false);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

/// The eraser toggle in the drawing panel.
///
/// It was a [TacticalChip], whose "on" is a 12%-opacity teal wash — fine for
/// a filter you read a list of, invisible for a mode that changes what every
/// tap on the board does. On it is now solid, the way the active tool in the
/// bottom bar is solid, and it says so in words.
class _EraserToggle extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;

  const _EraserToggle({required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: on,
      child: Material(
        color: on ? T.toolOn : T.surfaceHi,
        borderRadius: T.brSm,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: T.brSm,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: T.tap,
            padding: const EdgeInsets.symmetric(horizontal: T.s12),
            decoration: BoxDecoration(
              borderRadius: T.brSm,
              border: Border.all(
                color: on ? T.onToolOn.withValues(alpha: 0.55) : T.border,
                width: on ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  on ? Icons.backspace_rounded : Icons.backspace_outlined,
                  size: 17,
                  color: on ? T.onToolOn : T.textDim,
                ),
                const SizedBox(width: 6),
                Text(
                  'eraser'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                    color: on ? T.onToolOn : T.textDim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot(
      {required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // A ring around the swatch, not a thicker border on it: the swatch has
    // to stay the colour it is.
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 34,
          height: T.tap,
          child: Center(
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(color: T.selectedStroke, width: 2)
                    : Border.all(color: T.border),
              ),
              child: Center(
                child: Container(
                  width: selected ? 16 : 20,
                  height: selected ? 16 : 20,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formation Tile
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Play / Stop button
// ─────────────────────────────────────────────────────────────────────────────

/// One shape for every playback control. The bar used to carry six accent
/// colours — orange reset, blue steps, teal glyphs, red stop, green play,
/// purple timeline — so nothing in it read as the primary action.
class _PlayCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;
  final bool active;
  final String? semanticLabel;

  const _PlayCircle({
    required this.icon,
    this.onTap,
    this.primary = false,
    this.active = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = onTap == null
        ? T.textOff
        : primary
            ? T.onLime
            : active
                ? T.accentText
                : T.text;
    final Color bg = primary
        ? T.lime
        : active
            ? T.accentFill
            : Colors.transparent;
    // Play is the one control a coach hits from a metre away, so it is a
    // size up from the steppers around it.
    final dim = barButton(context) * (primary ? 1.14 : 1.0);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: Container(
          width: dim,
          height: dim,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: fg, size: dim * (primary ? 0.59 : 0.50)),
        ),
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
    return _PlayCircle(
      icon: isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
      primary: true,
      onTap: isPlaying
          ? state.stopAnimation
          : canPlay
              ? state.startAnimation
              : null,
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
    // On beat zero the routes are the whole plan, off by default; on any
    // other beat they are that beat's legs, which is the beat itself and is
    // on by default. One button, one word — see TacticsState.routesOn.
    final show = state.routesOn;
    // Hiding the run lines is a temporary view state, not a destructive one:
    // it used to be flagged in danger red, which put the loudest colour in
    // the app on a button that only cleans up the board for a screenshot.
    return _PlayCircle(
      icon: show ? Icons.timeline_rounded : Icons.visibility_off_outlined,
      onTap: state.toggleShowMoveLines,
      active: !show,
      semanticLabel: 'move_lines'.tr(),
    );
  }
}

class _TimelineBtn extends StatelessWidget {
  final TacticsState state;
  const _TimelineBtn({required this.state});

  @override
  Widget build(BuildContext context) {
    // This was the one purple control in the app, on a 36pt target inside a
    // bar where everything else is 44 and either lime or neutral.
    return _PlayCircle(
      icon: Icons.view_timeline_outlined,
      onTap: () => _showTimeline(context),
      semanticLabel: 'timeline'.tr(),
    );
  }

  void _showTimeline(BuildContext context) {
    showBoardPanel(
      context,
      maxWidth: kPanelMaxWidth,
      builder: (ctx) => TacticalSheet(
        padding: const EdgeInsets.fromLTRB(0, T.s12, 0, 0),
        child: scaledSheet(ctx, TimelineEditor(state: state)),
      ));
  }
}

class _ResetButton extends StatelessWidget {
  final TacticsState state;
  const _ResetButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final canReset = !state.isAnimating && state.atStep > 0;
    return _PlayCircle(
      icon: Icons.replay_rounded,
      onTap: canReset ? state.clearAnimatedPositions : null,
    );
  }
}

/// One phase back, one phase forward.
///
/// These were skip_previous / skip_next — the bar-and-triangle glyph that
/// means "jump to the start" and "jump to the end" in every media player ever
/// made, on buttons that move a single step. The reset arrow to their left is
/// the control that really does go back to the beginning, so the pair read as
/// two ways to do the same thing. Chevrons say one step.
class _StepBackButton extends StatelessWidget {
  final TacticsState state;
  const _StepBackButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final canStep = !state.isAnimating && state.atStep > 0;
    return _PlayCircle(
      icon: Icons.chevron_left_rounded,
      onTap: canStep ? state.stepBackward : null,
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
      style: TextStyle(color: T.text, fontSize: 16 * s, fontWeight: FontWeight.bold),
    );
  }
}

class _StepForwardButton extends StatelessWidget {
  final TacticsState state;
  const _StepForwardButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final canStep = !state.isAnimating && state.atStep < state.maxMoveSteps;
    return _PlayCircle(
      icon: Icons.chevron_right_rounded,
      onTap: canStep ? state.stepForward : null,
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
        padding: EdgeInsets.symmetric(
            horizontal: T.s12, vertical: 5 * uiScale(context)),
        // The same capsule as the tool bar below it. These were two different
        // dark treatments — translucent black here, T.surface there — stacked
        // one above the other, which read as two unrelated pieces of chrome
        // rather than one bar that had swapped its contents.
        decoration: BoxDecoration(
          color: state.sportType.theme.panelColor,
          borderRadius: T.brLg,
          border: const Border.fromBorderSide(BorderSide(color: T.border)),
          boxShadow: T.shadowFloat,
        ),
        // Scaled down as a whole when the screen is too narrow for seven
        // buttons at full size, rather than overflowing: at 375pt it ran 8pt
        // off the right edge and at 320 it never had a chance. Everything
        // keeps its proportions; only on a phone narrower than about 390pt
        // does any of it shrink at all.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ResetButton(state: state),
            const BarDivider(),
            _StepBackButton(state: state),
            const SizedBox(width: T.s4),
            _StepIndicator(state: state),
            const SizedBox(width: T.s4),
            _StepForwardButton(state: state),
            const SizedBox(width: 6),
            _PlayButton(state: state),
            const SizedBox(width: 6),
            _LinesToggle(state: state),
            const BarDivider(),
            _TimelineBtn(state: state),
          ],
        ),
        ),
      ),
    );
  }
}
