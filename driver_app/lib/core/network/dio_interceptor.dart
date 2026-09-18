import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  static const bool _networkLogsEnabled =
      bool.fromEnvironment('ENABLE_NETWORK_LOGS', defaultValue: true);

  AuthInterceptor(this.dio);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    String? token;

    // 1. Prefer active REST auth_token when driver is logged in
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');

    // 2. Try Secure Storage
    token ??= await SecureStorageService.getToken();

    // 3. Fallback to Firebase token if available
    if (token == null) {
      try {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          token = await firebaseUser.getIdToken().timeout(const Duration(seconds: 5));
        }
      } catch (_) {
        // Ignore and fall back below.
      }
    }

    // 4. Handle Local Development Bypass
    final bool isLocal = AppConfig.apiBaseUrl.toLowerCase().contains('localhost') ||
                        AppConfig.apiBaseUrl.toLowerCase().contains('127.0.0.1');
    
    if (token == null && isLocal) {
      token = 'dev-token-bypass';
    }

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      
      // If bypass, also add x-dev-uid if we have it locally
      if (token == 'dev-token-bypass') {
         final prefs = await SharedPreferences.getInstance();
         final userDataStr = prefs.getString('user_data');
         if (userDataStr != null) {
           try {
             final Map<String, dynamic> userData = Map<String, dynamic>.from(jsonDecode(userDataStr));
             final uid = userData['id'] ?? userData['_id'] ?? userData['uid'];
             if (uid != null) {
               options.headers['x-dev-uid'] = uid.toString();
             }
           } catch (_) {}
         }
      }
    }

    if (kDebugMode || _networkLogsEnabled) {
      print('REQUEST[${options.method}] => PATH: ${options.path}');
      print('REQUEST HEADERS: ${options.headers}');
      if (options.data != null) print('REQUEST DATA: ${options.data}');
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode || _networkLogsEnabled) {
      print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
      print('DATA: ${response.data}');
    }
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (kDebugMode || _networkLogsEnabled) {
      print(
          'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
      print('ERROR DATA: ${err.response?.data}');
    }

    if (err.response?.statusCode == 401) {
      // Attempt refresh
      final refreshToken = await SecureStorageService.getRefreshToken();
      if (refreshToken != null) {
        try {
          final refreshDio = Dio();
          final refreshResponse = await refreshDio.post(
            '${AppConfig.apiBaseUrl}/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          if (refreshResponse.statusCode == 200) {
            final newToken = refreshResponse.data['token'];
            await SecureStorageService.saveToken(newToken);

            // Retry request
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newToken';
            final cloneReq = await dio.request(
              opts.path,
              options: Options(
                method: opts.method,
                headers: opts.headers,
              ),
              data: opts.data,
              queryParameters: opts.queryParameters,
            );
            return handler.resolve(cloneReq);
          }
        } catch (e) {
          await SecureStorageService.clearAll();
          // Trigger logout/redirect to login
        }
      } else {
        await SecureStorageService.clearAll();
      }
    }

    return super.onError(err, handler);
  }
}
