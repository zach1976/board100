import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/player_photo.dart';

/// Manages the local library of user-uploaded face photos used as player
/// avatars on the board. Library is local-only (not cloud-synced).
///
/// Photos are organised into named [PhotoGroup]s (one per team's roster),
/// supporting workflows where the same install is reused across many teams.
///
/// Storage layout (inside the app documents directory):
///   photos/             — directory holding individual face PNGs
///   photos/index.json   — JSON list of [PlayerPhoto] entries
///   photos/groups.json  — JSON list of [PhotoGroup] entries
class PhotoLibraryService extends ChangeNotifier {
  PhotoLibraryService._();
  static final PhotoLibraryService instance = PhotoLibraryService._();

  static const MethodChannel _faceChannel =
      MethodChannel('com.zach.tacticsboard/faceDetection');
  static const String _defaultGroupName = '我的队伍';

  bool _initialized = false;
  List<PlayerPhoto> _photos = [];
  List<PhotoGroup> _groups = [];
  int _idCounter = 0;

  List<PlayerPhoto> get photos => List.unmodifiable(_photos);
  List<PhotoGroup> get groups => List.unmodifiable(_groups);

  Future<void> _ensureInit() async {
    if (_initialized) return;
    final dir = await _photosDir();
    if (!dir.existsSync()) dir.createSync(recursive: true);

    // Load groups first (photos may reference them).
    final groupsFile = await _groupsFile();
    if (groupsFile.existsSync()) {
      try {
        final raw = jsonDecode(await groupsFile.readAsString()) as List;
        _groups = raw
            .map((e) => PhotoGroup.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _groups = [];
      }
    }

    final index = await _indexFile();
    if (index.existsSync()) {
      try {
        final raw = jsonDecode(await index.readAsString()) as List;
        _photos = raw
            .map((e) => PlayerPhoto.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _photos = [];
      }
    }

    // Migration: if there are photos but no groups (e.g., user upgraded from
    // the home/away version), create a default group and assign every
    // orphaned photo to it.
    if (_groups.isEmpty && _photos.isNotEmpty) {
      final def = PhotoGroup(
        id: 'g_${DateTime.now().microsecondsSinceEpoch}',
        name: _defaultGroupName,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      _groups.add(def);
      _photos = _photos
          .map((p) => p.groupId == null ? p.copyWithGroup(def.id) : p)
          .toList();
      await _persistGroups();
      await _persistIndex();
    } else if (_groups.isEmpty) {
      // Fresh install — seed the default group so the strip has somewhere
      // to put new uploads.
      final def = PhotoGroup(
        id: 'g_${DateTime.now().microsecondsSinceEpoch}',
        name: _defaultGroupName,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      _groups.add(def);
      await _persistGroups();
    }

    _initialized = true;
  }

  Future<Directory> _photosDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'photos'));
  }

  Future<File> _indexFile() async {
    final dir = await _photosDir();
    return File(p.join(dir.path, 'index.json'));
  }

  Future<File> _groupsFile() async {
    final dir = await _photosDir();
    return File(p.join(dir.path, 'groups.json'));
  }

  Future<String> resolvePath(PlayerPhoto photo) async {
    final dir = await _photosDir();
    return p.join(dir.path, photo.filename);
  }

  /// All FACE photos, newest first. Element photos live in [listElements]
  /// and never appear in the team / strip / dedup flows.
  Future<List<PlayerPhoto>> list() async {
    await _ensureInit();
    final sorted = _photos
        .where((p) => p.kind == PlayerPhotoKind.face)
        .toList()
      ..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    return sorted;
  }

  /// 3-day rolling window for the elements-row usage sort.
  static const int _recentWindowMs = 3 * 24 * 60 * 60 * 1000;

  /// User-defined custom marker photos (kind == element), sorted by usage:
  /// most-used in the last 3 days first; ties broken by createdAtMs ascending
  /// so newly-added (zero-use) elements land at the END of the row, and
  /// older never-used ones come before them.
  Future<List<PlayerPhoto>> listElements() async {
    await _ensureInit();
    final cutoff = DateTime.now().millisecondsSinceEpoch - _recentWindowMs;
    int recent(PlayerPhoto p) =>
        p.recentUseAtMs.where((t) => t >= cutoff).length;
    final list = _photos
        .where((p) => p.kind == PlayerPhotoKind.element)
        .toList();
    list.sort((a, b) {
      final cmp = recent(b).compareTo(recent(a));
      if (cmp != 0) return cmp;
      return a.createdAtMs.compareTo(b.createdAtMs);
    });
    return list;
  }

  /// Records a usage of a custom-element photo: appends "now" to its
  /// recent-use timestamps and prunes anything outside the 3-day window.
  /// Persists + notifies so the elements row re-sorts the next time it
  /// rebuilds.
  Future<void> recordElementUse(String id) async {
    await _ensureInit();
    final idx = _photos.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    final old = _photos[idx];
    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - _recentWindowMs;
    final next = old.recentUseAtMs.where((t) => t >= cutoff).toList()
      ..add(now);
    _photos[idx] = PlayerPhoto(
      id: old.id,
      filename: old.filename,
      createdAtMs: old.createdAtMs,
      groupId: old.groupId,
      kind: old.kind,
      markerShapeIndex: old.markerShapeIndex,
      recentUseAtMs: next,
    );
    await _persistIndex();
    notifyListeners();
  }

  /// All groups, oldest first (so user-created order is stable).
  Future<List<PhotoGroup>> listGroups() async {
    await _ensureInit();
    final sorted = [..._groups]
      ..sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
    return sorted;
  }

  Future<PhotoGroup> createGroup(String name) async {
    await _ensureInit();
    final group = PhotoGroup(
      id: 'g_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}',
      name: name.trim().isEmpty ? _defaultGroupName : name.trim(),
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    _groups.add(group);
    await _persistGroups();
    notifyListeners();
    return group;
  }

  Future<void> renameGroup(String id, String newName) async {
    await _ensureInit();
    final idx = _groups.indexWhere((g) => g.id == id);
    if (idx < 0) return;
    _groups[idx] = _groups[idx].copyWithName(newName.trim());
    await _persistGroups();
    notifyListeners();
  }

  /// Deletes the group AND every photo inside it.
  Future<void> deleteGroup(String id) async {
    await _ensureInit();
    // Remove member photo files first.
    final dir = await _photosDir();
    final members = _photos.where((p) => p.groupId == id).toList();
    for (final m in members) {
      final f = File(p.join(dir.path, m.filename));
      if (f.existsSync()) {
        try { f.deleteSync(); } catch (_) {}
      }
    }
    _photos.removeWhere((p) => p.groupId == id);
    _groups.removeWhere((g) => g.id == id);
    await _persistGroups();
    await _persistIndex();
    notifyListeners();
  }

  /// Save a custom-element image (no group, kind=element). The shape is
  /// stored alongside so the rendered tile / marker can clip the photo
  /// to the user's chosen outline.
  Future<PlayerPhoto> saveElementBytes(
    Uint8List bytes, {
    int? markerShapeIndex,
  }) async {
    await _ensureInit();
    final id = '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';
    final filename = '$id.png';
    final dir = await _photosDir();
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    final photo = PlayerPhoto(
      id: id,
      filename: filename,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      kind: PlayerPhotoKind.element,
      markerShapeIndex: markerShapeIndex,
    );
    _photos.add(photo);
    await _persistIndex();
    notifyListeners();
    return photo;
  }

  Future<PlayerPhoto> savePngBytes(
    Uint8List bytes, {
    required String groupId,
  }) async {
    await _ensureInit();
    // microsecondsSinceEpoch alone is not collision-proof — saving N face
    // crops in a tight loop can hit the same microsecond on iOS, which
    // previously caused later saves to overwrite earlier files and produce
    // duplicate ids in the index. Tack on a per-instance counter to guarantee
    // uniqueness within a session.
    final id = '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';
    final filename = '$id.png';
    final dir = await _photosDir();
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    final photo = PlayerPhoto(
      id: id,
      filename: filename,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      groupId: groupId,
    );
    _photos.add(photo);
    await _persistIndex();
    notifyListeners();
    return photo;
  }

  /// Run the native dedupe pass on a list of cropped face PNG bytes.
  /// New crops are compared against:
  ///   • each other — `sourceIds[i]` (the index of the original picked
  ///     photo crop `i` came from) ensures crops from the SAME photo
  ///     are never deduped against each other.
  ///   • when [groupId] is set, every photo already saved in that group —
  ///     so re-importing a person who already exists in this team is
  ///     dropped automatically.
  /// Returns the kept new crops; existing photos are never touched.
  Future<List<Uint8List>> dedupeFaceCrops(
    List<Uint8List> crops, {
    required List<int> sourceIds,
    String? groupId,
  }) async {
    if (!Platform.isIOS || crops.isEmpty) return crops;
    await _ensureInit();
    final dir = await _photosDir();
    final tmpDir = Directory(p.join(dir.path, '_dedup_tmp'));
    if (!tmpDir.existsSync()) tmpDir.createSync(recursive: true);

    // Face-landmark dedup is reliable enough now to also compare new crops
    // against existing group members, so re-importing a person already in
    // this team gets caught.
    final allPaths = <String>[];
    final allSourceIds = <int>[];
    final existing = groupId == null
        ? const <PlayerPhoto>[]
        : _photos.where((p) => p.groupId == groupId).toList();
    for (int i = 0; i < existing.length; i++) {
      allPaths.add(p.join(dir.path, existing[i].filename));
      allSourceIds.add(-(i + 1)); // unique negative — never matches a new sourceId
    }
    final firstNewIdx = allPaths.length;

    final tempFiles = <File>[];
    for (int i = 0; i < crops.length; i++) {
      final f = File(p.join(tmpDir.path, 'c_$i.png'));
      await f.writeAsBytes(crops[i], flush: true);
      tempFiles.add(f);
      allPaths.add(f.path);
      allSourceIds.add(sourceIds[i]);
    }

    try {
      if (allPaths.length < 2) return crops;
      final keepRaw = await _faceChannel.invokeMethod<List<dynamic>>(
        'dedupeFacePaths',
        {
          'paths': allPaths,
          'sourceIds': allSourceIds,
          // Average landmark distance in normalised face coords. Same person
          // typically < 0.025; different people > 0.04 in our sandbox runs.
          'threshold': 0.035,
        },
      );
      if (keepRaw == null || keepRaw.length != allPaths.length) return crops;
      final out = <Uint8List>[];
      for (int i = 0; i < crops.length; i++) {
        if (keepRaw[firstNewIdx + i] == true) out.add(crops[i]);
      }
      return out;
    } on PlatformException {
      return crops;
    } on MissingPluginException {
      return crops;
    } finally {
      for (final f in tempFiles) {
        try { f.deleteSync(); } catch (_) {}
      }
    }
  }

  /// Move a photo to another group.
  Future<void> setGroup(String photoId, String groupId) async {
    await _ensureInit();
    final idx = _photos.indexWhere((p) => p.id == photoId);
    if (idx < 0) return;
    _photos[idx] = _photos[idx].copyWithGroup(groupId);
    await _persistIndex();
    notifyListeners();
  }

  /// Overwrite an existing photo's bytes (used by the crop editor). Rather
  /// than reusing the same filename — which Flutter's FileImage cache holds
  /// onto by path — we write to a fresh filename and rewrite the index to
  /// point at it. Every widget that subsequently re-resolves the photo
  /// gets a different path → fresh decode. The old file is deleted.
  Future<bool> overwritePhotoBytes(String id, Uint8List bytes) async {
    await _ensureInit();
    final idx = _photos.indexWhere((p) => p.id == id);
    if (idx < 0) return false;
    final old = _photos[idx];
    final dir = await _photosDir();
    // Use a wall-clock micro-time so each rewrite gets a globally unique
    // filename even after relaunch — `_idCounter` resets per session and
    // could otherwise collide with an existing `__vN` suffix on disk.
    final newFilename =
        '${id}__v${DateTime.now().microsecondsSinceEpoch}_${++_idCounter}.png';
    final newFile = File(p.join(dir.path, newFilename));
    await newFile.writeAsBytes(bytes, flush: true);
    // Best-effort delete of the previous file.
    if (old.filename != newFilename) {
      final oldFile = File(p.join(dir.path, old.filename));
      if (oldFile.existsSync()) {
        try { oldFile.deleteSync(); } catch (_) {}
      }
    }
    _photos[idx] = PlayerPhoto(
      id: old.id,
      filename: newFilename,
      createdAtMs: old.createdAtMs,
      groupId: old.groupId,
    );
    await _persistIndex();
    notifyListeners();
    return true;
  }

  Future<void> delete(String id) async {
    await _ensureInit();
    final idx = _photos.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    final photo = _photos[idx];
    final dir = await _photosDir();
    final file = File(p.join(dir.path, photo.filename));
    if (file.existsSync()) {
      try { file.deleteSync(); } catch (_) {}
    }
    _photos.removeAt(idx);
    await _persistIndex();
    notifyListeners();
  }

  Future<void> _persistIndex() async {
    final index = await _indexFile();
    await index.writeAsString(
      jsonEncode(_photos.map((p) => p.toJson()).toList()),
      flush: true,
    );
  }

  Future<void> _persistGroups() async {
    final f = await _groupsFile();
    await f.writeAsString(
      jsonEncode(_groups.map((g) => g.toJson()).toList()),
      flush: true,
    );
  }

  /// Preview-mode-only: extract the 8 face crops from a known 4×2 grid
  /// composite (see `assets/preview/team_photo.jpg`). Bypasses Vision /
  /// CIDetector entirely — the iOS simulator's face-detection path is
  /// unreliable on synthetic GAN composites and we need a deterministic
  /// 8-face result for the preview-video recording.
  ///
  /// The composite layout (set by `tool/...` in the recording prep):
  ///   2070 × 1050 canvas, 30px outer padding, 4 columns × 2 rows,
  ///   480 × 480 face cells, 30 px gaps. Total used: 30 + 4×480 + 3×30 +
  ///   30 = 2040 wide (15 px slack each side ≈ 2070), 30 + 2×480 + 30 +
  ///   30 = 1020 tall (15 px slack each side ≈ 1050).
  Future<List<Uint8List>> gridFacesForPreview(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return [];
    const cell = 480, gap = 30, pad = 30;
    const cols = 4, rows = 2;
    final crops = <Uint8List>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final x = pad + c * (cell + gap);
        final y = pad + r * (cell + gap);
        final piece =
            img.copyCrop(decoded, x: x, y: y, width: cell, height: cell);
        final resized = img.copyResize(piece, width: 256, height: 256);
        crops.add(Uint8List.fromList(img.encodePng(resized)));
      }
    }
    return crops;
  }

