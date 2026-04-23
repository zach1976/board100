import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

const _apiBase = 'https://tacticsboard.100for1.com/api/v1';

/// Result of a batch push. `conflicts` contains server rows whose
/// `client_updated_at` was newer than what we pushed — the caller should
/// overwrite local state with these (or delete locally for tombstones).
class BatchPushResult {
  final int accepted;
  final List<Map<String, dynamic>> conflicts;
  const BatchPushResult(this.accepted, this.conflicts);
}

class SyncService {
  static final SyncService _instance = SyncService._();
  static SyncService get instance => _instance;
  SyncService._();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (AuthService.instance.token != null)
      'Authorization': 'Bearer ${AuthService.instance.token}',
  };

  /// Push a single tactic. `clientUpdatedAt` is the logical modified time of
  /// the local row (e.g. file mtime) — server uses it for last-writer-wins.
  Future<bool> pushTactic(
    String name,
    String sportType,
    Map<String, dynamic> data, {
    DateTime? clientUpdatedAt,
  }) async {
    if (!AuthService.instance.isLoggedIn) return false;
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/tactics'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'sport_type': sportType,
          'data': data,
          if (clientUpdatedAt != null)
            'client_updated_at': clientUpdatedAt.toUtc().toIso8601String(),
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Sync push error: $e');
      return false;
    }
  }

  /// Batch push tactics. Each item may include `client_updated_at`.
  Future<BatchPushResult> pushAll(List<Map<String, dynamic>> tactics) async {
    if (!AuthService.instance.isLoggedIn) return const BatchPushResult(0, []);
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/tactics/sync'),
        headers: _headers,
        body: jsonEncode({'tactics': tactics}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accepted =
            (data['accepted'] as int?) ?? (data['synced'] as int?) ?? 0;
        final conflicts = (data['conflicts'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            const [];
        return BatchPushResult(accepted, conflicts);
      }
      return const BatchPushResult(0, []);
    } catch (e) {
      debugPrint('Sync pushAll error: $e');
      return const BatchPushResult(0, []);
    }
  }

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

  Future<bool> deleteTacticByName(
    String name,
    String sportType, {
    DateTime? clientUpdatedAt,
  }) async {
    if (!AuthService.instance.isLoggedIn) return false;
    try {
      final qp = <String, String>{'name': name, 'sport_type': sportType};
      if (clientUpdatedAt != null) {
        qp['client_updated_at'] = clientUpdatedAt.toUtc().toIso8601String();
      }
      final uri =
          Uri.parse('$_apiBase/tactics').replace(queryParameters: qp);
      final response = await http.delete(uri, headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Sync deleteTacticByName error: $e');
      return false;
    }
  }

  // ─── Practice plans ──────────────────────────────────────────────────

  Future<bool> pushPractice(
    String name,
    String sportType,
    Map<String, dynamic> data, {
    DateTime? clientUpdatedAt,
  }) async {
    if (!AuthService.instance.isLoggedIn) return false;
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/practices'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'sport_type': sportType,
          'data': data,
          if (clientUpdatedAt != null)
            'client_updated_at': clientUpdatedAt.toUtc().toIso8601String(),
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Sync pushPractice error: $e');
      return false;
    }
  }

  Future<BatchPushResult> pushAllPractices(
      List<Map<String, dynamic>> practices) async {
    if (!AuthService.instance.isLoggedIn) return const BatchPushResult(0, []);
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/practices/sync'),
        headers: _headers,
        body: jsonEncode({'practices': practices}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accepted =
            (data['accepted'] as int?) ?? (data['synced'] as int?) ?? 0;
        final conflicts = (data['conflicts'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            const [];
        return BatchPushResult(accepted, conflicts);
      }
      return const BatchPushResult(0, []);
    } catch (e) {
      debugPrint('Sync pushAllPractices error: $e');
      return const BatchPushResult(0, []);
    }
  }

  Future<List<Map<String, dynamic>>> listPractices({String? sportType}) async {
    if (!AuthService.instance.isLoggedIn) return [];
    try {
      final uri = Uri.parse(
          '$_apiBase/practices${sportType != null ? '?sport_type=$sportType' : ''}');
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['practices'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Sync listPractices error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> pullAllPractices({
    String? sportType,
    String? since,
  }) async {
    if (!AuthService.instance.isLoggedIn) return [];
    try {
      final qp = <String, String>{};
      if (sportType != null) qp['sport_type'] = sportType;
      if (since != null) qp['since'] = since;
      final uri = Uri.parse('$_apiBase/practices/pull')
          .replace(queryParameters: qp.isEmpty ? null : qp);
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['practices'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Sync pullAllPractices error: $e');
      return [];
    }
  }

  Future<bool> deletePracticeByName(
    String name,
    String sportType, {
    DateTime? clientUpdatedAt,
  }) async {
    if (!AuthService.instance.isLoggedIn) return false;
    try {
      final qp = <String, String>{'name': name, 'sport_type': sportType};
      if (clientUpdatedAt != null) {
        qp['client_updated_at'] = clientUpdatedAt.toUtc().toIso8601String();
      }
      final uri =
          Uri.parse('$_apiBase/practices').replace(queryParameters: qp);
      final response = await http.delete(uri, headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Sync deletePractice error: $e');
      return false;
    }
  }

  // ─── Practice history ────────────────────────────────────────────────

  Future<bool> pushSession(Map<String, dynamic> session) async {
    if (!AuthService.instance.isLoggedIn) return false;
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/practice-history'),
        headers: _headers,
        body: jsonEncode(session),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Sync pushSession error: $e');
      return false;
    }
  }

  Future<int> pushAllSessions(List<Map<String, dynamic>> sessions) async {
    if (!AuthService.instance.isLoggedIn) return 0;
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/practice-history/sync'),
        headers: _headers,
        body: jsonEncode({'sessions': sessions}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['synced'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Sync pushAllSessions error: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> listSessions({String? sportType}) async {
    if (!AuthService.instance.isLoggedIn) return [];
    try {
      final qp = <String, String>{};
      if (sportType != null) qp['sport_type'] = sportType;
      final uri = Uri.parse('$_apiBase/practice-history')
          .replace(queryParameters: qp.isEmpty ? null : qp);
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['sessions'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Sync listSessions error: $e');
      return [];
    }
  }

  Future<bool> clearSessions({String? sportType}) async {
    if (!AuthService.instance.isLoggedIn) return false;
    try {
      final qp = <String, String>{};
      if (sportType != null) qp['sport_type'] = sportType;
      final uri = Uri.parse('$_apiBase/practice-history')
          .replace(queryParameters: qp.isEmpty ? null : qp);
      final response = await http.delete(uri, headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Sync clearSessions error: $e');
      return false;
    }
  }
}
