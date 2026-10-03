import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:admin/app/modules/cab_detail/controllers/cab_detail_controller.dart';

class ShuttleManagementCardView extends StatelessWidget {
  final CabDetailController controller;
  final DarkThemeProvider themeChange;

  const ShuttleManagementCardView({
    super.key,
    required this.controller,
    required this.themeChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = themeChange.isDarkTheme();
    final cardBg = isDark ? AppThemData.greyShade900 : AppThemData.primaryWhite;
    final borderColor = isDark ? AppThemData.greyShade800 : AppThemData.greyShade200;
    final fieldFill = isDark ? AppThemData.greyShade950 : AppThemData.greyShade50;

    return Obx(() {
      final booking = controller.bookingModel.value;
      final status = (booking.bookingStatus ?? 'pending').toLowerCase();
      final isPending = status == 'pending' || status == 'placed' || status == 'booking_placed';
      final isAccepted = status == 'confirmed' || status == 'accepted' || status == 'approved';
      final isDeclined = status == 'cancelled' || status == 'declined' || status == 'rejected';

      Color statusColor = Colors.orange;
      if (isAccepted) statusColor = Colors.green;
      if (isDeclined) statusColor = Colors.red;

      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppThemData.primary500.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.directions_bus, color: AppThemData.primary500, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextCustom(
                          title: "Shuttle Booking Request".tr,
                          fontSize: 16,
                          fontFamily: AppThemeData.bold,
                        ),
                        TextCustom(
                          title: "Booking ID: ${controller.bookingIdText}",
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Route details
            _buildDetailRow(Icons.my_location, "Pickup Location", controller.pickupText.value.isNotEmpty ? controller.pickupText.value : (booking.pickUpLocationAddress ?? '-')),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.location_on, "Dropoff Location", controller.dropText.value.isNotEmpty ? controller.dropText.value : (booking.dropLocationAddress ?? '-')),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.person_outline, "Passenger Details", controller.customerText.value),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.payments_outlined, "Fare", "₹${booking.finalRate ?? booking.subTotal ?? '0'}"),

            const SizedBox(height: 20),
            TextCustom(
              title: "Admin Notes & Instructions for User".tr,
              fontSize: 14,
              fontFamily: AppThemeData.semiBold,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.adminNotesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter notes for user (e.g. Pickup point near Gate 2, driver will arrive at 9:00 AM)...",
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                filled: true,
                fillColor: fieldFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.isUpdatingShuttle.value
                        ? null
                        : () => controller.updateShuttleStatus('confirmed'),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    label: Text(
                      isAccepted ? "Accepted (Update Notes)".tr : "ACCEPT REQUEST".tr,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.isUpdatingShuttle.value
                        ? null
                        : () => controller.updateShuttleStatus('declined'),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.white, size: 18),
                    label: Text(
                      "DECLINE REQUEST".tr,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
