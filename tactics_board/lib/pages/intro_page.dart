import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sport_type.dart';
import '../ui/tokens.dart';
import '../widgets/sport_glyph.dart';

/// What this app is, in the four seconds before the coach decides.
///
/// The home page answers "what do I do now" but never "what is this" — and
/// the one thing that separates this from every other tactics board, a
/// library of drills with the coaching written out, is the thing a new user
/// is least likely to find on their own: it is behind a card called "what to
/// run today" that they will scroll past on the way to drawing.
///
/// Three panels, skippable from the first, shown once. A fourth would be one
/// more thing between someone and the board they came for.
///
/// Each panel is a full-bleed photograph of the sport with the words laid
/// over the empty top of it. The art is OPTIONAL: an app whose
/// `assets/intro/intro_N.webp` has not been shot yet falls back to a plain
/// gradient and the panel's icon, so a new sport ships before its artwork
/// does. See tools/intro_art_prompts.html for how the art is made and why
/// each app owns its own copy.
class IntroPage extends StatefulWidget {
  final SportType sportType;

  /// How many drills THIS app ships. Not the 624 in the repository: a
  /// single-sport build carries only its own sport's library, so the intro
  /// of Soccer Board promising six hundred drills is a promise of five
  /// hundred it does not have.
  ///
  /// Null until the library has been read. The intro does NOT wait for it —
  /// a first impression that begins with a blank frame while a file loads is
  /// a worse first impression than one without a number in it, and the
  /// reader is on the first panel long before the second one is reached.
  final int? drillCount;

  /// Runs when the intro is finished or skipped — the app carries on.
  final VoidCallback onDone;

  const IntroPage({
    super.key,
    required this.sportType,
    this.drillCount,
    required this.onDone,
  });

  static const _prefKey = 'intro_seen';

