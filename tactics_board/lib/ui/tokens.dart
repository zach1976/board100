import 'package:flutter/material.dart';

import 'sport_palettes.g.dart';

/// The design system, in one file.
///
/// Before this existed the app carried 380 hardcoded colours across 202
/// distinct values, five different sheet backgrounds and every radius from 8
/// to 32. Every screen invented its own. These tokens are the single source:
/// nothing in `lib/` should write `Color(0x…)` for chrome again, and anything
/// that does is a leftover to migrate.
///
/// The direction is "professional coaching software for the sideline":
/// the pitch is the hero, the chrome recedes, one accent carries interaction.
class T {
  const T._();

  // ── Surfaces ────────────────────────────────────────────────────────────
  // Four steps, deepest first. Background0 is the page behind everything;
  // Surface is a sheet; SurfaceHi is a row or card sitting on a sheet.
  //
  // These six are the only tokens that change per app: a single-sport build
  // takes its chrome's hue from the sport (navy for a volleyball hall, green
  // for a pitch) so the app and its store set are one colour family. The hub
  // keeps the teal they all started from. [palette] is set once, in main(),
  // before the first frame — which is why these are getters and not consts,
  // and why nothing below may write `const Foo(color: T.bg0)`.
  static SportPalette _p = SportPalette.teal;
  static SportPalette get palette => _p;
  static set palette(SportPalette p) => _p = p;

  static Color get bg0 => _p.bg0;
  static Color get bg1 => _p.bg1;
  static Color get surface => _p.surface;
  static Color get surfaceHi => _p.surfaceHi;

  /// A sheet sits a step above the page but below an elevated surface, so it
  /// does not read as a card the page is wearing. §25.
  static Color get sheet => _p.sheet;

  /// The tinted ground a coach's note sits on — barely a surface at all. §11.
  static Color get tint => _p.tint;

  /// The one border. Low-contrast on purpose: contrast between surfaces does
  /// most of the separating, and a line is only added where that is not
  /// enough.
  // Text, borders and the functional colours are the family's
  // (tools/design/sport_palettes.py → FamilyTokens): one cool neutral scale
  // for every app, so a warm chrome no longer wears teal-tinted greys.
  static const border = Color(0xB333383F); // divider @ 70%
  static const borderStrong = FamilyTokens.borderStrong; // a focused control only

  // ── Text ────────────────────────────────────────────────────────────────
  static const text = FamilyTokens.textPrimary;
  static const textDim = FamilyTokens.textSecondary;
  // ≥ 3:1 on every sport's elevated surface (the script checks it).
  static const textOff = FamilyTokens.textTertiary;
  static const textDisabled = FamilyTokens.textDisabled;

  // ── Accent ──────────────────────────────────────────────────────────────
  // One accent per app: the sport's primary (the hub keeps its teal). It
  // carries every action, selection and the play button — the board used to
  // show teal, blue, lime and a sport colour at once, and none of them led.

  /// The primary interactive colour. Selection, primary actions, focus.
  static Color get accent => _p.accent;

  /// Pressed / currently-running. One step brighter, never a glow.
  static Color get accentActive =>
      Color.lerp(_p.accent, const Color(0xFFFFFFFF), 0.12)!;

  /// Foreground on a filled accent: dark ink on a light accent, white on a
  /// deep one — whichever the script measured at ≥ 4.5:1.
  static Color get onAccent => _p.onAccent;

  /// Accent as a tinted fill behind an active control. Used instead of a
  /// solid accent block, which reads as a button even when it is a state.
  static Color get accentFill => _p.accent.withValues(alpha: 0.12);
  static Color get accentFillHi => _p.accent.withValues(alpha: 0.20);

  /// The sport's secondary accent: small supporting details only.
  static Color get accent2 => _p.secondary;

  /// The tool a coach is currently IN — Move, Draw, Select. A light neutral
  /// pill, not a second hue: a mode is a state, and the accent is kept for
  /// the one action beside it (play).
  static const toolOn = Color(0xFF4A525C);
  static const onToolOn = Color(0xFFFFFFFF);

  /// Playback: play, and the running animation. The app's accent.
  static Color get lime => _p.accent;
  static Color get onLime => _p.onAccent;
  static Color get limeFill => _p.accent.withValues(alpha: 0.14);

