class AppConfig {
  static const String appName = 'Transgloble Driver';

  // Single Backend URL
  static const String apiBaseUrl = 'https://api.transgloble.com/api';

  // Socket URL
  static String get socketBaseUrl {
    if (apiBaseUrl.endsWith('/api')) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - 4);
    }
    if (apiBaseUrl.endsWith('/api/')) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - 5);
    }
    return apiBaseUrl;
  }

  // Google Maps API Key
  static const String googleMapsApiKey =
      'AIzaSyCbVH78oWzBH1IpoiKsKoP80A14jXt8CBc';

  // Environment
  static const String environment = 'production';

  // Service Types
  static const String serviceCab = 'cab';
  static const String serviceTruck = 'truck';
  static const String serviceBus = 'bus';
}

