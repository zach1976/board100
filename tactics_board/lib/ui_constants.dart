import 'package:flutter/material.dart';

/// Shared visual constants — one accent colour and one surface colour scale,
/// so the whole app reads as a single, calm, professional system instead of
/// the rainbow of cyan / mint / purple / orange accents and five different
/// dialog backgrounds it grew over time.

/// The single brand accent. Used for selected/active state, primary actions,
/// and focus highlights. Refined teal-green — confident, not playful.
const Color kAccent = Color(0xFF00C2B2);

/// Accent at low opacity, for tinted fills behind active controls.
const Color kAccentFill = Color(0x2900C2B2); // ~16%

/// Base surface for modal sheets and dialogs.
const Color kSurface = Color(0xFF15303A);

/// Raised surface for cards / list rows / panels sitting on [kSurface].
const Color kSurfaceHi = Color(0xFF20424C);

/// Destructive action colour (delete / clear-all).
const Color kDanger = Color(0xFFFF6B6B);
