import 'package:flutter/material.dart';

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
  static const bg0 = Color(0xFF071D1F);
  static const bg1 = Color(0xFF0B272A);
  static const surface = Color(0xFF103338);
  static const surfaceHi = Color(0xFF153D42);

  /// A sheet sits a step above the page but below an elevated surface, so it
  /// does not read as a card the page is wearing. §25.
  static const sheet = Color(0xFF0D292C);

  /// The tinted ground a coach's note sits on — barely a surface at all. §11.
  static const tint = Color(0xFF0B292A);

  /// The one border. Low-contrast on purpose: contrast between surfaces does
  /// most of the separating, and a line is only added where that is not
  /// enough.
  static const border = Color(0x2EB4CDD2); // rgba(180,205,210,.18)
  static const borderStrong = Color(0x52B4CDD2); // for a focused control only

  // ── Text ────────────────────────────────────────────────────────────────
  static const text = Color(0xFFF4F7F5);
  static const textDim = Color(0xFFA9BAB8);
  static const textOff = Color(0xFF718A88);
  static const textDisabled = Color(0xFF506765);

  // ── Accent ──────────────────────────────────────────────────────────────
  /// The primary interactive colour. Selection, primary actions, focus.
  static const accent = Color(0xFF20C7C3);

  /// Pressed / currently-running. One step brighter, never a glow.
  static const accentActive = Color(0xFF2DD4CF);

  /// Foreground on a filled accent button. Dark enough to read at 17pt
  /// semibold without going to pure black, which is harsh on teal.
  static const onAccent = Color(0xFF062526);

  /// Accent as a tinted fill behind an active control. Used instead of a
  /// solid accent block, which reads as a button even when it is a state.
  static const accentFill = Color(0x1F20C7C3); // rgba(32,199,195,.12)
  static const accentFillHi = Color(0x3320C7C3); // ~20%, pressed

  /// Playback only: play, and the running animation. Never navigation.
  static const lime = Color(0xFFA8F05A);

  /// Foreground on [lime]. Lime is bright enough that white text on it is
  /// unreadable and pure black is harsh, so the play glyph gets a very dark
  /// green instead. Two screens had this value written out by hand.
  static const onLime = Color(0xFF16240A);
  static const limeFill = Color(0x24A8F05A);

  // ── Semantic ────────────────────────────────────────────────────────────
  static const home = Color(0xFF4D8FE8);
  static const away = Color(0xFFE86452);
  static const success = Color(0xFF4DBA78);
  static const warning = Color(0xFFE9A94B);
  static const danger = Color(0xFFE26B62);

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
