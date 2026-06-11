import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/player_icon.dart';
import '../models/sport_type.dart';
import '../models/sport_theme.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/purchase_service.dart';
import '../state/tactics_state.dart';
import '../ui_constants.dart';
import '../widgets/tactics_canvas.dart';
import '../widgets/toolbar.dart';
import '../widgets/sport_glyph.dart';
import '../widgets/language_picker.dart';
import '../widgets/photo_crop_editor.dart';
import '../widgets/timeline_editor.dart';
import '../models/practice.dart';
import '../services/practice_service.dart';
import 'practice_plan_page.dart';
import 'practice_run_page.dart';
import 'sport_selection_page.dart';

class TacticsBoardHomePage extends StatelessWidget {
  const TacticsBoardHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    context.locale;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final theme = context.select<TacticsState, SportTheme>((s) => s.sportType.theme);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.pageGradient,
          ),
        ),
        child: isLandscape ? _buildLandscape(context, topPad, bottomPad) : _buildPortrait(context, topPad, bottomPad),
      ),
    );
  }

  Widget _buildPortrait(BuildContext context, double topPad, double bottomPad) {
    return Column(
      children: [
        Expanded(child: _canvasStack(context, topPad)),
        _bottomBar(context, bottomPad),
      ],
    );
  }

  Widget _buildLandscape(BuildContext context, double topPad, double bottomPad) {
    return Row(
      children: [
        Expanded(child: _canvasStack(context, topPad)),
        Selector<TacticsState, ({bool visible, SportTheme theme})>(
          selector: (_, s) => (visible: s.toolbarVisible && !s.presentationMode, theme: s.sportType.theme),
          builder: (context, sel, _) => sel.visible
            ? SizedBox(
                width: 190,
                child: Material(
                  color: sel.theme.panelColor,
                  child: _landscapeSidePanel(context),
                ),
              )
            : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _canvasStack(BuildContext context, double topPad) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return DragTarget<PhotoDragData>(
      onAcceptWithDetails: (details) => _onPhotoDropped(context, details),
      builder: (ctx, candidate, rejected) => Stack(
      fit: StackFit.expand,
      children: [
        isLandscape
            ? const RotatedBox(quarterTurns: 1, child: TacticsCanvas())
            : const TacticsCanvas(),
        // Presentation mode swaps all editing chrome for a clean, locked
        // overlay; the normal board chrome is shown otherwise.
        Consumer<TacticsState>(
          builder: (context, state, _) {
            if (state.presentationMode) {
              return _PresentationOverlay(topPad: topPad);
            }
            // The selection edit bar spans the bottom width; the bottom
            // corner controls fade out while it's open so the panel never
            // overlaps the Half Court / zoom / fullscreen buttons.
            final editPanelOpen = !state.isAnimating &&
                !state.zoomMode &&
                (state.isDrawingMode ||
                    state.selectedStrokeId != null ||
                    state.selectedPlayerId != null);
            return Stack(
              fit: StackFit.expand,
              children: [
        if (!isSingleSportApp)
          Positioned(
            top: topPad + 8, left: 12,
            child: Selector<TacticsState, (String?, String?)>(
              selector: (_, s) => (s.editingFromPlan, s.runningPlanName),
              builder: (context, tuple, _) {
                final planName = tuple.$1;
                final runName = tuple.$2;
                final inPlanMode = planName != null || runName != null;
                return GestureDetector(
                  onTap: () async {
                    final state = context.read<TacticsState>();
                    if (runName != null) {
                      // Auto-save tactic edits made during a run, matching the
                      // plan-edit branch below.
                      if (state.currentTacticName != null) {
                        try {
                          await state.saveTactics(state.currentTacticName!);
                        } catch (_) {}
                      }
                      final startIdx = state.runningItemIndex;
                      state.runningPlanName = null;
                      state.editingFromPlan = null;
                      final p = await PracticeService.load(state.sportType, runName) ?? Practice(name: runName);
                      if (!context.mounted) return;
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PracticeRunPage(
                          state: state,
                          practice: p,
                          initialIndex: startIdx,
                        ),
                      ));
                      return;
                    }
                    if (planName != null) {
                      // Auto-save tactic edits made while in plan-edit mode, so
                      // the disk file (and cloud sync) pick up new players/moves
                      // without requiring a manual Save tap.
                      if (state.currentTacticName != null) {
                        try {
                          await state.saveTactics(state.currentTacticName!);
                        } catch (_) {}
                      }
                      state.editingFromPlan = null;
                      final p = await PracticeService.load(state.sportType, planName) ?? Practice(name: planName);
                      if (!context.mounted) return;
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PracticeEditPage(state: state, practice: p),
                      ));
                      return;
                    }
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const SportSelectionPage()),
                    );
                  },
                  child: _GlassCircle(
                    size: (32 * uiScale(context)).clamp(44.0, 60.0).toDouble(),
                    border: inPlanMode
                        ? Border.all(color: const Color(0xFF00C2B2), width: 1.5)
                        : null,
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: inPlanMode ? const Color(0xFF00C2B2) : Colors.white,
                      size: 16 * uiScale(context),
                    ),
                  ),
                );
              },
            ),
          ),
        Positioned(top: topPad + 8, right: 12, child: _MenuButton()),
        _CollapsibleEditPanel(),
        Positioned(
          bottom: 12, right: 12,
          child: IgnorePointer(
            ignoring: editPanelOpen,
            child: AnimatedOpacity(
              opacity: editPanelOpen ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 160),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ZoomResetButton(),
                  _ZoomModeButton(),
                  _FullscreenButton(),
                ],
              ),
            ),
          ),
        ),
        if (state.sportType == SportType.basketball)
          Positioned(
            bottom: 12, left: 12,
            child: IgnorePointer(
              ignoring: editPanelOpen,
              child: AnimatedOpacity(
                opacity: editPanelOpen ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 160),
                child: _HalfCourtButton(state: state),
              ),
            ),
          ),
              ],
            );
          },
        ),
      ],
      ),
    );
  }

  /// Drop handler for photos dragged from the My Teams strip — converts the
  /// global drop point into canvas coords and adds a player there.
  void _onPhotoDropped(BuildContext context, DragTargetDetails<PhotoDragData> details) {
    final state = context.read<TacticsState>();
    final ro = boardRepaintKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.attached) return;
    final localFromBoard = ro.globalToLocal(details.offset);
    final size = state.canvasSize;
    if (size.isEmpty) return;
    int max = 0;
    for (final p in state.players.where((p) => p.team == details.data.team)) {
      final n = int.tryParse(p.label) ?? 0;
      if (n > max) max = n;
    }
    final clamped = Offset(
      localFromBoard.dx.clamp(24.0, size.width - 24.0),
      localFromBoard.dy.clamp(24.0, size.height - 24.0),
    );
    state.addPlayer(PlayerIcon(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: '${max + 1}',
      team: details.data.team,
      position: clamped,
      photoId: details.data.photo.id,
    ));
    HapticFeedback.lightImpact();
  }

  Widget _bottomBar(BuildContext context, double bottomPad) {
    return Selector<TacticsState, ({bool visible, bool moves, bool present})>(
      selector: (_, s) => (visible: s.toolbarVisible, moves: s.hasMoves, present: s.presentationMode),
      builder: (context, sel, _) {
        // Presentation mode hides the whole toolbar/play bar — the locked
        // overlay carries its own large playback controls.
        if (sel.present) return SizedBox(height: bottomPad > 0 ? 36 : 20);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sel.visible)
              SizedBox(
                height: 48 * uiScale(context),
                child: sel.moves ? Center(child: PlayControlsBar(state: context.read<TacticsState>())) : null,
              ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: sel.visible ? const TacticsToolbar() : const SizedBox.shrink(),
            ),
            SizedBox(height: bottomPad > 0 ? 36 : 20),
          ],
        );
      },
    );
  }

  Widget _landscapeSidePanel(BuildContext context) {
    return Consumer<TacticsState>(
      builder: (context, state, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          children: [
            // Mode buttons
            Row(
              children: [
                Expanded(child: _lBtn('mode_move', !state.isDrawingMode, () => state.setDrawingMode(false))),
                const SizedBox(width: 6),
                Expanded(child: _lBtn('mode_draw', state.isDrawingMode, () => state.setDrawingMode(true))),
              ],
            ),
            const SizedBox(height: 10),
            // Undo / Redo — always reachable
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _lCircleBtn(Icons.undo, kAccent, state.canUndo ? state.undo : null),
                const SizedBox(width: 12),
                _lCircleBtn(Icons.redo, kAccent, state.canRedo ? state.redo : null),
              ],
            ),
            const SizedBox(height: 10),
            // Action buttons
            _lWideBtn(Icons.add, 'add_label', () => showAddElementSheet(context, state)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _lBtn('save', false, () => showSaveLoadSheet(context, state))),
                const SizedBox(width: 6),
                Expanded(child: _lBtn('share', false, () => shareBoardImage(context, state))),
              ],
            ),
            if (state.players.isNotEmpty || state.strokes.isNotEmpty) ...[
              const SizedBox(height: 6),
              _lWideBtn(Icons.delete_sweep, 'clear', () => confirmClearAll(context, state), color: Colors.redAccent),
            ],
            const Spacer(),
            // Play controls
            if (state.hasMoves) ...[
              const Divider(color: Colors.white12),
              const SizedBox(height: 4),
              // Step + controls in compact layout
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _lCircleBtn(Icons.skip_previous, Colors.blue, state.atStep > 0 ? state.stepBackward : null),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('${state.atStep}/${state.maxMoveSteps}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  _lCircleBtn(Icons.skip_next, Colors.blue, state.atStep < state.maxMoveSteps ? state.stepForward : null),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _lCircleBtn(Icons.replay, Colors.orange, state.atStep > 0 ? state.clearAnimatedPositions : null),
                  const SizedBox(width: 6),
                  _lCircleBtn(state.isAnimating ? Icons.stop : Icons.play_arrow, Colors.green, !state.isAnimating ? state.startAnimation : state.stopAnimation),
                  const SizedBox(width: 6),
                  _lCircleBtn(Icons.show_chart, state.showMoveLines ? Colors.white54 : Colors.redAccent, state.toggleShowMoveLines),
                  const SizedBox(width: 6),
                  _lCircleBtn(Icons.view_timeline, Colors.purpleAccent, () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF15303A),
                      isScrollControlled: true,
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (ctx) => scaledSheet(ctx, TimelineEditor(state: state)),
                    );
                  }),
                ],
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }


  Widget _lBtn(String key, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.blue : Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text(key.tr(), style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600))),
      ),
    );
  }

  Widget _lCircleBtn(IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap != null ? 1.0 : 0.35,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 17),
        ),
      ),
    );
  }

  Widget _lWideBtn(IconData icon, String key, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color ?? Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(key.tr(), style: TextStyle(color: color ?? Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// iOS-style frosted glass circular button — translucent fill on top of a
/// real-time backdrop blur. Used for top-corner chrome (back / menu / fullscreen).
class _GlassCircle extends StatelessWidget {
  final double size;
  final Widget child;
  final BoxBorder? border;
  const _GlassCircle({required this.size, required this.child, this.border});

  @override
  Widget build(BuildContext context) {
    // Shadow is drawn by the outer DecoratedBox so it's not clipped away by
    // ClipOval; the BackdropFilter blurs the field/board content underneath.
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              shape: BoxShape.circle,
              border: border,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    return PopupMenuButton<String>(
      onSelected: (value) => _onSelected(context, value),
      color: const Color(0xFF20424C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      child: _GlassCircle(
        size: (32 * s).clamp(44.0, 60.0).toDouble(),
        child: Icon(Icons.more_horiz, color: Colors.white, size: 18 * s),
      ),
      itemBuilder: (ctx) {
        final sport = ctx.read<TacticsState>().sportType;
        return [
          _menuItem(context, 'present', Icons.co_present_outlined, 'present_mode'.tr()),
          _menuItem(context, 'share', Icons.ios_share, 'share'.tr()),
          _menuItem(context, 'practice', Icons.event_note_outlined, 'practice_plan'.tr()),
          if (sport.scorerAppleId.isNotEmpty)
            _menuItem(context, 'scorer', Icons.scoreboard_outlined, 'menu_scorer'.tr()),
          _menuItem(context, 'language', Icons.language, 'menu_language'.tr()),
          _menuItem(context, 'contact', Icons.mail_outline, 'menu_contact'.tr()),
          if (PurchaseService.instance.isStoreEnabled &&
              AdService.instance.servesAds &&
              !PurchaseService.instance.hasPro)
            _menuItem(context, 'pro', Icons.workspace_premium_outlined,
                'menu_remove_ads'.tr()),
          _menuItem(context, 'login', Icons.person_outline, 'menu_login'.tr()),
        ];
      },
    );
  }

  PopupMenuItem<String> _menuItem(BuildContext context, String value, IconData icon, String label) {
    final s = uiScale(context);
    return PopupMenuItem(
      value: value,
      height: 44 * s,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20 * s),
          SizedBox(width: 12 * s),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 14 * s)),
        ],
      ),
    );
  }

  void _onSelected(BuildContext context, String value) {
    switch (value) {
      case 'present':
        context.read<TacticsState>().togglePresentationMode();
      case 'share':
        shareBoardImage(context, context.read<TacticsState>());
      case 'practice':
        _showPracticePlan(context);
      case 'scorer':
        _showScorer(context);
      case 'language':
        LanguagePicker.show(context);
      case 'contact':
        _showContact(context);
      case 'login':
        _showLogin(context);
      case 'pro':
        _showPaywall(context);
    }
  }

  void _showPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15303A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _PaywallSheet(),
    );
  }

  void _showPracticePlan(BuildContext context) {
    final state = context.read<TacticsState>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PracticePlanPage(state: state),
    ));
  }

  void _showScorer(BuildContext context) {
    final state = context.read<TacticsState>();
    final sport = state.sportType;
    final appName = sport.scorerAppName;
    final appleId = sport.scorerAppleId;
    if (appleId.isEmpty) return; // not yet on App Store
    final url = Uri.parse('https://apps.apple.com/app/id$appleId');
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15303A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => scaledSheet(ctx, _ScorerPromoSheet(sport: sport, appName: appName, url: url)),
    );
  }

  void _showContact(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _ContactPage()),
    );
  }

  void _showLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _LoginPage()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact Us page — email form via API (same as ScoreSyncer/zach_base)
