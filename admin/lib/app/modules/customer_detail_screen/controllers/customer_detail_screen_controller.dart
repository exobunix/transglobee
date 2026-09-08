import 'dart:convert';
import 'dart:developer';
import 'package:admin/app/utils/http_client.dart' as http;
import 'package:admin/app/constant/api_constant.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';

import 'package:admin/app/constant/collection_name.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/constant/show_toast.dart';
import 'package:admin/app/models/booking_model.dart';
import 'package:admin/app/models/user_model.dart';
import 'package:admin/app/models/wallet_transaction_model.dart';
import 'package:admin/app/utils/fire_store_utils.dart';

// ignore_for_file: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../routes/app_pages.dart';

class CustomerDetailScreenController extends GetxController {
  RxString title = "Customer Detail".tr.obs;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  RxBool isLoading = true.obs;
  Rx<UserModel> userModel = UserModel().obs;
  RxList<BookingModel> bookingList = <BookingModel>[].obs;
  Rx<TextEditingController> topupController = TextEditingController().obs;
  RxList<WalletTransactionModel> walletTransactionList = <WalletTransactionModel>[].obs;
  RxList<WalletTransactionModel> currentPageWalletTransaction = <WalletTransactionModel>[].obs;
  var currentPage = 1.obs;
  var startIndex = 1.obs;
  var endIndex = 1.obs;
  var totalPage = 1.obs;
  RxList<BookingModel> currentPageBooking = <BookingModel>[].obs;

  Rx<TextEditingController> dateFiledController = TextEditingController().obs;
  RxString selectedPayoutStatus = "All".obs;
  RxString selectedPayoutStatusForData = "All".obs;
  List<String> payoutStatus = [
    "All",
    "Place",
    "Complete",
    "Rejected",
    "Cancelled",
    "Accepted",
    "OnGoing",
  ];

  @override
  void onInit() {
    totalItemPerPage.value = Constant.numOfPageIemList.first;
    getData();
    super.onInit();
  }

  Future<void> getData() async {
    await getArgument();
    log("==============>${userModel.value.id}");
    totalItemPerPage.value = Constant.numOfPageIemList.first;
    await getBookings();
    dateFiledController.value.text = "${DateFormat('yyyy-MM-dd').format(selectedDate.value.start)} to ${DateFormat('yyyy-MM-dd').format(selectedDate.value.end)}";
    await getWalletTransactions();
    isLoading.value = false;
  }

  Future<void> getArgument() async {
    String userId = Get.parameters['userId']!;
    log("====> user ID :$userId");
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.get(
        Uri.parse(ApiConstant.adminUsers),
        headers: ApiConstant.headers(token: token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['users'] != null) {
          List list = data['users'];
          final found = list.firstWhereOrNull((element) => (element['_id'] == userId || element['id'] == userId));
          if (found != null) {
            userModel.value = UserModel.fromJson(found);
          }
        }
      }
    } catch (e) {
      log('Error fetching user details: $e');
    }
    isLoading.value = false;
  }

  // dynamic argumentData = Get.arguments;
  // if (argumentData != null) {
  // userModel.value = argumentData['userModel'];
  // } else {
  // Get.offAllNamed(Routes.ERROR_SCREEN);
  // }

  Future<void> getBookingDataForConverter() async {
    if (selectedPayoutStatus.value == "Rejected") {
      selectedPayoutStatusForData.value = "booking_rejected";
      await getBookings();
    } else if (selectedPayoutStatus.value == "Place") {
      selectedPayoutStatusForData.value = "booking_placed";
      await getBookings();
    } else if (selectedPayoutStatus.value == "Complete") {
      selectedPayoutStatusForData.value = "booking_completed";
      await getBookings();
    } else if (selectedPayoutStatus.value == "Cancelled") {
      selectedPayoutStatusForData.value = 'booking_cancelled';
      await getBookings();
    } else if (selectedPayoutStatus.value == "Accepted") {
      selectedPayoutStatusForData.value = 'booking_accepted';
      await getBookings();
    } else if (selectedPayoutStatus.value == "OnGoing") {
      selectedPayoutStatusForData.value = 'booking_ongoing';
      await getBookings();
    } else {
      // booking_accepted
      selectedPayoutStatusForData.value = "All";
      await getBookings();
    }
  }

  Future<void> removeBooking(BookingModel bookingModel) async {
    ShowToastDialog.toast("Booking deleted...!".tr);
  }

  Future<void> getBookings() async {
    isLoading.value = true;
    try {
      String token = await AppSharedPreference.getString('adminToken');
      final response = await http.get(
        Uri.parse("${ApiConstant.adminBookings}?type=ride"),
        headers: ApiConstant.headers(token: token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['bookings'] != null) {
          List list = data['bookings'];
          List<BookingModel> loaded = list.map((e) => BookingModel.fromJson(e)).toList();
          bookingList.value = loaded.where((b) => (b.customerId == userModel.value.id || b.customerId == userModel.value.email)).toList();
        }
      }
    } catch (e) {
      log('Error fetching bookings: $e');
    }
    setPagination(totalItemPerPage.value);
    isLoading.value = false;
  }

  Rx<DateTimeRange> selectedDate = DateTimeRange(
          start: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0, 0),
          end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 0))
      .obs;

  void setPagination(String page) {
    totalItemPerPage.value = page;
    int itemPerPage = pageValue(page);
    totalPage.value = (bookingList.length / itemPerPage).ceil();
    startIndex.value = (currentPage.value - 1) * itemPerPage;
    endIndex.value = (currentPage.value * itemPerPage) > bookingList.length ? bookingList.length : (currentPage.value * itemPerPage);
    if (endIndex.value < startIndex.value) {
      currentPage.value = 1;
      setPagination(page);
    } else {
      currentPageBooking.value = bookingList.sublist(startIndex.value, endIndex.value);
    }
    isLoading.value = false;
    update();
  }

  RxString totalItemPerPage = '0'.obs;

  int pageValue(String data) {
    if (data == 'All') {
      return bookingList.length;
    } else {
      return int.parse(data);
    }
  }

  Future<void> completeOrder(String transactionId) async {
    final amount = topupController.value.text;
    if (amount.isEmpty || double.tryParse(amount) == null || double.parse(amount) <= 0) {
      ShowToastDialog.toast("Please enter a valid amount.");
      return;
    }
    userModel.value.walletAmount = (double.parse(userModel.value.walletAmount ?? "0") + double.parse(amount)).toString();
    ShowToastDialog.toast("Amount added in your wallet.");
    Get.back();
  }

  Future<void> getWalletTransactions() async {
    walletTransactionList.value = [];
    setPaginationForTransactionHistory(totalItemPerPage.value);
  }

  void setDefaultData() {
    currentPage = 1.obs;
    startIndex = 1.obs;
    endIndex = 1.obs;
    totalPage = 1.obs;
  }

  void setPaginationForTransactionHistory(String page) {
    totalItemPerPage.value = page;
    int itemPerPage = pageValue(page);
    totalPage.value = (walletTransactionList.length / itemPerPage).ceil();
    startIndex.value = (currentPage.value - 1) * itemPerPage;
    endIndex.value = (currentPage.value * itemPerPage) > walletTransactionList.length ? walletTransactionList.length : (currentPage.value * itemPerPage);
    if (endIndex.value < startIndex.value) {
      currentPage.value = 1;
      setPagination(page);
    } else {
      currentPageWalletTransaction.value = walletTransactionList.sublist(startIndex.value, endIndex.value);
    }
    isLoading.value = false;
    update();
  }
}
