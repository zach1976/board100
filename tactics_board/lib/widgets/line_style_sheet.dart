import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/drawing_stroke.dart';
import '../painters/drawing_painter.dart';
import '../state/tactics_state.dart';
import '../ui_constants.dart';

const _kStrokeWidths = [2.0, 3.0, 5.0, 7.0];

/// Terminators, in the order they appear across each row of the grid.
const _kArrows = [
  ArrowStyle.none,
  ArrowStyle.end,
  ArrowStyle.both,
  ArrowStyle.cross,
  ArrowStyle.tbar,
];

/// A shape gets one grid row per dash pattern.
const _kSections = [
  (LineShape.freehand, 'line_shape_freehand'),
  (LineShape.straight, 'line_shape_straight'),
  (LineShape.wavy, 'line_shape_wavy'),
];

/// Bottom sheet letting the user pick the body, dash pattern and terminator of
/// the next stroke, plus its colour and width. Selections apply to strokes
/// drawn afterwards; they do not retro-edit the board.
void showLineStyleSheet(BuildContext context, TacticsState state) {
  showModalBottomSheet(
    context: context,
    backgroundColor: kSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _LineStyleSheet(state: state),
  );
}

class _LineStyleSheet extends StatefulWidget {
  final TacticsState state;
  const _LineStyleSheet({required this.state});

  @override
  State<_LineStyleSheet> createState() => _LineStyleSheetState();
}

class _LineStyleSheetState extends State<_LineStyleSheet> {
  late LineShape _shape = widget.state.lineShape;
  late StrokeStyle _dash = widget.state.strokeStyle;
  late ArrowStyle _arrow = widget.state.arrowStyle;
  late Color _color = widget.state.strokeColor;
  late double _width = widget.state.strokeWidth;

  /// Push the current selection to the board immediately. Called on every tap
  /// so a choice takes effect without a separate "confirm" press — a selected
  /// style that silently did nothing until confirmed was a trap.
  void _applyLive() {
    widget.state
      ..setLineShape(_shape)
      ..setStrokeStyle(_dash)
      ..setArrowStyle(_arrow)
      ..setStrokeColor(_color)
      ..setStrokeWidth(_width);
  }

  void _apply() {
    _applyLive();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Text('line_style_title'.tr(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (shape, labelKey) in _kSections) ...[
                      _sectionLabel(labelKey.tr()),
                      for (final dash in StrokeStyle.values)
                        _grid(shape, dash),
                      const SizedBox(height: 14),
                    ],
                    _sectionLabel('line_color'.tr()),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        for (final c in kStrokeColors)
                          _Swatch(
                            selected: _color == c,
                            onTap: () {
                              setState(() => _color = c);
                              _applyLive();
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                  color: c, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel('line_width'.tr()),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        for (final w in _kStrokeWidths)
                          _Swatch(
                            selected: _width == w,
                            onTap: () {
                              setState(() => _width = w);
                              _applyLive();
                            },
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Center(
                                child: Container(
                                  width: w * 2.4,
                                  height: w * 2.4,
                                  decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00C2B2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _apply,
                  child: Text('confirm'.tr(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );

  Widget _grid(LineShape shape, StrokeStyle dash) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, box) {
          const gap = 8.0;
          final cellW = (box.maxWidth - gap * (_kArrows.length - 1)) /
              _kArrows.length;
          return Row(
            children: [
              for (int i = 0; i < _kArrows.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                _StyleCell(
                  width: cellW,
                  shape: shape,
                  dash: dash,
                  arrow: _kArrows[i],
                  color: _color,
                  selected: _shape == shape &&
                      _dash == dash &&
                      _arrow == _kArrows[i],
                  onTap: () {
                    setState(() {
                      _shape = shape;
                      _dash = dash;
                      _arrow = _kArrows[i];
                    });
                    _applyLive();
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  const _Swatch(
      {required this.selected, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFFFD600) : Colors.transparent,
            width: 2,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _StyleCell extends StatelessWidget {
  final double width;
  final LineShape shape;
  final StrokeStyle dash;
  final ArrowStyle arrow;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StyleCell({
    required this.width,
    required this.shape,
    required this.dash,
    required this.arrow,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFFFD600) : Colors.transparent,
            width: 2,
          ),
        ),
        child: CustomPaint(
          painter: LineStylePreviewPainter(shape: shape, dash: dash, arrow: arrow, color: color),
          size: Size(width, 44),
        ),
      ),
    );
  }
}

/// never drift from what the canvas draws.
class LineStylePreviewPainter extends CustomPainter {
  final LineShape shape;
  final StrokeStyle dash;
  final ArrowStyle arrow;
  final Color color;

  const LineStylePreviewPainter(
      {required this.shape,
      required this.dash,
      required this.arrow,
      required this.color});

  /// Fixed preview width — the cell must stay legible regardless of the width
  /// the user picked for real strokes.
  static const _previewWidth = 2.4;

  @override
  void paint(Canvas canvas, Size size) {
    final padX = size.width * 0.16;
    final midY = size.height / 2;
    final span = size.width - padX * 2;
    if (span <= 0) return;

    // A gentle S for freehand so the curve reads; a level line for straight and
    // wavy, whose character comes from the painter itself.
    final points = <Offset>[];
    const steps = 24;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final dy = shape == LineShape.freehand
          ? sin(t * 2 * pi) * size.height * 0.16
          : 0.0;
      points.add(Offset(padX + span * t, midY + dy));
    }

    DrawingPainter(
      strokes: [
        DrawingStroke(
          id: 'preview',
          points: points,
          color: color,
          width: _previewWidth,
          style: dash,
          arrow: arrow,
          shape: shape,
        ),
      ],
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant LineStylePreviewPainter old) =>
      old.shape != shape ||
      old.dash != dash ||
      old.arrow != arrow ||
      old.color != color;
}
