import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../state/tactics_state.dart';

class PdfExportService {
  static Future<Uint8List?> _captureBoard({double pixelRatio = 2.0}) async {
    final boundary =
        boardRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  /// Capture the current board and share it as a single-page PDF.
  /// Caller should reset zoom and wait for a frame before invoking.
  static Future<bool> exportCurrentFrame({String title = 'Tactics Board'}) async {
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
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'tactics_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    return true;
  }
}
