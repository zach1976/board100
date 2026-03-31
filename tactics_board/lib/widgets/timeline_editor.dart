import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/player_icon.dart';
import '../state/tactics_state.dart';

/// Timeline editor — tap blocks to select, tap empty slot to move
class TimelineEditor extends StatefulWidget {
  final TacticsState state;
  const TimelineEditor({super.key, required this.state});

  @override
  State<TimelineEditor> createState() => _TimelineEditorState();
}

class _TimelineEditorState extends State<TimelineEditor> {
  // Selected block: playerId + moveIdx
  ({String playerId, int moveIdx})? _selected;

  int get _phaseCount {
    int max = 0;
    for (final p in widget.state.players) {
      p.syncPhases();
      for (final ph in p.movePhases) {
        if (ph > max) max = ph;
      }
    }
    return max + 2;
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.state.players.where((p) => p.moves.isNotEmpty).toList();
    if (players.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text('No moves', style: TextStyle(color: Colors.white54))),
      );
    }

    final phaseCount = _phaseCount;

    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) => SafeArea(
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
            const SizedBox(height: 12),
          ],
        ),
      ),
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
                final isSelected = _selected != null && _selected!.playerId == player.id && hasMove && _selected!.moveIdx == moveIdx;
                final canDrop = _selected != null && _selected!.playerId == player.id && !hasMove;

                return Expanded(
                  child: DragTarget<({String playerId, int moveIdx})>(
                    onWillAcceptWithDetails: (details) => details.data.playerId == player.id && !hasMove,
                    onAcceptWithDetails: (details) {
                      widget.state.setMovePhase(details.data.playerId, details.data.moveIdx, phaseIdx);
                      setState(() => _selected = null);
                    },
                    builder: (context, candidateData, _) {
                      final isDropHover = candidateData.isNotEmpty;
                      final slotColor = isSelected
                          ? Colors.amber.withValues(alpha: 0.4)
                          : isDropHover
                              ? player.moveColor.withValues(alpha: 0.35)
                              : hasMove
                                  ? player.moveColor.withValues(alpha: 0.5)
                                  : canDrop
                                      ? Colors.amber.withValues(alpha: 0.12)
                                      : Colors.white.withValues(alpha: 0.03);
                      final borderColor = isSelected
                          ? Colors.amber
                          : isDropHover
                              ? player.moveColor
                              : hasMove
                                  ? player.moveColor
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
                        child: hasMove
                            ? Center(
                                child: Text(
                                  '${moveIdx + 1}',
                                  style: TextStyle(
                                    color: isSelected ? Colors.amber : Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : (canDrop || isDropHover)
                                ? Center(child: Icon(Icons.add, color: isDropHover ? player.moveColor : Colors.amber, size: 16))
                                : null,
                      );

                      if (!hasMove) {
                        return GestureDetector(
                          onTap: () => _onSlotTap(player, phaseIdx, moveIdx, hasMove),
                          child: blockWidget,
                        );
                      }

                      return Draggable<({String playerId, int moveIdx})>(
                        data: (playerId: player.id, moveIdx: moveIdx),
                        onDragStarted: () => setState(() => _selected = (playerId: player.id, moveIdx: moveIdx)),
                        onDragEnd: (_) {},
                        feedback: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 48, height: 34,
                            decoration: BoxDecoration(
                              color: player.moveColor.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Center(
                              child: Text('${moveIdx + 1}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                            ),
                          ),
                        ),
                        childWhenDragging: Container(
                          height: 34,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: player.moveColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: player.moveColor.withValues(alpha: 0.3), width: 1),
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () => _onSlotTap(player, phaseIdx, moveIdx, hasMove),
                          child: blockWidget,
                        ),
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

  void _onSlotTap(PlayerIcon player, int phaseIdx, int moveIdx, bool hasMove) {
    if (_selected != null && _selected!.playerId == player.id) {
      if (hasMove && _selected!.moveIdx == moveIdx) {
        // Tapped the selected block again — deselect
        setState(() => _selected = null);
      } else if (!hasMove) {
        // Tapped empty slot — move the selected block here
        widget.state.setMovePhase(player.id, _selected!.moveIdx, phaseIdx);
        setState(() => _selected = null);
      } else {
        // Tapped a different block — select it instead
        setState(() => _selected = (playerId: player.id, moveIdx: moveIdx));
      }
    } else if (hasMove) {
      // Select this block
      setState(() => _selected = (playerId: player.id, moveIdx: moveIdx));
    }
  }

  void _resetToDefault() {
    for (final p in widget.state.players) {
      for (int i = 0; i < p.moves.length; i++) {
        widget.state.setMovePhase(p.id, i, i);
      }
    }
    setState(() => _selected = null);
  }
}
