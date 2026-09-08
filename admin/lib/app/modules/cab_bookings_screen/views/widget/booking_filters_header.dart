import 'dart:developer';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/models/driver_user_model.dart';
import 'package:admin/app/routes/app_pages.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/app/utils/fire_store_utils.dart';
import 'package:admin/widget/common_ui.dart';
import 'package:admin/widget/container_custom.dart';
import 'package:admin/widget/global_widgets.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:admin/app/utils/responsive.dart';
import 'package:admin/app/modules/cab_bookings_screen/controllers/cab_booking_controller.dart';
import 'booking_pdf_dialog.dart';

class BookingFiltersHeader extends StatelessWidget {
  final CabBookingController controller;
  final DarkThemeProvider themeChange;

  const BookingFiltersHeader({
    super.key,
    required this.controller,
    required this.themeChange,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveWidget.isDesktop(context)) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextCustom(title: controller.title.value.tr, fontSize: 20, fontFamily: AppThemeData.bold),
            spaceH(height: 2),
            Row(children: [
              GestureDetector(
                  onTap: () => Get.offAllNamed(Routes.DASHBOARD_SCREEN),
                  child: TextCustom(
                      title: 'Dashboard'.tr,
                      fontSize: 14,
                      fontFamily: AppThemeData.medium,
                      color: AppThemData.greyShade500)),
              const TextCustom(title: ' / ', fontSize: 14, fontFamily: AppThemeData.medium, color: AppThemData.greyShade500),
              TextCustom(
                  title: ' ${controller.title.value.tr} ',
                  fontSize: 14,
                  fontFamily: AppThemeData.medium,
                  color: AppThemData.primary500)
            ])
          ]),
          Row(
            children: [
              _buildDriverDropdown(context),
              spaceW(),
              _buildDateOptionDropdown(context),
              spaceW(),
              _buildStatusDropdown(context),
              spaceW(),
              NumberOfRowsDropDown(controller: controller),
              spaceW(),
              _buildPdfDownloadButton(context),
            ],
          )
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextCustom(title: controller.title.value.tr, fontSize: 20, fontFamily: AppThemeData.bold),
          spaceH(height: 2),
          Row(children: [
            GestureDetector(
                onTap: () => Get.offAllNamed(Routes.DASHBOARD_SCREEN),
                child: TextCustom(
                    title: 'Dashboard'.tr,
                    fontSize: 14,
                    fontFamily: AppThemeData.medium,
                    color: AppThemData.greyShade500)),
            const TextCustom(title: ' / ', fontSize: 14, fontFamily: AppThemeData.medium, color: AppThemData.greyShade500),
            TextCustom(
                title: ' ${controller.title.value.tr} ',
                fontSize: 14,
                fontFamily: AppThemeData.medium,
                color: AppThemData.primary500)
          ]),
          spaceH(),
          _buildDriverDropdown(context),
          spaceH(),
          Row(
            children: [
              _buildDateOptionDropdown(context),
              spaceW(),
              _buildStatusDropdown(context),
            ],
          ),
          spaceH(),
          Row(
            children: [
              NumberOfRowsDropDown(controller: controller),
              spaceW(),
              _buildPdfDownloadButton(context),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildDriverDropdown(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 160,
        child: DropdownSearch<DriverUserModel>(
          items: (f, cs) => controller.allDriverList,
          itemAsString: (DriverUserModel item) => '${item.fullName}',
          compareFn: (item, selectedItem) => item.id == selectedItem.id,
          onChanged: (DriverUserModel? selectedItem) async {
            controller.driverId.value = selectedItem!.id!;
            if (selectedItem.id == 'All') {
              log('===========> call all ');
              controller.driverId.value = 'All';
              await FireStoreUtils.countStatusWiseBooking(
                'All',
                controller.selectedBookingStatusForData.value,
                controller.selectedDateRange.value,
              );
              await controller.setPagination(controller.totalItemPerPage.value);
            } else {
              await FireStoreUtils.countStatusWiseBooking(
                controller.driverId.value,
                controller.selectedBookingStatusForData.value,
                controller.selectedDateRange.value,
              );
              await controller.setPagination(controller.totalItemPerPage.value);
            }
          },
          dropdownBuilder: (context, selectedItem) {
            return Text(
              selectedItem != null ? '${selectedItem.fullName}' : 'All Driver',
              style: TextStyle(
                fontFamily: AppThemeData.regular,
                fontSize: 16,
                color: themeChange.isDarkTheme() ? AppThemData.greyShade500 : AppThemData.greyShade800,
              ),
            );
          },
          popupProps: PopupProps.menu(
              showSearchBox: true,
              showSelectedItems: true,
              searchFieldProps: TextFieldProps(
                  cursorColor: AppThemData.appColor,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    hintText: "Search Driver",
                    hintStyle: TextStyle(
                      fontFamily: AppThemeData.regular,
                      fontSize: 16,
                      color: themeChange.isDarkTheme() ? AppThemData.greyShade500 : AppThemData.greyShade800,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        width: 0.5,
                        color: themeChange.isDarkTheme() ? AppThemData.greyShade950 : AppThemData.greyShade100,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        width: 0.5,
                        color: themeChange.isDarkTheme() ? AppThemData.greyShade950 : AppThemData.greyShade100,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(width: 0.5, color: AppThemData.red400),
                    ),
                  )),
              itemBuilder: (context, item, isDisabled, isSelected) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: TextCustom(
                    title: item.fullName.toString(),
                    fontFamily: AppThemeData.regular,
                    fontSize: 16,
                    color: themeChange.isDarkTheme() ? AppThemData.greyShade500 : AppThemData.greyShade800,
                  ),
                );
              }),
          suffixProps: const DropdownSuffixProps(
              dropdownButtonProps: DropdownButtonProps(
            iconClosed: Icon(
              Icons.arrow_drop_down,
              color: AppThemData.greyShade500,
            ),
            iconOpened: Icon(
              Icons.arrow_drop_up,
              color: AppThemData.greyShade500,
            ),
          )),
          decoratorProps: DropDownDecoratorProps(decoration: defaultInputDecorationForSearchDropDown(context)),
        ),
      ),
    );
  }

  Widget _buildDateOptionDropdown(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Obx(
        () => DropdownButtonFormField<String>(
          borderRadius: BorderRadius.circular(15),
          isExpanded: true,
          style: TextStyle(
            fontFamily: AppThemeData.medium,
            color: themeChange.isDarkTheme() ? AppThemData.textBlack : AppThemData.textGrey,
          ),
          onChanged: (String? statusType) async {
            final now = DateTime.now();
            controller.selectedDateOption.value = statusType ?? "All";
            switch (statusType) {
              case 'Last Month':
                controller.selectedDateRange.value = DateTimeRange(
                  start: now.subtract(const Duration(days: 30)),
                  end: DateTime(now.year, now.month, now.day, 23, 59, 0, 0),
                );
                await FireStoreUtils.countStatusWiseBooking(
                  controller.driverId.value,
                  controller.selectedBookingStatusForData.value,
                  controller.selectedDateRange.value,
                );
                await controller.setPagination(controller.totalItemPerPage.value);
                break;
              case 'Last 6 Months':
                controller.selectedDateRange.value = DateTimeRange(
                  start: DateTime(now.year, now.month - 6, now.day),
                  end: DateTime(now.year, now.month, now.day, 23, 59, 0, 0),
                );
                await FireStoreUtils.countStatusWiseBooking(
                  controller.driverId.value,
                  controller.selectedBookingStatusForData.value,
                  controller.selectedDateRange.value,
                );
                await controller.setPagination(controller.totalItemPerPage.value);
                break;
              case 'Last Year':
                controller.selectedDateRange.value = DateTimeRange(
                  start: DateTime(now.year - 1, now.month, now.day),
                  end: DateTime(now.year, now.month, now.day, 23, 59, 0, 0),
                );
                await FireStoreUtils.countStatusWiseBooking(
                  controller.driverId.value,
                  controller.selectedBookingStatusForData.value,
                  controller.selectedDateRange.value,
                );
                await controller.setPagination(controller.totalItemPerPage.value);
                break;
              case 'Custom':
                showDateRangePicker(context);
                break;
              case 'All':
              default:
                controller.selectedDateRange.value = DateTimeRange(
                  start: DateTime(now.year, 1, 1),
                  end: DateTime(now.year, now.month, now.day, 23, 59, 0, 0),
                );
                break;
            }
          },
          value: controller.selectedDateOption.value,
          items: controller.dateOption.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem(
                value: value,
                child: TextCustom(
                  title: value,
                  fontFamily: AppThemeData.regular,
                  fontSize: 16,
                  color: themeChange.isDarkTheme() ? AppThemData.greyShade500 : AppThemData.greyShade800,
                ));
          }).toList(),
          decoration: Constant.DefaultInputDecoration(context),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Obx(
        () => DropdownButtonFormField<String>(
          borderRadius: BorderRadius.circular(15),
          isExpanded: true,
          style: TextStyle(
            fontFamily: AppThemeData.medium,
            color: themeChange.isDarkTheme() ? AppThemData.textBlack : AppThemData.textGrey,
          ),
          onChanged: (String? statusType) {
            controller.selectedBookingStatus.value = statusType ?? "All";
            controller.getBookingDataByBookingStatus();
          },
          value: controller.selectedBookingStatus.value,
          items: controller.bookingStatus.map<DropdownMenuItem<String>>((String value) {
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
    );
  }

  Widget _buildPdfDownloadButton(BuildContext context) {
    return ContainerCustom(
      padding: paddingEdgeInsets(horizontal: 0, vertical: 0),
      color: AppThemData.primary500,
      child: IconButton(
        onPressed: () {
          BookingPdfDialog.showPdfDialog(context, controller, themeChange);
        },
        icon: Icon(
          Icons.picture_as_pdf,
          color: AppThemData.primaryWhite,
        ),
      ),
    );
  }

  Future<void> showDateRangePicker(BuildContext context) async {
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
                  controller.startDate = (args.value as PickerDateRange).startDate;
                  controller.endDate = (args.value as PickerDateRange).endDate;
                }
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
                onPressed: () {
                  controller.selectedDateRange.value = DateTimeRange(
                      start: DateTime(DateTime.now().year, DateTime.january, 1),
                      end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 0, 0));
                  controller.selectedBookingStatus.value = "All";
                  controller.getBookingDataByBookingStatus();
                  Navigator.of(context).pop();
                },
                child: const Text('clear')),
            TextButton(
              onPressed: () async {
                if (controller.startDate != null && controller.endDate != null) {
                  controller.selectedDateRange.value = DateTimeRange(
                      start: controller.startDate!,
                      end: DateTime(controller.endDate!.year, controller.endDate!.month, controller.endDate!.day, 23, 59, 0, 0));
                  await FireStoreUtils.countStatusWiseBooking(
                    controller.driverId.value,
                    controller.selectedBookingStatusForData.value,
                    controller.selectedDateRange.value,
                  );
                  await controller.setPagination(controller.totalItemPerPage.value);
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
}
