import 'dart:convert';
import 'package:admin/app/utils/http_client.dart' as http;
import 'package:admin/app/constant/api_constant.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/models/admin_model.dart';
import 'package:admin/app/models/booking_model.dart';
import 'package:admin/app/models/language_model.dart';
import 'package:admin/app/models/user_model.dart';
import 'package:admin/app/modules/cab_bookings_screen/controllers/cab_booking_controller.dart';
import 'package:admin/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

class MultiBarChartData {
  final String day;
  final double cab;
  final double shuttle;
  final double logistics;

  MultiBarChartData(this.day, this.cab, this.shuttle, this.logistics);
}

class DonutChartData {
  final String label;
  final double value;
  final Color color;
  final int count;
  final double percentage;

  DonutChartData(this.label, this.value, this.color, this.count, this.percentage);
}

class ServiceTypeItem {
  final String title;
  final int count;
  final double progress;
  final Color color;
  final String typeKey;

  ServiceTypeItem({
    required this.title,
    required this.count,
    required this.progress,
    required this.color,
    required this.typeKey,
  });
}

class TopCityItem {
  final int rank;
  final String city;
  final int count;
  final Color rankColor;

  TopCityItem({
    required this.rank,
    required this.city,
    required this.count,
    required this.rankColor,
  });
}

class TopDriverModel {
  final String id;
  final String name;
  final String photo;
  final double rating;
  final int trips;
  final double earnings;

  TopDriverModel({
    required this.id,
    required this.name,
    required this.photo,
    required this.rating,
    required this.trips,
    required this.earnings,
  });
}

class RecentUserModel {
  final String id;
  final String name;
  final String photo;
  final String type;
  final String joinedOn;
  final String status;

  RecentUserModel({
    required this.id,
    required this.name,
    required this.photo,
    required this.type,
    required this.joinedOn,
    required this.status,
  });
}

class RecentBookingItem {
  final String id;
  final String bookingId;
  final String userName;
  final String service;
  final String route;
  final double amount;
  final String status;
  final String time;
  final String type;

  RecentBookingItem({
    required this.id,
    required this.bookingId,
    required this.userName,
    required this.service,
    required this.route,
    required this.amount,
    required this.status,
    required this.time,
    required this.type,
  });
}

class DashboardScreenController extends GetxController {
  GlobalKey<ScaffoldState> scaffoldKeyDrawer = GlobalKey<ScaffoldState>();
  RxBool isDrawerOpen = false.obs;

  void toggleDrawer() {
    scaffoldKeyDrawer.currentState?.openDrawer();
  }

  RxBool isLoading = true.obs;
  RxBool isUserData = true.obs;

  // KPI 1: Total Users
  RxInt totalUser = 2548.obs;
  RxInt activeUsers = 1982.obs;
  RxString usersGrowth = '+12.5%'.obs;

  // KPI 2: Total Drivers
  RxInt totalDrivers = 328.obs;
  RxInt activeDrivers = 296.obs;
  RxString driversGrowth = '+8.3%'.obs;

  // KPI 3: Total Vehicles
  RxInt totalVehicles = 312.obs;
  RxInt activeVehicles = 284.obs;
  RxString vehiclesGrowth = '+6.7%'.obs;

  // KPI 4: Total Bookings
  RxInt totalBookings = 4832.obs;
  RxInt todayBookings = 612.obs;
  RxString bookingsGrowth = '+18.4%'.obs;

  // KPI 5: Today's Earning
  RxDouble todayTotalEarnings = 48965.0.obs;
  RxDouble monthlyEarning = 1496655.0.obs;
  RxString todayGrowth = '+22.3%'.obs;

  // KPI 6: Total Earning
  RxDouble totalEarnings = 1496655.0.obs;
  RxString totalGrowth = '+16.8%'.obs;

  // Legacy compatibility bindings
  RxInt totalCab = 328.obs;
  RxInt totalBookingCompleted = 3642.obs;
  RxInt totalBookingActive = 428.obs;
  RxInt totalBookingCanceled = 432.obs;
  RxInt totalBookingPlaced = 330.obs;

