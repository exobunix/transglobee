import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:nb_utils/nb_utils.dart';

import 'package:admin/app/components/menu_widget.dart';
import 'package:admin/widget/container_custom.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:admin/widget/common_ui.dart';
import 'package:admin/widget/global_widgets.dart';
import 'package:admin/widget/web_pagination.dart';
import 'package:admin/app/components/custom_button.dart';
import 'package:admin/app/components/custom_text_form_field.dart';
import 'package:admin/app/routes/app_pages.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/app/utils/responsive.dart';
import 'package:admin/app/constant/constants.dart';

import '../controllers/vehicle_screen_controller.dart';
import '../../../models/admin_vehicle_model.dart';
import '../../../models/driver_user_model.dart';

class VehicleScreenView extends GetView<VehicleScreenController> {
  const VehicleScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder<VehicleScreenController>(
      init: VehicleScreenController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemData.greyShade950 : AppThemData.greyShade50,
          appBar: AppBar(
            elevation: 0.0,
            toolbarHeight: 70,
            automaticallyImplyLeading: false,
            backgroundColor: themeChange.isDarkTheme() ? AppThemData.primaryBlack : AppThemData.primaryWhite,
            leadingWidth: 260,
            leading: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    if (!ResponsiveWidget.isDesktop(context)) {
                      Scaffold.of(context).openDrawer();
                    }
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: !ResponsiveWidget.isDesktop(context)
                        ? Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Icon(
                              Icons.menu,
                              size: 30,
                              color: AppThemData.primary500,
                            ),
                          )
                        : SizedBox(
                            height: 45,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/image/logo.png",
                                  height: 45,
                                  color: AppThemData.primary500,
                                ),
                                spaceW(),
                                const TextCustom(
                                  title: 'Transglobe',
                                  color: AppThemData.primary500,
                                  fontSize: 30,
                                  fontFamily: AppThemeData.semiBold,
                                  fontWeight: FontWeight.w700,
                                )
                              ],
                            ),
                          ),
                  ),
                );
              },
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  if (themeChange.darkTheme == 1) {
                    themeChange.darkTheme = 0;
                  } else if (themeChange.darkTheme == 0) {
                    themeChange.darkTheme = 1;
                  }
                },
                child: themeChange.isDarkTheme()
                    ? SvgPicture.asset(
                        "assets/icons/ic_sun.svg",
                        colorFilter: const ColorFilter.mode(AppThemData.yellow600, BlendMode.srcIn),
                        height: 20,
                        width: 20,
                      )
                    : SvgPicture.asset(
                        "assets/icons/ic_moon.svg",
                        colorFilter: const ColorFilter.mode(AppThemData.blue400, BlendMode.srcIn),
                        height: 20,
                        width: 20,
                      ),
              ),
              spaceW(),
              const LanguagePopUp(),
              spaceW(),
              ProfilePopUp()
            ],
          ),
          drawer: Drawer(
            width: 270,
            backgroundColor: themeChange.isDarkTheme() ? AppThemData.primaryBlack : AppThemData.primaryWhite,
            child: const MenuWidget(),
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ResponsiveWidget.isDesktop(context)) ...{const MenuWidget()},
              Expanded(
                child: Padding(
                  padding: paddingEdgeInsets(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ContainerCustom(
                          child: Column(
                            children: [
                              ResponsiveWidget.isDesktop(context)
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          const TextCustom(title: "Active Fleet Vehicles", fontSize: 20, fontFamily: AppThemeData.bold),
                                          spaceH(height: 2),
                                          Row(children: [
                                            GestureDetector(onTap: () => Get.offAllNamed(Routes.DASHBOARD_SCREEN), child: TextCustom(title: 'Dashboard'.tr, fontSize: 14, fontFamily: AppThemeData.medium, color: AppThemData.greyShade500)),
                                            const TextCustom(title: ' / ', fontSize: 14, fontFamily: AppThemeData.medium, color: AppThemData.greyShade500),
                                            TextCustom(title: ' Vehicles ', fontSize: 14, fontFamily: AppThemeData.medium, color: AppThemData.primary500)
                                          ])
                                        ]),
                                        CustomButtonWidget(
                                          padding: const EdgeInsets.symmetric(horizontal: 22),
                                          buttonTitle: "+ Add Vehicle".tr,
                                          borderRadius: 10,
                                          onPress: () {
                                            controller.clearForm();
                                            showDialog(
                                              context: context,
                                              builder: (context) => const VehicleAddEditDialog(),
                                            );
                                          },
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          const TextCustom(title: "Active Fleet Vehicles", fontSize: 20, fontFamily: AppThemeData.bold),
                                          spaceH(height: 2),
                                          Row(children: [
                                            GestureDetector(onTap: () => Get.offAllNamed(Routes.DASHBOARD_SCREEN), child: TextCustom(title: 'Dashboard'.tr, fontSize: 14, fontFamily: AppThemeData.medium, color: AppThemData.greyShade500)),
                                            const TextCustom(title: ' / ', fontSize: 14, fontFamily: AppThemeData.medium, color: AppThemData.greyShade500),
                                            TextCustom(title: ' Vehicles ', fontSize: 14, fontFamily: AppThemeData.medium, color: AppThemData.primary500)
                                          ])
                                        ]),
                                        spaceH(),
                                        CustomButtonWidget(
                                          width: MediaQuery.sizeOf(context).width * 0.7,
                                          buttonTitle: "+ Add Vehicle".tr,
                                          borderRadius: 10,
                                          onPress: () {
                                            controller.clearForm();
                                            showDialog(
                                              context: context,
                                              builder: (context) => const VehicleAddEditDialog(),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                              spaceH(height: 20),
                              Center(
                                child: TextCustom(
                                  title: "Transglobe Fleet".tr,
                                  fontSize: 24,
                                  fontFamily: AppThemeData.bold,
                                  color: themeChange.isDarkTheme() ? Colors.white : Colors.black87,
                                ),
                              ),
                              spaceH(height: 16),
                              
                              Obx(
                                () => Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: themeChange.isDarkTheme() ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: ['All', 'Cars', 'Trucks', 'Buses'].map((tab) {
                                      final isSelected = controller.selectedTab.value == tab;
                                      return GestureDetector(
                                        onTap: () {
                                          controller.selectedTab.value = tab;
                                          controller.filterVehicles();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: isSelected ? AppThemData.primary500 : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          child: TextCustom(
                                            title: tab.tr,
                                            fontSize: 16,
                                            fontFamily: isSelected ? AppThemeData.bold : AppThemeData.medium,
                                            color: isSelected
                                                ? AppThemData.primary500
                                                : (themeChange.isDarkTheme() ? Colors.grey[400] : Colors.grey[600]),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              spaceH(height: 20),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildFilterDropdown(
                                    label: "Status",
                                    themeChange: themeChange,
                                    onChanged: (val) {},
                                  ),
                                  const SizedBox(width: 12),
                                  _buildFilterDropdown(
                                    label: "Insurance",
                                    themeChange: themeChange,
                                    onChanged: (val) {},
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.withOpacity(0.5)),
                                    ),
                                    child: const TextCustom(
                                      title: "Needs Inspection",
                                      fontSize: 14,
                                      fontFamily: AppThemeData.medium,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              spaceH(height: 24),

                              Obx(
                                () => controller.isLoading.value
                                    ? Padding(
                                        padding: paddingEdgeInsets(),
                                        child: Constant.loader(),
                                      )
                                    : controller.currentPageVehicles.isEmpty
                                        ? const Center(child: TextCustom(title: "No Vehicles available"))
                                        : LayoutBuilder(
                                            builder: (context, constraints) {
                                              int crossAxisCount = constraints.maxWidth > 900 ? 2 : 1;
                                              return GridView.builder(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: crossAxisCount,
                                                  crossAxisSpacing: 20,
                                                  mainAxisSpacing: 20,
                                                  mainAxisExtent: 200,
                                                ),
                                                itemCount: controller.currentPageVehicles.length,
                                                itemBuilder: (context, index) {
                                                  final vehicle = controller.currentPageVehicles[index];
                                                  return _buildVehicleCard(vehicle, themeChange, context);
                                                },
                                              );
                                            },
                                          ),
                              ),
                              spaceH(height: 20),
                              Obx(
                                () => controller.vehicleList.isEmpty
                                    ? const SizedBox()
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              TextCustom(title: 'Show'.tr, fontSize: 14, fontFamily: AppThemeData.medium),
                                              spaceW(),
                                              DropdownButton(
                                                value: controller.totalItemPerPage.value,
                                                items: Constant.numOfPageIemList.map((value) {
                                                  return DropdownMenuItem(value: value, child: TextCustom(title: value, fontFamily: AppThemeData.regular, fontSize: 16));
                                                }).toList(),
                                                onChanged: (value) {
                                                  controller.currentPage.value = 1;
                                                  controller.setPagination(value.toString());
                                                },
                                              ),
                                              spaceW(),
                                              TextCustom(title: 'Entries'.tr, fontSize: 14, fontFamily: AppThemeData.medium),
                                            ],
                                          ),
                                          WebPagination(
                                            currentPage: controller.currentPage.value,
                                            totalPage: controller.totalPage.value,
                                            displayItemCount: controller.pageValue(controller.totalItemPerPage.value),
                                            onPageChanged: (page) {
                                              controller.currentPage.value = page;
                                              controller.setPagination(controller.totalItemPerPage.value);
                                            },
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleCard(AdminVehicleModel vehicle, DarkThemeProvider themeChange, BuildContext context) {
    final typeText = "Type: ${(vehicle.vehicleType ?? 'car').toUpperCase()}";
    final String expiryText = vehicle.status == 'maintenance' ? "INSPECTION DUE SOON" : " ";
    final bool isDueSoon = vehicle.status == 'maintenance';
    
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => VehicleDetailsDialog(vehicle: vehicle),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: themeChange.isDarkTheme() ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDueSoon ? Colors.amber : (themeChange.isDarkTheme() ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isDueSoon ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: themeChange.isDarkTheme() ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        child: vehicle.vehicleImage != null && vehicle.vehicleImage!.isNotEmpty
                            ? Image.network(
                                vehicle.vehicleImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, e, s) => Image.asset(
                                  "assets/image/logo.png",
                                  color: AppThemData.primary500,
                                ),
                              )
                            : Image.asset(
                                "assets/image/logo.png",
                                color: AppThemData.primary500,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextCustom(
                            title: vehicle.vehicleName ?? 'N/A',
                            fontSize: 18,
                            fontFamily: AppThemeData.bold,
                            color: themeChange.isDarkTheme() ? Colors.white : Colors.black87,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: themeChange.isDarkTheme() ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: TextCustom(
                                  title: vehicle.numberPlate ?? 'N/A',
                                  fontSize: 12,
                                  fontFamily: AppThemeData.medium,
                                  color: themeChange.isDarkTheme() ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 10),
                              TextCustom(
                                  title: typeText,
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontFamily: AppThemeData.regular,
                                ),
                            ],
                          ),
                          if (vehicle.routes != null && vehicle.routes!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.navigation_outlined, size: 14, color: AppThemData.primary500),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: TextCustom(
                                    title: "${vehicle.routes!.first.name ?? ''} (${vehicle.routes!.first.source ?? ''} -> ${vehicle.routes!.first.destination ?? ''})",
                                    fontSize: 12,
                                    color: AppThemData.primary500,
                                    fontFamily: AppThemeData.medium,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Divider(height: 1, color: Color(0xFF334155)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextCustom(
                          title: "INSURANCE EXPIRY",
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontFamily: AppThemeData.bold,
                        ),
                        const SizedBox(height: 4),
                        TextCustom(
                          title: expiryText,
                          fontSize: 13,
                          fontFamily: AppThemeData.bold,
                          color: isDueSoon 
                              ? Colors.amber 
                              : (themeChange.isDarkTheme() ? Colors.white : Colors.black87),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextCustom(
                          title: isDueSoon ? "STATUS ACTION" : "PLATE NUMBER",
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontFamily: AppThemeData.bold,
                        ),
                        const SizedBox(height: 4),
                        TextCustom(
                          title: isDueSoon ? (vehicle.status ?? 'ACTIVE').toUpperCase() : (vehicle.numberPlate ?? 'N/A'),
                          fontSize: 13,
                          fontFamily: AppThemeData.bold,
                          color: isDueSoon 
                              ? Colors.amber 
                              : (themeChange.isDarkTheme() ? Colors.white : Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDueSoon)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.black),
                  ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert, color: themeChange.isDarkTheme() ? Colors.white : Colors.black87),
                  onSelected: (val) {
                    if (val == 'edit') {
                      controller.fillForm(vehicle);
                      showDialog(
                        context: context,
                        builder: (context) => const VehicleAddEditDialog(),
                      );
                    } else if (val == 'delete') {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Delete Vehicle".tr),
                          content: Text("Are you sure you want to delete this vehicle?".tr),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Cancel".tr),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () {
                                Navigator.pop(context);
                                controller.deleteVehicle(vehicle.id!);
                              },
                              child: Text("Delete".tr, style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text("Edit".tr)),
                    PopupMenuItem(value: 'delete', child: Text("Delete".tr)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),);
  }

  Widget _buildFilterDropdown({required String label, required DarkThemeProvider themeChange, required void Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 40,
      decoration: BoxDecoration(
        color: themeChange.isDarkTheme() ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: themeChange.isDarkTheme() ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: label,
          icon: Icon(Icons.keyboard_arrow_down, color: themeChange.isDarkTheme() ? Colors.white : Colors.black87, size: 18),
          style: TextStyle(
            color: themeChange.isDarkTheme() ? Colors.white : Colors.black87,
            fontFamily: AppThemeData.medium,
            fontSize: 14,
          ),
          dropdownColor: themeChange.isDarkTheme() ? const Color(0xFF1E293B) : Colors.white,
          items: [
            DropdownMenuItem(value: label, child: Text(label.tr)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class VehicleAddEditDialog extends StatelessWidget {
  const VehicleAddEditDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final controller = Get.find<VehicleScreenController>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: themeChange.isDarkTheme() ? AppThemData.greyShade900 : AppThemData.primaryWhite,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextCustom(
                      title: controller.isEditing.value ? "Edit Vehicle".tr : "Add New Vehicle".tr,
                      fontSize: 18,
                      fontFamily: AppThemeData.bold,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                // Form Fields
                CustomTextFormField(
                  title: "Vehicle Name".tr,
                  hintText: "Enter vehicle name (e.g. Swift VXI)".tr,
                  controller: controller.nameController,
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        title: "Brand".tr,
                        hintText: "e.g. Suzuki".tr,
                        controller: controller.brandController,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextFormField(
                        title: "Model".tr,
                        hintText: "e.g. Swift".tr,
                        controller: controller.modelController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        title: "Year".tr,
                        hintText: "e.g. 2023".tr,
                        controller: controller.yearController,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextFormField(
                        title: "Number Plate".tr,
                        hintText: "e.g. MH-12-AB-1234".tr,
                        controller: controller.numberPlateController,
                        validator: (val) => val == null || val.isEmpty ? "Required" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Vehicle Type Dropdown
                TextCustom(title: "Vehicle Category Type".tr, fontSize: 14, fontFamily: AppThemeData.medium),
                const SizedBox(height: 8),
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedVehicleType.value,
                    decoration: Constant.DefaultInputDecoration(context),
                    items: const [
                      DropdownMenuItem(value: 'car', child: Text("Car")),
                      DropdownMenuItem(value: 'bus', child: Text("Bus")),
                      DropdownMenuItem(value: 'truck', child: Text("Truck")),
                    ],
                    onChanged: (val) {
                      if (val != null) controller.selectedVehicleType.value = val;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Capacity Fields
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        title: "Passenger Capacity".tr,
                        hintText: "e.g. 4".tr,
                        controller: controller.passengerCapacityController,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextFormField(
                        title: "Luggage Capacity".tr,
                        hintText: "e.g. 2".tr,
                        controller: controller.luggageCapacityController,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextFormField(
                        title: "Truck Load Capacity (tonnes)".tr,
                        hintText: "e.g. 5".tr,
                        controller: controller.truckLoadCapacityController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Driver Assignment Dropdown
                TextCustom(title: "Assign Driver".tr, fontSize: 14, fontFamily: AppThemeData.medium),
                const SizedBox(height: 8),
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedDriverId.value.isEmpty ? null : controller.selectedDriverId.value,
                    decoration: Constant.DefaultInputDecoration(context),
                    hint: Text("Select Driver".tr),
                    items: [
                      DropdownMenuItem(value: "", child: Text("None".tr)),
                      ...controller.driverList.map((driver) {
                        return DropdownMenuItem(
                          value: driver.id ?? '',
                          child: Text(driver.fullName ?? 'Unknown Driver'),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      controller.selectedDriverId.value = val ?? '';
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Assign Routes Checklist
                TextCustom(title: "Assign Routes".tr, fontSize: 14, fontFamily: AppThemeData.medium),
                const SizedBox(height: 8),
                Obx(
                  () => Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: themeChange.isDarkTheme() ? AppThemData.greyShade700 : AppThemData.greyShade300,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: controller.dbRoutesList.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: TextCustom(title: "No Routes Available".tr, fontSize: 13),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: controller.dbRoutesList.length,
                            itemBuilder: (context, index) {
                              final route = controller.dbRoutesList[index];
                              final isChecked = controller.selectedRouteIds.contains(route.id);
                              return CheckboxListTile(
                                title: TextCustom(
                                  title: "${route.name ?? ''} (${route.source ?? ''} -> ${route.destination ?? ''})",
                                  fontSize: 13,
                                ),
                                value: isChecked,
                                activeColor: AppThemData.primary500,
                                onChanged: (val) {
                                  if (val == true) {
                                    controller.selectedRouteIds.add(route.id!);
                                  } else {
                                    controller.selectedRouteIds.remove(route.id!);
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Vehicle Status Dropdown
                TextCustom(title: "Status".tr, fontSize: 14, fontFamily: AppThemeData.medium),
                const SizedBox(height: 8),
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedStatus.value,
                    decoration: Constant.DefaultInputDecoration(context),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text("Active")),
                      DropdownMenuItem(value: 'inactive', child: Text("Inactive")),
                      DropdownMenuItem(value: 'maintenance', child: Text("Maintenance")),
                    ],
                    onChanged: (val) {
                      if (val != null) controller.selectedStatus.value = val;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                 // Vehicle Image Picker
                TextCustom(title: "Vehicle Image".tr, fontSize: 14, fontFamily: AppThemeData.medium),
                const SizedBox(height: 8),
                Obx(
                  () => InkWell(
                    onTap: () {
                      controller.pickImage();
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: themeChange.isDarkTheme() ? AppThemData.greyShade800 : AppThemData.greyShade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeChange.isDarkTheme() ? AppThemData.greyShade700 : AppThemData.greyShade300,
                        ),
                      ),
                      child: controller.selectedImageFile.value != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.file(
                                controller.selectedImageFile.value!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : controller.imageController.text.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.network(
                                    controller.imageController.text,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (c, e, s) => Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.cloud_upload_outlined, size: 30),
                                          const SizedBox(height: 8),
                                          Text("Click to upload vehicle photo".tr),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.cloud_upload_outlined, size: 30),
                                      const SizedBox(height: 8),
                                      Text("Click to upload vehicle photo".tr),
                                    ],
                                  ),
                                ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Close".tr),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemData.primary500,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        if (controller.isEditing.value) {
                          controller.editVehicle();
                        } else {
                          controller.addVehicle();
                        }
                      },
                      child: Text(
                        controller.isEditing.value ? "Save".tr : "Add".tr,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VehicleDetailsDialog extends StatelessWidget {
  final AdminVehicleModel vehicle;
  const VehicleDetailsDialog({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: themeChange.isDarkTheme() ? AppThemData.greyShade900 : AppThemData.primaryWhite,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextCustom(
                    title: "Vehicle Details".tr,
                    fontSize: 18,
                    fontFamily: AppThemeData.bold,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              if (vehicle.vehicleImage != null && vehicle.vehicleImage!.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      vehicle.vehicleImage!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const SizedBox(),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _buildDetailRow(context, "Vehicle Name".tr, vehicle.vehicleName ?? 'N/A'),
              _buildDetailRow(context, "Number Plate".tr, vehicle.numberPlate ?? 'N/A'),
              _buildDetailRow(context, "Vehicle Type".tr, (vehicle.vehicleType ?? 'N/A').toUpperCase()),
              _buildDetailRow(context, "Brand / Model".tr, "${vehicle.brand ?? 'N/A'} / ${vehicle.model ?? 'N/A'}"),
              _buildDetailRow(context, "Year".tr, vehicle.year ?? 'N/A'),
              _buildDetailRow(context, "Passenger Capacity".tr, "${vehicle.passengerCapacity ?? 0}"),
              _buildDetailRow(context, "Luggage Capacity".tr, "${vehicle.luggageCapacity ?? 0}"),
              _buildDetailRow(context, "Truck Load Capacity".tr, "${vehicle.truckLoadCapacity ?? 0.0} tonnes"),
              _buildDetailRow(context, "Assigned Driver".tr, vehicle.driverName ?? 'Unassigned'),
              _buildDetailRow(context, "Status".tr, (vehicle.status ?? 'active').toUpperCase()),
              if (vehicle.routes != null && vehicle.routes!.isNotEmpty)
                _buildDetailRow(
                  context,
                  "Assigned Routes".tr,
                  vehicle.routes!.map((r) => "${r.name ?? ''} (${r.source ?? ''} -> ${r.destination ?? ''})").join("\n"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextCustom(
              title: label,
              fontFamily: AppThemeData.bold,
              fontSize: 14,
            ),
          ),
          Expanded(
            flex: 3,
            child: TextCustom(
              title: value,
              fontFamily: AppThemeData.regular,
              fontSize: 14,
              maxLine: 5,
            ),
          ),
        ],
      ),
    );
  }
}
