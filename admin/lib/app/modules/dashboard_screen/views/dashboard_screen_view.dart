// ignore_for_file: deprecated_member_use

import 'package:admin/app/components/menu_widget.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/modules/dashboard_screen/controllers/dashboard_screen_controller.dart';
import 'package:admin/app/routes/app_pages.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/app/utils/responsive.dart';
import 'package:admin/widget/common_ui.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DashboardScreenView extends GetView<DashboardScreenController> {
  const DashboardScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetBuilder<DashboardScreenController>(
      init: DashboardScreenController(),
      builder: (controller) {
        return ResponsiveWidget(
          mobile: Scaffold(
            key: controller.scaffoldKeyDrawer,
            backgroundColor: isDark ? const Color(0xFF111418) : const Color(0xFFF6F8FB),
            appBar: AppBar(
              elevation: 0.0,
              toolbarHeight: 65,
              automaticallyImplyLeading: false,
              backgroundColor: isDark ? AppThemData.primaryBlack : AppThemData.primaryWhite,
              leading: IconButton(
                icon: Icon(Icons.menu, color: AppThemData.primary500),
                onPressed: () => controller.toggleDrawer(),
              ),
              title: TextCustom(
                title: "Dashboard".tr,
                fontSize: 18,
                fontFamily: AppThemeData.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              actions: [
                _buildThemeToggle(themeChange),
                12.width,
                const LanguagePopUp(),
                12.width,
                ProfilePopUp(),
                16.width,
              ],
            ),
            drawer: Drawer(
              width: 270,
              backgroundColor: isDark ? AppThemData.primaryBlack : AppThemData.primaryWhite,
              child: const MenuWidget(),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildDashboardContent(context, controller, isDark, isMobile: true),
            ),
          ),
          tablet: Scaffold(
            backgroundColor: isDark ? const Color(0xFF111418) : const Color(0xFFF6F8FB),
            appBar: CommonUI.appBarCustom(themeChange: themeChange, scaffoldKey: controller.scaffoldKeyDrawer),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MenuWidget(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: _buildDashboardContent(context, controller, isDark, isMobile: true),
                  ),
                ),
              ],
            ),
          ),
          desktop: Scaffold(
            backgroundColor: isDark ? const Color(0xFF111418) : const Color(0xFFF6F8FB),
            appBar: CommonUI.appBarCustom(themeChange: themeChange, scaffoldKey: controller.scaffoldKeyDrawer),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MenuWidget(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: _buildDashboardContent(context, controller, isDark, isMobile: false),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeToggle(DarkThemeProvider themeChange) {
    return GestureDetector(
      onTap: () {
        if (themeChange.darkTheme == 1) {
          themeChange.darkTheme = 0;
        } else {
          themeChange.darkTheme = 1;
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeChange.isDarkTheme() ? Colors.white10 : Colors.black.withOpacity(0.04),
          shape: BoxShape.circle,
        ),
        child: themeChange.isDarkTheme()
            ? SvgPicture.asset("assets/icons/ic_sun.svg", color: AppThemData.yellow600, height: 18, width: 18)
            : SvgPicture.asset("assets/icons/ic_moon.svg", color: AppThemData.blue400, height: 18, width: 18),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, DashboardScreenController controller, bool isDark, {required bool isMobile}) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. TOP 6 METRIC CARDS ──────────────────────────────────
          _buildMetricCardsRow(context, controller, isDark, isMobile),
          24.height,

          // ─── 2. ROW 2: ANALYTICS (Booking, Earning, Users Dist) ──────
          if (isMobile) ...[
            _buildBookingOverviewCard(context, controller, isDark),
            20.height,
            _buildEarningOverviewCard(context, controller, isDark),
            20.height,
            _buildUsersDistributionCard(context, controller, isDark),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 44, child: _buildBookingOverviewCard(context, controller, isDark)),
                20.width,
                Expanded(flex: 34, child: _buildEarningOverviewCard(context, controller, isDark)),
                20.width,
                Expanded(flex: 22, child: _buildUsersDistributionCard(context, controller, isDark)),
              ],
            ),
          ],
          24.height,

          // ─── 3. ROW 3: OPERATIONS (Status, Service Type, Top Cities, Live) ──
          if (isMobile) ...[
            _buildBookingStatusCard(context, controller, isDark),
            20.height,
            _buildServiceTypeWiseCard(context, controller, isDark),
            20.height,
            _buildTopCitiesCard(context, controller, isDark),
            20.height,
            _buildLiveBookingsCard(context, controller, isDark),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 25, child: _buildBookingStatusCard(context, controller, isDark)),
                20.width,
                Expanded(flex: 28, child: _buildServiceTypeWiseCard(context, controller, isDark)),
                20.width,
                Expanded(flex: 21, child: _buildTopCitiesCard(context, controller, isDark)),
                20.width,
                Expanded(flex: 26, child: _buildLiveBookingsCard(context, controller, isDark)),
              ],
            ),
          ],
          24.height,

          // ─── 4. ROW 4: DATA TABLES (Recent Bookings, Top Drivers, Recent Users) ──
          if (isMobile) ...[
            _buildRecentBookingsCard(context, controller, isDark),
            20.height,
            _buildTopDriversCard(context, controller, isDark),
            20.height,
            _buildRecentUsersCard(context, controller, isDark),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 48, child: _buildRecentBookingsCard(context, controller, isDark)),
                20.width,
                Expanded(flex: 27, child: _buildTopDriversCard(context, controller, isDark)),
                20.width,
                Expanded(flex: 25, child: _buildRecentUsersCard(context, controller, isDark)),
              ],
            ),
          ],
          30.height,
        ],
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION 1: TOP 6 METRIC CARDS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildMetricCardsRow(BuildContext context, DashboardScreenController controller, bool isDark, bool isMobile) {
    final currencySymbol = Constant.currencyModel?.symbol ?? '₹';
    final cards = [
      _buildSingleMetricCard(
        title: "Total Users",
        value: NumberFormat('#,##,###').format(controller.totalUser.value),
        growth: controller.usersGrowth.value,
        subtext: "${NumberFormat('#,##,###').format(controller.activeUsers.value)} Active",
        icon: Icons.person_rounded,
        iconBg: const Color(0xFFE8F1FF),
        iconColor: const Color(0xFF2F80ED),
        sparklineColor: const Color(0xFF2F80ED),
        isDark: isDark,
        onTap: controller.navigateToUsers,
      ),
      _buildSingleMetricCard(
        title: "Total Drivers",
        value: NumberFormat('#,##,###').format(controller.totalDrivers.value),
        growth: controller.driversGrowth.value,
        subtext: "${NumberFormat('#,##,###').format(controller.activeDrivers.value)} Active",
        icon: Icons.drive_eta_rounded,
        iconBg: const Color(0xFFFFEFE5),
        iconColor: const Color(0xFFFF7A00),
        sparklineColor: const Color(0xFFFF7A00),
        isDark: isDark,
        onTap: controller.navigateToDrivers,
      ),
      _buildSingleMetricCard(
        title: "Total Vehicles",
        value: NumberFormat('#,##,###').format(controller.totalVehicles.value),
        growth: controller.vehiclesGrowth.value,
        subtext: "${NumberFormat('#,##,###').format(controller.activeVehicles.value)} Active",
        icon: Icons.directions_car_filled_rounded,
        iconBg: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF9B51E0),
        sparklineColor: const Color(0xFF9B51E0),
        isDark: isDark,
        onTap: controller.navigateToVehicles,
      ),
      _buildSingleMetricCard(
        title: "Total Bookings",
        value: NumberFormat('#,##,###').format(controller.totalBookings.value),
        growth: controller.bookingsGrowth.value,
        subtext: "${NumberFormat('#,##,###').format(controller.todayBookings.value)} Today",
        icon: Icons.receipt_long_rounded,
        iconBg: const Color(0xFFE8F8F0),
        iconColor: const Color(0xFF27AE60),
        sparklineColor: const Color(0xFF27AE60),
        isDark: isDark,
        onTap: controller.navigateToBookings,
      ),
      _buildSingleMetricCard(
        title: "Today's Earning",
        value: "$currencySymbol ${NumberFormat('#,##,###').format(controller.todayTotalEarnings.value.round())}",
        growth: controller.todayGrowth.value,
        subtext: "This month $currencySymbol ${NumberFormat('#,##,###').format(controller.monthlyEarning.value.round())}",
        icon: Icons.currency_rupee_rounded,
        iconBg: const Color(0xFFFFE8EC),
        iconColor: const Color(0xFFEB5757),
        sparklineColor: const Color(0xFFEB5757),
        isDark: isDark,
        onTap: controller.navigateToEarnings,
      ),
      _buildSingleMetricCard(
        title: "Total Earning",
        value: "$currencySymbol ${NumberFormat('#,##,###').format(controller.totalEarnings.value.round())}",
        growth: controller.totalGrowth.value,
        subtext: "This year",
        icon: Icons.account_balance_wallet_rounded,
        iconBg: const Color(0xFFFFF7E6),
        iconColor: const Color(0xFFF2994A),
        sparklineColor: const Color(0xFFF2994A),
        isDark: isDark,
        onTap: controller.navigateToEarnings,
      ),
    ];

    if (isMobile) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cards.map((c) => SizedBox(width: (MediaQuery.of(context).size.width - 44) / 2, child: c)).toList(),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - (5 * 14)) / 6;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
      );
    });
  }

  Widget _buildSingleMetricCard({
    required String title,
    required String value,
    required String growth,
    required String subtext,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color sparklineColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.02),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E222A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFEAEFF5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : const Color(0x0A000000),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: isDark ? iconColor.withOpacity(0.2) : iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFB0B7C3)),
                ],
              ),
              12.height,
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ),
              4.height,
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              10.height,
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.arrow_upward_rounded, size: 12, color: Color(0xFF27AE60)),
                            const SizedBox(width: 2),
                            Text(
                              growth,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF27AE60),
                              ),
                            ),
                          ],
                        ),
                        2.height,
                        Text(
                          subtext,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 24,
                    width: 46,
                    child: CustomPaint(
                      painter: MiniSparklinePainter(color: sparklineColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION 2: ROW 2 ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════

  // 1. Booking Overview Card
  Widget _buildBookingOverviewCard(BuildContext context, DashboardScreenController controller, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Booking Overview",
                style: _cardTitleStyle(isDark),
              ),
              _buildDropdownPill("Last 30 Days", isDark),
            ],
          ),
          10.height,
          Row(
            children: [
              _buildLegendDot(const Color(0xFFFF7A00), "Cab", isDark),
              16.width,
              _buildLegendDot(const Color(0xFF2F80ED), "Shuttle", isDark),
              16.width,
              _buildLegendDot(const Color(0xFF27AE60), "Logistics", isDark),
            ],
          ),
          16.height,
          SizedBox(
            height: 240,
            child: SfCartesianChart(
              margin: EdgeInsets.zero,
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: AxisLine(color: isDark ? Colors.white24 : const Color(0xFFE5E7EB)),
                labelStyle: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF6B7280)),
              ),
              primaryYAxis: NumericAxis(
                maximum: 200,
                interval: 50,
                majorGridLines: MajorGridLines(
                  color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                  dashArray: const <double>[4, 4],
                ),
                axisLine: const AxisLine(width: 0),
                labelStyle: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF6B7280)),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CartesianSeries>[
                ColumnSeries<MultiBarChartData, String>(
                  name: 'Cab',
                  dataSource: controller.bookingOverviewBars,
                  xValueMapper: (MultiBarChartData data, _) => data.day,
                  yValueMapper: (MultiBarChartData data, _) => data.cab,
                  color: const Color(0xFFFF7A00),
                  width: 0.25,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                ColumnSeries<MultiBarChartData, String>(
                  name: 'Shuttle',
                  dataSource: controller.bookingOverviewBars,
                  xValueMapper: (MultiBarChartData data, _) => data.day,
                  yValueMapper: (MultiBarChartData data, _) => data.shuttle,
                  color: const Color(0xFF2F80ED),
                  width: 0.25,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                ColumnSeries<MultiBarChartData, String>(
                  name: 'Logistics',
                  dataSource: controller.bookingOverviewBars,
                  xValueMapper: (MultiBarChartData data, _) => data.day,
                  yValueMapper: (MultiBarChartData data, _) => data.logistics,
                  color: const Color(0xFF27AE60),
                  width: 0.25,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Earning Overview Card
  Widget _buildEarningOverviewCard(BuildContext context, DashboardScreenController controller, bool isDark) {
    final currencySymbol = Constant.currencyModel?.symbol ?? '₹';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Earning Overview",
                style: _cardTitleStyle(isDark),
              ),
              _buildDropdownPill("Last 30 Days", isDark),
            ],
          ),
          8.height,
          Row(
            children: [
              Text(
                "$currencySymbol ${NumberFormat('#,##,###').format(controller.totalEarnings.value.round())}",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              10.width,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward_rounded, size: 12, color: Color(0xFF27AE60)),
                    const SizedBox(width: 2),
                    Text(
                      controller.totalGrowth.value,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF27AE60)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          16.height,
          SizedBox(
            height: 240,
            child: SfCartesianChart(
              margin: EdgeInsets.zero,
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: AxisLine(color: isDark ? Colors.white24 : const Color(0xFFE5E7EB)),
                labelStyle: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF6B7280)),
              ),
              primaryYAxis: NumericAxis(
                numberFormat: NumberFormat.compact(),
                majorGridLines: MajorGridLines(
                  color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                  dashArray: const <double>[4, 4],
                ),
                axisLine: const AxisLine(width: 0),
                labelStyle: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF6B7280)),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                header: '',
                canShowMarker: true,
                format: 'point.x : $currencySymbol point.y',
              ),
              series: <CartesianSeries>[
                SplineAreaSeries<ChartData, String>(
                  dataSource: controller.earningOverviewSpline,
                  xValueMapper: (ChartData data, _) => data.x,
                  yValueMapper: (ChartData data, _) => data.y,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF7A00).withOpacity(0.35),
                      const Color(0xFFFF7A00).withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderColor: const Color(0xFFFF7A00),
                  borderWidth: 2.5,
                ),
                SplineSeries<ChartData, String>(
                  dataSource: controller.earningOverviewSpline,
                  xValueMapper: (ChartData data, _) => data.x,
                  yValueMapper: (ChartData data, _) => data.y,
                  color: const Color(0xFFFF7A00),
                  width: 2.5,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    height: 6,
                    width: 6,
                    shape: DataMarkerType.circle,
                    borderWidth: 2,
                    borderColor: Colors.white,
                    color: Color(0xFFFF7A00),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Users Distribution Card
  Widget _buildUsersDistributionCard(BuildContext context, DashboardScreenController controller, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.navigateToUsers,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Users Distribution", style: _cardTitleStyle(isDark)),
                  _buildDropdownPill("This Month", isDark),
                ],
              ),
              12.height,
              SizedBox(
                height: 170,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SfCircularChart(
                      margin: EdgeInsets.zero,
                      series: <CircularSeries>[
                        DoughnutSeries<DonutChartData, String>(
                          dataSource: controller.usersDistributionList,
                          xValueMapper: (DonutChartData data, _) => data.label,
                          yValueMapper: (DonutChartData data, _) => data.value,
                          pointColorMapper: (DonutChartData data, _) => data.color,
                          innerRadius: '72%',
                          radius: '95%',
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          NumberFormat('#,##,###').format(controller.totalUser.value),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          "Total Users",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              12.height,
              Column(
                children: controller.usersDistributionList.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                        ),
                        8.width,
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF4B5563)),
                          ),
                        ),
                        Text(
                          NumberFormat('#,##,###').format(item.count),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        8.width,
                        SizedBox(
                          width: 34,
                          child: Text(
                            "${item.percentage.round()}%",
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION 3: ROW 3 OPERATIONS GRID
  // ═══════════════════════════════════════════════════════════════════════

  // 1. Booking Status Card
  Widget _buildBookingStatusCard(BuildContext context, DashboardScreenController controller, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.navigateToBookings,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Booking Status", style: _cardTitleStyle(isDark)),
                  _buildDropdownPill("This Month", isDark),
                ],
              ),
              12.height,
              SizedBox(
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SfCircularChart(
                      margin: EdgeInsets.zero,
                      series: <CircularSeries>[
                        DoughnutSeries<DonutChartData, String>(
                          dataSource: controller.bookingStatusList,
                          xValueMapper: (DonutChartData data, _) => data.label,
                          yValueMapper: (DonutChartData data, _) => data.value,
                          pointColorMapper: (DonutChartData data, _) => data.color,
                          innerRadius: '72%',
                          radius: '95%',
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          NumberFormat('#,##,###').format(controller.totalBookings.value),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          "Total Bookings",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              12.height,
              Column(
                children: controller.bookingStatusList.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(2)),
                        ),
                        8.width,
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF4B5563)),
                          ),
                        ),
                        Text(
                          NumberFormat('#,##,###').format(item.count),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        8.width,
                        SizedBox(
                          width: 32,
                          child: Text(
                            "${item.percentage.round()}%",
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Service Type Wise Bookings Card
  Widget _buildServiceTypeWiseCard(BuildContext context, DashboardScreenController controller, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Service Type Wise Bookings", style: _cardTitleStyle(isDark)),
              _buildDropdownPill("This Month", isDark),
            ],
          ),
          16.height,
          Column(
            children: controller.serviceTypeList.map((item) {
              return InkWell(
                onTap: () => controller.navigateToBookings(category: item.typeKey),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                            ),
                          ),
                          Text(
                            NumberFormat('#,##,###').format(item.count),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      6.height,
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: item.progress,
                          minHeight: 8,
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                          valueColor: AlwaysStoppedAnimation<Color>(item.color),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 3. Top Cities Card
  Widget _buildTopCitiesCard(BuildContext context, DashboardScreenController controller, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Top Cities", style: _cardTitleStyle(isDark)),
              _buildDropdownPill("This Month", isDark),
            ],
          ),
          16.height,
          Column(
            children: controller.topCityList.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: item.rankColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.rank.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: item.rankColor,
                        ),
                      ),
                    ),
                    12.width,
                    Expanded(
                      child: Text(
                        item.city,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    Text(
                      NumberFormat('#,##,###').format(item.count),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 4. Live Bookings Widget Card
  Widget _buildLiveBookingsCard(BuildContext context, DashboardScreenController controller, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Live Bookings", style: _cardTitleStyle(isDark)),
              _buildOrangeViewAllButton(onTap: controller.navigateToBookings),
            ],
          ),
          16.height,
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 215,
              width: double.infinity,
              color: isDark ? const Color(0xFF151921) : const Color(0xFFEBF3FC),
              child: Stack(
                children: [
                  // Vector map roads visual
                  CustomPaint(
                    size: const Size(double.infinity, 215),
                    painter: MiniMapRoadPainter(isDark: isDark),
                  ),
                  // Simulated Live Vehicle Markers
                  _buildMapMarker(top: 25, left: 40, icon: Icons.local_shipping_rounded, color: const Color(0xFF27AE60)),
                  _buildMapMarker(top: 90, right: 35, icon: Icons.local_shipping_rounded, color: const Color(0xFFFF7A00)),
                  _buildMapMarker(bottom: 45, left: 30, icon: Icons.directions_car_filled_rounded, color: const Color(0xFF2F80ED)),
                  _buildMapMarker(bottom: 25, right: 65, icon: Icons.directions_car_filled_rounded, color: const Color(0xFF111827)),
                  // User Location Pin
                  Positioned(
                    top: 85,
                    left: 110,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F80ED),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2F80ED).withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black54 : Colors.white70,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF27AE60),
                              shape: BoxShape.circle,
                            ),
                          ),
                          6.width,
                          const Text(
                            "LIVE",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF27AE60)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapMarker({double? top, double? bottom, double? left, double? right, required IconData icon, required Color color}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION 4: ROW 4 DATA TABLES & LISTS
  // ═══════════════════════════════════════════════════════════════════════

  // 1. Recent Bookings Table Card
  Widget _buildRecentBookingsCard(BuildContext context, DashboardScreenController controller, bool isDark) {
    final currencySymbol = Constant.currencyModel?.symbol ?? '₹';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Recent Bookings", style: _cardTitleStyle(isDark)),
              _buildOrangeViewAllButton(onTap: controller.navigateToBookings),
            ],
          ),
          16.height,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              horizontalMargin: 8,
              columnSpacing: 18,
              headingRowHeight: 40,
              dataRowMaxHeight: 56,
              headingTextStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              ),
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('User')),
                DataColumn(label: Text('Service')),
                DataColumn(label: Text('From → To')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Time')),
                DataColumn(label: Text('')),
              ],
              rows: controller.recentBookingsList.map((b) {
                return DataRow(
                  onSelectChanged: (_) => controller.navigateToBookingDetail(b.id),
                  cells: [
                    DataCell(Text(
                      b.bookingId,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF374151),
                      ),
                    )),
                    DataCell(Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFFE5E7EB),
                          child: Text(
                            b.userName.isNotEmpty ? b.userName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                          ),
                        ),
                        8.width,
                        Text(
                          b.userName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                      ],
                    )),
                    DataCell(_buildServicePill(b.service)),
                    DataCell(Text(
                      b.route,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF4B5563)),
                    )),
                    DataCell(Text(
                      "$currencySymbol ${b.amount.round()}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    )),
                    DataCell(_buildStatusBadge(b.status)),
                    DataCell(Text(
                      b.time,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                    )),
                    DataCell(IconButton(
                      icon: const Icon(Icons.more_vert_rounded, size: 16, color: Color(0xFF9CA3AF)),
                      onPressed: () => controller.navigateToBookingDetail(b.id),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Top Drivers List Card
  Widget _buildTopDriversCard(BuildContext context, DashboardScreenController controller, bool isDark) {
    final currencySymbol = Constant.currencyModel?.symbol ?? '₹';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Top Drivers", style: _cardTitleStyle(isDark)),
              _buildOrangeViewAllButton(onTap: controller.navigateToDrivers),
            ],
          ),
          16.height,
          Column(
            children: controller.topDriversList.asMap().entries.map((entry) {
              final idx = entry.key;
              final d = entry.value;
              return InkWell(
                onTap: () => controller.navigateToDriverDetail(d.id),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: (idx == 0)
                              ? const Color(0xFFFFEFE5)
                              : (idx == 1)
                                  ? const Color(0xFFEBF3FC)
                                  : (idx == 2)
                                      ? const Color(0xFFFFF7E6)
                                      : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "${idx + 1}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: (idx == 0)
                                ? const Color(0xFFFF7A00)
                                : (idx == 1)
                                    ? const Color(0xFF2F80ED)
                                    : (idx == 2)
                                        ? const Color(0xFFF2994A)
                                        : Colors.grey,
                          ),
                        ),
                      ),
                      10.width,
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFE5E7EB),
                        child: Text(
                          d.name.isNotEmpty ? d.name[0].toUpperCase() : 'D',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                        ),
                      ),
                      10.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF111827),
                              ),
                            ),
                            2.height,
                            Row(
                              children: [
                                Text(
                                  "${d.rating}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB800)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "$currencySymbol ${NumberFormat('#,##,###').format(d.earnings.round())}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                            ),
                          ),
                          2.height,
                          Text(
                            "${d.trips} trips",
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                      4.width,
                      const Icon(Icons.more_vert_rounded, size: 16, color: Color(0xFFB0B7C3)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 3. Recent Users List Card
  Widget _buildRecentUsersCard(BuildContext context, DashboardScreenController controller, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Recent Users", style: _cardTitleStyle(isDark)),
              _buildOrangeViewAllButton(onTap: controller.navigateToUsers),
            ],
          ),
          16.height,
          Column(
            children: controller.recentUsersList.map((u) {
              return InkWell(
                onTap: controller.navigateToUsers,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFE5E7EB),
                        child: Text(
                          u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                        ),
                      ),
                      10.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF111827),
                              ),
                            ),
                            2.height,
                            Text(
                              u.joinedOn,
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      ),
                      _buildUserTypePill(u.type),
                      8.width,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "Active",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF27AE60)),
                        ),
                      ),
                      4.width,
                      const Icon(Icons.more_vert_rounded, size: 16, color: Color(0xFFB0B7C3)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHARED STYLING HELPERS & BADGES
  // ═══════════════════════════════════════════════════════════════════════

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E222A) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFEAEFF5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black26 : const Color(0x0A000000),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  TextStyle _cardTitleStyle(bool isDark) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: isDark ? Colors.white : const Color(0xFF111827),
      letterSpacing: -0.3,
    );
  }

  Widget _buildDropdownPill(String title, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.white24 : const Color(0xFFE5E7EB),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : const Color(0xFF4B5563)),
          ),
          4.width,
          Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: isDark ? Colors.white70 : const Color(0xFF4B5563)),
        ],
      ),
    );
  }

  Widget _buildOrangeViewAllButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFF7A00),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          "View All",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        6.width,
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildServicePill(String service) {
    Color bg = const Color(0xFFFFEFE5);
    Color text = const Color(0xFFFF7A00);
    if (service.toLowerCase().contains('logistics')) {
      bg = const Color(0xFFE8F8F0);
      text = const Color(0xFF27AE60);
    } else if (service.toLowerCase().contains('shuttle')) {
      bg = const Color(0xFFEBF3FC);
      text = const Color(0xFF2F80ED);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        service,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFE8F8F0);
    Color text = const Color(0xFF27AE60);

    if (status.toLowerCase().contains('ongoing') || status.toLowerCase().contains('active')) {
      bg = const Color(0xFFEBF3FC);
      text = const Color(0xFF2F80ED);
    } else if (status.toLowerCase().contains('cancel')) {
      bg = const Color(0xFFFFE8EC);
      text = const Color(0xFFEB5757);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text),
      ),
    );
  }

  Widget _buildUserTypePill(String type) {
    Color bg = const Color(0xFFEBF3FC);
    Color text = const Color(0xFF2F80ED);

    if (type.toLowerCase() == 'driver') {
      bg = const Color(0xFFFFEFE5);
      text = const Color(0xFFFF7A00);
    } else if (type.toLowerCase() == 'logistics') {
      bg = const Color(0xFFE8F8F0);
      text = const Color(0xFF27AE60);
    } else if (type.toLowerCase() == 'shuttle') {
      bg = const Color(0xFFF3E8FF);
      text = const Color(0xFF9B51E0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        type,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: text),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS: MINI SPARKLINE & MINI MAP
// ═══════════════════════════════════════════════════════════════════════

class MiniSparklinePainter extends CustomPainter {
  final Color color;

  MiniSparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.9,
      size.width * 0.4,
      size.height * 0.2,
      size.width * 0.65,
      size.height * 0.4,
    );
    path.cubicTo(
      size.width * 0.8,
      size.height * 0.55,
      size.width * 0.9,
      size.height * 0.1,
      size.width,
      size.height * 0.2,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiniMapRoadPainter extends CustomPainter {
  final bool isDark;

  MiniMapRoadPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = isDark ? Colors.white12 : const Color(0xFFD6E4F0)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final majorRoadPaint = Paint()
      ..color = isDark ? Colors.white24 : const Color(0xFFBFD7ED)
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Diagonal main highway
    final path1 = Path();
    path1.moveTo(0, size.height * 0.3);
    path1.quadraticBezierTo(size.width * 0.5, size.height * 0.4, size.width, size.height * 0.8);
    canvas.drawPath(path1, majorRoadPaint);

    // Cross road
    final path2 = Path();
    path2.moveTo(size.width * 0.2, 0);
    path2.lineTo(size.width * 0.8, size.height);
    canvas.drawPath(path2, roadPaint);

    // Secondary connector
    final path3 = Path();
    path3.moveTo(0, size.height * 0.75);
    path3.lineTo(size.width * 0.6, size.height * 0.3);
    canvas.drawPath(path3, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
