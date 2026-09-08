import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/app/utils/responsive.dart';
import 'package:admin/widget/container_custom.dart';
import '../../controllers/cab_detail_controller.dart';
import 'standard_booking_details_widget.dart';
import 'standard_pricing_details_widget.dart';
import 'pick_drop_point_view.dart';

class StandardCabDetailLayoutView extends StatelessWidget {
  final CabDetailController controller;
  final DarkThemeProvider themeChange;

  const StandardCabDetailLayoutView({
    super.key,
    required this.controller,
    required this.themeChange,
  });

  @override
  Widget build(BuildContext context) {
    final booking = controller.bookingModel.value;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: ContainerCustom(
              child: Column(
                children: [
                  ResponsiveWidget(
                    mobile: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StandardBookingDetailsWidget(controller: controller, themeChange: themeChange),
                        const SizedBox(height: 20),
                        PickDropPointView(
                          dropAddress: booking.dropLocationAddress.toString(),
                          pickUpAddress: booking.pickUpLocationAddress.toString(),
                        ),
                        const SizedBox(height: 20),
                        StandardPricingDetailsWidget(controller: controller, themeChange: themeChange),
                      ],
                    ),
                    tablet: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StandardBookingDetailsWidget(controller: controller, themeChange: themeChange),
                        const SizedBox(height: 20),
                        PickDropPointView(
                          dropAddress: booking.dropLocationAddress.toString(),
                          pickUpAddress: booking.pickUpLocationAddress.toString(),
                        ),
                        const SizedBox(height: 20),
                        StandardPricingDetailsWidget(controller: controller, themeChange: themeChange),
                      ],
                    ),
                    desktop: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  StandardBookingDetailsWidget(controller: controller, themeChange: themeChange),
                                  const SizedBox(height: 20),
                                  PickDropPointView(
                                    dropAddress: booking.dropLocationAddress.toString(),
                                    pickUpAddress: booking.pickUpLocationAddress.toString(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 1,
                              child: StandardPricingDetailsWidget(controller: controller, themeChange: themeChange),
                            ),
                          ],
                        ),
                      ],
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
}
