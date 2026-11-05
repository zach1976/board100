import 'dart:convert';
import 'dart:io' show zlib;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/volleyball_rotation.dart';
import 'package:tactics_board/services/pdf_export_service.dart';

/// The lineup sheet: one PDF page out of a rotation, in any language —
/// Helvetica has no Chinese, so the words it cannot set are drawn by
/// Flutter and placed as pictures.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  LineupSheetStrings words({bool latin = true}) => latin
      ? const LineupSheetStrings(
          heading: 'Lineup sheet',
          team: 'Home',
          rotation: 'Rotation 3',
          system: '5-1',
          phase: 'Serve',
          servingOrder: 'Serving order',
          libero: 'Libero',
          rules: 'Rule set',
          subs: 'Subs 12/set',
          net: 'Net',
        )
      : const LineupSheetStrings(
          heading: '阵容表',
          team: '主队',
          rotation: '第 3 轮',
          system: '5-1',
          phase: '发球',
          servingOrder: '发球顺序',
          libero: '自由人',
          rules: '规则',
          subs: '换人 12/局',
          net: '球网',
        );

  /// The file's objects with every Flate stream inflated, as text.
  String inflated(Uint8List bytes) {
    final raw = latin1.decode(bytes, allowInvalid: true);
    final out = StringBuffer();
    var at = 0;
    for (final m in RegExp(r'(?<!end)stream\r?\n').allMatches(raw)) {
      final end = raw.indexOf('endstream', m.end);
      if (end < 0) break;
      out.write(raw.substring(at, m.end));
      final body = bytes.sublist(m.end, end);
      try {
        out.write(latin1.decode(zlib.decode(body), allowInvalid: true));
      } catch (_) {
        out.write(raw.substring(m.end, end));
      }
      at = end;
    }
    out.write(raw.substring(at));
    return out.toString();
  }

  const setup = RotationSetup(
      rotation: 3, phase: RotationPhase.serve, rules: RotationRules.usav);

  test('is one PDF page', () async {
    final bytes = await PdfExportService.buildLineupSheet(setup,
        labels: const {'S': '7', 'L': 'Ana'},
        words: words(),
        title: 'Tigers');
    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
    final text = inflated(bytes);
    expect(RegExp(r'/Type\s*/Page[^s]').allMatches(text).length, 1);
    // The player labels and the rule set are set as text.
    for (final word in ['Tigers', 'Ana', 'USAV', 'Serving', 'Libero']) {
      expect(text, contains(word), reason: word);
    }
  });

  test('a language Helvetica cannot set still makes a page', () async {
    final bytes = await PdfExportService.buildLineupSheet(setup,
        labels: const {}, words: words(latin: false), title: '老虎队');
    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
    expect(inflated(bytes), contains('/Image'));
  });
}
