import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ride_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

final rideServiceProvider = Provider<RideService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final authService = ref.watch(authServiceProvider);
  return RideService(apiService, authService);
});

final myRidesProvider = FutureProvider<List<RideModel>>((ref) async {
  final rideService = ref.watch(rideServiceProvider);
  return rideService.getMyRides();
});

class RideService {
  final ApiService _apiService;
  final AuthService _authService;

  RideService(this._apiService, this._authService);

  String? _extractMobileNumber() {
    final user = _authService.currentUser;
    final dynamic phone = user?.phoneNumber;
    if (phone != null && phone.toString().trim().isNotEmpty) {
      return phone.toString().trim();
    }
    return null;
  }

  String _ridePath(String suffix) => '/rides$suffix';
  String _legacyRidePath(String suffix) => '/ride$suffix';

  Future<RideModel> createRide({
    required List<double> pickupCoordinates,
    required List<double> dropoffCoordinates,
    required String pickupAddress,
    required String dropoffAddress,
    required String serviceType,
    required double fareEstimation,
    required double distance,
    required double duration,
    bool isScheduled = false,
    DateTime? scheduledTime,
    String? vehicleType,
    String? typeOfGood,
  }) async {
    final mobileNumber = _extractMobileNumber();
    final payload = {
      'mobileNumber': ?mobileNumber,
      'locations': {
        'pickup': {
          'title': pickupAddress,
          'address': pickupAddress,
          'latitude': pickupCoordinates.isNotEmpty ? pickupCoordinates[0] : 0,
          'longitude': pickupCoordinates.length > 1 ? pickupCoordinates[1] : 0,
        },
        'dropoff': {
          'title': dropoffAddress,
          'address': dropoffAddress,
          'latitude': dropoffCoordinates.isNotEmpty ? dropoffCoordinates[0] : 0,
          'longitude': dropoffCoordinates.length > 1 ? dropoffCoordinates[1] : 0,
        },
      },
      'rideMode': serviceType,
      'fare': fareEstimation,
      'distance': distance,
      'duration': duration,
      'paymentMode': 'cash',
      'isScheduled': isScheduled,
      if (scheduledTime != null) 'scheduledTime': scheduledTime.toIso8601String(),
      'vehicleType': ?vehicleType,
      'typeOfGood': ?typeOfGood,
    };
    final response = await _apiService.postWithFallback(
      _ridePath('/book'),
      _legacyRidePath('/ride-request'),
      payload,
    );
    return RideModel.fromJson(response['data'] ?? response);
  }

  Future<RideModel> createRideRequest({
    required Map<String, dynamic> locations,
    required String rideMode,
    required double fare,
    String? distance,
    String? paymentMode,
    String? vehicleType,
    String? typeOfGood,
    int? helperCount,
    List<Map<String, dynamic>>? logisticItems,
  }) async {
    final mobileNumber = _extractMobileNumber();
    final payload = {
      'mobileNumber': ?mobileNumber,
      'locations': locations,
      'rideMode': rideMode,
      'fare': fare,
      'distance': ?distance,
      'paymentMode': ?paymentMode,
      'vehicleType': ?vehicleType,
      'typeOfGood': ?typeOfGood,
      'helperCount': ?helperCount,
      'logisticItems': ?logisticItems,
    };
    final response = await _apiService.postWithFallback(
      _ridePath('/book'),
      _legacyRidePath('/ride-request'),
      payload,
    );
    return RideModel.fromJson(response['data'] ?? response);
  }

  Future<List<RideModel>> getMyRides() async {
    final response = await _apiService.getWithFallback(
      _ridePath('/history'),
      _legacyRidePath('/my-rides'),
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response['rides'] ?? response) : response;
    if (data is List) {
      return data.map((e) => RideModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    return [];
  }

  Future<RideModel?> getRideById(String rideId) async {
    final data = await fetchRidePayload(rideId);
    return data != null ? RideModel.fromJson(data) : null;
  }

  Future<Map<String, dynamic>?> fetchRidePayload(String rideId) async {
    final response = await _apiService.getWithFallback(
      _ridePath('/$rideId'),
      _legacyRidePath('/rides/$rideId'),
    );
    if (response is! Map<String, dynamic>) return null;
    if (response['success'] != true) return null;
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  bool isRideAcceptedStatus(String? status) {
    if (status == null) return false;
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
      case 'on_the_way':
      case 'arrived':
      case 'ongoing':
      case 'in_transit':
        return true;
      default:
        return false;
    }
  }

  Future<RideModel> updateRideStatus(
    String rideId,
    String status, {
    String? delayReason,
  }) async {
    final payload = {
      'status': status,
      'delayReason': ?delayReason,
    };
    final response = await _apiService.putWithFallback(
      _ridePath('/$rideId/status'),
      _legacyRidePath('/rides/$rideId/status'),
      payload,
    );
    final data = response['ride'] ?? response['data'] ?? response;
    return RideModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<RideModel> cancelRide(String rideId) async {
    return updateRideStatus(rideId, 'cancelled');
  }

  Future<Map<String, dynamic>> updateFare(String rideId, int extraFare) async {
    final response = await _apiService.putWithFallback(
      _ridePath('/fare'),
      _legacyRidePath('/update-fare'),
      {
      'rideId': rideId,
      'extraFare': extraFare,
      },
    );
    return response;
  }

  Future<void> submitReview({
    required String bookingId,
    required String driverId,
    required int rating,
    required String comment,
  }) async {
    await _apiService.postWithFallback(
      _ridePath('/$bookingId/rate'),
      _legacyRidePath('/review'),
      {
      'bookingId': bookingId,
      'driverId': driverId,
      'rating': rating,
      'comment': comment,
      },
    );
  }
}
