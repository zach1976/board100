import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../services/photo_library_service.dart';

/// Lets the user re-frame an existing avatar — pan with one finger, pinch
/// with two. On save, captures the circular viewport via RepaintBoundary
/// and overwrites the source PNG so every place that references the photo
/// (the strip, the board markers, the flight animation) shows the new crop.
class PhotoCropEditor extends StatefulWidget {
  final String photoId;
  const PhotoCropEditor({super.key, required this.photoId});

  static Future<void> show(BuildContext context, {required String photoId}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => PhotoCropEditor(photoId: photoId),
    );
  }

  @override
  State<PhotoCropEditor> createState() => _PhotoCropEditorState();
}

class _PhotoCropEditorState extends State<PhotoCropEditor> {
  final GlobalKey _boundaryKey = GlobalKey();
  String? _path;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  // Captured at gesture start so concurrent pan + pinch compose cleanly.
  Offset _startOffset = Offset.zero;
  double _startScale = 1.0;
  Offset _startFocalPoint = Offset.zero;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final list = await PhotoLibraryService.instance.list();
    final photo = list.cast<dynamic>()
        .firstWhere((p) => p?.id == widget.photoId, orElse: () => null);
    if (photo == null) return;
    final p = await PhotoLibraryService.instance.resolvePath(photo);
    if (mounted) setState(() => _path = p);
  }

  Future<void> _save() async {
    // Don't capture a frame while the source image is still loading — the
    // RepaintBoundary would snapshot the spinner and overwrite the avatar
    // with a blank placeholder.
    if (_saving || _path == null) return;
    setState(() => _saving = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      // pixelRatio 4× the on-screen 192-pt viewport ≈ 768 px PNG. Plenty
      // for retina avatar markers and the strip thumbnails.
      final image = await boundary.toImage(pixelRatio: 4.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      await PhotoLibraryService.instance
          .overwritePhotoBytes(widget.photoId, bytes.buffer.asUint8List());
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final viewport = (media.size.width - 64).clamp(180.0, 320.0);

    return Dialog(
      backgroundColor: const Color(0xFF20424C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.crop, color: Color(0xFF00C2B2)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'photo_crop_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'photo_crop_hint'.tr(),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Circular viewport — what gets rendered into the new PNG.
            RepaintBoundary(
              key: _boundaryKey,
              child: ClipOval(
                child: Container(
                  width: viewport, height: viewport,
                  color: Colors.black,
                  child: _path == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00C2B2),
                            strokeWidth: 3,
                          ),
                        )
                      : GestureDetector(
                          onScaleStart: (d) {
                            _startOffset = _offset;
                            _startScale = _scale;
                            _startFocalPoint = d.focalPoint;
                          },
                          onScaleUpdate: (d) {
                            setState(() {
                              _scale = (_startScale * d.scale).clamp(0.5, 4.0);
                              // Total displacement from gesture start — this
                              // makes one-finger panning track the finger
                              // properly. focalPointDelta is per-event only.
                              _offset = _startOffset + (d.focalPoint - _startFocalPoint);
                            });
                          },
                          child: Transform(
                            transform: Matrix4.identity()
                              ..translate(_offset.dx, _offset.dy)
                              ..scale(_scale),
                            alignment: Alignment.center,
                            child: Image.file(
                              File(_path!),
                              fit: BoxFit.cover,
                              width: viewport,
                              height: viewport,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _offset = Offset.zero;
                      _scale = 1.0;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'photo_crop_reset'.tr(),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: (_saving || _path == null) ? null : _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C2B2).withValues(
                          alpha: (_saving || _path == null) ? 0.4 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: _saving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.black87,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'save'.tr(),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
