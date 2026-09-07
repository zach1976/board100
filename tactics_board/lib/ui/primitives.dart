import 'package:flutter/material.dart';

import 'tokens.dart';

/// The shared UI vocabulary.
///
/// Drills, Language, Add and Pitch each used to build their own sheet — their
/// own background, radius, drag handle, header row, close button and padding.
/// Four sheets, four looks. Everything here exists so that stops: a screen
/// says what it contains, not what it looks like.

// ── Sheets ────────────────────────────────────────────────────────────────

/// The one bottom sheet. Wrap the content; the chrome comes for free.
///
/// [maxHeightFraction] keeps a sheet from swallowing the board — past it the
/// content scrolls inside the sheet instead of pushing the pitch off screen.
class TacticalSheet extends StatelessWidget {
  final Widget child;
  final double maxHeightFraction;
  final EdgeInsets padding;

  const TacticalSheet({
    super.key,
    required this.child,
    this.maxHeightFraction = 0.72,
    this.padding = const EdgeInsets.fromLTRB(
        T.sheetPad, T.s12, T.sheetPad, T.s20),
  });

  /// Open [builder] as a sheet with the app's shape and barrier.
  static Future<T2?> show<T2>(BuildContext context,
      {required WidgetBuilder builder, bool isScrollControlled = true}) {
    return showModalBottomSheet<T2>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C000000),
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // At a large accessibility text size the fixed part of a sheet — its
    // title, search field and filter rows — grows faster than the list does,
    // and at 200% it can exceed the whole sheet, leaving the list zero
    // height and the column overflowing. Give the sheet more of the screen
    // before that happens; the content itself still scrolls inside it.
    final scale = mq.textScaler.scale(15) / 15;
    final fraction =
        (maxHeightFraction * (scale > 1.2 ? 1.15 : 1.0)).clamp(0.3, 0.94);
    final maxH = mq.size.height * fraction;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: T.surface,
        borderRadius: T.brSheet,
        boxShadow: T.shadowSheet,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DragHandle(),
              // Flexible, not a bare child: the column is mainAxisSize.min,
              // so an unwrapped child is handed unbounded height and any
              // Flexible inside it takes the full intrinsic height of its
              // list — 16,302 pixels of drill library, in the first version
              // of this widget.
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.only(bottom: T.s16),
          decoration: BoxDecoration(
            color: T.textOff,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

/// Title, optional subtitle, optional trailing actions, and one close button
/// in the same place on every sheet.
class TacticalSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onClose;

  const TacticalSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: T.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: T.titleSheet, maxLines: 2),
                // The subtitle is a courtesy, and at a large text size it is
                // the first thing that should give up its room.
                if (subtitle != null &&
                    MediaQuery.of(context).textScaler.scale(15) < 19) ...[
                  const SizedBox(height: T.s4),
                  Text(subtitle!, style: T.secondary, maxLines: 2),
                ],
              ],
            ),
          ),
          ...actions,
          TacticalIconButton(
            icon: Icons.close_rounded,
            onTap: onClose ?? () => Navigator.of(context).maybePop(),
            semanticLabel: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ],
      ),
    );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────

/// A 44pt icon target with no box around it. The old app drew a bordered
/// rounded rectangle behind every icon; the tap area is what matters, not
/// the outline.
class TacticalIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final double size;
  final String? semanticLabel;
  final bool active;

  const TacticalIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.size = 22,
    this.semanticLabel,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = onTap == null
        ? T.textOff
        : active
            ? T.accent
            : (color ?? T.textDim);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: Container(
          width: T.tap,
          height: T.tap,
          alignment: Alignment.center,
          decoration: active
              ? const BoxDecoration(color: T.accentFill, shape: BoxShape.circle)
              : null,
          child: Icon(icon, size: size, color: tint),
        ),
      ),
    );
  }
}

/// The primary action. One shape, used for New Plan, Buy, Save — anything a
/// screen wants a coach to press.
class TacticalButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool danger;
  final bool quiet;

  const TacticalButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.danger = false,
    this.quiet = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final Color fg;
    final Color bg;
    if (quiet) {
      fg = enabled ? T.text : T.textOff;
      bg = T.surfaceHi;
    } else if (danger) {
      fg = Colors.white;
      bg = T.danger;
    } else {
      fg = const Color(0xFF04231F);
      bg = enabled ? T.accent : T.surfaceHi;
    }
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: bg,
        borderRadius: T.brMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: T.brMd,
          child: Container(
            height: T.tap,
            padding: const EdgeInsets.symmetric(horizontal: T.s20),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: T.s8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: fg),
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

