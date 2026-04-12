import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/drawing_stroke.dart';

void main() {
  group('DrawingStroke defaults', () {
    test('default values', () {
      final s = DrawingStroke(id: '1', points: []);
      expect(s.color, const Color(0xFFFFD600));
      expect(s.width, 3.0);
      expect(s.style, StrokeStyle.solid);
      expect(s.arrow, ArrowStyle.end);
    });
  });

  group('DrawingStroke.copyWith', () {
    test('replaces only specified fields', () {
      final s = DrawingStroke(
        id: 'a', points: [Offset(1, 2)],
        color: Color(0xFF123456), width: 5.0,
        style: StrokeStyle.dashed, arrow: ArrowStyle.none,
      );
      final copy = s.copyWith(width: 2.0);
      expect(copy.id, 'a');
      expect(copy.color, const Color(0xFF123456));
      expect(copy.width, 2.0);
      expect(copy.style, StrokeStyle.dashed);
      expect(copy.arrow, ArrowStyle.none);
      expect(copy.points, [const Offset(1, 2)]);
    });

    test('points list is a copy', () {
      final s = DrawingStroke(id: 'a', points: [Offset(1, 2)]);
      final copy = s.copyWith();
      (copy.points as List).add(const Offset(3, 4));
      expect(s.points.length, 1);
    });

    test('can replace all fields', () {
      final s = DrawingStroke(id: 'a', points: []);
      final copy = s.copyWith(
        id: 'b',
        points: [const Offset(5, 6)],
        color: const Color(0xFFABCDEF),
        width: 8.0,
        style: StrokeStyle.dashed,
        arrow: ArrowStyle.both,
      );
      expect(copy.id, 'b');
      expect(copy.points, [const Offset(5, 6)]);
      expect(copy.color, const Color(0xFFABCDEF));
      expect(copy.width, 8.0);
      expect(copy.style, StrokeStyle.dashed);
      expect(copy.arrow, ArrowStyle.both);
    });
  });
}
