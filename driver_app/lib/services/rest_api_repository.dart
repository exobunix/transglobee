import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_response.dart';
import '../models/booking_model.dart';
import '../models/driver_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

final restApiRepositoryProvider = Provider<RestApiRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final authService = ref.watch(authServiceProvider);
  return RestApiRepository(apiService, authService);
});

class RestApiRepository {
  final ApiService _api;
  final AuthService _auth;

  RestApiRepository(this._api, this._auth);

  // --- AUTH ---
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/driver/login', {
      'email': email,
      'password': password,
    });

    final success = response['success'] ?? (response['token'] != null);
    final token = response['token'];
    final driverData =
        response['driver'] ?? response['user'] ?? response['data'];

    if (success && token != null) {
      await _auth.saveRestAuth(token, driverData ?? response);
    }

    return ApiResponse<Map<String, dynamic>>(
      success: success,
      message: response['message'],
      data: driverData != null ? Map<String, dynamic>.from(driverData) : null,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> register(
      Map<String, dynamic> data) async {
    final response = await _api.post('/driver/register', data);

    final bool success = response['success'] ?? (response['token'] != null);
    final String? token = response['token'];
    final driverData =
        response['driver'] ?? response['user'] ?? response['data'];

    if (success && token != null) {
      await _auth.saveRestAuth(token, driverData ?? response);
    }

    return ApiResponse<Map<String, dynamic>>(
      success: success,
      message: response['message'],
      data: driverData != null ? Map<String, dynamic>.from(driverData) : null,
    );
  }

  // --- DRIVER PROFILE & STATUS ---
  Future<ApiResponse<DriverModel>> getProfile() async {
    final response = await _api.get('/driver/profile');
    final driverData = response['driver'] ?? response['data'] ?? response;

    return ApiResponse<DriverModel>(
      success: response['success'] ?? (driverData != null),
      message: response['message'] ?? '',
      data: driverData != null ? DriverModel.fromJson(driverData) : null,
    );
  }

  Future<ApiResponse<void>> updateStatus(
      {required bool isOnline, String? status}) async {
    final response = await _api.put('/driver/status', {
      'isOnline': isOnline,
      if (status != null) 'status': status,
    });
    return ApiResponse<void>.fromJson(response, (_) {});
  }

  // --- BOOKING ACTIONS ---
  Future<ApiResponse<List<BookingModel>>> getAvailableBookings() async {
    final response = await _api.get('/driver/pending-bookings');
    return ApiResponse<List<BookingModel>>.fromJson(
      response,
      (data) => (data as List).map((e) => BookingModel.fromJson(e)).toList(),
    );
  }

  Future<ApiResponse<void>> acceptBooking(String bookingId) async {
    final response = await _api.patch('/booking/$bookingId/accept', {});
    return ApiResponse<void>.fromJson(response, (_) {});
  }

  /// Cab ride (History) — first driver to accept wins
  Future<ApiResponse<void>> assignCabRide(
    String rideId,
    String driverId, {
    double? fare,
  }) async {
    final response = await _api.putWithFallback(
      '/rides/$rideId/assign',
      '/ride/rides/$rideId/assign',
      {
        'driverId': driverId,
        if (fare != null) 'fare': fare,
      },
    );
    return ApiResponse<void>.fromJson(response, (_) {});
  }

  Future<ApiResponse<void>> rejectCabRide(String rideId, String driverId) async {
    final response = await _api.putWithFallback(
      '/rides/$rideId/reject',
      '/ride/rides/$rideId/reject',
      {'driverId': driverId},
    );
    return ApiResponse<void>.fromJson(response, (_) {});
  }

  Future<ApiResponse<void>> updateBookingStatus(
      String bookingId, String status, {String bookingType = 'CAB'}) async {
    final type = bookingType.toUpperCase();
    if (type == 'LOGISTICS' || type == 'SHUTTLE') {
      String backendStatus = status;
      if (status == 'ongoing') backendStatus = 'in_transit';
      if (status == 'completed') backendStatus = 'delivered';

      final response = await _api.patch('/logistics-bookings/$bookingId/status', {
        'status': backendStatus,
      });
      return ApiResponse<void>.fromJson(response, (_) {});
    } else {
      final response = await _api.putWithFallback(
        '/rides/$bookingId/status',
        '/ride/rides/$bookingId/status',
        {
          'status': status,
        },
      );
      return ApiResponse<void>.fromJson(response, (_) {});
    }
  }

  Future<ApiResponse<void>> completeBooking(
      String bookingId, double actualFare, {String bookingType = 'CAB'}) async {
    final type = bookingType.toUpperCase();
    if (type == 'LOGISTICS' || type == 'SHUTTLE') {
      final response = await _api.patch('/logistics-bookings/$bookingId/status', {
        'status': 'delivered',
        'actualFare': actualFare,
      });
      return ApiResponse<void>.fromJson(response, (_) {});
    } else {
      final response = await _api.putWithFallback(
        '/rides/$bookingId/complete',
        '/ride/rides/$bookingId/complete',
        {
          'status': 'completed',
          'actualFare': actualFare,
        },
      );
      return ApiResponse<void>.fromJson(response, (_) {});
    }
  }

  // --- EARNINGS & WALLET ---
  Future<ApiResponse<Map<String, dynamic>>> topupWallet(double amount, {String method = 'upi'}) async {
    final response = await _api.post('/wallet/topup', {
      'amount': amount,
      'method': method,
    });
    return ApiResponse<Map<String, dynamic>>.fromJson(
      response,
      (data) => data is Map<String, dynamic> ? data : {},
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getEarnings() async {
    final response = await _api.get('/driver/earnings');
    return ApiResponse<Map<String, dynamic>>.fromJson(
      response,
      (data) => data as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getDriverWallet() async {
    final response = await _api.get('/driver/wallet');
    return ApiResponse<Map<String, dynamic>>.fromJson(
      response,
      (data) => data as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<List<BookingModel>>> getBookingHistory() async {
    final response = await _api.get('/driver/bookings/history');
    return ApiResponse<List<BookingModel>>.fromJson(
      response,
      (data) => (data as List).map((e) => BookingModel.fromJson(e)).toList(),
    );
  }

  Future<ApiResponse<void>> updateLocation(
    double lat,
    double lng, {
    double? heading,
  }) async {
    final response = await _api.put('/driver/location', {
      'latitude': lat,
      'longitude': lng,
      if (heading != null) 'heading': heading,
    });
    return ApiResponse<void>.fromJson(response, (_) {});
  }

  Future<ApiResponse<BookingModel>> getBookingById(String bookingId) async {
    final response = await _api.getWithFallback(
      '/rides/$bookingId',
      '/ride/rides/$bookingId',
    );
    final bookingData = response['data'] ?? response;
    return ApiResponse<BookingModel>(
      success: response['success'] ?? (bookingData != null),
      message: response['message'] ?? '',
      data: bookingData != null ? BookingModel.fromJson(Map<String, dynamic>.from(bookingData)) : null,
    );
  }
}
