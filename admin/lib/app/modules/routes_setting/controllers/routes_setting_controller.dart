import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/app/utils/http_client.dart' as http;
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../models/admin_vehicle_model.dart';
import '../../../services/shared_preferences/app_preference.dart';
import '../../../constant/api_constant.dart';
import '../../../constant/show_toast.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] ?? {};
    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structured['main_text'] ?? json['description'] ?? '',
      secondaryText: structured['secondary_text'] ?? '',
    );
  }
}



class RoutesSettingController extends GetxController {
  RxList<AdminVehicleRoute> routesList = <AdminVehicleRoute>[].obs;
  RxBool isLoading = false.obs;

  // Form Controllers
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final sourceController = TextEditingController();
  final destinationController = TextEditingController();
  final distanceController = TextEditingController();

  // Autocomplete suggestions
  RxList<PlaceSuggestion> sourceSuggestions = <PlaceSuggestion>[].obs;
  RxList<PlaceSuggestion> destSuggestions = <PlaceSuggestion>[].obs;
  RxBool isSourceSuggestionVisible = false.obs;
  RxBool isDestSuggestionVisible = false.obs;
  RxBool isCalculatingDistance = false.obs;

  // Maps fields
  GoogleMapController? mapController;
  RxSet<Marker> markers = <Marker>{}.obs;
  RxSet<Polyline> polylines = <Polyline>{}.obs;

  LatLng defaultLatLng = const LatLng(28.6139, 77.2090); // New Delhi
  LatLng? startLatLng;
  LatLng? endLatLng;

  RxBool isEditing = false.obs;
  String? editingRouteId;

  static const String _googleApiKey = 'AIzaSyAJZ0z6ayXWTRsQzslL21I6CtYgW2X3sfQ';

  @override
  void onInit() {
    getRoutes();
    super.onInit();
  }

  @override
  void onClose() {
    nameController.dispose();
    sourceController.dispose();
    destinationController.dispose();
    distanceController.dispose();
    super.onClose();
  }

  void clearForm() {
    nameController.clear();
    sourceController.clear();
    destinationController.clear();
    distanceController.clear();
    startLatLng = null;
    endLatLng = null;
    markers.clear();
    polylines.clear();
    sourceSuggestions.clear();
    destSuggestions.clear();
    isSourceSuggestionVisible.value = false;
    isDestSuggestionVisible.value = false;
    isEditing.value = false;
    editingRouteId = null;
  }

  Future<void> fillForm(AdminVehicleRoute route) async {
    nameController.text = route.name ?? '';
    sourceController.text = route.source ?? '';
    destinationController.text = route.destination ?? '';
    distanceController.text = route.distance?.toStringAsFixed(1) ?? '0';
    isEditing.value = true;
    editingRouteId = route.id;

    markers.clear();
    polylines.clear();

    if (route.startLat != null && route.startLat != 0.0) {
      startLatLng = LatLng(route.startLat!, route.startLng ?? 0.0);
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: startLatLng!,
          infoWindow: InfoWindow(title: route.source ?? 'Start Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    if (route.endLat != null && route.endLat != 0.0) {
      endLatLng = LatLng(route.endLat!, route.endLng ?? 0.0);
      markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: endLatLng!,
          infoWindow: InfoWindow(title: route.destination ?? 'End Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    if (startLatLng != null && endLatLng != null) {
      await _fetchOSRMRoute();
    }
    update();
  }

  // ─── Google Places Autocomplete ───────────────────────────────────────────

  Future<void> searchSourceLocation(String query) async {
    if (query.trim().length < 2) {
      sourceSuggestions.clear();
      isSourceSuggestionVisible.value = false;
      return;
    }
    try {
      final suggestions = await _getPlaceSuggestions(query);
      sourceSuggestions.value = suggestions;
      isSourceSuggestionVisible.value = suggestions.isNotEmpty;
    } catch (e) {
      log("Error fetching source suggestions: $e");
    }
  }

  Future<void> searchDestLocation(String query) async {
    if (query.trim().length < 2) {
      destSuggestions.clear();
      isDestSuggestionVisible.value = false;
      return;
    }
    try {
      final suggestions = await _getPlaceSuggestions(query);
      destSuggestions.value = suggestions;
      isDestSuggestionVisible.value = suggestions.isNotEmpty;
    } catch (e) {
      log("Error fetching destination suggestions: $e");
    }
  }

  Future<List<PlaceSuggestion>> _getPlaceSuggestions(String query) async {
    final url = Uri.parse(
      '${ApiConstant.baseUrl}/maps/autocomplete'
      '?input=${Uri.encodeComponent(query)}'
      '&key=$_googleApiKey'
      '&components=country:in',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        final predictions = data['predictions'] as List;
        return predictions.map((p) => PlaceSuggestion.fromJson(p)).toList();
      }
    }
    return [];
  }

  Future<void> selectSourcePlace(PlaceSuggestion suggestion) async {
    sourceController.text = suggestion.description;
    isSourceSuggestionVisible.value = false;
    sourceSuggestions.clear();

    final latLng = await _getPlaceLatLng(suggestion.placeId);
    if (latLng != null) {
      startLatLng = latLng;
      _updateMarker('start', latLng, suggestion.mainText, BitmapDescriptor.hueBlue);
      _moveCameraToFit();
      if (endLatLng != null) {
        await _calculateAndSetDistance();
        await _fetchOSRMRoute();
      }
    }
    update();
  }

  Future<void> selectDestPlace(PlaceSuggestion suggestion) async {
    destinationController.text = suggestion.description;
    isDestSuggestionVisible.value = false;
    destSuggestions.clear();

    final latLng = await _getPlaceLatLng(suggestion.placeId);
    if (latLng != null) {
      endLatLng = latLng;
      _updateMarker('end', latLng, suggestion.mainText, BitmapDescriptor.hueRed);
      _moveCameraToFit();
      if (startLatLng != null) {
        await _calculateAndSetDistance();
        await _fetchOSRMRoute();
      }
    }
    update();
  }

  Future<LatLng?> _getPlaceLatLng(String placeId) async {
    try {
      final url = Uri.parse(
        '${ApiConstant.baseUrl}/maps/details'
        '?place_id=$placeId'
        '&key=$_googleApiKey',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final loc = data['result']['geometry']['location'];
          return LatLng(loc['lat'], loc['lng']);
        }
      }
    } catch (e) {
      log("Error fetching place details: $e");
    }
    return null;
  }

