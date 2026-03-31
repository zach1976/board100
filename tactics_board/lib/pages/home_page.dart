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
    return Consumer<TacticsState>(
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF1E1E2E),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(),
                        child: const TacticsCanvas(),
                      ),
                      // Back button (multi-sport only)
                      if (!isSingleSportApp)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          left: 12,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const SportSelectionPage()),
                            ),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16),
                            ),
                          ),
                        ),
                      // Menu button (top right)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 12,
                        child: _MenuButton(),
                      ),
                      // Drawing options overlay — bottom of canvas, no impact on canvas height
                      if (state.isDrawingMode)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: const Color(0xDD1E1E2E),
                            child: DrawingOptionsBar(state: state),
                          ),
                        ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: state.toggleToolbar,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              state.toolbarVisible ? Icons.fullscreen : Icons.fullscreen_exit,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Play controls — always reserve space to prevent canvas jump
                if (state.toolbarVisible && !state.isDrawingMode)
                  SizedBox(
                    height: 48,
                    child: state.hasMoves
                        ? Center(child: PlayControlsBar(state: state))
                        : null,
                  ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: state.toolbarVisible ? const TacticsToolbar() : const SizedBox.shrink(),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? 16 : 4),
              ],
            ),
          ),
        );
      },
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
        _menuItem('language', Icons.language, 'Language'),
        _menuItem('contact', Icons.mail_outline, 'Contact Us'),
        _menuItem('login', Icons.person_outline, 'Login'),
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
    if (_emailCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final uri = Uri.parse('http://safecommunity.100for1.com:8080/api/send-email');
      final response = await http.post(uri, body: {
        'email': _emailCtrl.text.trim(),
        'subject': _subjectCtrl.text.trim(),
        'message': _bodyCtrl.text.trim(),
        'app': 'Tactics Board',
      }, headers: {'Content-Type': 'application/x-www-form-urlencoded'});

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent successfully!')),
        );
        Navigator.pop(context);
      } else if (response.statusCode == 422) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email format')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
        title: const Text('Contact Us'),
        backgroundColor: const Color(0xFF1E1E2E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Send us a message', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 20),
            _field(_emailCtrl, 'Your Email', TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(_subjectCtrl, 'Subject'),
            const SizedBox(height: 12),
            _field(_bodyCtrl, 'Message', null, 5),
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
                  : const Text('Send', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        SnackBar(content: Text('Welcome, ${result.name ?? result.email ?? 'User'}!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Login failed')),
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
        SnackBar(content: Text('Welcome, ${result.name ?? result.email ?? 'User'}!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = _auth.isLoggedIn;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text('Login'),
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
            child: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildSignIn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.person_outline, color: Colors.white38, size: 80),
        const SizedBox(height: 24),
        const Text('Sign in to sync your tactics',
            style: TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        if (_loading)
          const CircularProgressIndicator()
        else ...[
          // Apple Sign In
          _signInButton(
            icon: Icons.apple,
            label: 'Sign in with Apple',
            color: Colors.white,
            bgColor: Colors.black,
            onTap: _loginWithApple,
          ),
          const SizedBox(height: 14),
          // Google Sign In
          _signInButton(
            icon: Icons.g_mobiledata,
            label: 'Sign in with Google',
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
