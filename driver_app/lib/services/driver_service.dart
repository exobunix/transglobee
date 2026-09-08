import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/booking_provider.dart';
import '../providers/active_ride_tracking_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/driver_model.dart';
import '../models/booking_model.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'socket_service.dart';

import 'rest_api_repository.dart';

final driverServiceProvider = Provider<DriverService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final socketService = ref.watch(socketServiceProvider);
  final repo = ref.watch(restApiRepositoryProvider);
  return DriverService(apiService, authService, socketService, repo, ref);
});

final driverProfileProvider = FutureProvider<DriverModel?>((ref) async {
  // Watch authStateProvider to trigger recheck on login/logout
  final authStateAsync = ref.watch(authStateProvider);
  final currentUser = authStateAsync.value;
  
  final authService = ref.watch(authServiceProvider);
  final dbService = ref.watch(databaseServiceProvider);
  final driverId = currentUser?.uid?.toString();
  if (driverId == null || driverId.isEmpty) return null;
  final token = await authService.getIdToken();
  if (token == null || token.isEmpty) {
    return _fallbackDriverProfile(currentUser);
  }

  final profile = await dbService.getDriverProfile(driverId, token);
  if (profile != null) return profile;

  try {
    await dbService.saveDriverToBackend(currentUser, token);
    final syncedProfile = await dbService.getDriverProfile(driverId, token);
    if (syncedProfile != null) return syncedProfile;
  } catch (e) {
    debugPrint('Driver profile sync fallback failed: $e');
  }

  return _fallbackDriverProfile(currentUser);
});

DriverModel _fallbackDriverProfile(dynamic currentUser) {
  final uid = currentUser?.uid?.toString() ?? '';
  final email = currentUser?.email?.toString() ?? '';
  final name = currentUser?.displayName?.toString();
  return DriverModel(
    id: uid,
    firebaseId: uid,
    email: email,
    name: (name != null && name.trim().isNotEmpty)
        ? name
        : (email.isNotEmpty ? email.split('@').first : 'Driver'),
    vehicleId: '',
    status: 'pending',
    isOnline: false,
    onboardingComplete: false,
    isEmailVerified: email.isNotEmpty,
    documents: const [],
  );
}
class DriverService {
  final ApiService _api;
  final AuthService _auth;
  final SocketService _socket;
  final RestApiRepository _repo;
  final Ref _ref;
  late final DatabaseReference _locationRef;
  StreamSubscription<Position>? _positionSub;

  DriverService(this._api, this._auth, this._socket, this._repo, this._ref) {
    try {
      _locationRef = FirebaseDatabase.instance.ref("drivers");
    } catch (e) {
      debugPrint('[FIREBASE] Database ref initialization failed: $e');
    }
  }

  String _ridesPath(String suffix) => '/rides$suffix';
    String _legacyRidePath(String suffix) => '/ride$suffix';

  // String _legacyRidePath(String suffix) => '/api/ride$suffix';

  // --- Location Streaming ---
  Future<void> setOnline(bool online) async {
    final driverId = _auth.currentUser?.uid;
    if (driverId == null) return;

    if (online) {
      await _locationRef.child(driverId).update({'status': 'online'});
      await _repo.updateStatus(isOnline: true, status: 'active');
      _startLocationStream(driverId);
    } else {
      await _locationRef.child(driverId).update({'status': 'offline'});
      await _repo.updateStatus(isOnline: false, status: 'offline');
      _stopLocationStream();
    }
  }