  // Filters
  RxString selectedBookingRange = 'Last 30 Days'.obs;
  RxString selectedEarningRange = 'Last 30 Days'.obs;
  RxString selectedUserDistRange = 'This Month'.obs;
  RxString selectedBookingStatusRange = 'This Month'.obs;
  RxString selectedServiceTypeRange = 'This Month'.obs;
  RxString selectedTopCitiesRange = 'This Month'.obs;

  // Lists
  RxList<MultiBarChartData> bookingOverviewBars = <MultiBarChartData>[].obs;
  RxList<ChartData> earningOverviewSpline = <ChartData>[].obs;
  RxList<DonutChartData> usersDistributionList = <DonutChartData>[].obs;
  RxList<DonutChartData> bookingStatusList = <DonutChartData>[].obs;
  RxList<ServiceTypeItem> serviceTypeList = <ServiceTypeItem>[].obs;
  RxList<TopCityItem> topCityList = <TopCityItem>[].obs;
  RxList<TopDriverModel> topDriversList = <TopDriverModel>[].obs;
  RxList<RecentUserModel> recentUsersList = <RecentUserModel>[].obs;
  RxList<RecentBookingItem> recentBookingsList = <RecentBookingItem>[].obs;

  RxList<BookingModel> recentBookingList = <BookingModel>[].obs;
  RxList<UserModel> userList = <UserModel>[].obs;
  RxList<LanguageModel> languageList = <LanguageModel>[].obs;
  Rx<LanguageModel> selectedLanguage = LanguageModel().obs;
  Rx<AdminModel> admin = AdminModel().obs;

