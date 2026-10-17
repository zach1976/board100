import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config_constants.dart';
import '../main.dart';
import '../models/player_icon.dart';
import '../models/player_role.dart';
import '../models/court_layout.dart';
import '../models/sport_type.dart';
import '../models/sport_theme.dart';
import '../models/volleyball_rotation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/purchase_service.dart';
import '../state/tactics_state.dart';
import '../ui_constants.dart';
import '../ui/primitives.dart';
import '../ui/tokens.dart';
import '../painters/ball_painter.dart';
import '../widgets/player_icon_widget.dart';
import '../widgets/board_shortcuts.dart';
import '../widgets/marker_shape_clipper.dart';
import '../widgets/tactics_canvas.dart';
import '../widgets/toolbar.dart';
import '../widgets/sport_glyph.dart';
import '../models/player_photo.dart';
import '../services/photo_library_service.dart';
import 'drill_library_page.dart';
import '../widgets/photo_crop_editor.dart';
import '../widgets/photo_import_sheet.dart';
import '../widgets/timeline_editor.dart';
import '../models/practice.dart';
import '../services/practice_service.dart';
import 'practice_plan_page.dart';
import 'practice_run_page.dart';

/// How wide the landscape rail is.
///
/// Its floor is the playback row — four 32pt circles with 6 between them and
/// the panel's own 4 each side, which is 154. The rest of the rail is text
/// that is centred in whatever it is given, so the number is set by that row
/// and the board keeps the difference.
const double kRailWidth = 160;

/// Which long edge the Dynamic Island (or notch) is on, turned sideways:
/// "left", "right" or "none".
///
/// iOS reports the same inset on both long edges in landscape, so this asks
/// the native side, which reads the interface orientation — and which also
/// pushes the answer on every rotation, because a half turn from one
/// landscape to the other changes nothing Flutter would rebuild for.
class IslandSide {
  static const _channel = MethodChannel('com.zach.tacticsboard/islandSide');
  static final ValueNotifier<String> side = ValueNotifier('none');
  static bool _wired = false;

  static void ensure() {
    if (_wired) return;
    _wired = true;
    if (!Platform.isIOS) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed' && call.arguments is String) {
        side.value = call.arguments as String;
      }
    });
    refresh();
  }

  static Future<void> refresh() async {
    try {
      side.value = await _channel.invokeMethod<String>('get') ?? 'none';
    } catch (_) {
      // An older native build without the channel: keep the rail right.
    }
  }
}

/// How tall the board's bottom chrome (playback + tool capsules) stands,
/// so a tablet's SnackBar can sit on top of it instead of over it.
final ValueNotifier<double> _bottomChromeHeight = ValueNotifier(0);

