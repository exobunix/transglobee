import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../core/config.dart';
import '../models/address_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/rest_api_repository.dart';
import 'api_state_providers.dart';
import 'logistics_booking_state.dart';
import 'logistics_vehicle_provider.dart';

class LogisticsBookingNotifier extends Notifier<LogisticsBookingState> {
  @override
  LogisticsBookingState build() {
    return LogisticsBookingState();
  }

  // ─── Direct State Mutators ───────────────────────────────────────────
  void selectRoute(UserRoute? route) {
    state = state.copyWith(selectedRoute: () => route);
  }

  void selectVehicle(String? vehicle, LogisticsVehicle? vehicleData) {
    state = state.copyWith(
      selectedVehicle: () => vehicle,
      selectedVehicleData: () => vehicleData,
    );
  }

  void selectGoodType(String? type) {
    state = state.copyWith(selectedGoodType: () => type);
  }

  void setUnit(String unit) {
    state = state.copyWith(selectedUnit: unit);
  }

  void setHelperCount(int count) {
    state = state.copyWith(helperCount: count);
  }

  void selectPickupAddress(AddressEntry? address) {
    state = state.copyWith(selectedPickupAddress: () => address);
  }

  void selectDropoffAddress(AddressEntry? address) {
    state = state.copyWith(selectedDropoffAddress: () => address);
  }

  void removeAddedItem(int index) {
    final newList = List<LogisticsItemEntry>.from(state.addedItems)..removeAt(index);
    state = state.copyWith(addedItems: newList);
  }

  void clearAddedItems() {
    state = state.copyWith(addedItems: const []);
  }

  void setCoupon(String? coupon, double discount) {
    state = state.copyWith(
      appliedCoupon: () => coupon,
      discountAmount: discount,
    );
  }

  void setRouteInfo(List<LatLng> points, double distance) {
    state = state.copyWith(routePoints: points, distance: distance);
  }

  void setBooking(bool isBooking) {
    state = state.copyWith(isBooking: isBooking);
  }

  // Helper getters/computations
  double get helperCostPerPerson => state.selectedVehicleData?.helperCostRate ?? 800.0;
  double get helperCost => state.helperCount * helperCostPerPerson;
  
  double get vehiclePrice {
    if (state.selectedVehicleData == null) return 0.0;
    double total = state.selectedVehicleData!.basePrice;
    if (state.pickup != null && state.dropoff != null) {
      total += state.selectedVehicleData!.pricePerKm * state.distance;
    }
    total += state.selectedVehicleData!.pricePerPiece * state.addedItems.length;
    return total;
  }

  double get totalPrice => (vehiclePrice + helperCost - state.discountAmount).clamp(0.0, double.infinity);

