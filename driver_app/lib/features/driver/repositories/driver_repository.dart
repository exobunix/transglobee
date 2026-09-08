import '../../../core/network/api_response.dart';
import '../../../services/rest_api_repository.dart';
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
import '../models/request/update_location_request.dart';
import '../models/response/update_location_response.dart';
import '../models/request/logout_request_model.dart';
import '../models/response/logout_response_model.dart';

class DriverRepository {
  final RestApiRepository _repo;
  DriverRepository(this._repo);

  Future<ApiResponse<DriverProfileResponseModel>> getDriverProfile() async {
    final response = await _repo.getProfile();
    return ApiResponse<DriverProfileResponseModel>(
      success: response.success,
      message: response.message ?? '',
      data: response.data != null ? DriverProfileResponseModel.fromModel(response.data!) : null,
    );
  }

  Future<ApiResponse<UpdateDriverStatusResponse>> updateDriverStatus(
      UpdateDriverStatusRequest request) async {
    final response = await _repo.updateStatus(isOnline: request.isOnline, status: 'active');
    return ApiResponse<UpdateDriverStatusResponse>(
      success: response.success,
      message: response.message ?? '',
      data: response.success
          ? UpdateDriverStatusResponse(
              isOnline: request.isOnline,
              updatedAt: DateTime.now().toIso8601String(),
            )
          : null,
    );
  }

  Future<ApiResponse<DriverWalletResponseModel>> getDriverWallet() async {
    final response = await _repo.getEarnings();
    return ApiResponse<DriverWalletResponseModel>(
      success: response.success,
      message: response.message ?? '',
      data: response.data != null ? DriverWalletResponseModel.fromJson(response.data!) : null,
    );
  }

  Future<ApiResponse<EarningsPaginationModel>> getDriverEarnings(
      {int page = 1, int limit = 20}) async {
    final response = await _repo.getEarnings();
    return ApiResponse<EarningsPaginationModel>(
      success: response.success,
      message: response.message ?? '',
      data: response.data != null ? EarningsPaginationModel.fromJson(response.data!) : null,
    );
  }

  Future<ApiResponse<BookingHistoryModel>> getBookingHistory(
      {int page = 1, int limit = 20, String status = 'completed'}) async {
    final response = await _repo.getBookingHistory();
    return ApiResponse<BookingHistoryModel>(
      success: response.success,
      message: response.message ?? '',
      data: response.success
          ? BookingHistoryModel(
              page: page,
              limit: limit,
              total: response.data?.length ?? 0,
              bookings: const [], 
            )
          : null,
    );
  }

  Future<ApiResponse<AcceptBookingResponse>> acceptBooking(
      AcceptBookingRequest request) async {
    final response = await _repo.acceptBooking(request.bookingId);
    return ApiResponse<AcceptBookingResponse>(
      success: response.success,
      message: response.message ?? '',
      data: response.success
          ? AcceptBookingResponse(
              bookingId: request.bookingId,
              status: 'accepted',
            )
          : null,
    );
  }

  Future<ApiResponse<RejectBookingResponse>> rejectBooking(
      RejectBookingRequest request) async {
    return ApiResponse<RejectBookingResponse>(
      success: true,
      message: 'Rejected successfully',
      data: RejectBookingResponse(bookingId: request.bookingId, status: 'rejected'),
    );
  }

  Future<ApiResponse<StartTripResponse>> startTrip(
      StartTripRequest request) async {
    return ApiResponse<StartTripResponse>(
      success: true,
      message: 'Trip started',
      data: StartTripResponse(
        bookingId: request.bookingId,
        status: 'started',
        startedAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<ApiResponse<CompleteTripResponse>> completeTrip(
      CompleteTripRequest request, {String bookingType = 'CAB'}) async {
    final response = await _repo.completeBooking(request.bookingId, request.distance, bookingType: bookingType);
    return ApiResponse<CompleteTripResponse>(
      success: response.success,
      message: response.message ?? '',
      data: response.success
          ? CompleteTripResponse(
              bookingId: request.bookingId,
              status: 'completed',
              fare: 0.0,
              distance: request.distance,
              duration: request.duration,
              completedAt: DateTime.now().toIso8601String(),
            )
          : null,
    );
  }

  Future<ApiResponse<UpdateLocationResponse>> updateLiveLocation(
      UpdateLocationRequest request) async {
    final response = await _repo.updateLocation(request.lat, request.lng);
    return ApiResponse<UpdateLocationResponse>(
      success: response.success,
      message: response.message ?? '',
      data: response.success
          ? UpdateLocationResponse(
              lat: request.lat,
              lng: request.lng,
              updatedAt: DateTime.now().toIso8601String(),
            )
          : null,
    );
  }

  Future<ApiResponse<CurrentBookingResponseModel>> getCurrentBooking() async {
    return ApiResponse<CurrentBookingResponseModel>(
      success: false,
      message: 'No current booking',
    );
  }

  Future<ApiResponse<PayoutResponseModel>> submitPayoutRequest(
      PayoutRequestModel request) async {
    return ApiResponse<PayoutResponseModel>(
      success: false,
      message: 'Payout request failed',
    );
  }

  Future<ApiResponse<NotificationResponseModel>> getNotifications() async {
    return ApiResponse<NotificationResponseModel>(
      success: true,
      message: 'Success',
      data: const NotificationResponseModel(
        unreadCount: 0,
        notifications: [],
      ),
    );
  }

  Future<ApiResponse<LogoutResponseModel>> logout(
      LogoutRequestModel request) async {
    await _repo.updateStatus(isOnline: false, status: 'offline');
    return ApiResponse<LogoutResponseModel>(
      success: true,
      message: 'Logged out successfully',
      data: const LogoutResponseModel(
        success: true,
        message: 'Logged out successfully',
      ),
    );
  }
}