class _ReportHeight extends SingleChildRenderObjectWidget {
  const _ReportHeight({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReportHeight();
}

class _RenderReportHeight extends RenderProxyBox {
  @override
  void performLayout() {
    super.performLayout();
    final h = size.height;
    if ((_bottomChromeHeight.value - h).abs() > 0.5) {
      // Not during layout: it rebuilds the page's theme.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _bottomChromeHeight.value = h,
      );
    }
  }
}

class TacticsBoardHomePage extends StatelessWidget {
  const TacticsBoardHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    // A language switch puts the drill's step note into the new language
    // (unless the coach has rewritten it). After the frame: it notifies.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.read<TacticsState>().localizeDrill(locale.countryCode == null
          ? locale.languageCode
          : '${locale.languageCode}-${locale.countryCode}');
    });
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;

    final theme = context.select<TacticsState, SportTheme>(
      (s) => s.sportType.theme,
    );
    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      // A hardware keyboard drives the board: Space, arrows, ⌘Z, Delete,
      // Esc, ⌘S. See BoardShortcuts.
      body: BoardShortcuts(child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.pageGradient,
          ),
        ),
        // The side rail is for a landscape PHONE, where a bottom bar would
        // eat a third of what little height there is. A tablet turned
        // sideways has height to spare and a lot of width, and a coach
        // holding one wants the board as wide as the screen with the
        // controls under his thumbs — the same bar the portrait layout
        // uses, not a column down the right that the board has to shrink
        // to make room for.
        child: isLandscape && !isTablet
            ? _buildLandscape(context, topPad, bottomPad)
            : _buildPortrait(context, topPad, bottomPad),
      )),
    );
    // An upright phone too: its two capsules stand ~150pt, and the app's
    // 96pt lift laid a drill's name across the playback capsule (reported
    // 2026-10-17). Measured, not guessed, the same way as the tablet's.
    if (isTablet || !isLandscape) {
      // A tablet's two capsules are 1.4x a phone's, and stacked in portrait
      // they stand ~170pt tall: the app's 96pt lift left a drill's name, or
      // "Saved", lying over the step counter and Play for four seconds,
      // 992pt wide. Here it is a 480pt pill that sits on the chrome's
      // measured top edge, whatever row layout the chrome chose.
      final app = Theme.of(context);
      final width = MediaQuery.sizeOf(context).width;
      return ValueListenableBuilder<double>(
        valueListenable: _bottomChromeHeight,
        builder: (context, chrome, child) {
          final side = math.max(T.s16, (width - 480) / 2);
          return Theme(
            data: app.copyWith(
              snackBarTheme: app.snackBarTheme.copyWith(
                insetPadding: EdgeInsets.fromLTRB(
                  side,
                  T.s8,
                  side,
                  math.max(96.0, chrome + T.s8),
                ),
              ),
            ),
            child: child!,
          );
        },
        child: scaffold,
      );
    }
    if (!isLandscape) return scaffold;
    // The app's SnackBar sits 96pt off the bottom to clear the portrait
    // toolbar capsule. Turned sideways the capsule is a rail down the right
    // and there is nothing at the bottom to clear, so a drill's name arrived
    // across the middle of the pitch, running under the rail. Here it sits
    // at the foot of the board, inside the board's own column.
    final railShown = context.select<TacticsState, bool>(
      (s) => s.toolbarVisible && !s.presentationMode,
    );
    final app = Theme.of(context);
    return Theme(
      data: app.copyWith(
        snackBarTheme: app.snackBarTheme.copyWith(
          insetPadding: () {
            final rail = railShown ? kRailWidth * uiScale(context) : 0.0;
            final left = IslandSide.side.value == 'left';
            return EdgeInsets.fromLTRB(
              (left ? rail : 0) + T.s16,
              T.s8,
              (left ? 0 : rail) + T.s16,
              bottomPad + T.s12,
            );
          }(),
        ),
      ),
      child: scaffold,
    );
  }

  Widget _buildPortrait(BuildContext context, double topPad, double bottomPad) {
    return Column(
      children: [
        Expanded(child: _canvasStack(context, topPad)),
        _bottomBar(context, bottomPad),
      ],
    );
  }

  Widget _buildLandscape(
    BuildContext context,
    double topPad,
    double bottomPad,
  ) {
    // Sideways the Dynamic Island is a pill down one long edge — about a
    // third of that edge long, in the middle of it, and a good deal
    // narrower than the inset iOS reports for it. Over the board it would
    // sit at the height where the server stands in the free zone beyond the
    // end line, and a board has nothing it can move out of the way.
    //
    // The board runs edge to edge and the rail goes to the island's side,
    // where only the rows that run behind the pill step aside (see
    // [_landscapeSidePanel] and [IslandSide]).
    //
    // Nothing is given up for the island on the board's side, because iOS
    // cannot tell us which side it is on: turned sideways it reports the
    // same 59pt inset on BOTH edges, so honouring it cost 59pt of court in
    // every orientation for a pill that is only on one of them. What the
    // pill does have is a fixed place along the edge — the middle third —
    // and everything the board floats sits in the top and bottom bands,
    // well clear of it. The one thing that can end up behind it is a player
    // standing right out in the free zone beyond the end line, half a
    // figure of him, in one of the two orientations.
    final rail = Selector<TacticsState, ({bool visible, SportTheme theme})>(
      selector: (_, s) => (
        visible: s.toolbarVisible && !s.presentationMode,
        theme: s.sportType.theme,
      ),
      builder: (context, sel, _) => sel.visible
          ? SizedBox(
              // The rail's contents are text at uiScale, so the rail has to
              // scale with them; a fixed width overflows on a tablet.
              width: kRailWidth * uiScale(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: T.s8),
                // On the page's own ground, the sport's colour taken deep,
                // exactly as the upright phone has it under its capsules:
                // each control is a white chip on it, and nothing is a
                // white strip (reported 2026-10-17, twice).
                child: Material(
                  type: MaterialType.transparency,
                  child: _landscapeSidePanel(context),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
    // The rail goes to whichever side the island is on, so the pill only
    // ever lies over the rail's own rows (which step aside for it) and
    // never over the board. Right when there is no island, or no telling.
    IslandSide.ensure();
    return ValueListenableBuilder<String>(
      valueListenable: IslandSide.side,
      builder: (context, side, _) {
        final board = Expanded(child: _canvasStack(context, topPad));
        return Row(
          children: side == 'left' ? [rail, board] : [board, rail],
        );
      },
    );
  }

  /// Vertical offset of the floating corner buttons. The status bar is
  /// hidden (UIStatusBarHidden), so the safe-area inset only exists for the
  /// notch / Dynamic Island — which is centred, leaving both corners free.
  /// Sitting the buttons beside it instead of below reclaims ~40pt of board.
  ///
  /// That only holds while the corners hold small buttons. A board with more
  /// than one page grows the page control from one circle to three — back,
  /// count, forward — and anchored to the right it then reaches left into
  /// the island, where the "previous page" chevron disappeared under it.
  ///
  /// So the chrome is two rows. Back and the menu never move: they are one
  /// button each, they fit the corners, and a back button that jumps down
  /// the moment you add a page is a navigation bar that changes height with
  /// its content. The page control is what grows, so the page control is
  /// what drops — to its own row below the inset, where the board makes room
  /// for it rather than sitting underneath it.
  double _chromeTop(double topPad) =>
      (topPad - 38).clamp(8.0, topPad + 8).toDouble();

  /// The second row: only a multi-page board has one.
  ///
  /// Measured against the first row's circles, not the inset: with the
  /// first row level with an island, topPad+6 was only 6pt under it on the
  /// 402pt phones, which the circles' shadows closed up to nothing.
  double _pagesTop(double topPad) =>
      math.max(topPad + 6, _chromeTop(topPad) + 44 + 10);

  /// How much of the top the second row takes, so the pitch can start below
  /// it. Zero for the one-page board that has no second row.
  double _pagesBand(BuildContext context, double topPad, bool wide) {
    // The pitch starts below the chrome on every board, not only the
    // multi-page one. Reclaiming the top row for the board assumed the
    // corners held nothing but the buttons; a penalty corner puts the
    // injector on the backline in the corner, and the page badge sat on
    // top of him — covering the man and taking his taps.
    final row = chromeCircle(context) + 6;
    return (wide ? _pagesTop(topPad) : _chromeTop(topPad)) + row;
  }

  /// Which band of the card the floating buttons float in, turned sideways:
  /// the one above and below the court, or the one at its ends.
  ///
  /// The court is centred in the card at its own aspect, so sideways one of
  /// those two bands is wide and the other is a few points — and which it is
  /// depends on the sport. A court narrow for its length (volleyball,
  /// tennis, badminton) is fitted by the card's length and keeps its spare
  /// room above and below; a pitch wide for its length (football, rugby,
  /// hockey) is fitted by the card's height and keeps it at the ends.
  ///
  /// So the buttons go wherever the room already is and the board gives up
  /// nothing for them. Above and below is the better place to be when it is
  /// available: the ends are where the rail is, and four circles stacked
  /// down that edge read as a second rail beside the first.
  bool _chromeAcross(BuildContext context, Size card) {
    if (card.width <= 0 || card.height <= 0) return false;
    final sport = context.select<TacticsState, SportType>((s) => s.sportType);
    // Sideways the canvas is a RotatedBox away: it is laid out portrait with
    // the card's height for its width, so fieldRect's WIDTH is the court
    // measured across the screen's short side — the band this is after.
    final court = sport.fieldRect(Size(card.height, card.width));
    // Three quarters of a circle, not a whole one. The buttons sit 4 off the
    // card's edge in the corners, where the court's own corner is the point
    // furthest from them; asking for the whole circle made the answer flip
    // every time the board changed width by a few points, and the layout
    // flipping with it is worse than a quarter of a glass circle lying over
    // a touchline at the very end of it.
    return (card.height - court.width) / 2 >= chromeCircle(context) * 0.75;
  }

  /// How far in from each end the board has to start, turned sideways, so
  /// the floating corner buttons are not standing on the court.
  ///
  /// A pitch is longer than it is wide, so sideways it is fitted by HEIGHT
  /// and what is left over at each end is whatever the width did not need.
  /// On a tablet, or in a window, that is a wide margin of turf and the
  /// buttons float in it, which is what they were written for. On a phone it
  /// is a couple of points: the court runs to within a nail's width of the
  /// card's ends, and the menu, the page badge, the zoom and the fullscreen
  /// circles all sat on the playing surface — over the baseline, over the
  /// key, over a man standing in the corner, taking his taps.
  ///
  /// So the gutter is measured, not assumed: the two button columns reach
  /// [chromeCircle] + 12 in from each edge, and the board gives up only
  /// however much of that the court was not already clear of. A screen with
  /// the room keeps every point of board it has today.
  double _endGutter(BuildContext context, Size box, bool across) {
    const small = T.s8;
    if (box.width <= 0 || box.height <= 0) return small;
    // Nothing stands at the ends when the buttons are above and below.
    if (across) return small;
    final need = 12 + chromeCircle(context) + 4;
    final sport = context.select<TacticsState, SportType>((s) => s.sportType);
    // Sideways the canvas is a RotatedBox away: it is laid out portrait, with
    // the card's height for its width. fieldRect's own height is the court's
    // length, which runs across the screen.
    // Only the shortfall, not the whole of [need]: it was all or nothing,
    // and a basketball court that was 18pt short of clear gave up 60 at
    // each end — a fifth of the board's length — for the circles to stand
    // on page (reported 2026-10-17). A court fitted by the card's length
    // shrinks as the card does, so the answer is found by stepping, each
    // step measured against the court the smaller card would draw.
    var gutter = small;
    for (var i = 0; i < 4; i++) {
      final card = Size(box.width - gutter * 2, box.height);
      final court = sport.fieldRect(Size(card.height, card.width));
      final clear = gutter + (card.width - court.height) / 2;
      if (clear >= need - 0.5) break;
      gutter = math.min(need, gutter + (need - clear));
    }
    return gutter;
  }

  Widget _canvasStack(BuildContext context, double topPad) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    // Only the page count matters here, so the whole board does not rebuild
    // every time something on it moves.
    final wideChrome =
        context.select<TacticsState, int>((s) => s.pageCount) > 1;
    return DragTarget<PhotoDragData>(
      onAcceptWithDetails: (details) => _onPhotoDropped(context, details),
      builder: (ctx, candidate, rejected) => LayoutBuilder(
        builder: (context, outer) {
          // Where the floating buttons float, sideways: above and below the
          // court, or at its ends. Measured once here because the board's own
          // padding and four separate pieces of chrome all have to agree.
          final across =
              isLandscape &&
              _chromeAcross(
                context,
                Size(outer.maxWidth - T.s8 * 2, outer.maxHeight - T.s8 * 2),
              );
          // In that band the circles sit 4 off the card's edge rather than 8:
          // the band was measured to the point and every point below it is court.
          final chromeTop = across ? 4.0 : _chromeTop(topPad);
          return Stack(
            fit: StackFit.expand,
            children: [
              // A one-page board runs full bleed: its two corner buttons sit in
              // the island's own band, where there is nothing but grass. A
              // multi-page board's row had to come down out of that band to stay
              // reachable, and down there it covers the penalty area — so the
              // pitch starts below it instead of underneath it. Only the boards
              // that pay for the row pay for the inset.
              // The board is a card, not the page. It used to run to all four
              // edges, which read as paint that had spilled off the screen; with
              // the sport's own dark ground showing round it and the corners
              // taken off, the pitch reads as something laid on the table. The
              // corner buttons stay where they are, half on the card and half
              // off, which is how they stop being part of the pitch.
              //
              // Sideways, the board takes the whole height. A pitch is longer than
              // it is wide and a sideways screen is wider still, so the pitch is
              // fitted by height and leaves a wide margin of turf at each end —
              // room enough for the corner buttons to float in, which is what the
              // chrome band was reserving space for. Upright the inset stays: a
              // penalty corner puts the injector on the backline, in the corner,
              // and the page badge sat on top of him.
              LayoutBuilder(
                builder: (context, box) {
                  // A phone turned sideways gives the card the whole
                  // height: the 8pt of page above and below it were the
                  // one margin left on a screen with none to spare, and a
                  // pitch fitted by the card's height grows by them
                  // (reported 2026-10-17). A tablet keeps its breathing room.
                  final phoneSideways = isLandscape &&
                      MediaQuery.sizeOf(context).shortestSide < 600;
                  final foot = phoneSideways ? 0.0 : T.s8;
                  var top = isLandscape
                      ? foot
                      : _pagesBand(context, topPad, wideChrome);
                  // An upright phone whose court leaves a deep band at its
                  // far end — a volleyball or tennis court, with the
                  // server's zone behind the end line — starts its card
                  // right under the inset, and the corner circles float
                  // on that band, the way they float on the board turned
                  // sideways. The row they stood on was page, and the
                  // court lost it (reported 2026-10-16). A pitch whose
                  // band is shallow keeps the card below the circles: a
                  // penalty corner's injector stands in that corner.
                  if (!isLandscape &&
                      !wideChrome &&
                      MediaQuery.sizeOf(context).shortestSide < 600) {
                    final reach = _chromeTop(topPad) + chromeCircle(context) -
                        topPad;
                    final canvas = Size(box.maxWidth - T.s8 * 2,
                        box.maxHeight - topPad - T.s8);
                    final sport = context.read<TacticsState>().sportType;
                    if (canvas.height > 0 &&
                        sport.fieldRect(canvas).top >= reach + 28) {
                      top = topPad;
                    }
                  }
                  // Upright on a phone the card runs edge to edge too: the
                  // court is fitted by the card's width there, and the 8pt
                  // of page at each side was court (reported 2026-10-17).
                  final phone = MediaQuery.sizeOf(context).shortestSide < 600;
                  final side = isLandscape
                      ? _endGutter(
                          context,
                          Size(box.maxWidth, box.maxHeight - top - foot),
                          across,
                        )
                      : (phone ? 0.0 : T.s8);
                  // A drill's step note is a text element on the board, not chrome
                  // painted over it — so it is placed once the board knows its own
                  // size and which way round it is drawn, which is this frame.
                  if (context.select<TacticsState, bool>((s) => s.noteWanted)) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => context.read<TacticsState>().placeDrillNote(
                        sideways: isLandscape,
                        maxWidth: textElementMaxWidth(context, '', note: true),
                      ),
                    );
                  }
                  // Turned since the note was put down, and it has not been
                  // moved: under the court is now another side of the canvas.
                  final placed = context.select<TacticsState, bool?>(
                    (s) => s.notePlacedSideways,
                  );
                  if (placed != null && placed != isLandscape) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => context.read<TacticsState>().reorientDrillNote(
                        sideways: isLandscape,
                        maxWidth: textElementMaxWidth(context, '', note: true),
                      ),
                    );
                  }
                  // The rail's side keeps no gutter: the board runs up to
                  // the rail, and the one circle there — Back, in the top
                  // corner — lies over the corner of the court, where a
                  // drill puts nobody (reported 2026-10-17). The far side
                  // keeps the gutter the four circles there need.
                  final railLeft = IslandSide.side.value == 'left';
                  final leftPad = isLandscape && railLeft ? T.s8 : side;
                  final rightPad = isLandscape && !railLeft ? T.s8 : side;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(leftPad, top, rightPad, foot),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(
                          Radius.circular(T.rBoard),
                        ),
                        boxShadow: T.shadowFloat,
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(T.rBoard),
                        ),
                        child: isLandscape
                            ? const RotatedBox(
                                quarterTurns: 1,
                                child: TacticsCanvas(boardTurns: 1),
                              )
                            : const TacticsCanvas(),
                      ),
                    ),
                  );
                },
              ),
              // Presentation mode swaps all editing chrome for a clean, locked
              // overlay; the normal board chrome is shown otherwise.
              Consumer<TacticsState>(
                builder: (context, state, _) {
                  if (state.presentationMode) {
                    return _PresentationOverlay(topPad: topPad);
                  }
                  // The selection edit bar spans the bottom width; the bottom
                  // corner controls fade out while it's open so the panel never
                  // overlaps the Half Court / zoom / fullscreen buttons.
                  final editPanelOpen =
                      !state.isAnimating &&
                      (state.isDrawingMode ||
                          state.selectedStrokeId != null ||
                          state.selectedPlayerId != null);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // The first-run coach mark sits under the corner chrome and gets out
                      // of the way for good once the coach selects or draws anything.
                      if (!editPanelOpen) const _FirstRunHint(),
                      // Always: the board is pushed from the sport's home page now, in
                      // every build. It used to be the root — so a single-sport app had no
                      // back button at all, and once the home page went in front of it
                      // there was no way off the board. The board swallows the edge-swipe
                      // (it draws with it), so this is the only way back.
                      // Not when the rail stands at the screen's left: the
                      // way back is at its head there, the top-left of the
                      // screen (reported 2026-10-17).
                      if (!(isLandscape &&
                          MediaQuery.sizeOf(context).shortestSide < 600 &&
                          IslandSide.side.value == 'left' &&
                          state.toolbarVisible))
                        Positioned(
                          top: chromeTop,
                          left: 12,
                          child: const _BackButton(),
                        ),
                      // Pages. Always there, because a routine is several boards and the
                      // way to make the second one has to be visible before anybody knows
                      // they want it; a coach wrote a review saying there was no easy way
                      // to add pages, and there was no way at all.
                      // Beside the menu while it is one circle; on its own row once it
                      // grows chevrons, because three circles anchored right reach into
                      // the island.
                      // Sideways it keeps the top row, beside the menu: the band above the
                      // court runs the whole width of the card, so anything in it is off
                      // the pitch however wide the badge grows. On a board whose spare
                      // room is at the ends instead (see [_chromeAcross]) there is no such
                      // band — a badge beside the menu sat on the touchline — so there it
                      // stacks under the menu, down the end margin, the same column the
                      // zoom and fullscreen buttons make at the bottom corner.
                      Positioned(
                        top: across
                            ? chromeTop
                            : isLandscape
                            ? _chromeTop(topPad) + chromeCircle(context) + T.s8
                            : wideChrome
                            ? _pagesTop(topPad)
                            : _chromeTop(topPad),
                        right: across
                            ? 12 + chromeCircle(context) + T.s8
                            : wideChrome || isLandscape
                            ? 12
                            : 12 + chromeCircle(context),
                        child: const _PagesButton(),
                      ),
                      Positioned(
                        top: chromeTop,
                        right: 12,
                        child: _MenuButton(),
                      ),
                      // A rotation board's stepper: see _RotationPill. Top
                      // centre of the chrome row on a tablet and a phone
                      // turned sideways. Upright, a phone's top centre is
                      // the Dynamic Island — the pill sat behind it — so
                      // there it goes down a row and to the left, on the
                      // board's band over the far court, which a rotation
                      // board leaves empty; a multi-page board's pages
                      // badge shares that row on the right.
                      Builder(builder: (context) {
                        final islandRow = !isLandscape &&
                            MediaQuery.sizeOf(context).shortestSide < 600;
                        // In the bottom chrome instead, while that row is
                        // free: see _bottomBar.
                        final below = _pillInBottomRow(context) &&
                            context.select<TacticsState, bool>(
                                (s) => !s.hasMoves && s.toolbarVisible);
                        if (below) return const SizedBox.shrink();
                        // The phone's playback row is taken: down the
                        // board's left margin instead, level with the net,
                        // as a column — the band over the court is too
                        // thin for the pill and it overlapped the corner.
                        if (islandRow) {
                          return const Positioned(
                            left: 6,
                            top: 0,
                            bottom: 0,
                            child: Center(child: _RotationPill(vertical: true)),
                          );
                        }
                        return Positioned(
                          top: chromeTop,
                          left: 0,
                          right: 0,
                          child: const Center(child: _RotationPill()),
                        );
                      }),
                      _CollapsibleEditPanel(),
                      // Zoom and fullscreen live in the tool capsule now, on every screen
                      // wide enough to hold them (viewButtonsInBar). What stays on the
                      // board regardless is the way back: fullscreen hides the capsule,
                      // and a button that hides itself cannot be pressed again, so while
                      // the toolbar is away this circle sits in the bottom corner — on
                      // the turf, which is fine for the moment a coach is presenting and
                      // not editing. The zoom-reset is there too, for a board zoomed in.
                      // A phone too narrow for the pair in the bar gets both of them
                      // here as well, floating, the way every phone did before.
                      Selector<TacticsState, bool>(
                        selector: (_, s) => s.toolbarVisible,
                        builder: (context, visible, _) {
                          final inBar = viewButtonsInBar(context);
                          final buttons = [
                            _ZoomResetButton(across: across),
                            if (!inBar) _ZoomModeButton(across: across),
                            if (!inBar || !visible) _FullscreenButton(),
                          ];
                          final pair = IgnorePointer(
                            ignoring: editPanelOpen,
                            child: AnimatedOpacity(
                              opacity: editPanelOpen ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 160),
                              // Laid along the bottom band where there is one, so the
                              // pair does not climb the end margin the board no longer
                              // leaves for it.
                              child: across
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: buttons,
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: buttons,
                                    ),
                            ),
                          );
                          // A phone turned sideways with the circles down the
                          // end: the pair joins menu and pages at the top of
                          // that column, so the foot of the board — where a
                          // drill's sentence and the bottom corner's players
                          // are — is clear (asked for 2026-10-17).
                          if (isLandscape &&
                              !across &&
                              MediaQuery.sizeOf(context).shortestSide < 600) {
                            return Positioned(
                              top: _chromeTop(topPad) +
                                  2 * (chromeCircle(context) + T.s8),
                              right: 12,
                              child: pair,
                            );
                          }
                          return _ClearOfText(
                            // 4 rather than 12 where the band is the court's own
                            // clearance: [_chromeAcross] measured it to the point.
                            bottom: across ? 4 : 12,
                            right: 12,
                            child: pair,
                          );
                        },
                      ),
                      // Fullscreen hides the rail, and with it the only way to walk a
                      // drill — which is the one thing fullscreen is FOR. Three circles
                      // in the opposite bottom corner from the zoom pair: back a beat,
                      // play, forward a beat. Only on a board that has beats.
                      Selector<
                        TacticsState,
                        ({bool show, int at, int steps, bool playing})
                      >(
                        selector: (_, s) => (
                          show:
                              !s.toolbarVisible &&
                              !s.presentationMode &&
                              s.hasMoves,
                          at: s.atStep,
                          steps: s.maxMoveSteps,
                          playing: s.isAnimating,
                        ),
                        builder: (context, sel, _) {
                          if (!sel.show) return const SizedBox.shrink();
                          final state = context.read<TacticsState>();
                          final d = chromeCircle(context);
                          Widget circle(IconData icon, VoidCallback? onTap) =>
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: onTap,
                                  child: Opacity(
                                    opacity: onTap == null ? 0.35 : 1.0,
                                    child: _GlassCircle(
                                      size: d,
                                      child: Icon(
                                        icon,
                                        color: T.text,
                                        size: 18 * uiScale(context),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                          return _ClearOfText(
                            bottom: across ? 4 : 12,
                            left: 12,
                            child: IgnorePointer(
                              ignoring: editPanelOpen,
                              child: AnimatedOpacity(
                                opacity: editPanelOpen ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 160),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    circle(
                                      Icons.chevron_left_rounded,
                                      sel.at > 0 ? state.stepBackward : null,
                                    ),
                                    circle(
                                      sel.playing
                                          ? Icons.stop_rounded
                                          : Icons.play_arrow_rounded,
                                      sel.playing
                                          ? state.stopAnimation
                                          : state.startAnimation,
                                    ),
                                    circle(
                                      Icons.chevron_right_rounded,
                                      sel.at < sel.steps
                                          ? state.stepForward
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Last in the stack, so it is over the board and over the edit bar —
                      // which opens in the same breath as the selection this explains, and
                      // took the bottom of the screen with it.
                      const _FocusHint(),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Drop handler for photos dragged from the My Teams strip — converts the
  /// global drop point into canvas coords and adds a player there.
  void _onPhotoDropped(
    BuildContext context,
    DragTargetDetails<PhotoDragData> details,
  ) {
    final state = context.read<TacticsState>();
    final ro = boardRepaintKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.attached) return;
    final localFromBoard = ro.globalToLocal(details.offset);
    final size = state.canvasSize;
    if (size.isEmpty) return;
    int max = 0;
    for (final p in state.players.where((p) => p.team == details.data.team)) {
      final n = int.tryParse(p.label) ?? 0;
      if (n > max) max = n;
    }
    final clamped = Offset(
      localFromBoard.dx.clamp(24.0, size.width - 24.0),
      localFromBoard.dy.clamp(24.0, size.height - 24.0),
    );
    state.addPlayer(
      PlayerIcon(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: '${max + 1}',
        team: details.data.team,
        position: clamped,
        photoId: details.data.photo.id,
      ),
    );
    HapticFeedback.lightImpact();
  }

  /// An upright phone: the rotation stepper lives in the playback row of
  /// the bottom chrome whenever that row has no playback capsule in it.
  bool _pillInBottomRow(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.shortestSide < 600 && size.height > size.width;
  }

  Widget _bottomBar(BuildContext context, double bottomPad) {
    return Selector<TacticsState, ({bool visible, bool moves, bool present})>(
      selector: (_, s) => (
        visible: s.toolbarVisible,
        moves: s.hasMoves,
        present: s.presentationMode,
      ),
      builder: (context, sel, _) {
        // Presentation mode hides the whole toolbar/play bar — the locked
        // overlay carries its own large playback controls.
        if (sel.present) return SizedBox(height: bottomPad > 0 ? 36 : 20);
        final foot = SizedBox(height: bottomPad > 0 ? 36 : 20);
        return _ReportHeight(child: LayoutBuilder(
          builder: (context, box) {
            // One row, side by side, where there is room for both capsules at
            // their full width: a tablet or a window. Two rows of chrome under
            // a board that already has the width for them is a phone layout
            // nobody shrank the screen for. The threshold is the tool bar's own
            // cap plus what the playback capsule takes; below it they stack, so
            // every phone keeps what it had. An upright tablet from 760pt
            // joins them too, the tools folding to icons (tightTabletRow):
            // the court is twice as tall as it is wide, so the row given
            // back is all court.
            final oneRow = sel.visible &&
                sel.moves &&
                (box.maxWidth >= 1100 ||
                    (uiScale(context) > 1 && box.maxWidth >= 760));
            if (oneRow) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: T.s16),
                      PlayControlsBar(state: context.read<TacticsState>()),
                      const SizedBox(width: T.s12),
                      // Whatever is left, which its own centeredPanel caps at
                      // kBarMaxWidth. Fixed at that width the pair ran off an
                      // 11-inch iPad, where a tablet's bigger buttons make the
                      // playback capsule half as wide again as a phone's.
                      const Expanded(child: TacticsToolbar()),
                    ],
                  ),
                  foot,
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sel.visible)
                  SizedBox(
                    height: playBarHeight(context),
                    // A board with nothing to play leaves this row empty,
                    // and an upright phone's rotation stepper takes it
                    // (see _RotationPill): the board's top band, where it
                    // sat, is a thin strip between the island row and the
                    // far court. With runs on the board the playback
                    // capsule is here and the pill goes back up.
                    child: sel.moves
                        ? Center(
                            child: PlayControlsBar(
                              state: context.read<TacticsState>(),
                            ),
                          )
                        : _pillInBottomRow(context)
                            ? const Center(child: _RotationPill())
                            : null,
                  ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: sel.visible
                      ? const TacticsToolbar()
                      : const SizedBox.shrink(),
                ),
                foot,
              ],
            );
          },
        ));
      },
    );
  }

  Widget _landscapeSidePanel(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    // A phone screen is a rounded rectangle, and the corner eats sideways
    // into the edge: with a 55pt radius, 8pt down from the top the right
    // edge has already come 26pt in. The rail's first and last rows sit in
    // exactly that band, which is why Move and the replay button arrived
    // with their ends shaved off. So on a phone with rounded corners the
    // rail keeps its content off the edge and off the two ends; a flat
    // old phone (no insets anywhere) keeps the tight margins it had.
    final rounded = pad.left > 0 || pad.right > 0 || pad.bottom > 0;
    final edge = rounded ? 14.0 : 4.0;
    final vPad = rounded ? 20.0 : 8.0;
    // The three wide text rows are the ones that run behind the Dynamic
    // Island: measured on a 402pt edge the pill covers the middle third,
    // roughly y 130..270, which is Add, Save/Share and Clear. The modes sit
    // above it and the playback controls below, and what is left in the
    // middle is the Spacer. So only these three give ground — the rail
    // itself runs to the screen edge, and the board keeps the 59pt that a
    // SafeArea over the whole edge used to take off the court.
    // On the left, when that is where the island is, it all mirrors: the
    // screen edge — and the pill — are on the rail's left.
    final onLeft = IslandSide.side.value == 'left';
    final dodge = onLeft
        ? EdgeInsets.only(left: math.max(0, pad.left - edge))
        : EdgeInsets.only(right: math.max(0, pad.right - edge));
    return Consumer<TacticsState>(
      builder: (context, state, _) => Padding(
        // With Back at its head (rail on the left) the column is a row
        // taller and ran 10pt off the foot of a 402pt screen (reported
        // 2026-10-17). The head comes up 8: a 44pt circle 14 in from the
        // edge is clear of the screen's 55pt corner from 12 down.
        padding: onLeft
            ? EdgeInsets.fromLTRB(edge, rounded ? 12 : vPad, 4, vPad)
            : EdgeInsets.fromLTRB(4, vPad, edge, vPad),
        child: Column(
          children: [
            // The way back, at the top-left of the screen when the rail is
            // there (reported 2026-10-17); the board's own corner otherwise.
            // Back at the head, with undo and redo beside it in the room
            // its row had to its right (asked for 2026-10-17): one row
            // instead of two.
            if (onLeft) ...[
              Row(
                children: [
                  const _BackButton(),
                  const Spacer(),
                  _lCircleBtn(
                    Icons.undo_rounded,
                    T.accentText,
                    state.canUndo ? state.undo : null,
                  ),
                  const SizedBox(width: 10),
                  _lCircleBtn(
                    Icons.redo_rounded,
                    T.accentText,
                    state.canRedo ? state.redo : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Mode buttons — Move / Draw / Select, matching the portrait
            // toolbar's _ModeSegment so landscape exposes the same modes.
            Row(
              children: [
                Expanded(
                  child: _lBtn(
                    'mode_move',
                    !state.isDrawingMode && !state.multiSelectMode,
                    () {
                      state.setMultiSelectMode(false);
                      state.setDrawingMode(false);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _lBtn(
                    'mode_draw',
                    state.isDrawingMode,
                    () => state.setDrawingMode(true),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _lBtn(
                    'mode_select',
                    state.multiSelectMode,
                    () => state.setMultiSelectMode(!state.multiSelectMode),
                  ),
                ),
              ],
            ),
            SizedBox(height: onLeft ? 6 : 10),
            // Undo / Redo — always reachable
            if (!onLeft) ...[
            Padding(
              padding: dodge,
              child: Row(
              // Flush with Add's two edges below, not centred in the rail
              // (reported 2026-10-17): the same island dodge, one circle
              // at each end.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _lCircleBtn(
                  Icons.undo_rounded,
                  T.accentText,
                  state.canUndo ? state.undo : null,
                ),
                _lCircleBtn(
                  Icons.redo_rounded,
                  T.accentText,
                  state.canRedo ? state.redo : null,
                ),
              ],
            ),
            ),
            const SizedBox(height: 10),
            ],
            // Action buttons
            Padding(
              padding: dodge,
              child: _lWideBtn(
                Icons.add_rounded,
                'add_label',
                () => showAddElementSheet(context, state),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: dodge,
              child: Row(
                children: [
                  Expanded(
                    child: _lBtn(
                      'save',
                      false,
                      () => showSaveLoadSheet(context, state),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _lBtn(
                      'share',
                      false,
                      () => shareBoardImage(context, state),
                    ),
                  ),
                ],
              ),
            ),
            if (state.players.isNotEmpty || state.strokes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: dodge,
                child: _lWideBtn(
                  Icons.delete_sweep_outlined,
                  'clear',
                  () => confirmClearAll(context, state),
                  color: T.danger,
                ),
              ),
            ],
            const Spacer(),
            // Play controls
            if (state.hasMoves) ...[
              const Divider(color: Color(0x4DFFFFFF)),
              const SizedBox(height: 4),
              // Step + controls in compact layout
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _lCircleBtn(
                    Icons.chevron_left_rounded,
                    T.textDim,
                    state.atStep > 0 ? state.stepBackward : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '${state.atStep}/${state.maxMoveSteps}',
                      // On the page's deep ground, like the chips' rims.
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _lCircleBtn(
                    Icons.chevron_right_rounded,
                    T.textDim,
                    state.atStep < state.maxMoveSteps
                        ? state.stepForward
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _lCircleBtn(
                    Icons.replay,
                    T.textDim,
                    state.atStep > 0 ? state.clearAnimatedPositions : null,
                  ),
                  const SizedBox(width: 4),
                  _lCircleBtn(
                    state.isAnimating
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    // Play is the one coloured control: the app's accent.
                    T.accentText,
                    !state.isAnimating
                        ? state.startAnimation
                        : state.stopAnimation,
                  ),
                  const SizedBox(width: 4),
                  _lCircleBtn(
                    Icons.show_chart,
                    state.routesOn ? T.textDim : T.warning,
                    state.toggleShowMoveLines,
                  ),
                  const SizedBox(width: 4),
                  _lCircleBtn(
                    Icons.view_timeline_outlined,
                    T.textDim,
                    () {
                      showModalBottomSheet(
                        context: context,
                        constraints: sheetConstraints(context),
                        backgroundColor: T.surface,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (ctx) =>
                            scaledSheet(ctx, TimelineEditor(state: state)),
                      );
                    },
                  ),
                ],
              ),
            ],
            // 4, not 8: an iPhone SE turned sideways gives the rail 304pt and
            // its contents want 305.
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _lBtn(String key, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        // On the capsule's own white, like the upright tool bar's tools:
        // a grey chip under every button made the rail a grey block
        // beside a white page (reported 2026-10-17). The chosen one is
        // the dark pill, as upright.
        decoration: BoxDecoration(
          color: active ? T.toolOn : T.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: T.shadowFloat,
        ),
        // One line, shrunk to fit rather than wrapped: the rail is narrow and
        // "Sélectionner" took three lines of it, which pushed the playback
        // controls off the bottom. Scaling keeps the rail the same height in
        // every language.
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              key.tr(),
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: active ? T.onToolOn : T.textDim,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lCircleBtn(IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap != null ? 1.0 : 0.35,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: T.surface,
            shape: BoxShape.circle,
            boxShadow: T.shadowFloat,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _lWideBtn(
    IconData icon,
    String key,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: T.shadowFloat,
        ),
        // Shrunk to fit rather than clipped, same as _lBtn: these rows step
        // aside for the island and "Añadir" is wider than what is left.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color ?? T.textDim, size: 18),
              const SizedBox(width: 6),
              Text(
                key.tr(),
                maxLines: 1,
                softWrap: false,
                style: TextStyle(color: color ?? T.textDim, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// iOS-style frosted glass circular button — translucent fill on top of a
/// real-time backdrop blur. Used for top-corner chrome (back / menu / fullscreen).
class _GlassCircle extends StatefulWidget {
  final double size;
  final Widget child;
  final BoxBorder? border;
  const _GlassCircle({required this.size, required this.child, this.border});

  @override
  State<_GlassCircle> createState() => _GlassCircleState();
}

class _GlassCircleState extends State<_GlassCircle> {
  // A trackpad or mouse pointer over it: a hand cursor and a lighter fill,
  // so the corner chrome says it is a button before it is clicked.
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.size, child = widget.child, border = widget.border;
    // Shadow is drawn by the outer DecoratedBox so it's not clipped away by
    // ClipOval; the BackdropFilter blurs the field/board content underneath.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Light glass: the disc sits on the light page above the board
              // as often as on the court, and a dark disc went grey on the
              // page. White at 82% over the blur reads on both.
              color: _hover
                  ? Colors.white.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.82),
              shape: BoxShape.circle,
              // A hairline so the circle has an edge on a bright court as
              // well as the page. Callers that pass their own border — the
              // plan-mode accent ring — still win.
              border: border ?? Border.all(color: T.border),
            ),
            child: child,
          ),
        ),
      ),
    ));
  }
}

/// A rotation board's stepper, on the board: ‹ Rotation n › with the
/// setter's zone under it. The full controls — system, phase, rule set,
/// the libero — stay in the Add panel, but that panel covers the near half
/// of the court on an iPad, so stepping through rotations there showed
/// nothing moving. Top centre, in the band over the far court, which a
/// rotation board leaves empty. Reported 2026-10-16.
class _RotationPill extends StatelessWidget {
  /// A column down the board's margin: chevron, "R3", chevron. For an
  /// upright phone whose playback row is taken; the zone is in the Add
  /// panel.
  final bool vertical;
  const _RotationPill({this.vertical = false});

  @override
  Widget build(BuildContext context) {
    return Selector<TacticsState, RotationSetup?>(
      selector: (_, s) => s.rotation,
      builder: (context, r, _) {
        if (r == null) return const SizedBox.shrink();
        final state = context.read<TacticsState>();
        final s = uiScale(context);
        final dim = chromeCircle(context);
        if (vertical) {
          Widget tap(IconData icon, int by, String tip) => Semantics(
                button: true,
                label: tip,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => state.applyRotation(r.rotated(by)),
                  child: SizedBox(
                    width: dim,
                    height: dim * 0.8,
                    child: Icon(icon, color: T.text, size: 22 * s),
                  ),
                ),
              );
          return _glass(
            dim,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                tap(Icons.expand_less_rounded, -1, 'rotation_back'.tr()),
                Text(
                  'R${r.rotation}',
                  style: TextStyle(
                    color: T.text,
                    fontSize: 13 * s,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                tap(Icons.expand_more_rounded, 1, 'rotation_forward'.tr()),
              ],
            ),
          );
        }
        Widget arrow(IconData icon, int by, String tip) => Semantics(
              button: true,
              label: tip,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => state.applyRotation(r.rotated(by)),
                child: SizedBox(
                  width: dim,
                  height: dim,
                  child: Icon(icon, color: T.text, size: 22 * s),
                ),
              ),
            );
        return _glass(
          dim,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4 * s),
            child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    arrow(Icons.chevron_left_rounded, -1,
                        'rotation_back'.tr()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6 * s),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'rotation_number'
                                .tr(namedArgs: {'n': '${r.rotation}'}),
                            style: TextStyle(
                              color: T.text,
                              fontSize: 13 * s,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'rotation_setter_zone'.tr(namedArgs: {
                              'z': '${r.zoneOf(r.activeSetter) ?? ''}'
                            }),
                            style: TextStyle(
                              color: T.textOff,
                              fontSize: 10.5 * s,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    arrow(Icons.chevron_right_rounded, 1,
                        'rotation_forward'.tr()),
                  ],
                ),
          ),
        );
      },
    );
  }

  /// The same light glass as the circles beside it.
  static Widget _glass(double radius, Widget child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: T.border),
              ),
              child: child,
            ),
          ),
        ),
      );
}


