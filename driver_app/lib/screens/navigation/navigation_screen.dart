import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../services/location_service.dart';
import '../../services/socket_service.dart';
import '../../services/auth_service.dart';


class NavigationScreen extends ConsumerStatefulWidget {
  final LatLng destination;
  final String destinationName;
  final String rideId;

  const NavigationScreen({
    super.key,
    required this.destination,
    required this.destinationName,
    required this.rideId,
  });

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPos = const LatLng(26.8467, 80.9462); // Fallback Lucknow
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _isLoading = true;
  double _distance = 0.0;
  double _duration = 0.0;
  StreamSubscription<Position>? _positionSubscription;
  
  @override
  void initState() {
    super.initState();
    _initNavigation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initNavigation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      if (mounted) {
        setState(() {
          _currentPos = LatLng(position.latitude, position.longitude);
        });
      }
      
      _startLocationUpdates();
      _fetchRoute();
    } catch (e) {
      debugPrint("Error initializing navigation: $e");
    }
  }

  void _startLocationUpdates() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPos = LatLng(position.latitude, position.longitude);
        });

        // Send update via Socket.io
        final userId = ref.read(authServiceProvider).currentUser?.uid;
        if (userId != null) {
          ref.read(socketServiceProvider).updateLocation(
            rideId: widget.rideId,
            userId: userId,
            latitude: position.latitude,
            longitude: position.longitude,
            heading: position.heading,
          );
        }

        // Update current location marker
        _updateMarkers();
        
        // Move camera if needed (optional, maybe only if user is not dragging)
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_currentPos),
        );
      }
    });
  }

  Future<void> _fetchRoute() async {
    setState(() => _isLoading = true);
    
    // Note: LocationService needs to return LatLng (google_maps_flutter) 
    // instead of LatLng (latlong2). I'll handle the conversion here for now.
    final routeData = await LocationService.getRouteData(
      // Conversion from google_maps_flutter LatLng to latlong2 LatLng (if needed)
      _currentPos, 
      widget.destination
    );
    
    if (mounted) {
      setState(() {
        final List<LatLng> polylinePoints = (routeData['points'] as List).map((p) => LatLng(p[0], p[1])).toList();
        
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylinePoints,
            color: AppTheme.neonGreen,
            width: 6,
          ),
        };
        
        _distance = routeData['distance'];
        _duration = routeData['duration'];
        _updateMarkers();
        _isLoading = false;
      });
      
      _fitBounds();
    }
  }

  void _updateMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('current'),
        position: _currentPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.destinationName),
      ),
    };
  }

  void _fitBounds() {
    if (_mapController == null || _polylines.isEmpty) return;
    
    final polyline = _polylines.firstOrNull;
    if (polyline == null || polyline.points.isEmpty) return;
    final points = polyline.points;

    double? minLat, maxLat, minLng, maxLng;
    for (final p in points) {
      if (minLat == null || p.latitude < minLat) minLat = p.latitude;
      if (maxLat == null || p.latitude > maxLat) maxLat = p.latitude;
      if (minLng == null || p.longitude < minLng) minLng = p.longitude;
      if (maxLng == null || p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat!, minLng!),
          northeast: LatLng(maxLat!, maxLng!),
        ),
        50.0,
      ),
    );
  }

  Future<void> _startExternalNavigation() async {
    final googleMapsUrl = "https://www.google.com/maps/dir/?api=1&origin=${_currentPos.latitude},${_currentPos.longitude}&destination=${widget.destination.latitude},${widget.destination.longitude}&travelmode=driving";
    final googleMapsUri = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback for iOS Apple Maps or if Google Maps app is not installed
      final appleUrl = "https://maps.apple.com/?saddr=${_currentPos.latitude},${_currentPos.longitude}&daddr=${widget.destination.latitude},${widget.destination.longitude}&dirflg=d";
      final appleUri = Uri.parse(appleUrl);
      if (await canLaunchUrl(appleUri)) {
        await launchUrl(appleUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch navigation app')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentPos, zoom: 15),
            onMapCreated: (controller) {
              _mapController = controller;
              if (!_isLoading) _fitBounds();
            },
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen)),

          // Header Instructions
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.neonGreen.withOpacity(0.5)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.neonGreen.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.navigation, color: AppTheme.neonGreen, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _distance < 1.0 
                            ? '${(_distance * 1000).toInt()} m' 
                            : '${_distance.toStringAsFixed(1)} km', 
                          style: const TextStyle(color: AppTheme.neonGreen, fontSize: 24, fontWeight: FontWeight.w900)
                        ),
                        Text('Towards ${widget.destinationName}', style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Actions
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('DISTANCE', '${_distance.toStringAsFixed(1)} km'),
                      _vertDivider(),
                      _statItem('TIME', '${_duration.toInt()} min'),
                      _vertDivider(),
                      _statItem('DEST', widget.destinationName),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: _startExternalNavigation,
                          icon: const Icon(Icons.directions),
                          label: const Text('START NAVIGATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkSurface,
                            foregroundColor: AppTheme.offlineRed,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: const BorderSide(color: AppTheme.offlineRed),
                          ),
                          child: const Text('QUIT', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 16, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _vertDivider() {
    return Container(width: 1, height: 30, color: AppTheme.darkDivider);
  }
}
