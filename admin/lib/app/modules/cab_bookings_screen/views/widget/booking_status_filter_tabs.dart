import 'package:admin/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/app/modules/cab_bookings_screen/controllers/cab_booking_controller.dart';

class BookingStatusFilterTabs extends StatelessWidget {
  final CabBookingController controller;
  const BookingStatusFilterTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedType = controller.selectedBookingType.value;
      if (selectedType == "truck" || selectedType == "bus") {
        final activeStatus = controller.selectedBookingStatus.value;
        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusTab("Pending".tr, "Placed", activeStatus == "Placed" || activeStatus == "All", width: 50, onTap: () {
                controller.selectedBookingStatus.value = "Placed";
                controller.getBookingDataByBookingStatus();
              }),
              const SizedBox(width: 40),
              _buildStatusTab("Approved & Assigned".tr, "Approved & Assigned", activeStatus == "Approved & Assigned", width: 120, onTap: () {
                controller.selectedBookingStatus.value = "Approved & Assigned";
                controller.getBookingDataByBookingStatus();
              }),
              const SizedBox(width: 40),
              _buildStatusTab("Accepted".tr, "Accepted", activeStatus == "Accepted", width: 50, onTap: () {
                controller.selectedBookingStatus.value = "Accepted";
                controller.getBookingDataByBookingStatus();
              }),
              const SizedBox(width: 40),
              _buildStatusTab("Cancelled".tr, "Cancelled", activeStatus == "Cancelled", width: 50, onTap: () {
                controller.selectedBookingStatus.value = "Cancelled";
                controller.getBookingDataByBookingStatus();
              }),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildStatusTab(String label, String statusValue, bool isActive, {required double width, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppThemData.primary500 : Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: width,
            color: isActive ? AppThemData.primary500 : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