  // ── Semantic ────────────────────────────────────────────────────────────
  // Team colours belong to the board, not the chrome: unchanged.
  static const home = Color(0xFF4D8FE8);
  static const away = Color(0xFFE86452);
  static const success = FamilyTokens.success;
  static const warning = FamilyTokens.warning;
  static const danger = FamilyTokens.error;
  static const info = FamilyTokens.info;
  static const focus = FamilyTokens.focus;

  /// Movement on the board, by what the movement IS — not by whose turn it
  /// is to be colourful. §09.
  static const routePass = Color(0xFF35C7C2);
  static const routeRun = Color(0xFFE3A348);
  static const routeAlt = Color(0xFFB66BD4);

  /// The ring on a selected player. A ring, not a glow. §09.
  static const selectRing = Color(0xFFFFFFFF);

  // ── Pitch ───────────────────────────────────────────────────────────────
  /// Deeper and less saturated than the old #2E7D32 family: the players and
  /// the paths have to be the brightest things on the board, and they were
  /// competing with the grass.
  static const turf = Color(0xFF126B36);
  static const turfHi = Color(0xFF178443);
  static const turfLight = Color(0xFF20974D);
  static const turfLine = Color(0xBFFFFFFF); // white @ 75%, never pure

  // ── Spacing ─────────────────────────────────────────────────────────────
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s28 = 28.0;
  static const s32 = 32.0;
  static const s40 = 40.0;

  /// Between two sections of a page. §06.
  static const sectionGap = 28.0;

  /// Horizontal margin for a screen's content.
  static const screenX = 20.0;

  /// Padding inside a panel, a card, a popover.
  static const panelPad = 16.0;

  /// Padding inside a large bottom sheet.
  static const sheetPad = 24.0;

  /// Nothing tappable is smaller than this.
  static const tap = 44.0;

  // ── Radius ──────────────────────────────────────────────────────────────
  /// Small control: a chip, a tag, a stepper button.
  static const rSm = 9.0;

  /// Button.
  static const rMd = 14.0;

  /// Card. Was 20 — the brief's point is that a card is not a pill, and at 20
  /// every panel read as one more rounded blob. §07.
  static const rLg = 16.0;

  /// Sheet, top corners only.
  static const rSheet = 24.0;

  /// The board itself, which is a card laid on the page rather than the page.
  /// Larger than a card's [rLg] on purpose: it is the biggest thing on the
  /// screen, and at 16 the corner reads as a mistake rather than a shape.
  static const rBoard = 22.0;

  /// Dialog. §24.
  static const rDialog = 18.0;

  static const brSm = BorderRadius.all(Radius.circular(rSm));
  static const brMd = BorderRadius.all(Radius.circular(rMd));
  static const brLg = BorderRadius.all(Radius.circular(rLg));
  static const brDialog = BorderRadius.all(Radius.circular(rDialog));
  static const brSheet =
      BorderRadius.vertical(top: Radius.circular(rSheet));

  // ── Icons ───────────────────────────────────────────────────────────────
  /// Three sizes, so a row of icons never mixes 17 with 22 by accident. §27.
  static const iSm = 16.0;
  static const iMd = 20.0;
  static const iLg = 24.0;

