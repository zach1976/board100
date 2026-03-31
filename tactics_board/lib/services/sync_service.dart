import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

const _apiBase = 'https://tacticsboard.100for1.com/api/v1';

class SyncService {
  static final SyncService _instance = SyncService._();
  static SyncService get instance => _instance;
  SyncService._();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (AuthService.instance.token != null)
      'Authorization': 'Bearer ${AuthService.instance.token}',
  };

  /// Push a single tactic to the server
  Future<bool> pushTactic(String name, String sportType, Map<String, dynamic> data) async {
    if (!AuthService.instance.isLoggedIn) return false;
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/tactics'),
        headers: _headers,
        body: jsonEncode({'name': name, 'sport_type': sportType, 'data': data}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Sync push error: $e');
      return false;
    }
  }

  /// Push all local tactics to server
  Future<int> pushAll(List<Map<String, dynamic>> tactics) async {
    if (!AuthService.instance.isLoggedIn) return 0;
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/tactics/sync'),
        headers: _headers,
        body: jsonEncode({'tactics': tactics}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['synced'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Sync pushAll error: $e');
      return 0;
    }
  }

  /// Pull all tactics from server
  Future<List<Map<String, dynamic>>> pullAll({String? since}) async {
    if (!AuthService.instance.isLoggedIn) return [];
    try {
      final uri = Uri.parse('$_apiBase/tactics/pull${since != null ? '?since=$since' : ''}');
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['tactics'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Sync pull error: $e');
      return [];
    }
  }

  /// List tactics (metadata only)
  Future<List<Map<String, dynamic>>> listTactics({String? sportType}) async {
    if (!AuthService.instance.isLoggedIn) return [];
    try {
      final uri = Uri.parse('$_apiBase/tactics${sportType != null ? '?sport_type=$sportType' : ''}');
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['tactics'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Sync list error: $e');
      return [];
    }
  }

  /// Get a single tactic with full data
  Future<Map<String, dynamic>?> getTactic(int id) async {
    if (!AuthService.instance.isLoggedIn) return null;
    try {
      final response = await http.get(Uri.parse('$_apiBase/tactics/$id'), headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['tactic'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Sync get error: $e');
      return null;
    }
  }

  /// Delete a tactic from server
  Future<bool> deleteTactic(int id) async {
    if (!AuthService.instance.isLoggedIn) return false;
    try {
      final response = await http.delete(Uri.parse('$_apiBase/tactics/$id'), headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Sync delete error: $e');
      return false;
    }
  }
}
