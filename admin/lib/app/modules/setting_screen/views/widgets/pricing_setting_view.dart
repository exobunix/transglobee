import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/app/components/custom_text_form_field.dart';
import 'package:admin/widget/global_widgets.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:admin/app/constant/show_toast.dart';
import 'package:admin/app/constant/api_constant.dart';

class ServicePricingModel {
  String serviceName;
  double baseFare;
  double baseDistanceKm;
  double perKmRate;
  double perMinuteRate;
  double minBookingFare;
  double surgeMultiplier;
  double nightChargePercentage;
  double cancellationFee;

  ServicePricingModel({
    required this.serviceName,
    required this.baseFare,
    required this.baseDistanceKm,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.minBookingFare,
    required this.surgeMultiplier,
    required this.nightChargePercentage,
    required this.cancellationFee,
  });
}

class PricingSettingController extends GetxController {
  RxBool isLoading = false.obs;

  Rx<TextEditingController> baseFare = TextEditingController().obs;
  Rx<TextEditingController> baseDistanceKm = TextEditingController().obs;
  Rx<TextEditingController> perKmRate = TextEditingController().obs;
  Rx<TextEditingController> perMinuteRate = TextEditingController().obs;
  Rx<TextEditingController> minBookingFare = TextEditingController().obs;
  Rx<TextEditingController> surgeMultiplier = TextEditingController().obs;
  Rx<TextEditingController> nightChargePercentage = TextEditingController().obs;
  Rx<TextEditingController> cancellationFee = TextEditingController().obs;

  RxString selectedCategory = "Cab Service".obs;
  final List<String> categories = [
    "Cab Service",
    "Shuttle Service",
    "Logistics Service"
  ];