  // ── Elevation ───────────────────────────────────────────────────────────
  /// One shadow for floating chrome, one for a sheet. Not a shadow on
  /// everything: most separation comes from the surface step.
  static const List<BoxShadow> shadowFloat = [
    BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> shadowSheet = [
    BoxShadow(color: Color(0x73000000), blurRadius: 32, offset: Offset(0, -8)),
  ];

  // ── Type ────────────────────────────────────────────────────────────────
  // Sizes and weights only: the family comes from the platform so CJK and
  // Thai fall back correctly, which a bundled Latin face would break.
  /// 1 — DISPLAY. A page's own name, once per page.
  static const display = TextStyle(
      fontSize: 30, fontWeight: FontWeight.w700, color: text, height: 1.18);

  /// Kept: the app already asks for `titleLg` in a dozen places, and it means
  /// exactly this.
  static const titleLg = display;

  static const titleSheet = TextStyle(
      fontSize: 21, fontWeight: FontWeight.w600, color: text, height: 1.25);

  /// 2 — SECTION TITLE.
  static const section = TextStyle(
      fontSize: 18, fontWeight: FontWeight.w600, color: text, height: 1.3);

  /// 3 — BODY. 16pt is the floor the brief sets for readable dark-mode CJK
  /// (§05, §29); it was 15.5 with a 1.45 leading and read thin.
  static const body = TextStyle(
      fontSize: 16.5, fontWeight: FontWeight.w400, color: text, height: 1.5);

  /// 4 — META. "8 分钟", "8 人", "热身". Medium, never thin: at regular
  /// weight on a dark ground these disappear.
  static const meta = TextStyle(
      fontSize: 14.5, fontWeight: FontWeight.w500, color: textDim, height: 1.3);

  /// 5 — CAPTION.
  static const caption = TextStyle(
      fontSize: 12.5, fontWeight: FontWeight.w400, color: textOff, height: 1.35);

  /// Secondary body — a full sentence that is not the main one. Distinct from
  /// [caption], which is a fragment.
  static const secondary = TextStyle(
      fontSize: 14.5, fontWeight: FontWeight.w400, color: textDim, height: 1.45);

  static const toolbar = TextStyle(
      fontSize: 13.5, fontWeight: FontWeight.w500, color: text, height: 1.2);

  /// A dialog's title and body. §24 sets these apart from a page's section
  /// heading: a dialog asks one question, and its title carries more weight
  /// than a heading inside a page that is already being read.
  static const dialogTitle = TextStyle(
      fontSize: 20, fontWeight: FontWeight.w600, color: text, height: 1.25);
  static const dialogBody = TextStyle(
      fontSize: 15.5, fontWeight: FontWeight.w400, color: textDim, height: 1.45);

  /// An all-caps eyebrow above a group.
  static const label = TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600, color: textDim, letterSpacing: 0.6);
}

/// The six chrome surfaces of one app, deepest first.
///
/// Every sport's set is the teal reference with its hue replaced — the same
/// six lightness and saturation steps, so the surface ladder (page, sheet,
/// card) separates identically in every app and only the colour family moves.
class SportPalette {
  const SportPalette({
    required this.bg0,
    required this.bg1,
    required this.surface,
    required this.surfaceHi,
    required this.sheet,
    required this.tint,
    this.accent = const Color(0xFF20C7C3),
    this.onAccent = const Color(0xFF062526),
    this.secondary = const Color(0xFF8FA3B5),
  });

  final Color bg0;
  final Color bg1;
  final Color surface;
  final Color surfaceHi;
  final Color sheet;
  final Color tint;
  final Color accent;
  final Color onAccent;
  final Color secondary;

  /// The hub: the family's slate surfaces at the family hue itself, with
  /// the teal it has always worn as its accent.
  static const teal = SportPalette(
    bg0: Color(0xFF0D1116),
    bg1: Color(0xFF12161C),
    surface: Color(0xFF171C22),
    surfaceHi: Color(0xFF252B32),
    sheet: Color(0xFF171C22),
    tint: Color(0xFF12161C),
  );

  /// A sport's palette from the family system (sport_palettes.g.dart).
  /// Background, surface, elevated → bg0, surface, surfaceHi; the steps in
  /// between are mixes, so the four-step ladder the screens were built on
  /// keeps its order.
  factory SportPalette.fromColors(SportColors c) => SportPalette(
        bg0: c.background,
        bg1: Color.lerp(c.background, c.surface, 0.5)!,
        surface: c.surface,
        surfaceHi: c.elevatedSurface,
        sheet: c.surface,
        tint: Color.lerp(c.background, c.surface, 0.5)!,
        accent: c.primaryAccent,
        onAccent: c.onPrimaryAccent,
        secondary: c.secondaryAccent,
      );

  /// The teal ladder re-hued. [hue] is in degrees; [saturation] scales the
  /// reference's own, so a sand-coloured chrome can sit a little quieter than
  /// a blue one without a second ladder.
  factory SportPalette.hue(double hue, {double saturation = 1.0}) {
    Color re(Color c) {
      final h = HSLColor.fromColor(c);
      return h
          .withHue(hue % 360)
          .withSaturation((h.saturation * saturation).clamp(0.0, 1.0))
          .toColor();
    }
    return SportPalette(
      bg0: re(teal.bg0),
      bg1: re(teal.bg1),
      surface: re(teal.surface),
      surfaceHi: re(teal.surfaceHi),
      sheet: re(teal.sheet),
      tint: re(teal.tint),
    );
  }
}
