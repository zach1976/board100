import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

const _apiServer = 'tacticsboard.100for1.com';
const _apiBase = 'http://$_apiServer/api/v1';
const _googleClientId = '711017030012-lf4ostf39c4dn5b336h5pl17bosm8ek7.apps.googleusercontent.com';

class AuthResult {
  final bool success;
  final String? token;
  final String? name;
  final String? email;
  final String? error;

  AuthResult({this.success = false, this.token, this.name, this.email, this.error});
}

class AuthService {
  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;
  AuthService._();

  String? _token;
  String? _userName;
  String? _userEmail;

  bool get isLoggedIn => _token != null;
  String? get token => _token;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  Future<AuthResult> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: _googleClientId.isNotEmpty ? _googleClientId : null,
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        return AuthResult(error: 'Google sign-in cancelled');
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null) {
        return AuthResult(error: 'Failed to get Google ID token');
      }

      // Send to backend
      final response = await http.post(
        Uri.parse('$_apiBase/auth/google'),
        body: jsonEncode({'id_token': idToken}),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'] as String?;
        _userName = data['user']?['name'] as String? ?? account.displayName;
        _userEmail = data['user']?['email'] as String? ?? account.email;
        return AuthResult(success: true, token: _token, name: _userName, email: _userEmail);
      } else {
        return AuthResult(error: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Google login error: $e');
      return AuthResult(error: _friendlyError(e));
    }
  }

  Future<AuthResult> loginWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) {
        return AuthResult(error: 'Failed to get Apple identity token');
      }

      // Send to backend
      final response = await http.post(
        Uri.parse('$_apiBase/auth/apple'),
        body: jsonEncode({
          'identity_token': identityToken,
          'nonce': rawNonce,
          'user_identifier': credential.userIdentifier,
          'given_name': credential.givenName,
          'family_name': credential.familyName,
          'email': credential.email,
        }),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'] as String?;
        _userName = data['user']?['name'] as String? ??
            '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
        _userEmail = data['user']?['email'] as String? ?? credential.email;
        return AuthResult(success: true, token: _token, name: _userName, email: _userEmail);
      } else {
        return AuthResult(error: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Apple login error: $e');
      return AuthResult(error: _friendlyError(e));
    }
  }

  /// Returns a short error key or message
  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('canceled') || msg.contains('cancelled')) {
      return 'login_cancelled';
    }
    if (msg.contains('error 1000') || msg.contains('AuthorizationError')) {
      return 'login_not_available';
    }
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'login_network_error';
    }
    if (msg.contains('Server error')) {
      return 'login_server_error';
    }
    return 'login_failed';
  }

  void logout() {
    _token = null;
    _userName = null;
    _userEmail = null;
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
