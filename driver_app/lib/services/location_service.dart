import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart' as poly;
import '../core/config.dart';

class LocationService {
  static Future<Map<String, dynamic>> getRouteData(
    dynamic start, // Can be latlong2.LatLng or google_maps_flutter.LatLng
    dynamic end,
  ) async {
    try {
      final startLat = start.latitude;
      final startLng = start.longitude;
      final endLat = end.latitude;
      final endLng = end.longitude;

      final apiKey = AppConfig.googleMapsApiKey;
      const baseUrl = AppConfig.apiBaseUrl;
      final url = Uri.parse(
        '$baseUrl/maps/directions?origin=$startLat,$startLng&destination=$endLat,$endLng&key=$apiKey',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          String encodedPolyline = route['overview_polyline']['points'];
          final List<List<double>> decodedPoints = poly.decodePolyline(encodedPolyline).map((p) => [p[0].toDouble(), p[1].toDouble()]).toList();
          
          double parseDouble(dynamic val) {
            if (val == null) return 0.0;
            if (val is num) return val.toDouble();
            if (val is String) return double.tryParse(val) ?? 0.0;
            return 0.0;
          }

          return {
            'points': decodedPoints, // Returning as raw coordinates to avoid package conflicts
            'distance': parseDouble(leg['distance']['value']) / 1000, 
            'duration': parseDouble(leg['duration']['value']) / 60,   
          };
        }
      }
    } catch (e) {
      debugPrint('Error fetching route for driver: $e');
    }
    return {
      'points': [[start.latitude, start.longitude], [end.latitude, end.longitude]],
      'distance': 0.0,
      'duration': 0.0,
    };
  }
}