// ── Chips ─────────────────────────────────────────────────────────────────

/// A filter chip. Selected is a teal tint, not a solid block; unselected is a
/// surface step with no border, because a row of outlined pills is a row of
/// boxes competing with the content behind them.
class TacticalChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const TacticalChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? T.accentFill : T.surfaceHi,
        borderRadius: T.brSm,
        child: InkWell(
          onTap: onTap,
          borderRadius: T.brSm,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: T.s12),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: selected ? T.accent : T.textDim),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? T.accent : T.textDim,
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

// ── Cards, rows, sections ─────────────────────────────────────────────────

/// A content card. Surface contrast, no border by default — the old cards
/// each drew a 1px outline, so a list read as a stack of boxes.
class TacticalCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsets padding;

  const TacticalCard({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding = const EdgeInsets.all(T.panelPad),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? T.accentFill : T.surfaceHi,
      borderRadius: T.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: T.brMd,
        child: Container(
          padding: padding,
          decoration: selected
              ? BoxDecoration(
                  borderRadius: T.brMd,
                  border: Border.all(color: T.accent, width: 1.5))
              : null,
          child: child,
        ),
      ),
    );
  }
}

/// An all-caps section label above a group inside a sheet.
class TacticalSectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const TacticalSectionHeader({super.key, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: T.s12, top: T.s4),
        child: Row(
          children: [
            Expanded(child: Text(label.toUpperCase(), style: T.label)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// The search field, one shape everywhere.
class TacticalSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const TacticalSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: T.tap,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: T.body,
        cursorColor: T.accent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: T.textOff, fontSize: 15),
          prefixIcon: const Icon(Icons.search_rounded, color: T.textOff, size: 20),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          filled: true,
          fillColor: T.surfaceHi,
          border: const OutlineInputBorder(
              borderRadius: T.brSm, borderSide: BorderSide.none),
          enabledBorder: const OutlineInputBorder(
              borderRadius: T.brSm, borderSide: BorderSide.none),
          focusedBorder: const OutlineInputBorder(
              borderRadius: T.brSm,
              borderSide: BorderSide(color: T.accent, width: 1.5)),
        ),
      ),
    );
  }
}

/// Illustration, headline, one supporting line, one action. The three empty
/// states each had their own arrangement; this is the arrangement.
class TacticalEmptyState extends StatelessWidget {
  final String? image;
  final IconData? icon;
  final String title;
  final String? message;
  final Widget? action;

  const TacticalEmptyState({
    super.key,
    this.image,
    this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: T.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null)
              Opacity(opacity: 0.65, child: Image.asset(image!, width: 116))
            else if (icon != null)
              Icon(icon, size: 46, color: T.textOff),
            const SizedBox(height: T.s20),
            Text(title, textAlign: TextAlign.center, style: T.section),
            if (message != null) ...[
              const SizedBox(height: T.s8),
              Text(message!, textAlign: TextAlign.center, style: T.secondary),
            ],
            if (action != null) ...[
              const SizedBox(height: T.s24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ── Popover ───────────────────────────────────────────────────────────────

/// A compact anchored popover — the overflow menu's shape. Narrow, grouped,
/// and visibly coming from the control that opened it.
class TacticalPopover extends StatelessWidget {
  final List<Widget> children;
  final double width;

  const TacticalPopover({super.key, required this.children, this.width = 260});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: T.border),
        boxShadow: T.shadowFloat,
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

/// One row of a popover or a settings list.
class TacticalMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? tint;
  final Widget? trailing;

  const TacticalMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.tint,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = tint ?? T.text;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: T.s16),
        child: Row(
          children: [
            Icon(icon, size: 19, color: tint ?? T.textDim),
            const SizedBox(width: T.s12),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: c)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// A hairline between popover groups. One pixel, inset, low contrast.
class TacticalDivider extends StatelessWidget {
  const TacticalDivider({super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s4),
        color: T.border,
      );
}
