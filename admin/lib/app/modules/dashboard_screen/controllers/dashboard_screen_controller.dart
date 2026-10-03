import 'dart:convert';
import 'package:admin/app/utils/http_client.dart' as http;
import 'package:admin/app/constant/api_constant.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/models/admin_model.dart';
import 'package:admin/app/models/booking_model.dart';
import 'package:admin/app/models/language_model.dart';
import 'package:admin/app/models/user_model.dart';
import 'package:admin/app/models/vehicle_type_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

class DashboardScreenController extends GetxController {
  GlobalKey<ScaffoldState> scaffoldKeyDrawer = GlobalKey<ScaffoldState>();
  RxBool isDrawerOpen = false.obs;

  void toggleDrawer() {
    GlobalKey<ScaffoldState> scaffoldKey = scaffoldKeyDrawer;
    scaffoldKey.currentState?.openDrawer();
  }

  RxBool isLoading = true.obs;
  RxBool isUserData = true.obs;

  RxInt totalBookingPlaced = 0.obs;
  RxInt totalBookingActive = 0.obs;
  RxInt totalBookingCompleted = 0.obs;

  RxInt totalBookingCanceled = 0.obs;

  RxInt totalBookings = 0.obs;
  RxInt totalCab = 0.obs;
  RxDouble totalEarnings = 0.0.obs;

  RxDouble todayTotalEarnings = 0.0.obs;
  RxDouble monthlyEarning = 0.0.obs;

  RxList<LanguageModel> languageList = <LanguageModel>[].obs;
  Rx<LanguageModel> selectedLanguage = LanguageModel().obs;
  Rx<TextEditingController> searchController = TextEditingController().obs;
  Rx<AdminModel> admin = AdminModel().obs;

  RxList<VehicleTypeModel> vehicleTypeList = <VehicleTypeModel>[].obs;
  List<ChartData>? bookingChartData;
  List<ChartData>? usersChartData;
  List<ChartDataCircle>? usersCircleChartData;
  var monthlyUserCount = List<int>.filled(12, 0).obs;

  RxBool isLoadingBookingChart = true.obs;
  RxBool isLoadingUserChart = true.obs;
  RxList<UserModel> userList = <UserModel>[].obs;
  RxList<BookingModel> bookingList = <BookingModel>[].obs;
  RxList<BookingModel> recentBookingList = <BookingModel>[].obs;
  List<ChartDataCircle> chartDataCircle = [];
  List<SalesStatistic> salesStatistic = [];
  RxInt todayService = 0.obs;
  RxInt totalService = 0.obs;
  RxInt totalUser = 0.obs;

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  Future<void> getData() async {
    isUserData.value = true;
    
    if (Constant.adminModel != null) {
      admin.value = Constant.adminModel!;
    }

    await Constant.getCurrencyData();

    try {
      String token = await AppSharedPreference.getString('adminToken');
      
      // 1. Fetch Dashboard Stats from MongoDB Backend API
      final statsResponse = await http.get(
        Uri.parse(ApiConstant.adminDashboard),
        headers: ApiConstant.headers(token: token),
      );

      if (statsResponse.statusCode == 200) {
        final statsData = jsonDecode(statsResponse.body);
        if (statsData['success'] == true) {
          final data = statsData['data'] ?? {};
          
          totalUser.value = statsData['totalUsers'] ?? data['users']?['total'] ?? 0;
          totalCab.value = statsData['activeDrivers'] ?? data['drivers']?['total'] ?? 0;
          todayTotalEarnings.value = (statsData['todayRevenue'] ?? data['revenue']?['today'] ?? 0.0).toDouble();
          totalEarnings.value = (data['revenue']?['allTime'] ?? 0.0).toDouble();
          
          totalBookings.value = data['bookings']?['total'] ?? 0;
          totalService.value = data['bookings']?['completed'] ?? 0;
          totalBookingPlaced.value = data['bookings']?['pending'] ?? 0;
          totalBookingActive.value = data['bookings']?['active'] ?? 0;
          totalBookingCompleted.value = data['bookings']?['completed'] ?? 0;
          totalBookingCanceled.value = data['bookings']?['cancelled'] ?? 0;

          // Parse recent bookings
          final recent = statsData['recentBookings'] ?? data['recentBookings'];
          if (recent is List) {
            recentBookingList.value = recent.map((e) => BookingModel.fromJson(Map<String, dynamic>.from(e))).toList();
          }

          // Parse monthly series
          final List? monthlyEarn = statsData['monthlyEarnings'] ?? data['trends']?['monthlyEarnings'];
          final List? monthlyBk = statsData['monthlyBookings'] ?? data['trends']?['monthlyBookings'];

          final months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
          bookingChartData = List.generate(12, (i) {
            final val = (monthlyEarn != null && i < monthlyEarn.length) ? (monthlyEarn[i] is num ? monthlyEarn[i].toDouble() : 0.0) : 0.0;
            return ChartData(months[i], val);
          });

          usersChartData = List.generate(12, (i) {
            final val = (monthlyBk != null && i < monthlyBk.length) ? (monthlyBk[i] is num ? monthlyBk[i].toDouble() : 0.0) : 0.0;
            return ChartData(months[i], val);
          });
        }
      }
    } catch (e) {
      log('Error fetching dashboard statistics from REST API: $e');
    }

    // Initialize chart data structures fallback if not populated
    bookingChartData ??= List.filled(12, ChartData("", 0));
    usersChartData ??= List.filled(12, ChartData("", 0));
    usersCircleChartData = List.filled(12, ChartDataCircle("", 0, Colors.amber));

    // Populate chart structures and custom chart lists locally
    salesStatistic = [
      SalesStatistic("Total Earning", totalEarnings.value, Colors.green),
    ];

    chartDataCircle = [
      ChartDataCircle('Completed', totalBookingCompleted.value, Colors.deepOrange),
      ChartDataCircle('Active', totalBookingActive.value, Colors.brown),
      ChartDataCircle('Pending', totalBookingPlaced.value, Colors.yellow),
      ChartDataCircle('Canceled', totalBookingCanceled.value, Colors.red),
      ChartDataCircle('Total Bookings', totalBookings.value, Colors.purple),
      ChartDataCircle('Total Users', totalUser.value, Colors.green),
      ChartDataCircle('Active Drivers', totalCab.value, Colors.blue),
    ];

    isLoadingBookingChart.value = false;
    isLoadingUserChart.value = false;
    await getLanguage();
    isUserData.value = false;
  }

  Future<void> getTodayStatisticData() async {}
  Future<void> getAllStatisticData() async {}
  Future<void> getBookingData() async {}
  Future<void> getBookingMonthWiseData(String monthValue, int index, String monthName) async {}

  Future<void> getLanguage() async {
    LanguageModel eng = LanguageModel(id: "en", name: "English", code: "en", active: true);
    languageList.value = [eng];
    selectedLanguage.value = eng;
  }
}

class ChartData {
  ChartData(this.x, this.y);

  final String x;
  final double y;
}

class ChartDataCircle {
  ChartDataCircle(this.x, this.y, [this.color]);

  final String x;
  final int y;
  final Color? color;
}

class SalesStatistic {
  SalesStatistic(this.x, this.y, [this.color]);

  final String x;
  final double y;
  final Color? color;
}
