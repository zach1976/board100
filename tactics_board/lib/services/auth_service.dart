import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

const _apiServer = 'safecommunity.100for1.com:8080';
// TODO: Replace with your Google OAuth client ID
const _googleClientId = '';

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
        Uri.parse('http://$_apiServer/api/google-login'),
        body: jsonEncode({'id_token': idToken}),
        headers: {'Content-Type': 'application/json'},
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
      return AuthResult(error: e.toString());
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
        Uri.parse('http://$_apiServer/api/apple-login'),
        body: jsonEncode({
          'identity_token': identityToken,
          'nonce': rawNonce,
          'user_identifier': credential.userIdentifier,
          'given_name': credential.givenName,
          'family_name': credential.familyName,
          'email': credential.email,
        }),
        headers: {'Content-Type': 'application/json'},
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
      return AuthResult(error: e.toString());
    }
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
