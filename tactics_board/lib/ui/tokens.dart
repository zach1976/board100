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
  // Light, V4.3 (2026-10-15). The ladder, lightest page first: bg0 is the
  // warm off-white page behind everything; bg1 a bar or nav strip; surface
  // a white card or sheet; surfaceHi a row or selected tile on a card, one
  // step of cool tint down from white. Shared by all sixteen apps — only
  // the accents change per sport. [palette] is set once, in main(), before
  // the first frame, which is why the accent tokens are getters and why
  // nothing below may write `const Foo(color: T.accent)`.
  static SportPalette _p = SportPalette.hub;
  static SportPalette get palette => _p;
  static set palette(SportPalette p) => _p = p;

  static const bg0 = LightTokens.appBackground;
  static const bg1 = LightTokens.secondarySurface;
  static const surface = LightTokens.surface;
  static const surfaceHi = LightTokens.elevatedSurface;

  /// A sheet is a white card rising from the page. §25.
  static const sheet = LightTokens.surface;

  /// The tinted ground a coach's note sits on — barely a surface at all. §11.
  static const tint = LightTokens.secondarySurface;

  /// The page canvas behind a scrolling list, one step warmer than [bg0].
  static const canvas = LightTokens.pageBackground;

  /// Decorative dividers and card edges: low contrast on purpose. An input
  /// boundary or anything that must be found takes [borderStrong] (≥ 3:1).
  static const border = LightTokens.decorativeBorder;
  static const borderStrong = LightTokens.inputBorder;

  // ── Text ────────────────────────────────────────────────────────────────
  static const text = LightTokens.textPrimary;
  static const textDim = LightTokens.textSecondary;
  static const textOff = LightTokens.textTertiary;
  /// Disabled: never carries information a coach has to read.
  static const textDisabled = Color(0xFF8A97A6);
  static const disabledFill = LightTokens.disabledSurface;

  // ── Accent ──────────────────────────────────────────────────────────────
  // One brand per app: the sport's primary (the hub its slate). Fills and
  // identity use [accent]; anything a coach reads in the brand colour uses
  // [accentText], and a selection outline [selectedStroke] — both derived
  // to read on every light ground (V4.3 audit).

  /// The brand colour: filled surfaces, identity, large graphics.
  static Color get accent => _p.accent;

  /// Brand-coloured text: links, selected nav labels, active chips.
  static Color get accentText => _p.accentText;

  /// A selected card, tab or tool's outline.
  static Color get selectedStroke => _p.selectedStroke;

  /// Pressed / currently-running. One step darker, never a glow.
  static Color get accentActive =>
      Color.lerp(_p.accent, const Color(0xFF000000), 0.10)!;

  /// The filled button: the brand, or a sibling of it tuned so its label
  /// reads at 5:1.
  static Color get buttonFill => _p.buttonFill;

  /// Foreground on [buttonFill] / [accent]: dark ink or white, whichever
  /// the audit measured.
  static Color get onAccent => _p.onAccent;

  /// The brand as a soft tinted ground behind a selected row or a branded
  /// panel; [accentText] reads on it.
  static Color get accentFill => _p.soft;
  static Color get accentFillHi => _p.accent.withValues(alpha: 0.20);

  /// The sport's secondary accent: decorative only. Text in it takes
  /// [accent2Text], a thin stroke [accent2Stroke].
  static Color get accent2 => _p.secondary;
  static Color get accent2Text => _p.secondaryText;
  static Color get accent2Stroke => _p.secondaryStroke;

  /// The tool a coach is currently IN — Move, Draw, Select. A dark neutral
  /// pill: a mode is a state, and the brand is kept for actions.
  static const toolOn = LightTokens.textSecondary;
  static const onToolOn = Color(0xFFFFFFFF);

  /// Playback: play, and the running animation. The app's button fill.
  static Color get lime => _p.buttonFill;
  static Color get onLime => _p.onAccent;
  static Color get limeFill => _p.soft;

  // ── Semantic ────────────────────────────────────────────────────────────
  // The state of the app, the same in every sport. Never a brand colour.
  // Team colours belong to the board, not the chrome: unchanged.
  static const home = Color(0xFF4D8FE8);
  static const away = Color(0xFFE86452);
  static const success = LightTokens.success;
  static const danger = LightTokens.error;
  static const info = LightTokens.information;
  static const focus = LightTokens.focus;

  /// Warning is four tokens: the amber icon always sits beside
  /// [warningText] (the only one that is read), on [warningBackground]
  /// inside [warningBorder].
  static const warning = LightTokens.warningText;
  static const warningIcon = LightTokens.warningIcon;
  static const warningBackground = LightTokens.warningBackground;
  static const warningBorder = LightTokens.warningBorder;

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
    BoxShadow(color: Color(0x1F16212E), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> shadowSheet = [
    BoxShadow(color: Color(0x2616212E), blurRadius: 32, offset: Offset(0, -8)),
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

/// One app's colours as the tokens read them (V4.3).
class SportPalette {
  const SportPalette({
    required this.accent,
    required this.onAccent,
    required this.buttonFill,
    required this.accentText,
    required this.selectedStroke,
    required this.secondary,
    required this.secondaryText,
    required this.secondaryStroke,
    required this.soft,
  });

  final Color accent;
  final Color onAccent;
  final Color buttonFill;
  final Color accentText;
  final Color selectedStroke;
  final Color secondary;
  final Color secondaryText;
  final Color secondaryStroke;
  final Color soft;

  factory SportPalette.fromColors(SportColorPalette c) => SportPalette(
        accent: c.primaryAccent,
        onAccent: c.primaryButtonForeground,
        buttonFill: c.primaryButtonFill,
        accentText: c.accentText,
        selectedStroke: c.selectedStroke,
        secondary: c.secondaryAccent,
        secondaryText: c.secondaryAccentText,
        secondaryStroke: c.secondaryAccentStroke,
        soft: c.accentSoftBackground,
      );

  /// The hub's own brand (the `null` row of the table).
  static final hub = SportPalette.fromColors(kSportColors[null]!);
}
