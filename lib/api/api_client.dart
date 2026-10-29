import 'dart:convert';

import 'package:http/http.dart' as http;

/// RFC 9457 problem-details error surfaced to the UI.
class ApiException implements Exception {
  ApiException(this.status, this.code, this.detail, {this.errors});

  final int status;
  final String code;
  final String detail;
  final Map<String, List<String>>? errors;

  @override
  String toString() => detail;
}

/// Thin JSON client for the advertising backend (/api/v1).
///
/// Base URL comes from `--dart-define=API_BASE=http://host`. When empty the
/// app stays in offline-demo mode and repositories should not be used.
class ApiClient {
  ApiClient({String? baseUrl, http.Client? httpClient})
      : baseUrl = (baseUrl ?? const String.fromEnvironment('API_BASE'))
            .replaceAll(RegExp(r'/+$'), ''),
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;
  String? _token;

  bool get isConfigured => baseUrl.isNotEmpty;

  set token(String? value) => _token = value;

  Future<Map<String, dynamic>> get(String path, [Map<String, String>? query]) =>
      _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path,
          {Map<String, dynamic>? body, String? idempotencyKey}) =>
      _send('POST', path, body: body, idempotencyKey: idempotencyKey);

  Future<Map<String, dynamic>> patch(String path,
          {Map<String, dynamic>? body, String? ifMatch}) =>
      _send('PATCH', path, body: body, ifMatch: ifMatch);

  Future<void> delete(String path, {String? idempotencyKey}) =>
      _send('DELETE', path, idempotencyKey: idempotencyKey, emptyOk: true)
          .then((_) {});

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    String? idempotencyKey,
    String? ifMatch,
    bool emptyOk = false,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1$path')
        .replace(queryParameters: query?.isEmpty == true ? null : query);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Accept-Language': 'ar',
      if (_token != null) 'Authorization': 'Bearer $_token',
      if (body != null) 'Content-Type': 'application/json',
      'Idempotency-Key': ?idempotencyKey,
      'If-Match': ?ifMatch,
    };
    final response = await _http
        .send(http.Request(method, uri)
          ..headers.addAll(headers)
          ..body = body == null ? '' : jsonEncode(body))
        .timeout(const Duration(seconds: 20));

    final raw = await response.stream.bytesToString();
    if (response.statusCode >= 400) {
      Map<String, dynamic> problem = const {};
      try {
        problem = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
      throw ApiException(
        response.statusCode,
        problem['code'] as String? ?? 'http.${response.statusCode}',
        problem['detail'] as String? ??
            problem['title'] as String? ??
            'خطأ غير متوقع (${response.statusCode})',
        errors: (problem['errors'] as Map?)?.map(
          (k, v) => MapEntry('$k', (v as List).map((e) => '$e').toList()),
        ),
      );
    }
    if (response.statusCode == 204 || (emptyOk && raw.isEmpty)) {
      return const {};
    }
    return raw.isEmpty ? const {} : jsonDecode(raw) as Map<String, dynamic>;
  }
}
