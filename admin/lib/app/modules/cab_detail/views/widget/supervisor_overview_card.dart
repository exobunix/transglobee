import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/widget/container_custom.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:admin/app/modules/cab_detail/controllers/cab_detail_controller.dart';

class SupervisorOverviewCard extends StatelessWidget {
  final CabDetailController controller;
  final DarkThemeProvider themeChange;

  const SupervisorOverviewCard({
    super.key,
    required this.controller,
    required this.themeChange,
  });

  @override
  Widget build(BuildContext context) {
    final cardBgColor = themeChange.isDarkTheme() ? AppThemData.greyShade900 : AppThemData.primaryWhite;
    final borderColor = themeChange.isDarkTheme() ? AppThemData.greyShade800 : AppThemData.greyShade100;

    return ContainerCustom(
      child: Card(
        color: cardBgColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppThemData.primary500),
                  const SizedBox(width: 8),
                  TextCustom(title: "Booking Overview".tr, fontSize: 16, fontFamily: AppThemeData.bold),
                ],
              ),
              const SizedBox(height: 20),
              _buildOverviewRow("Booking ID:", controller.bookingIdText),
              Obx(() => _buildOverviewRow("Customer:", controller.customerText.value.isEmpty ? '-' : controller.customerText.value)),
              Obx(() => _buildOverviewRow("Pickup:", controller.pickupText.value.isEmpty ? '-' : controller.pickupText.value)),
              Obx(() => _buildOverviewRow("Drop:", controller.dropText.value.isEmpty ? '-' : controller.dropText.value)),
              Obx(() => _buildOverviewRow("Mode:", controller.transportMode.value)),
              Obx(() => _buildOverviewRow("Total Price:", "₹${controller.totalPrice.value.toStringAsFixed(2)}")),
              _buildOverviewRow("Status:", controller.bookingModel.value.bookingStatus?.toUpperCase() ?? 'PENDING'),
              Obx(() => _buildOverviewRow("Roadmap:", controller.roadmapStatusText.value)),
              Obx(() => _buildOverviewRow("Items:", "${controller.itemsCount.value} item(s)")),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewRow(String label, String value) {
    final textStyle = TextStyle(
      color: themeChange.isDarkTheme() ? Colors.white : Colors.black,
      fontSize: 14,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: themeChange.isDarkTheme() ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
