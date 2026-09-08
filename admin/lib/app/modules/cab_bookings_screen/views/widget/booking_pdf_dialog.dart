import 'dart:developer';
import 'package:admin/app/components/custom_button.dart';
import 'package:admin/app/components/custom_text_form_field.dart';
import 'package:admin/app/components/dialog_box.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/models/driver_user_model.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/app/utils/toast.dart';
import 'package:admin/widget/common_ui.dart';
import 'package:admin/widget/container_custom.dart';
import 'package:admin/widget/global_widgets.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:admin/app/modules/cab_bookings_screen/controllers/cab_booking_controller.dart';

class BookingPdfDialog extends StatelessWidget {
  final CabBookingController controller;
  final DarkThemeProvider themeChange;

  const BookingPdfDialog({
    super.key,
    required this.controller,
    required this.themeChange,
  });

  static Future<void> showPdfDialog(BuildContext context, CabBookingController controller, DarkThemeProvider themeChange) async {
    controller.dateRangeController.value.text = "";
    await showDialog(
      context: context,
      builder: (context) => BookingPdfDialog(controller: controller, themeChange: themeChange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      controller: controller,
      title: "Cab History Download",
      widgetList: [
        const TextCustom(
          title: 'Select Time',
          fontFamily: AppThemeData.regular,
          fontSize: 16,
        ),
        spaceH(),
        SizedBox(
          width: 200,
          child: Obx(
            () => DropdownButtonFormField<String>(
              borderRadius: BorderRadius.circular(15),
              isExpanded: true,
              style: TextStyle(
                fontFamily: AppThemeData.medium,
                color: themeChange.isDarkTheme() ? AppThemData.textBlack : AppThemData.textGrey,
              ),
              onChanged: (String? statusType) {
                final now = DateTime.now();
                controller.selectedDateOption.value = statusType ?? "All";

                switch (statusType) {
                  case 'Last Month':
                    controller.selectedDateRangeForPdf.value = DateTimeRange(
                      start: now.subtract(const Duration(days: 30)),
                      end: DateTime(now.year, now.month, now.day, 23, 59, 0, 0),
                    );
                    break;
                  case 'Last 6 Months':
                    controller.selectedDateRangeForPdf.value = DateTimeRange(
                      start: DateTime(now.year, now.month - 6, now.day),
                      end: DateTime(now.year, now.month, now.day, 23, 59, 0, 0),
                    );
                    break;
                  case 'Last Year':
                    controller.selectedDateRangeForPdf.value = DateTimeRange(
                      start: DateTime(now.year - 1, now.month, now.day),
                      end: DateTime(now.year, now.month, now.day, 23, 59, 0, 0),
                    );
                    break;
                  case 'Custom':
                    controller.isCustomVisible.value = true;
                    break;
                  case 'All':
                  default:
                    controller.selectedDateRangeForPdf.value = DateTimeRange(
                      start: DateTime(now.year, 1, 1),
                      end: DateTime(now.year, now.month, now.day, 23, 59, 0, 0),
                    );
                    break;
                }

                controller.isCustomVisible.value = statusType == 'Custom';
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
                  ),
                );
              }).toList(),
              decoration: Constant.DefaultInputDecoration(context),
            ),
          ),
        ),
        spaceH(),
        Obx(
          () => Visibility(
            visible: controller.isCustomVisible.value,
            child: CustomTextFormField(
              validator: (value) => value != null && value.isNotEmpty ? null : 'Start & End Date Required'.tr,
              hintText: "Select Start & End Date",
              controller: controller.dateRangeController.value,
              title: "Start & End Date",
              onPress: () {
                _showDateRangePickerForPdf(context);
              },
              isReadOnly: true,
              suffix: const Icon(
                Icons.calendar_month_outlined,
                color: AppThemData.greyShade500,
                size: 24,
              ),
            ),
          ),
        ),
        spaceH(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextCustom(
              title: 'Select Driver',
              fontFamily: AppThemeData.regular,
              fontSize: 16,
            ),
            spaceH(),
            SizedBox(
              width: 250,
              child: DropdownSearch<DriverUserModel>(
                items: (filter, infiniteScrollProps) => controller.allDriverList,
                itemAsString: (DriverUserModel? driver) => driver?.fullName ?? "",
                compareFn: (item, selectedItem) => item.id == selectedItem.id,
                onChanged: (DriverUserModel? driver) {
                  controller.selectedDriver.value = driver;
                },
                dropdownBuilder: (context, DriverUserModel? driver) {
                  return Text(driver?.fullName ?? "All Driver");
                },
                popupProps: PopupProps.menu(
                    showSearchBox: true,
                    showSelectedItems: true,
                    searchFieldProps: TextFieldProps(
                        cursorColor: AppThemData.primary500,
                        decoration: InputDecoration(
                          fillColor: themeChange.isDarkTheme() ? AppThemData.greyShade950 : AppThemData.greyShade500,
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                          hintText: "Search Provider",
                          hintStyle: const TextStyle(fontSize: 14, fontFamily: AppThemeData.regular, color: AppThemData.lightGrey08),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(width: 0.5, color: AppThemData.appColor),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(width: 0.5, color: themeChange.isDarkTheme() ? AppThemData.greyShade950 : AppThemData.greyShade100),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(width: 0.5, color: AppThemData.red500),
                          ),
                        )),
                    itemBuilder: (context, item, isDisabled, isSelected) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          '${item.fullName}',
                          style: TextStyle(
                            fontFamily: AppThemeData.regular,
                            color: themeChange.isDarkTheme() ? AppThemData.greyShade500 : AppThemData.greyShade950,
                          ),
                        ),
                      );
                    }),
                decoratorProps: DropDownDecoratorProps(decoration: defaultInputDecorationForSearchDropDown(context)),
              ),
            ),
          ],
        ),
        spaceH(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextCustom(
              title: 'Booking Status',
              fontFamily: AppThemeData.regular,
              fontSize: 16,
            ),
            spaceH(),
            SizedBox(
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
                    controller.selectedFilterBookingStatus.value = statusType ?? "All";
                  },
                  value: controller.selectedFilterBookingStatus.value,
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
            ),
          ],
        ),
      ],
      bottomWidgetList: [
        CustomButtonWidget(
          buttonTitle: "Close",
          textColor: themeChange.isDarkTheme() ? Colors.white : Colors.black,
          buttonColor: themeChange.isDarkTheme() ? AppThemData.greyShade900 : AppThemData.greyShade100,
          onPress: () {
            Navigator.pop(context);
          },
        ),
        spaceW(),
        Obx(
          () => controller.isHistoryDownload.value
              ? Constant.loader()
              : CustomButtonWidget(
                  buttonTitle: "Download".tr,
                  onPress: () {
                    if (Constant.isDemo) {
                      DialogBox.demoDialogBox();
                    } else {
                      if (controller.selectedDriver.value == null ||
                          controller.selectedDriver.value!.id == null ||
                          controller.selectedDriver.value!.id!.isEmpty) {
                        ShowToast.errorToast('Select Driver');
                        return;
                      }
                      if (controller.selectedDateOption.value == 'Custom' && controller.dateRangeController.value.text.isEmpty) {
                        ShowToast.errorToast("Please select the start & end date.");
                        return;
                      }
                      controller.downloadCabBookingPdf(context);
                    }
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showDateRangePickerForPdf(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Ride Booking Date'),
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
                  log('--------------------==================> ${controller.startDateForPdf} and end data ${controller.endDateForPdf}');
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
