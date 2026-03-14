import 'dart:convert';
import 'package:http/http.dart' as http;

/// Lightweight HTTP client pre-configured for the local FastAPI backend.
///
/// Inject via [apiClientProvider] so the URL can be overridden in tests.
class ApiClient {
  final String baseUrl;

  const ApiClient({this.baseUrl = 'http://localhost:8000'});

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ── GET ────────────────────────────────────────────────────────────────────

  Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    return _handle(response);
  }

  // ── POST ───────────────────────────────────────────────────────────────────

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(response);
  }

  // ── Response handler ───────────────────────────────────────────────────────

  dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: _detail(response.body),
    );
  }

  String _detail(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      return map['detail']?.toString() ?? 'Request failed';
    } catch (_) {
      return body.isNotEmpty ? body : 'Request failed (${body.length} bytes)';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