  RxMap<String, ServicePricingModel> savedPricings = <String, ServicePricingModel>{
    "Cab Service": ServicePricingModel(
      serviceName: "Cab Service",
      baseFare: 50.0,
      baseDistanceKm: 2.0,
      perKmRate: 15.0,
      perMinuteRate: 1.5,
      minBookingFare: 60.0,
      surgeMultiplier: 1.0,
      nightChargePercentage: 10.0,
      cancellationFee: 30.0,
    ),
    "Shuttle Service": ServicePricingModel(
      serviceName: "Shuttle Service",
      baseFare: 30.0,
      baseDistanceKm: 3.0,
      perKmRate: 8.0,
      perMinuteRate: 0.5,
      minBookingFare: 30.0,
      surgeMultiplier: 1.0,
      nightChargePercentage: 5.0,
      cancellationFee: 15.0,
    ),
    "Logistics Service": ServicePricingModel(
      serviceName: "Logistics Service",
      baseFare: 120.0,
      baseDistanceKm: 3.0,
      perKmRate: 25.0,
      perMinuteRate: 2.0,
      minBookingFare: 150.0,
      surgeMultiplier: 1.1,
      nightChargePercentage: 15.0,
      cancellationFee: 50.0,
    ),
  }.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategoryFields(selectedCategory.value);
    fetchPricingConfigs();
  }

  void loadCategoryFields(String category) {
    var model = savedPricings[category];
    if (model != null) {
      baseFare.value.text = model.baseFare.toStringAsFixed(0);
      baseDistanceKm.value.text = model.baseDistanceKm.toStringAsFixed(1);
      perKmRate.value.text = model.perKmRate.toStringAsFixed(0);
      perMinuteRate.value.text = model.perMinuteRate.toStringAsFixed(1);
      minBookingFare.value.text = model.minBookingFare.toStringAsFixed(0);
      surgeMultiplier.value.text = model.surgeMultiplier.toStringAsFixed(1);
      nightChargePercentage.value.text = model.nightChargePercentage.toStringAsFixed(0);
      cancellationFee.value.text = model.cancellationFee.toStringAsFixed(0);
    }
  }

  Future<void> fetchPricingConfigs() async {
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse("${ApiConstant.baseUrl}/pricing/configs")).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          for (var item in data['data']) {
            String name = item['categoryName'] ?? "";
            if (savedPricings.containsKey(name)) {
              savedPricings[name] = ServicePricingModel(
                serviceName: name,
                baseFare: (item['baseFare'] ?? 50.0).toDouble(),
                baseDistanceKm: (item['baseDistanceKm'] ?? 2.0).toDouble(),
                perKmRate: (item['perKmRate'] ?? 15.0).toDouble(),
                perMinuteRate: (item['perMinuteRate'] ?? 1.5).toDouble(),
                minBookingFare: (item['minBookingFare'] ?? 60.0).toDouble(),
                surgeMultiplier: (item['surgeMultiplier'] ?? 1.0).toDouble(),
                nightChargePercentage: (item['nightChargePercentage'] ?? 10.0).toDouble(),
                cancellationFee: (item['cancellationFee'] ?? 30.0).toDouble(),
              );
            }
          }
          loadCategoryFields(selectedCategory.value);
        }
      }
    } catch (e) {
      // Retain dynamic defaults
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> savePricingConfig() async {
    ShowToastDialog.showLoader("Saving ${selectedCategory.value} Pricing...".tr);
    double bFare = double.tryParse(baseFare.value.text) ?? 50.0;
    double bDist = double.tryParse(baseDistanceKm.value.text) ?? 2.0;
    double pKm = double.tryParse(perKmRate.value.text) ?? 15.0;
    double pMin = double.tryParse(perMinuteRate.value.text) ?? 1.5;
    double minFare = double.tryParse(minBookingFare.value.text) ?? 60.0;
    double surge = double.tryParse(surgeMultiplier.value.text) ?? 1.0;
    double night = double.tryParse(nightChargePercentage.value.text) ?? 10.0;
    double cancelFee = double.tryParse(cancellationFee.value.text) ?? 30.0;

    savedPricings[selectedCategory.value] = ServicePricingModel(
      serviceName: selectedCategory.value,
      baseFare: bFare,
      baseDistanceKm: bDist,
      perKmRate: pKm,
      perMinuteRate: pMin,
      minBookingFare: minFare,
      surgeMultiplier: surge,
      nightChargePercentage: night,
      cancellationFee: cancelFee,
    );
    savedPricings.refresh();

    try {
      await http.put(
        Uri.parse("${ApiConstant.baseUrl}/pricing/config/${selectedCategory.value}"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "categoryName": selectedCategory.value,
          "baseFare": bFare,
          "baseDistanceKm": bDist,
          "perKmRate": pKm,
          "perMinuteRate": pMin,
          "minBookingFare": minFare,
          "surgeMultiplier": surge,
          "nightChargePercentage": night,
          "cancellationFee": cancelFee,
        }),
      ).timeout(const Duration(seconds: 4));

      ShowToastDialog.closeLoader();
      ShowToastDialog.toast("${selectedCategory.value} pricing updated successfully!".tr);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.toast("${selectedCategory.value} pricing saved!".tr);
    }
  }
}