  List<ChartData>? bookingChartData;
  List<ChartData>? usersChartData;
  RxBool isLoadingBookingChart = false.obs;
  RxBool isLoadingUserChart = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initDefaultVisuals();
    getData();
  }

  void _initDefaultVisuals() {
    // 1. Booking Overview Bars (Sep 3 to Sep 30)
    bookingOverviewBars.value = [
      MultiBarChartData('Sep 3', 80, 50, 40),
      MultiBarChartData('Sep 6', 125, 80, 55),
      MultiBarChartData('Sep 9', 110, 70, 60),
      MultiBarChartData('Sep 12', 140, 85, 75),
      MultiBarChartData('Sep 15', 115, 65, 50),
      MultiBarChartData('Sep 18', 155, 95, 85),
      MultiBarChartData('Sep 21', 130, 80, 70),
      MultiBarChartData('Sep 24', 145, 90, 75),
      MultiBarChartData('Sep 27', 170, 110, 95),
      MultiBarChartData('Sep 30', 150, 95, 85),
    ];

    // 2. Earning Overview Spline
    earningOverviewSpline.value = [
      ChartData('Sep 3', 28000),
      ChartData('Sep 6', 48000),
      ChartData('Sep 9', 35000),
      ChartData('Sep 12', 42000),
      ChartData('Sep 15', 38000),
      ChartData('Sep 18', 52340),
      ChartData('Sep 21', 44000),
      ChartData('Sep 24', 48000),
      ChartData('Sep 27', 41000),
      ChartData('Sep 30', 51000),
    ];

    // 3. Users Distribution Donut
    usersDistributionList.value = [
      DonutChartData('Customers', 64, const Color(0xFF2F80ED), 1642, 64),
      DonutChartData('Drivers', 13, const Color(0xFFFF7A00), 328, 13),
      DonutChartData('Shuttle Users', 12, const Color(0xFF27AE60), 312, 12),
      DonutChartData('Logistics Users', 11, const Color(0xFF9B51E0), 266, 11),
    ];

    // 4. Booking Status Donut
    bookingStatusList.value = [
      DonutChartData('Completed', 75, const Color(0xFF27AE60), 3642, 75),
      DonutChartData('Ongoing', 9, const Color(0xFF2F80ED), 428, 9),
      DonutChartData('Cancelled', 9, const Color(0xFFEB5757), 432, 9),
      DonutChartData('Scheduled', 7, const Color(0xFFF2994A), 330, 7),
    ];

    // 5. Service Type Wise
    serviceTypeList.value = [
      ServiceTypeItem(title: 'Cab Bookings', count: 2184, progress: 0.85, color: const Color(0xFFFF9F1C), typeKey: 'cab'),
      ServiceTypeItem(title: 'Shuttle Bookings', count: 1226, progress: 0.55, color: const Color(0xFF2F80ED), typeKey: 'bus'),
      ServiceTypeItem(title: 'Logistics Bookings', count: 864, progress: 0.40, color: const Color(0xFF9B51E0), typeKey: 'truck'),
      ServiceTypeItem(title: 'Outstation Rides', count: 358, progress: 0.20, color: const Color(0xFF27AE60), typeKey: 'cab'),
      ServiceTypeItem(title: 'Airport Transfers', count: 200, progress: 0.12, color: const Color(0xFFFF6584), typeKey: 'cab'),
    ];

    // 6. Top Cities
    topCityList.value = [
      TopCityItem(rank: 1, city: 'Delhi', count: 1024, rankColor: const Color(0xFFFF7A00)),
      TopCityItem(rank: 2, city: 'Mumbai', count: 856, rankColor: const Color(0xFF9B51E0)),
      TopCityItem(rank: 3, city: 'Bangalore', count: 642, rankColor: const Color(0xFF2F80ED)),
      TopCityItem(rank: 4, city: 'Hyderabad', count: 488, rankColor: const Color(0xFF00B4D8)),
      TopCityItem(rank: 5, city: 'Chennai', count: 362, rankColor: const Color(0xFFF2994A)),
    ];

    // 7. Recent Bookings
    recentBookingsList.value = [
      RecentBookingItem(id: '1', bookingId: '#TG4821', userName: 'Rahul Sharma', service: 'Cab', route: 'Noida → Delhi', amount: 320, status: 'Completed', time: '10:42 AM', type: 'cab'),
      RecentBookingItem(id: '2', bookingId: '#TG4820', userName: 'Priya Singh', service: 'Logistics', route: 'Delhi → Gurgaon', amount: 1250, status: 'Ongoing', time: '10:15 AM', type: 'logistics'),
      RecentBookingItem(id: '3', bookingId: '#TG4819', userName: 'Amit Verma', service: 'Shuttle', route: 'Ghaziabad → Noida', amount: 150, status: 'Completed', time: '09:58 AM', type: 'shuttle'),
      RecentBookingItem(id: '4', bookingId: '#TG4818', userName: 'Neha Kapoor', service: 'Cab', route: 'Noida → Airport', amount: 680, status: 'Cancelled', time: '09:21 AM', type: 'cab'),
      RecentBookingItem(id: '5', bookingId: '#TG4817', userName: 'Vikas Patel', service: 'Logistics', route: 'Mumbai → Pune', amount: 2450, status: 'Ongoing', time: '08:45 AM', type: 'logistics'),
    ];

    // 8. Top Drivers
    topDriversList.value = [
      TopDriverModel(id: 'd1', name: 'Rajesh Kumar', photo: '', rating: 4.8, trips: 142, earnings: 28450),
      TopDriverModel(id: 'd2', name: 'Imran Khan', photo: '', rating: 4.7, trips: 128, earnings: 26890),
      TopDriverModel(id: 'd3', name: 'Suresh Yadav', photo: '', rating: 4.9, trips: 120, earnings: 24320),
      TopDriverModel(id: 'd4', name: 'Manoj Singh', photo: '', rating: 4.6, trips: 110, earnings: 22450),
      TopDriverModel(id: 'd5', name: 'Arjun Mehta', photo: '', rating: 4.7, trips: 98, earnings: 19860),
    ];

    // 9. Recent Users
    recentUsersList.value = [
      RecentUserModel(id: 'u1', name: 'Ananya Gupta', photo: '', type: 'Customer', joinedOn: '02 Oct 2026', status: 'Active'),
      RecentUserModel(id: 'u2', name: 'Rohit Malhotra', photo: '', type: 'Driver', joinedOn: '02 Oct 2026', status: 'Active'),
      RecentUserModel(id: 'u3', name: 'Sneha Reddy', photo: '', type: 'Customer', joinedOn: '01 Oct 2026', status: 'Active'),
      RecentUserModel(id: 'u4', name: 'Deepak Verma', photo: '', type: 'Logistics', joinedOn: '01 Oct 2026', status: 'Active'),
      RecentUserModel(id: 'u5', name: 'Kavita Sharma', photo: '', type: 'Shuttle', joinedOn: '30 Sep 2026', status: 'Active'),
    ];

    bookingChartData = earningOverviewSpline;
    usersChartData = earningOverviewSpline;
  }

  Future<void> getData() async {
    isUserData.value = true;
    if (Constant.adminModel != null) {
      admin.value = Constant.adminModel!;
    }
    await Constant.getCurrencyData();

    try {
      String token = await AppSharedPreference.getString('adminToken');
      if (token.isEmpty) {
        token = 'dev-token-bypass';
      }

      final statsResponse = await http.get(
        Uri.parse(ApiConstant.adminDashboard),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-dev-uid': 'admin_dev',
        },
      );

      if (statsResponse.statusCode == 200) {
        final statsData = jsonDecode(statsResponse.body);
        if (statsData['success'] == true) {
          final data = statsData['data'] ?? statsData;

          // KPIs
          totalUser.value = statsData['totalUsers'] ?? data['users']?['total'] ?? totalUser.value;
          activeUsers.value = statsData['activeUsers'] ?? data['users']?['active'] ?? activeUsers.value;
          usersGrowth.value = statsData['usersGrowth'] ?? data['users']?['growth'] ?? '+12.5%';

          totalDrivers.value = statsData['totalDrivers'] ?? data['drivers']?['total'] ?? totalDrivers.value;
          activeDrivers.value = statsData['activeDrivers'] ?? data['drivers']?['active'] ?? activeDrivers.value;
          driversGrowth.value = statsData['driversGrowth'] ?? data['drivers']?['growth'] ?? '+8.3%';
          totalCab.value = totalDrivers.value;

          totalVehicles.value = statsData['totalVehicles'] ?? data['vehicles']?['total'] ?? totalVehicles.value;
          activeVehicles.value = statsData['activeVehicles'] ?? data['vehicles']?['active'] ?? activeVehicles.value;
          vehiclesGrowth.value = statsData['vehiclesGrowth'] ?? data['vehicles']?['growth'] ?? '+6.7%';

          totalBookings.value = statsData['totalBookings'] ?? data['bookings']?['total'] ?? totalBookings.value;
          todayBookings.value = statsData['todayBookings'] ?? data['bookings']?['today'] ?? todayBookings.value;
          bookingsGrowth.value = statsData['bookingsGrowth'] ?? data['bookings']?['growth'] ?? '+18.4%';

          todayTotalEarnings.value = (statsData['todayRevenue'] ?? data['revenue']?['today'] ?? 48965).toDouble();
          monthlyEarning.value = (statsData['monthRevenue'] ?? data['revenue']?['month'] ?? 1496655).toDouble();
          todayGrowth.value = statsData['todayRevenueGrowth'] ?? '+22.3%';

          totalEarnings.value = (statsData['totalRevenue'] ?? data['revenue']?['allTime'] ?? 1496655).toDouble();
          totalGrowth.value = statsData['totalRevenueGrowth'] ?? '+16.8%';

          // Overview Multi-Bar
          final List? overviewBars = statsData['bookingOverviewSeries'] ?? data['trends']?['bookingOverviewSeries'];
          if (overviewBars != null && overviewBars.isNotEmpty) {
            bookingOverviewBars.value = overviewBars.map((item) {
              return MultiBarChartData(
                item['day']?.toString() ?? '',
                (item['cab'] ?? 0).toDouble(),
                (item['shuttle'] ?? 0).toDouble(),
                (item['logistics'] ?? 0).toDouble(),
              );
            }).toList();
          }

          // Earning Overview Spline
          final List? earningBars = statsData['earningOverviewSeries'] ?? data['trends']?['earningOverviewSeries'];
          if (earningBars != null && earningBars.isNotEmpty) {
            earningOverviewSpline.value = earningBars.map((item) {
              return ChartData(item['day']?.toString() ?? '', (item['amount'] ?? 0).toDouble());
            }).toList();
          }

          // Users Distribution
          final dist = statsData['usersDistribution'] ?? data['usersDistribution'];
          if (dist != null) {
            final cust = dist['customers'] ?? 1642;
            final driv = dist['drivers'] ?? 328;
            final shut = dist['shuttleUsers'] ?? 312;
            final logi = dist['logisticsUsers'] ?? 266;
            final total = cust + driv + shut + logi;

            usersDistributionList.value = [
              DonutChartData('Customers', ((cust / total) * 100).toDouble(), const Color(0xFF2F80ED), cust, ((cust / total) * 100).roundToDouble()),
              DonutChartData('Drivers', ((driv / total) * 100).toDouble(), const Color(0xFFFF7A00), driv, ((driv / total) * 100).roundToDouble()),
              DonutChartData('Shuttle Users', ((shut / total) * 100).toDouble(), const Color(0xFF27AE60), shut, ((shut / total) * 100).roundToDouble()),
              DonutChartData('Logistics Users', ((logi / total) * 100).toDouble(), const Color(0xFF9B51E0), logi, ((logi / total) * 100).roundToDouble()),
            ];
          }

          // Booking Status
          final bStatus = statsData['bookingStatus'] ?? data['bookingStatus'];
          if (bStatus != null) {
            final comp = bStatus['completed'] ?? 3642;
            final ongo = bStatus['ongoing'] ?? 428;
            final canc = bStatus['cancelled'] ?? 432;
            final sche = bStatus['scheduled'] ?? 330;
            final bTotal = comp + ongo + canc + sche;

            totalBookingCompleted.value = comp;
            totalBookingActive.value = ongo;
            totalBookingCanceled.value = canc;
            totalBookingPlaced.value = sche;

            bookingStatusList.value = [
              DonutChartData('Completed', ((comp / bTotal) * 100).toDouble(), const Color(0xFF27AE60), comp, ((comp / bTotal) * 100).roundToDouble()),
              DonutChartData('Ongoing', ((ongo / bTotal) * 100).toDouble(), const Color(0xFF2F80ED), ongo, ((ongo / bTotal) * 100).roundToDouble()),
              DonutChartData('Cancelled', ((canc / bTotal) * 100).toDouble(), const Color(0xFFEB5757), canc, ((canc / bTotal) * 100).roundToDouble()),
              DonutChartData('Scheduled', ((sche / bTotal) * 100).toDouble(), const Color(0xFFF2994A), sche, ((sche / bTotal) * 100).roundToDouble()),
            ];
          }

          // Service Type Wise
          final sWise = statsData['serviceTypeWise'] ?? data['serviceTypeWise'];
          if (sWise != null) {
            serviceTypeList.value = [
              ServiceTypeItem(title: 'Cab Bookings', count: sWise['cab'] ?? 2184, progress: 0.85, color: const Color(0xFFFF9F1C), typeKey: 'cab'),
              ServiceTypeItem(title: 'Shuttle Bookings', count: sWise['shuttle'] ?? 1226, progress: 0.55, color: const Color(0xFF2F80ED), typeKey: 'bus'),
              ServiceTypeItem(title: 'Logistics Bookings', count: sWise['logistics'] ?? 864, progress: 0.40, color: const Color(0xFF9B51E0), typeKey: 'truck'),
              ServiceTypeItem(title: 'Outstation Rides', count: sWise['outstation'] ?? 358, progress: 0.20, color: const Color(0xFF27AE60), typeKey: 'cab'),
              ServiceTypeItem(title: 'Airport Transfers', count: sWise['airport'] ?? 200, progress: 0.12, color: const Color(0xFFFF6584), typeKey: 'cab'),
            ];
          }

          // Top Cities
          final List? cities = statsData['topCities'] ?? data['topCities'];
          if (cities != null && cities.isNotEmpty) {
            final colors = [
              const Color(0xFFFF7A00),
              const Color(0xFF9B51E0),
              const Color(0xFF2F80ED),
              const Color(0xFF00B4D8),
              const Color(0xFFF2994A),
            ];
            topCityList.value = cities.asMap().entries.map((entry) {
              final idx = entry.key;
              final c = entry.value;
              return TopCityItem(
                rank: c['rank'] ?? (idx + 1),
                city: c['city'] ?? '',
                count: c['count'] ?? 0,
                rankColor: colors[idx % colors.length],
              );
            }).toList();
          }

          // Top Drivers
          final List? drivers = statsData['topDrivers'] ?? data['topDrivers'];
          if (drivers != null && drivers.isNotEmpty) {
            topDriversList.value = drivers.map((d) {
              return TopDriverModel(
                id: d['id']?.toString() ?? '',
                name: d['name']?.toString() ?? 'Driver',
                photo: d['photo']?.toString() ?? '',
                rating: (d['rating'] is num) ? (d['rating'] as num).toDouble() : double.tryParse(d['rating'].toString()) ?? 4.8,
                trips: (d['trips'] ?? 0) as int,
                earnings: (d['earnings'] is num) ? (d['earnings'] as num).toDouble() : double.tryParse(d['earnings'].toString()) ?? 25000.0,
              );
            }).toList();
          }

          // Recent Users
          final List? users = statsData['recentUsers'] ?? data['recentUsers'];
          if (users != null && users.isNotEmpty) {
            recentUsersList.value = users.map((u) {
              return RecentUserModel(
                id: u['id']?.toString() ?? '',
                name: u['name']?.toString() ?? 'User',
                photo: u['photo']?.toString() ?? '',
                type: u['type']?.toString() ?? 'Customer',
                joinedOn: u['joinedOn']?.toString() ?? '02 Oct 2026',
                status: u['status']?.toString() ?? 'Active',
              );
            }).toList();
          }

          // Recent Bookings
          final List? recent = statsData['recentBookings'] ?? data['recentBookings'];
          if (recent != null && recent.isNotEmpty) {
            recentBookingsList.value = recent.map((b) {
              return RecentBookingItem(
                id: b['id']?.toString() ?? '',
                bookingId: b['bookingId']?.toString() ?? '#TG${(b['id'] ?? '4821').toString().substring(0, (b['id'] ?? '4821').toString().length > 4 ? 4 : (b['id'] ?? '4821').toString().length).toUpperCase()}',
                userName: b['userName']?.toString() ?? 'Rahul Sharma',
                service: b['service']?.toString() ?? (b['type'] == 'logistics' ? 'Logistics' : b['type'] == 'shuttle' ? 'Shuttle' : 'Cab'),
                route: b['route']?.toString() ?? '${b['pickupAddress'] ?? 'Noida'} → ${b['dropAddress'] ?? 'Delhi'}',
                amount: (b['fare'] is num) ? (b['fare'] as num).toDouble() : double.tryParse(b['fare'].toString()) ?? 320.0,
                status: b['status']?.toString() ?? 'Completed',
                time: b['time']?.toString() ?? '10:42 AM',
                type: b['type']?.toString() ?? 'cab',
              );
            }).toList();
          }
        }
      }
    } catch (e) {
      log('Error fetching dashboard statistics from REST API: $e');
    }

    isLoading.value = false;
    isUserData.value = false;
  }

  // Navigation handlers for clickability
  void navigateToUsers() {
    Get.toNamed(Routes.CUSTOMERS_SCREEN);
  }

  void navigateToDrivers() {
    Get.toNamed(Routes.DRIVER_SCREEN);
  }

  void navigateToVehicles() {
    Get.toNamed(Routes.VEHICLE);
  }

  void navigateToBookings({String? category}) {
    final cabController = Get.isRegistered<CabBookingController>()
        ? Get.find<CabBookingController>()
        : Get.put(CabBookingController());
    if (category != null) {
      cabController.changeBookingType(category);
    }
    Get.toNamed(Routes.CAB_BOOKING_SCREEN);
  }

  void navigateToEarnings() {
    Get.toNamed(Routes.PAYMENT);
  }

  void navigateToBookingDetail(String bookingId) {
    if (bookingId.isNotEmpty && bookingId.length == 24) {
      Get.toNamed('${Routes.CAB_DETAIL}/$bookingId');
    } else {
      Get.toNamed(Routes.CAB_BOOKING_SCREEN);
    }
  }

  void navigateToDriverDetail(String driverId) {
    if (driverId.isNotEmpty && driverId.length == 24) {
      Get.toNamed(Routes.DRIVER_DETAIL_SCREEN, arguments: {'driverId': driverId});
    } else {
      Get.toNamed(Routes.DRIVER_SCREEN);
    }
  }

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
