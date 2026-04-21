import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/practice.dart';
import '../services/practice_service.dart';
import '../state/tactics_state.dart';
import 'practice_run_page.dart';

const _kBg = Color(0xFF0E1C22);
const _kCard = Color(0xFF213E48);
const _kAccent = Color(0xFF00E5CC);

class PracticePlanPage extends StatefulWidget {
  final TacticsState state;
  const PracticePlanPage({super.key, required this.state});

  @override
  State<PracticePlanPage> createState() => _PracticePlanPageState();
}

class _PracticePlanPageState extends State<PracticePlanPage> {
  List<String> _names = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final names = await PracticeService.listNames(widget.state.sportType);
    if (!mounted) return;
    setState(() {
      _names = names;
      _loading = false;
    });
  }

  Future<void> _createNew() async {
    const blankSentinel = '__blank__';
    String? copyFrom;
    if (_names.isNotEmpty) {
      copyFrom = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: _kCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('practice_new'.tr(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: _kAccent),
                title: Text('practice_new_blank'.tr(),
                    style: const TextStyle(color: _kAccent, fontWeight: FontWeight.bold)),
                onTap: () => Navigator.pop(ctx, blankSentinel),
              ),
              const Divider(color: Colors.white12, height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('practice_copy_from'.tr(),
                    style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ),
              ..._names.map((n) => ListTile(
                    leading: const Icon(Icons.copy, color: Colors.white54),
                    title: Text(n, style: const TextStyle(color: Colors.white)),
                    onTap: () => Navigator.pop(ctx, n),
                  )),
            ],
          ),
        ),
      );
      if (copyFrom == null) return;
      if (!mounted) return;
    }

    final sport = widget.state.sportType;
    final name = await _promptName(context, title: 'practice_new'.tr());
    if (name == null || name.isEmpty) return;
    final existing = await PracticeService.load(sport, name);
    if (existing != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('practice_name_exists'.tr())),
      );
      return;
    }
    Practice p;
    if (copyFrom != null && copyFrom != blankSentinel) {
      final base = await PracticeService.load(sport, copyFrom);
      p = Practice(
        name: name,
        notes: base?.notes ?? '',
        items: base?.items
                .map((it) => PracticeItem(
                      tacticName: it.tacticName,
                      durationMinutes: it.durationMinutes,
                      note: it.note,
                    ))
                .toList() ??
            [],
      );
    } else {
      p = Practice(name: name);
    }
    await PracticeService.save(sport, p);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PracticeEditPage(state: widget.state, practice: p),
    ));
    _reload();
  }

  Future<void> _open(String name) async {
    final p = await PracticeService.load(widget.state.sportType, name);
    if (p == null || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PracticeEditPage(state: widget.state, practice: p),
    ));
    _reload();
  }

  Future<void> _confirmDelete(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        title: Text('practice_delete_title'.tr(), style: const TextStyle(color: Colors.white)),
        content: Text(name, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('remove'.tr(), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await PracticeService.delete(widget.state.sportType, name);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        title: Text('practice_plan'.tr(), style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: _kAccent),
            onPressed: _createNew,
            tooltip: 'practice_new'.tr(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kAccent))
          : _names.isEmpty
              ? _EmptyState(onCreate: _createNew)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _names.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (ctx, i) {
                    final name = _names[i];
                    return FutureBuilder<Practice?>(
                      future: PracticeService.load(widget.state.sportType, name),
                      builder: (c, snap) {
                        final p = snap.data;
                        final subtitle = p == null
                            ? ''
                            : '${p.items.length} · ${p.totalMinutes} ${'practice_minutes'.tr()}';
                        return ListTile(
                          leading: const Icon(Icons.event_note, color: _kAccent),
                          title: Text(name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _confirmDelete(name),
                          ),
                          onTap: () => _open(name),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_note_outlined, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          Text('practice_empty'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 15)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: Text('practice_new'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit page
// ─────────────────────────────────────────────────────────────────────────────

class PracticeEditPage extends StatefulWidget {
  final TacticsState state;
  final Practice practice;
  const PracticeEditPage({super.key, required this.state, required this.practice});

  @override
  State<PracticeEditPage> createState() => _PracticeEditPageState();
}

class _PracticeEditPageState extends State<PracticeEditPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  late Practice _p;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _p = widget.practice;
    _nameCtrl = TextEditingController(text: _p.name);
    _notesCtrl = TextEditingController(text: _p.notes);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveIfDirty() async {
    if (!_dirty) return;
    final sport = widget.state.sportType;
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;
    if (newName != _p.name) {
      final existing = await PracticeService.load(sport, newName);
      if (existing != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('practice_name_exists'.tr())),
        );
        return;
      }
      await PracticeService.rename(sport, _p.name, newName);
      _p.name = newName;
    }
    _p.notes = _notesCtrl.text;
    await PracticeService.save(sport, _p);
    _dirty = false;
  }

  Future<void> _saveCurrentAsNew() async {
    const blankSentinel = '__blank_tactic__';
    final existing = await widget.state.listSavedTactics();
    if (!mounted) return;

    String? base;
    if (existing.isEmpty) {
      base = blankSentinel;
    } else {
      base = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: _kCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('practice_add_tactic'.tr(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: _kAccent),
                title: Text('tactic_new_blank'.tr(),
                    style: const TextStyle(color: _kAccent, fontWeight: FontWeight.bold)),
                onTap: () => Navigator.pop(ctx, blankSentinel),
              ),
              const Divider(color: Colors.white12, height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('tactic_copy_from'.tr(),
                    style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ),
              ...existing.map((n) => ListTile(
                    leading: const Icon(Icons.copy, color: Colors.white54),
                    title: Text(n, style: const TextStyle(color: Colors.white)),
                    onTap: () => Navigator.pop(ctx, n),
                  )),
            ],
          ),
        ),
      );
      if (base == null) return;
      if (!mounted) return;
    }

    final name = await _promptName(
      context,
      title: 'practice_add_tactic'.tr(),
      hint: 'tactics_name'.tr(),
    );
    if (name == null || name.isEmpty) return;
    if (existing.contains(name)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('practice_name_exists'.tr())),
      );
      return;
    }

    if (base == blankSentinel) {
      widget.state.clearAll();
    } else {
      await widget.state.loadTactics(base);
    }
    await widget.state.saveTactics(name);
    if (!mounted) return;
    setState(() {
      _p.items.add(PracticeItem(tacticName: name));
      _dirty = true;
    });
    await _saveIfDirty();
  }

  Future<void> _addItem() async {
    final names = await widget.state.listSavedTactics();
    if (!mounted) return;
    const _newSentinel = '__save_current__';
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'practice_pick_tactic'.tr(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: _kAccent),
              title: Text('practice_add_tactic'.tr(), style: const TextStyle(color: _kAccent, fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(ctx, _newSentinel),
            ),
            if (names.isNotEmpty) const Divider(color: Colors.white12, height: 1),
            ...names.map((n) => ListTile(
                  leading: const Icon(Icons.description, color: Colors.white54),
                  title: Text(n, style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(ctx, n),
                )),
          ],
        ),
      ),
    );
    if (picked == null) return;
    if (picked == _newSentinel) {
      await _saveCurrentAsNew();
      return;
    }
    setState(() {
      _p.items.add(PracticeItem(tacticName: picked));
      _dirty = true;
    });
    await _saveIfDirty();
  }

  Future<void> _confirmRemoveItem(int index) async {
    final name = _p.items[index].tacticName;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        title: Text('practice_remove_item_title'.tr(),
            style: const TextStyle(color: Colors.white)),
        content: Text(name, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('remove'.tr(),
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _p.items.removeAt(index);
      _dirty = true;
    });
    await _saveIfDirty();
  }

  Future<void> _startRun() async {
    await _saveIfDirty();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PracticeRunPage(state: widget.state, practice: _p),
    ));
  }

  Future<void> _loadTactic(String name) async {
    await _saveIfDirty();
    await widget.state.loadTactics(name);
    if (!mounted) return;
    widget.state.editingFromPlan = _p.name;
    Navigator.of(context).popUntil((r) => r.isFirst);
    if (widget.state.hasMoves) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.state.startAnimation();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, __) => _saveIfDirty(),
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kCard,
          title: Text('practice_edit'.tr(), style: const TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (_p.items.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.play_circle_fill, color: _kAccent),
                tooltip: 'practice_start'.tr(),
                onPressed: _startRun,
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text('practice_name'.tr(),
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: _inputDeco(),
              onChanged: (_) => _dirty = true,
              onEditingComplete: _saveIfDirty,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text('practice_notes'.tr(),
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ),
            TextField(
              controller: _notesCtrl,
              style: const TextStyle(color: Colors.white70),
              decoration: _inputDeco(),
              minLines: 2,
              maxLines: 4,
              onChanged: (_) => _dirty = true,
              onEditingComplete: _saveIfDirty,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('practice_items'.tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const Spacer(),
                Text('${_p.totalMinutes} ${'practice_minutes'.tr()}',
                    style: const TextStyle(color: _kAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (_p.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'practice_no_items'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _p.items.length,
                onReorder: (oldIdx, newIdx) {
                  setState(() {
                    if (newIdx > oldIdx) newIdx -= 1;
                    final it = _p.items.removeAt(oldIdx);
                    _p.items.insert(newIdx, it);
                    _dirty = true;
                  });
                  _saveIfDirty();
                },
                itemBuilder: (ctx, i) {
                  final it = _p.items[i];
                  return _ItemCard(
                    key: ValueKey('item-$i-${it.tacticName}'),
                    index: i,
                    item: it,
                    onDurationChange: (v) {
                      setState(() {
                        it.durationMinutes = v;
                        _dirty = true;
                      });
                      _saveIfDirty();
                    },
                    onNoteChange: (v) {
                      it.note = v;
                      _dirty = true;
                    },
                    onNoteEditEnd: _saveIfDirty,
                    onDelete: () => _confirmRemoveItem(i),
                    onLoad: () => _loadTactic(it.tacticName),
                  );
                },
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: Text('practice_add_tactic'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco() => InputDecoration(
        filled: true,
        fillColor: _kCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      );
}

class _ItemCard extends StatefulWidget {
  final int index;
  final PracticeItem item;
  final ValueChanged<int> onDurationChange;
  final ValueChanged<String> onNoteChange;
  final VoidCallback onNoteEditEnd;
  final VoidCallback onDelete;
  final VoidCallback onLoad;

  const _ItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.onDurationChange,
    required this.onNoteChange,
    required this.onNoteEditEnd,
    required this.onDelete,
    required this.onLoad,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.item.note);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: widget.index,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.drag_handle, color: Colors.white38),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onLoad,
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: _kAccent, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.item.tacticName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: _kAccent, size: 20),
                onPressed: widget.onLoad,
                tooltip: 'practice_edit'.tr(),
              ),
              _DurationField(
                value: widget.item.durationMinutes,
                onChanged: widget.onDurationChange,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          TextField(
            controller: _noteCtrl,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'practice_item_note'.tr(),
              hintStyle: const TextStyle(color: Colors.white24),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
            ),
            onChanged: widget.onNoteChange,
            onEditingComplete: widget.onNoteEditEnd,
          ),
        ],
      ),
    );
  }
}

class _DurationField extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _DurationField({required this.value, required this.onChanged});

  @override
  State<_DurationField> createState() => _DurationFieldState();
}

class _DurationFieldState extends State<_DurationField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          suffixText: 'm',
          suffixStyle: const TextStyle(color: Colors.white38, fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
        ),
        onChanged: (v) {
          final n = int.tryParse(v);
          if (n != null && n >= 0) widget.onChanged(n);
        },
      ),
    );
  }
}

Future<String?> _promptName(BuildContext context, {required String title, String? hint}) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _kCard,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint ?? 'practice_name'.tr(),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr())),
        TextButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: Text('confirm'.tr(), style: const TextStyle(color: _kAccent)),
        ),
      ],
    ),
  );
}
