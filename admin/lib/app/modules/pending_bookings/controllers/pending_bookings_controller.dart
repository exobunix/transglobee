// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:developer';

import 'package:admin/app/constant/api_constant.dart';
import 'package:admin/app/constant/show_toast.dart';
import 'package:admin/app/models/booking_model.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';
import 'package:admin/app/utils/http_client.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PendingBookingsController extends GetxController
    with GetTickerProviderStateMixin {
  // ─── Tab Controller ──────────────────────────────────────────────────────
  late TabController tabController;

  // ─── State ───────────────────────────────────────────────────────────────
  RxBool isLoadingShuttle = true.obs;
  RxBool isLoadingLogistics = true.obs;
  RxBool isActionLoading = false.obs;

  RxList<BookingModel> shuttleBookings = <BookingModel>[].obs;
  RxList<BookingModel> logisticsBookings = <BookingModel>[].obs;

  // For driver assignment dialog
  RxList<Map<String, dynamic>> availableDrivers =
      <Map<String, dynamic>>[].obs;
  RxBool isLoadingDrivers = false.obs;

  // Form controllers for price override
  final priceController = TextEditingController();
  final rejectReasonController = TextEditingController();

  @override
  void onInit() {
    tabController = TabController(length: 2, vsync: this);
    fetchShuttleBookings();
    fetchLogisticsBookings();
    super.onInit();
  }

  @override
  void onClose() {
    tabController.dispose();
    priceController.dispose();
    rejectReasonController.dispose();
    super.onClose();
  }

  // ─── Fetch Bookings ───────────────────────────────────────────────────────

  Future<void> fetchShuttleBookings() async {
    isLoadingShuttle.value = true;
    try {
      final token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse(
          '${ApiConstant.adminBookings}?type=shuttle&status=pending');
      final response =
          await http.get(uri, headers: ApiConstant.headers(token: token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['bookings'] != null) {
          final List list = data['bookings'];
          shuttleBookings.value =
              list.map((e) => BookingModel.fromJson(e)).toList();
        } else {
          shuttleBookings.value = [];
        }
      } else {
        shuttleBookings.value = [];
      }
    } catch (e) {
      log('Error fetching shuttle bookings: $e');
      shuttleBookings.value = [];
    } finally {
      isLoadingShuttle.value = false;
    }
  }

  Future<void> fetchLogisticsBookings() async {
    isLoadingLogistics.value = true;
    try {
      final token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse(
          '${ApiConstant.adminBookings}?type=logistics&status=pending');
      final response =
          await http.get(uri, headers: ApiConstant.headers(token: token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['bookings'] != null) {
          final List list = data['bookings'];
          logisticsBookings.value =
              list.map((e) => BookingModel.fromJson(e)).toList();
        } else {
          logisticsBookings.value = [];
        }
      } else {
        logisticsBookings.value = [];
      }
    } catch (e) {
      log('Error fetching logistics bookings: $e');
      logisticsBookings.value = [];
    } finally {
      isLoadingLogistics.value = false;
    }
  }

  Future<void> refreshCurrent() async {
    if (tabController.index == 0) {
      await fetchShuttleBookings();
    } else {
      await fetchLogisticsBookings();
    }
  }

  // ─── Accept Booking ───────────────────────────────────────────────────────

  Future<void> acceptBooking(BookingModel booking) async {
    isActionLoading.value = true;
    try {
      final token = await AppSharedPreference.getString('adminToken');
      final uri =
          Uri.parse('${ApiConstant.adminBookings}/${booking.id}/status');
      final response = await http.put(
        uri,
        headers: ApiConstant.headers(token: token),
        body: jsonEncode({'status': 'accepted', 'bookingStatus': 'booking_accepted'}),
      );

      if (response.statusCode == 200) {
        ShowToastDialog.toast('Booking accepted successfully');
        _removeFromList(booking);
      } else {
        final data = jsonDecode(response.body);
        ShowToastDialog.toast(data['message'] ?? 'Failed to accept booking');
      }
    } catch (e) {
      log('Error accepting booking: $e');
      ShowToastDialog.toast('Error accepting booking');
    } finally {
      isActionLoading.value = false;
    }
  }

  // ─── Reject Booking ───────────────────────────────────────────────────────

  Future<void> rejectBooking(BookingModel booking, String reason) async {
    isActionLoading.value = true;
    try {
      final token = await AppSharedPreference.getString('adminToken');
      final uri =
          Uri.parse('${ApiConstant.adminBookings}/${booking.id}/status');
      final response = await http.put(
        uri,
        headers: ApiConstant.headers(token: token),
        body: jsonEncode({
          'status': 'rejected',
          'bookingStatus': 'booking_rejected',
          'cancelledReason': reason,
          'cancelledBy': 'admin',
        }),
      );

      if (response.statusCode == 200) {
        ShowToastDialog.toast('Booking rejected');
        _removeFromList(booking);
      } else {
        final data = jsonDecode(response.body);
        ShowToastDialog.toast(data['message'] ?? 'Failed to reject booking');
      }
    } catch (e) {
      log('Error rejecting booking: $e');
      ShowToastDialog.toast('Error rejecting booking');
    } finally {
      isActionLoading.value = false;
    }
  }

  // ─── Assign Driver ────────────────────────────────────────────────────────

  Future<void> fetchAvailableDrivers() async {
    isLoadingDrivers.value = true;
    availableDrivers.clear();
    try {
      final token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse('${ApiConstant.adminDrivers}?status=available');
      final response =
          await http.get(uri, headers: ApiConstant.headers(token: token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['drivers'] ?? data['data'] ?? [];
        availableDrivers.value =
            list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      log('Error fetching drivers: $e');
    } finally {
      isLoadingDrivers.value = false;
    }
  }

  Future<void> assignDriver(
      BookingModel booking, String driverId, String driverName) async {
    isActionLoading.value = true;
    try {
      final token = await AppSharedPreference.getString('adminToken');
      final uri =
          Uri.parse('${ApiConstant.adminBookings}/${booking.id}/assign');
      final response = await http.put(
        uri,
        headers: ApiConstant.headers(token: token),
        body: jsonEncode({'driverId': driverId}),
      );

      if (response.statusCode == 200) {
        ShowToastDialog.toast('Driver "$driverName" assigned successfully');
        await refreshCurrent();
      } else {
        final data = jsonDecode(response.body);
        ShowToastDialog.toast(data['message'] ?? 'Failed to assign driver');
      }
    } catch (e) {
      log('Error assigning driver: $e');
      ShowToastDialog.toast('Error assigning driver');
    } finally {
      isActionLoading.value = false;
    }
  }

  // ─── Price Override ───────────────────────────────────────────────────────

  Future<void> overridePrice(BookingModel booking, String newPrice) async {
    isActionLoading.value = true;
    try {
      final token = await AppSharedPreference.getString('adminToken');
      final uri =
          Uri.parse('${ApiConstant.adminBookings}/${booking.id}/price');
      final response = await http.put(
        uri,
        headers: ApiConstant.headers(token: token),
        body: jsonEncode({'subTotal': newPrice, 'totalPrice': newPrice}),
      );

      if (response.statusCode == 200) {
        ShowToastDialog.toast('Price updated to ₹$newPrice');
        await refreshCurrent();
      } else {
        final data = jsonDecode(response.body);
        ShowToastDialog.toast(data['message'] ?? 'Failed to update price');
      }
    } catch (e) {
      log('Error updating price: $e');
      ShowToastDialog.toast('Error updating price');
    } finally {
      isActionLoading.value = false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _removeFromList(BookingModel booking) {
    shuttleBookings.removeWhere((b) => b.id == booking.id);
    logisticsBookings.removeWhere((b) => b.id == booking.id);
  }

  String statusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'booking_placed':
      case 'placed':
      case 'pending':
        return 'PENDING';
      case 'booking_accepted':
      case 'accepted':
        return 'ACCEPTED';
      case 'booking_rejected':
      case 'rejected':
        return 'REJECTED';
      case 'booking_completed':
      case 'completed':
        return 'COMPLETED';
      case 'booking_cancelled':
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status?.toUpperCase() ?? 'UNKNOWN';
    }
  }
}