  /// Whether it still has to be shown. False forever after the first time.
  static Future<bool> shouldShow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) != true;
    } catch (_) {
      // No prefs is a first run in every way that matters, but showing the
      // intro on every launch because storage is broken would be worse than
      // never showing it.
      return false;
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    } catch (_) {}
  }

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final _pages = PageController();
  int _at = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await IntroPage.markSeen();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final panels = <_Panel>[
      _Panel(
        n: 1,
        icon: Icons.gesture,
        title: 'intro_board_t'.tr(),
        body: 'intro_board_b'.tr(),
      ),
      _Panel(
        n: 2,
        icon: Icons.menu_book_outlined,
        title: widget.drillCount == null
            ? 'intro_drills_t_plain'.tr()
            : 'intro_drills_t'.tr(args: ['${widget.drillCount}']),
        body: 'intro_drills_b'.tr(),
      ),
      _Panel(
        n: 3,
        icon: Icons.event_note_outlined,
        title: 'intro_plan_t'.tr(),
        body: 'intro_plan_b'.tr(),
        // Only the last panel carries them: it is the one making a claim
        // about a whole session rather than about one board.
        pillars: const [
          (Icons.event_available_outlined, 'intro_pillar_plan'),
          (Icons.checklist_rtl, 'intro_pillar_run'),
          (Icons.trending_up, 'intro_pillar_grow'),
        ],
      ),
    ];
    final last = _at == panels.length - 1;
    return Scaffold(
      backgroundColor: T.bg0,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The art slides with its own words rather than cross-fading under
          // them: a backdrop that stays put while the headline moves reads
          // as a bug on the very first screen of the app.
          PageView(
            controller: _pages,
            onPageChanged: (i) => setState(() => _at = i),
            children: [
              for (final p in panels)
                _PanelView(panel: p, sport: widget.sportType),
            ],
          ),
          // Chrome sits above the pager so it does not slide: skip, the dots
          // and the button belong to the intro, not to a panel.
          SafeArea(
            child: Column(
              children: [
                // Skip is on every panel including the first: someone who
                // knows what a tactics board is should never have to page
                // through an explanation of one.
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, T.s8, T.s12, 0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _finish,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: T.s12, vertical: T.s8),
                        child: Text('intro_skip'.tr(),
                            style: const TextStyle(
                                color: T.textDim,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < panels.length; i++) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == _at ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _at ? T.accent : T.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      if (i != panels.length - 1) const SizedBox(width: 6),
                    ],
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      T.screenX, T.s20, T.screenX, T.s20),
                  child: _BigCta(
                    label: last ? 'intro_start'.tr() : 'intro_next'.tr(),
                    onTap: last
                        ? _finish
                        : () => _pages.nextPage(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel {
  /// Which of the three, and so which image: `assets/intro/intro_$n.webp`.
  final int n;
  final IconData icon;
  final String title;
  final String body;
  final List<(IconData, String)> pillars;
  const _Panel({
    required this.n,
    required this.icon,
    required this.title,
    required this.body,
    this.pillars = const [],
  });
}

class _PanelView extends StatelessWidget {
  final _Panel panel;
  final SportType sport;
  const _PanelView({required this.panel, required this.sport});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _Backdrop(n: panel.n, icon: panel.icon),
        // Two scrims, not one: the headline needs the top dark enough to read
        // white on, and the button at the foot needs the same. The middle is
        // left alone — that band is where the board and the ball are.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xF0071A1D),
                Color(0xB8071A1D),
                Color(0x00071A1D),
                Color(0x00071A1D),
                Color(0xCC071A1D),
                Color(0xF5071A1D),
              ],
              stops: [0.0, 0.22, 0.46, 0.62, 0.88, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            // Clear of the skip row, and never further down than the top
            // third: the art below it is composed with the top 40% empty, so
            // words that drift lower start landing on the board.
            padding: const EdgeInsets.fromLTRB(T.s32, 52, T.s32, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Which of the sixteen apps this is. Small, spaced and dim:
                // it is a label on the page, not a line of the pitch.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SportGlyph(sport: sport, size: 14),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'home_board_title'.tr(args: [sport.displayName]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: T.textOff,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: T.s20),
                _StrokeTitle(raw: panel.title),
                const SizedBox(height: T.s16),
                Text(
                  panel.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: T.textDim, fontSize: 15.5, height: 1.6),
                ),
                if (panel.pillars.isNotEmpty) ...[
                  const SizedBox(height: T.s32),
                  _Pillars(items: panel.pillars),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The photograph, or the gradient that stands in for one.
///
/// Anchored to the bottom on purpose: the art is shot for a 9:19.5 frame with
/// the board low in it, so a shorter phone must lose the empty sky at the top
/// rather than crop the board off the bottom.
class _Backdrop extends StatelessWidget {
  final int n;
  final IconData icon;
  const _Backdrop({required this.n, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      // NOT packageAsset(): that resolves to the core package, and the core
      // would then have to carry all sixteen sports' artwork into every one
      // of the sixteen apps. A bare path resolves to the SHELL's own bundle,
      // the same way each app owns its icon — see CLAUDE.md, "one app = one
      // directory".
      'assets/intro/intro_$n.webp',
      fit: BoxFit.cover,
      alignment: Alignment.bottomCenter,
      // Every app owns its own three images, so most of the sixteen will not
      // have them on the day the layout lands. That is not an error state —
      // it is the app running without artwork.
      errorBuilder: (_, _, _) => _NoArt(icon: icon),
    );
  }
}

class _NoArt extends StatelessWidget {
  final IconData icon;
  const _NoArt({required this.icon});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [T.bg0, T.bg1, T.bg0],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Align(
        // In the lower 60%, where the board would be — so the words above it
        // sit at the same height with art and without.
        alignment: const Alignment(0, 0.35),
        child: Container(
          width: 108,
          height: 108,
          decoration: const BoxDecoration(
              color: T.accentFill, shape: BoxShape.circle),
          child: Icon(icon, size: 44, color: T.accent),
        ),
      ),
    );
  }
}

/// A title with one run in accent and a hand-drawn stroke under it.
///
/// The run is marked in the translation file with asterisks — "画出来，*再走
/// 一遍*" — rather than worked out from the text, because which words carry
/// the line is a writing decision and it is different in every language. A
/// title with no asterisks is drawn plainly, so a locale nobody has marked
/// still reads correctly instead of guessing.
class _StrokeTitle extends StatelessWidget {
  final String raw;
  const _StrokeTitle({required this.raw});

  static const _style = TextStyle(
    color: T.text,
    fontSize: 31,
    fontWeight: FontWeight.w700,
    height: 1.28,
    letterSpacing: -0.4,
  );

  @override
  Widget build(BuildContext context) {
    final m = _Marked.parse(raw);
    // A TextPainter inherits nothing, so the ambient style has to be merged
    // in by hand — without it the title alone falls back to the platform
    // default face while every other line on the page uses the theme's, and
    // in a locale whose glyphs only exist in the fallback family it renders
    // as empty boxes.
    final style = DefaultTextStyle.of(context).style.merge(_style);
    return LayoutBuilder(
      builder: (context, c) {
        final tp = TextPainter(
          text: TextSpan(children: [
            TextSpan(text: m.text.substring(0, m.start), style: style),
            TextSpan(
                text: m.text.substring(m.start, m.end),
                style: style.copyWith(color: T.accent)),
            TextSpan(text: m.text.substring(m.end), style: style),
          ]),
          textAlign: TextAlign.center,
          textDirection: Directionality.of(context),
          maxLines: 3,
          ellipsis: '…',
        )..layout(minWidth: c.maxWidth, maxWidth: c.maxWidth);
        return CustomPaint(
          size: Size(c.maxWidth, tp.height),
          painter: _StrokePainter(tp, m),
        );
      },
    );
  }
}

class _StrokePainter extends CustomPainter {
  final TextPainter tp;
  final _Marked marked;
  const _StrokePainter(this.tp, this.marked);

  @override
  void paint(Canvas canvas, Size size) {
    if (marked.hasAccent) {
      final boxes = tp.getBoxesForSelection(TextSelection(
          baseOffset: marked.start, extentOffset: marked.end));
      final brush = Paint()
        ..color = T.accent
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final b in boxes) {
        // Under the run and a little past it at both ends, dipping in the
        // middle: a marker pulled across in one go, not a text-decoration
        // rule. The overshoot is what stops it reading as an underline.
        final y = b.bottom - 5;
        canvas.drawPath(
          Path()
            ..moveTo(b.left - 4, y - 1.5)
            ..quadraticBezierTo((b.left + b.right) / 2, y + 4.5, b.right + 6, y - 2.5),
          brush,
        );
      }
    }
    tp.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(_StrokePainter old) =>
      old.tp != tp || old.marked.text != marked.text;
}

/// "画出来，*再走一遍*" → the text without asterisks, and where the run is.
class _Marked {
  final String text;
  final int start;
  final int end;
  const _Marked(this.text, this.start, this.end);

  bool get hasAccent => end > start;

  static _Marked parse(String raw) {
    final open = raw.indexOf('*');
    if (open < 0) return _Marked(raw, 0, 0);
    final close = raw.indexOf('*', open + 1);
    // A lone asterisk is a typo in a translation file, not a marker; drop it
    // rather than showing it to a reader.
    if (close < 0) return _Marked(raw.replaceAll('*', ''), 0, 0);
    final text = raw.substring(0, open) +
        raw.substring(open + 1, close) +
        raw.substring(close + 1);
    return _Marked(text, open, close - 1);
  }
}

class _Pillars extends StatelessWidget {
  final List<(IconData, String)> items;
  const _Pillars({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i != 0)
            Container(width: 1, height: 34, color: T.border),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: T.accentFill, shape: BoxShape.circle),
                  child: Icon(items[i].$1, size: 21, color: T.accent),
                ),
                const SizedBox(height: T.s8),
                Text(
                  items[i].$2.tr(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: T.text, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The intro's own button: a full-width pill with the label centred and the
/// arrow beside it. Deliberately not [TacticalButton] — that one is the
/// app's working button, sized and cornered for a toolbar, and widening it
/// here would change every screen that uses it.
class _BigCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BigCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: T.accent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF04231F),
                        fontSize: 17,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: T.s12),
                const Icon(Icons.arrow_forward,
                    size: 20, color: Color(0xFF04231F)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
