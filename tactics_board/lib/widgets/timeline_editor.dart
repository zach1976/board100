import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/player_icon.dart';
import '../models/drawing_stroke.dart';
import '../state/tactics_state.dart';

/// Timeline editor — tap blocks to select, tap empty slot to move
class TimelineEditor extends StatefulWidget {
  final TacticsState state;
  const TimelineEditor({super.key, required this.state});

  @override
  State<TimelineEditor> createState() => _TimelineEditorState();
}

class _TimelineEditorState extends State<TimelineEditor> {
  // Selected block: either a player move or a stroke
  ({String id, int moveIdx, bool isStroke})? _selected;

  int get _phaseCount {
    int max = 0;
    for (final p in widget.state.players) {
      p.syncPhases();
      for (final ph in p.movePhases) {
        if (ph > max) max = ph;
      }
    }
    for (final s in widget.state.strokes) {
      if (s.phase > max) max = s.phase;
    }
    return max + 2;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final players = widget.state.players.where((p) => p.moves.isNotEmpty).toList();
        final strokes = widget.state.strokes;
        if (players.isEmpty && strokes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text('No moves', style: TextStyle(color: Colors.white54))),
          );
        }
        final phaseCount = _phaseCount;
        return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.view_timeline, color: Colors.purpleAccent, size: 20),
                  const SizedBox(width: 8),
                  Text('timeline'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  if (_selected != null)
                    GestureDetector(
                      onTap: () => setState(() => _selected = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _resetToDefault,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                      child: Text('timeline_reset'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            if (_selected != null)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text('Tap an empty slot to move', style: TextStyle(color: Colors.amber, fontSize: 11)),
              ),
            // Phase numbers
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 4, 12, 2),
              child: Row(
                children: List.generate(phaseCount, (i) => Expanded(
                  child: Center(
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                )),
              ),
            ),
            // Player rows
            ...players.map((player) => _buildPlayerRow(player, phaseCount)),
            // Stroke rows
            if (strokes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                child: Row(
                  children: [
                    Icon(Icons.draw, color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    Text('mode_draw'.tr(), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              ...strokes.asMap().entries.map((e) => _buildStrokeRow(e.value, e.key, phaseCount)),
            ],
            const SizedBox(height: 12),
          ],
        ),
      );
      },
    );
  }

  Widget _buildPlayerRow(PlayerIcon player, int phaseCount) {
    player.syncPhases();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Row(
              children: [
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: player.color, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                ),
                const SizedBox(width: 4),
                Text(player.label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(phaseCount, (phaseIdx) {
                final moveIdx = player.movePhases.indexOf(phaseIdx);
                final hasMove = moveIdx >= 0;
                final isSelected = _selected != null && !_selected!.isStroke && _selected!.id == player.id && hasMove && _selected!.moveIdx == moveIdx;
                final canDrop = _selected != null && !_selected!.isStroke && _selected!.id == player.id && !hasMove;

                return Expanded(
                  child: DragTarget<({String id, int moveIdx, bool isStroke})>(
                    onWillAcceptWithDetails: (details) => !details.data.isStroke && details.data.id == player.id && !hasMove,
                    onAcceptWithDetails: (details) {
                      widget.state.setMovePhase(details.data.id, details.data.moveIdx, phaseIdx);
                      setState(() => _selected = null);
                    },
                    builder: (context, candidateData, _) {
                      final isDropHover = candidateData.isNotEmpty;
                      return _buildSlot(
                        color: player.moveColor,
                        hasContent: hasMove,
                        isSelected: isSelected,
                        isDropHover: isDropHover,
                        canDrop: canDrop,
                        label: hasMove ? '${moveIdx + 1}' : null,
                        onTap: () => _onPlayerSlotTap(player, phaseIdx, moveIdx, hasMove),
                        onDelete: isSelected ? () {
                          widget.state.removePlayerWaypoint(player.id, moveIdx);
                          setState(() => _selected = null);
                        } : null,
                        dragData: hasMove ? (id: player.id, moveIdx: moveIdx, isStroke: false) : null,
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrokeRow(DrawingStroke stroke, int index, int phaseCount) {
    final c = stroke.color;
    final start = stroke.isFullSpan ? 0 : stroke.startPhase;
    final end = stroke.isFullSpan ? phaseCount - 1 : stroke.endPhase.clamp(0, phaseCount - 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Row(
              children: [
                Icon(Icons.gesture, color: c, size: 14),
                const SizedBox(width: 4),
                Text('${index + 1}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(phaseCount, (i) {
                final inRange = i >= start && i <= end;
                final isStart = !stroke.isFullSpan && i == start;
                final isEnd = !stroke.isFullSpan && i == end;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (stroke.isFullSpan) {
                        // First tap: narrow to single cell
                        widget.state.setStrokePhaseRange(stroke.id, i, i);
                      } else if (inRange) {
                        if (start == end) {
                          // Single cell: reset to ALL
                          widget.state.setStrokePhaseRange(stroke.id, -1, -1);
                        } else if (i == start) {
                          // Tap left edge: shrink from left
                          widget.state.setStrokePhaseRange(stroke.id, start + 1, end);
                        } else if (i == end) {
                          // Tap right edge: shrink from right
                          widget.state.setStrokePhaseRange(stroke.id, start, end - 1);
                        }
                      } else {
                        // Tap outside: expand to include
                        final ns = i < start ? i : start;
                        final ne = i > end ? i : end;
                        widget.state.setStrokePhaseRange(stroke.id, ns, ne);
                      }
                    },
                    child: Container(
                      height: 34,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: inRange ? c.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: inRange ? c.withValues(alpha: 0.7) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: inRange
                          ? Center(
                              child: (isStart || isEnd)
                                  ? Icon(
                                      isStart ? Icons.chevron_right : Icons.chevron_left,
                                      color: c, size: 16,
                                    )
                                  : (stroke.isFullSpan && i == phaseCount ~/ 2)
                                      ? Text('ALL', style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold))
                                      : Icon(Icons.draw, color: c.withValues(alpha: 0.5), size: 10),
                            )
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlot({
    required Color color,
    required bool hasContent,
    required bool isSelected,
    required bool isDropHover,
    required bool canDrop,
    String? label,
    IconData? icon,
    required VoidCallback onTap,
    VoidCallback? onDelete,
    ({String id, int moveIdx, bool isStroke})? dragData,
  }) {
    final slotColor = isSelected
        ? Colors.amber.withValues(alpha: 0.4)
        : isDropHover
            ? color.withValues(alpha: 0.35)
            : hasContent
                ? color.withValues(alpha: 0.5)
                : canDrop
                    ? Colors.amber.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.03);
    final borderColor = isSelected
        ? Colors.amber
        : isDropHover
            ? color
            : hasContent
                ? color
                : canDrop
                    ? Colors.amber.withValues(alpha: 0.4)
                    : Colors.transparent;

    final blockWidget = Container(
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: slotColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: isSelected || isDropHover ? 2 : 1.5),
      ),
      child: hasContent
          ? (isSelected && onDelete != null)
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label ?? '', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 2),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.close, color: Colors.redAccent, size: 14),
                    ),
                  ],
                )
              : Center(
                  child: icon != null
                      ? Icon(icon, color: isSelected ? Colors.amber : Colors.white, size: 14)
                      : Text(
                          label ?? '',
                          style: TextStyle(
                            color: isSelected ? Colors.amber : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                )
          : (canDrop || isDropHover)
              ? Center(child: Icon(Icons.add, color: isDropHover ? color : Colors.amber, size: 16))
              : null,
    );

    if (dragData == null) {
      return GestureDetector(onTap: onTap, child: blockWidget);
    }

    return Draggable<({String id, int moveIdx, bool isStroke})>(
      data: dragData,
      onDragStarted: () => setState(() => _selected = dragData),
      onDragEnd: (_) {},
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 48,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, color: Colors.white, size: 14)
                : Text(label ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
          ),
        ),
      ),
      childWhenDragging: Container(
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: GestureDetector(onTap: onTap, child: blockWidget),
    );
  }

  void _onPlayerSlotTap(PlayerIcon player, int phaseIdx, int moveIdx, bool hasMove) {
    if (_selected != null && !_selected!.isStroke && _selected!.id == player.id) {
      if (hasMove && _selected!.moveIdx == moveIdx) {
        setState(() => _selected = null);
      } else if (!hasMove) {
        widget.state.setMovePhase(player.id, _selected!.moveIdx, phaseIdx);
        setState(() => _selected = null);
      } else {
        setState(() => _selected = (id: player.id, moveIdx: moveIdx, isStroke: false));
      }
    } else if (hasMove) {
      setState(() => _selected = (id: player.id, moveIdx: moveIdx, isStroke: false));
    }
  }

  void _resetToDefault() {
    for (final p in widget.state.players) {
      for (int i = 0; i < p.moves.length; i++) {
        widget.state.setMovePhase(p.id, i, i);
      }
    }
    for (final s in widget.state.strokes) {
      widget.state.setStrokePhaseRange(s.id, -1, -1);
    }
    setState(() => _selected = null);
  }
}
