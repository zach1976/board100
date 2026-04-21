import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/practice.dart';
import '../state/tactics_state.dart';

const _kBg = Color(0xFF0E1C22);
const _kCard = Color(0xFF213E48);
const _kAccent = Color(0xFF00E5CC);

class PracticeRunPage extends StatefulWidget {
  final TacticsState state;
  final Practice practice;
  final int initialIndex;
  const PracticeRunPage({
    super.key,
    required this.state,
    required this.practice,
    this.initialIndex = 0,
  });

  @override
  State<PracticeRunPage> createState() => _PracticeRunPageState();
}

class _PracticeRunPageState extends State<PracticeRunPage> {
  int _idx = 0;
  int _secLeft = 0;
  bool _running = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex.clamp(0, widget.practice.items.length - 1);
    widget.state.runningPlanName = null;
    _resetItem();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  PracticeItem? get _current =>
      _idx < widget.practice.items.length ? widget.practice.items[_idx] : null;

  void _resetItem() {
    final it = _current;
    setState(() {
      _secLeft = (it?.durationMinutes ?? 0) * 60;
      _running = false;
    });
    _timer?.cancel();
  }

  void _togglePlay() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      if (_secLeft <= 0) return;
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_secLeft <= 1) {
          _timer?.cancel();
          HapticFeedback.heavyImpact();
          setState(() {
            _secLeft = 0;
            _running = false;
          });
          _onItemFinished();
        } else {
          setState(() => _secLeft -= 1);
        }
      });
    }
  }

  void _onItemFinished() {
    if (_idx + 1 >= widget.practice.items.length) {
      _showCompleteDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('practice_item_done'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
      _next();
    }
  }

  void _prev() {
    if (_idx <= 0) return;
    setState(() => _idx -= 1);
    _resetItem();
  }

  void _next() {
    if (_idx + 1 >= widget.practice.items.length) return;
    setState(() => _idx += 1);
    _resetItem();
  }

  Future<void> _openOnBoard() async {
    final it = _current;
    if (it == null) return;
    _timer?.cancel();
    widget.state.runningPlanName = widget.practice.name;
    widget.state.runningItemIndex = _idx;
    widget.state.editingFromPlan = null;
    await widget.state.loadTactics(it.tacticName);
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    if (widget.state.hasMoves) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.state.startAnimation();
      });
    }
  }

  Future<void> _showCompleteDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        title: Text('practice_complete_title'.tr(),
            style: const TextStyle(color: Colors.white)),
        content: Text(widget.practice.name,
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('confirm'.tr(),
                style: const TextStyle(color: _kAccent)),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  String _mmss(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.practice.items;
    final it = _current;
    if (items.isEmpty || it == null) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kCard,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(widget.practice.name,
              style: const TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Text('practice_no_items'.tr(),
              style: const TextStyle(color: Colors.white54)),
        ),
      );
    }
    final total = items.length;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.practice.name,
            style: const TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('${_idx + 1} / $total',
                  style: const TextStyle(color: Colors.white54, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.tacticName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    if (it.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(it.note,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _mmss(_secLeft),
                style: TextStyle(
                  color: _secLeft == 0 ? Colors.redAccent : _kAccent,
                  fontSize: 84,
                  fontWeight: FontWeight.w300,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RoundBtn(
                    icon: Icons.skip_previous,
                    enabled: _idx > 0,
                    onTap: _prev,
                  ),
                  _RoundBtn(
                    icon: _running ? Icons.pause : Icons.play_arrow,
                    size: 72,
                    enabled: _secLeft > 0,
                    primary: true,
                    onTap: _togglePlay,
                  ),
                  _RoundBtn(
                    icon: Icons.skip_next,
                    enabled: _idx + 1 < total,
                    onTap: _next,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetItem,
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      label: Text('timeline_reset'.tr(),
                          style: const TextStyle(color: Colors.white70)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _openOnBoard,
                      icon: const Icon(Icons.open_in_full),
                      label: Text('practice_open_board'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool primary;
  final bool enabled;
  const _RoundBtn({
    required this.icon,
    required this.onTap,
    this.size = 56,
    this.primary = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? _kAccent : _kCard;
    final fg = primary ? Colors.black : Colors.white;
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: fg, size: size * 0.5),
        ),
      ),
    );
  }
}