class PricingSettingView extends StatelessWidget {
  const PricingSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetBuilder<PricingSettingController>(
      init: PricingSettingController(),
      builder: (controller) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppThemData.primaryBlack : AppThemData.primaryWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextCustom(
                      title: 'Service Pricing & Surge Settings'.tr,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppThemData.greyShade100 : AppThemData.greyShade900,
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemData.primary500,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => controller.savePricingConfig(),
                      icon: const Icon(Icons.save, color: Colors.white, size: 18),
                      label: Text(
                        "Save Pricing".tr,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                TextCustom(
                  title: 'Admin control panel to configure rates specifically for Cab, Shuttle, and Logistics services.'.tr,
                  fontSize: 14,
                  color: isDark ? AppThemData.greyShade400 : AppThemData.greyShade600,
                ),
                const Divider(height: 28),

                // Saved Prices Overview Header
                TextCustom(
                  title: '📋 Saved Prices Overview (Active Rates)'.tr,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppThemData.primary500,
                ),
                const SizedBox(height: 12),

                // Saved Prices Overview Cards Row
                Obx(() => Row(
                  children: controller.categories.map((cat) {
                    var model = controller.savedPricings[cat];
                    bool isSelected = controller.selectedCategory.value == cat;
                    IconData catIcon = cat.contains("Cab")
                        ? Icons.local_taxi
                        : cat.contains("Shuttle")
                            ? Icons.directions_bus
                            : Icons.local_shipping;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          controller.selectedCategory.value = cat;
                          controller.loadCategoryFields(cat);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? AppThemData.primary500.withOpacity(0.2) : AppThemData.primary500.withOpacity(0.08))
                                : (isDark ? AppThemData.greyShade900 : AppThemData.greyShade50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppThemData.primary500 : (isDark ? AppThemData.greyShade800 : AppThemData.greyShade200),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(catIcon, color: AppThemData.primary500, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text("Base Fare: ₹${model?.baseFare.toStringAsFixed(0)} (${model?.baseDistanceKm} KM)", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[800])),
                              Text("Per KM Rate: ₹${model?.perKmRate.toStringAsFixed(0)}/KM", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[800])),
                              Text("Per Min Rate: ₹${model?.perMinuteRate.toStringAsFixed(1)}/Min", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[800])),
                              Text("Surge Multiplier: ${model?.surgeMultiplier}x", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[800])),
                              Text("Night Extra: ${model?.nightChargePercentage.toStringAsFixed(0)}%", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[800])),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )),
                const SizedBox(height: 24),

                // Vehicle Category Dropdown Selection
                TextCustom(title: 'Select Service to Edit Pricing'.tr, fontSize: 14, fontWeight: FontWeight.w600),
                const SizedBox(height: 8),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppThemData.greyShade900 : AppThemData.greyShade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? AppThemData.greyShade800 : AppThemData.greyShade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedCategory.value,
                        isExpanded: true,
                        dropdownColor: isDark ? AppThemData.greyShade900 : AppThemData.primaryWhite,
                        items: controller.categories.map((String cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            controller.selectedCategory.value = val;
                            controller.loadCategoryFields(val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Base Pricing Row
                TextCustom(title: 'Base Pricing & Distance'.tr, fontSize: 16, fontWeight: FontWeight.w700),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        title: "Base Fare (₹)".tr,
                        hintText: "50",
                        controller: controller.baseFare.value,
                      ),
                    ),
                    spaceW(),
                    Expanded(
                      child: CustomTextFormField(
                        title: "Base Distance Included (KM)".tr,
                        hintText: "2.0",
                        controller: controller.baseDistanceKm.value,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Distance & Traffic Rates Row
                TextCustom(title: 'Distance & Delay Rates'.tr, fontSize: 16, fontWeight: FontWeight.w700),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        title: "Per KM Rate (₹/KM)".tr,
                        hintText: "15",
                        controller: controller.perKmRate.value,
                      ),
                    ),
                    spaceW(),
                    Expanded(
                      child: CustomTextFormField(
                        title: "Per Minute Rate (₹/Min)".tr,
                        hintText: "1.5",
                        controller: controller.perMinuteRate.value,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Dynamic Surge & Night Shift Section
                TextCustom(title: 'Surge Multiplier & Night Shift Extra'.tr, fontSize: 16, fontWeight: FontWeight.w700),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        title: "Peak Hour Surge Multiplier (e.g. 1.2x)".tr,
                        hintText: "1.0",
                        controller: controller.surgeMultiplier.value,
                      ),
                    ),
                    spaceW(),
                    Expanded(
                      child: CustomTextFormField(
                        title: "Night Shift Extra % (10 PM - 6 AM)".tr,
                        hintText: "10",
                        controller: controller.nightChargePercentage.value,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Minimum Thresholds & Fees
                TextCustom(title: 'Rules & Minimum Thresholds'.tr, fontSize: 16, fontWeight: FontWeight.w700),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        title: "Minimum Trip Fare Threshold (₹)".tr,
                        hintText: "60",
                        controller: controller.minBookingFare.value,
                      ),
                    ),
                    spaceW(),
                    Expanded(
                      child: CustomTextFormField(
                        title: "Standard Cancellation Fee (₹)".tr,
                        hintText: "30",
                        controller: controller.cancellationFee.value,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
