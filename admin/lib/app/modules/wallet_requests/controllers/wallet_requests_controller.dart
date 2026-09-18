import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/app/constant/api_constant.dart';
import 'package:admin/app/constant/show_toast.dart';
import 'package:admin/app/models/wallet_request_model.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';
import 'package:admin/app/utils/http_client.dart' as http;

class WalletRequestsController extends GetxController {
  RxString title = "Wallet Requests".tr.obs;
  RxBool isLoading = true.obs;
  RxBool isActionLoading = false.obs;

  RxList<WalletRequestModel> requestList = <WalletRequestModel>[].obs;
  Rx<WalletRequestStats> stats = WalletRequestStats().obs;

  RxString selectedStatus = "All".obs;
  final List<String> statusFilters = ["All", "Pending", "Approved", "Rejected"];

  RxString selectedUserType = "All".obs;
  final List<String> userTypeFilters = ["All", "User", "Driver"];

  final TextEditingController searchController = TextEditingController();
  final TextEditingController adminNoteController = TextEditingController();

  var currentPage = 1.obs;
  var totalPage = 1.obs;
  var totalItems = 0.obs;
  final int limit = 20;

  @override
  void onInit() {
    super.onInit();
    fetchRequests();
  }

  @override
  void onClose() {
    searchController.dispose();
    adminNoteController.dispose();
    super.onClose();
  }

  Future<void> fetchRequests({int page = 1}) async {
    isLoading.value = true;
    currentPage.value = page;

    try {
      String token = await AppSharedPreference.getString('adminToken');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (selectedStatus.value != "All") {
        queryParams['status'] = selectedStatus.value.toLowerCase();
      }
      if (selectedUserType.value != "All") {
        queryParams['userType'] = selectedUserType.value.toLowerCase();
      }
      final search = searchController.text.trim();
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(ApiConstant.adminWalletRequests).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: ApiConstant.headers(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List rawRequests = data['requests'] ?? [];
          requestList.value = rawRequests.map((e) => WalletRequestModel.fromJson(e)).toList();

          if (data['stats'] != null) {
            stats.value = WalletRequestStats.fromJson(data['stats']);
          }

          if (data['pagination'] != null) {
            totalItems.value = data['pagination']['total'] ?? requestList.length;
            totalPage.value = data['pagination']['totalPages'] ?? 1;
          }
        }
      } else {
        log('Failed to fetch wallet requests: ${response.statusCode}');
        ShowToastDialog.toast("Failed to load wallet requests");
      }
    } catch (e, stack) {
      log('Error fetching wallet requests: $e\n$stack');
      ShowToastDialog.toast("Something went wrong loading requests");
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> approveRequest(String requestId, {String? note}) async {
    isActionLoading.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse("${ApiConstant.adminWalletRequests}/$requestId/approve");

      final response = await http.put(
        uri,
        headers: ApiConstant.headers(token: token),
        body: jsonEncode({
          'adminNote': note ?? 'Approved by Admin',
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        ShowToastDialog.toast("Wallet top-up approved successfully! Amount credited.");
        await fetchRequests(page: currentPage.value);
      } else {
        ShowToastDialog.toast(data['message'] ?? "Failed to approve request");
      }
    } catch (e) {
      log('Error approving wallet request: $e');
      ShowToastDialog.toast("Error approving request");
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> rejectRequest(String requestId, {String? reason}) async {
    isActionLoading.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final uri = Uri.parse("${ApiConstant.adminWalletRequests}/$requestId/reject");

      final response = await http.put(
        uri,
        headers: ApiConstant.headers(token: token),
        body: jsonEncode({
          'reason': reason ?? 'Rejected by Admin',
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        ShowToastDialog.toast("Wallet top-up request rejected.");
        await fetchRequests(page: currentPage.value);
      } else {
        ShowToastDialog.toast(data['message'] ?? "Failed to reject request");
      }
    } catch (e) {
      log('Error rejecting wallet request: $e');
      ShowToastDialog.toast("Error rejecting request");
    } finally {
      isActionLoading.value = false;
    }
  }

  void onStatusChanged(String newStatus) {
    if (selectedStatus.value != newStatus) {
      selectedStatus.value = newStatus;
      fetchRequests(page: 1);
    }
  }

  void onUserTypeChanged(String newType) {
    if (selectedUserType.value != newType) {
      selectedUserType.value = newType;
      fetchRequests(page: 1);
    }
  }

  void onSearchSubmit(String query) {
    fetchRequests(page: 1);
  }

  void clearSearch() {
    searchController.clear();
    fetchRequests(page: 1);
  }
}
