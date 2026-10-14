import 'dart:convert' show latin1;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/match_day.dart';
import '../models/volleyball_rotation.dart';
import '../state/tactics_state.dart';

/// The words on a lineup sheet, already in the coach's language. The
/// service takes them ready-made so it needs no localisation context.
class LineupSheetStrings {
  final String heading;
  final String team;
  final String rotation;
  final String system;
  final String phase;
  final String servingOrder;
  final String libero;
  final String rules;
  final String subs;
  final String net;
  const LineupSheetStrings({
    required this.heading,
    required this.team,
    required this.rotation,
    required this.system,
    required this.phase,
    required this.servingOrder,
    required this.libero,
    required this.rules,
    required this.subs,
    required this.net,
  });
}

/// The words on a match-day sheet, already in the coach's language.
class MatchSheetStrings {
  final String heading;
  final String playingTime;
  final String substitutions;
  final String noSubs;
  final String player;
  final String minutes;
  final String time;
  final String period;
  final String off;
  final String on;
  final String starter;
  const MatchSheetStrings({
    required this.heading,
    required this.playingTime,
    required this.substitutions,
    required this.noSubs,
    required this.player,
    required this.minutes,
    required this.time,
    required this.period,
    required this.off,
    required this.on,
    required this.starter,
  });
}

class PdfExportService {
  static const _roman = ['I', 'II', 'III', 'IV', 'V', 'VI'];

  /// A piece of text for the page. Helvetica — the pdf package's built-in
  /// font — stops at Latin-1 and throws on anything else, and the apps
  /// bundle no other font; so a word it cannot set is drawn by Flutter
  /// with the platform's own fonts and placed as a small picture.
  static Future<pw.Widget> _text(
    String text, {
    double size = 11,
    bool bold = false,
    PdfColor color = PdfColors.black,
  }) async {
    var latin = true;
    try {
      latin1.encode(text);
    } catch (_) {
      latin = false;
    }
    if (latin) {
      return pw.Text(text,
          style: pw.TextStyle(
              fontSize: size,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color));
    }
    const k = 4.0;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size * k,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: Color(color.toInt()),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rec = ui.PictureRecorder();
    tp.paint(Canvas(rec), Offset.zero);
    final img = await rec
        .endRecording()
        .toImage(tp.width.ceil().clamp(1, 1 << 14), tp.height.ceil().clamp(1, 1 << 14));
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return pw.SizedBox(width: tp.width / k, height: tp.height / k);
    return pw.Image(pw.MemoryImage(bytes.buffer.asUint8List()),
        width: tp.width / k, height: tp.height / k);
  }

