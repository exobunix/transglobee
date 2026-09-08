import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:admin/app/modules/cab_detail/controllers/cab_detail_controller.dart';
import 'supervisor_overview_card.dart';
import 'supervisor_goods_card_view.dart';
import 'supervisor_roadmap_card_view.dart';
import 'supervisor_pricing_card_view.dart';

class SupervisorLayoutView extends StatelessWidget {
  final CabDetailController controller;
  final DarkThemeProvider themeChange;

  const SupervisorLayoutView({
    super.key,
    required this.controller,
    required this.themeChange,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = controller.bookingModel.value.bookingStatus?.toLowerCase() == 'placed' ||
                      controller.bookingModel.value.bookingStatus?.toLowerCase() == 'pending' ||
                      controller.bookingModel.value.bookingStatus?.toLowerCase() == 'booking_placed';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Get.back(),
                    ),
                    const SizedBox(width: 8),
                    TextCustom(
                      title: "Manage: ${controller.userModel.value.fullName ?? ''}",
                      fontSize: 20,
                      fontFamily: AppThemeData.bold,
                    ),
                  ],
                ),
                if (isPending)
                  ElevatedButton.icon(
                    onPressed: () => controller.approveBooking(),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    label: Text("ACCEPT BOOKING".tr, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      elevation: 0,
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            SupervisorOverviewCard(controller: controller, themeChange: themeChange),
                            const SizedBox(height: 20),
                            SupervisorGoodsCardView(controller: controller, themeChange: themeChange),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            SupervisorRoadmapCardView(controller: controller, themeChange: themeChange),
                            const SizedBox(height: 20),
                            SupervisorPricingCardView(controller: controller, themeChange: themeChange),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      SupervisorOverviewCard(controller: controller, themeChange: themeChange),
                      const SizedBox(height: 20),
                      SupervisorGoodsCardView(controller: controller, themeChange: themeChange),
                      const SizedBox(height: 20),
                      SupervisorRoadmapCardView(controller: controller, themeChange: themeChange),
                      const SizedBox(height: 20),
                      SupervisorPricingCardView(controller: controller, themeChange: themeChange),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
