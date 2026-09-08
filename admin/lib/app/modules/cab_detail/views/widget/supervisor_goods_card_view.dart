import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/widget/container_custom.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:admin/app/modules/cab_detail/controllers/cab_detail_controller.dart';

class SupervisorGoodsCardView extends StatelessWidget {
  final CabDetailController controller;
  final DarkThemeProvider themeChange;

  const SupervisorGoodsCardView({
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
                  Icon(Icons.widgets_outlined, color: AppThemData.primary500),
                  const SizedBox(width: 8),
                  TextCustom(title: "Edit Goods Details".tr, fontSize: 16, fontFamily: AppThemeData.bold),
                ],
              ),
              const SizedBox(height: 20),
              TextCustom(title: "Transport Mode".tr, fontSize: 14, fontFamily: AppThemeData.medium),
              const SizedBox(height: 8),
              Obx(() {
                final mode = controller.transportMode.value;
                final items = ["Train", "Truck", "Flight", "Shuttle"];
                final selectedValue = items.contains(mode) ? mode : items.first;
                return DropdownButtonFormField<String>(
                  value: selectedValue,
                  dropdownColor: cardBgColor,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: items.map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(m, style: textStyle),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      controller.transportMode.value = val;
                    }
                  },
                );
              }),
              const SizedBox(height: 20),
              TextCustom(title: "Number of Helpers".tr, fontSize: 14, fontFamily: AppThemeData.medium),
              const SizedBox(height: 8),
              Obx(() => Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (controller.helperCount.value > 0) {
                        controller.helperCount.value--;
                        controller.recalculateTotal();
                      }
                    },
                    icon: Icon(Icons.remove_circle_outline, color: AppThemData.primary500),
                  ),
                  Text(
                    "${controller.helperCount.value}",
                    style: textStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.helperCount.value++;
                      controller.recalculateTotal();
                    },
                    icon: Icon(Icons.add_circle_outline, color: AppThemData.primary500),
                  ),
                ],
              )),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => controller.saveGoodsDetails(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemData.primary500,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text("Save Goods Details".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