  /// The paper lineup sheet, as one A4 page: the team and rotation, the
  /// six zones as a 2×3 grid (4 3 2 over 5 6 1, the net at the top) with
  /// the player in each, the serving order I–VI, the libero and the rule
  /// set. [labels] names each role's player on the board.
  static Future<Uint8List> buildLineupSheet(
    RotationSetup setup, {
    required Map<String, String> labels,
    required LineupSheetStrings words,
    String? title,
  }) async {
    final roles = setup.zoneRoles;
    String labelOf(String role) =>
        labels[role] ?? VolleyballRotation.displayLabel(role);
    final dateStr = DateTime.now().toIso8601String().split('T').first;

    final heading = await _text(words.heading, size: 18, bold: true);
    final titleW = title == null || title.trim().isEmpty
        ? null
        : await _text(title.trim(), size: 14, bold: true);
    final teamW = await _text(words.team, size: 11, color: PdfColors.grey700);
    final setupW = await _text(
        '${words.rotation}  ·  ${words.system}  ·  ${words.phase}',
        size: 11);
    final netW = await _text(words.net, size: 9, bold: true, color: PdfColors.grey700);
    final cells = <int, pw.Widget>{};
    for (final z in roles.keys) {
      final role = roles[z]!;
      final label = labelOf(role);
      // The role itself, small, where it adds something: "MB1" tells the
      // two middles apart, "S" under "S" says nothing.
      final sub = role;
      cells[z] = pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
        await _text(label, size: 22, bold: true),
        if (sub != label) ...[
          pw.SizedBox(height: 2),
          await _text(sub, size: 9, color: PdfColors.grey700),
        ],
      ]);
    }
    final orderHead = await _text(words.servingOrder, size: 12, bold: true);
    final orderRows = <pw.Widget>[];
    for (var z = 1; z <= 6; z++) {
      final role = setup.roleInZone(z);
      final serving = setup.phase == RotationPhase.serve && z == 1;
      orderRows.add(pw.Row(children: [
        pw.SizedBox(
            width: 28,
            child: await _text(_roman[z - 1], size: 11, bold: true)),
        pw.SizedBox(width: 56, child: await _text(labelOf(role), size: 11, bold: serving)),
        if (role != labelOf(role))
          await _text(role, size: 9, color: PdfColors.grey700),
        if (serving) pw.SizedBox(width: 6),
        if (serving)
          pw.Container(
              width: 6,
              height: 6,
              decoration: const pw.BoxDecoration(
                  color: PdfColors.amber700, shape: pw.BoxShape.circle)),
      ]));
      orderRows.add(pw.SizedBox(height: 4));
    }
    final replaced = setup.liberoReplaces;
    // Latin-1 throughout, so an English sheet stays real text: the
    // middle the libero is in for follows in brackets.
    final liberoW = await _text(
        '${words.libero}:  ${setup.libero ? labelOf(VolleyballRotation.liberoRole) : '-'}'
        '${replaced == null ? '' : '  (${labelOf(replaced)})'}',
        size: 11);
    final rulesW = await _text(
        '${words.rules}:  ${setup.rules.label}  ·  ${words.subs}',
        size: 11);
    final dateW = pw.Text(dateStr,
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600));

    pw.Widget cell(int z) => pw.Container(
          width: 110,
          height: 80,
          decoration: pw.BoxDecoration(
            color: roles[z] == VolleyballRotation.liberoRole
                ? PdfColor.fromInt(TacticsState.kLiberoColor.toARGB32())
                    .shade(0.25)
                : null,
            border: pw.Border.all(color: PdfColors.grey800, width: 0.8),
          ),
          child: pw.Stack(children: [
            pw.Positioned(
                left: 4,
                top: 3,
                child: pw.Text('$z',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600))),
            pw.Center(child: cells[z]),
          ]),
        );

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [heading, dateW],
            ),
            pw.SizedBox(height: 10),
            ?titleW,
            if (titleW != null) pw.SizedBox(height: 2),
            teamW,
            pw.SizedBox(height: 6),
            setupW,
            pw.SizedBox(height: 18),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 330,
                      padding: const pw.EdgeInsets.only(bottom: 3),
                      alignment: pw.Alignment.center,
                      decoration: const pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColors.grey800, width: 3))),
                      child: netW,
                    ),
                    pw.Row(children: [cell(4), cell(3), cell(2)]),
                    pw.Row(children: [cell(5), cell(6), cell(1)]),
                  ],
                ),
                pw.SizedBox(width: 24),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      orderHead,
                      pw.SizedBox(height: 8),
                      ...orderRows,
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            liberoW,
            pw.SizedBox(height: 6),
            rulesW,
          ],
        ),
      ),
    );
    return doc.save();
  }

  static String _mmss(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// The match-day sheet: every player's minutes, most first, with the
  /// starters marked, and the substitution log under it. Runs onto a
  /// second page for a long roster.
  static Future<Uint8List> buildMatchSheet(
    MatchDay match, {
    required MatchSheetStrings words,
  }) async {
    final dateStr = match.startedAt.toIso8601String().split('T').first;
    final times = match.playingTime(match.clock());
    final order = [...match.players]
      ..sort((a, b) => (times[b.id] ?? 0).compareTo(times[a.id] ?? 0));
    final starters = match.starters.toSet();

    final heading = await _text(words.heading, size: 18, bold: true);
    final titleW = match.name.trim().isEmpty
        ? null
        : await _text(match.name.trim(), size: 14, bold: true);
    final setupW = await _text(
        '${match.periods} × ${match.periodSeconds ~/ 60} min  ·  ${match.onPitch} v ${match.onPitch}',
        size: 11,
        color: PdfColors.grey700);
    final timeHead = await _text(words.playingTime, size: 12, bold: true);
    final playerCol = await _text(words.player, size: 9, color: PdfColors.grey700);
    final minutesCol = await _text(words.minutes, size: 9, color: PdfColors.grey700);
    final rows = <pw.Widget>[];
    for (final p in order) {
      final secs = times[p.id] ?? 0;
      rows.add(pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        decoration: const pw.BoxDecoration(
            border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
        child: pw.Row(children: [
          pw.Expanded(child: await _text(p.label, size: 11)),
          if (starters.contains(p.id))
            pw.Padding(
                padding: const pw.EdgeInsets.only(right: 12),
                child: await _text(words.starter,
                    size: 8, color: PdfColors.grey600)),
          pw.SizedBox(
              width: 56,
              child: pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(_mmss(secs),
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)))),
        ]),
      ));
    }
    final subsHead = await _text(words.substitutions, size: 12, bold: true);
    final subRows = <pw.Widget>[];
    if (match.subs.isEmpty) {
      subRows.add(await _text(words.noSubs, size: 10, color: PdfColors.grey600));
    } else {
      subRows.add(pw.Row(children: [
        pw.SizedBox(width: 48, child: await _text(words.time, size: 9, color: PdfColors.grey700)),
        pw.SizedBox(width: 40, child: await _text(words.period, size: 9, color: PdfColors.grey700)),
        pw.Expanded(child: await _text(words.off, size: 9, color: PdfColors.grey700)),
        pw.Expanded(child: await _text(words.on, size: 9, color: PdfColors.grey700)),
      ]));
      subRows.add(pw.SizedBox(height: 3));
      for (final sub in match.subs) {
        subRows.add(pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(children: [
            pw.SizedBox(
                width: 48,
                child: pw.Text(_mmss(sub.clock),
                    style: const pw.TextStyle(fontSize: 10))),
            pw.SizedBox(
                width: 40,
                child: pw.Text('${sub.period}',
                    style: const pw.TextStyle(fontSize: 10))),
            pw.Expanded(
                child: await _text(match.player(sub.outId)?.label ?? sub.outId,
                    size: 10)),
            pw.Expanded(
                child: await _text(match.player(sub.inId)?.label ?? sub.inId,
                    size: 10, bold: true)),
          ]),
        ));
      }
    }
    final dateW = pw.Text(dateStr,
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600));

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [heading, dateW],
          ),
          pw.SizedBox(height: 10),
          ?titleW,
          if (titleW != null) pw.SizedBox(height: 2),
          setupW,
          pw.SizedBox(height: 18),
          timeHead,
          pw.SizedBox(height: 6),
          pw.Row(children: [
            pw.Expanded(child: playerCol),
            pw.SizedBox(
                width: 56,
                child: pw.Align(
                    alignment: pw.Alignment.centerRight, child: minutesCol)),
          ]),
          pw.SizedBox(height: 2),
          ...rows,
          pw.SizedBox(height: 18),
          subsHead,
          pw.SizedBox(height: 6),
          ...subRows,
        ],
      ),
    );
    return doc.save();
  }

  /// Share the match-day sheet; see [buildMatchSheet].
  static Future<bool> exportMatchSheet(
    MatchDay match, {
    required MatchSheetStrings words,
    String? filename,
  }) async {
    final bytes = await buildMatchSheet(match, words: words);
    return Printing.sharePdf(
      bytes: bytes,
      filename:
          filename ?? 'match_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Share the lineup sheet for [setup]; see [buildLineupSheet].
  static Future<bool> exportLineupSheet(
    RotationSetup setup, {
    required Map<String, String> labels,
    required LineupSheetStrings words,
    String? title,
    String? filename,
  }) async {
    final bytes = await buildLineupSheet(setup,
        labels: labels, words: words, title: title);
    return Printing.sharePdf(
      bytes: bytes,
      filename:
          filename ?? 'lineup_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<Uint8List?> _captureBoard({double pixelRatio = 2.0}) async {
    final boundary =
        boardRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  /// Share a document: one PDF page per board page, in order.
  ///
  /// A routine that can be drawn across several pages but only sent as one
  /// is a routine you cannot hand to anybody, so this takes the captures the
  /// caller collected by walking the pages — the walking has to happen up
  /// there, where there is a state to drive and frames to wait for.
  static Future<bool> exportFrames(
    List<Uint8List> pngs, {
    String title = 'Tactics Board',
    String? filename,
  }) async {
    if (pngs.isEmpty) return false;
    final doc = pw.Document();
    final dateStr = DateTime.now().toIso8601String().split('T').first;
    for (var i = 0; i < pngs.length; i++) {
      final img = pw.MemoryImage(pngs[i]);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                      pngs.length > 1 ? '$title  ${i + 1}/${pngs.length}' : title,
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text(dateStr,
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Expanded(child: pw.Image(img, fit: pw.BoxFit.contain)),
            ],
          ),
        ),
      );
    }
    final bytes = await doc.save();
    return Printing.sharePdf(
      bytes: bytes,
      filename:
          filename ?? 'tactics_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// One capture of the live board, for a caller walking the pages itself.
  static Future<Uint8List?> captureBoard({double pixelRatio = 2.0}) =>
      _captureBoard(pixelRatio: pixelRatio);

  /// Capture the current board and share it as a single-page PDF.
  /// Caller should reset zoom and wait for a frame before invoking.
  /// Returns true only when the document was actually shared (false on capture
  /// failure or when the user cancels the share sheet).
  static Future<bool> exportCurrentFrame({String title = 'Tactics Board', String? filename}) async {
    final png = await _captureBoard();
    if (png == null) return false;
    final doc = pw.Document();
    final img = pw.MemoryImage(png);
    final dateStr = DateTime.now().toIso8601String().split('T').first;
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(title,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text(dateStr,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Expanded(child: pw.Image(img, fit: pw.BoxFit.contain)),
          ],
        ),
      ),
    );
    final bytes = await doc.save();
    return Printing.sharePdf(
      bytes: bytes,
      filename: filename ?? 'tactics_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
