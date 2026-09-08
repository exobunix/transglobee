import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';
import '../models/booking_model.dart';
import '../models/wallet_model.dart';
import '../models/shuttle_model.dart';
import '../models/notification_model.dart';
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

  Future<ApiResponse<Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _api.post('/auth/register', {
      'name': name,
      'email': email,
      'mobileNumber': phone,
      'password': password,
    });
    
    final success = response['success'] ?? false;
    final token = response['token'];
    
    if (success && token != null) {
      await _auth.saveRestAuth(token, response);
    }

    return ApiResponse<Map<String, dynamic>>.fromJson(
      response,
      (data) => data as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });

    // Login response structure: { "success": true, "token": "...", "user": { ... } }
    final success = response['success'] ?? false;
    final token = response['token'];
    
    if (success && token != null) {
      await _auth.saveRestAuth(token, response['user'] ?? {});
    }
    
    return ApiResponse<Map<String, dynamic>>(
      success: success,
      message: response['message'],
      data: response['user'] != null ? Map<String, dynamic>.from(response['user']) : null,
    );
  }


  Future<ApiResponse<void>> logout(String deviceId) async {
    final response = await _api.post('/auth/logout', {'deviceId': deviceId});
    await _auth.clearRestAuth();
    return ApiResponse<void>.fromJson(response, (_) {});
  }

  // --- USER PROFILE ---

  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    final response = await _api.get('/user/profile');
    return ApiResponse<Map<String, dynamic>>.fromJson(
      response,
      (data) => data as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    String? name,
    String? phone,
    String? profilePic,
  }) async {
    final response = await _api.put('/user/profile', {
      'name': name,
      'mobileNumber': phone,
      'profilePic': profilePic,
    });
    return ApiResponse<Map<String, dynamic>>.fromJson(
      response,
      (data) => data as Map<String, dynamic>,
    );
  }

  // --- BOOKINGS ---

  Future<ApiResponse<BookingModel>> createBooking(Map<String, dynamic> bookingData) async {
    final String type = (bookingData['type'] ?? '').toString().toLowerCase();
    String endpoint = '/bookings/create';
    Map<String, dynamic> payload = bookingData;

    if (type == 'ride') {
      // Cab (Ola/Uber): instant broadcast to all online drivers
      endpoint = '/ride/book';
      payload = {
        if (bookingData['name'] != null) 'name': bookingData['name'],
        if (bookingData['mobileNumber'] != null) 'mobileNumber': bookingData['mobileNumber'],
        'rideMode': bookingData['vehicleType'],
        'paymentMode': bookingData['paymentMethod'] ?? 'cash',
        'fare': bookingData['fare'],
        'distance': bookingData['distance'],
        'locations': {
          'pickup': bookingData['pickupLocation'],
          'dropoff': bookingData['dropLocation'],
        },
        if (bookingData['couponCode'] != null) 'appliedCoupon': bookingData['couponCode'],
        if (bookingData['discountAmount'] != null) 'discountAmount': bookingData['discountAmount'],
      };
    } else if (type == 'logistics' || type == 'shuttle') {
      // Logistics & shuttle: admin/supervisor first, drivers after roadmap approval
      final user = _auth.currentUser;
      final userId = user?.uid?.toString() ?? bookingData['userId']?.toString();
      final pickup = bookingData['pickupLocation'] as Map<String, dynamic>?;
      final dropoff = bookingData['dropLocation'] as Map<String, dynamic>?;
      payload = {
        'userId': userId,
        'userName': bookingData['userName'] ?? user?.displayName,
        'userPhone': bookingData['userPhone'] ?? user?.phoneNumber?.toString(),
        'bookingCategory': type,
        'type': type,
        'pickup': pickup != null
            ? {
                'name': pickup['title'] ?? pickup['name'],
                'address': pickup['address'] ?? pickup['title'],
                'lat': pickup['latitude'] ?? pickup['lat'],
                'lng': pickup['longitude'] ?? pickup['lng'],
              }
            : bookingData['pickup'],
        'dropoff': dropoff != null
            ? {
                'name': dropoff['title'] ?? dropoff['name'],
                'address': dropoff['address'] ?? dropoff['title'],
                'lat': dropoff['latitude'] ?? dropoff['lat'],
                'lng': dropoff['longitude'] ?? dropoff['lng'],
              }
            : bookingData['dropoff'],
        'distanceKm': bookingData['distance'] ?? bookingData['distanceKm'],
        'vehicleType': bookingData['vehicleType'],
        'vehiclePrice': bookingData['vehiclePrice'] ?? bookingData['fare'],
        'totalPrice': bookingData['totalPrice'] ?? bookingData['fare'],
        'items': bookingData['items'],
        'helperCount': bookingData['helperCount'],
        'helperCost': bookingData['helperCost'] ?? ((bookingData['helperCount'] ?? 0) * 800.0),
        'discountAmount': bookingData['discount'] ?? bookingData['discountAmount'],
        'appliedCoupon': bookingData['couponCode'] ?? bookingData['appliedCoupon'],
        'pickupAddress': bookingData['pickupAddressDetails'] ?? bookingData['pickupAddress'],
        'receivedAddress': bookingData['deliveryAddressDetails'] ?? bookingData['receivedAddress'],
        'paymentMode': bookingData['paymentMethod'] ?? 'cash',
      };
    }

    final response = await _api.post(endpoint, payload);
    return ApiResponse<BookingModel>.fromJson(
      response,
      (data) {
        if (data is Map<String, dynamic>) {
           return BookingModel.fromJson(data);
        }
        return BookingModel.fromJson({'bookingId': ''});
      },
    );
  }


  Future<ApiResponse<BookingModel>> getBookingDetails(String bookingId) async {
    final response = await _api.getWithFallback(
      '/rides/$bookingId',
      '/ride/$bookingId',
    );
    return ApiResponse<BookingModel>.fromJson(
      response,
      (data) => BookingModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  /// Driver name, phone, vehicle + booking OTP after accept.
  Future<ApiResponse<Map<String, dynamic>>> getDriverDetailsForBooking(
    String bookingId,
  ) async {
    final response = await _api.get('/user/booking/$bookingId/driver-details');
    return ApiResponse<Map<String, dynamic>>.fromJson(
      response,
      (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> cancelBooking({required String bookingId, required String reason}) async {
    final response = await _api.post('/ride/$bookingId/cancel', {
      'reason': reason,
    });
    return ApiResponse<Map<String, dynamic>>.fromJson(
      response,
      (data) => data is Map<String, dynamic> ? data : response,
    );
  }

  Future<ApiResponse<List<BookingModel>>> getBookingHistory({int page = 1, int limit = 20}) async {
    final restToken = await _auth.getRestToken();
    final idToken = await _auth.getIdToken();
    final hasToken = restToken != null || idToken != null;

    if (!hasToken) {
      final prefs = await SharedPreferences.getInstance();
      final guestPhone = prefs.getString('guest_phone');
      if (guestPhone == null || guestPhone.isEmpty) {
        return ApiResponse<List<BookingModel>>(
          success: true,
          message: 'No active session or guest bookings',
          data: [],
        );
      }

      final response = await _api.get('/ride/history?page=$page&limit=$limit&phone=$guestPhone');
      final apiRes = ApiResponse<List<BookingModel>>.fromJson(
        response,
        (data) => (data as List).map((e) => BookingModel.fromJson(e)).toList(),
      );

      if (apiRes.success && apiRes.data != null) {
        final filteredList = apiRes.data!.where((booking) {
          final status = (booking.status ?? '').toLowerCase();
          return status != 'completed' && status != 'cancelled';
        }).toList();
        return ApiResponse<List<BookingModel>>(
          success: true,
          message: apiRes.message,
          data: filteredList,
        );
      }
      return apiRes;
    }

    final response = await _api.get('/ride/history?page=$page&limit=$limit');
    return ApiResponse<List<BookingModel>>.fromJson(
      response,
      (data) => (data as List).map((e) => BookingModel.fromJson(e)).toList(),
    );
  }

  // --- WALLET ---

  Future<ApiResponse<UserWalletState>> getWalletBalance() async {
    final response = await _api.get('/wallet/balance');
    return ApiResponse<UserWalletState>.fromJson(
      response,
      (data) => UserWalletState.fromBalanceJson(response),
    );
  }

  Future<ApiResponse<void>> topupWallet(double amount, String paymentMethod) async {
    final response = await _api.post('/wallet/topup', {
      'amount': amount,
      'paymentMethod': paymentMethod,
    });
    return ApiResponse<void>.fromJson(response, (_) {});
  }

  Future<ApiResponse<List<WalletTransaction>>> getWalletHistory({int page = 1}) async {
    final response = await _api.get('/wallet/history?page=$page');
    // Structure: { success, transactions: [...] }
    final success = response['success'] ?? false;
    final txns = response['transactions'] as List?;
    
    return ApiResponse<List<WalletTransaction>>(
      success: success,
      message: response['message'],
      data: txns?.map((e) => WalletTransaction.fromJson(e)).toList(),
    );
  }


  // --- PAYMENTS ---

  Future<ApiResponse<Map<String, dynamic>>> initiatePayment({
    required String bookingId,
    required double amount,
    required String paymentMethod,
  }) async {
    final response = await _api.post('/payments/initiate', {
      'bookingId': bookingId,
      'amount': amount,
      'paymentMethod': paymentMethod,
    });
    // Structure: { success, paymentId, status }
    return ApiResponse<Map<String, dynamic>>(
      success: response['success'] ?? false,
      message: response['message'],
      data: response, // has paymentId, status at top level
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> refundPayment({
    required String bookingId,
    required String reason,
  }) async {
    final response = await _api.post('/payments/refund', {
      'bookingId': bookingId,
      'reason': reason,
    });
    return ApiResponse<Map<String, dynamic>>.fromJson(
      response,
      (data) => response,
    );
  }

  // --- SHUTTLE ---

  Future<ApiResponse<List<ShuttleRoute>>> getShuttleRoutes() async {
    final response = await _api.get('/shuttle/routes');
    // Structure: { success, routes: [...] }
    final success = response['success'] ?? false;
    final routes = response['routes'] as List?;

    return ApiResponse<List<ShuttleRoute>>(
      success: success,
      message: response['message'],
      data: routes?.map((e) => ShuttleRoute.fromJson(e)).toList(),
    );
  }


  Future<ApiResponse<BookingModel>> bookShuttle({
    required String routeId,
    required int seats,
    required String scheduledDate,
  }) async {
    final response = await _api.post('/shuttle/book', {
      'routeId': routeId,
      'seats': seats,
      'scheduledDate': scheduledDate,
    });
    return ApiResponse<BookingModel>.fromJson(
      response,
      (data) => BookingModel.fromJson(data as Map<String, dynamic>),
    );
  }


  Future<ApiResponse<ShuttleTracking>> trackShuttle(String bookingId) async {
    final response = await _api.get('/shuttle/track/$bookingId');
    return ApiResponse<ShuttleTracking>.fromJson(
      response,
      (data) => ShuttleTracking.fromJson(data),
    );
  }

  // --- NOTIFICATIONS ---

  Future<ApiResponse<List<NotificationModel>>> getNotifications() async {
    try {
      final response = await _api.get('/notifications');
      // Structure: { success, notifications: [...] }
      final success = response['success'] ?? false;
      final list = response['notifications'] as List?;
      
      return ApiResponse<List<NotificationModel>>(
        success: success,
        message: response['message'],
        data: list?.map((e) => NotificationModel.fromJson(e)).toList(),
      );
    } catch (e) {
      return ApiResponse<List<NotificationModel>>(
        success: false,
        message: e.toString(),
        data: [],
      );
    }
  }

  // --- CMS ---

  Future<ApiResponse<List<dynamic>>> getCMSContent(String type) async {
    final response = await _api.get('/user/cms?type=$type');
    final success = response['success'] ?? false;
    final list = response['contents'] as List? ?? [];
    return ApiResponse<List<dynamic>>(
      success: success,
      message: response['message'],
      data: list,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> estimateFare({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> dropoff,
  }) async {
    final response = await _api.post('/pricing/estimate-fare', {
      'pickup': pickup,
      'dropoff': dropoff,
    });
    return ApiResponse<Map<String, dynamic>>.fromJson(
      response,
      (data) => data as Map<String, dynamic>,
    );
  }
}