  void _startLocationStream(String driverId) {
    _stopLocationStream();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, 
        distanceFilter: 2, // 2 meters for smoother tracking
      ),
    ).listen((pos) {
      // 1. Update Firebase RD (Already there)
      _locationRef.child(driverId).update({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'heading': pos.heading,
        'lastUpdate': DateTime.now().toIso8601String(),
      });

      // 2. Stream live location to user during active rides (Ola/Uber style)
      try {
        final tracking = _ref.read(activeRideTrackingProvider);
        final activeBooking = _ref.read(currentActiveBookingProvider);
        final rideId = tracking?.rideId ?? activeBooking?.id;
        final userId = tracking?.userId ?? activeBooking?.userId ?? '';
        final status = activeBooking?.status ?? 'accepted';

        if (rideId != null &&
            rideId.isNotEmpty &&
            ['accepted', 'confirmed', 'on_the_way', 'arrived', 'ongoing', 'in_transit']
                .contains(status)) {
          _socket.updateLocation(
            rideId: rideId,
            userId: userId,
            latitude: pos.latitude,
            longitude: pos.longitude,
            heading: pos.heading,
          );
          unawaited(() async {
            try {
              await _repo.updateLocation(
                pos.latitude,
                pos.longitude,
                heading: pos.heading,
              );
            } catch (_) {}
          }());
        }
      } catch (e) {
        debugPrint("Error sending socket location update: $e");
      }
    });
  }

  void _stopLocationStream() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  // --- Ride Status Management ---
  Future<void> updateRideStatus(String rideId, String status, {String bookingType = 'CAB'}) async {
    await _repo.updateBookingStatus(rideId, status, bookingType: bookingType);
  }

  Future<void> acceptRide(
    String rideId, {
    double? fare,
    required String driverId,
    String bookingType = 'CAB',
  }) async {
    final type = bookingType.toUpperCase();
    if (type == 'LOGISTICS' || type == 'SHUTTLE') {
      await acceptBooking(rideId);
      return;
    }
    await _repo.assignCabRide(rideId, driverId, fare: fare);
  }

  Future<void> rejectRide(String rideId, {required String driverId, String bookingType = 'CAB'}) async {
    final type = bookingType.toUpperCase();
    if (type == 'LOGISTICS' || type == 'SHUTTLE') {
      await rejectBooking(rideId);
      return;
    }
    await _repo.rejectCabRide(rideId, driverId);
  }

  // --- New Logistics Booking APIs ---
  Future<void> acceptBooking(String id) async {
    try {
      await _api.patchWithFallback(
        '/logistics/$id/accept-roadmap',
        '/booking/$id/accept',
        {},
      );
      debugPrint('>>> Logistics booking $id accepted successfully');
    } catch (e) {
      debugPrint('>>> Error accepting logistics booking: $e');
      rethrow;
    }
  }

  Future<void> rejectBooking(String id) async {
    try {
      await _api.patchWithFallback(
        '/logistics/$id/cancel',
        '/booking/$id/reject',
        {},
      );
      debugPrint('>>> Logistics booking $id rejected successfully');
    } catch (e) {
      debugPrint('>>> Error rejecting logistics booking: $e');
      rethrow;
    }
  }

  Future<void> completeRide(String rideId, double actualFare, {String bookingType = 'CAB'}) async {
    await _repo.completeBooking(rideId, actualFare, bookingType: bookingType);
  }

  // --- Statistics ---
  Future<Map<String, dynamic>> getDriverStats() async {
    final res = await _repo.getEarnings();
    return res.data ?? {};
  }

  // --- Fetch Bookings ---
  Future<List<BookingModel>> getDriverBookings() async {
    final List<BookingModel> results = [];
    final seen = <String>{};

    void addAll(Iterable<BookingModel> list) {
      for (final b in list) {
        if (b.id.isEmpty || seen.contains(b.id)) continue;
        seen.add(b.id);
        results.add(b);
      }
    }

    // Open dispatch queue (cab + approved logistics/shuttle)
    try {
      final pending = await _repo.getAvailableBookings();
      if (pending.success && pending.data != null) {
        addAll(pending.data!);
      }
    } catch (e) {
      debugPrint('Error fetching pending bookings: $e');
    }

    // Assigned / active history for this driver
    try {
      final res = await _api.getWithFallback(
        _ridesPath('/driver-bookings'),
        _legacyRidePath('/driver-bookings'),
      );
      if (res != null) {
        final List bookings = res['bookings'] ?? res['data'] ?? [];
        addAll(bookings.map((e) => BookingModel.fromJson(Map<String, dynamic>.from(e as Map))));
      }
    } catch (e) {
      debugPrint('Error fetching regular driver bookings: $e');
    }

    return results;
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await updateRideStatus(id, status);
    } catch (e) {
      debugPrint('Error updating ride status: $e');
      rethrow;
    }
  }

  Future<void> verifyOtp(String rideId, String otp) async {
    try {
      await _api.putWithFallback(
        _ridesPath('/$rideId/verify-otp'),
        _legacyRidePath('/rides/$rideId/verify-otp'),
        {
        'otp': otp,
        },
      );
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      rethrow;
    }
  }

  Future<void> updateBilling(String bookingId, {
    required double vehiclePrice,
    required double helperCost,
    required double discountAmount,
    required double totalPrice,
  }) async {
    try {
      await _api.patch('/logistics-bookings/$bookingId/billing', {
        'vehiclePrice': vehiclePrice,
        'helperCost': helperCost,
        'discountAmount': discountAmount,
        'totalPrice': totalPrice,
      });
    } catch (e) {
      debugPrint('Error updating billing: $e');
      rethrow;
    }
  }
}
