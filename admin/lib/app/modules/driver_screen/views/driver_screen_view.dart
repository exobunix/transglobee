import 'package:admin/app/components/custom_button.dart';
import 'package:admin/app/components/custom_text_form_field.dart';
import 'package:admin/app/components/dialog_box.dart';
import 'package:admin/app/components/menu_widget.dart';
import 'package:admin/app/components/network_image_widget.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/app/utils/fire_store_utils.dart';
import 'package:admin/app/utils/toast.dart';
import 'package:admin/widget/common_ui.dart';
import 'package:admin/widget/container_custom.dart';
import 'package:admin/widget/global_widgets.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:admin/widget/web_pagination.dart';
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:admin/app/constant/show_toast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../../routes/app_pages.dart';
import '../../../utils/responsive.dart';
import '../controllers/driver_screen_controller.dart';

class DriverScreenView extends GetView<DriverScreenController> {
  const DriverScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<DriverScreenController>(
      init: DriverScreenController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemData.greyShade950 : AppThemData.greyShade50,
          appBar: AppBar(
            elevation: 0.0,
            toolbarHeight: 70,
            automaticallyImplyLeading: false,
            backgroundColor: themeChange.isDarkTheme() ? AppThemData.primaryBlack : AppThemData.primaryWhite,
            leadingWidth: 260,
            // title: title,
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
                              color: themeChange.isDarkTheme() ? AppThemData.primary500 : AppThemData.primary500,
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
                  } else if (themeChange.darkTheme == 2) {
                    themeChange.darkTheme = 0;
                  } else {
                    themeChange.darkTheme = 2;
                  }
                },
                child: themeChange.isDarkTheme()
                    ? SvgPicture.asset(
                        "assets/icons/ic_sun.svg",
                        color: AppThemData.yellow600,
                        height: 20,
                        width: 20,
                      )
                    : SvgPicture.asset(
                        "assets/icons/ic_moon.svg",
                        color: AppThemData.blue400,
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
            // key: scaffoldKey,
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
                      child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ContainerCustom(
                          child: Column(children: [
                            ResponsiveWidget.isDesktop(context)
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        TextCustom(title: controller.title.value, fontSize: 20, fontFamily: AppThemeData.bold),
                                        spaceH(height: 2),
                                        Row(children: [
                                          GestureDetector(
                                              onTap: () => Get.offAllNamed(Routes.DASHBOARD_SCREEN),
                                              child: TextCustom(title: 'Dashboard'.tr, fontSize: 14, fontFamily: AppThemeData.medium, color: AppThemData.greyShade500)),
                                          const TextCustom(title: ' / ', fontSize: 14, fontFamily: AppThemeData.medium, color: AppThemData.greyShade500),
                                          TextCustom(title: ' ${controller.title.value} ', fontSize: 14, fontFamily: AppThemeData.medium, color: AppThemData.primary500)
                                        ])
                                      ]),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 120,
                                            child: Obx(
                                              () => DropdownButtonFormField(
                                                borderRadius: BorderRadius.circular(15),
                                                isExpanded: true,
                                                style: TextStyle(
                                                  fontFamily: AppThemeData.medium,
                                                  color: themeChange.isDarkTheme() ? AppThemData.textBlack : AppThemData.textGrey,
                                                ),
                                                onChanged: (String? searchType) {
                                                  controller.selectedSearchType.value = searchType ?? "Name";
                                                  controller.getSearchType();
                                                },
                                                value: controller.selectedSearchType.value,
                                                items: controller.searchType.map<DropdownMenuItem<String>>((String value) {
                                                  return DropdownMenuItem(
                                                    value: value,
                                                    child: TextCustom(
                                                      title: value,
                                                      fontFamily: AppThemeData.regular,
                                                      fontSize: 16,
                                                      color: themeChange.isDarkTheme() ? AppThemData.greyShade500 : AppThemData.greyShade800,
                                                    ),
                                                  );
                                                }).toList(),
                                                decoration: Constant.DefaultInputDecoration(context),
                                              ),
                                            ),
                                          ),
                                          spaceW(),
                                          SizedBox(
                                            height: 41,
                                            width: ResponsiveWidget.isDesktop(context) ? MediaQuery.of(context).size.width * 0.15 : 200,
                                            child: CustomTextFormField(
                                              bottom: 0,
                                              hintText: "Search here",
                                              controller: controller.searchController.value,
                                              onChanged: (value) {
                                                controller.setPagination(controller.totalItemPerPage.value);
                                              },
                                              onSubmit: (value) async {
                                                controller.setPagination(controller.totalItemPerPage.value);
                                              },
                                              suffix: IconButton(
                                                onPressed: () async {
                                                  if (controller.isSearchEnable.value) {
                                                    controller.setPagination(controller.totalItemPerPage.value);
                                                    controller.isSearchEnable.value = false;
                                                  } else {
                                                    controller.searchController.value.text = "";
                                                    controller.setPagination(controller.totalItemPerPage.value);
                                                    controller.isSearchEnable.value = true;
                                                  }
                                                },
                                                icon: Icon(
                                                  controller.isSearchEnable.value ? Icons.search : Icons.clear,
                                                ),
                                              ),
                                            ),
                                          ),
                                          spaceW(),
                                          NumberOfRowsDropDown(
                                            controller: controller,
                                          ),
                                          ContainerCustom(
                                              padding: paddingEdgeInsets(horizontal: 0, vertical: 0),
                                              color: AppThemData.primary500,
                                              child: IconButton(
                                                onPressed: () {
                                                  controller.dateRangeController.value.text = "";
                                                  showDialog(
                                                      context: context,
                                                      builder: (context) => CustomDialog(
                                                        controller: controller,
                                                        title: "Drivers Data Download",
                                                        widgetList: [
                                                          CustomTextFormField(
                                                            validator: (value) => value != null && value.isNotEmpty ? null : 'Start & End Date Required'.tr,
                                                            hintText: "Select Start & End Date",
                                                            controller: controller.dateRangeController.value,
                                                            title: "Start & End Date",
                                                            onPress: () {
                                                              showDateRangePickerForPdf(context);
                                                            },
                                                            isReadOnly: true,
                                                            suffix: const Icon(
                                                              Icons.calendar_month_outlined,
                                                              color: AppThemData.greyShade500,
                                                              size: 24,
                                                            ),
                                                          )
                                                        ],
                                                        bottomWidgetList: [
                                                          CustomButtonWidget(
                                                            buttonTitle: "Close",
                                                            textColor: themeChange.isDarkTheme() ? Colors.white : Colors.black,
                                                            buttonColor: themeChange.isDarkTheme()
                                                                ? AppThemData.greyShade900
                                                                : AppThemData.greyShade100,
                                                            onPress: () {
                                                              Navigator.pop(context);
                                                            },
                                                          ),
                                                          spaceW(),
                                                          CustomButtonWidget(
                                                            buttonTitle: "Download".tr,
                                                            onPress: () {
                                                              if (Constant.isDemo) {
                                                                DialogBox.demoDialogBox();
                                                              } else {
                                                                if(controller.dateRangeController.value.text.isNotEmpty){
                                                                  controller.downloadDriverDataPdf();
                                                                  Navigator.pop(context);
                                                                }else {
                                                                  ShowToast.successToast("Please Select the Date..");
                                                                }
                                                                // Add your download logic here
                                                              }
                                                            },
                                                          ),
                                                        ],
                                                      ));
                                                },
                                                icon: SvgPicture.asset(
                                                  "assets/icons/ic_downlod.svg",
                                                  color: AppThemData.primaryWhite,
                                                  height: 18,
                                                  width: 18,
                                                ),
                                              )),
                                          spaceW(),
                                          // ── ADD DRIVER BUTTON (Desktop) ──
                                          ElevatedButton.icon(
                                            onPressed: () => _showAddDriverDialog(context, controller),
                                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                                            label: Text('Add Driver'.tr),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppThemData.primary500,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        TextCustom(title: controller.title.value, fontSize: 20, fontFamily: AppThemeData.bold),
                                        spaceH(height: 2),
                                        Row(children: [
                                          GestureDetector(
                                              onTap: () => Get.offAllNamed(Routes.DASHBOARD_SCREEN),
                                              child: TextCustom(title: 'Dashboard'.tr, fontSize: 14, fontFamily: AppThemeData.medium, color: AppThemData.greyShade500)),
                                          const TextCustom(title: ' / ', fontSize: 14, fontFamily: AppThemeData.medium, color: AppThemData.greyShade500),
                                          TextCustom(title: ' ${controller.title.value} ', fontSize: 14, fontFamily: AppThemeData.medium, color: AppThemData.primary500)
                                        ])
                                      ]),
                                      spaceH(),
                                      SizedBox(
                                        width: MediaQuery.sizeOf(context).width *0.8,
                                        child: Obx(
                                          () => DropdownButtonFormField(
                                            borderRadius: BorderRadius.circular(15),
                                            isExpanded: true,
                                            style: TextStyle(
                                              fontFamily: AppThemeData.medium,
                                              color: themeChange.isDarkTheme() ? AppThemData.textBlack : AppThemData.textGrey,
                                            ),
                                            onChanged: (String? searchType) {
                                              controller.selectedSearchType.value = searchType ?? "Name";
                                              controller.getSearchType();
                                            },
                                            value: controller.selectedSearchType.value,
                                            items: controller.searchType.map<DropdownMenuItem<String>>((String value) {
                                              return DropdownMenuItem(
                                                value: value,
                                                child: TextCustom(
                                                  title: value,
                                                  fontFamily: AppThemeData.regular,
                                                  fontSize: 16,
                                                ),
                                              );
                                            }).toList(),
                                            decoration: Constant.DefaultInputDecoration(context),
                                          ),
                                        ),
                                      ),
                                      spaceH(),
                                      SizedBox(
                                        height: 50,
                                        width: MediaQuery.sizeOf(context).width *0.8,
                                        child: CustomTextFormField(
                                          bottom: 0,
                                          hintText: "Search here",
                                          controller: controller.searchController.value,
                                          onSubmit: (value) async {
                                            if (controller.isSearchEnable.value) {
                                              await FireStoreUtils.countSearchDrivers(
                                                  controller.searchController.value.text, controller.selectedSearchTypeForData.value);
                                              controller.setPagination(controller.totalItemPerPage.value);
                                              controller.isSearchEnable.value = false;
                                            } else {
                                              controller.searchController.value.text = "";
                                              controller.getUser();
                                              controller.isSearchEnable.value = true;
                                            }
                                            controller.setPagination(controller.totalItemPerPage.value);
                                          },
                                          suffix: IconButton(
                                            onPressed: () async {
                                              if (controller.isSearchEnable.value) {
                                                await FireStoreUtils.countSearchDrivers(
                                                    controller.searchController.value.text, controller.selectedSearchTypeForData.value);
                                                controller.setPagination(controller.totalItemPerPage.value);
                                                controller.isSearchEnable.value = false;
                                              } else {
                                                controller.searchController.value.text = "";
                                                controller.getUser();
                                                controller.isSearchEnable.value = true;
                                              }
                                            },
                                            icon: Icon(
                                              controller.isSearchEnable.value ? Icons.search : Icons.clear,
                                            ),
                                          ),
                                        ),
                                      ),
                                      spaceH(),
                                      Row(
                                        children: [
                                          NumberOfRowsDropDown(
                                            controller: controller,
                                          ),
                                          ContainerCustom(
                                              padding: paddingEdgeInsets(horizontal: 0, vertical: 0),
                                              color: AppThemData.primary500,
                                              child: IconButton(
                                                onPressed: () {
                                                  controller.dateRangeController.value.text = "";
                                                  showDialog(
                                                      context: context,
                                                      builder: (context) => CustomDialog(
                                                        controller: controller,
                                                        title: "Drivers Data Download",
                                                        widgetList: [
                                                          CustomTextFormField(
                                                            validator: (value) => value != null && value.isNotEmpty ? null : 'Start & End Date Required'.tr,
                                                            hintText: "Select Start & End Date",
                                                            controller: controller.dateRangeController.value,
                                                            title: "Start & End Date",
                                                            onPress: () {
                                                              showDateRangePickerForPdf(context);
                                                            },
                                                            isReadOnly: true,
                                                            suffix: const Icon(
                                                              Icons.calendar_month_outlined,
                                                              color: AppThemData.greyShade500,
                                                              size: 24,
                                                            ),
                                                          )
                                                        ],
                                                        bottomWidgetList: [
                                                          CustomButtonWidget(
                                                            buttonTitle: "Close",
                                                            textColor: themeChange.isDarkTheme() ? Colors.white : Colors.black,
                                                            buttonColor: themeChange.isDarkTheme()
                                                                ? AppThemData.greyShade900
                                                                : AppThemData.greyShade100,
                                                            onPress: () {
                                                              Navigator.pop(context);
                                                            },
                                                          ),
                                                          spaceW(),
                                                          CustomButtonWidget(
                                                            buttonTitle: "Download".tr,
                                                            onPress: () {
                                                              if (Constant.isDemo) {
                                                                DialogBox.demoDialogBox();
                                                              } else {
                                                                if(controller.dateRangeController.value.text.isNotEmpty){
                                                                  controller.downloadDriverDataPdf();
                                                                  Navigator.pop(context);
                                                                }else {
                                                                  ShowToast.successToast("Please Select the Date..");
                                                                }
                                                                // Add your download logic here
                                                              }
                                                            },
                                                          ),
                                                        ],
                                                      ));
                                                },
                                                icon: SvgPicture.asset(
                                                  "assets/icons/ic_downlod.svg",
                                                  color: AppThemData.primaryWhite,
                                                  height: 18,
                                                  width: 18,
                                                ),
                                              )),
                                          spaceW(),
                                          // ── ADD DRIVER BUTTON (Mobile) ──
                                          ElevatedButton.icon(
                                            onPressed: () => _showAddDriverDialog(context, controller),
                                            icon: const Icon(Icons.person_add_alt_1, size: 16),
                                            label: Text('Add'.tr),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppThemData.primary500,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                            spaceH(height: 20),
                            controller.isLoading.value
                                ? Padding(
                                    padding: paddingEdgeInsets(),
                                    child: Constant.loader(),
                                  )
                                : controller.currentPageDriver.isEmpty
                                    ? TextCustom(title: "No Data available".tr)
                                    : GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: ResponsiveWidget.isDesktop(context) ? 2 : 1,
                                          crossAxisSpacing: 20,
                                          mainAxisSpacing: 20,
                                          mainAxisExtent: 215,
                                        ),
                                        itemCount: controller.currentPageDriver.length,
                                        itemBuilder: (context, index) {
                                          final driverUserModel = controller.currentPageDriver[index];
                                          final String firstLetter = (driverUserModel.fullName != null && driverUserModel.fullName!.isNotEmpty)
                                              ? driverUserModel.fullName![0].toUpperCase()
                                              : "D";
                                          return Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: themeChange.isDarkTheme() ? AppThemData.greyShade900 : AppThemData.primaryWhite,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: themeChange.isDarkTheme() ? AppThemData.greyShade800 : AppThemData.greyShade200,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 28,
                                                      backgroundColor: Colors.pinkAccent,
                                                      backgroundImage: (driverUserModel.profilePic != null && driverUserModel.profilePic!.isNotEmpty)
                                                          ? NetworkImage(driverUserModel.profilePic!)
                                                          : null,
                                                      child: (driverUserModel.profilePic == null || driverUserModel.profilePic!.isEmpty)
                                                          ? Text(
                                                              firstLetter,
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 22,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            )
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 15),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            driverUserModel.fullName ?? "N/A",
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                              color: themeChange.isDarkTheme() ? Colors.white : Colors.black,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 5),
                                                          Text(
                                                            "${driverUserModel.email ?? 'N/A'} • ${Constant.maskMobileNumber(mobileNumber: driverUserModel.phoneNumber, countryCode: driverUserModel.countryCode)}",
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: themeChange.isDarkTheme() ? Colors.grey[400] : Colors.grey[600],
                                                            ),
                                                          ),
                                                          const SizedBox(height: 5),
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons.lock_outline,
                                                                size: 14,
                                                                color: themeChange.isDarkTheme() ? AppThemData.primary500 : Colors.deepOrange,
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                "Password: ",
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: themeChange.isDarkTheme() ? Colors.grey[400] : Colors.grey[700],
                                                                ),
                                                              ),
                                                              SelectableText(
                                                                driverUserModel.plainPassword != null && driverUserModel.plainPassword!.isNotEmpty
                                                                    ? driverUserModel.plainPassword!
                                                                    : "123456",
                                                                style: TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: themeChange.isDarkTheme() ? AppThemData.primary500 : Colors.deepOrange,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 6),
                                                              InkWell(
                                                                onTap: () {
                                                                  final pass = driverUserModel.plainPassword != null && driverUserModel.plainPassword!.isNotEmpty
                                                                      ? driverUserModel.plainPassword!
                                                                      : "123456";
                                                                  Clipboard.setData(ClipboardData(text: pass));
                                                                  ShowToastDialog.toast("Password copied: $pass");
                                                                },
                                                                child: Padding(
                                                                  padding: const EdgeInsets.all(2.0),
                                                                  child: Icon(
                                                                    Icons.copy,
                                                                    size: 13,
                                                                    color: themeChange.isDarkTheme() ? Colors.grey[400] : Colors.grey[600],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Spacer(),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        onPressed: () {
                                                          // Chat action
                                                        },
                                                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                                        label: Text("Chat".tr),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: AppThemData.primary500,
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: OutlinedButton.icon(
                                                        onPressed: () {
                                                          Get.toNamed('${Routes.DRIVER_DETAIL_SCREEN}/${driverUserModel.id}');
                                                        },
                                                        icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                                                        label: Text("View".tr),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: themeChange.isDarkTheme() ? Colors.white : Colors.black,
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                          side: BorderSide(
                                                            color: themeChange.isDarkTheme() ? AppThemData.greyShade800 : AppThemData.greyShade300,
                                                          ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    IconButton(
                                                      onPressed: () async {
                                                        if (Constant.isDemo) {
                                                          DialogBox.demoDialogBox();
                                                        } else {
                                                          bool confirmDelete = await DialogBox.showConfirmationDeleteDialog(context);
                                                          if (confirmDelete) {
                                                            await controller.removeDriver(driverUserModel);
                                                            controller.getUser();
                                                          }
                                                        }
                                                      },
                                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                                      style: IconButton.styleFrom(
                                                        backgroundColor: Colors.red.withOpacity(0.1),
                                                        padding: const EdgeInsets.all(12),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                            spaceH(),
                            ResponsiveWidget.isMobile(context)
                                ? SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Visibility(
                                      visible: controller.totalPage.value > 1,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: WebPagination(
                                                currentPage: controller.currentPage.value,
                                                totalPage: controller.totalPage.value,
                                                displayItemCount: controller.pageValue("5"),
                                                onPageChanged: (page) {
                                                  controller.currentPage.value = page;
                                                  controller.setPagination(controller.totalItemPerPage.value);
                                                }),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Visibility(
                                    visible: controller.totalPage.value > 1,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: WebPagination(
                                              currentPage: controller.currentPage.value,
                                              totalPage: controller.totalPage.value,
                                              displayItemCount: controller.pageValue("5"),
                                              onPageChanged: (page) {
                                                controller.currentPage.value = page;
                                                controller.setPagination(controller.totalItemPerPage.value);
                                              }),
                                        ),
                                      ],
                                    ),
                                  ),
                          ]),
                        )
                      ]),
                    )),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Premium Add Driver dialog — styled like driver_app's Step 1 registration.
  void _showAddDriverDialog(BuildContext context, DriverScreenController controller) {
    bool _obscurePass = true;
    bool _isLoading = false;
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              width: 480,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2D2D44), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppThemData.primary500.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.person_add_alt_1, color: AppThemData.primary500, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Add New Driver',
                                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Fill in the driver\'s basic details',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close, color: Colors.white54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Full Name
                        _addDriverField(
                          label: 'Full Name *',
                          hint: 'e.g. Ravi Kumar',
                          icon: Icons.person_outline,
                          controller: controller.addDriverNameController.value,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Name is required';
                            if (v.trim().length < 3) return 'Enter at least 3 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Mobile
                        _addDriverField(
                          label: 'Mobile Number *',
                          hint: 'e.g. 9876543210',
                          icon: Icons.phone_android,
                          controller: controller.addDriverMobileController.value,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Mobile number is required';
                            if (!RegExp(r'^[0-9]{10}$').hasMatch(v.trim())) return 'Enter a valid 10-digit number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email
                        _addDriverField(
                          label: 'Email Address *',
                          hint: 'e.g. driver@example.com',
                          icon: Icons.email_outlined,
                          controller: controller.addDriverEmailController.value,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(v.trim())) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        StatefulBuilder(
                          builder: (_, setStatePass) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password *',
                                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: controller.addDriverPasswordController.value,
                                obscureText: _obscurePass,
                                style: const TextStyle(color: Colors.white),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Password is required';
                                  if (v.length < 6) return 'Minimum 6 characters';
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: 'Minimum 6 characters',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                                  prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.5), size: 20),
                                  suffixIcon: IconButton(
                                    onPressed: () => setStatePass(() => _obscurePass = !_obscurePass),
                                    icon: Icon(
                                      _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.white.withOpacity(0.5),
                                      size: 20,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF16213E),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Colors.transparent),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFF2D2D44)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: AppThemData.primary500, width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Colors.redAccent),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // License Number (optional)
                        _addDriverField(
                          label: 'Driving License Number (optional)',
                          hint: 'e.g. DL-1420110012345',
                          icon: Icons.credit_card_outlined,
                          controller: controller.addDriverLicenseController.value,
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  foregroundColor: Colors.white54,
                                  side: const BorderSide(color: Color(0xFF2D2D44)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        if (!_formKey.currentState!.validate()) return;
                                        setState(() => _isLoading = true);
                                        final success = await controller.addDriver();
                                        setState(() => _isLoading = false);
                                        if (success && ctx.mounted) Navigator.pop(ctx);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppThemData.primary500,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text('Add Driver', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Reusable styled text field for the Add Driver dialog.
  Widget _addDriverField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
            filled: true,
            fillColor: const Color(0xFF16213E),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2D2D44)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppThemData.primary500, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> showDateRangePickerForPdf(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Date'),
          content: SizedBox(
            height: 300,
            width: 300,
            child: SfDateRangePicker(
              initialDisplayDate: DateTime.now(),
              maxDate: DateTime.now(),
              selectionMode: DateRangePickerSelectionMode.range,
              onSelectionChanged: (DateRangePickerSelectionChangedArgs args) async {
                if (args.value is PickerDateRange) {
                  controller.startDateForPdf = (args.value as PickerDateRange).startDate;
                  controller.endDateForPdf = (args.value as PickerDateRange).endDate;
                }
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
                onPressed: () {
                  controller.selectedDateRangeForPdf.value = DateTimeRange(
                      start: DateTime(DateTime.now().year, DateTime.january, 1),
                      end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 0, 0));
                  Navigator.of(context).pop();
                },
                child: const Text('clear')),
            TextButton(
              onPressed: () async {
                if (controller.startDateForPdf != null && controller.endDateForPdf != null) {
                  controller.selectedDateRangeForPdf.value = DateTimeRange(
                      start: controller.startDateForPdf!,
                      end: DateTime(controller.endDateForPdf!.year, controller.endDateForPdf!.month, controller.endDateForPdf!.day, 23, 59, 0, 0));
                  controller.dateRangeController.value.text =
                  "${DateFormat('dd/MM/yyyy').format(controller.selectedDateRangeForPdf.value.start)} to ${DateFormat('dd/MM/yyyy').format(controller.selectedDateRangeForPdf.value.end)}";
                }
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  WidgetBuilder horizontalDrawerBuilder() {
    return (BuildContext context) {
      final themeChange = Provider.of<DarkThemeProvider>(context);

      return GetX<DriverScreenController>(
          init: DriverScreenController(),
          builder: (taxController) {
            return Drawer(
              backgroundColor: themeChange.isDarkTheme() ? AppThemData.greyShade950 : AppThemData.greyShade50,
              width: 500,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(Icons.arrow_back_ios_new_outlined)),
                    ),
                  ),
                  Padding(
                    padding: paddingEdgeInsets(vertical: 24, horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            TextCustom(title: controller.title.value, fontSize: 20),
                          ],
                        ),
                        spaceH(height: 24),
                        SizedBox(
                          height: 1,
                          child: ContainerCustom(
                            color: themeChange.isDarkTheme() ? AppThemData.greyShade900 : AppThemData.greyShade100,
                          ),
                        ),
                        spaceH(height: 40),
                        controller.imagePath.value.path.isEmpty
                            ? SizedBox(
                                height: 100,
                                width: 100,
                                child: Stack(
                                  children: [
                                    NetworkImageWidget(
                                      borderRadius: 60,
                                      imageUrl: controller.imageController.value.text.toString(),
                                      height: 100,
                                      width: 100,
                                    ),
                                    Align(
                                      alignment: AlignmentDirectional.bottomEnd,
                                      child: InkWell(
                                        onTap: () {
                                          controller.pickPhoto();
                                        },
                                        child: Container(
                                            height: 30,
                                            width: 30,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle, color: themeChange.isDarkTheme() ? AppThemData.greyShade900 : AppThemData.greyShade100),
                                            child: const Icon(
                                              Icons.edit,
                                              size: 20,
                                            )),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : controller.uploading.value
                                ? Center(child: Constant.loader())
                                : SizedBox(
                                    height: 100,
                                    width: 100,
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(60),
                                          child: Image.memory(
                                            controller.imagePickedFileBytes.value,
                                            height: 100,
                                            width: 100,
                                          ),
                                        ),
                                        Align(
                                          alignment: AlignmentDirectional.bottomEnd,
                                          child: InkWell(
                                            onTap: () {
                                              controller.pickPhoto();
                                            },
                                            child: Container(
                                                height: 30,
                                                width: 30,
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle, color: themeChange.isDarkTheme() ? AppThemData.greyShade900 : AppThemData.greyShade100),
                                                child: const Icon(
                                                  Icons.edit,
                                                  size: 20,
                                                )),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                        spaceH(height: 40),
                        Column(
                          children: [
                            CustomTextFormField(
                              title: "First Name *".tr,
                              hintText: "Enter first name".tr,
                              controller: controller.userNameController.value,
                            ),
                            spaceH(height: 20),
                            CustomTextFormField(
                              isReadOnly: true,
                              title: "Phone Number *".tr,
                              hintText: "Enter phone number".tr,
                              controller: controller.phoneNumberController.value,
                            ),
                            const SizedBox(height: 20),
                            CustomTextFormField(
                              isReadOnly: true,
                              title: "Email Address *".tr,
                              hintText: "Enter email".tr,
                              controller: controller.emailController.value,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Row(
                          children: [
                            const Spacer(),
                            CustomButtonWidget(
                                buttonTitle: "Save".tr,
                                onPress: () async {
                                  if (Constant.isDemo) {
                                    DialogBox.demoDialogBox();
                                  } else {
                                    Constant.waitingLoader();
                                    if (controller.imagePath.value.path.isNotEmpty) {
                                      String? downloadUrl = await FireStoreUtils.uploadPic(
                                          PickedFile(controller.imagePath.value.path), "profileImage".tr, controller.editingId.value, controller.mimeType.value);
                                      controller.driverModel.value.profilePic = downloadUrl;
                                      log(downloadUrl.toString());
                                    }
                                    controller.driverModel.value.id = controller.editingId.value;
                                    controller.driverModel.value.fullName = controller.userNameController.value.text;
                                    bool isSaved = await FireStoreUtils.updateDriver(controller.driverModel.value);
                                    if (isSaved) {
                                      Get.back();
                                      ShowToast.successToast("Users data updated".tr);
                                    } else {
                                      ShowToast.errorToast("Something went wrong, Please try later!".tr);
                                      Get.back();
                                    }
                                  }
                                }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          });
    };
  }
}
