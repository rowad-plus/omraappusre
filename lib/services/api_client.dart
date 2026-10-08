import 'dart:convert';
import 'package:http/http.dart' as http;
import '../state/locale_state.dart';

/// Uniform exception for API errors — carries a ready-to-display Arabic
/// message (from Laravel's "message" field) and the HTTP status code.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;
  final Map<String, dynamic>? data;

  ApiException(this.statusCode, this.message, {this.errors, this.data});

  @override
  String toString() => message;
}

/// Thin HTTP client for the Front (customer) API — injects the Sanctum
/// token automatically and converts error responses into ApiException.
///
/// Note: this backend's custom auth middleware redirects (302) rather than
/// returning 401 for an invalid/expired sanctum token, and `http` follows
/// redirects by default — so an expired session can come back as a 200 with
/// an HTML login page instead of a clean error. Callers that need "am I
/// still logged in" certainty should check the decoded body actually has
/// the expected shape, not just rely on a non-2xx status.
class ApiClient {
  static const String baseUrl = 'https://omraway.com/api/v1/front';

  String? _token;

  void setToken(String? token) => _token = token;

  // The server (SetApiLocale) picks the language of trip titles, city names
  // etc. from this header; without it every response came back in Arabic.
  String get _lang => LocaleState.locale.value.languageCode;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Accept-Language': _lang,
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      for (final e in query.entries)
        if (e.value != null) e.key: e.value.toString(),
    });
  }

  dynamic _decode(http.Response res) {
    dynamic body;
    if (res.body.isNotEmpty) {
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        // Non-JSON response (e.g. an HTML redirect target) — leave body
        // null and fall back to a generic message below.
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body ?? {};
    }

    final map = body is Map<String, dynamic> ? body : null;
    final message = map?['message'] as String? ??
        (res.statusCode == 401
            ? 'انتهت صلاحية الجلسة، الرجاء تسجيل الدخول من جديد'
            : res.statusCode == 403
                ? 'ليس لديك صلاحية للقيام بهذا الإجراء'
                : 'حدث خطأ غير متوقع، الرجاء المحاولة لاحقًا');
    final errors = map?['errors'] as Map<String, dynamic>?;
    throw ApiException(res.statusCode, message, errors: errors, data: map);
  }

  Future<dynamic> get(String path, [Map<String, dynamic>? query]) async {
    final res = await http.get(_uri(path, query), headers: _headers);
    return _decode(res);
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? data]) async {
    final res = await http.post(_uri(path), headers: _headers, body: jsonEncode(data ?? {}));
    return _decode(res);
  }

  Future<dynamic> put(String path, [Map<String, dynamic>? data]) async {
    final res = await http.put(_uri(path), headers: _headers, body: jsonEncode(data ?? {}));
    return _decode(res);
  }

  Future<dynamic> delete(String path, [Map<String, dynamic>? data]) async {
    final res = await http.delete(_uri(path), headers: _headers, body: data == null ? null : jsonEncode(data));
    return _decode(res);
  }

  /// Multipart POST for endpoints that accept file uploads alongside plain
  /// fields (e.g. a timeline post's image/video).
  Future<dynamic> postMultipart(
    String path,
    Map<String, dynamic> fields, {
    List<MapEntry<String, List<int>>> files = const [],
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers['Accept'] = 'application/json';
    request.headers['Accept-Language'] = _lang;
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    fields.forEach((k, v) {
      if (v != null) request.fields[k] = v.toString();
    });
    for (var i = 0; i < files.length; i++) {
      request.files.add(http.MultipartFile.fromBytes(files[i].key, files[i].value, filename: 'media_$i'));
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }
}
