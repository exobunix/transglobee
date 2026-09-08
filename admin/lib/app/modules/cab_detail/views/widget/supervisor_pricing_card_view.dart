import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/widget/container_custom.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:admin/app/modules/cab_detail/controllers/cab_detail_controller.dart';

class SupervisorPricingCardView extends StatelessWidget {
  final CabDetailController controller;
  final DarkThemeProvider themeChange;

  const SupervisorPricingCardView({
    super.key,
    required this.controller,
    required this.themeChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = themeChange.isDarkTheme();
    final cardBgColor = isDark ? AppThemData.greyShade900 : AppThemData.primaryWhite;
    final borderColor = isDark ? AppThemData.greyShade800 : AppThemData.greyShade100;
    final textStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black,
      fontSize: 14,
    );

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
                  Icon(Icons.currency_rupee, color: AppThemData.primary500),
                  const SizedBox(width: 8),
                  TextCustom(title: "Pricing Override".tr, fontSize: 16, fontFamily: AppThemeData.bold),
                ],
              ),
              const SizedBox(height: 20),
              _buildPricingInput("Vehicle/Transport Price", controller.vehiclePriceController),
              _buildPricingInput("Helper Cost", controller.helperCostController),
              _buildPricingInput("Toll Charges", controller.tollChargesController),
              _buildPricingInput("Night Charges", controller.nightChargesController),
              _buildPricingInput("Handling Charges", controller.handlingChargesController),
              _buildPricingInput("Discount", controller.discountController),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total:".tr, style: textStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                  Obx(() => Text(
                    "₹${controller.totalPrice.value}",
                    style: textStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 18, color: AppThemData.primary500),
                  )),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => controller.savePricingOverride(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemData.primary500,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text("Save Pricing Details".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingInput(String label, TextEditingController fieldController) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: fieldController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => controller.recalculateTotal(),
        decoration: InputDecoration(
          labelText: label.tr,
          prefixText: "₹ ",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}
