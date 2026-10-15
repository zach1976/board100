import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../ui/primitives.dart';
import '../ui/adaptive.dart';
import '../ui/tokens.dart';

import '../models/tactic_meta.dart';
import '../state/tactics_state.dart';
import '../ui_constants.dart';

/// Full-page form for saving a board: name, folder, description and coaching
/// points. Pops a [TacticMeta] on confirm, or null on cancel. Persisting is the
/// caller's job so it can handle name collisions.
class SaveTacticPage extends StatefulWidget {
  final TacticsState state;

  /// Pre-fills the form when re-saving an existing board.
  final TacticMeta? initial;

  /// Boards the caller has already listed. Passing them spares this page a
  /// second read-and-decode of every saved file just to collect folder names.
  final List<TacticMeta>? knownMetas;

  const SaveTacticPage(
      {super.key, required this.state, this.initial, this.knownMetas});

  @override
  State<SaveTacticPage> createState() => _SaveTacticPageState();
}

class _SaveTacticPageState extends State<SaveTacticPage> {
  late final _nameCtrl = TextEditingController(
      text: widget.initial?.name ??
          widget.state.currentTacticName ??
          widget.state.openedDrillName ??
          '');
  late final _descCtrl =
      TextEditingController(text: widget.initial?.description ?? '');
  late final _pointsCtrl =
      TextEditingController(text: widget.initial?.coachingPoints ?? '');

  late String _folder = widget.initial?.folder ?? '';
  List<String> _folders = [];

  @override
  void initState() {
    super.initState();
    _reloadFolders();
  }

  Future<void> _reloadFolders() async {
    // A newly created folder lands in prefs, which listFolders always reads, so
    // reusing knownMetas here still picks it up.
    final folders = await widget.state.listFolders(knownMetas: widget.knownMetas);
    if (mounted) setState(() => _folders = folders);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('tactics_name'.tr())));
      return;
    }
    final base = widget.initial ?? TacticMeta.initial(name);
    Navigator.pop(
      context,
      base.copyWith(
        name: name,
        folder: _folder,
        description: _descCtrl.text.trim(),
        coachingPoints: _pointsCtrl.text.trim(),
      ),
    );
  }

  Future<void> _pickFolder() async {
    final picked = await TacticalSheet.show(
      context,
      builder: (ctx) => TacticalSheet(
        padding: const EdgeInsets.fromLTRB(0, T.s12, 0, 0),
        child: _FolderPicker(folders: _folders, selected: _folder),
      ));
    if (picked == null || !mounted) return;
    if (picked == _kNewFolderSentinel) {
      await _createFolder();
      return;
    }
    setState(() => _folder = picked);
  }

  Future<void> _createFolder() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('new_folder'.tr(),
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'folder_name'.tr(),
            hintStyle: const TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('confirm'.tr(),
                style: TextStyle(color: T.accent)),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    await widget.state.createFolder(name);
    await _reloadFolders();
    if (mounted) setState(() => _folder = name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('save_tactic_title'.tr(),
            style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.check_rounded, color: T.accent),
            onPressed: _confirm,
          ),
        ],
      ),
      body: SafeArea(
        // A form's width on a tablet, centred: four fields 1300pt wide with
        // the screen's lower two-thirds empty read as a phone page stretched.
        child: LayoutBuilder(builder: (context, box) {
          final x = 20 +
              tabletInset(context, box.maxWidth - 40, maxWidth: kFormMaxWidth);
          return ListView(
          padding: EdgeInsets.fromLTRB(x, 8, x, 32),
          children: [
            _label('tactic_name_label'.tr()),
            _field(controller: _nameCtrl, hint: 'tactics_name'.tr()),
            const SizedBox(height: 22),
            _label('select_folder'.tr()),
            GestureDetector(
              onTap: _pickFolder,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_outlined,
                        color: Colors.white54, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _folder.isEmpty ? 'folder_default'.tr() : _folder,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded, color: Colors.white54, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            _label('description'.tr()),
            _field(controller: _descCtrl, hint: '', maxLines: 4),
            const SizedBox(height: 22),
            _label('coaching_points'.tr()),
            _field(controller: _pointsCtrl, hint: '', maxLines: 4),
          ],
        );
        }),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) =>
      TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        textInputAction:
            maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
      );
}

/// Popped by [_FolderPicker] to mean "let me name a new one".
const _kNewFolderSentinel = '\u0000new';

class _FolderPicker extends StatelessWidget {
  final List<String> folders;
  final String selected;
  const _FolderPicker({required this.folders, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Text('select_folder'.tr(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _tile(context, '', 'folder_default'.tr()),
                  for (final f in folders) _tile(context, f, f),
                  ListTile(
                    leading: Icon(Icons.create_new_folder_outlined,
                        color: T.accent, size: 20),
                    title: Text('new_folder'.tr(),
                        style: TextStyle(
                            color: T.accent, fontSize: 14)),
                    onTap: () => Navigator.pop(context, _kNewFolderSentinel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String value, String label) => ListTile(
        leading: const Icon(Icons.folder_outlined, color: Colors.white54, size: 20),
        title: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: value == selected
            ? Icon(Icons.check_rounded, color: T.accent, size: 20)
            : null,
        onTap: () => Navigator.pop(context, value),
      );
}