  /// Detect every face in [imagePath] and crop each one into a square PNG.
  /// On iOS, face detection uses the native Apple Vision framework via a
  /// method channel. On other platforms (no native bridge yet) the entire
  /// image is returned as a single avatar so the upload flow still works.
  /// Pads the bounding box by ~25% on every side to include hair and chin.
  Future<List<Uint8List>> detectAndCropFaces(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return [];

    final List<Map<String, num>> faces = await _detectFaceBoxes(imagePath);

    // No fallback: if Vision finds nothing, return an empty list so the
    // upload preview surfaces "no faces detected" rather than silently
    // crammming the whole photo in as an avatar.
    final crops = <Uint8List>[];
    for (final face in faces) {
      final crop = _squareCropAndEncode(decoded, face);
      crops.add(crop);
    }
    return crops;
  }

  Future<List<Map<String, num>>> _detectFaceBoxes(String imagePath) async {
    if (!Platform.isIOS) return [];
    try {
      final raw = await _faceChannel
          .invokeMethod<List<dynamic>>('detectFaces', {'path': imagePath});
      if (raw == null) return [];
      return raw
          .cast<Map<dynamic, dynamic>>()
          .map((m) => m.map((k, v) => MapEntry(k as String, v as num)))
          .toList();
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }

  /// Crop [decoded] to a square covering the given face bbox (or the centre
  /// of the image when [face] is null), pad by ~25 % beyond the box for
  /// hair/chin, then PNG-encode at most 256 px on a side.
  Uint8List _squareCropAndEncode(img.Image decoded, Map<String, num>? face) {
    int left, top, right, bottom;
    if (face != null) {
      final fl = face['left']!.toDouble();
      final ft = face['top']!.toDouble();
      final fr = face['right']!.toDouble();
      final fb = face['bottom']!.toDouble();
      // Expand the detected face bbox by ~35 % per side (≈70 % total
      // growth) so the saved crop includes shoulders / hair / background.
      // The crop editor later lets the user pan & zoom within this area,
      // so a generous initial crop gives meaningful adjustment room.
      final expand = ((fr - fl) + (fb - ft)) * 0.35;
      left = (fl - expand).clamp(0, decoded.width.toDouble()).toInt();
      top = (ft - expand).clamp(0, decoded.height.toDouble()).toInt();
      right = (fr + expand).clamp(0, decoded.width.toDouble()).toInt();
      bottom = (fb + expand).clamp(0, decoded.height.toDouble()).toInt();
    } else {
      // Centre crop — favours the middle of the photo.
      final s = decoded.width < decoded.height ? decoded.width : decoded.height;
      left = (decoded.width - s) ~/ 2;
      top = (decoded.height - s) ~/ 2;
      right = left + s;
      bottom = top + s;
    }
    final w = right - left;
    final h = bottom - top;

    // Cap the crop edge to the image's shortest side — close-up selfies can
    // produce face boxes (after padding) larger than the remaining image
    // dimension, which would make `decoded.{w,h} - size` negative and crash
    // `clamp(0, negative)`.
    final maxSize =
        decoded.width < decoded.height ? decoded.width : decoded.height;
    final size = (w > h ? w : h).clamp(1, maxSize);
    final cx = left + w ~/ 2;
    final cy = top + h ~/ 2;
    final sx = (cx - size ~/ 2).clamp(0, decoded.width - size);
    final sy = (cy - size ~/ 2).clamp(0, decoded.height - size);

    final cropped = img.copyCrop(
      decoded,
      x: sx,
      y: sy,
      width: size,
      height: size,
    );
    // Target 1024×1024 — large enough that the user can pan / pinch-zoom
    // inside the crop editor without hitting source-resolution limits.
    // Cubic interpolation preserves face detail better than linear.
    const target = 1024;
    final scaled = cropped.width > target
        ? img.copyResize(
            cropped,
            width: target,
            height: target,
            interpolation: img.Interpolation.cubic,
          )
        : cropped;
    return Uint8List.fromList(img.encodePng(scaled));
  }
}
