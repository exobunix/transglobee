import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/driver_service.dart';
import '../services/socket_service.dart';
import '../models/booking_model.dart';
import '../features/driver/controllers/driver_providers.dart';
import 'active_ride_tracking_provider.dart';

class BookingNotifier extends Notifier<List<BookingModel>> {
  Timer? _pollingTimer;

  final Set<String> _updatingIds = {};

  Set<String> _rejectedIds = {};

  static const String _rejectedIdsKey = 'rejected_booking_ids';

  @override
  List<BookingModel> build() {
    // Load persisted rejection IDs
    _loadRejectedIds();

    Future.microtask(() => fetchBookings());
    _startPolling();

    final socket = ref.watch(socketServiceProvider);

    // ── 1. New booking dispatched by admin ──────────────────────────────────
    socket.newRideStream.listen((data) {
      try {
        final booking = BookingModel.fromJson(data);
        addIncomingRequest(booking);
      } catch (e) {
        print('Error parsing socket new_ride: $e');
      }
    });

    // ── 2. Another driver accepted — remove from ALL drivers' pending ────────
    socket.rideAssignedStream.listen((data) {
      final rideId =
          data['rideId']?.toString() ?? data['bookingId']?.toString() ?? data['id']?.toString();
      if (rideId != null) {
        state = state.where((b) {
          if (b.id != rideId) return true;
          // Keep if this driver already accepted (it's their active order)
          const activeStatuses = {
            'accepted',
            'confirmed',
            'processing',
            'on_the_way',
            'arrived',
            'ongoing',
            'in_transit',
          };
          if (activeStatuses.contains(b.status)) return true;
          return false;
        }).toList();
      }
    });

    // ── 3. Ride status or payment status updated ──────────────────────────────────
    socket.rideStatusStream.listen((data) {
      try {
        final rideId = data['rideId']?.toString();
        final status = data['status']?.toString();
        final paymentStatus = data['paymentStatus']?.toString();
        if (rideId != null) {
          state = state.map((b) {
            if (b.id == rideId) {
              return b.copyWith(
                status: status ?? b.status,
                paymentStatus: paymentStatus ?? b.paymentStatus,
              );
            }
            return b;
          }).toList();
          print('>>> Socket updated booking $rideId: status=$status, paymentStatus=$paymentStatus');
        }
      } catch (e) {
        print('Error processing socket ride_status_update: $e');
      }
    });

    socket.paymentRequestedStream.listen((data) {
      try {
        final rideId = data['rideId']?.toString();
        if (rideId != null) {
          state = state.map((b) {
            if (b.id == rideId) {
              return b.copyWith(paymentStatus: 'paid');
            }
            return b;
          }).toList();
          print('>>> Socket payment_requested for $rideId: set paymentStatus=paid');
        }
      } catch (e) {
        print('Error processing socket payment_requested: $e');
      }
    });

    socket.rideCancelledStream.listen((data) {
      try {
        final rideId = data['rideId']?.toString() ?? data['bookingId']?.toString();
        if (rideId != null) {
          state = state.map((b) {
            if (b.id == rideId) {
              return b.copyWith(status: 'cancelled');
            }
            return b;
          }).toList();
          
          // Remove if it was pending
          state = state.where((b) {
            if (b.id == rideId && (b.status == 'pending' || b.status == 'pending_for_driver')) {
              return false;
            }
            return true;
          }).toList();
          print('>>> Socket ride_cancelled for $rideId: status=cancelled');
        }
      } catch (e) {
        print('Error processing socket ride_cancelled: $e');
      }
    });

    ref.onDispose(() => _pollingTimer?.cancel());
    return [];
  }

