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
    final token = await _authService.getIdToken();
    final dynamic user = _authService.currentUser;
    final String? uid = (user != null) ? (user.uid) : null;

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (token == 'dev-token-bypass' && uid != null) 'x-dev-uid': uid,
    };
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
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
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
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
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
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

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> patchWithFallback(
    String primaryEndpoint,
    String fallbackEndpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      return await patch(primaryEndpoint, body);
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      return patch(fallbackEndpoint, body);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: $statusCode - $message';
}
