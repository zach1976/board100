import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import '../models/player_icon.dart';
import '../services/ad_service.dart';
import '../services/photo_library_service.dart';
import 'marker_shape_clipper.dart';

/// Pick a single photo, choose the marker shape, then crop it (pan +
/// pinch) inside that shape. No face detection — element photos can be
/// any object the user wants on the board, in circle / square /
/// triangle / diamond outlines.
class ElementImportFlow {
  static Future<void> show(BuildContext context) async {
    final picker = ImagePicker();
    XFile? picked;
    AdService.instance.suppressNextAppOpen(); // photo picker backgrounds the app
    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
    } catch (_) {
      return;
    }
    if (picked == null) return;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _ElementCropDialog(sourcePath: picked!.path),
    );
  }
}

class _ElementCropDialog extends StatefulWidget {
  final String sourcePath;
  const _ElementCropDialog({required this.sourcePath});

  @override
  State<_ElementCropDialog> createState() => _ElementCropDialogState();
}

class _ElementCropDialogState extends State<_ElementCropDialog> {
  final GlobalKey _boundaryKey = GlobalKey();
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset _startOffset = Offset.zero;
  double _startScale = 1.0;
  Offset _startFocalPoint = Offset.zero;
  bool _saving = false;
  MarkerShape _shape = MarkerShape.circle;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 4.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      await PhotoLibraryService.instance.saveElementBytes(
        bytes.buffer.asUint8List(),
        markerShapeIndex: _shape.index,
      );
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
                const Icon(Icons.add_photo_alternate_outlined,
                    color: Color(0xFF00C2B2)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'element_crop_title'.tr(),
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
            const SizedBox(height: 12),
            // Shape picker — chips for circle / square / triangle / diamond.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final s in kPhotoMarkerShapes)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _ShapeChip(
                      shape: s,
                      selected: s == _shape,
                      onTap: () => setState(() => _shape = s),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            RepaintBoundary(
              key: _boundaryKey,
              child: ClipPath(
                clipper: MarkerShapeClipper(_shape),
                child: Container(
                  width: viewport, height: viewport,
                  color: Colors.black,
                  child: GestureDetector(
                    onScaleStart: (d) {
                      _startOffset = _offset;
                      _startScale = _scale;
                      _startFocalPoint = d.focalPoint;
                    },
                    onScaleUpdate: (d) {
                      setState(() {
                        _scale = (_startScale * d.scale).clamp(0.5, 4.0);
                        _offset = _startOffset + (d.focalPoint - _startFocalPoint);
                      });
                    },
                    child: Transform(
                      transform: Matrix4.identity()
                        ..translate(_offset.dx, _offset.dy)
                        ..scale(_scale),
                      alignment: Alignment.center,
                      child: Image.file(
                        File(widget.sourcePath),
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
                    onTap: _saving ? null : _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C2B2).withValues(
                          alpha: _saving ? 0.4 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: _saving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.black87, strokeWidth: 2),
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

class _ShapeChip extends StatelessWidget {
  final MarkerShape shape;
  final bool selected;
  final VoidCallback onTap;
  const _ShapeChip({
    required this.shape,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 44, height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? const Color(0xFF00C2B2).withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: selected ? const Color(0xFF00C2B2) : Colors.white24,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: 22, height: 22,
          child: ClipPath(
            clipper: MarkerShapeClipper(shape),
            child: Container(color: selected
                ? const Color(0xFF00C2B2)
                : Colors.white60),
          ),
        ),
      ),
    );
  }
}
