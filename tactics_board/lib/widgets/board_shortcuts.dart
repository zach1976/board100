import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/tactics_state.dart';
import 'toolbar.dart';

/// The board's hardware-keyboard shortcuts — an iPad with a Magic Keyboard,
/// a Mac window.
///
///   Space            play / stop
///   ← / →            step back / forward
///   ⌘Z / ⇧⌘Z         undo / redo (Ctrl on other platforms)
///   Delete, ⌫        remove what is selected
///   Esc              deselect; leave Draw / Select; leave full screen
///   ⌘S               save (in place when the board has a name)
///
/// None of them fires while a text field has the focus: a coach typing a
/// note into a dialog is typing, not driving the board. A sheet or popover
/// on top takes the focus with its route, so the board's keys are quiet
/// under it and Esc closes it (ModalRoute's own dismiss).
class BoardShortcuts extends StatefulWidget {
  final Widget child;
  const BoardShortcuts({super.key, required this.child});

  @override
  State<BoardShortcuts> createState() => _BoardShortcutsState();
}

class _BoardShortcutsState extends State<BoardShortcuts> {
  final FocusNode _node = FocusNode(debugLabel: 'board shortcuts');

  @override
  void initState() {
    super.initState();
    // Autofocus alone is not enough: it only takes when the route's scope
    // has nothing focused yet, and a closed dialog or a tap can leave the
    // focus nowhere — and then no key reaches the board. Whenever the
    // board's route is on top and nothing in particular has the focus,
    // the board takes it back.
    FocusManager.instance.addListener(_refocus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refocus());
  }

  void _refocus() {
    if (!mounted || _node.hasPrimaryFocus) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    final f = FocusManager.instance.primaryFocus;
    if (f == null || f is FocusScopeNode) _node.requestFocus();
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_refocus);
    _node.dispose();
    super.dispose();
  }

  /// A text field — anywhere — has the keyboard.
  static bool get typing {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText ||
        ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  VoidCallback _guard(void Function(TacticsState s) f) => () {
        if (typing || !mounted) return;
        f(context.read<TacticsState>());
      };

  static void playPause(TacticsState s) {
    if (s.isAnimating) {
      s.stopAnimation();
    } else if (s.hasMoves) {
      s.startAnimation();
    }
  }

  static void deleteSelection(TacticsState s) {
    if (s.isAnimating) return;
    final id = s.selectedPlayerId;
    if (id != null) {
      s.removePlayer(id);
      return;
    }
    final stroke = s.selectedStrokeId;
    if (stroke != null) {
      s.deleteStroke(stroke);
      return;
    }
    if (s.multiSelectMode && s.hasMultiSelection) {
      for (final p in s.multiSelectIds) {
        s.removePlayer(p);
      }
      for (final k in s.multiSelectStrokeIds) {
        s.deleteStroke(k);
      }
      s.clearMultiSelect();
    }
  }

  static void escape(TacticsState s) {
    if (s.selectedPlayerId != null) {
      s.selectPlayer(null);
    } else if (s.selectedStrokeId != null) {
      s.selectStroke(null);
    } else if (s.multiSelectMode) {
      s.setMultiSelectMode(false);
    } else if (s.isDrawingMode) {
      s.setDrawingMode(false);
    } else if (s.presentationMode) {
      s.togglePresentationMode();
    } else if (!s.toolbarVisible) {
      s.toggleToolbar();
    }
  }

  void _save(TacticsState s) {
    final name = s.currentTacticName;
    if (name == null) {
      // A board with no name yet: the Save panel, one tap from the form.
      showSaveLoadSheet(context, s);
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    s.saveTactics(name).then((_) {
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        SnackBar(content: Text('${'save_success'.tr()}: $name')),
      );
    }, onError: (Object e) {
      messenger?.showSnackBar(SnackBar(content: Text('save_error'.tr())));
    });
  }

  @override
  Widget build(BuildContext context) {
    final undo = _guard((s) {
      if (s.canUndo && !s.isAnimating) s.undo();
    });
    final redo = _guard((s) {
      if (s.canRedo && !s.isAnimating) s.redo();
    });
    final save = _guard(_save);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _guard(playPause),
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            _guard((s) => s.stepBackward()),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            _guard((s) => s.stepForward()),
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): undo,
        const SingleActivator(LogicalKeyboardKey.keyZ,
            meta: true, shift: true): redo,
        const SingleActivator(LogicalKeyboardKey.keyZ,
            control: true, shift: true): redo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): redo,
        const SingleActivator(LogicalKeyboardKey.delete):
            _guard(deleteSelection),
        const SingleActivator(LogicalKeyboardKey.backspace):
            _guard(deleteSelection),
        const SingleActivator(LogicalKeyboardKey.escape): _guard(escape),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): save,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): save,
      },
      child: Focus(
        focusNode: _node,
        autofocus: true,
        child: widget.child,
      ),
    );
  }
}
