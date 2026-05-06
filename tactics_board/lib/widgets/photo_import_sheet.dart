import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/photo_library_service.dart';

enum PhotoImportSource { gallery, camera }

/// Bottom sheet that walks the user through uploading face avatars:
///   1. Pick one or more photos from the gallery, or take a photo with the
///      camera (selectable via [source]).
///   2. Run face detection on each photo and crop every face into a square.
///   3. Show a preview grid; user can remove any unwanted face.
///   4. On confirm, every remaining crop is saved to the photo library.
class PhotoImportSheet extends StatefulWidget {
  final PhotoImportSource source;
  /// Photo group the new photos will belong to.
  final String groupId;
  const PhotoImportSheet({
    super.key,
    this.source = PhotoImportSource.gallery,
    required this.groupId,
  });

  /// Show a small action sheet asking the user to pick the source, then
  /// open [PhotoImportSheet] with the chosen mode.
  static Future<void> showWithSourcePicker(
    BuildContext context, {
    required String groupId,
  }) async {
    final source = await showModalBottomSheet<PhotoImportSource>(
      context: context,
      backgroundColor: const Color(0xFF14302A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Colors.white),
              title: Text('photo_take'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () => Navigator.of(ctx).pop(PhotoImportSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Colors.white),
              title: Text('photo_from_gallery'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () => Navigator.of(ctx).pop(PhotoImportSource.gallery),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text('cancel'.tr(),
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center),
              onTap: () => Navigator.of(ctx).pop(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14302A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PhotoImportSheet(source: source, groupId: groupId),
    );
  }

  @override
  State<PhotoImportSheet> createState() => _PhotoImportSheetState();
}

enum _Stage { picking, detecting, preview, saving, done }

class _PhotoImportSheetState extends State<PhotoImportSheet> {
  _Stage _stage = _Stage.picking;
  final List<Uint8List> _crops = [];
  String _statusText = '';
  int _droppedDuplicates = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final picker = ImagePicker();
    List<XFile> picked;
    try {
      if (widget.source == PhotoImportSource.camera) {
        final shot = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 100,
        );
        picked = shot == null ? <XFile>[] : [shot];
      } else {
        picked = await picker.pickMultiImage(imageQuality: 100);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    if (picked.isEmpty) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _stage = _Stage.detecting;
      _statusText = 'photo_detecting'.tr();
    });
    final all = <Uint8List>[];
    final sources = <int>[];
    for (int i = 0; i < picked.length; i++) {
      if (!mounted) return;
      setState(() {
        _statusText =
            'photo_detecting_progress'.tr(args: ['${i + 1}', '${picked.length}']);
      });
      final faces = await PhotoLibraryService.instance
          .detectAndCropFaces(picked[i].path);
      for (final f in faces) {
        all.add(f);
        sources.add(i);
      }
    }
    if (!mounted) return;
    // Cross-photo dedup: if the user picked multiple shots that include the
    // same person, keep only the first crop. Crops from the SAME photo are
    // never deduped against each other — they're guaranteed distinct people.
    final beforeCount = all.length;
    final deduped = await PhotoLibraryService.instance
        .dedupeFaceCrops(all, sourceIds: sources, groupId: widget.groupId);
    final dropped = beforeCount - deduped.length;
    if (!mounted) return;
    setState(() {
      _crops.addAll(deduped);
      _droppedDuplicates = dropped;
      _stage = _Stage.preview;
    });
  }

  Future<void> _confirm() async {
    setState(() => _stage = _Stage.saving);
    for (final bytes in _crops) {
      await PhotoLibraryService.instance
          .savePngBytes(bytes, groupId: widget.groupId);
    }
    if (!mounted) return;
    setState(() => _stage = _Stage.done);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: switch (_stage) {
          _Stage.picking => const _Loading(),
          _Stage.detecting => _Loading(label: _statusText),
          _Stage.saving => _Loading(label: 'photo_saving'.tr()),
          _Stage.done => const SizedBox.shrink(),
          _Stage.preview => _buildPreview(),
        },
      ),
    );
  }

  Widget _buildPreview() {
    if (_crops.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.face_retouching_off, color: Colors.white30, size: 48),
          const SizedBox(height: 12),
          Text(
            'photo_no_faces'.tr(),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text('cancel'.tr(), style: const TextStyle(color: Colors.white54)),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.face, color: Color(0xFF6EE7B7), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'photo_review_count'.tr(args: ['${_crops.length}']),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.close, color: Colors.white54),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'photo_review_hint'.tr(),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        if (_droppedDuplicates > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'photo_dedup_msg'.tr(args: ['$_droppedDuplicates']),
              style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),
        Flexible(
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: _crops.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, i) {
              final bytes = _crops[i];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipOval(
                    child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
                  ),
                  Positioned(
                    top: -4, right: -4,
                    child: GestureDetector(
                      onTap: () => setState(() => _crops.removeAt(i)),
                      child: Container(
                        width: 22, height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('cancel'.tr(),
                        style: const TextStyle(color: Colors.white70)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _confirm,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A7DFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'photo_confirm_save'.tr(args: ['${_crops.length}']),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  final String? label;
  const _Loading({this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF6EE7B7)),
          ),
          if (label != null && label!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(label!, style: const TextStyle(color: Colors.white70)),
          ],
        ],
      ),
    );
  }
}
