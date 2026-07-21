import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../state/tactics_state.dart';

/// Renders the board's move animation to an MP4 and shares it.
///
/// It drives the animation frame-by-frame off the main ticker: for each
/// precomputed frame it pushes the interpolated positions into the state,
/// lets the board repaint, captures the [boardRepaintKey] boundary as raw
/// RGBA, and feeds that to the hardware H.264 encoder.
class VideoExportService {
  static const int fps = 30;

  /// Returns true when a video was produced and the share sheet was shown.
  /// [onProgress] reports 0..1. Must be called while the board is on screen.
  static Future<bool> exportAndShare(
    TacticsState state, {
    void Function(double progress)? onProgress,
    String? filename,
  }) async {
    final path = await renderToFile(state, onProgress: onProgress, filename: filename);
    if (path == null) return false;
    final result =
        await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
    return result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.dismissed;
  }

  /// Render the move animation to an MP4 and return its file path (null on
  /// failure / nothing to animate). Must run while the board is on screen.
  static Future<String?> renderToFile(
    TacticsState state, {
    void Function(double progress)? onProgress,
    String? filename,
  }) async {
    final frames = state.computeAnimationFrames(fps: fps);
    if (frames.isEmpty) return null;

    final boundary =
        boardRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    // Probe the first frame to fix the (even) output dimensions.
    state.updateAnimatedPositions(frames.first);
    await _settle();
    final probe = await _capture(boundary);
    if (probe == null) {
      state.updateAnimatedPositions({});
      return null;
    }
    final w = probe.width - (probe.width % 2); // H.264 needs even dimensions
    final h = probe.height - (probe.height % 2);

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/${filename ?? 'tactics_${DateTime.now().millisecondsSinceEpoch}'}.mp4';
    File(path).existsSync() ? File(path).deleteSync() : null;

    await FlutterQuickVideoEncoder.setup(
      width: w,
      height: h,
      fps: fps,
      videoBitrate: (w * h * fps * 0.15).round().clamp(2000000, 16000000),
      profileLevel: ProfileLevel.high40,
      audioChannels: 0,
      audioBitrate: 0,
      sampleRate: 0,
      filepath: path,
    );

    try {
      for (int i = 0; i < frames.length; i++) {
        state.updateAnimatedPositions(frames[i]);
        await _settle();
        final cap = await _capture(boundary);
        if (cap == null) continue;
        await FlutterQuickVideoEncoder.appendVideoFrame(
            _cropToEven(cap.rgba, cap.width, cap.height, w, h));
        onProgress?.call((i + 1) / frames.length);
      }
      await FlutterQuickVideoEncoder.finish();
    } finally {
      state.updateAnimatedPositions({});
    }
    return path;
  }

  /// Wait for the board to repaint with the newly-pushed positions. The short
  /// timeout keeps the export from stalling if the engine isn't producing
  /// frames (e.g. the window is briefly not foregrounded).
  static Future<void> _settle() async {
    WidgetsBinding.instance.scheduleFrame();
    await SchedulerBinding.instance.endOfFrame
        .timeout(const Duration(milliseconds: 400), onTimeout: () {});
  }

  static Future<({Uint8List rgba, int width, int height})?> _capture(
      RenderRepaintBoundary boundary) async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final wh = (image.width, image.height);
    image.dispose();
    if (data == null) return null;
    return (rgba: data.buffer.asUint8List(), width: wh.$1, height: wh.$2);
  }

  /// Crop RGBA [src] of size [w]x[h] down to [ew]x[eh] (top-left aligned).
  static Uint8List _cropToEven(Uint8List src, int w, int h, int ew, int eh) {
    if (ew == w && eh == h) return src;
    final out = Uint8List(ew * eh * 4);
    for (int y = 0; y < eh; y++) {
      final srcStart = y * w * 4;
      final dstStart = y * ew * 4;
      out.setRange(dstStart, dstStart + ew * 4, src, srcStart);
    }
    return out;
  }
}
