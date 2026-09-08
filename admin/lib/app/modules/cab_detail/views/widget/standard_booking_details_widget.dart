import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/extension/date_time_extension.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/widget/text_widget.dart';
import '../../controllers/cab_detail_controller.dart';

class StandardBookingDetailsWidget extends StatelessWidget {
  final CabDetailController controller;
  final DarkThemeProvider themeChange;

  const StandardBookingDetailsWidget({
    super.key,
    required this.controller,
    required this.themeChange,
  });

  @override
  Widget build(BuildContext context) {
    final booking = controller.bookingModel.value;

    return Container(
      decoration: BoxDecoration(
        color: themeChange.isDarkTheme() ? AppThemData.greyShade950 : AppThemData.greyShade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID & Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  title: "Order ID # ${controller.bookingIdText}",
                  fontSize: 18,
                  fontFamily: AppThemeData.bold,
                ),
                const SizedBox(height: 2),
                TextCustom(
                  title: "${Constant.timestampToDate(controller.createAtTime)} at ${Constant.timestampToTime(controller.createAtTime)}",
                  fontSize: 14,
                  fontFamily: AppThemeData.medium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Constant.bookingStatusText(context, booking.bookingStatus.toString()),
            const SizedBox(height: 30),

            // Customer Details
            TextCustom(
              title: "Customer Details".tr,
              fontSize: 16,
              fontFamily: AppThemeData.bold,
            ),
            const SizedBox(height: 16),
            _rowDataWidget(
              name: "Name",
              value: controller.userModel.value.fullName.toString(),
            ),
            _rowDataWidget(
              name: "Phone No.",
              value: Constant.maskMobileNumber(
                mobileNumber: controller.userModel.value.phoneNumber.toString(),
                countryCode: controller.userModel.value.countryCode.toString(),
              ),
            ),
            const SizedBox(height: 24),

            // Driver Details
            if (controller.driverModel.value.id != null) ...[
              TextCustom(
                title: "Driver Details".tr,
                fontSize: 16,
                fontFamily: AppThemeData.bold,
              ),
              const SizedBox(height: 16),
              _rowDataWidget(
                name: "ID",
                value: "# ${controller.driverModel.value.id.toString().substring(0, 6)}",
              ),
              _rowDataWidget(
                name: "Name",
                value: controller.driverModel.value.fullName.toString(),
              ),
              _rowDataWidget(
                name: "Phone No.",
                value: Constant.maskMobileNumber(
                  mobileNumber: controller.driverModel.value.phoneNumber.toString(),
                  countryCode: controller.driverModel.value.countryCode.toString(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Cancelled Reason
            if (booking.cancelledReason != null && booking.cancelledReason.toString().isNotEmpty) ...[
              TextCustom(
                title: "Cancelled Reason".tr,
                fontSize: 16,
                fontFamily: AppThemeData.bold,
              ),
              const SizedBox(height: 8),
              TextCustom(title: booking.cancelledReason.toString()),
              const SizedBox(height: 20),
            ],

            // Payment Method
            TextCustom(
              title: "Payment Method".tr,
              fontSize: 16,
              fontFamily: AppThemeData.bold,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildPaymentIcon(booking.paymentType),
                const SizedBox(width: 8),
                TextCustom(
                  title: "${booking.paymentType}",
                  fontSize: 14,
                  fontFamily: AppThemeData.regular,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Ride Details
            TextCustom(
              title: "Ride Details".tr,
              fontSize: 16,
              fontFamily: AppThemeData.bold,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SvgPicture.asset(
                  "assets/icons/ic_calendar.svg",
                  width: 18, height: 18,
                  color: themeChange.isDarkTheme() ? AppThemData.primaryWhite : AppThemData.primaryBlack,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _rowDataWidget(
                    name: "Date",
                    value: booking.bookingTime == null
                        ? ""
                        : controller.bookingTimeVal.toDate().dateMonthYear(),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                SvgPicture.asset(
                  "assets/icons/ic_time.svg",
                  width: 18, height: 18,
                  color: themeChange.isDarkTheme() ? AppThemData.primaryWhite : AppThemData.primaryBlack,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _rowDataWidget(
                    name: "Time",
                    value: booking.bookingTime == null
                        ? ""
                        : controller.bookingTimeVal.toDate().time(),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                SvgPicture.asset(
                  "assets/icons/ic_distance.svg",
                  width: 18, height: 18,
                  color: themeChange.isDarkTheme() ? AppThemData.primaryWhite : AppThemData.primaryBlack,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _rowDataWidget(
                    name: "Distance",
                    value: "${controller.distanceText} ${booking.distance?.distanceType ?? ''}",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowDataWidget({required String name, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: TextCustom(title: name.tr, fontSize: 14, fontFamily: AppThemeData.medium),
          ),
          const TextCustom(title: ":   ", fontSize: 14, fontFamily: AppThemeData.medium),
          Expanded(
            flex: 1,
            child: TextCustom(
              title: value,
              fontSize: 14,
              fontFamily: AppThemeData.regular,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentIcon(String? paymentType) {
    if (paymentType == "Cash") {
      return SvgPicture.asset("assets/icons/ic_cash.svg");
    } else if (paymentType == "Wallet") {
      return SvgPicture.asset(
        "assets/icons/ic_wallet.svg",
        height: 24,
        color: themeChange.isDarkTheme() ? AppThemData.lightGrey08 : AppThemData.black08,
      );
    } else if (paymentType == "Razorpay") {
      return Image.asset("assets/image/ig_razorpay.png", height: 24, width: 24);
    } else if (paymentType == "Paypal") {
      return Image.asset("assets/image/ig_paypal.png", height: 24, width: 24);
    } else if (paymentType == "Strip") {
      return Image.asset("assets/image/ig_stripe.png", height: 24, width: 24);
    } else if (paymentType == "PayStack") {
      return Image.asset("assets/image/ig_paystack.png", height: 24, width: 24);
    } else if (paymentType == "Mercado Pago") {
      return Image.asset("assets/image/ig_marcadopago.png", height: 24, width: 24);
    } else if (paymentType == "payfast") {
      return Image.asset("assets/image/ig_payfast.png", height: 24, width: 24);
    } else if (paymentType == "Flutter Wave") {
      return Image.asset("assets/image/ig_flutterwave.png", height: 24, width: 24);
    }
    return SvgPicture.asset("assets/icons/ic_cash.svg");
  }
}
