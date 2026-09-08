import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/models/tax_model.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/widget/text_widget.dart';
import '../../controllers/cab_detail_controller.dart';
import 'price_row_view.dart';

class StandardPricingDetailsWidget extends StatelessWidget {
  final CabDetailController controller;
  final DarkThemeProvider themeChange;

  const StandardPricingDetailsWidget({
    super.key,
    required this.controller,
    required this.themeChange,
  });

  @override
  Widget build(BuildContext context) {
    final booking = controller.bookingModel.value;
    final isDark = themeChange.isDarkTheme();

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 12),
      decoration: ShapeDecoration(
        color: isDark ? AppThemData.greyShade900 : AppThemData.greyShade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cab Vehicle Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: ShapeDecoration(
                color: isDark ? AppThemData.greyShade950 : AppThemData.greyShade25,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: isDark ? AppThemData.greyShade800 : AppThemData.greyShade100,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextCustom(
                    title: "Cab Details".tr,
                    fontSize: 16,
                    fontFamily: AppThemeData.bold,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        height: 60,
                        width: 80,
                        child: CachedNetworkImage(
                          imageUrl: booking.vehicleType == null
                              ? Constant.userPlaceHolder
                              : controller.vehicleImage,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Constant.loader(),
                          errorWidget: (context, url, error) => Image.asset(
                            Constant.userPlaceHolder,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextCustom(
                          title: booking.vehicleType == null ? "" : controller.vehicleTitle,
                          fontSize: 16,
                          fontFamily: AppThemeData.medium,
                        ),
                      ),
                      Row(
                        children: [
                          SvgPicture.asset("assets/icons/ic_multi_person.svg"),
                          const SizedBox(width: 6),
                          TextCustom(
                            title: booking.vehicleType == null ? "" : controller.vehiclePersons,
                            fontSize: 16,
                            fontFamily: AppThemeData.regular,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Base Amount
            PriceRowView(
              price: booking.subTotal.toString(),
              title: "Amount".tr,
              priceColor: isDark ? AppThemData.greyShade25 : AppThemData.greyShade950,
              titleColor: isDark ? AppThemData.greyShade25 : AppThemData.greyShade950,
            ),
            const SizedBox(height: 16),

            // Discount
            PriceRowView(
              price: Constant.amountToShow(amount: booking.discount ?? '0.0'),
              title: (booking.coupon?.code ?? '').isEmpty
                  ? "Discount".tr
                  : "Discount (${booking.coupon?.code ?? ""})".tr,
              priceColor: isDark ? AppThemData.greyShade25 : AppThemData.greyShade950,
              titleColor: isDark ? AppThemData.greyShade25 : AppThemData.greyShade950,
            ),
            const SizedBox(height: 16),

            // Tax List
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.taxListLength,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                TaxModel taxModel = (booking.taxList ?? [])[index];
                return Column(
                  children: [
                    PriceRowView(
                      price: Constant.amountToShow(
                        amount: Constant.calculateTax(
                          amount: Constant.amountBeforeTax(booking).toString(),
                          taxModel: taxModel,
                        ).toString(),
                      ),
                      title: "${taxModel.name!} (${taxModel.isFix == true ? Constant.amountToShow(amount: taxModel.value) : "${taxModel.value}%"})",
                      priceColor: isDark ? AppThemData.greyShade25 : AppThemData.greyShade950,
                      titleColor: isDark ? AppThemData.greyShade25 : AppThemData.greyShade950,
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Divider(color: isDark ? AppThemData.greyShade800 : AppThemData.greyShade100),
            const SizedBox(height: 12),

            // Final Total
            PriceRowView(
              price: Constant.amountShow(
                amount: Constant.calculateFinalAmount(booking).toString(),
              ),
              title: "Total Amount".tr,
              priceColor: AppThemData.primary500,
              titleColor: isDark ? AppThemData.greyShade25 : AppThemData.greyShade950,
            ),
          ],
        ),
      ),
    );
  }
}
