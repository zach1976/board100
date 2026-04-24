import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/player_icon.dart';
import '../models/sport_type.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../state/tactics_state.dart';
import '../widgets/tactics_canvas.dart';
import '../widgets/toolbar.dart';
import '../widgets/language_picker.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFF213E48),
      body: isLandscape ? _buildLandscape(context, topPad, bottomPad) : _buildPortrait(context, topPad, bottomPad),
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
        Selector<TacticsState, bool>(
          selector: (_, s) => s.toolbarVisible,
          builder: (context, visible, _) => visible
            ? SizedBox(
                width: 190,
                child: Material(
                  color: const Color(0xFF213E48),
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
    return Stack(
      fit: StackFit.expand,
      children: [
        isLandscape
            ? const RotatedBox(quarterTurns: 1, child: TacticsCanvas())
            : const TacticsCanvas(),
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
                  child: Container(
                    width: 32 * uiScale(context), height: 32 * uiScale(context),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: inPlanMode
                          ? Border.all(color: const Color(0xFF00E5CC), width: 1.5)
                          : null,
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: inPlanMode ? const Color(0xFF00E5CC) : Colors.white70,
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
          child: Selector<TacticsState, bool>(
            selector: (_, s) => s.toolbarVisible,
            builder: (context, visible, _) => GestureDetector(
              onTap: context.read<TacticsState>().toggleToolbar,
              child: Container(
                width: 32 * uiScale(context), height: 32 * uiScale(context),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                child: Icon(visible ? Icons.fullscreen : Icons.fullscreen_exit, color: Colors.white70, size: 18 * uiScale(context)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(BuildContext context, double bottomPad) {
    return Selector<TacticsState, ({bool visible, bool drawing, bool moves, int steps, int atStep, bool animating})>(
      selector: (_, s) => (visible: s.toolbarVisible, drawing: s.isDrawingMode, moves: s.hasMoves, steps: s.maxMoveSteps, atStep: s.atStep, animating: s.isAnimating),
      builder: (context, sel, _) => Column(
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
      ),
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
                      backgroundColor: const Color(0xFF213E48),
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

class _MenuButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    return PopupMenuButton<String>(
      onSelected: (value) => _onSelected(context, value),
      color: const Color(0xFF2A4D58),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      child: Container(
        width: 32 * s,
        height: 32 * s,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.more_horiz, color: Colors.white70, size: 18 * s),
      ),
      itemBuilder: (ctx) {
        final sport = ctx.read<TacticsState>().sportType;
        return [
          _menuItem(context, 'practice', Icons.event_note_outlined, 'practice_plan'.tr()),
          if (sport.scorerAppleId.isNotEmpty)
            _menuItem(context, 'scorer', Icons.scoreboard_outlined, 'menu_scorer'.tr()),
          _menuItem(context, 'language', Icons.language, 'menu_language'.tr()),
          _menuItem(context, 'contact', Icons.mail_outline, 'menu_contact'.tr()),
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
    }
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
      backgroundColor: const Color(0xFF213E48),
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
        backgroundColor: const Color(0xFF213E48),
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
        backgroundColor: const Color(0xFF213E48),
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
        backgroundColor: const Color(0xFF213E48),
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
                child: Text(sport.emoji, style: const TextStyle(fontSize: 40)),
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

  Future<void> _openAppStore(BuildContext context) async {
    try {
      const channel = MethodChannel('com.zach.tacticsboard/share');
      await channel.invokeMethod('openUrl', {'url': url.toString()});
    } catch (_) {
      // Fallback: copy URL to clipboard
      await Clipboard.setData(ClipboardData(text: url.toString()));
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
  const _PlayerEditBar({required this.state, required this.player});

  @override
  State<_PlayerEditBar> createState() => _PlayerEditBarState();
}

class _PlayerEditBarState extends State<_PlayerEditBar> {
  static const _colors = <Color>[
    Color(0xFF1565C0),
    Color(0xFFC62828),
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
          // Row 1: label + actions
          Row(
            children: [
              // Player indicator
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: p.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.yellow, width: 2),
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
              // Delete
              _editAction(Icons.delete, Colors.redAccent, () {
                widget.state.removePlayer(p.id);
              }),
              const SizedBox(width: 8),
              // Deselect
              GestureDetector(
                onTap: () => widget.state.selectPlayer(null),
                child: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: color swatches
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
                      color: p.customColor == c ? Colors.yellow : Colors.white24,
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
                  activeColor: const Color(0xFF00E5CC),
                  inactiveColor: Colors.white24,
                  onChanged: (v) {
                    widget.state.updatePlayer(p.id, scale: v);
                  },
                ),
              ),
            ],
          ),
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
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<TacticsState>(
      builder: (context, state, _) {
        if (state.isAnimating) return const SizedBox.shrink();

        Widget? panel;
        bool pinTop = false;
        if (state.isDrawingMode || state.selectedStrokeId != null) {
          panel = DrawingOptionsBar(state: state);
        } else if (state.selectedPlayerId != null) {
          final player = state.players.cast<PlayerIcon?>().firstWhere(
            (p) => p?.id == state.selectedPlayerId, orElse: () => null);
          if (player != null) {
            panel = _PlayerEditBar(state: state, player: player);
            final h = state.canvasSize.height;
            if (h > 0 && player.position.dy > h * 0.5) {
              pinTop = true;
            }
          }
        }

        if (panel == null) {
          _collapsed = false;
          return const SizedBox.shrink();
        }

        final topPad = MediaQuery.of(context).padding.top;
        return Positioned(
          top: pinTop ? topPad + 52 : null,
          bottom: pinTop ? null : 0,
          left: 0, right: 0,
          child: Container(
            color: const Color(0xDD1A2035),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Collapse/expand toggle bar
                GestureDetector(
                  onTap: () => setState(() => _collapsed = !_collapsed),
                  child: Builder(builder: (ctx) {
                    final s = uiScale(ctx);
                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 8 * s, horizontal: 16 * s),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            pinTop
                                ? (_collapsed ? Icons.expand_more : Icons.expand_less)
                                : (_collapsed ? Icons.expand_less : Icons.expand_more),
                            color: Colors.white54, size: 22 * s,
                          ),
                          SizedBox(width: 6 * s),
                          Text(
                            (_collapsed ? 'more' : 'less').tr(),
                            style: TextStyle(color: Colors.white54, fontSize: 12 * s, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                if (!_collapsed) panel,
              ],
            ),
          ),
        );
      },
    );
  }
}

