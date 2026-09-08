import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../core/config.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart' as poly;
import 'auth_service.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint("Error fetching location: $e");
      return null;
    }
  }

  static Future<String> getAddressFromLatLng(
  double lat,
  double lng,
) async {
  try {
    debugPrint("Fetching address for: $lat,$lng");

    final apiKey = AppConfig.googleMapsApiKey;
    final baseUrl = AppConfig.apiBaseUrl;
    final mapsBaseUrl = baseUrl.endsWith('/api')
        ? baseUrl.substring(0, baseUrl.length - 4)
        : (baseUrl.endsWith('/api/')
            ? baseUrl.substring(0, baseUrl.length - 5)
            : baseUrl);

    final url = kIsWeb
        ? Uri.parse(
            '$mapsBaseUrl/maps/geocode?latlng=$lat,$lng&key=$apiKey')
        : Uri.parse(
            'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey');

    final headers = kIsWeb
        ? await AuthService().buildAuthHeaders(
            includeContentType: false,
          )
        : null;

    final response = await http.get(url, headers: headers);

    debugPrint("STATUS CODE: ${response.statusCode}");
    debugPrint("BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'OK' &&
          data['results'] != null &&
          data['results'].isNotEmpty) {
        return data['results'][0]['formatted_address'];
      }

      debugPrint("Google API Status: ${data['status']}");
    }
  } catch (e) {
    debugPrint('Error reverse geocoding: $e');
  }

  return 'Unknown Location';
}


  // static Future<String> getAddressFromLatLng(double lat, double lng) async {
  //   try {
  //     final apiKey = AppConfig.googleMapsApiKey;
  //     final baseUrl = AppConfig.apiBaseUrl;
  //     final url = kIsWeb
  //         ? Uri.parse('$baseUrl/api/maps/geocode?latlng=$lat,$lng&key=$apiKey')
  //         : Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey');
  //     final headers = kIsWeb
  //         ? await AuthService().buildAuthHeaders(includeContentType: false)
  //         : null;
  //     final response = await http.get(url, headers: headers);
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       if (data['results'] != null && data['results'].isNotEmpty) {
  //         return data['results'][0]['formatted_address'] ?? 'Unknown Location';
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint('Error reverse geocoding: $e');
  //   }
  //   return 'Unknown Location';
  // }



  static Future<Map<String, dynamic>> getRouteData(dynamic start, dynamic end) async {
    try {
      final apiKey = AppConfig.googleMapsApiKey;
      final baseUrl = AppConfig.apiBaseUrl;
      final mapsBaseUrl = baseUrl.endsWith('/api')
          ? baseUrl.substring(0, baseUrl.length - 4)
          : (baseUrl.endsWith('/api/')
              ? baseUrl.substring(0, baseUrl.length - 5)
              : baseUrl);
      final origin = "${start.latitude},${start.longitude}";
      final dest = "${end.latitude},${end.longitude}";
      
      final url = kIsWeb
          ? Uri.parse('$mapsBaseUrl/maps/directions?origin=$origin&destination=$dest&key=$apiKey')
          : Uri.parse('https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$dest&key=$apiKey');
          
      final headers = kIsWeb
          ? await AuthService().buildAuthHeaders(includeContentType: false)
          : null;
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          String encodedPolyline = route['overview_polyline']['points'];
          final List<List<double>> points = poly.decodePolyline(encodedPolyline).map((p) => [p[0].toDouble(), p[1].toDouble()]).toList();
          
          double parseDouble(dynamic val) {
            if (val == null) return 0.0;
            if (val is num) return val.toDouble();
            if (val is String) return double.tryParse(val) ?? 0.0;
            return 0.0;
          }

          return {
            'points': points,
            'distance': parseDouble(leg['distance']['value']) / 1000,
            'duration': parseDouble(leg['duration']['value']) / 60,
          };
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
    return {
      'points': [[start.latitude, start.longitude], [end.latitude, end.longitude]],
      'distance': 0.0,
      'duration': 0.0,
    };
  }
}
