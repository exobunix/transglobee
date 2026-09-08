import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/network/api_state.dart';
import '../repositories/driver_repository.dart';
import '../models/response/driver_profile_response.dart';
import '../models/request/update_driver_status_request.dart';
import '../models/response/update_driver_status_response.dart';
import '../models/response/driver_wallet_response.dart';
import '../models/response/earnings_pagination_model.dart';
import '../models/request/payout_request_model.dart';
import '../models/response/payout_response_model.dart';
import '../models/response/booking_history_model.dart';
import '../models/response/current_booking_response.dart';
import '../models/request/accept_booking_request.dart';
import '../models/response/accept_booking_response.dart';
import '../models/request/reject_booking_request.dart';
import '../models/response/reject_booking_response.dart';
import '../models/request/start_trip_request.dart';
import '../models/response/start_trip_response.dart';
import '../models/request/complete_trip_request.dart';
import '../models/response/complete_trip_response.dart';
import '../models/response/notification_response_model.dart';
import '../models/request/logout_request_model.dart';
import '../models/response/logout_response_model.dart';

import '../../../services/rest_api_repository.dart';

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  final repo = ref.watch(restApiRepositoryProvider);
  return DriverRepository(repo);
});

// Profile Controller
final driverProfileControllerProvider = StateNotifierProvider<
    DriverProfileController, ApiState<DriverProfileResponseModel>>((ref) {
  return DriverProfileController(ref.watch(driverRepositoryProvider));
});

class DriverProfileController
    extends StateNotifier<ApiState<DriverProfileResponseModel>> {
  final DriverRepository _repository;
  DriverProfileController(this._repository) : super(const ApiState());

  Future<void> getDriverProfile() async {
    state = state.copyWith(status: ApiStatus.loading);
    try {
      final response = await _repository.getDriverProfile();
      if (response.success && response.data != null) {
        state = state.copyWith(status: ApiStatus.success, data: response.data);
      } else {
        state =
            state.copyWith(status: ApiStatus.error, message: response.message);
      }
    } catch (e) {
      state = state.copyWith(status: ApiStatus.error, message: e.toString());
    }
  }
}

// Status Controller
final updateDriverStatusControllerProvider = StateNotifierProvider<
    UpdateDriverStatusController, ApiState<UpdateDriverStatusResponse>>((ref) {
  return UpdateDriverStatusController(ref.watch(driverRepositoryProvider));
});

class UpdateDriverStatusController
    extends StateNotifier<ApiState<UpdateDriverStatusResponse>> {
  final DriverRepository _repository;
  UpdateDriverStatusController(this._repository) : super(const ApiState());

  Future<void> updateOnlineStatus(bool isOnline) async {
    state = state.copyWith(status: ApiStatus.loading);
    try {
      final response = await _repository
          .updateDriverStatus(UpdateDriverStatusRequest(isOnline: isOnline));
      if (response.success && response.data != null) {
        state = state.copyWith(
            status: ApiStatus.success,
            data: response.data,
            message: response.message);
      } else {
        state =
            state.copyWith(status: ApiStatus.error, message: response.message);
      }
    } catch (e) {
      state = state.copyWith(status: ApiStatus.error, message: e.toString());
    }
  }
}

// Earnings Controller
final earningsControllerProvider = StateNotifierProvider<EarningsController,
    ApiState<EarningsPaginationModel>>((ref) {
  return EarningsController(ref.watch(driverRepositoryProvider));
});

class EarningsController
    extends StateNotifier<ApiState<EarningsPaginationModel>> {
  final DriverRepository _repository;
  EarningsController(this._repository) : super(const ApiState());

  Future<void> getDriverEarnings({int page = 1, int limit = 20}) async {
    state = state.copyWith(status: ApiStatus.loading);
    try {
      final response =
          await _repository.getDriverEarnings(page: page, limit: limit);
      if (response.success && response.data != null) {
        state = state.copyWith(status: ApiStatus.success, data: response.data);
      } else {
        state =
            state.copyWith(status: ApiStatus.error, message: response.message);
      }
    } catch (e) {
      state = state.copyWith(status: ApiStatus.error, message: e.toString());
    }
  }
}

// Booking Controller
final bookingControllerProvider =
    StateNotifierProvider<BookingController, ApiState<BookingHistoryModel>>(
        (ref) {
  return BookingController(ref.watch(driverRepositoryProvider));
});

class BookingController extends StateNotifier<ApiState<BookingHistoryModel>> {
  final DriverRepository _repository;
  BookingController(this._repository) : super(const ApiState());

  Future<void> getBookingHistory(
      {int page = 1, int limit = 20, String status = 'completed'}) async {
    state = state.copyWith(status: ApiStatus.loading);
    try {
      final response = await _repository.getBookingHistory(
          page: page, limit: limit, status: status);
      if (response.success && response.data != null) {
        state = state.copyWith(status: ApiStatus.success, data: response.data);
      } else {
        state =
            state.copyWith(status: ApiStatus.error, message: response.message);
      }
    } catch (e) {
      state = state.copyWith(status: ApiStatus.error, message: e.toString());
    }
  }

