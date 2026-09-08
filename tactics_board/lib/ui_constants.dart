import 'package:flutter/material.dart';

import 'ui/tokens.dart';

/// The old constants, now aliases of the design tokens.
///
/// This file used to be the app's half-built colour system: one accent, one
/// surface pair and a danger colour, while 380 other colours lived inline
/// across the screens. `lib/ui/tokens.dart` is the real system now. These
/// names stay because ~100 call sites use them and renaming every one in a
/// single pass would bury the visual changes in a diff nobody could read —
/// but there is only one value behind each, so the two can no longer drift.
///
/// New code should use `T.` directly. When a screen is next touched, its
/// `kAccent` should become `T.accent` and this file should shrink.

/// The single brand accent. Selected/active state, primary actions, focus.
const Color kAccent = T.accent;

/// Accent at low opacity, for tinted fills behind active controls.
const Color kAccentFill = T.accentFill;

/// Base surface for modal sheets and dialogs.
const Color kSurface = T.surface;

/// Raised surface for cards / list rows / panels sitting on [kSurface].
const Color kSurfaceHi = T.surfaceHi;

/// Destructive action colour (delete / clear-all).
const Color kDanger = T.danger;

/// Palette offered for drawn strokes. Shared by the draw palette and the
/// line-style sheet, which must always offer the same set — otherwise a
/// colour picked in one fails to show as selected in the other.
///
/// These are pigment, not chrome: a coach picks them to tell one run from
/// another on the pitch, so they stay saturated and stay out of the token
/// system, which is about the app's own surfaces.
const List<Color> kStrokeColors = [
  Color(0xFFFFD600),
  Colors.white,
  Color(0xFFE53935),
  Color(0xFF43A047),
  Color(0xFF1E88E5),
  Color(0xFFFF6F00),
];