  void _updateMarker(String id, LatLng position, String title, double hue) {
    markers.removeWhere((m) => m.markerId.value == id);
    markers.add(
      Marker(
        markerId: MarkerId(id),
        position: position,
        infoWindow: InfoWindow(title: title),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      ),
    );
    // Polyline is drawn via _fetchOSRMRoute() once both points are set
  }

  void _moveCameraToFit() {
    if (mapController == null) return;
    if (startLatLng != null && endLatLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          math.min(startLatLng!.latitude, endLatLng!.latitude),
          math.min(startLatLng!.longitude, endLatLng!.longitude),
        ),
        northeast: LatLng(
          math.max(startLatLng!.latitude, endLatLng!.latitude),
          math.max(startLatLng!.longitude, endLatLng!.longitude),
        ),
      );
      mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    } else {
      final target = startLatLng ?? endLatLng!;
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(target, 12));
    }
  }

  // ─── Distance Calculation ─────────────────────────────────────────────────

  Future<void> _calculateAndSetDistance() async {
    if (startLatLng == null || endLatLng == null) return;
    isCalculatingDistance.value = true;
    try {
      // Try Google Distance Matrix first (road distance)
      final roadDistance = await _getRoadDistance(startLatLng!, endLatLng!);
      if (roadDistance != null) {
        distanceController.text = roadDistance.toStringAsFixed(1);
      } else {
        // Fallback: Haversine (straight-line) distance
        final haversine = _haversineDistance(startLatLng!, endLatLng!);
        distanceController.text = haversine.toStringAsFixed(1);
      }
    } catch (e) {
      log("Distance calc error: $e");
      final haversine = _haversineDistance(startLatLng!, endLatLng!);
      distanceController.text = haversine.toStringAsFixed(1);
    } finally {
      isCalculatingDistance.value = false;
    }
    update();
  }

  Future<double?> _getRoadDistance(LatLng origin, LatLng dest) async {
    try {
      final url = Uri.parse(
        '${ApiConstant.baseUrl}/maps/eta'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${dest.latitude},${dest.longitude}'
        '&key=$_googleApiKey',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final distanceMeters = data['data']['distanceMeters'] as int;
          return distanceMeters / 1000.0; // convert to km
        }
      }
    } catch (e) {
      log("Road distance error: $e");
    }
    return null;
  }

  /// Haversine formula – straight-line distance in km
  double _haversineDistance(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final sinHalfLat = math.sin(dLat / 2);
    final sinHalfLon = math.sin(dLon / 2);
    final h = sinHalfLat * sinHalfLat +
        math.cos(_toRad(a.latitude)) *
            math.cos(_toRad(b.latitude)) *
            sinHalfLon *
            sinHalfLon;
    return 2 * earthRadiusKm * math.asin(math.sqrt(h));
  }

  double _toRad(double deg) => deg * math.pi / 180;

  // ─── Map Tap (manual pin drop) ────────────────────────────────────────────

  void onMapTap(LatLng position) {
    if (startLatLng == null) {
      startLatLng = position;
      _updateMarker('start', position, sourceController.text.isEmpty ? 'Start' : sourceController.text, BitmapDescriptor.hueBlue);
      if (sourceController.text.isEmpty) {
        _reverseGeocode(position, isSource: true);
      }
    } else if (endLatLng == null) {
      endLatLng = position;
      _updateMarker('end', position, destinationController.text.isEmpty ? 'End' : destinationController.text, BitmapDescriptor.hueRed);
      if (destinationController.text.isEmpty) {
        _reverseGeocode(position, isSource: false);
      }
      _calculateAndSetDistance();
      _fetchOSRMRoute();
    } else {
      // Reset and start fresh
      startLatLng = position;
      endLatLng = null;
      markers.clear();
      polylines.clear();
      _updateMarker('start', position, 'Start', BitmapDescriptor.hueBlue);
      _reverseGeocode(position, isSource: true);
      distanceController.clear();
    }
    _moveCameraToFit();
    update();
  }

  Future<void> _reverseGeocode(LatLng position, {required bool isSource}) async {
    try {
      final url = Uri.parse(
        '${ApiConstant.baseUrl}/maps/geocode'
        '?latlng=${position.latitude},${position.longitude}'
        '&key=$_googleApiKey',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final address = data['results'][0]['formatted_address'] as String;
          if (isSource) {
            sourceController.text = address;
          } else {
            destinationController.text = address;
          }
          update();
        }
      }
    } catch (e) {
      log("Reverse geocode error: $e");
    }
  }

  // ─── OSRM Road Geometry Polyline ─────────────────────────────────────────

  /// Fetches the actual driving-road geometry from OSRM and draws it as a
  /// polyline. Falls back silently (no polyline) on network errors.
  Future<void> _fetchOSRMRoute() async {
    if (startLatLng == null || endLatLng == null) return;
    isCalculatingDistance.value = true;
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${startLatLng!.longitude},${startLatLng!.latitude};'
          '${endLatLng!.longitude},${endLatLng!.latitude}'
          '?overview=full&geometries=geojson';
      final response = await Dio().get(url);
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final routes = data['routes'] as List;
        if (routes.isNotEmpty) {
          final geometry = routes[0]['geometry']['coordinates'] as List;
          final points = geometry
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          polylines
            ..clear()
            ..add(
              Polyline(
                polylineId: const PolylineId('route_line'),
                points: points,
                color: Colors.blue,
                width: 5,
              ),
            );
          update();
        }
      }
    } catch (e) {
      log('OSRM route error: $e');
      // Fallback: straight-line polyline
      polylines
        ..clear()
        ..add(
          Polyline(
            polylineId: const PolylineId('route_line'),
            points: [startLatLng!, endLatLng!],
            color: Colors.blue,
            width: 5,
          ),
        );
      update();
    } finally {
      isCalculatingDistance.value = false;
    }
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> getRoutes() async {
    isLoading.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.get(
        Uri.parse("${ApiConstant.baseUrl}/admin/routes"),
        headers: ApiConstant.headers(token: token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null) {
          List list = data['routes'];
          routesList.value = list.map((e) => AdminVehicleRoute.fromJson(e)).toList();
        }
      }
    } catch (e) {
      log("Error fetching routes: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveRoute() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final sourceName = sourceController.text.trim();
      final destName = destinationController.text.trim();
      final body = {
        "name": nameController.text.trim(),
        "source": sourceName,
        "destination": destName,
        "startLocation": sourceName,
        "endLocation": destName,
        "distance": double.tryParse(distanceController.text.trim()) ?? 0.0,
        "startLat": startLatLng?.latitude,
        "startLng": startLatLng?.longitude,
        "endLat": endLatLng?.latitude,
        "endLng": endLatLng?.longitude,
        "isActive": true,
        "stops": [
          if (startLatLng != null)
            {
              "name": sourceName,
              "coordinates": {
                "lat": startLatLng!.latitude,
                "lng": startLatLng!.longitude,
              },
              "estimatedTimeFromStart": 0,
            },
          if (endLatLng != null)
            {
              "name": destName,
              "coordinates": {
                "lat": endLatLng!.latitude,
                "lng": endLatLng!.longitude,
              },
              "estimatedTimeFromStart": 0,
            },
        ],
      };

      http.Response response;
      if (isEditing.value && editingRouteId != null) {
        response = await http.put(
          Uri.parse("${ApiConstant.baseUrl}/admin/routes/$editingRouteId"),
          headers: ApiConstant.headers(token: token),
          body: jsonEncode(body),
        );
      } else {
        response = await http.post(
          Uri.parse("${ApiConstant.baseUrl}/admin/routes"),
          headers: ApiConstant.headers(token: token),
          body: jsonEncode(body),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        ShowToastDialog.toast(isEditing.value ? "Route updated successfully" : "Route added successfully");
        Get.back();
        getRoutes();
      } else {
        final data = jsonDecode(response.body);
        ShowToastDialog.toast(data['message'] ?? "Failed to save route");
      }
    } catch (e) {
      log("Error saving route: $e");
      ShowToastDialog.toast("Error saving route");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteRoute(String id) async {
    isLoading.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.delete(
        Uri.parse("${ApiConstant.baseUrl}/admin/routes/$id"),
        headers: ApiConstant.headers(token: token),
      );
      if (response.statusCode == 200) {
        ShowToastDialog.toast("Route deleted successfully");
        getRoutes();
      } else {
        ShowToastDialog.toast("Failed to delete route");
      }
    } catch (e) {
      log("Error deleting route: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