  Future<AcceptBookingResponse?> acceptBooking(String bookingId) async {
    try {
      final response = await _repository
          .acceptBooking(AcceptBookingRequest(bookingId: bookingId));
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<RejectBookingResponse?> rejectBooking(
      String bookingId, String reason) async {
    try {
      final response = await _repository.rejectBooking(
          RejectBookingRequest(bookingId: bookingId, reason: reason));
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<StartTripResponse?> startTrip(String bookingId, String otp) async {
    try {
      final response = await _repository
          .startTrip(StartTripRequest(bookingId: bookingId, otp: otp));
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<CompleteTripResponse?> completeTrip(
      String bookingId, double distance, int duration, {String bookingType = 'CAB'}) async {
    try {
      final response = await _repository.completeTrip(
          CompleteTripRequest(
              bookingId: bookingId, distance: distance, duration: duration),
          bookingType: bookingType);
      return response.data;
    } catch (e) {
      return null;
    }
  }
}

// Current Booking Controller
final currentBookingControllerProvider = StateNotifierProvider<
    CurrentBookingController, ApiState<CurrentBookingResponseModel>>((ref) {
  return CurrentBookingController(ref.watch(driverRepositoryProvider));
});

class CurrentBookingController
    extends StateNotifier<ApiState<CurrentBookingResponseModel>> {
  final DriverRepository _repository;
  CurrentBookingController(this._repository) : super(const ApiState());

  Future<void> getCurrentBooking() async {
    state = state.copyWith(status: ApiStatus.loading);
    try {
      final response = await _repository.getCurrentBooking();
      if (response.success && response.data != null) {
        state = state.copyWith(status: ApiStatus.success, data: response.data);
      } else {
        state =
            state.copyWith(status: ApiStatus.error, message: response.message);
      }
    } catch (e) {
      state = state.copyWith(status: ApiStatus.error, message: e.toString());
    }
  }
}

// Payout Controller
final payoutControllerProvider =
    StateNotifierProvider<PayoutController, ApiState<PayoutResponseModel>>(
        (ref) {
  return PayoutController(ref.watch(driverRepositoryProvider));
});

class PayoutController extends StateNotifier<ApiState<PayoutResponseModel>> {
  final DriverRepository _repository;
  PayoutController(this._repository) : super(const ApiState());

  Future<void> requestPayout(double amount, String method) async {
    state = state.copyWith(status: ApiStatus.loading);
    try {
      final response = await _repository.submitPayoutRequest(
          PayoutRequestModel(amount: amount, method: method));
      if (response.success && response.data != null) {
        state = state.copyWith(status: ApiStatus.success, data: response.data);
      } else {
        state =
            state.copyWith(status: ApiStatus.error, message: response.message);
      }
    } catch (e) {
      state = state.copyWith(status: ApiStatus.error, message: e.toString());
    }
  }
}

// Wallet Controller
final walletControllerProvider = StateNotifierProvider<WalletController,
    ApiState<DriverWalletResponseModel>>((ref) {
  return WalletController(ref.watch(driverRepositoryProvider));
});

class WalletController
    extends StateNotifier<ApiState<DriverWalletResponseModel>> {
  final DriverRepository _repository;
  WalletController(this._repository) : super(const ApiState());

  Future<void> getDriverWallet() async {
    state = state.copyWith(status: ApiStatus.loading);
    try {
      final response = await _repository.getDriverWallet();
      if (response.success && response.data != null) {
        state = state.copyWith(status: ApiStatus.success, data: response.data);
      } else {
        state =
            state.copyWith(status: ApiStatus.error, message: response.message);
      }
    } catch (e) {
      state = state.copyWith(status: ApiStatus.error, message: e.toString());
    }
  }
}

// Notification Controller
final notificationControllerProvider = StateNotifierProvider<
    NotificationController, ApiState<NotificationResponseModel>>((ref) {
  return NotificationController(ref.watch(driverRepositoryProvider));
});

class NotificationController
    extends StateNotifier<ApiState<NotificationResponseModel>> {
  final DriverRepository _repository;
  NotificationController(this._repository) : super(const ApiState());

  Future<void> getNotifications() async {
    state = state.copyWith(status: ApiStatus.loading);
    try {
      final response = await _repository.getNotifications();
      if (response.success && response.data != null) {
        state = state.copyWith(status: ApiStatus.success, data: response.data);
      } else {
        state =
            state.copyWith(status: ApiStatus.error, message: response.message);
      }
    } catch (e) {
      state = state.copyWith(status: ApiStatus.error, message: e.toString());
    }
  }
}

// Logout Controller
final logoutControllerProvider =
    StateNotifierProvider<LogoutController, ApiState<LogoutResponseModel>>(
        (ref) {
  return LogoutController(ref.watch(driverRepositoryProvider));
});

class LogoutController extends StateNotifier<ApiState<LogoutResponseModel>> {
  final DriverRepository _repository;
  LogoutController(this._repository) : super(const ApiState());

  Future<void> logout(String deviceToken) async {
    state = state.copyWith(status: ApiStatus.loading);
    try {
      final response = await _repository
          .logout(LogoutRequestModel(deviceToken: deviceToken));
      if (response.success && response.data != null) {
        state = state.copyWith(status: ApiStatus.success, data: response.data);
      } else {
        state =
            state.copyWith(status: ApiStatus.error, message: response.message);
      }
    } catch (e) {
      state = state.copyWith(status: ApiStatus.error, message: e.toString());
    }
  }
}
