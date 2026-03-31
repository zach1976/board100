import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../state/tactics_state.dart';
import '../widgets/tactics_canvas.dart';
import '../widgets/toolbar.dart';
import '../widgets/language_picker.dart';
import 'sport_selection_page.dart';

class TacticsBoardHomePage extends StatelessWidget {
  const TacticsBoardHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Subscribe to locale changes so page rebuilds on language switch
    context.locale;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const TacticsCanvas(),
                if (!isSingleSportApp)
                  Positioned(
                    top: topPad + 8, left: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const SportSelectionPage()),
                      ),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16),
                      ),
                    ),
                  ),
                Positioned(top: topPad + 8, right: 12, child: _MenuButton()),
                Selector<TacticsState, bool>(
                  selector: (_, s) => s.isDrawingMode,
                  builder: (context, isDrawing, _) => isDrawing
                    ? Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          color: const Color(0xDD1E1E2E),
                          child: DrawingOptionsBar(state: context.read<TacticsState>()),
                        ),
                      )
                    : const SizedBox.shrink(),
                ),
                Positioned(
                  bottom: 12, right: 12,
                  child: Selector<TacticsState, bool>(
                    selector: (_, s) => s.toolbarVisible,
                    builder: (context, visible, _) => GestureDetector(
                      onTap: context.read<TacticsState>().toggleToolbar,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                        child: Icon(visible ? Icons.fullscreen : Icons.fullscreen_exit, color: Colors.white70, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Selector<TacticsState, ({bool visible, bool drawing, bool moves, int steps, int atStep, bool animating})>(
            selector: (_, s) => (visible: s.toolbarVisible, drawing: s.isDrawingMode, moves: s.hasMoves, steps: s.maxMoveSteps, atStep: s.atStep, animating: s.isAnimating),
            builder: (context, sel, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sel.visible && !sel.drawing)
                  SizedBox(
                    height: 48,
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
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => _onSelected(context, value),
      color: const Color(0xFF2A2A3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_horiz, color: Colors.white70, size: 18),
      ),
      itemBuilder: (ctx) => [
        _menuItem('language', Icons.language, 'menu_language'.tr()),
        _menuItem('contact', Icons.mail_outline, 'menu_contact'.tr()),
        _menuItem('login', Icons.person_outline, 'menu_login'.tr()),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      height: 44,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  void _onSelected(BuildContext context, String value) {
    switch (value) {
      case 'language':
        LanguagePicker.show(context);
      case 'contact':
        _showContact(context);
      case 'login':
        _showLogin(context);
    }
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
    setState(() => _sending = true);
    try {
      final response = await http.post(
        Uri.parse('https://tacticsboard.100for1.com/api/v1/send-email'),
        body: {
          'email': email,
          'subject': _subjectCtrl.text.trim().isEmpty ? 'Feedback' : _subjectCtrl.text.trim(),
          'message': body,
          'app': 'Tactics Board',
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
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: Text('contact_title'.tr()),
        backgroundColor: const Color(0xFF1E1E2E),
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

  Future<void> _loginWithApple() async {
    setState(() => _loading = true);
    final result = await _auth.loginWithApple();
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'welcome'.tr()}, ${result.name ?? result.email ?? 'User'}!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result.error ?? 'login_failed').tr())),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    final result = await _auth.loginWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'welcome'.tr()}, ${result.name ?? result.email ?? 'User'}!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result.error ?? 'login_failed').tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = _auth.isLoggedIn;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: Text('login_title'.tr()),
        backgroundColor: const Color(0xFF1E1E2E),
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
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _auth.logout();
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
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _confirmDeleteAccount(),
          child: Text('delete_account'.tr(), style: const TextStyle(color: Colors.red, fontSize: 14)),
        ),
      ],
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
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