  Future<void> _loadRejectedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_rejectedIdsKey) ?? [];
    _rejectedIds = list.toSet();
    print('>>> Persistent rejection list loaded: ${_rejectedIds.length} items');
  }

  Future<void> _saveRejectedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_rejectedIdsKey, _rejectedIds.toList());
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      fetchBookings();
    });
  }

  // ─── Fetch from backend ───────────────────────────────────────────────────
  Future<void> fetchBookings() async {
    try {
      final service = ref.read(driverServiceProvider);
      final list = await service.getDriverBookings();

      // Merge: keep optimistic local state for IDs being updated
      final mergedRows = list.map((remote) {
        if (_updatingIds.contains(remote.id)) {
          final local = state.where((b) => b.id == remote.id).firstOrNull;
          if (local != null) return local;
        }
        return remote;
      }).toList();

      // ── Preservation Logic ────────────────────────────────────────────────
      // Keep only active and historical items that still have meaning after a refresh.
      const activeStatuses = {
        'accepted',
        'confirmed',
        'on_the_way',
        'arrived',
        'ongoing',
        'in_transit'
      };
      final localActiveOrders = state.where((b) {
        if (!activeStatuses.contains(b.status)) return false;
        if (mergedRows.any((r) => r.id == b.id)) return false;
        return true;
      }).toList();

      // Preserve completed/rejected history cards if the backend response is still catching up.
      const historyStatuses = {
        'rejected',
        'completed',
        'delivered',
        'cancelled',
      };
      final localHistoryOrders = state.where((b) {
        if (!historyStatuses.contains(b.status)) return false;
        if (mergedRows.any((r) => r.id == b.id)) return false;
        return true;
      }).toList();

      state = [...mergedRows, ...localActiveOrders, ...localHistoryOrders];

      // deduplicate
      final seenIds = <String>{};
      state = state.where((b) => seenIds.add(b.id)).toList();
      print('>>> SYNC COMPLETE: ${state.length} bookings in total memory');
    } catch (e) {
      print('❗️ Error fetching bookings: $e');
    }
  }

  // ─── Accept ───────────────────────────────────────────────────────────────
  Future<void> acceptBooking(String id) async {
    final b = state.where((item) => item.id == id).firstOrNull;
    if (b == null) return;

    final isLogistics = _isLogisticsBooking(b);
    _updatingIds.add(id);

    state = state
        .map((item) => item.id == id ? item.copyWith(status: 'accepted') : item)
        .toList();

    ref.read(activeRideTrackingProvider.notifier).state = ActiveRideTracking(
      rideId: id,
      userId: b.userId ?? '',
    );

    try {
      final service = ref.read(driverServiceProvider);
      if (isLogistics) {
        await service.acceptBooking(id);
      } else {
        final profileState = ref.read(driverProfileControllerProvider);
        final driverId = profileState.data?.id ?? '';
        final isShuttle = b.subType.toLowerCase() == 'shuttle' ||
            b.vehicleType.toLowerCase() == 'bus' ||
            b.vehicleType.toLowerCase().contains('shuttle');
        await service.acceptRide(
          id,
          driverId: driverId,
          bookingType: isShuttle ? 'SHUTTLE' : 'CAB',
        );
      }
    } catch (e) {
      print('❗️ Error accepting booking: $e');
      state = state
          .map((item) => item.id == id ? item.copyWith(status: b.status) : item)
          .toList();
    } finally {
      Future.delayed(const Duration(seconds: 3), () => _updatingIds.remove(id));
    }
  }

  // ─── Reject ───────────────────────────────────────────────────────────────
  Future<void> rejectBooking(String id) async {
    final b = state.where((item) => item.id == id).firstOrNull;
    if (b == null) return;

    final isLogistics = _isLogisticsBooking(b);
    _rejectedIds.add(id);
    _saveRejectedIds();

    state = state
        .map((item) => item.id == id ? item.copyWith(status: 'rejected') : item)
        .toList();

    try {
      final service = ref.read(driverServiceProvider);
      if (isLogistics) {
        await service.rejectBooking(id);
      } else {
        final profileState = ref.read(driverProfileControllerProvider);
        final driverId = profileState.data?.id ?? '';
        final isShuttle = b.subType.toLowerCase() == 'shuttle' ||
            b.vehicleType.toLowerCase() == 'bus' ||
            b.vehicleType.toLowerCase().contains('shuttle');
        await service.rejectRide(
          id,
          driverId: driverId,
          bookingType: isShuttle ? 'SHUTTLE' : 'CAB',
        );
      }
    } catch (e) {
      print('❗️ Error rejecting booking: $e');
    }
  }

  // ─── Fare Update ──────────────────────────────────────────────────────────
  void updateBookingFare(String id, double newFare) {
    state =
        state.map((b) => b.id == id ? b.copyWith(fare: newFare) : b).toList();
    print('>>> Updated fare for booking $id to ₹$newFare');
  }

  // ─── Status updates ───────────────────────────────────────────────────────
  Future<void> updateStatus(String id, String newStatus,
      {double? actualFare}) async {
    _updatingIds.add(id);

    final booking = state.cast<BookingModel?>().firstWhere(
      (b) => b?.id == id,
      orElse: () => null,
    );
    final bookingType = booking?.dispatchType ?? 'CAB';

    state = state
        .map((b) => b.id == id ? b.copyWith(status: newStatus) : b)
        .toList();

    try {
      final service = ref.read(driverServiceProvider);
      if (newStatus == 'completed' && actualFare != null) {
        await service.completeRide(id, actualFare, bookingType: bookingType);
      } else {
        await service.updateRideStatus(id, newStatus, bookingType: bookingType);
      }
    } catch (e) {
      print('❗️ Error syncing status: $e');
    } finally {
      Future.delayed(const Duration(seconds: 3), () => _updatingIds.remove(id));
    }
  }

  void startTrip(String id) => updateStatus(id, 'ongoing');
  void completeTrip(String id, double fare) =>
      updateStatus(id, 'completed', actualFare: fare);
  void markOnTheWay(String id) => updateStatus(id, 'on_the_way');
  void markArrived(String id) => updateStatus(id, 'arrived');

  void addBooking(BookingModel booking) {
    if (state.any((b) => b.id == booking.id)) return;
    if (_rejectedIds.contains(booking.id)) return;
    if (booking.status == 'pending' || booking.status == 'pending_for_driver') {
      return;
    }
    state = [booking, ...state];
  }

  /// Incoming dispatch (cab or approved logistics/shuttle) for the requests list.
  void addIncomingRequest(BookingModel booking) {
    if (_rejectedIds.contains(booking.id)) return;
    const incoming = {'pending', 'pending_for_driver'};
    if (!incoming.contains(booking.status.toLowerCase())) return;
    state = [booking, ...state.where((b) => b.id != booking.id)];
  }

  /// Remove a booking when another driver has accepted or when dismissed
  void removeBooking(String id) {
    state = state.where((b) => b.id != id).toList();
  }

  Future<void> verifyOtp(String id, String otp, {bool isDelivery = false}) async {
    try {
      final service = ref.read(driverServiceProvider);
      await service.verifyOtp(id, otp);
      state = state
          .map((b) => b.id == id ? b.copyWith(status: isDelivery ? 'completed' : 'ongoing') : b)
          .toList();
    } catch (e) {
      print('❗️ Error verifying OTP: $e');
      rethrow;
    }
  }

  bool _isLogisticsBooking(BookingModel b) {
    if (b.vehicleType == 'truck') return true;
    final sub = b.subType.toLowerCase();
    return [
      'train',
      'flight',
      'ship',
      'sea',
      'cargo',
      'logistics',
      'flatbed',
      'pickup',
      'container',
      'sea cargo'
    ].any(sub.contains);
  }
}

