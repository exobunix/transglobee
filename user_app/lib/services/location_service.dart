import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../core/config.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart' as poly;

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
    final apiKey = AppConfig.googleMapsApiKey;
    final baseUrl = AppConfig.apiBaseUrl;

    final urls = [
      Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey'),
      Uri.parse('$baseUrl/maps/geocode?latlng=$lat,$lng&key=$apiKey'),
    ];

    for (final url in urls) {
      try {
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' &&
              data['results'] != null &&
              (data['results'] as List).isNotEmpty) {
            return data['results'][0]['formatted_address'] ?? 'Selected Location';
          }
        }
      } catch (e) {
        debugPrint('Reverse geocode attempt failed for $url: $e');
      }
    }

    return 'Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
  }

  static Future<Map<String, dynamic>> getRouteData(dynamic start, dynamic end) async {
    final apiKey = AppConfig.googleMapsApiKey;
    final baseUrl = AppConfig.apiBaseUrl;
    final origin = "${start.latitude},${start.longitude}";
    final dest = "${end.latitude},${end.longitude}";

    final urls = [
      Uri.parse('https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$dest&key=$apiKey'),
      Uri.parse('$baseUrl/maps/directions?origin=$origin&destination=$dest&key=$apiKey'),
    ];

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    for (final url in urls) {
      try {
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' &&
              data['routes'] != null &&
              (data['routes'] as List).isNotEmpty) {
            final route = data['routes'][0];
            final leg = route['legs'][0];
            String encodedPolyline = route['overview_polyline']['points'];
            final List<List<double>> points = poly
                .decodePolyline(encodedPolyline)
                .map((p) => [p[0].toDouble(), p[1].toDouble()])
                .toList();

            final distance = parseDouble(leg['distance']?['value']) / 1000.0;
            final duration = parseDouble(leg['duration']?['value']) / 60.0;

            return {
              'points': points,
              'distance': distance > 0 ? distance : 1.0,
              'duration': duration > 0 ? duration : 5.0,
            };
          }
        }
      } catch (e) {
        debugPrint('Route fetch attempt failed for $url: $e');
      }
    }

    // Fallback: Haversine geodesic distance so distance is NEVER 0.0
    final distanceMeters = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
    final fallbackDistKm = (distanceMeters / 1000.0).clamp(0.5, 500.0);
    final fallbackDurationMins = (fallbackDistKm / 30.0) * 60.0;

    return {
      'points': [
        [start.latitude, start.longitude],
        [end.latitude, end.longitude],
      ],
      'distance': double.parse(fallbackDistKm.toStringAsFixed(1)),
      'duration': double.parse(fallbackDurationMins.toStringAsFixed(1)),
    };
  }
}
