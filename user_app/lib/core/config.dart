import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'Transglobal';

  // static const String _localBackendUrl = 'http://localhost:8082';
  static const String _defaultBackendUrl = 
  // 'http://localhost:8082';
  'https://api.transgloble.com';
  // 'https://api.buildora.cloud';
  static const String _overrideApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
    //  'http://localhost:8082',
    'https://api.transgloble.com',
    // 'https://api.buildora.cloud',
  );

  // static bool get _isLocalhostWeb {
  //   if (!kIsWeb) return false;
  //   final host = Uri.base.host.toLowerCase();
  //   return host == 'localhost' ||
  //       host == '127.0.0.1' ||
  //       host == '0.0.0.0' ||
  //       host == '::1';
  // }

  /// VPS: Transglobe nginx vhost on :8085 (`/api/` → Node :8080).
  static const String _vpsBackendUrl = 'http://72.61.172.182:8085';

  static bool get _isVpsWeb {
    if (!kIsWeb) return false;
    final h = Uri.base.host.toLowerCase();
    final p = Uri.base.port;
    return h == '72.61.172.182' && p == 8085;
  }

  static String get apiBaseUrl {
    String url;
    if (_overrideApiBaseUrl.isNotEmpty) {
      url = _overrideApiBaseUrl;
    } else if (_isVpsWeb) {
      url = _vpsBackendUrl;
    } else {
      url = _defaultBackendUrl;
    }

    if (url.endsWith('/api')) return url;
    if (url.endsWith('/api/')) return url.substring(0, url.length - 1);
    return url.endsWith('/') ? '${url}api' : '$url/api';
  }

  // Google Maps API Key (Replace with your key)
  static const String googleMapsApiKey =
      'AIzaSyAJZ0z6ayXWTRsQzslL21I6CtYgW2X3sfQ';

  // Service Types
  static const String serviceCab = 'cab';
  static const String serviceTruck = 'truck';
  static const String serviceBus = 'bus';
}