// ---------------------------------------------------------------------------
// Provider declarations
// ---------------------------------------------------------------------------
final bookingProvider =
    NotifierProvider<BookingNotifier, List<BookingModel>>(BookingNotifier.new);

/// Open jobs waiting for a driver (cab + approved logistics/shuttle).
final incomingRideRequestsProvider = Provider<List<BookingModel>>((ref) {
  return ref.watch(bookingProvider).where((b) {
    return b.status == 'pending' || b.status == 'pending_for_driver';
  }).toList();
});

@Deprecated('Use incomingRideRequestsProvider')
final pendingBookingsProvider = incomingRideRequestsProvider;

final activeBookingsProvider = Provider<List<BookingModel>>((ref) {
  return ref
      .watch(bookingProvider)
      .where((b) => [
            'accepted',
            'on_the_way',
            'arrived',
            'ongoing',
            'confirmed',
            'in_transit'
          ].contains(b.status))
      .toList();
});

final historyBookingsProvider = Provider<List<BookingModel>>((ref) {
  return ref
      .watch(bookingProvider)
      .where((b) => [
            'completed',
            'cancelled',
            'rejected',
            'delivered',
          ].contains(b.status))
      .toList();
});

final currentActiveBookingProvider = Provider<BookingModel?>((ref) {
  final active = ref.watch(activeBookingsProvider);
  return active.isNotEmpty ? active.first : null;
});
