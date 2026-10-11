import 'package:flutter/material.dart';

/// The iPad half of the app's layout: a few rules every page outside the
/// board shares, so "tablet" means the same thing on each of them.
///
/// The pages were built for a 402pt phone and on a 1376pt iPad they were
/// that phone stretched — lists with thousand-point lines, forms with
/// thousand-point fields, buttons the width of the screen. Every rule here
/// is gated on [isTabletLayout], so a phone, upright or sideways, lays out
/// exactly as it did.

/// The same test the board uses (home_page.dart `isTablet`, toolbar.dart
/// `uiScale`): the window's short side, so an iPad in Split View still
/// counts and a Pro Max on its side does not.
bool isTabletLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600;

/// The readable width of a list of rows on a tablet — the library, Me,
/// plans, history. Past this a row's name and the value at its end are two
/// things a screen apart.
const double kListMaxWidth = 760;

/// The width of a form — save board, edit plan, sign in, contact. Matches the
/// 620pt the app's sheets already stop at (toolbar.dart kPanelMaxWidth).
const double kFormMaxWidth = 640;

/// Wide enough for a list beside its detail: a 13" iPad either way up, an
/// 11" iPad on its side. A tablet below this keeps push navigation.
const double kSplitMinWidth = 900;

/// [child] centred at no more than [maxWidth], on a tablet only. On a phone
/// it is returned untouched.
Widget tabletColumn(BuildContext context, Widget child,
    {double maxWidth = kListMaxWidth}) {
  if (!isTabletLayout(context)) return child;
  return Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// The extra side margin that centres a [maxWidth] column in [available]
/// points, on a tablet only — for a list that should keep scrolling from
/// anywhere on the screen rather than only inside its column. Zero on a
/// phone, and zero on a tablet window narrower than the column.
double tabletInset(BuildContext context, double available,
    {double maxWidth = kListMaxWidth}) {
  if (!isTabletLayout(context) || available <= maxWidth) return 0;
  return (available - maxWidth) / 2;
}

/// Pushes a full-page form. On a phone that is the usual page; on a tablet
/// it opens as a centred form sheet over the page it came from, the way
/// iPadOS presents a form, rather than a 1376pt-wide page of fields.
Future<T?> pushFormSheet<T>(BuildContext context, Widget page) {
  if (!isTabletLayout(context)) {
    return Navigator.of(context)
        .push<T>(MaterialPageRoute<T>(builder: (_) => page));
  }
  return showDialog<T>(
    context: context,
    barrierColor: const Color(0x8C000000),
    builder: (ctx) {
      final size = MediaQuery.sizeOf(ctx);
      return Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: kFormMaxWidth,
          height: (size.height * 0.86).clamp(320.0, 780.0),
          child: page,
        ),
      );
    },
  );
}