/// The way back off the board: to the home page, or to the plan or the run
/// that opened it. On the board's top-left corner, or at the head of a
/// sideways phone's rail when that is the screen's top-left.
class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Selector<TacticsState, (String?, String?)>(
                          selector: (_, s) =>
                              (s.editingFromPlan, s.runningPlanName),
                          builder: (context, tuple, _) {
                            final planName = tuple.$1;
                            final runName = tuple.$2;
                            final inPlanMode =
                                planName != null || runName != null;
                            // Named for VoiceOver: a bare GestureDetector
                            // was a silent, unlabelled spot on the screen.
                            return Semantics(
                              button: true,
                              label: 'common_back'.tr(),
                              child: GestureDetector(
                              onTap: () async {
                                final state = context.read<TacticsState>();
                                if (runName != null) {
                                  // Auto-save tactic edits made during a run, matching the
                                  // plan-edit branch below.
                                  if (state.currentTacticName != null) {
                                    try {
                                      await state.saveTactics(
                                        state.currentTacticName!,
                                      );
                                    } catch (_) {}
                                  }
                                  final startIdx = state.runningItemIndex;
                                  state.runningPlanName = null;
                                  state.editingFromPlan = null;
                                  // The run page that opened this board is
                                  // right underneath: go back to it. Pushing
                                  // a fresh one each time is what looped.
                                  if (!context.mounted) return;
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                    return;
                                  }
                                  final p =
                                      await PracticeService.load(
                                        state.sportType,
                                        runName,
                                      ) ??
                                      Practice(name: runName);
                                  if (!context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PracticeRunPage(
                                        state: state,
                                        practice: p,
                                        initialIndex: startIdx,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (planName != null) {
                                  // Auto-save tactic edits made while in plan-edit mode, so
                                  // the disk file (and cloud sync) pick up new players/moves
                                  // without requiring a manual Save tap.
                                  if (state.currentTacticName != null) {
                                    try {
                                      await state.saveTactics(
                                        state.currentTacticName!,
                                      );
                                    } catch (_) {}
                                  }
                                  state.editingFromPlan = null;
                                  final p =
                                      await PracticeService.load(
                                        state.sportType,
                                        planName,
                                      ) ??
                                      Practice(name: planName);
                                  if (!context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PracticeEditPage(
                                        state: state,
                                        practice: p,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                // Back to the sport's home page, which is what pushed
                                // the board. It used to replace the route with the sport
                                // grid, which skipped the home page in the hub and did
                                // not exist at all in a single-sport build.
                                Navigator.of(context).maybePop();
                              },
                              child: _GlassCircle(
                                size: chromeCircle(context),
                                border: inPlanMode
                                    ? Border.all(color: T.selectedStroke, width: 1.5)
                                    : null,
                                child: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: inPlanMode ? T.accentText : T.text,
                                  size: 16 * uiScale(context),
                                ),
                              ),
                              ),
                            );
                          },
                        );
  }
}

/// The page counter, and the way in to the rest of them.
///
/// Flicking is the thing the reviewer asked for, so the chevrons are on the
/// board itself once there is more than one page; adding, copying and
/// deleting live behind the counter, which is where you go when you are
/// thinking about the routine rather than drawing it.
class _PagesButton extends StatelessWidget {
  const _PagesButton();

  @override
  Widget build(BuildContext context) {
    return Selector<TacticsState, (int, int)>(
      selector: (_, s) => (s.pageIndex, s.pageCount),
      builder: (context, tuple, _) {
        final state = context.read<TacticsState>();
        final index = tuple.$1;
        final count = tuple.$2;
        final s = uiScale(context);
        final dim = chromeCircle(context);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count > 1) ...[
              GestureDetector(
                onTap: index > 0 ? () => state.goToPage(index - 1) : null,
                child: _GlassCircle(
                  size: dim,
                  child: Icon(
                    Icons.chevron_left,
                    color: index > 0 ? T.text : T.textDisabled,
                    size: 20 * s,
                  ),
                ),
              ),
              SizedBox(width: 4 * s),
            ],
            GestureDetector(
              onTap: () => _openSheet(context, state),
              child: _GlassCircle(
                size: dim,
                child: Text(
                  count > 1 ? '${index + 1}/$count' : '1',
                  style: TextStyle(
                    color: T.text,
                    fontSize: (count > 1 ? 11 : 13) * s,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            if (count > 1) ...[
              SizedBox(width: 4 * s),
              GestureDetector(
                onTap: index < count - 1
                    ? () => state.goToPage(index + 1)
                    : null,
                child: _GlassCircle(
                  size: dim,
                  child: Icon(
                    Icons.chevron_right,
                    color: index < count - 1 ? T.text : T.textDisabled,
                    size: 20 * s,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _openSheet(BuildContext context, TacticsState state) {
    TacticalSheet.show<void>(
      context,
      builder: (ctx) => scaledSheet(
        ctx,
        TacticalSheet(
          maxHeightFraction: 0.6,
          padding: const EdgeInsets.fromLTRB(
            T.screenX,
            T.s12,
            T.screenX,
            T.s16,
          ),
          child: Consumer<TacticsState>(
            builder: (context, s, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TacticalSheetHeader(
                  title: 'pages_title'.tr(),
                  subtitle: 'pages_hint'.tr(),
                ),
                const SizedBox(height: T.s12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var i = 0; i < s.pageCount; i++)
                          _PageRow(
                            index: i,
                            current: i == s.pageIndex,
                            canDelete: s.pageCount > 1,
                            onTap: () => s.goToPage(i),
                            onDelete: () => s.deletePage(i),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: T.s12),
                Row(
                  children: [
                    Expanded(
                      child: TacticalButton(
                        label: 'pages_duplicate'.tr(),
                        icon: Icons.copy_all_outlined,
                        onTap: () => s.addPage(copyCurrent: true),
                      ),
                    ),
                    const SizedBox(width: T.s8),
                    Expanded(
                      child: TacticalButton(
                        label: 'pages_add'.tr(),
                        icon: Icons.add,
                        quiet: true,
                        onTap: () => s.addPage(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageRow extends StatelessWidget {
  final int index;
  final bool current;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _PageRow({
    required this.index,
    required this.current,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: T.s8),
        padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s12),
        decoration: BoxDecoration(
          color: current ? T.accentFill : T.surfaceHi,
          borderRadius: T.brMd,
          border: current ? Border.all(color: T.selectedStroke, width: 1.5) : null,
        ),
        child: Row(
          children: [
            Text(
              '${index + 1}',
              style: TextStyle(
                color: current ? T.accentText : T.textDim,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: T.s12),
            Expanded(
              child: Text(
                'pages_page'.tr(args: ['${index + 1}']),
                style: TextStyle(
                  color: current ? T.text : T.textDim,
                  fontSize: 15,
                ),
              ),
            ),
            if (canDelete)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: kDanger,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    return PopupMenuButton<String>(
      onSelected: (value) => _onSelected(context, value),
      // A compact anchored popover, grouped: it used to be a full-width
      // slab where every entry carried the same weight, so "Language" read
      // as loudly as "Presentation".
      color: T.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shadowColor: const Color(0x73000000),
      constraints: const BoxConstraints(minWidth: 250, maxWidth: 280),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: T.border),
      ),
      // Anchored under the ellipsis it came from.
      offset: const Offset(0, 46),
      padding: EdgeInsets.zero,
      child: _GlassCircle(
        size: chromeCircle(context),
        child: Icon(Icons.more_horiz, color: T.text, size: 18 * s),
      ),
      itemBuilder: (ctx) {
        final sport = ctx.read<TacticsState>().sportType;
        final showPro =
            PurchaseService.instance.isStoreEnabled &&
            AdService.instance.servesAds &&
            !PurchaseService.instance.hasPro;
        return [
          // Working with the board
          _menuItem('present', Icons.co_present_outlined, 'present_mode'.tr()),
          if (sport == SportType.soccer)
            _menuItem('field', Icons.grass_outlined, 'menu_field'.tr()),
          if (sport.hasCourtPicker)
            _menuItem('court', Icons.dashboard_outlined, 'menu_court'.tr()),
          _menuItem('drills', Icons.menu_book_outlined, 'drills_title'.tr()),
          // Also here, not only on the toolbar: the toolbar drops this
          // button on a narrow phone, and the boards have to stay reachable.
          _menuItem('boards', Icons.folder_outlined, 'boards'.tr()),
          _menuItem(
            'practice',
            Icons.event_note_outlined,
            'practice_plan'.tr(),
          ),
          _divider(),
          // Getting it out of the app
          _menuItem('share', Icons.ios_share_rounded, 'share'.tr()),
          if (sport.scorerAppleId.isNotEmpty)
            _menuItem('scorer', Icons.scoreboard_outlined, 'menu_scorer'.tr()),
          // Language, Contact Us and Login are not here. They are about the
          // app, not about the board, and they already have a home on the
          // 我的 tab — the account card and the settings list. A full-screen
          // editor's one menu should be things you do to what is on the
          // screen; three ways out of it made the list a second settings
          // page that happened to be reachable from a pitch.
          if (showPro) ...[
            _divider(),
            _menuItem(
              'pro',
              Icons.workspace_premium_outlined,
              'menu_remove_ads'.tr(),
              tint: T.accent,
            ),
          ],
          _divider(),
          // Destructive, and rare: it used to sit a thumb's width from Undo
          // on the toolbar, where the two are easy to confuse.
          _menuItem(
            'clear',
            Icons.delete_sweep_outlined,
            // The menu item asks for the action; the confirm dialog is what
            // asks the question. Both were reading 'Clear Board?'.
            'clear_all'.tr(),
            tint: T.danger,
          ),
        ];
      },
    );
  }

  PopupMenuEntry<String> _divider() => const PopupMenuItem<String>(
    enabled: false,
    height: 9,
    padding: EdgeInsets.zero,
    child: TacticalDivider(),
  );

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    Color? tint,
  }) {
    return PopupMenuItem(
      value: value,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: T.s16),
      child: Row(
        children: [
          Icon(icon, color: tint ?? T.textDim, size: 19),
          const SizedBox(width: T.s12),
          // Two lines allowed: several of these labels are long in French,
          // Vietnamese and Thai, and the popover is deliberately narrow.
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tint ?? T.text,
                fontSize: 15,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSelected(BuildContext context, String value) {
    switch (value) {
      case 'present':
        context.read<TacticsState>().togglePresentationMode();
      case 'clear':
        confirmClearAll(context, context.read<TacticsState>());
      case 'boards':
        showSaveLoadSheet(context, context.read<TacticsState>());
      case 'field':
        showFieldSettingsSheet(context, context.read<TacticsState>());
      case 'court':
        showCourtSettingsSheet(context, context.read<TacticsState>());
      case 'share':
        shareBoardImage(context, context.read<TacticsState>());
      case 'drills':
        DrillLibraryPage.push(
          context,
          context.read<TacticsState>(),
          onUpgrade: () => _showPaywall(context),
        );
      case 'practice':
        _showPracticePlan(context);
      case 'scorer':
        _showScorer(context);
      case 'pro':
        _showPaywall(context);
    }
  }

  void _showPaywall(BuildContext context) {
    TacticalSheet.show(context, builder: (_) => const _PaywallSheet());
  }

  void _showPracticePlan(BuildContext context) {
    final state = context.read<TacticsState>();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PracticePlanPage(state: state)));
  }

  void _showScorer(BuildContext context) {
    final state = context.read<TacticsState>();
    final sport = state.sportType;
    final appName = sport.scorerAppName;
    final appleId = sport.scorerAppleId;
    if (appleId.isEmpty) return; // not yet on App Store
    final url = Uri.parse('https://apps.apple.com/app/id$appleId');
    TacticalSheet.show(
      context,
      builder: (ctx) => TacticalSheet(
        padding: const EdgeInsets.fromLTRB(0, T.s12, 0, 0),
        child: scaledSheet(
          ctx,
          _ScorerPromoSheet(sport: sport, appName: appName, url: url),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact Us page — email form via API (same as ScoreSyncer/zach_base)
// ─────────────────────────────────────────────────────────────────────────────
class ContactPage extends StatefulWidget {
  const ContactPage({super.key});
  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    // Validation
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${'your_email'.tr()} required')));
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('send_email_error'.tr())));
      return;
    }
    if (body.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${'message'.tr()} required')));
      return;
    }
    final sport = context.read<TacticsState>().sportType;
    final appName = isSingleSportApp ? _flavorAppName(sport) : 'Tactics Board';

    setState(() => _sending = true);
    try {
      final response = await http
          .post(
            Uri.parse('https://tacticsboard.100for1.com/api/v1/send-email'),
            body: {
              'from': 'support@ScoreSyncer.com',
              'to': 'zachsong@gmail.com',
              'email': email,
              'sport': sport.name,
              'app': appName,
              'subject': _subjectCtrl.text.trim().isEmpty
                  ? 'Feedback'
                  : _subjectCtrl.text.trim(),
              'message': body,
            },
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('send_success'.tr()),
            backgroundColor: T.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('send_failed'.tr())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('send_failed'.tr())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.surfaceHi,
      appBar: AppBar(
        title: Text('contact_title'.tr()),
        backgroundColor: T.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'contact_subtitle'.tr(),
              style: const TextStyle(color: T.textDim, fontSize: 16),
            ),
            const SizedBox(height: 20),
            _field(_emailCtrl, 'your_email'.tr(), TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(_subjectCtrl, 'subject'.tr()),
            const SizedBox(height: 12),
            _field(_bodyCtrl, 'message'.tr(), null, 5),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: T.buttonFill,
                foregroundColor: T.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _sending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: T.onAccent,
                      ),
                    )
                  : Text(
                      'send'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _flavorAppName(SportType s) {
    switch (s) {
      case SportType.badminton:
        return 'Badminton Board';
      case SportType.tableTennis:
        return 'Table Tennis Board';
      case SportType.tennis:
        return 'Tennis Board';
      case SportType.basketball:
        return 'Basketball Board';
      case SportType.volleyball:
        return 'Volleyball Board';
      case SportType.pickleball:
        return 'Pickleball Board';
      case SportType.soccer:
        return 'Soccer Board';
      case SportType.fieldHockey:
        return 'Field Hockey Board';
      case SportType.rugby:
        return 'Rugby Board';
      case SportType.baseball:
        return 'Baseball Board';
      case SportType.handball:
        return 'Handball Board';
      case SportType.waterPolo:
        return 'Water Polo Board';
      case SportType.sepakTakraw:
        return 'Sepak Takraw Board';
      case SportType.beachTennis:
        return 'Beach Tennis Board';
      case SportType.footvolley:
        return 'Footvolley Board';
    }
  }

  Widget _field(
    TextEditingController ctrl,
    String label, [
    TextInputType? type,
    int maxLines = 1,
  ]) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(color: T.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: T.textOff),
        filled: true,
        fillColor: T.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: T.focus),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login page — Apple + Google sign-in (same pattern as lang1000/chinesefriend)
// ─────────────────────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService.instance;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    CloudSyncService.statusTick.addListener(_onStatusChange);
    if (_auth.isLoggedIn) {
      // Background probe so the status row reflects server state without
      // forcing a full sync.
      CloudSyncService.probeRemote();
    }
  }

  @override
  void dispose() {
    CloudSyncService.statusTick.removeListener(_onStatusChange);
    super.dispose();
  }

  void _onStatusChange() {
    if (mounted) setState(() {});
  }

  Future<void> _manualSync() async {
    setState(() => _loading = true);
    await CloudSyncService.syncNow();
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('sync_done'.tr()), backgroundColor: T.success),
    );
  }

  Future<void> _loginWithApple() async {
    setState(() => _loading = true);
    final result = await _auth.loginWithApple();
    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${'welcome'.tr()}, ${result.name ?? result.email ?? 'User'}!',
          ),
          backgroundColor: T.success,
        ),
      );
      // Keep spinner on while we pull cloud data so the user doesn't see a
      // half-populated screen if they navigate away immediately.
      await CloudSyncService.syncNow();
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pop(context);
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result.error ?? 'login_failed').tr())),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    final result = await _auth.loginWithGoogle();
    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${'welcome'.tr()}, ${result.name ?? result.email ?? 'User'}!',
          ),
          backgroundColor: T.success,
        ),
      );
      await CloudSyncService.syncNow();
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pop(context);
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result.error ?? 'login_failed').tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = _auth.isLoggedIn;

    return Scaffold(
      backgroundColor: T.surfaceHi,
      appBar: AppBar(
        title: Text('login_title'.tr()),
        backgroundColor: T.surface,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: loggedIn ? _buildLoggedIn() : _buildSignIn(),
        ),
      ),
    );
  }

  Widget _buildLoggedIn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: T.success,
          size: 80,
        ),
        const SizedBox(height: 16),
        Text(
          _auth.userName ?? 'User',
          style: const TextStyle(
            color: T.text,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_auth.userEmail != null)
          Text(
            _auth.userEmail!,
            style: const TextStyle(color: T.textOff, fontSize: 14),
          ),
        const SizedBox(height: 28),
        _buildSyncStatus(),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_loading || CloudSyncService.isSyncing)
                ? null
                : _manualSync,
            icon: const Icon(Icons.cloud_sync_outlined),
            label: Text(
              'sync_now'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: T.buttonFill,
              foregroundColor: T.onAccent,
              disabledBackgroundColor: T.disabledFill,
              disabledForegroundColor: T.textDisabled,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _auth.logout();
              CloudSyncService.reset();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: T.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'logout'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 40),
        TextButton(
          onPressed: _confirmDeleteAccount,
          style: TextButton.styleFrom(
            foregroundColor: T.textOff,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'delete_account'.tr(),
            style: const TextStyle(
              color: T.textOff,
              fontSize: 12,
              decoration: TextDecoration.underline,
              decorationColor: T.border,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncStatus() {
    final syncing = CloudSyncService.isSyncing;
    final local = CloudSyncService.hasLocalPendingChanges;
    final remote = CloudSyncService.hasRemoteUpdates;
    final last = CloudSyncService.lastSyncAt;

    IconData icon;
    Color color;
    String primary;
    if (syncing) {
      icon = Icons.sync;
      color = T.textDim;
      primary = 'sync_status_syncing'.tr();
    } else if (local && remote) {
      icon = Icons.sync_problem_outlined;
      color = T.warning;
      primary = 'sync_status_both_dirty'.tr();
    } else if (local) {
      icon = Icons.cloud_upload_outlined;
      color = T.warning;
      primary = 'sync_status_local_dirty'.tr();
    } else if (remote) {
      icon = Icons.cloud_download_outlined;
      color = T.warning;
      primary = 'sync_status_remote_dirty'.tr();
    } else if (last == null) {
      icon = Icons.cloud_off_outlined;
      color = T.textOff;
      primary = 'sync_status_never'.tr();
    } else {
      icon = Icons.cloud_done_outlined;
      color = T.accentText;
      primary = 'sync_status_synced'.tr();
    }

    final secondary = last != null
        ? 'sync_last'.tr(args: [_formatRelativeTime(last)])
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  primary,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (secondary != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    style: const TextStyle(color: T.textOff, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'time_just_now'.tr();
    if (diff.inHours < 1) {
      return 'time_minutes_ago'.tr(args: [diff.inMinutes.toString()]);
    }
    if (diff.inDays < 1) {
      return 'time_hours_ago'.tr(args: [diff.inHours.toString()]);
    }
    return 'time_days_ago'.tr(args: [diff.inDays.toString()]);
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'delete_account'.tr(),
          style: const TextStyle(color: T.text),
        ),
        content: Text(
          'delete_account_confirm'.tr(),
          style: const TextStyle(color: T.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _loading = true);
              try {
                final response = await http.delete(
                  Uri.parse(
                    'https://tacticsboard.100for1.com/api/v1/auth/delete-account',
                  ),
                  headers: {
                    'Authorization': 'Bearer ${_auth.token}',
                    'Accept': 'application/json',
                  },
                );
                _auth.logout();
                if (mounted) {
                  setState(() => _loading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        response.statusCode == 200
                            ? 'delete_account_success'.tr()
                            : 'delete_account_failed'.tr(),
                      ),
                    ),
                  );
                }
              } catch (_) {
                _auth.logout();
                if (mounted) setState(() => _loading = false);
              }
            },
            child: Text(
              'delete_account'.tr(),
              style: const TextStyle(color: T.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignIn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.person_outline, color: T.textDisabled, size: 80),
        const SizedBox(height: 24),
        Text(
          'login_subtitle'.tr(),
          style: TextStyle(color: T.textDim, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        if (_loading)
          const CircularProgressIndicator()
        else ...[
          // Apple Sign In — Apple platforms only: on Android the plugin
          // needs a web redirect this app has not set up, so the button
          // could only fail.
          if (Platform.isIOS || Platform.isMacOS) ...[
            _signInButton(
              icon: Icons.apple,
              label: 'login_apple'.tr(),
              color: Colors.white,
              bgColor: Colors.black,
              onTap: _loginWithApple,
            ),
            const SizedBox(height: 14),
          ],
          // Google Sign In
          _signInButton(
            icon: Icons.g_mobiledata,
            label: 'login_google'.tr(),
            color: Colors.black87,
            bgColor: Colors.white,
            onTap: _loginWithGoogle,
          ),
        ],
      ],
    );
  }

  Widget _signInButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ScoreSyncer promotion bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ScorerPromoSheet extends StatelessWidget {
  final SportType sport;
  final String appName;
  final Uri url;
  const _ScorerPromoSheet({
    required this.sport,
    required this.appName,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App icon area
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: T.accentFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(child: SportGlyph(sport: sport, size: 46)),
            ),
            const SizedBox(height: 16),
            Text(
              appName,
              style: const TextStyle(
                color: T.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'scorer_description'.tr(),
              style: const TextStyle(color: T.textOff, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Feature highlights
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _featureChip(
                  Icons.scoreboard_outlined,
                  'scorer_feature_score'.tr(),
                ),
                const SizedBox(width: 8),
                _featureChip(Icons.timer_outlined, 'scorer_feature_timer'.tr()),
                const SizedBox(width: 8),
                _featureChip(
                  Icons.history_rounded,
                  'scorer_feature_history'.tr(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openAppStore(context),
                icon: const Icon(Icons.download, size: 20),
                label: Text(
                  'scorer_download'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: T.buttonFill,
                  foregroundColor: T.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            // Badminton-only training companion apps
            if (sport == SportType.badminton) ...[
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'trainer_also_try'.tr(),
                  style: const TextStyle(
                    color: T.textDim,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _trainerRow(
                context,
                Icons.bolt,
                'trainer_whip_name'.tr(),
                'trainer_whip_desc'.tr(),
                'https://apps.apple.com/app/id6775930960',
              ),
              const SizedBox(height: 8),
              _trainerRow(
                context,
                Icons.directions_run,
                'trainer_footwork_name'.tr(),
                'trainer_footwork_desc'.tr(),
                'https://apps.apple.com/app/id6777419248',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _trainerRow(
    BuildContext context,
    IconData icon,
    String name,
    String desc,
    String urlStr,
  ) {
    return InkWell(
      onTap: () => _openLink(context, urlStr),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: T.surfaceHi,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: T.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: T.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: T.textDim, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: T.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(color: T.textOff, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, color: T.textDisabled, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: T.surfaceHi,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: T.textOff, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: T.textOff, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _openAppStore(BuildContext context) =>
      _openLink(context, url.toString());

  Future<void> _openLink(BuildContext context, String urlStr) async {
    try {
      const channel = MethodChannel('com.zach.tacticsboard/share');
      await channel.invokeMethod('openUrl', {'url': urlStr});
    } catch (_) {
      // Fallback: copy URL to clipboard
      await Clipboard.setData(ClipboardData(text: urlStr));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('scorer_link_copied'.tr()),
            backgroundColor: T.success,
          ),
        );
      }
    }
    if (context.mounted) Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Player/Marker edit bar — shown when a player element is selected
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerEditBar extends StatefulWidget {
  final TacticsState state;
  final PlayerIcon player;

  /// When set, the close × and delete actions invoke this in addition to
  /// their usual behaviour.
  final VoidCallback? onClose;
  const _PlayerEditBar({
    required this.state,
    required this.player,
    this.onClose,
  });

  @override
  State<_PlayerEditBar> createState() => _PlayerEditBarState();
}

class _PlayerEditBarState extends State<_PlayerEditBar> {
  /// Colour palette + size slider stay collapsed by default — they are
  /// low-frequency next to move / run / delete, so they don't crowd the
  /// bar until the user taps the tune button to ask for them.
  bool _expanded = false;

  static const _colors = kElementColors;

  Widget _scaleSlider(PlayerIcon p) => Slider(
    value: p.scale,
    min: 0.5,
    max: 3.0,
    divisions: 10,
    activeColor: kAccent,
    inactiveColor: T.border,
    onChanged: (v) => widget.state.updatePlayer(p.id, scale: v),
  );

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    // A second tap on a text element on the board asks for its words. The
    // dialog lives here, so the request is picked up and cleared here —
    // after the frame, because opening a route while this one is building
    // is how you get "setState called during build".
    if (widget.state.labelEditRequest == p.id) {
      widget.state.clearLabelEditRequest();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _promptLabel();
      });
    }
    // A custom graphic is its own picture: the colour swatches do nothing to
    // it, so size is the only thing the tune panel can change. Show that row
    // straight away rather than making a coach find a ⚙ to reach the one
    // control that applies — and give the slider the whole width once the
    // swatches are gone.
    final isPhoto = p.photoId != null;
    // Anything drawn from a picture — a photo, the ball, equipment that
    // ships as artwork — has no colour to change: the swatches did nothing
    // to a cone and a coach tried them. Such an element gets the size row
    // straight away and no swatches, the way a photo already did.
    final isPicture =
        isPhoto ||
        p.isBall ||
        (p.isMarker &&
            !p.isPersonMarker &&
            markerImageAsset(p.markerShape, widget.state.sportType) != null);
    final expanded = _expanded || isPicture;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1 — core actions, always visible.
          Row(
            children: [
              // Identity + role. One flex child soaks up all the slack so the
              // action cluster stays pinned right while both chips keep their
              // natural width — a Spacer beside them would split the free
              // space and ellipsize the role chip on a row that fits fine.
              Expanded(
                child: Row(
                  children: [
                    // Tapping the chip renames the element: the label is the
                    // one field this bar has no other route to, and a full
                    // action button would push the row off-screen once the
                    // photo-crop action is also showing.
                    // The only flex child in the row: everything beside it
                    // keeps its natural width (an assigned role code must
                    // never be squeezed to blank), so a long name is what
                    // gives way when the row runs out of space.
                    Flexible(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _promptLabel,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _identityGlyph(p),
                            if (p.label.isNotEmpty && !p.labelInside) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  p.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: T.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_showRole(p)) ...[
                      const SizedBox(width: 6),
                      _roleChip(p),
                    ],
                  ],
                ),
              ),
              // Explicit add-run toggle — while on, taps on the board lay
              // this player's movement path (so a stray tap never can).
              // People and the ball run; equipment does not. A cone was
              // offered a run like a player, and a coach asked why.
              if (!(p.isMarker &&
                  p.markerShape != MarkerShape.referee &&
                  p.markerShape != MarkerShape.coach)) ...[
                const SizedBox(width: 6),
                _MoveToggle(
                  state: widget.state,
                  compact: p.label.isNotEmpty && !p.labelInside,
                ),
              ],
              if (!isPicture) ...[
                const SizedBox(width: 6),
                // Colour + size — collapsed by default; this reveals Row 2.
                _editAction(
                  Icons.tune,
                  _expanded ? T.accentText : T.textOff,
                  () => setState(() => _expanded = !_expanded),
                ),
              ],
              const SizedBox(width: 6),
              // Copy. The paste is in the + sheet, because that is where
              // things come onto the board from; a coach who copies here
              // and finds nothing to press next is told where to look.
              _editAction(Icons.copy_rounded, T.textDim, () {
                widget.state.copyPlayer(p.id);
                final m = ScaffoldMessenger.maybeOf(context);
                m?.hideCurrentSnackBar();
                m?.showSnackBar(
                  SnackBar(
                    content: Text('element_copied'.tr()),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }),
              const SizedBox(width: 6),
              // Delete
              _editAction(Icons.delete_outline_rounded, kDanger, () {
                widget.state.removePlayer(p.id);
                widget.onClose?.call();
              }),
              const SizedBox(width: 6),
              // Close (deselect).
              GestureDetector(
                onTap: () {
                  widget.state.selectPlayer(null);
                  widget.onClose?.call();
                },
                child: const Icon(
                  Icons.close_rounded,
                  color: T.textOff,
                  size: 20,
                ),
              ),
            ],
          ),
          // Row 2 — colour swatches + size slider, revealed on demand.
          if (expanded) ...[
            const SizedBox(height: 8),
            // Turn it. Two fingers on the element does the same thing, but on
            // a phone that is a fiddly gesture for what is usually one clear
            // intention — "face him up the pitch" — so it gets buttons too.
            Row(
              children: [
                const Icon(
                  Icons.rotate_90_degrees_ccw,
                  color: T.textDisabled,
                  size: 14,
                ),
                const SizedBox(width: 8),
                _editAction(
                  Icons.rotate_left,
                  T.textDim,
                  () => _turn(p, -_notch(p)),
                ),
                const SizedBox(width: 6),
                _editAction(
                  Icons.rotate_right,
                  T.textDim,
                  () => _turn(p, _notch(p)),
                ),
                const SizedBox(width: 10),
                Text(
                  _degrees(_shown(p)),
                  style: const TextStyle(
                    color: T.textOff,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                // Reset undoes a turn the coach made: for a person that is
                // the hand-set facing, and the board decides again after.
                if (_picture(p) ? p.rotation != 0 : p.facingLocked)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _turn(p, -_shown(p)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        'rotate_reset'.tr(),
                        style: TextStyle(
                          color: T.accentText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                // Who is standing there. The Add sheet can put a woman on the
                // board but nothing could turn one of the eleven a formation
                // dropped into one, which left half a squad unreachable.
                if (_showGender(p)) ...[
                  const SizedBox(width: 10),
                  _genderAction(p, PlayerGender.male, Icons.man),
                  const SizedBox(width: 6),
                  _genderAction(p, PlayerGender.female, Icons.woman),
                ],
                // Racket in hand or not. Every court has someone feeding,
                // and a diamond has one bat and eight gloves.
                if (_showGender(p) &&
                    widget.state.sportType.playerImplement != null) ...[
                  const SizedBox(width: 6),
                  _holdsAction(p),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!isPicture)
                  ..._colors.map(
                    (c) => GestureDetector(
                      onTap: () {
                        widget.state.updatePlayer(p.id, customColor: c);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                            color: p.customColor == c
                                ? T.selectedStroke
                                : T.border,
                            width: p.customColor == c ? 2.5 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!isPicture) const Spacer(),
                const Icon(
                  Icons.photo_size_select_small,
                  color: T.textDisabled,
                  size: 14,
                ),
                // Beside six swatches the slider gets a fixed 100pt, which is
                // coarse for a 0.5x–3x range but all the row can spare. With
                // the swatches gone it takes the whole row — the same widget
                // either way, so a photo and a player scale identically.
                if (isPicture)
                  Expanded(child: _scaleSlider(p))
                else
                  SizedBox(width: 100, child: _scaleSlider(p)),
              ],
            ),
            // A picture the coach brought in is cut to a shape — chosen when
            // it was imported, and until now never again. The same four the
            // import offers, each drawn as itself.
            if (isPhoto && p.isMarker) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.category_outlined,
                    color: T.textDisabled,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  for (final shape in kPhotoMarkerShapes)
                    GestureDetector(
                      onTap: () => widget.state.updatePlayer(
                        p.id,
                        markerShape: shape,
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: 36,
                        height: 32,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: T.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: p.markerShape == shape
                                ? T.selectedStroke
                                : T.border,
                            width: p.markerShape == shape ? 2 : 1,
                          ),
                        ),
                        child: ClipPath(
                          clipper: MarkerShapeClipper(shape),
                          child: ColoredBox(
                            color: p.markerShape == shape
                                ? kAccent
                                : T.textDim,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            // A text element is its text, so it also has a face. Four,
            // shown as themselves; the empty name is the app's own.
            if (isTextElement(p)) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.text_fields,
                    color: T.textDisabled,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  for (final f in kTextFonts)
                    TextFontChip(
                      font: f,
                      selected: (p.font ?? '') == f,
                      onTap: () => widget.state.updatePlayer(
                        p.id,
                        font: f.isEmpty ? null : f,
                        clearFont: f.isEmpty,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// A person has eight pictures to face with, so a notch is an eighth of
  /// a turn and every tap shows. A marker turns freely in 15° steps.
  /// Drawn from a picture that turns freely, as opposed to a figure drawn
  /// from eight headings — which is what a referee or a coach is too.
  bool _picture(PlayerIcon p) => p.isBall || (p.isMarker && !p.isPersonMarker);

  double _notch(PlayerIcon p) => _picture(p) ? math.pi / 12 : math.pi / 4;

  /// The turn the board is showing, as the bar reads it back.
  ///
  /// For equipment that is its rotation. A person faces what the board says
  /// they are doing this beat unless a coach has turned them by hand, so the
  /// number here — and the place a notch of the buttons starts from — is
  /// the heading actually drawn, relative to the team's default. The bar
  /// used to show the stored rotation, which for a drill's players is a
  /// baked opening stance the pitch was no longer showing: it said 45° over
  /// a man facing straight up, and one tap "left" turned him to 0°.
  double _shown(PlayerIcon p) {
    if (_picture(p) || p.facingLocked) return p.rotation;
    final st = widget.state;
    final beat = st.atStep > 0 ? st.atStep : st.targetStep;
    final h = faceAcrossNet(
      boardHeading(st.players, p, beat) ?? playerFacing(p),
      p,
      st.sportType,
      standingAt(p, beat),
      st.canvasSize,
      ball: ballStandingAt(st.players, beat),
    );
    return TacticsState.snapFacing(
      h - (p.team == PlayerTeam.home ? 0.0 : math.pi),
    );
  }

  /// One notch of the rotate buttons, snapped by the state.
  void _turn(PlayerIcon p, double delta) {
    widget.state.rotatePlayer(p.id, _shown(p) + delta);
    widget.state.rotatePlayerEnd(p.id);
  }

  /// "0°", "90°", "-45°" — read back so a coach can match two elements.
  String _degrees(double radians) {
    final deg = (radians * 180 / math.pi).round() % 360;
    return '${deg > 180 ? deg - 360 : deg}\u00B0';
  }

  /// Title key follows the element kind — markers and balls aren't
  /// "players", so the blanket 编辑球员 wording would read incorrectly.
  String _titleKey() {
    final p = widget.player;
    if (p.isBall) return 'edit_ball';
    if (p.isMarker) return 'edit_marker';
    return 'edit_player';
  }

  Future<void> _promptLabel() async {
    final p = widget.player;
    // No TextEditingController: the dialog's field outlives the await by one
    // route transition, so disposing the controller here trips a framework
    // assertion — an initialValue + onChanged has no such lifecycle.
    var text = p.label;
    var team = p.team;
    var photoId = p.photoId;
    var role = p.role;
    // The value is wrapped in a 1-element list so "applied an empty name"
    // (`['']`) stays distinguishable from "cancelled" (`null`).
    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            _titleKey().tr(),
            style: const TextStyle(color: T.text),
          ),
          // Scrollable, because the dialog's own height is whatever is left of
          // a phone turned sideways — 402pt, less the title, the actions and
          // the keyboard. A text element's field carries a character counter
          // that a player's does not, and that one extra line was two pixels
          // more than the box had.
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar and name are one edit: tapping the preview opens the
                // crop editor on top of this dialog (the field keeps its text),
                // and the preview refreshes itself when the crop is saved.
                GestureDetector(
                  onTap: (p.isBall || p.isMarker)
                      ? null
                      : () async {
                          final picked = await _pickAvatar(photoId);
                          if (picked == null) return; // dismissed
                          setDialogState(
                            () => photoId = picked.isEmpty ? null : picked,
                          );
                        },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _identityGlyph(
                        p.copyWith(
                          team: team,
                          photoId: photoId,
                          clearPhotoId: photoId == null,
                        ),
                        dim: 64,
                      ),
                      if (!p.isBall && !p.isMarker) ...[
                        const SizedBox(height: 6),
                        Text(
                          'avatar_pick_title'.tr(),
                          style: TextStyle(
                            color: T.accentText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Which side the player belongs to. Only real players have one —
                // balls and markers are neutral.
                if (!p.isBall && !p.isMarker) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (final t in [PlayerTeam.home, PlayerTeam.away]) ...[
                        if (t == PlayerTeam.away) const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => team = t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: PlayerIcon.teamColor(
                                  t,
                                ).withValues(alpha: team == t ? 0.30 : 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: team == t
                                      ? PlayerIcon.teamColor(t)
                                      : T.border,
                                  width: team == t ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: PlayerIcon.teamColor(t),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    (t == PlayerTeam.home
                                            ? 'team_home'
                                            : 'team_away')
                                        .tr(),
                                    style: TextStyle(
                                      color: team == t
                                          ? T.text
                                          : T.textOff,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                // Position: same sheet the bar chip opens, but the pick is held
                // until Apply like every other field here.
                if (_showRole(p)) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'role_title'.tr(),
                        style: const TextStyle(
                          color: T.textOff,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          final picked = await _chooseRole(role);
                          if (picked == null) return;
                          setDialogState(
                            () => role = picked.isEmpty ? null : picked,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: role != null
                                ? kAccent.withValues(alpha: 0.22)
                                : T.surfaceHi,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: role != null ? T.selectedStroke : T.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            role ?? 'role_set'.tr(),
                            style: TextStyle(
                              color: role != null ? T.accentText : T.textDim,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: p.label,
                  autofocus: true,
                  // A name has to fit the badge under the board icon and the chip
                  // in the edit bar; past this it is only ever seen truncated.
                  // A text element is the sentence, not a name under a token.
                  maxLength: isTextElement(p) ? kTextElementMaxChars : 12,
                  // A sentence gets the room of one: two lines to start,
                  // four as it grows. Two was a slot to type a name in.
                  minLines: isTextElement(p) ? 2 : null,
                  maxLines: isTextElement(p) ? 4 : 1,
                  style: const TextStyle(color: T.text),
                  decoration: InputDecoration(
                    counterStyle: const TextStyle(
                      color: T.textOff,
                      fontSize: 11,
                    ),
                    labelText: 'player_name'.tr(),
                    labelStyle: const TextStyle(color: T.textOff),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: T.borderStrong),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: kAccent),
                    ),
                  ),
                  onChanged: (v) => text = v,
                  onFieldSubmitted: (v) => Navigator.of(ctx).pop([v]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'cancel'.tr(),
                style: const TextStyle(color: T.textOff),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop([text]),
              child: Text(
                'confirm'.tr(),
                style: TextStyle(color: T.accentText),
              ),
            ),
          ],
        ),
      ),
    );
    if (result == null) return; // cancelled
    // A team switch drops any hand-picked colour — otherwise the player would
    // keep the old side's colour and the change wouldn't show anywhere.
    widget.state.updatePlayer(
      p.id,
      label: result.first.trim(),
      team: team == p.team ? null : team,
      clearCustomColor: team != p.team,
      photoId: photoId,
      clearPhotoId: photoId == null,
    );
    if (role != p.role) widget.state.setPlayerRole(p.id, role);
  }

  /// Avatar chooser: pick one of the saved faces, upload a new one, re-crop
  /// the current one, or drop it. Returns the chosen photo id, `''` to mean
  /// "no avatar", or null when the sheet was dismissed without a choice.
  Future<String?> _pickAvatar(String? current) async {
    return TacticalSheet.show(
      context,
      builder: (ctx) => TacticalSheet(
        padding: const EdgeInsets.fromLTRB(0, T.s12, 0, 0),
        child: _AvatarPickerSheet(currentPhotoId: current),
      ),
    );
  }

  /// Miniature of the selected element, drawn with the very same painters the
  /// board uses, so the chip reads as "this thing" rather than a generic dot.
  Widget _identityGlyph(PlayerIcon p, {double dim = 26}) {
    Widget glyph;
    if (p.photoId != null) {
      glyph = p.isMarker
          ? ShapedPhotoMarker(player: p, isSelected: false)
          : PhotoPlayerShape(player: p, isSelected: false);
    } else if (p.isBall) {
      glyph = ballWidget(p.sportType ?? widget.state.sportType);
    } else if (p.isMarker && !p.isPersonMarker) {
      // The same picture the board draws: equipment that ships as artwork
      // is shown as that artwork, not as the painter's stand-in shape. The
      // bar showed a coach a plain triangle for the cone he had selected on
      // the grass, and he asked which one it was.
      final art = markerImageAsset(p.markerShape, widget.state.sportType);
      final drawn = CustomPaint(
        painter: MarkerPainter(shape: p.markerShape, color: p.color),
        size: Size(dim, dim),
      );
      glyph = art == null
          ? drawn
          : Image.asset(
              art,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => drawn,
            );
    } else {
      glyph = Stack(
        children: [
          CustomPaint(
            painter: TopDownPlayerPainter(
              color: p.color,
              borderColor: Colors.white,
              borderWidth: 1.5,
              gender: p.gender,
              figure: TopDownPlayerPainter.figureFor(widget.state.sportType, p),
              sport: widget.state.sportType,
              heading: playerFacing(p),
            ),
            size: Size(dim, dim),
          ),
          if (p.labelInside)
            Align(
              alignment: playerLabelAlign(widget.state.sportType, p),
              child: Text(
                p.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: dim * 0.35,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
        ],
      );
    }
    return SizedBox(width: dim, height: dim, child: glyph);
  }

  /// Gender is a person's, so it is offered on people: not on a ball, not on
  /// a cone, and not on an element wearing a photo, whose picture is already
  /// whoever it is.
  bool _showGender(PlayerIcon p) =>
      !p.isBall && !p.isMarker && p.photoId == null;

  /// Whether this one player has the sport's implement in hand. Tapping
  /// flips it away from whatever the sport does by default; there is no way
  /// back to "unset" from here, and no need for one — the two states are
  /// what a coach is choosing between.
  Widget _holdsAction(PlayerIcon p) {
    final sport = widget.state.sportType;
    final on = p.holdsImplement ?? sport.implementHeldByDefault;
    return _editAction(
      Icons.sports_tennis,
      on ? T.accentText : T.textOff,
      () => widget.state.updatePlayer(p.id, holdsImplement: !on),
    );
  }

  /// Tapping the one already set puts the element back to unspecified, which
  /// is what a formation lays down and what draws the default figure.
  Widget _genderAction(PlayerIcon p, PlayerGender g, IconData icon) {
    final on = p.gender == g;
    return _editAction(icon, on ? T.accentText : T.textOff, () {
      widget.state.updatePlayer(
        p.id,
        gender: on ? PlayerGender.unspecified : g,
      );
    });
  }

  Widget _editAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // Position/role is only meaningful for real outfield players of a sport that
  // defines roles (soccer, basketball) — not balls or neutral markers.
  bool _showRole(PlayerIcon p) =>
      !p.isBall &&
      !p.isMarker &&
      p.team != PlayerTeam.neutral &&
      PlayerRoles.supports(widget.state.sportType);

  Widget _roleChip(PlayerIcon p) {
    final assigned = p.role != null && p.role!.isNotEmpty;
    // A named element leaves no room for the "Position" placeholder beside
    // it, so the unset state falls back to its icon. An assigned role is only
    // 2-3 characters ('GK', 'CM'), so that always stays as text.
    final iconOnly = !assigned && p.label.isNotEmpty && !p.labelInside;
    return GestureDetector(
      onTap: _pickRole,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: iconOnly ? 6 : 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: assigned
              ? kAccent.withValues(alpha: 0.22)
              : T.surfaceHi,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: assigned ? T.selectedStroke : T.border,
            width: 1,
          ),
        ),
        child: iconOnly
            ? const Icon(Icons.place_outlined, color: T.textDim, size: 14)
            : Text(
                assigned ? p.role! : 'role_set'.tr(),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  color: assigned ? T.accentText : T.textDim,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Future<void> _pickRole() async {
    final picked = await _chooseRole(widget.player.role);
    if (picked == null) return; // dismissed
    widget.state.setPlayerRole(
      widget.player.id,
      picked.isEmpty ? null : picked,
    );
  }

  /// Role sheet shared by the bar chip and the edit dialog. Returns the picked
  /// role, `''` for "no role", or null when dismissed without choosing.
  Future<String?> _chooseRole(String? current) async {
    final state = widget.state;
    final roles = PlayerRoles.forSport(state.sportType);
    if (roles.isEmpty) return null;
    return TacticalSheet.show(
      context,
      builder: (ctx) => TacticalSheet(
        padding: const EdgeInsets.fromLTRB(0, T.s12, 0, 0),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'role_title'.tr(),
                  style: const TextStyle(
                    color: T.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _roleOption(ctx, 'role_none'.tr(), current == null, ''),
                    for (final r in roles) _roleOption(ctx, r, current == r, r),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleOption(
    BuildContext ctx,
    String label,
    bool selected,
    String value,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(ctx).pop(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? T.accentFill : T.surfaceHi,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? T.selectedStroke : T.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? T.accentText : T.textDim,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collapsible edit panel — drawing options / player edit with collapse toggle
// ─────────────────────────────────────────────────────────────────────────────
/// Where every text element is on the screen, as drawn — turned chips by
/// the box they actually cover.
///
/// Read off the board's own render tree rather than estimated from the
/// element, because a chip's width is its words: the drill note is a
/// different length at every beat. The board also lays chips out far off
/// screen to measure them; only the ones on the board count.
List<Rect> textChipsOnScreen() {
  final root = boardRepaintKey.currentContext;
  final board = root?.findRenderObject();
  if (root == null || board is! RenderBox || !board.attached) return const [];
  final bounds = MatrixUtils.transformRect(
    board.getTransformTo(null),
    Offset.zero & board.size,
  );
  final out = <Rect>[];
  void visit(Element e) {
    if (e.widget is TextElementChip) {
      final box = e.renderObject;
      if (box is RenderBox && box.attached && box.hasSize) {
        final r = MatrixUtils.transformRect(
          box.getTransformTo(null),
          Offset.zero & box.size,
        );
        if (r.overlaps(bounds)) out.add(r);
      }
      return;
    }
    e.visitChildElements(visit);
  }

  (root as Element).visitChildElements(visit);
  return out;
}

/// A cluster of floating corner buttons that steps up over the words on the
/// board instead of sitting on them.
///
/// Fullscreen puts the beat controls and the way back in the bottom
/// corners, in the band under the court — which is exactly where a drill's
/// step note is placed, so the circles covered the sentence they were
/// stepping through. Measured after each frame: if the cluster at rest
/// covers a text chip, it is lifted to just above it (and above the next
/// one, if that lands it on another).
class _ClearOfText extends StatefulWidget {
  final double bottom;
  final double? left;
  final double? right;
  final Widget child;
  const _ClearOfText({
    required this.bottom,
    this.left,
    this.right,
    required this.child,
  });

  @override
  State<_ClearOfText> createState() => _ClearOfTextState();
}

class _ClearOfTextState extends State<_ClearOfText> {
  final GlobalKey _key = GlobalKey();
  double _lift = 0;

  void _measure() {
    if (!mounted) return;
    final box = _key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final atRest = (box.localToGlobal(Offset.zero) & box.size).shift(
      Offset(0, _lift),
    );
    final chips = textChipsOnScreen();
    var lift = 0.0;
    // A few rounds: a lift that clears one chip can land on another.
    for (var i = 0; i < 4; i++) {
      final r = atRest.shift(Offset(0, -lift));
      final hit = chips.where((c) {
        final o = r.intersect(c);
        return o.width > 0 && o.height > 0;
      });
      if (hit.isEmpty) break;
      final top = hit.map((c) => c.top).reduce(math.min);
      lift = atRest.bottom - (top - 4);
    }
    // Never more than half the screen: past that it is better on the words
    // than in the middle of the court.
    lift = lift.clamp(0.0, MediaQuery.sizeOf(context).height / 2);
    if ((lift - _lift).abs() > 0.5) setState(() => _lift = lift);
  }

  @override
  Widget build(BuildContext context) {
    // Only what moves a chip, so playing a drill does not walk the tree
    // every frame: the words (the note changes at each beat), where it is,
    // how big, which way round, and the face it is set in.
    context.select<TacticsState, String>(
      (s) => [
        for (final p in s.players)
          if (isTextElement(p))
            '${p.id}|${p.label}|${p.position}|${p.scale}|${p.rotation}|${p.font}',
      ].join('\n'),
    );
    MediaQuery.sizeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    return Positioned(
      bottom: widget.bottom + _lift,
      left: widget.left,
      right: widget.right,
      child: KeyedSubtree(key: _key, child: widget.child),
    );
  }
}

class _CollapsibleEditPanel extends StatefulWidget {
  @override
  State<_CollapsibleEditPanel> createState() => _CollapsibleEditPanelState();
}

class _CollapsibleEditPanelState extends State<_CollapsibleEditPanel> {
  /// How far the coach has pushed the bar from where it opens.
  ///
  /// It opens across the foot of the board, which is also where a text
  /// element's words sit and where the last row of a formation stands — so
  /// the bar covers the very thing it was opened to edit. Dragging it is
  /// the answer: anywhere on the bar, including over its buttons, because
  /// a drag is not a tap and the buttons only answer taps.
  Offset _drag = Offset.zero;

  /// What the bar was last placed for. Each new selection places it again:
  /// at the foot of the board, unless that covers the very thing just
  /// selected — a line drawn along the baseline, a text chip under the
  /// court — in which case at the head. A drag after that is kept until
  /// the selection changes.
  String? _placedFor;
  final GlobalKey _panelKey = GlobalKey();

  /// The bar's offset for a selection whose box on the screen is [target],
  /// given where the bar rests undragged.
  ///
  /// Not just the foot or the head: anywhere between the two, so the bar
  /// can sit in the gap between the thing being edited and the words
  /// written on the board. The selection comes first — a bar over the very
  /// element it edits is no use — and after it every text element on the
  /// board, [texts], which is what a coach is reading while editing. Of
  /// the places that cover equally little, the one nearest the foot.
  static Offset _slotFor(
    Rect atRest,
    Rect? target,
    List<Rect> texts,
    double boardTop, {
    List<Rect> figures = const [],
    Rect? ownHalf,
    double minDx = 0,
    double maxDx = 0,
  }) {
    // 64: under the back / pages / menu circles across the top.
    final up = (boardTop + 64) - atRest.top;
    if (up >= 0 && minDx == maxDx) return Offset.zero;
    final top = math.min(up, 0.0);
    double covered(Rect r, Rect o) {
      final x = r.intersect(o);
      return x.isEmpty ? 0 : x.width * x.height;
    }

    // The selection (and the run it is drawing) above all; then the words
    // on the board and the other players; and, on a net court, the side
    // of the net the selected player is on — nobody crosses the net, so
    // the other half is where the bar is in nobody's way.
    double cost(Offset d) {
      final r = atRest.shift(d);
      var c = target == null ? 0.0 : covered(r, target) * 1000;
      for (final t in texts) {
        c += covered(r, t);
      }
      for (final f in figures) {
        c += covered(r, f);
      }
      if (ownHalf != null) c += covered(r, ownHalf) * 0.3;
      return c;
    }

    // The foot, the head, and every place where the bar's edge just clears
    // an edge of something it should not cover — down the screen, and
    // across it where the bar is narrower than the screen (sideways).
    final ys = <double>{0, top};
    final xs = <double>{0, minDx, maxDx};
    for (final o in [?target, ...texts, ...figures, ?ownHalf]) {
      ys.add((o.top - 4) - atRest.bottom);
      ys.add((o.bottom + 4) - atRest.top);
      xs.add((o.left - 4) - atRest.right);
      xs.add((o.right + 4) - atRest.left);
    }
    var best = Offset.zero;
    var bestCost = cost(best);
    if (bestCost == 0) return Offset.zero;
    for (final rx in xs) {
      final dx = rx.clamp(minDx, maxDx).toDouble();
      for (final ry in ys) {
        final d = Offset(dx, ry.clamp(top, 0.0).toDouble());
        final c = cost(d);
        // Of equal places, the one nearest the foot, then the centre.
        if (c < bestCost - 0.5 ||
            (c <= bestCost + 0.5 &&
                (d.dy > best.dy + 0.5 ||
                    (d.dy >= best.dy - 0.5 && d.dx.abs() < best.dx.abs())))) {
          best = d;
          bestCost = c;
        }
      }
    }
    return best;
  }

  /// A canvas rect on the screen: the bounds of its corners carried through
  /// the canvas's own transform, which sideways is a quarter turn.
  static Rect _onScreen(RenderBox canvas, Rect r) {
    final pts = [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]
        .map(canvas.localToGlobal)
        .toList();
    var out = Rect.fromPoints(pts.first, pts.first);
    for (final p in pts) {
      out = out.expandToInclude(Rect.fromPoints(p, p));
    }
    return out;
  }

  /// Where the selected thing is on the screen, generously: a stroke's
  /// bounds, or a box around the figure, chip or token.
  Rect? _targetRect(TacticsState state, RenderBox canvas) {
    final stroke = state.selectedStroke;
    if (stroke != null) {
      if (stroke.points.isEmpty) return null;
      var r = Rect.fromPoints(stroke.points.first, stroke.points.first);
      for (final pt in stroke.points) {
        r = r.expandToInclude(Rect.fromPoints(pt, pt));
      }
      return _onScreen(canvas, r.inflate(stroke.width / 2 + 8));
    }
    final id = state.selectedPlayerId;
    if (id == null) return null;
    final p = state.players.cast<PlayerIcon?>().firstWhere(
      (x) => x?.id == id,
      orElse: () => null,
    );
    if (p == null) return null;
    final box = _elementRect(state, canvas, p);
    if (p.moves.isEmpty) return box;
    // The run being drawn is part of what is being edited: a bar over the
    // route hid the very line the coach was adding a point to.
    var route = Rect.fromPoints(p.position, p.position);
    for (final pt in p.moves) {
      route = route.expandToInclude(Rect.fromPoints(pt, pt));
    }
    return box.expandToInclude(_onScreen(canvas, route.inflate(24)));
  }

  /// On a court with a net, the selected player's side of it on the
  /// screen — the half the bar should stay off. Null elsewhere, or on a
  /// layout that shows only one side.
  Rect? _ownHalf(TacticsState state, RenderBox canvas) {
    final sport = state.sportType;
    if (!sport.hasNet) return null;
    final layout = state.courtLayout(sport);
    if (layout == CourtLayout.half || layout == CourtLayout.blank) {
      return null;
    }
    final id = state.selectedPlayerId;
    if (id == null) return null;
    final p = state.players.cast<PlayerIcon?>().firstWhere(
      (x) => x?.id == id,
      orElse: () => null,
    );
    if (p == null || isTextElement(p)) return null;
    final size = canvas.size;
    final net = sport.fieldRect(size).center.dy;
    final half = p.position.dy < net
        ? Rect.fromLTRB(0, 0, size.width, net)
        : Rect.fromLTRB(0, net, size.width, size.height);
    return _onScreen(canvas, half);
  }

  /// A box round one element on the screen.
  Rect _elementRect(TacticsState state, RenderBox canvas, PlayerIcon p) {
    final at = state.animatedPositions[p.id] ?? p.position;
    double w, h;
    if (isTextElement(p)) {
      final note = p.id == TacticsState.kDrillNoteId;
      w = textElementMaxWidth(context, p.label, note: note) * p.scale;
      h = 30 * p.scale * textElementMaxLines(p.label, note: note);
      // A chip laid on its side is tall, not wide. Its rotation is read
      // against the screen (text counter-turns with the board, see
      // turnedForText), so on the board's own frame — a quarter turn away
      // in landscape — an upright chip is the one lying down.
      final turned =
          MediaQuery.orientationOf(context) == Orientation.landscape ? 1 : 0;
      final quarter = (p.rotation / (math.pi / 2)).round() + turned;
      if (quarter.isOdd) {
        final t = w;
        w = h;
        h = t;
      }
    } else {
      // A figure stands taller than its icon box: head above the point,
      // feet and shadow below.
      w = kPlayerIconSize * 1.4 * p.scale;
      h = kPlayerIconSize * 2.4 * p.scale;
    }
    return _onScreen(
      canvas,
      Rect.fromCenter(center: at, width: w, height: h),
    );
  }

  /// Every text element on the board other than the one being edited.
  List<Rect> _textRects(TacticsState state, RenderBox canvas) => [
    for (final p in state.players)
      if (isTextElement(p) && p.id != state.selectedPlayerId)
        _elementRect(state, canvas, p),
  ];

  /// Measure after the frame — the bar has to have a size and a place
  /// before it can be asked whether it is in the way.
  void _place(TacticsState state, String key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _placedFor == key) return;
      final sameSelection = _placedFor != null &&
          _placedFor!.split('#').first == key.split('#').first;
      final panel = _panelKey.currentContext?.findRenderObject();
      final canvas = boardRepaintKey.currentContext?.findRenderObject();
      if (panel is! RenderBox ||
          !panel.attached ||
          canvas is! RenderBox ||
          !canvas.attached) {
        return;
      }
      _placedFor = key;
      // Through the panel's whole transform: on a tablet it is drawn
      // scaled (_ScaledBox), and its own size is the unscaled one.
      final atRest = MatrixUtils.transformRect(
        panel.getTransformTo(null),
        Offset.zero & panel.size,
      ).shift(-_drag);
      final board = _onScreen(canvas, Offset.zero & canvas.size);
      // Drawing with nothing selected, the bar has no one element to keep
      // clear of — so it keeps clear of all of them. Resting at the foot
      // it hid a table-tennis server and his ball, the very player a coach
      // draws a line from (audit 2026-10-11 M3); now it settles wherever it
      // covers the fewest figures, which on most boards is open court.
      final drawing =
          state.isDrawingMode && state.selectedStrokeId == null;
      final target = _targetRect(state, canvas);
      // The same player, a point added to his run: if the bar where it is
      // still keeps clear of him and the run, leave it — the coach may
      // have put it there.
      if (sameSelection &&
          target != null &&
          !atRest.shift(_drag).overlaps(target)) {
        return;
      }
      // A tablet docks the bar beside what it edits — a player at the
      // left touchline had his bar 500pt away at the bottom centre. Just
      // under it, or over it when there is no room under; across, centred
      // on it and kept on the screen.
      if (target != null &&
          MediaQuery.sizeOf(context).shortestSide >= 600) {
        final screenW = MediaQuery.sizeOf(context).width;
        final up = (board.top + 64) - atRest.top;
        final below = (target.bottom + 12) - atRest.top;
        final above = (target.top - 12) - atRest.bottom;
        final dy = (below <= 0 ? below : above).clamp(math.min(up, 0.0), 0.0);
        final dx = (target.center.dx - atRest.center.dx).clamp(
          8 - atRest.left,
          math.max(8 - atRest.left, screenW - 8 - atRest.right),
        );
        final near = Offset(dx.toDouble(), dy.toDouble());
        if (near != _drag) setState(() => _drag = near);
        return;
      }
      final screenW = MediaQuery.sizeOf(context).width;
      final slot = _slotFor(
        atRest,
        target,
        _textRects(state, canvas),
        board.top,
        // The other players: drawing, the bar keeps clear of all of them
        // (audit 2026-10-11 M3); editing one, of the rest of them too — a
        // bar across the foot sat on the back row.
        figures: [
          for (final p in state.players)
            if (!isTextElement(p) &&
                p.id != state.selectedPlayerId &&
                !p.isBall)
              _elementRect(state, canvas, p),
        ],
        ownHalf: drawing ? null : _ownHalf(state, canvas),
        // Sideways the bar is narrower than the screen and can move
        // across it too, onto the far half of the court.
        minDx: math.min(0.0, board.left + 4 - atRest.left),
        maxDx: math.max(0.0, math.min(board.right, screenW - 8) - 4 - atRest.right),
      );
      if (slot != _drag) setState(() => _drag = slot);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TacticsState>(
      builder: (context, state, _) {
        if (state.isAnimating || state.presentationMode) {
          _placedFor = null;
          return const SizedBox.shrink();
        }

        final hasDrawing =
            state.isDrawingMode || state.selectedStrokeId != null;
        final hasPlayer = state.selectedPlayerId != null;
        if (!hasDrawing && !hasPlayer) {
          _placedFor = null;
          return const SizedBox.shrink();
        }
        final selected = state.selectedPlayerId == null
            ? null
            : state.players.cast<PlayerIcon?>().firstWhere(
                (p) => p?.id == state.selectedPlayerId,
                orElse: () => null,
              );
        // A point added to the selected player's run places the bar again:
        // the run may have grown under it.
        final placeKey = state.selectedStrokeId ??
            (selected != null
                ? '${selected.id}#${selected.moves.length}'
                : state.selectedPlayerId) ??
            'draw';
        if (_placedFor != placeKey) _place(state, placeKey);

        // The edit surface is shown inline, anchored just above the toolbar —
        // no extra ⚙ tap, no modal dialog. One unified, always-visible bar.
        Widget child;
        if (hasDrawing) {
          child = DrawingOptionsBar(state: state, showOptions: true);
        } else {
          final player = state.players.cast<PlayerIcon?>().firstWhere(
            (p) => p?.id == state.selectedPlayerId,
            orElse: () => null,
          );
          if (player == null) return const SizedBox.shrink();
          child = _PlayerEditBar(
            state: state,
            player: player,
            onClose: () => state.selectPlayer(null),
          );
        }
        final screen = MediaQuery.sizeOf(context);
        // The drag moves the Positioned itself, not a Transform inside it.
        //
        // Transform.translate paints the bar somewhere else and leaves its
        // box behind: Transform skips its own bounds check, but the Center
        // and the Positioned above it do not, so every tap on the moved bar
        // was rejected before it got that far and fell through to the board
        // underneath — which deselected the very element being edited.
        // A tablet draws the bar larger, whole: its 30pt buttons and 24pt
        // swatches were a phone's, under a coach's finger on a 13-inch
        // screen. Scaled as one piece (layout and hit-testing too) so
        // nothing inside has to know; capped by the screen's width.
        final tabletScale = screen.shortestSide >= 600
            ? math.min(1.45, (screen.width - 16) / 540).clamp(1.0, 1.45)
            : 1.0;
        // The pen's panel steps aside while a line is being drawn: it
        // stands across the foot of the board — a third of it on a phone
        // turned sideways — and a stroke that ran under it stopped there
        // (reported 2026-10-17). Gone from the moment the finger is down
        // to the moment it lifts, and back for the next choice.
        final inking = hasDrawing && state.currentStroke != null;
        return Positioned(
          left: 8 + _drag.dx,
          right: 8 - _drag.dx,
          bottom: 10 - _drag.dy,
          child: IgnorePointer(
            ignoring: inking,
            child: AnimatedOpacity(
              opacity: inking ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 120),
          child: Center(
            child: _ScaledBox(
              scale: tabletScale.toDouble(),
              child: ConstrainedBox(
              // The pen's panel is two short rows — a style picker, six
              // colours and a thickness — and at 540 the slider ran half
              // the screen and the panel covered most of a sideways board
              // (2026-10-17). A player's bar keeps 540 for its actions.
              constraints: BoxConstraints(maxWidth: hasDrawing ? 400 : 540),
              child: GestureDetector(
                // Translucent, so the chip and the actions inside still
                // get their taps; this only claims the drag.
                //
                // And ONLY the drag: a double-tap recogniser up here —
                // it was a "put it back" shortcut — holds every child's
                // tap for the double-tap timeout and can take it outright,
                // which left the tune button on the bar doing nothing.
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (d) => setState(() {
                  // Kept on the screen: half of it off an edge and the
                  // only way back is to close it and open it again.
                  _drag = Offset(
                    (_drag.dx + d.delta.dx).clamp(
                      -screen.width / 2,
                      screen.width / 2,
                    ),
                    (_drag.dy + d.delta.dy).clamp(-screen.height + 80, 0.0),
                  );
                }),
                child: Material(
                  key: _panelKey,
                  color: kSurfaceHi,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  // A grab bar across the top. The bar has always dragged,
                  // from anywhere on it, but nothing said so — a coach who
                  // had just drawn a line under it had no reason to try.
                  // Laid over the bar's own top padding by a Stack, so it
                  // costs no height and the pan still belongs to the
                  // detector above.
                  child: Stack(
                    children: [
                      // Opening the tune rows makes the bar several times
                      // taller, and a place chosen for the short bar can
                      // put the tall one over the very words it dodged.
                      // So a change of size places it again.
                      NotificationListener<SizeChangedLayoutNotification>(
                        onNotification: (_) {
                          _placedFor = null;
                          _place(state, placeKey);
                          return true;
                        },
                        child: SizeChangedLayoutNotifier(child: child),
                      ),
                      Positioned(
                        top: 4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 32,
                            height: 3.5,
                            decoration: BoxDecoration(
                              color: T.borderStrong,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
          ),
            ),
          ),
        );
      },
    );
  }
}

/// Lays its child out [scale] times smaller and draws it [scale] times
/// larger, so the child — layout, paint and taps — is simply bigger.
class _ScaledBox extends SingleChildRenderObjectWidget {
  final double scale;
  const _ScaledBox({required this.scale, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderScaledBox(scale);

  @override
  void updateRenderObject(BuildContext context, _RenderScaledBox r) =>
      r.scale = scale;
}

class _RenderScaledBox extends RenderProxyBox {
  _RenderScaledBox(this._scale);
  double _scale;
  set scale(double v) {
    if (v == _scale) return;
    _scale = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c.layout(constraints / _scale, parentUsesSize: true);
    size = constraints.constrain(c.size * _scale);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c == null) return;
    if (_scale == 1.0) {
      context.paintChild(c, offset);
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      Matrix4.diagonal3Values(_scale, _scale, 1),
      (ctx, o) => ctx.paintChild(c, o),
      oldLayer: layer is TransformLayer ? layer as TransformLayer : null,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final c = child;
    if (c == null) return false;
    return result.addWithPaintTransform(
      transform: Matrix4.diagonal3Values(_scale, _scale, 1),
      position: position,
      hitTest: (r, p) => c.hitTest(r, position: p),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.scaleByDouble(_scale, _scale, 1, 1);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add-run toggle — explicit sub-mode entry shown in the player edit bar.
// While on, board taps lay this player's run; while off a tap only deselects.
// ─────────────────────────────────────────────────────────────────────────────
/// Grid of the saved face photos plus the actions that manage them. Pops the
/// chosen photo id, `''` for "no avatar", or nothing when dismissed.
class _AvatarPickerSheet extends StatefulWidget {
  final String? currentPhotoId;
  const _AvatarPickerSheet({required this.currentPhotoId});

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  late Future<List<(PlayerPhoto, String)>> _photos;

  @override
  void initState() {
    super.initState();
    _photos = _load();
  }

  Future<List<(PlayerPhoto, String)>> _load() async {
    final svc = PhotoLibraryService.instance;
    final list = await svc.list();
    return [for (final p in list) (p, await svc.resolvePath(p))];
  }

  Future<void> _upload() async {
    final groups = await PhotoLibraryService.instance.listGroups();
    if (!mounted || groups.isEmpty) return;
    await PhotoImportSheet.showWithSourcePicker(
      context,
      groupId: groups.first.id,
    );
    if (mounted) setState(() => _photos = _load());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'avatar_pick_title'.tr(),
                    style: const TextStyle(
                      color: T.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close_rounded, color: T.textOff),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: FutureBuilder<List<(PlayerPhoto, String)>>(
                future: _photos,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: kAccent,
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  }
                  final items = snap.data ?? const <(PlayerPhoto, String)>[];
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'photo_no_faces'.tr(),
                        style: const TextStyle(
                          color: T.textOff,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final entry in items)
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(entry.$1.id),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: FileImage(File(entry.$2)),
                                  fit: BoxFit.cover,
                                ),
                                border: Border.all(
                                  color: entry.$1.id == widget.currentPhotoId
                                      ? T.selectedStroke
                                      : T.border,
                                  width: entry.$1.id == widget.currentPhotoId
                                      ? 2.5
                                      : 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(color: T.border, height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.add_a_photo_outlined,
                color: T.text,
              ),
              title: Text(
                'avatar_upload_new'.tr(),
                style: const TextStyle(color: T.text, fontSize: 15),
              ),
              onTap: _upload,
            ),
            if (widget.currentPhotoId != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.crop, color: T.accentText),
                title: Text(
                  'photo_crop_title'.tr(),
                  style: TextStyle(color: T.accentText, fontSize: 15),
                ),
                onTap: () => PhotoCropEditor.show(
                  context,
                  photoId: widget.currentPhotoId!,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.person_outline,
                  color: T.textOff,
                ),
                title: Text(
                  'avatar_remove'.tr(),
                  style: const TextStyle(color: T.textOff, fontSize: 15),
                ),
                onTap: () => Navigator.of(context).pop(''),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoveToggle extends StatelessWidget {
  final TacticsState state;

  /// Icon-only pill. Used when the selected element carries a name, which
  /// needs the ~50pt the label would otherwise take.
  final bool compact;
  const _MoveToggle({required this.state, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final on = state.isAddingMove;
    return GestureDetector(
      onTap: () {
        state.setAddingMove(!on);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: on ? kAccent : kAccentFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kAccent, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              on ? Icons.check_rounded : Icons.directions_run,
              size: 14,
              color: on ? T.onAccent : T.accentText,
            ),
            if (!compact) ...[
              const SizedBox(width: 4),
              Text(
                on ? 'move_done'.tr() : 'move_add'.tr(),
                style: TextStyle(
                  color: on ? T.onAccent : T.accentText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom-right chrome — fullscreen toggle + reset-zoom (only while zoomed).
// ─────────────────────────────────────────────────────────────────────────────
class _ZoomModeButton extends StatelessWidget {
  /// Laid along the bottom of the board rather than up its end, which is
  /// where the gap to the next button has to go. Carried by the button and
  /// not by the row because this one can vanish — a gap left behind by a
  /// button that is not there is a hole.
  final bool across;
  const _ZoomModeButton({this.across = false});

  @override
  Widget build(BuildContext context) {
    return Selector<TacticsState, bool>(
      selector: (_, s) => s.zoomMode,
      builder: (context, on, _) => Padding(
        padding: across
            ? const EdgeInsets.only(right: 8)
            : const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: context.read<TacticsState>().toggleZoomMode,
          child: _GlassCircle(
            size: chromeCircle(context),
            border: on ? Border.all(color: T.selectedStroke, width: 1.5) : null,
            child: Icon(
              Icons.pinch,
              color: on ? T.accentText : T.text,
              size: 17 * uiScale(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullscreenButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<TacticsState, bool>(
      selector: (_, s) => s.toolbarVisible,
      builder: (context, visible, _) => GestureDetector(
        onTap: context.read<TacticsState>().toggleToolbar,
        child: _GlassCircle(
          size: chromeCircle(context),
          child: Icon(
            visible ? Icons.fullscreen : Icons.fullscreen_exit,
            color: T.text,
            size: 18 * uiScale(context),
          ),
        ),
      ),
    );
  }
}

/// Appears only while the board is zoomed/panned — one tap restores the
/// 1:1 fit (and clears the basketball half-court preset).
class _ZoomResetButton extends StatefulWidget {
  /// See [_ZoomModeButton.across].
  final bool across;
  const _ZoomResetButton({this.across = false});

  @override
  State<_ZoomResetButton> createState() => _ZoomResetButtonState();
}

class _ZoomResetButtonState extends State<_ZoomResetButton> {
  TransformationController? _ctrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = context.read<TacticsState>().transformationController;
    if (c != _ctrl) {
      _ctrl?.removeListener(_onChange);
      _ctrl = c;
      c.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    _ctrl?.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<TacticsState>();
    final zoomed = state.transformationController.value != Matrix4.identity();
    if (!zoomed) return const SizedBox.shrink();
    return Padding(
      padding: widget.across
          ? const EdgeInsets.only(right: 8)
          : const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: state.resetZoom,
        child: _GlassCircle(
          size: chromeCircle(context),
          child: Icon(
            Icons.zoom_out_map,
            color: T.text,
            size: 17 * uiScale(context),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Presentation overlay — a locked, clean board for showing players a play.
// All editing is disabled; only playback + an exit affordance remain.
// ─────────────────────────────────────────────────────────────────────────────
class _PresentationOverlay extends StatelessWidget {
  final double topPad;
  const _PresentationOverlay({required this.topPad});

  @override
  Widget build(BuildContext context) {
    final state = context.read<TacticsState>();
    return Stack(
      fit: StackFit.expand,
      children: [
        // Exit pill — top center.
        Positioned(
          top: topPad + 10,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: state.togglePresentationMode,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  // A quiet pill, not an accent-outlined button: nothing in
                  // presentation mode should compete with the board.
                  color: const Color(0xD1050F12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: T.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'present_exit'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Large playback controls — bottom center, only when there are moves.
        if (state.hasMoves)
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(child: _BigPlayControls(state: state)),
          ),
      ],
    );
  }
}

/// Oversized, glance-and-tap playback controls used in presentation mode.
class _BigPlayControls extends StatelessWidget {
  final TacticsState state;
  const _BigPlayControls({required this.state});

  @override
  Widget build(BuildContext context) {
    final animating = state.isAnimating;
    final atStart = state.atStep <= 0;
    final atEnd = state.atStep >= state.maxMoveSteps;
    // A translucent near-black capsule: it sits on the pitch, and the pitch
    // is what the players are looking at.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: T.s16, vertical: T.s8),
      decoration: BoxDecoration(
        color: const Color(0xD1050F12),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: T.border),
        boxShadow: T.shadowFloat,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _bigBtn(
            Icons.chevron_left_rounded,
            (!animating && !atStart) ? state.stepBackward : null,
          ),
          const SizedBox(width: 10),
          _bigBtn(
            animating ? Icons.stop_rounded : Icons.play_arrow_rounded,
            animating ? state.stopAnimation : state.startAnimation,
            primary: true,
          ),
          const SizedBox(width: 12),
          Text(
            '${state.atStep}/${state.maxMoveSteps}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 12),
          _bigBtn(
            Icons.chevron_right_rounded,
            (!animating && !atEnd) ? state.stepForward : null,
          ),
          const SizedBox(width: 10),
          // Toggle the move-arrow overlay while presenting — show the end
          // position first, then reveal how each player got there.
          GestureDetector(
            onTap: () {
              state.toggleShowMoveLines();
              HapticFeedback.selectionClick();
            },
            // Neutral until it is off, and then it is only dimmed — it used
            // to go danger-red, which put a fifth colour in a control group
            // that should carry one.
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.routesOn ? T.accentFill : Colors.transparent,
              ),
              child: Icon(
                state.routesOn
                    ? Icons.timeline_rounded
                    : Icons.visibility_off_outlined,
                color: state.routesOn ? T.accent : Colors.white70,
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigBtn(IconData icon, VoidCallback? onTap, {bool primary = false}) {
    final size = primary ? 58.0 : 48.0;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1.0,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Lime is the play button and nothing else; the rest of the
            // group is neutral so the eye lands on the one action.
            color: primary ? T.lime : Colors.transparent,
          ),
          child: Icon(
            icon,
            color: onTap == null
                ? Colors.white54
                : primary
                ? T.onLime
                : Colors.white,
            size: primary ? 34 : 28,
          ),
        ),
      ),
    );
  }
}

/// Toggles free-form zoom/pan mode. While on, the board content is locked
/// and pinch/drag operate the InteractiveViewer — so zooming can never be
/// confused with dragging a player. Tap off to edit at the new zoom level.
/// "Remove Ads" paywall — a professional in-app-purchase sheet: premium badge,
/// title + value line, a 3-up benefits card, selectable plan cards (yearly
/// preselected, with a "recommended" badge + per-month price), a prominent
/// gradient primary CTA, a secondary Restore link, the App Store-required
/// auto-renew disclosure, and Terms / Privacy links. Selecting a plan only
/// changes [_selectedId]; the CTA buys it. Buying or restoring flips
/// PurchaseService.hasPro, which AdService reads live to disable every ad.
/// The paywall, for pages that gate something of their own on Pro — the
/// match-day sheet's clock. The sheet stays private to this file; this is
/// the one door in.
void showPaywallSheet(BuildContext context) {
  TacticalSheet.show(context, builder: (_) => const _PaywallSheet());
}

class _PaywallSheet extends StatefulWidget {
  const _PaywallSheet();

  @override
  State<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<_PaywallSheet> {
  static final Uri _termsUrl = Uri.parse(
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );
  static final Uri _privacyUrl = Uri.parse(
    'https://tacticsboard.100for1.com/privacy',
  );

  List<ProductDetails>? _products;
  String? _selectedId;
  bool _loading = true;
  bool _busy = false; // a purchase/restore is in flight

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final products = await PurchaseService.instance.productList();
    if (!mounted) return;
    setState(() {
      _products = products;
      // Preselect the yearly plan (the recommended entry point).
      _selectedId = _byId(PurchaseService.yearlyId) != null
          ? PurchaseService.yearlyId
          : (products != null && products.isNotEmpty
                ? products.first.id
                : null);
      _loading = false;
    });
  }

  ProductDetails? _byId(String? id) {
    if (id == null) return null;
    for (final p in _products ?? const <ProductDetails>[]) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> _buySelected() async {
    final product = _byId(_selectedId);
    if (product == null) return;
    setState(() => _busy = true);
    bool pro = false;
    try {
      pro = await PurchaseService.instance.buy(product);
    } catch (_) {
      if (mounted) _toast('pro_purchase_failed'.tr());
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (pro) _done();
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final pro = await PurchaseService.instance.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    if (pro) {
      _done();
    } else {
      _toast('pro_restore_none'.tr());
    }
  }

  void _done() {
    _toast('pro_thanks'.tr());
    Navigator.of(context).pop();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  /// "≈ ¥1.83 / mo" derived from the yearly plan's localized store price.
  String? _perMonth(ProductDetails y) {
    final m = y.rawPrice / 12;
    if (m <= 0) return null;
    return 'pro_permonth'.tr(
      namedArgs: {'p': '${y.currencySymbol}${m.toStringAsFixed(2)}'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final lifetime = _byId(PurchaseService.lifetimeId);
    final yearly = _byId(PurchaseService.yearlyId);
    final hasYearly = yearly != null;
    return SafeArea(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: T.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // The banner carries the premium mood; the badge anchors it.
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          packageAsset('assets/icon/paywall_banner.jpg'),
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(bottom: -18, child: _badge()),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
                Text(
                  'pro_title'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: T.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'pro_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: T.textOff,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                _benefits(),
                const SizedBox(height: 18),
                if (_loading)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: CircularProgressIndicator(color: kAccent),
                    ),
                  )
                else if (lifetime == null && yearly == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'pro_unavailable'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: T.textOff),
                    ),
                  )
                else ...[
                  if (yearly != null)
                    _planCard(
                      yearly,
                      icon: Icons.calendar_month_outlined,
                      title: 'pro_plan_yearly_t'.tr(),
                      desc: 'pro_plan_yearly_d'.tr(),
                      priceSub: _perMonth(yearly),
                      badge: 'pro_badge'.tr(),
                    ),
                  if (yearly != null && lifetime != null)
                    const SizedBox(height: 12),
                  if (lifetime != null)
                    _planCard(
                      lifetime,
                      icon: Icons.diamond_outlined,
                      title: 'pro_plan_lifetime_t'.tr(),
                      desc: 'pro_plan_lifetime_d'.tr(),
                      priceSub: 'pro_lifetime_tag'.tr(),
                    ),
                  const SizedBox(height: 18),
                  _cta(),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      onPressed: _busy ? null : _restore,
                      child: Text(
                        'pro_restore'.tr(),
                        style: const TextStyle(
                          color: T.textDim,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  if (hasYearly) ...[
                    const SizedBox(height: 2),
                    Text(
                      'pro_legal'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: T.textOff,
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _link('pro_terms'.tr(), _termsUrl),
                      const Text(
                        '    ·    ',
                        style: TextStyle(color: T.textDisabled, fontSize: 12),
                      ),
                      _link('pro_privacy'.tr(), _privacyUrl),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 6,
            right: 4,
            child: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: T.textOff,
                size: 22,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge() {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: T.accentFill,
        border: Border.all(color: T.accent.withValues(alpha: 0.5), width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.shield_outlined, color: kAccent, size: 44),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Icon(Icons.star_rounded, color: T.accentText, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _benefits() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: kSurfaceHi,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: T.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _benefit(
            Icons.do_not_disturb_on_outlined,
            'pro_b1_t'.tr(),
            'pro_b1_s'.tr(),
          ),
          _benefitDivider(),
          _benefit(Icons.insights_outlined, 'pro_b2_t'.tr(), 'pro_b2_s'.tr()),
          _benefitDivider(),
          _benefit(Icons.cloud_sync_outlined, 'pro_b3_t'.tr(), 'pro_b3_s'.tr()),
        ],
      ),
    );
  }

  Widget _benefitDivider() =>
      Container(width: 1, height: 44, color: T.border);

  Widget _benefit(IconData icon, String title, String sub) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Icon(icon, color: kAccent, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: T.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              sub,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: T.textOff,
                fontSize: 10.5,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard(
    ProductDetails p, {
    required IconData icon,
    required String title,
    required String desc,
    String? priceSub,
    String? badge,
  }) {
    final selected = _selectedId == p.id;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: _busy ? null : () => setState(() => _selectedId = p.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
            decoration: BoxDecoration(
              color: selected ? kAccentFill : kSurfaceHi,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? T.selectedStroke : T.border,
                width: selected ? 1.6 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: kAccent.withValues(alpha: 0.18),
                        blurRadius: 16,
                        spreadRadius: -6,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                _radio(selected),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? kAccentFill : T.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? T.accentText : T.textDim,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: T.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: T.textOff,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      p.price,
                      style: const TextStyle(
                        color: T.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (priceSub != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        priceSub,
                        style: TextStyle(
                          color: selected ? T.accentText : T.textOff,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: T.onAccent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _radio(bool selected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? T.selectedStroke : T.borderStrong,
          width: selected ? 6.5 : 1.6,
        ),
      ),
    );
  }

  Widget _cta() {
    final enabled = !_busy && _selectedId != null;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(color: T.buttonFill, borderRadius: T.brMd),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? _buySelected : null,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              child: _busy
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: T.onAccent,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_open_rounded,
                          color: T.onAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'pro_cta'.tr(),
                          style: TextStyle(
                            color: T.onAccent,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _link(String label, Uri url) {
    return GestureDetector(
      onTap: () => launchUrl(url, mode: LaunchMode.externalApplication),
      child: Text(
        label,
        style: const TextStyle(color: T.textOff, fontSize: 12),
      ),
    );
  }
}

/// One-time coach mark on a fresh install. The board opens empty, and nothing
/// on it says where players come from — this bubble does, once, and never
/// again after it is tapped away.
/// Said once: selecting an element follows its route.
///
/// The focus rides on a gesture a coach already has — tap a player — which
/// makes it free to reach and invisible to discover. Rather than give it a
/// control of its own, the board says what happened the first time it
/// happens, and never again.
class _FocusHint extends StatefulWidget {
  const _FocusHint();

  @override
  State<_FocusHint> createState() => _FocusHintState();
}

class _FocusHintState extends State<_FocusHint> {
  static const _prefKey = 'focus_hint_seen';
  bool _unseen = false;
  bool _showing = false;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      if (prefs.getBool(_prefKey) != true) setState(() => _unseen = true);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  /// Seen is seen: the pref is written the moment it appears, not when it is
  /// dismissed. A coach who reads it and taps elsewhere has been told.
  void _markSeen() {
    _unseen = false;
    SharedPreferences.getInstance().then((p) => p.setBool(_prefKey, true));
  }

  @override
  Widget build(BuildContext context) {
    // Only for an element that has a route — selecting a cone fades nothing,
    // so there is nothing to explain.
    final onRoute = context.select<TacticsState, bool>((s) {
      final id = s.selectedPlayerId;
      if (id == null) return false;
      for (final p in s.players) {
        if (p.id == id) return p.moves.isNotEmpty;
      }
      return false;
    });

    if (_unseen && onRoute && !_showing) {
      _showing = true;
      _markSeen();
      // Long enough to read, short enough not to become furniture.
      _hide = Timer(const Duration(seconds: 6), () {
        if (mounted) setState(() => _showing = false);
      });
    }
    if (!_showing) return const SizedBox.shrink();
    if (!onRoute) {
      // They moved on before the timer did.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _showing) setState(() => _showing = false);
      });
      return const SizedBox.shrink();
    }

    // At the top, not the bottom. Selecting an element opens the edit bar
    // over the bottom of the board, and the first version of this card was
    // built, found by a test, and invisible underneath it. Here it is clear
    // of the back button and the ⋯ above it, and of everything below.
    return Positioned(
      left: T.s16,
      right: T.s16,
      top: 72,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.fromLTRB(T.s16, T.s12, T.s8, T.s12),
          decoration: BoxDecoration(
            color: T.surface,
            borderRadius: BorderRadius.circular(T.rMd),
            border: Border.all(color: T.border),
            boxShadow: T.shadowFloat,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timeline_rounded, size: 18, color: T.accent),
              const SizedBox(width: T.s8),
              Flexible(
                child: Text(
                  'focus_hint'.tr(),
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 14,
                    color: T.text,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: T.s4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _showing = false),
                child: const Padding(
                  padding: EdgeInsets.all(T.s4),
                  child: Icon(Icons.close_rounded, color: T.textOff, size: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FirstRunHint extends StatefulWidget {
  const _FirstRunHint();

  @override
  State<_FirstRunHint> createState() => _FirstRunHintState();
}

class _FirstRunHintState extends State<_FirstRunHint> {
  static const _prefKey = 'board_hint_seen';
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      if (prefs.getBool(_prefKey) != true) setState(() => _visible = true);
    });
  }

  void _dismiss() {
    setState(() => _visible = false);
    SharedPreferences.getInstance().then((p) => p.setBool(_prefKey, true));
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    // Anything on the board means the coach no longer needs telling how to
    // put something on it — a loaded drill counts as much as a manual add.
    final boardInUse = context.select<TacticsState, bool>(
      (s) => s.players.isNotEmpty || s.strokes.isNotEmpty,
    );
    if (boardInUse) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _visible) _dismiss();
      });
      return const SizedBox.shrink();
    }
    // Full screen has no Add button for the card to point at. Hidden, not
    // dismissed: it is still news when the toolbar comes back.
    if (!context.select<TacticsState, bool>((s) => s.toolbarVisible)) {
      return const SizedBox.shrink();
    }
    // A light coach mark above the toolbar, not a paragraph across the
    // board. It says the one thing a coach needs on an empty pitch, points
    // at the control that does it, and goes away for good.
    // The right rail (zoom / fullscreen) sits at right: 12 and is up to 60
    // wide, so the card has to stop short of it — centred across the full
    // width, it slid under the fullscreen button and hid its own dismiss X.
    return Positioned(
      left: T.s16,
      right: 68,
      bottom: 8,
      child: Center(
        child: Semantics(
          button: true,
          child: GestureDetector(
            // Tapping the card does what the card says. It used to only
            // dismiss, which made its + a button that looked exactly like the
            // toolbar's Add and did the opposite of it.
            onTap: () {
              // Open first, dismiss after. _dismiss() takes this card out of
              // the tree, and showModalBottomSheet resolves its Navigator
              // from the context it is handed — hand it a context that is
              // being unmounted in the same frame and the sheet never
              // arrives, which hung the simulator walk indefinitely.
              showAddElementSheet(context, context.read<TacticsState>());
              _dismiss();
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.fromLTRB(T.s16, T.s12, T.s8, T.s12),
              decoration: BoxDecoration(
                color: T.surface,
                borderRadius: BorderRadius.circular(T.rMd),
                border: Border.all(color: T.border),
                boxShadow: T.shadowFloat,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 18, color: T.accent),
                  const SizedBox(width: T.s8),
                  Flexible(
                    child: Text(
                      'first_run_hint'.tr(args: ['add_label'.tr()]),
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 14,
                        color: T.text,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: T.s4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _dismiss,
                    child: const Padding(
                      padding: EdgeInsets.all(T.s4),
                      child: Icon(
                        Icons.close_rounded,
                        color: T.textOff,
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
