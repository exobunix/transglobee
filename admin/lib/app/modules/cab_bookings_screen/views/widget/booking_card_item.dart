import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/models/booking_model.dart';
import 'package:admin/app/models/user_model.dart';
import 'package:admin/app/routes/app_pages.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/app/utils/fire_store_utils.dart';
import 'package:admin/widget/global_widgets.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookingCardItem extends StatelessWidget {
  final BookingModel bookingModel;
  final DarkThemeProvider themeChange;

  const BookingCardItem({
    super.key,
    required this.bookingModel,
    required this.themeChange,
  });

  @override
  Widget build(BuildContext context) {
    final statusLower = (bookingModel.bookingStatus ?? '').toLowerCase();
    final isCancelled = statusLower == 'cancelled' || statusLower == 'booking_cancelled';
    final isCompleted = statusLower == 'completed' || statusLower == 'booking_completed';
    final hasSegmentsOrDriver = (bookingModel.segments != null && bookingModel.segments!.isNotEmpty) || (bookingModel.driverId != null && bookingModel.driverId!.isNotEmpty);
    final isAssigned = hasSegmentsOrDriver && !isCancelled;
    final isAccepted = !isAssigned && (statusLower == 'accepted' || statusLower == 'booking_accepted' || statusLower == 'confirmed' || statusLower == 'approved');

    return GestureDetector(
      onTap: () {
        Get.toNamed('${Routes.CAB_DETAIL}/${bookingModel.id}');
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: themeChange.isDarkTheme() ? AppThemData.greyShade800 : AppThemData.greyShade100,
            width: 1,
          ),
        ),
        elevation: 0,
        color: themeChange.isDarkTheme() ? AppThemData.greyShade900 : AppThemData.primaryWhite,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextCustom(
                    title: "BOOKING ID #${bookingModel.id?.toUpperCase() ?? ''}",
                    fontSize: 16,
                    fontFamily: AppThemeData.bold,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? Colors.red.shade50
                          : isCompleted
                              ? Colors.green.shade50
                              : isAssigned
                                  ? Colors.purple.shade50
                                  : isAccepted
                                      ? Colors.blue.shade50
                                      : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isCancelled
                          ? "CANCELLED"
                          : isCompleted
                              ? "COMPLETED"
                              : isAssigned
                                  ? "APPROVED & ASSIGNED"
                                  : isAccepted
                                      ? "ACCEPTED"
                                      : "PENDING",
                      style: TextStyle(
                        color: isCancelled
                            ? Colors.red
                            : isCompleted
                                ? Colors.green
                                : isAssigned
                                    ? Colors.purple
                                    : isAccepted
                                        ? Colors.blue
                                        : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              spaceH(height: 8),
              FutureBuilder<UserModel?>(
                future: FireStoreUtils.getUserByUserID(bookingModel.customerId.toString()),
                builder: (context, snapshot) {
                  String name = "aman";
                  if (snapshot.hasData && snapshot.data != null) {
                    name = snapshot.data!.fullName ?? "aman";
                  }
                  return TextCustom(
                    title: name,
                    fontSize: 15,
                    fontFamily: AppThemeData.semiBold,
                  );
                },
              ),
              spaceH(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.radio_button_checked, color: Colors.green, size: 16),
                      Container(
                        width: 2,
                        height: 35,
                        color: Colors.grey.shade300,
                      ),
                      const Icon(Icons.location_on, color: Colors.red, size: 16),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookingModel.pickUpLocationAddress ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          bookingModel.dropLocationAddress ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              spaceH(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: themeChange.isDarkTheme() ? AppThemData.greyShade800 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.payment, size: 14, color: AppThemData.primary500),
                            const SizedBox(width: 4),
                            Text(
                              bookingModel.paymentType ?? 'N/A',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppThemData.primary500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Constant.amountShow(amount: bookingModel.subTotal.toString()),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppThemData.primary500),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: themeChange.isDarkTheme() ? AppThemData.greyShade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          bookingModel.createAt == null
                              ? ''
                              : "${Constant.timestampToDate(bookingModel.createAt!)}, ${Constant.timestampToTime(bookingModel.createAt!)}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
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
}
