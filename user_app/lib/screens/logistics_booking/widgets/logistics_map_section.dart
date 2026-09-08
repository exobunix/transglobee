import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../widgets/leaflet_map.dart';

class LogisticsMapSection extends StatelessWidget {
  final Map<String, dynamic>? pickup;
  final Map<String, dynamic>? dropoff;
  final List<LatLng> routePoints;

  const LogisticsMapSection({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.routePoints,
  });

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LeafletMap(
          location: pickup ?? dropoff,
          polylines: [
            if (routePoints.isNotEmpty)
              Polyline(
                points: routePoints,
                color: const Color(0xFF0F5A3B),
                strokeWidth: 5,
              ),
          ],
          markers: [
            if (pickup != null)
              Marker(
                point: LatLng(
                  _parseDouble(pickup!['lat']),
                  _parseDouble(pickup!['lng']),
                ),
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.circle,
                  color: Color(0xFF0F5A3B),
                  size: 24,
                ),
              ),
            if (dropoff != null)
              Marker(
                point: LatLng(
                  _parseDouble(dropoff!['lat']),
                  _parseDouble(dropoff!['lng']),
                ),
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
