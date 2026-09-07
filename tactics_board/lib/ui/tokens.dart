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
  static const bg0 = Color(0xFF071A1D);
  static const bg1 = Color(0xFF0B2328);
  static const surface = Color(0xFF12333B);
  static const surfaceHi = Color(0xFF173E47);

  /// The one border. Low-contrast on purpose: contrast between surfaces does
  /// most of the separating, and a line is only added where that is not
  /// enough.
  static const border = Color(0x2EB4CDD2); // rgba(180,205,210,.18)
  static const borderStrong = Color(0x52B4CDD2); // for a focused control only

  // ── Text ────────────────────────────────────────────────────────────────
  static const text = Color(0xFFF3F7F6);
  static const textDim = Color(0xFF9AAEB1);
  static const textOff = Color(0xFF60777B);

  // ── Accent ──────────────────────────────────────────────────────────────
  /// The primary interactive colour. Selection, primary actions, focus.
  static const accent = Color(0xFF18C7BC);

  /// Accent as a tinted fill behind an active control. Used instead of a
  /// solid accent block, which reads as a button even when it is a state.
  static const accentFill = Color(0x2318C7BC); // ~14%
  static const accentFillHi = Color(0x3818C7BC); // ~22%, pressed

  /// Playback only: play, and the running animation. Never navigation.
  static const lime = Color(0xFFA8F05A);
  static const limeFill = Color(0x24A8F05A);

  // ── Semantic ────────────────────────────────────────────────────────────
  static const home = Color(0xFF3E8EF7);
  static const away = Color(0xFFFF5964);
  static const warning = Color(0xFFE6A93D);
  static const danger = Color(0xFFEF5B62);

  // ── Pitch ───────────────────────────────────────────────────────────────
  /// Deeper and less saturated than the old #2E7D32 family: the players and
  /// the paths have to be the brightest things on the board, and they were
  /// competing with the grass.
  static const turf = Color(0xFF176B35);
  static const turfHi = Color(0xFF1E783C);
  static const turfLine = Color(0xC7FFFFFF); // white @ 78%

  // ── Spacing ─────────────────────────────────────────────────────────────
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;

  /// Horizontal margin for a screen's content.
  static const screenX = 20.0;

  /// Padding inside a panel, a card, a popover.
  static const panelPad = 16.0;

  /// Padding inside a large bottom sheet.
  static const sheetPad = 24.0;

  /// Nothing tappable is smaller than this.
  static const tap = 44.0;

  // ── Radius ──────────────────────────────────────────────────────────────
  static const rSm = 10.0;
  static const rMd = 14.0;
  static const rLg = 20.0;
  static const rSheet = 28.0;

  static const brSm = BorderRadius.all(Radius.circular(rSm));
  static const brMd = BorderRadius.all(Radius.circular(rMd));
  static const brLg = BorderRadius.all(Radius.circular(rLg));
  static const brSheet =
      BorderRadius.vertical(top: Radius.circular(rSheet));

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
  static const titleLg =
      TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: text, height: 1.2);
  static const titleSheet =
      TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: text, height: 1.25);
  static const section =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: text, height: 1.3);
  static const body =
      TextStyle(fontSize: 15.5, fontWeight: FontWeight.w400, color: text, height: 1.45);
  static const secondary =
      TextStyle(fontSize: 13.5, fontWeight: FontWeight.w400, color: textDim, height: 1.45);
  static const toolbar =
      TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: text, height: 1.2);
  static const label = TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600, color: textDim, letterSpacing: 0.6);
}
