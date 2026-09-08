import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config.dart';
import 'auth_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ApiService(authService);
});

class ApiService {
  final AuthService _authService;
  final String baseUrl = AppConfig.apiBaseUrl;

  ApiService(this._authService);

  Future<Map<String, String>> _getHeaders() async {
    return _authService.buildAuthHeaders();
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = '$baseUrl$endpoint';

    _logRequest('GET', url, headers, null);

    final response = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 7));

    _logResponse('GET', url, response);
    return _handleResponse(response);
  }

  Future<dynamic> getWithFallback(
    String primaryEndpoint,
    String fallbackEndpoint,
  ) async {
    try {
      return await get(primaryEndpoint);
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      return get(fallbackEndpoint);
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    
    // Interceptor for ride cancellation API
    if (endpoint.contains('/cancel')) {
      print('[INTERCEPTOR] Intercepting cancellation request for: $endpoint');
      headers['x-request-intercepted'] = 'true';
    }

    final url = '$baseUrl$endpoint';

    _logRequest('POST', url, headers, body);

    final response = await http
        .post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 7));

    _logResponse('POST', url, response);
    return _handleResponse(response);
  }

  Future<dynamic> postWithFallback(
    String primaryEndpoint,
    String fallbackEndpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      return await post(primaryEndpoint, body);
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      return post(fallbackEndpoint, body);
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = '$baseUrl$endpoint';

    _logRequest('PUT', url, headers, body);

    final response = await http
        .put(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    _logResponse('PUT', url, response);
    return _handleResponse(response);
  }

  Future<dynamic> putWithFallback(
    String primaryEndpoint,
    String fallbackEndpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      return await put(primaryEndpoint, body);
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      return put(fallbackEndpoint, body);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();
    final url = '$baseUrl$endpoint';

    _logRequest('DELETE', url, headers, null);

    final response = await http
        .delete(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 7));

    _logResponse('DELETE', url, response);
    return _handleResponse(response);
  }

  void _logRequest(
    String method,
    String url,
    Map<String, String> headers,
    dynamic body,
  ) {
    print('\n[API REQUEST] 🚀');
    print('--> $method $url');
    print('Headers: $headers');
    if (body != null) print('Body: ${jsonEncode(body)}');
    print('-----------------------------------\n');
  }

  void _logResponse(String method, String url, http.Response response) {
    print('\n[API RESPONSE] ✅');
    print('<-- $method ${response.statusCode} $url');
    print('Body: ${response.body}');
    print('-----------------------------------\n');
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        print('[API SERVICE] Unauthorized response (401). Logging user out.');
        _authService.signOut();
      }

      String errorMessage = 'Something went wrong';

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic> && decoded.containsKey('message')) {
          errorMessage = decoded['message'].toString();
        }
      } catch (_) {
        errorMessage = response.body;
      }

      throw ApiException(
        statusCode: response.statusCode,
        message: errorMessage,
      );
    }
  }
}

//   dynamic _handleResponse(http.Response response) {
//     if (response.statusCode >= 200 && response.statusCode < 300) {
//       if (response.body.isEmpty) return null;
//       return jsonDecode(response.body);
//     } else {
//       throw ApiException(
//         statusCode: response.statusCode,
//         message: response.body,
//       );
//     }
//   }
// }

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}
