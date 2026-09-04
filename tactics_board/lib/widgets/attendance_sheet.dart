import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/player_photo.dart';
import '../services/photo_library_service.dart';
import '../ui_constants.dart';
import 'toolbar.dart' show sheetConstraints, scaledSheet;

/// "Who was here?" — asked once, at the end of a session.
///
/// This is the only data entry the season log needs, so it has to cost the
/// coach seconds, not minutes: everyone starts present (the common case is a
/// full squad minus one or two), and tapping a face marks them absent. The
/// sheet is skippable — a session with no attendance is still a session, and
/// nagging is how a log stops being filled in at all.
class AttendanceSheet extends StatefulWidget {
  final List<PlayerPhoto> squad;
  final String? squadId;
  const AttendanceSheet({super.key, required this.squad, this.squadId});

  /// Returns the ids present, or null if the coach skipped.
  static Future<List<String>?> show(
    BuildContext context, {
    required List<PlayerPhoto> squad,
    String? squadId,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      constraints: sheetConstraints(context),
      backgroundColor: kSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) =>
          scaledSheet(ctx, AttendanceSheet(squad: squad, squadId: squadId)),
    );
  }

  @override
  State<AttendanceSheet> createState() => _AttendanceSheetState();
}

class _AttendanceSheetState extends State<AttendanceSheet> {
  late Set<String> _present;

  @override
  void initState() {
    super.initState();
    _present = {for (final m in widget.squad) m.id};
  }

  @override
  Widget build(BuildContext context) {
    final absent = widget.squad.length - _present.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.how_to_reg_outlined, color: kAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('attendance_title'.tr(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('attendance_skip'.tr(),
                      style: const TextStyle(color: Colors.white54)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              absent == 0
                  ? 'attendance_all_here'.tr()
                  : 'attendance_absent'.tr(args: ['$absent']),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final m in widget.squad)
                      _MemberToggle(
                        member: m,
                        present: _present.contains(m.id),
                        onTap: () => setState(() {
                          if (!_present.remove(m.id)) _present.add(m.id);
                        }),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: kAccent),
                onPressed: () => Navigator.of(context).pop(_present.toList()),
                child: Text('attendance_save'.tr(args: ['${_present.length}']),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberToggle extends StatefulWidget {
  final PlayerPhoto member;
  final bool present;
  final VoidCallback onTap;
  const _MemberToggle({required this.member, required this.present, required this.onTap});

  @override
  State<_MemberToggle> createState() => _MemberToggleState();
}

class _MemberToggleState extends State<_MemberToggle> {
  String? _path;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    if (widget.member.filename.isEmpty) return;
    final p = await PhotoLibraryService.instance.resolvePath(widget.member);
    if (mounted) setState(() => _path = p);
  }

  @override
  Widget build(BuildContext context) {
    final present = widget.present;
    final label = widget.member.boardLabel;
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Opacity(
                  opacity: present ? 1 : 0.32,
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                      image: _path != null
                          ? DecorationImage(image: FileImage(File(_path!)), fit: BoxFit.cover)
                          : null,
                      border: Border.all(
                        color: present ? kAccent : Colors.white24,
                        width: present ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _path == null
                        ? Text(label,
                            style: const TextStyle(
                                color: Colors.white70, fontWeight: FontWeight.w700))
                        : null,
                  ),
                ),
                if (!present)
                  const Positioned(
                    right: 0, bottom: 0,
                    child: Icon(Icons.remove_circle, color: Colors.white38, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.member.playerName?.trim().isNotEmpty == true
                  ? widget.member.playerName!
                  : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: present ? Colors.white70 : Colors.white30,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