// ─────────────────────────────────────────────────────────────────────────────
class _ContactPage extends StatefulWidget {
  const _ContactPage();
  @override
  State<_ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<_ContactPage> {
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    // Validation
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('your_email'.tr() + ' required')));
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('send_email_error'.tr())));
      return;
    }
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('message'.tr() + ' required')));
      return;
    }
    final sport = context.read<TacticsState>().sportType;
    final appName = isSingleSportApp ? _flavorAppName(sport) : 'Tactics Board';

    setState(() => _sending = true);
    try {
      final response = await http.post(
        Uri.parse('https://tacticsboard.100for1.com/api/v1/send-email'),
        body: {
          'from': 'support@ScoreSyncer.com',
          'to': 'zachsong@gmail.com',
          'email': email,
          'sport': sport.name,
          'app': appName,
          'subject': _subjectCtrl.text.trim().isEmpty ? 'Feedback' : _subjectCtrl.text.trim(),
          'message': body,
        },
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('send_success'.tr()), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('send_failed'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('send_failed'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3A4A),
      appBar: AppBar(
        title: Text('contact_title'.tr()),
        backgroundColor: const Color(0xFF15303A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('contact_subtitle'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 20),
            _field(_emailCtrl, 'your_email'.tr(), TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(_subjectCtrl, 'subject'.tr()),
            const SizedBox(height: 12),
            _field(_bodyCtrl, 'message'.tr(), null, 5),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('send'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  String _flavorAppName(SportType s) {
    switch (s) {
      case SportType.badminton:    return 'Badminton Board';
      case SportType.tableTennis:  return 'Table Tennis Board';
      case SportType.tennis:       return 'Tennis Board';
      case SportType.basketball:   return 'Basketball Board';
      case SportType.volleyball:   return 'Volleyball Board';
      case SportType.pickleball:   return 'Pickleball Board';
      case SportType.soccer:       return 'Soccer Board';
      case SportType.fieldHockey:  return 'Field Hockey Board';
      case SportType.rugby:        return 'Rugby Board';
      case SportType.baseball:     return 'Baseball Board';
      case SportType.handball:     return 'Handball Board';
      case SportType.waterPolo:    return 'Water Polo Board';
      case SportType.sepakTakraw:  return 'Sepak Takraw Board';
      case SportType.beachTennis:  return 'Beach Tennis Board';
      case SportType.footvolley:   return 'Footvolley Board';
    }
  }

  Widget _field(TextEditingController ctrl, String label, [TextInputType? type, int maxLines = 1]) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login page — Apple + Google sign-in (same pattern as lang1000/chinesefriend)
// ─────────────────────────────────────────────────────────────────────────────
class _LoginPage extends StatefulWidget {
  const _LoginPage();
  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  final _auth = AuthService.instance;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    CloudSyncService.statusTick.addListener(_onStatusChange);
    if (_auth.isLoggedIn) {
      // Background probe so the status row reflects server state without
      // forcing a full sync.
      CloudSyncService.probeRemote();
    }
  }

  @override
  void dispose() {
    CloudSyncService.statusTick.removeListener(_onStatusChange);
    super.dispose();
  }

  void _onStatusChange() {
    if (mounted) setState(() {});
  }

  Future<void> _manualSync() async {
    setState(() => _loading = true);
    await CloudSyncService.syncNow();
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('sync_done'.tr()), backgroundColor: Colors.green),
    );
  }

  Future<void> _loginWithApple() async {
    setState(() => _loading = true);
    final result = await _auth.loginWithApple();
    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'welcome'.tr()}, ${result.name ?? result.email ?? 'User'}!'), backgroundColor: Colors.green),
      );
      // Keep spinner on while we pull cloud data so the user doesn't see a
      // half-populated screen if they navigate away immediately.
      await CloudSyncService.syncNow();
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pop(context);
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result.error ?? 'login_failed').tr())),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    final result = await _auth.loginWithGoogle();
    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'welcome'.tr()}, ${result.name ?? result.email ?? 'User'}!'), backgroundColor: Colors.green),
      );
      await CloudSyncService.syncNow();
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pop(context);
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result.error ?? 'login_failed').tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = _auth.isLoggedIn;

    return Scaffold(
      backgroundColor: const Color(0xFF1A3A4A),
      appBar: AppBar(
        title: Text('login_title'.tr()),
        backgroundColor: const Color(0xFF15303A),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: loggedIn ? _buildLoggedIn() : _buildSignIn(),
        ),
      ),
    );
  }

  Widget _buildLoggedIn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 80),
        const SizedBox(height: 16),
        Text(_auth.userName ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        if (_auth.userEmail != null)
          Text(_auth.userEmail!, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 28),
        _buildSyncStatus(),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_loading || CloudSyncService.isSyncing)
                ? null
                : _manualSync,
            icon: const Icon(Icons.cloud_sync),
            label: Text('sync_now'.tr(),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A65A5),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
              disabledForegroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _auth.logout();
              CloudSyncService.reset();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('logout'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 40),
        TextButton(
          onPressed: _confirmDeleteAccount,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white38,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'delete_account'.tr(),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncStatus() {
    final syncing = CloudSyncService.isSyncing;
    final local = CloudSyncService.hasLocalPendingChanges;
    final remote = CloudSyncService.hasRemoteUpdates;
    final last = CloudSyncService.lastSyncAt;

    IconData icon;
    Color color;
    String primary;
    if (syncing) {
      icon = Icons.sync;
      color = const Color(0xFF7FC8FF);
      primary = 'sync_status_syncing'.tr();
    } else if (local && remote) {
      icon = Icons.sync_problem;
      color = const Color(0xFFFFB74D);
      primary = 'sync_status_both_dirty'.tr();
    } else if (local) {
      icon = Icons.cloud_upload;
      color = const Color(0xFFFFB74D);
      primary = 'sync_status_local_dirty'.tr();
    } else if (remote) {
      icon = Icons.cloud_download;
      color = const Color(0xFFFFB74D);
      primary = 'sync_status_remote_dirty'.tr();
    } else if (last == null) {
      icon = Icons.cloud_off;
      color = Colors.white54;
      primary = 'sync_status_never'.tr();
    } else {
      icon = Icons.cloud_done;
      color = const Color(0xFF80D88A);
      primary = 'sync_status_synced'.tr();
    }

    final secondary = last != null
        ? 'sync_last'.tr(args: [_formatRelativeTime(last)])
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(primary,
                    style: TextStyle(
                        color: color, fontSize: 14, fontWeight: FontWeight.w600)),
                if (secondary != null) ...[
                  const SizedBox(height: 2),
                  Text(secondary,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'time_just_now'.tr();
    if (diff.inHours < 1) {
      return 'time_minutes_ago'.tr(args: [diff.inMinutes.toString()]);
    }
    if (diff.inDays < 1) {
      return 'time_hours_ago'.tr(args: [diff.inHours.toString()]);
    }
    return 'time_days_ago'.tr(args: [diff.inDays.toString()]);
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF15303A),
        title: Text('delete_account'.tr(), style: const TextStyle(color: Colors.white)),
        content: Text('delete_account_confirm'.tr(), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _loading = true);
              try {
                final response = await http.delete(
                  Uri.parse('https://tacticsboard.100for1.com/api/v1/auth/delete-account'),
                  headers: {'Authorization': 'Bearer ${_auth.token}', 'Accept': 'application/json'},
                );
                _auth.logout();
                if (mounted) {
                  setState(() => _loading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response.statusCode == 200 ? 'delete_account_success'.tr() : 'delete_account_failed'.tr())),
                  );
                }
              } catch (_) {
                _auth.logout();
                if (mounted) setState(() => _loading = false);
              }
            },
            child: Text('delete_account'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSignIn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.person_outline, color: Colors.white38, size: 80),
        const SizedBox(height: 24),
        Text('login_subtitle'.tr(),
            style: TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        if (_loading)
          const CircularProgressIndicator()
        else ...[
          // Apple Sign In
          _signInButton(
            icon: Icons.apple,
            label: 'login_apple'.tr(),
            color: Colors.white,
            bgColor: Colors.black,
            onTap: _loginWithApple,
          ),
          const SizedBox(height: 14),
          // Google Sign In
          _signInButton(
            icon: Icons.g_mobiledata,
            label: 'login_google'.tr(),
            color: Colors.black87,
            bgColor: Colors.white,
            onTap: _loginWithGoogle,
          ),
        ],
      ],
    );
  }

  Widget _signInButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ScoreSyncer promotion bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ScorerPromoSheet extends StatelessWidget {
  final SportType sport;
  final String appName;
  final Uri url;
  const _ScorerPromoSheet({required this.sport, required this.appName, required this.url});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App icon area
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: SportGlyph(sport: sport, size: 46),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              appName,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'scorer_description'.tr(),
              style: const TextStyle(color: Colors.white60, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Feature highlights
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _featureChip(Icons.scoreboard, 'scorer_feature_score'.tr()),
                const SizedBox(width: 8),
                _featureChip(Icons.timer, 'scorer_feature_timer'.tr()),
                const SizedBox(width: 8),
                _featureChip(Icons.history, 'scorer_feature_history'.tr()),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openAppStore(context),
                icon: const Icon(Icons.download, size: 20),
                label: Text('scorer_download'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            // Badminton-only training companion apps
            if (sport == SportType.badminton) ...[
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'trainer_also_try'.tr(),
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              _trainerRow(context, Icons.bolt, 'trainer_whip_name'.tr(),
                  'trainer_whip_desc'.tr(), 'https://apps.apple.com/app/id6775930960'),
              const SizedBox(height: 8),
              _trainerRow(context, Icons.directions_run, 'trainer_footwork_name'.tr(),
                  'trainer_footwork_desc'.tr(), 'https://apps.apple.com/app/id6777419248'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _trainerRow(BuildContext context, IconData icon, String name, String desc, String urlStr) {
    return InkWell(
      onTap: () => _openLink(context, urlStr),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white70, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _openAppStore(BuildContext context) => _openLink(context, url.toString());

  Future<void> _openLink(BuildContext context, String urlStr) async {
    try {
      const channel = MethodChannel('com.zach.tacticsboard/share');
      await channel.invokeMethod('openUrl', {'url': urlStr});
    } catch (_) {
      // Fallback: copy URL to clipboard
      await Clipboard.setData(ClipboardData(text: urlStr));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('scorer_link_copied'.tr()), backgroundColor: Colors.green),
        );
      }
    }
    if (context.mounted) Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Player/Marker edit bar — shown when a player element is selected
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerEditBar extends StatefulWidget {
  final TacticsState state;
  final PlayerIcon player;
  /// When set, the close × and delete actions invoke this in addition to
  /// their usual behaviour.
  final VoidCallback? onClose;
  const _PlayerEditBar({
    required this.state,
    required this.player,
    this.onClose,
  });

  @override
  State<_PlayerEditBar> createState() => _PlayerEditBarState();
}

class _PlayerEditBarState extends State<_PlayerEditBar> {
  /// Colour palette + size slider stay collapsed by default — they are
  /// low-frequency next to move / run / delete, so they don't crowd the
  /// bar until the user taps the tune button to ask for them.
  bool _expanded = false;

  static const _colors = <Color>[
    Color(0xFF3A7DFF),
    Color(0xFFFF5A5F),
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFFAD1457),
    Color(0xFFF9A825),
  ];

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1 — core actions, always visible.
          Row(
            children: [
              // Player indicator
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: p.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: kAccent, width: 2),
                ),
                child: p.label.length <= 2 && p.label.isNotEmpty
                    ? Center(child: Text(p.label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1)))
                    : null,
              ),
              if (p.label.length > 2) ...[
                const SizedBox(width: 6),
                Text(p.label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
              const Spacer(),
              // Explicit add-run toggle — while on, taps on the board lay
              // this player's movement path (so a stray tap never can).
              _MoveToggle(state: widget.state),
              const SizedBox(width: 8),
              // Colour + size — collapsed by default; this reveals Row 2.
              _editAction(
                Icons.tune,
                _expanded ? kAccent : Colors.white60,
                () => setState(() => _expanded = !_expanded),
              ),
              const SizedBox(width: 8),
              // Adjust photo crop — only visible when the player is using a
              // user-uploaded face avatar.
              if (p.photoId != null) ...[
                _editAction(Icons.crop, kAccent, () {
                  PhotoCropEditor.show(context, photoId: p.photoId!);
                }),
                const SizedBox(width: 8),
              ],
              // Delete
              _editAction(Icons.delete, kDanger, () {
                widget.state.removePlayer(p.id);
                widget.onClose?.call();
              }),
              const SizedBox(width: 8),
              // Close (deselect).
              GestureDetector(
                onTap: () {
                  widget.state.selectPlayer(null);
                  widget.onClose?.call();
                },
                child: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            ],
          ),
          // Row 2 — colour swatches + size slider, revealed on demand.
          if (_expanded) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                ..._colors.map((c) => GestureDetector(
                  onTap: () {
                    widget.state.updatePlayer(p.id, customColor: c);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c,
                      border: Border.all(
                        color: p.customColor == c ? kAccent : Colors.white24,
                        width: p.customColor == c ? 2.5 : 1,
                      ),
                    ),
                  ),
                )),
                const Spacer(),
                // Size slider compact
                const Icon(Icons.photo_size_select_small, color: Colors.white38, size: 14),
                SizedBox(
                  width: 100,
                  child: Slider(
                    value: p.scale,
                    min: 0.5,
                    max: 3.0,
                    divisions: 10,
                    activeColor: kAccent,
                    inactiveColor: Colors.white24,
                    onChanged: (v) {
                      widget.state.updatePlayer(p.id, scale: v);
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _editAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collapsible edit panel — drawing options / player edit with collapse toggle
// ─────────────────────────────────────────────────────────────────────────────
class _CollapsibleEditPanel extends StatefulWidget {
  @override
  State<_CollapsibleEditPanel> createState() => _CollapsibleEditPanelState();
}

class _CollapsibleEditPanelState extends State<_CollapsibleEditPanel> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TacticsState>(
      builder: (context, state, _) {
        if (state.isAnimating || state.presentationMode || state.zoomMode) {
          return const SizedBox.shrink();
        }

        final hasDrawing = state.isDrawingMode || state.selectedStrokeId != null;
        final hasPlayer = state.selectedPlayerId != null;
        if (!hasDrawing && !hasPlayer) return const SizedBox.shrink();

        // The edit surface is shown inline, anchored just above the toolbar —
        // no extra ⚙ tap, no modal dialog. One unified, always-visible bar.
        Widget child;
        if (hasDrawing) {
          child = DrawingOptionsBar(state: state, showOptions: true);
        } else {
          final player = state.players.cast<PlayerIcon?>().firstWhere(
            (p) => p?.id == state.selectedPlayerId,
            orElse: () => null,
          );
          if (player == null) return const SizedBox.shrink();
          child = _PlayerEditBar(
            state: state,
            player: player,
            onClose: () => state.selectPlayer(null),
          );
        }
        return Positioned(
          left: 8, right: 8, bottom: 10,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Material(
                color: kSurfaceHi,
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Add-run toggle — explicit sub-mode entry shown in the player edit bar.
// While on, board taps lay this player's run; while off a tap only deselects.
// ─────────────────────────────────────────────────────────────────────────────
class _MoveToggle extends StatelessWidget {
  final TacticsState state;
  const _MoveToggle({required this.state});

  @override
  Widget build(BuildContext context) {
    final on = state.isAddingMove;
    return GestureDetector(
      onTap: () {
        state.setAddingMove(!on);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: on ? kAccent : kAccentFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kAccent, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(on ? Icons.check : Icons.directions_run,
                size: 14, color: on ? Colors.white : kAccent),
            const SizedBox(width: 4),
            Text(on ? 'move_done'.tr() : 'move_add'.tr(),
                style: TextStyle(
                    color: on ? Colors.white : kAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom-right chrome — fullscreen toggle + reset-zoom (only while zoomed).
// ─────────────────────────────────────────────────────────────────────────────
class _FullscreenButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<TacticsState, bool>(
      selector: (_, s) => s.toolbarVisible,
      builder: (context, visible, _) => GestureDetector(
        onTap: context.read<TacticsState>().toggleToolbar,
        child: _GlassCircle(
          size: (32 * uiScale(context)).clamp(44.0, 60.0).toDouble(),
          child: Icon(visible ? Icons.fullscreen : Icons.fullscreen_exit,
              color: Colors.white, size: 18 * uiScale(context)),
        ),
      ),
    );
  }
}

/// Appears only while the board is zoomed/panned — one tap restores the
/// 1:1 fit (and clears the basketball half-court preset).
class _ZoomResetButton extends StatefulWidget {
  @override
  State<_ZoomResetButton> createState() => _ZoomResetButtonState();
}

class _ZoomResetButtonState extends State<_ZoomResetButton> {
  TransformationController? _ctrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = context.read<TacticsState>().transformationController;
    if (c != _ctrl) {
      _ctrl?.removeListener(_onChange);
      _ctrl = c;
      c.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    _ctrl?.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<TacticsState>();
    final zoomed = state.transformationController.value != Matrix4.identity();
    if (!zoomed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          state.resetZoom();
          state.setBasketballHalfCourt(false);
        },
        child: _GlassCircle(
          size: (32 * uiScale(context)).clamp(44.0, 60.0).toDouble(),
          child: Icon(Icons.zoom_out_map,
              color: Colors.white, size: 17 * uiScale(context)),
        ),
      ),
    );
  }
}

/// Basketball-only — toggles a zoom preset focused on the home half of the
/// court, where most set-play coaching happens.
class _HalfCourtButton extends StatelessWidget {
  final TacticsState state;
  const _HalfCourtButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final on = state.basketballHalfCourt;
    return GestureDetector(
      onTap: () {
        final next = !on;
        state.setBasketballHalfCourt(next);
        if (next) {
          final sz = state.canvasSize;
          if (sz.width <= 0 || sz.height <= 0) return;
          const frac = 0.58; // show the home 58% of the court
          final s = 1 / frac;
          state.transformationController.value = Matrix4.identity()
            ..translate(-sz.width * (s - 1) / 2, -s * (1 - frac) * sz.height)
            ..scale(s);
        } else {
          state.resetZoom();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(16),
          border: on ? Border.all(color: kAccent, width: 1.2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.straighten,
                size: 14, color: on ? kAccent : Colors.white),
            const SizedBox(width: 5),
            Text(on ? 'full_court'.tr() : 'half_court'.tr(),
                style: TextStyle(
                    color: on ? kAccent : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Presentation overlay — a locked, clean board for showing players a play.
// All editing is disabled; only playback + an exit affordance remain.
// ─────────────────────────────────────────────────────────────────────────────
class _PresentationOverlay extends StatelessWidget {
  final double topPad;
  const _PresentationOverlay({required this.topPad});

  @override
  Widget build(BuildContext context) {
    final state = context.read<TacticsState>();
    return Stack(
      fit: StackFit.expand,
      children: [
        // Exit pill — top center.
        Positioned(
          top: topPad + 10, left: 0, right: 0,
          child: Center(
            child: GestureDetector(
              onTap: state.togglePresentationMode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: kAccent.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.close, color: kAccent, size: 18),
                    const SizedBox(width: 6),
                    Text('present_exit'.tr(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Large playback controls — bottom center, only when there are moves.
        if (state.hasMoves)
          Positioned(
            bottom: 28, left: 0, right: 0,
            child: Center(child: _BigPlayControls(state: state)),
          ),
      ],
    );
  }
}

/// Oversized, glance-and-tap playback controls used in presentation mode.
class _BigPlayControls extends StatelessWidget {
  final TacticsState state;
  const _BigPlayControls({required this.state});

  @override
  Widget build(BuildContext context) {
    final animating = state.isAnimating;
    final atStart = state.atStep <= 0;
    final atEnd = state.atStep >= state.maxMoveSteps;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _bigBtn(Icons.skip_previous,
              (!animating && !atStart) ? state.stepBackward : null),
          const SizedBox(width: 10),
          _bigBtn(
            animating ? Icons.stop : Icons.play_arrow,
            animating ? state.stopAnimation : state.startAnimation,
            primary: true,
          ),
          const SizedBox(width: 12),
          Text('${state.atStep}/${state.maxMoveSteps}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          _bigBtn(Icons.skip_next,
              (!animating && !atEnd) ? state.stepForward : null),
          const SizedBox(width: 10),
          // Toggle the move-arrow overlay while presenting — show the end
          // position first, then reveal how each player got there.
          GestureDetector(
            onTap: () {
              state.toggleShowMoveLines();
              HapticFeedback.selectionClick();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.showMoveLines
                    ? Colors.white.withValues(alpha: 0.14)
                    : kDanger.withValues(alpha: 0.25),
              ),
              child: Icon(
                state.showMoveLines ? Icons.timeline : Icons.visibility_off,
                color: state.showMoveLines ? Colors.white : kDanger,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigBtn(IconData icon, VoidCallback? onTap, {bool primary = false}) {
    final size = primary ? 58.0 : 48.0;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1.0,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary ? kAccent : Colors.white.withValues(alpha: 0.14),
          ),
          child: Icon(icon, color: Colors.white, size: primary ? 34 : 28),
        ),
      ),
    );
  }
}

/// Toggles free-form zoom/pan mode. While on, the board content is locked
/// and pinch/drag operate the InteractiveViewer — so zooming can never be
/// confused with dragging a player. Tap off to edit at the new zoom level.
class _ZoomModeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<TacticsState, bool>(
      selector: (_, s) => s.zoomMode,
      builder: (context, on, _) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: context.read<TacticsState>().toggleZoomMode,
          child: _GlassCircle(
            size: (32 * uiScale(context)).clamp(44.0, 60.0).toDouble(),
            border: on ? Border.all(color: kAccent, width: 1.5) : null,
            child: Icon(Icons.pinch,
                color: on ? kAccent : Colors.white,
                size: 17 * uiScale(context)),
          ),
        ),
      ),
    );
  }
}

/// "Remove Ads" paywall — a professional in-app-purchase sheet: premium badge,
/// title + value line, a 3-up benefits card, selectable plan cards (yearly
/// preselected, with a "recommended" badge + per-month price), a prominent
/// gradient primary CTA, a secondary Restore link, the App Store-required
/// auto-renew disclosure, and Terms / Privacy links. Selecting a plan only
/// changes [_selectedId]; the CTA buys it. Buying or restoring flips
/// PurchaseService.hasPro, which AdService reads live to disable every ad.
class _PaywallSheet extends StatefulWidget {
  const _PaywallSheet();

  @override
  State<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<_PaywallSheet> {
  static final Uri _termsUrl =
      Uri.parse('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/');
  static final Uri _privacyUrl = Uri.parse('https://tacticsboard.100for1.com/privacy');

  List<ProductDetails>? _products;
  String? _selectedId;
  bool _loading = true;
  bool _busy = false; // a purchase/restore is in flight

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final products = await PurchaseService.instance.productList();
    if (!mounted) return;
    setState(() {
      _products = products;
      // Preselect the yearly plan (the recommended entry point).
      _selectedId = _byId(PurchaseService.yearlyId) != null
          ? PurchaseService.yearlyId
          : (products != null && products.isNotEmpty ? products.first.id : null);
      _loading = false;
    });
  }

  ProductDetails? _byId(String? id) {
    if (id == null) return null;
    for (final p in _products ?? const <ProductDetails>[]) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> _buySelected() async {
    final product = _byId(_selectedId);
    if (product == null) return;
    setState(() => _busy = true);
    bool pro = false;
    try {
      pro = await PurchaseService.instance.buy(product);
    } catch (_) {
      if (mounted) _toast('pro_purchase_failed'.tr());
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (pro) _done();
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final pro = await PurchaseService.instance.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    if (pro) {
      _done();
    } else {
      _toast('pro_restore_none'.tr());
    }
  }

  void _done() {
    _toast('pro_thanks'.tr());
    Navigator.of(context).pop();
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  /// "≈ ¥1.83 / mo" derived from the yearly plan's localized store price.
  String? _perMonth(ProductDetails y) {
    final m = y.rawPrice / 12;
    if (m <= 0) return null;
    return 'pro_permonth'.tr(
        namedArgs: {'p': '${y.currencySymbol}${m.toStringAsFixed(2)}'});
  }

  @override
  Widget build(BuildContext context) {
    final lifetime = _byId(PurchaseService.lifetimeId);
    final yearly = _byId(PurchaseService.yearlyId);
    final hasYearly = yearly != null;
    return SafeArea(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Center(child: _badge()),
                const SizedBox(height: 16),
                Text('pro_title'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2)),
                const SizedBox(height: 8),
                Text('pro_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 13.5, height: 1.35)),
                const SizedBox(height: 20),
                _benefits(),
                const SizedBox(height: 18),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator(color: kAccent)),
                  )
                else if (lifetime == null && yearly == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text('pro_unavailable'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54)),
                  )
                else ...[
                  if (yearly != null)
                    _planCard(
                      yearly,
                      icon: Icons.calendar_month_outlined,
                      title: 'pro_plan_yearly_t'.tr(),
                      desc: 'pro_plan_yearly_d'.tr(),
                      priceSub: _perMonth(yearly),
                      badge: 'pro_badge'.tr(),
                    ),
                  if (yearly != null && lifetime != null)
                    const SizedBox(height: 12),
                  if (lifetime != null)
                    _planCard(
                      lifetime,
                      icon: Icons.diamond_outlined,
                      title: 'pro_plan_lifetime_t'.tr(),
                      desc: 'pro_plan_lifetime_d'.tr(),
                      priceSub: 'pro_lifetime_tag'.tr(),
                    ),
                  const SizedBox(height: 18),
                  _cta(),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      onPressed: _busy ? null : _restore,
                      child: Text('pro_restore'.tr(),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                  ),
                  if (hasYearly) ...[
                    const SizedBox(height: 2),
                    Text('pro_legal'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11, height: 1.45)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _link('pro_terms'.tr(), _termsUrl),
                      const Text('    ·    ',
                          style: TextStyle(color: Colors.white24, fontSize: 12)),
                      _link('pro_privacy'.tr(), _privacyUrl),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 6,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 22),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge() {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kAccentFill, Color(0x142B8AE0)],
        ),
        border: Border.all(color: kAccent.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
              color: kAccent.withValues(alpha: 0.25),
              blurRadius: 22,
              spreadRadius: -4),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Icon(Icons.shield, color: kAccent, size: 44),
          Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.star_rounded, color: Color(0xFF06262B), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _benefits() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: kSurfaceHi,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _benefit(Icons.do_not_disturb_on_outlined, 'pro_b1_t'.tr(), 'pro_b1_s'.tr()),
          _benefitDivider(),
          _benefit(Icons.insights_outlined, 'pro_b2_t'.tr(), 'pro_b2_s'.tr()),
          _benefitDivider(),
          _benefit(Icons.cloud_sync_outlined, 'pro_b3_t'.tr(), 'pro_b3_s'.tr()),
        ],
      ),
    );
  }

  Widget _benefitDivider() =>
      Container(width: 1, height: 44, color: Colors.white10);

  Widget _benefit(IconData icon, String title, String sub) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Icon(icon, color: kAccent, size: 24),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(sub,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 10.5, height: 1.25)),
          ],
        ),
      ),
    );
  }

  Widget _planCard(
    ProductDetails p, {
    required IconData icon,
    required String title,
    required String desc,
    String? priceSub,
    String? badge,
  }) {
    final selected = _selectedId == p.id;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: _busy ? null : () => setState(() => _selectedId = p.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
            decoration: BoxDecoration(
              color: selected ? kAccentFill : kSurfaceHi,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selected ? kAccent : Colors.white12,
                  width: selected ? 1.6 : 1),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: kAccent.withValues(alpha: 0.18),
                          blurRadius: 16,
                          spreadRadius: -6),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                _radio(selected),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: selected ? kAccentFill : Colors.white10,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon,
                      color: selected ? kAccent : Colors.white70, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(p.price,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    if (priceSub != null) ...[
                      const SizedBox(height: 2),
                      Text(priceSub,
                          style: TextStyle(
                              color: selected ? kAccent : Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: const BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(12)),
              ),
              child: Text(badge,
                  style: const TextStyle(
                      color: Color(0xFF06262B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }

  Widget _radio(bool selected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: selected ? kAccent : Colors.white38,
            width: selected ? 6.5 : 1.6),
      ),
    );
  }

  Widget _cta() {
    final enabled = !_busy && _selectedId != null;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2B8AE0), kAccent],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: kAccent.withValues(alpha: 0.30),
                blurRadius: 18,
                spreadRadius: -6,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? _buySelected : null,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_open_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text('pro_cta'.tr(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _link(String label, Uri url) {
    return GestureDetector(
      onTap: () => launchUrl(url, mode: LaunchMode.externalApplication),
      child: Text(label,
          style: const TextStyle(color: Colors.white38, fontSize: 12)),
    );
  }
}
