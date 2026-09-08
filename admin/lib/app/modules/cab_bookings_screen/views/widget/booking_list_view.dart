import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/app/modules/cab_bookings_screen/controllers/cab_booking_controller.dart';
import 'booking_card_item.dart';

class BookingListView extends StatelessWidget {
  final CabBookingController controller;
  final DarkThemeProvider themeChange;

  const BookingListView({
    super.key,
    required this.controller,
    required this.themeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(color: AppThemData.primary500),
          ),
        );
      }

      if (controller.currentPageBooking.isEmpty) {
        return Center(
          child: TextCustom(title: "No Data available".tr),
        );
      }

      return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: controller.currentPageBooking.length,
        itemBuilder: (context, index) {
          final bookingModel = controller.currentPageBooking[index];
          return BookingCardItem(
            bookingModel: bookingModel,
            themeChange: themeChange,
          );
        },
      );
    });
  }
}
