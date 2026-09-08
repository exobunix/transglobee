import 'package:admin/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/app/modules/cab_bookings_screen/controllers/cab_booking_controller.dart';

class BookingTypeTabs extends StatelessWidget {
  final CabBookingController controller;
  const BookingTypeTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedType = controller.selectedBookingType.value;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTypeTab("Cab", "cab", selectedType),
          const SizedBox(width: 40),
          _buildTypeTab("Shuttle", "bus", selectedType),
          const SizedBox(width: 40),
          _buildTypeTab("Logistics", "truck", selectedType),
        ],
      );
    });
  }

  Widget _buildTypeTab(String label, String typeKey, String selectedType) {
    final isSelected = selectedType == typeKey;
    return GestureDetector(
      onTap: () => controller.changeBookingType(typeKey),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppThemData.primary500 : Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 50,
            color: isSelected ? AppThemData.primary500 : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
