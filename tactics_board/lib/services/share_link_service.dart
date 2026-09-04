import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

const _apiBase = 'https://tacticsboard.100for1.com/api/v1';

/// Publishes a play as a link anyone can open in a browser.
///
/// Exporting a PNG and sending it through a chat app already works — this
/// exists because a still image is not the play. The link shows the animation,
/// survives being forwarded, and costs the receiver nothing: no app, no
/// account, no sign-up wall. Sharing works signed-out for the same reason.
///
/// The upload carries both the rendered media (an MP4 of the animation, or a
/// PNG for a static board) and the board JSON, so the page can show the play
/// today and be re-rendered properly later without asking anyone to re-share.
class ShareLinkService {
  ShareLinkService._();
  static final ShareLinkService instance = ShareLinkService._();

  /// Uploads a play and returns its public URL, or null if the upload failed.
  ///
  /// [media] is the already-rendered MP4 or PNG. [data] is the tactic JSON as
  /// the app saves it locally. [ttlDays] lets a caller shorten the default
  /// server-side lifetime.
  Future<String?> publish({
    required String sportType,
    required Map<String, dynamic> data,
    File? media,
    String? title,
    int? ttlDays,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_apiBase/share'));
      request.fields['sport_type'] = sportType;
      request.fields['data'] = jsonEncode(data);
      if (title != null && title.trim().isNotEmpty) {
        request.fields['title'] = title.trim();
      }
      if (ttlDays != null) request.fields['ttl_days'] = '$ttlDays';

      // Signed-in coaches get their links attached to their account, so they
      // can unpublish later. Signed-out links are anonymous and still work.
      final token = AuthService.instance.token;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      if (media != null && await media.exists()) {
        request.files.add(await http.MultipartFile.fromPath('media', media.path));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 201) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['url'] as String?;
    } catch (_) {
      // Offline at the pitch is the normal case, not an exception: the caller
      // falls back to sharing the file itself.
      return null;
    }
  }
}