  // ─── API Helpers ─────────────────────────────────────────────────────
  Future<Map<String, String>> _authHeaders({bool includeContentType = true}) async {
    return ref.read(authServiceProvider).buildAuthHeaders(
          includeContentType: includeContentType,
        );
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val) ?? 0.0;
    }
    return 0.0;
  }

  // ─── Autocomplete / Address suggestions ──────────────────────────────
  Future<void> fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(suggestions: const []);
      return;
    }

    state = state.copyWith(isFetchingSuggestions: true);
    try {
      final apiKey = AppConfig.googleMapsApiKey;
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get(
        '/maps/autocomplete?input=${Uri.encodeComponent(query)}&key=$apiKey&components=country:in',
      );

      final List predictions = (response as Map<String, dynamic>)['predictions'] ?? [];
      final results = predictions
          .map((item) => {
                'name': item['structured_formatting']['main_text'] as String,
                'address': item['description'] as String,
                'place_id': item['place_id'] as String,
              })
          .toList();
      state = state.copyWith(suggestions: results, isFetchingSuggestions: false);
    } catch (e) {
      state = state.copyWith(isFetchingSuggestions: false);
    }
  }

  Future<void> selectSuggestion(Map<String, dynamic> suggestion, bool isPickup) async {
    try {
      double lat = 0.0;
      double lng = 0.0;
      
      if (suggestion['place_id'] != null && suggestion['place_id'].toString().isNotEmpty) {
        final apiKey = AppConfig.googleMapsApiKey;
        final apiService = ref.read(apiServiceProvider);
        final response = await apiService.get(
          '/maps/details?place_id=${suggestion['place_id']}&key=$apiKey&fields=geometry',
        );
        final loc = (response as Map<String, dynamic>)['result']['geometry']['location'];
        lat = loc['lat'] as double;
        lng = loc['lng'] as double;
      } else {
        lat = _parseDouble(suggestion['lat']);
        lng = _parseDouble(suggestion['lng']);
      }

      final result = {
        'name': suggestion['name'],
        'address': suggestion['address'],
        'lat': lat,
        'lng': lng,
      };

      if (isPickup) {
        state = state.copyWith(
          pickup: () => result,
          suggestions: const [],
        );
      } else {
        state = state.copyWith(
          dropoff: () => result,
          suggestions: const [],
        );
      }
      await fetchRoute();
    } catch (e) {
      debugPrint('Error selecting suggestion: $e');
    }
  }

  // ─── Routing ─────────────────────────────────────────────────────────
  Future<void> fetchRoute() async {
    if (state.pickup == null || state.dropoff == null) return;
    final pLat = _parseDouble(state.pickup!['lat']);
    final pLng = _parseDouble(state.pickup!['lng']);
    final dLat = _parseDouble(state.dropoff!['lat']);
    final dLng = _parseDouble(state.dropoff!['lng']);
    if (pLat == 0 || dLat == 0) return;

    state = state.copyWith(isFetchingRoute: true);
    final url = 'https://router.project-osrm.org/route/v1/driving/$pLng,$pLat;$dLng,$dLat?overview=full&geometries=geojson';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;
        if (routes.isNotEmpty) {
          final route = routes[0];
          final geometry = route['geometry']['coordinates'] as List;
          final distance = (route['distance'] as num).toDouble() / 1000.0;
          final routePoints = geometry
              .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();
          state = state.copyWith(
            distance: distance,
            routePoints: routePoints,
            isFetchingRoute: false,
          );
        } else {
          state = state.copyWith(isFetchingRoute: false);
        }
      } else {
        state = state.copyWith(isFetchingRoute: false);
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
      state = state.copyWith(isFetchingRoute: false);
    }
  }

  // ─── Add Logistics Item ──────────────────────────────────────────────
  Future<void> addItemToList({
    required String name,
    required String goodTypeName,
    required double length,
    required double height,
    required double width,
    required Uint8List? imageBytes,
    required String? imageName,
  }) async {
    state = state.copyWith(isAddingItem: true);
    try {
      String? uploadedUrl;
      if (imageBytes != null && imageName != null) {
        uploadedUrl = await _uploadImageToImageKit(imageBytes, imageName);
      }

      final item = LogisticsItemEntry(
        name: name,
        type: goodTypeName.isEmpty ? 'General' : goodTypeName,
        length: length,
        height: height,
        width: width,
        unit: state.selectedUnit,
        imageBytes: imageBytes,
        imageName: imageName,
        savedImageUrl: uploadedUrl,
      );

      final newList = List<LogisticsItemEntry>.from(state.addedItems)..add(item);
      state = state.copyWith(
        addedItems: newList,
        isAddingItem: false,
      );
    } catch (e) {
      state = state.copyWith(isAddingItem: false);
      rethrow;
    }
  }

  Future<String?> _uploadImageToImageKit(Uint8List bytes, String fileName) async {
    final authService = ref.read(authServiceProvider);
    await authService.waitForSession();
    final userId = authService.currentUser?.uid as String? ?? 'guest';

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/logistic-goods/upload-image');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _authHeaders(includeContentType: false));
    request.fields['userId'] = userId;
    request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: fileName));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['url'] as String?;
    }
    return null;
  }

  // ─── Finalize and Book ────────────────────────────────────────────────
  String? validateBookingInputs() {
    if (state.selectedRoute == null) {
      return 'Please select an assigned route first';
    }
    if (state.selectedVehicleData == null) {
      return 'Please select a vehicle before booking';
    }
    if (state.pickup == null || state.dropoff == null) {
      return 'Please select both pickup and drop locations on the map';
    }
    if ((state.pickup?['address']?.toString().trim().toLowerCase() ?? '') ==
        (state.dropoff?['address']?.toString().trim().toLowerCase() ?? '')) {
      return 'Pickup and drop locations must be different';
    }
    if (state.addedItems.isEmpty) {
      return 'Please add at least one item with complete details';
    }

    final pLat = _parseDouble(state.pickup!['lat']);
    final routeStartLat = state.selectedRoute!.startLat ?? 0.0;
    final diffLat = (pLat - routeStartLat).abs();

    if (diffLat > 0.01) {
      return 'Pickup location must match the selected route start location: ${state.selectedRoute!.startLocation ?? state.selectedRoute!.name}';
    }

    if (state.selectedPickupAddress == null) {
      return 'Please select a Pickup Address from your address book (tap "Pickup Address" below)';
    }
    if (state.selectedPickupAddress!.type != 'pickup') {
      return 'The selected pickup address is not of type "Pickup". Please choose a valid pickup address';
    }
    if (state.selectedDropoffAddress == null) {
      return 'Please select a Delivery Address from your address book (tap "Delivery Address" below)';
    }
    if (state.selectedDropoffAddress!.type != 'received') {
      return 'The selected delivery address is not of type "Received". Please choose a valid delivery address';
    }
    return null;
  }

  Future<void> bookLogisticsRide() async {
    final validationError = validateBookingInputs();
    if (validationError != null) {
      state = state.copyWith(errorMessage: () => validationError);
      return;
    }

    state = state.copyWith(isBooking: true, errorMessage: () => null);

    try {
      final goodTypeName = state.selectedGoodType ?? 'General';
      await _saveAllItemsToDB(goodTypeName);

      final pickupPayload = {
        'type': 'pickup',
        'label': state.selectedPickupAddress!.label,
        'fullAddress': state.pickup!['address'],
        'houseNumber': state.selectedPickupAddress!.houseNumber,
        'floorNumber': state.selectedPickupAddress!.floorNumber,
        'landmark': state.selectedPickupAddress!.landmark,
        'city': state.selectedPickupAddress!.city,
        'pincode': state.selectedPickupAddress!.pincode,
        'phone': state.selectedPickupAddress!.phone,
        'email': state.selectedPickupAddress!.email,
      };

      final receivedPayload = {
        'type': 'received',
        'label': state.selectedDropoffAddress!.label,
        'fullAddress': state.dropoff!['address'],
        'houseNumber': state.selectedDropoffAddress!.houseNumber,
        'floorNumber': state.selectedDropoffAddress!.floorNumber,
        'landmark': state.selectedDropoffAddress!.landmark,
        'city': state.selectedDropoffAddress!.city,
        'pincode': state.selectedDropoffAddress!.pincode,
        'phone': state.selectedDropoffAddress!.phone,
        'email': state.selectedDropoffAddress!.email,
      };

      final repo = ref.read(restApiRepositoryProvider);
      final payload = {
        'type': 'logistics',
        'pickupLocation': {
          'title': state.pickup!['name'],
          'address': state.pickup!['address'],
          'latitude': _parseDouble(state.pickup!['lat']),
          'longitude': _parseDouble(state.pickup!['lng']),
        },
        'dropLocation': {
          'title': state.dropoff!['name'],
          'address': state.dropoff!['address'],
          'latitude': _parseDouble(state.dropoff!['lat']),
          'longitude': _parseDouble(state.dropoff!['lng']),
        },
        'distance': state.distance,
        'vehicleType': state.selectedVehicle ?? 'General',
        'items': state.addedItems.map((item) => {
          'itemName': item.name,
          'type': item.type,
          'length': item.length,
          'height': item.height,
          'width': item.width,
          'unit': item.unit,
          'imageUrl': item.savedImageUrl,
        }).toList(),
        'helperCount': state.helperCount,
        'helperCost': helperCost,
        'vehiclePrice': vehiclePrice,
        'discount': state.discountAmount,
        'fare': totalPrice,
        'couponCode': state.appliedCoupon,
        'pickupAddressDetails': pickupPayload,
        'deliveryAddressDetails': receivedPayload,
        'routeId': state.selectedRoute?.id,
      };

      final response = await repo.createBooking(payload);

      if (response.success && response.data != null) {
        state = state.copyWith(
          bookingSuccessId: () => response.data!.bookingId,
          isBooking: false,
        );
      } else {
        state = state.copyWith(
          errorMessage: () => response.message ?? 'Failed to save booking',
          isBooking: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: () => e.toString(),
        isBooking: false,
      );
    }
  }

  Future<void> _saveAllItemsToDB(String goodTypeName) async {
    final authService = ref.read(authServiceProvider);
    await authService.waitForSession();
    final userId = authService.currentUser?.uid as String? ?? 'guest';
    final headers = await _authHeaders(includeContentType: false);

    for (final item in state.addedItems) {
      try {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}/logistic-goods');
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(headers);
        request.fields['userId'] = userId;
        request.fields['itemName'] = item.name;
        request.fields['type'] = item.type;
        request.fields['length'] = item.length.toString();
        request.fields['height'] = item.height.toString();
        request.fields['width'] = item.width.toString();
        request.fields['unit'] = item.unit;
        if (item.savedImageUrl != null) {
          request.fields['imageUrl'] = item.savedImageUrl!;
        }
        await request.send();
      } catch (e) {
        debugPrint('Error saving item: $e');
      }
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: () => null);
  }

  void clearBookingSuccess() {
    state = state.copyWith(bookingSuccessId: () => null);
  }
}

final logisticsBookingProvider = NotifierProvider.autoDispose<LogisticsBookingNotifier, LogisticsBookingState>(() {
  return LogisticsBookingNotifier();
});
