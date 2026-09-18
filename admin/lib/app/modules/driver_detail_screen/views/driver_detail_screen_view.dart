import 'package:admin/app/components/custom_button.dart';
import 'package:admin/app/components/custom_text_form_field.dart';
import 'package:admin/app/components/dialog_box.dart';
import 'package:admin/app/components/menu_widget.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/extension/date_time_extension.dart';
import 'package:admin/app/models/user_model.dart';
import 'package:admin/app/models/wallet_transaction_model.dart';
import 'package:admin/app/routes/app_pages.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/app/utils/fire_store_utils.dart';
import 'package:admin/app/utils/responsive.dart';
import 'package:admin/widget/common_ui.dart';
import 'package:admin/widget/container_custom.dart';
import 'package:admin/widget/global_widgets.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:admin/widget/web_pagination.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart';

import '../controllers/driver_detail_screen_controller.dart';
import 'package:intl/intl.dart';

class DriverDetailScreenView extends StatelessWidget {
  const DriverDetailScreenView({super.key});
  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<DriverDetailScreenController>(
      init: DriverDetailScreenController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemData.greyShade950 : AppThemData.greyShade50,
          // appBar: CommonUI.appBarCustom(themeChange: themeChange, scaffoldKey: controller.scaffoldKey),
          // drawer: CommonUI.drawerCustom(scaffoldKey: controller.scaffoldKey, themeChange: themeChange),
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
            width: 270,
            backgroundColor: themeChange.isDarkTheme() ? AppThemData.primaryBlack : AppThemData.primaryWhite,
            child: const MenuWidget(),
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ResponsiveWidget.isDesktop(context)) ...{const MenuWidget()},
              Expanded(
                  child: controller.isLoading.value
                      ? Padding(
                          padding: paddingEdgeInsets(),
                          child: Constant.loader(),
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: paddingEdgeInsets(horizontal: 24, vertical: 24),
                                  child: ContainerCustom(
                                    child: Column(children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            TextCustom(title: controller.title.value, fontSize: 20, fontFamily: AppThemeData.bold),
                                            spaceH(height: 2),
                                            Row(children: [
                                              GestureDetector(
                                                  onTap: () => Get.offAllNamed(Routes.DASHBOARD_SCREEN),
                                                  child: TextCustom(
                                                      title: 'Dashboard'.tr,
                                                      fontSize: 14,
                                                      fontFamily: AppThemeData.medium,
                                                      color: AppThemData.greyShade500)),
                                              const TextCustom(
                                                  title: ' / ', fontSize: 14, fontFamily: AppThemeData.medium, color: AppThemData.greyShade500),
                                              GestureDetector(
                                                  onTap: () => Get.back(),
                                                  child: TextCustom(
                                                      title: 'All Drivers'.tr,
                                                      fontSize: 14,
                                                      fontFamily: AppThemeData.medium,
                                                      color: AppThemData.greyShade500)),
                                              const TextCustom(
                                                  title: ' / ', fontSize: 14, fontFamily: AppThemeData.medium, color: AppThemData.greyShade500),
                                              TextCustom(
                                                  title: ' ${controller.title.value} ',
                                                  fontSize: 14,
                                                  fontFamily: AppThemeData.medium,
                                                  color: AppThemData.primary500)
                                            ])
                                          ]),
                                        ],
                                      ),
                                      spaceH(height: 20),
                                      ResponsiveWidget(
                                        desktop: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: _buildVerificationDocumentsPanel(context, controller, themeChange),
                                            ),
                                            const SizedBox(width: 24),
                                            SizedBox(
                                              width: 400,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildProfileAndDetailsPanel(context, controller, themeChange),
                                                  // const SizedBox(height: 24),
                                                  // _buildWalletCard(context, controller, themeChange),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        tablet: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildProfileAndDetailsPanel(context, controller, themeChange),
                                            // const SizedBox(height: 24),
                                            // _buildWalletCard(context, controller, themeChange),
                                            const SizedBox(height: 24),
                                            _buildVerificationDocumentsPanel(context, controller, themeChange),
                                          ],
                                        ),
                                        mobile: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildProfileAndDetailsPanel(context, controller, themeChange),
                                            // const SizedBox(height: 24),
                                            // _buildWalletCard(context, controller, themeChange),
                                            const SizedBox(height: 24),
                                            _buildVerificationDocumentsPanel(context, controller, themeChange),
                                          ],
                                        ),
                                      ),
                                      spaceH(height: 20),
                                      Obx(
                                        () => SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: controller.isLoading.value
                                                ? Padding(
                                                    padding: paddingEdgeInsets(),
                                                    child: Constant.loader(),
                                                  )
                                                : controller.currentPageBooking.isEmpty
                                                    ? TextCustom(title: "No Data available".tr)
                                                    : DataTable(
                                                        horizontalMargin: 20,
                                                        columnSpacing: 30,
                                                        dataRowMaxHeight: 65,
                                                        headingRowHeight: 65,
                                                        border: TableBorder.all(
                                                          color: themeChange.isDarkTheme() ? AppThemData.greyShade800 : AppThemData.greyShade100,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        headingRowColor: WidgetStateColor.resolveWith((states) =>
                                                            themeChange.isDarkTheme() ? AppThemData.greyShade800 : AppThemData.greyShade100),
                                                        columns: [
                                                          CommonUI.dataColumnWidget(context, columnTitle: "Order Id".tr, width: 150),
                                                          CommonUI.dataColumnWidget(context,
                                                              columnTitle: "Customer Name".tr,
                                                              width: ResponsiveWidget.isMobile(context)
                                                                  ? 150
                                                                  : MediaQuery.of(context).size.width * 0.15),
                                                          CommonUI.dataColumnWidget(context,
                                                              columnTitle: "Booking Date".tr,
                                                              width: ResponsiveWidget.isMobile(context)
                                                                  ? 220
                                                                  : MediaQuery.of(context).size.width * 0.17),
                                                          CommonUI.dataColumnWidget(context,
                                                              columnTitle: "Booking Status".tr,
                                                              width: ResponsiveWidget.isMobile(context)
                                                                  ? 220
                                                                  : MediaQuery.of(context).size.width * 0.10),
                                                          CommonUI.dataColumnWidget(context,
                                                              columnTitle: "Payment Status".tr,
                                                              width: ResponsiveWidget.isMobile(context)
                                                                  ? 220
                                                                  : MediaQuery.of(context).size.width * 0.07),

                                                          CommonUI.dataColumnWidget(context, columnTitle: "Total".tr, width: 140),
                                                          // CommonUI.dataColumnWidget(context,
                                                          //     columnTitle: "Status", width: ResponsiveWidget.isMobile(context) ? 100 : MediaQuery.of(context).size.width * 0.10),
                                                          CommonUI.dataColumnWidget(
                                                            context,
                                                            columnTitle: "Action".tr,
                                                            width: 100,
                                                          ),
                                                        ],
                                                        rows: controller.currentPageBooking
                                                            .map((bookingModel) => DataRow(cells: [
                                                                  DataCell(
                                                                    TextCustom(
                                                                      title: bookingModel.id!.isEmpty
                                                                          ? "N/A".tr
                                                                          : "#${bookingModel.id!.substring(0, 8)}",
                                                                    ),
                                                                  ),
                                                                  DataCell(
                                                                    Container(
                                                                      alignment: Alignment.centerLeft,
                                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                                      child: TextCustom(
                                                                        title: (bookingModel.customerName != null && bookingModel.customerName!.isNotEmpty)
                                                                            ? bookingModel.customerName!
                                                                            : "Unknown User".tr,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  DataCell(TextCustom(
                                                                      title: bookingModel.createAt == null
                                                                          ? ''
                                                                          : Constant.timestampToDate(bookingModel.createAt!))),
                                                                  DataCell(TextCustom(
                                                                      title: bool.parse(bookingModel.paymentStatus!.toString())
                                                                          ? "Paid".tr
                                                                          : "Unpaid".tr)),
                                                                  DataCell(
                                                                    // e.bookingStatus.toString()
                                                                    Constant.bookingStatusText(context, bookingModel.bookingStatus.toString()),
                                                                  ),
                                                                  DataCell(TextCustom(title: Constant.amountShow(amount: bookingModel.subTotal))),
                                                                  DataCell(
                                                                    Container(
                                                                      alignment: Alignment.center,
                                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                                      child: Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          InkWell(
                                                                            onTap: () async {
                                                                              // Get.toNamed(Routes.CAB_DETAIL,
                                                                              //     arguments: {'bookingModel': bookingModel});

                                                                              Get.toNamed('${Routes.CAB_DETAIL}/${bookingModel.id}');
                                                                            },
                                                                            child: SvgPicture.asset(
                                                                              "assets/icons/ic_eye.svg",
                                                                              color: AppThemData.greyShade400,
                                                                              height: 16,
                                                                              width: 16,
                                                                            ),
                                                                          ),
                                                                          InkWell(
                                                                            onTap: () async {
                                                                              if (Constant.isDemo) {
                                                                                DialogBox.demoDialogBox();
                                                                              } else {
                                                                                bool confirmDelete =
                                                                                    await DialogBox.showConfirmationDeleteDialog(context);
                                                                                if (confirmDelete) {
                                                                                  await controller.removeBooking(bookingModel);
                                                                                  controller.getBookings();
                                                                                }
                                                                              }
                                                                            },
                                                                            child: SvgPicture.asset(
                                                                              "assets/icons/ic_delete.svg",
                                                                              color: AppThemData.greyShade400,
                                                                              height: 16,
                                                                              width: 16,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ]))
                                                            .toList()),
                                          ),
                                        ),
                                      ),
                                      spaceH(),
                                      Visibility(
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
                                  ),
                                ),
                              ]),
                        )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerificationDocumentsPanel(BuildContext context, DriverDetailScreenController controller, DarkThemeProvider themeChange) {
    final driver = controller.driverUserModel.value;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeChange.isDarkTheme() ? AppThemData.greyShade900 : AppThemData.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeChange.isDarkTheme() ? AppThemData.greyShade800 : AppThemData.greyShade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextCustom(
            title: "VERIFICATION DOCUMENTS".tr,
            fontSize: 16,
            fontFamily: AppThemeData.bold,
            color: AppThemData.primary500,
          ),
          const SizedBox(height: 24),
          customRowData(label: "Aadhar Number", value: driver.aadharCardNumber ?? "N/A", themeChange: themeChange),
          customRowData(label: "PAN Number", value: driver.panCardNumber ?? "N/A", themeChange: themeChange),
          customRowData(label: "License Number", value: driver.drivingLicenseNumber ?? "N/A", themeChange: themeChange),
          const SizedBox(height: 32),
          
          // Documents Images Grid
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 1.5,
                children: [
                  _documentImageWidget(title: "Aadhar Card", imageUrl: driver.aadharCard, themeChange: themeChange),
                  _documentImageWidget(title: "Driving License", imageUrl: driver.drivingLicense, themeChange: themeChange),
                  _documentImageWidget(title: "PAN Card", imageUrl: driver.panCardImage, themeChange: themeChange),
                  _documentImageWidget(title: "PAN Card (High-res)", imageUrl: driver.panCardImage, themeChange: themeChange),
                  _documentImageWidget(title: "RC Book", imageUrl: driver.rcBook, themeChange: themeChange),
                  _documentImageWidget(title: "Insurance", imageUrl: driver.insurance, themeChange: themeChange),
                  _documentImageWidget(title: "Signature", imageUrl: driver.signature, themeChange: themeChange),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAndDetailsPanel(BuildContext context, DriverDetailScreenController controller, DarkThemeProvider themeChange) {
    final driver = controller.driverUserModel.value;
    final String firstLetter = (driver.fullName ?? "D").isNotEmpty ? driver.fullName![0].toUpperCase() : "D";
    final String submittedAt = driver.createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(driver.createdAt!.toDate())
        : "N/A";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeChange.isDarkTheme() ? AppThemData.greyShade900 : AppThemData.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeChange.isDarkTheme() ? AppThemData.greyShade800 : AppThemData.greyShade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.pinkAccent,
            backgroundImage: (driver.profilePic != null && driver.profilePic!.isNotEmpty)
                ? NetworkImage(driver.profilePic!)
                : null,
            child: (driver.profilePic == null || driver.profilePic!.isEmpty)
                ? Text(
                    firstLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          // Name
          TextCustom(
            title: driver.fullName ?? "N/A",
            fontSize: 22,
            fontFamily: AppThemeData.bold,
            color: themeChange.isDarkTheme() ? Colors.white : Colors.black,
          ),
          const SizedBox(height: 32),
          
          // Basic Info Section
          Align(
            alignment: Alignment.centerLeft,
            child: TextCustom(
              title: "BASIC INFORMATION".tr,
              fontSize: 14,
              fontFamily: AppThemeData.bold,
              color: AppThemData.primary500,
            ),
          ),
          const SizedBox(height: 16),
          customRowData(label: "Phone", value: driver.phoneNumber ?? "N/A", themeChange: themeChange),
          customRowData(label: "Email", value: driver.email ?? "N/A", themeChange: themeChange),
          customRowData(label: "Password", value: driver.plainPassword != null && driver.plainPassword!.isNotEmpty ? driver.plainPassword! : "123456", themeChange: themeChange),
          customRowData(label: "Vehicle Type", value: (driver.driverVehicleDetails?.vehicleTypeName?.isNotEmpty == true ? driver.driverVehicleDetails!.vehicleTypeName! : (driver.vehicleType?.isNotEmpty == true ? driver.vehicleType! : "N/A")), themeChange: themeChange),
          customRowData(label: "Submitted At", value: submittedAt, themeChange: themeChange),
          
          const SizedBox(height: 32),
          // Vehicle Details Section
          Align(
            alignment: Alignment.centerLeft,
            child: TextCustom(
              title: "VEHICLE DETAILS".tr,
              fontSize: 14,
              fontFamily: AppThemeData.bold,
              color: AppThemData.primary500,
            ),
          ),
          const SizedBox(height: 16),
          customRowData(label: "Vehicle Type", value: (driver.driverVehicleDetails?.vehicleTypeName?.isNotEmpty == true ? driver.driverVehicleDetails!.vehicleTypeName! : (driver.vehicleType?.isNotEmpty == true ? driver.vehicleType! : "N/A")), themeChange: themeChange),
          customRowData(label: "Model", value: driver.vehicleModel ?? driver.driverVehicleDetails?.modelName ?? "N/A", themeChange: themeChange),
          customRowData(label: "Number Plate", value: driver.vehicleNumberPlate ?? driver.driverVehicleDetails?.vehicleNumber ?? "N/A", themeChange: themeChange),
          customRowData(label: "Manufacture Year", value: driver.vehicleYear ?? "N/A", themeChange: themeChange),
          const SizedBox(height: 32),
          // Actions: Approve & Suspend
          Row(
            children: [
              if (driver.status != 'active')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.approveDriver(),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text("Approve".tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              if (driver.status != 'active' && driver.status != 'suspended')
                const SizedBox(width: 12),
              if (driver.status != 'suspended')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.suspendDriver(),
                    icon: const Icon(Icons.block_outlined, size: 16),
                    label: Text("Suspend".tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, DriverDetailScreenController controller, DarkThemeProvider themeChange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 25),
      width: double.infinity,
      decoration: BoxDecoration(
        image: const DecorationImage(image: AssetImage("assets/image/wallet_card.png"), fit: BoxFit.fill),
        border: Border.all(color: AppThemData.lightGrey06.withOpacity(.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppThemData.primaryWhite.withOpacity(.2)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(
                    'assets/icons/ic_wallet.svg',
                    colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                    height: 30,
                    width: 30,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextCustom(
                      title: 'Wallet Amount',
                      fontSize: 14,
                      color: themeChange.isDarkTheme()
                          ? AppThemData.primaryWhite.withOpacity(.7)
                          : AppThemData.primaryBlack.withOpacity(.7),
                      fontFamily: AppThemeData.medium,
                    ),
                    const SizedBox(height: 7),
                    FittedBox(
                      child: Text(
                        Constant.amountShow(amount: controller.driverUserModel.value.walletAmount ?? "0"),
                        style: Constant.defaultTextStyle(
                          size: 18,
                          color: themeChange.isDarkTheme()
                              ? AppThemData.primaryWhite.withOpacity(.7)
                              : AppThemData.primaryBlack.withOpacity(.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: CustomButtonWidget(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  buttonTitle: "Top Up".tr,
                  borderRadius: 60,
                  textColor: AppThemData.primaryWhite,
                  buttonColor: AppThemData.primaryBlack,
                  onPress: () {
                    controller.setDefaultData();
                    showDialog(context: context, builder: (context) => const TopUpDialog());
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButtonWidget(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  buttonTitle: "Transaction History".tr,
                  borderRadius: 60,
                  textColor: AppThemData.primaryBlack,
                  buttonColor: AppThemData.primary200,
                  onPress: () {
                    controller.setDefaultData();
                    showDialog(context: context, builder: (context) => const TransactionHistoryDialog());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _documentImageWidget({required String title, required String? imageUrl, required DarkThemeProvider themeChange}) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextCustom(
              title: title.tr,
              fontSize: 14,
              fontFamily: AppThemeData.bold,
              color: themeChange.isDarkTheme() ? Colors.white : Colors.black,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: themeChange.isDarkTheme() ? AppThemData.greyShade950 : AppThemData.greyShade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: themeChange.isDarkTheme() ? AppThemData.greyShade800 : AppThemData.greyShade200,
                  ),
                ),
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _showZoomedImageDialog(context, imageUrl, title),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
          ],
        );
      }
    );
  }

  void _showZoomedImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(title, style: const TextStyle(color: Colors.white)),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, size: 80, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget customRowData({required String label, required String value, required DarkThemeProvider themeChange}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextCustom(
            title: label.tr,
            fontSize: 14,
            fontFamily: AppThemeData.medium,
            color: themeChange.isDarkTheme() ? Colors.grey[400] : Colors.grey[600],
          ),
          TextCustom(
            title: value,
            fontSize: 14,
            fontFamily: AppThemeData.bold,
            color: themeChange.isDarkTheme() ? Colors.white : Colors.black,
          ),
        ],
      ),
    );
  }
}

Row rowDataWidget({required String name, required String value, required themeChange}) {
  return Row(
    children: [
      TextCustom(title: name.tr, fontSize: 14, fontFamily: AppThemeData.medium).expand(flex: 1),
      const TextCustom(title: ":   ", fontSize: 14, fontFamily: AppThemeData.medium),
      TextCustom(
        title: value,
        fontSize: 14,
        fontFamily: AppThemeData.regular,
      ).expand(flex: 2),
    ],
  );
}

class TopUpDialog extends StatelessWidget {
  const TopUpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<DriverDetailScreenController>(
      init: DriverDetailScreenController(),
      builder: (controller) {
        return CustomDialog(
          title: "Top Up",
          widgetList: [
            SizedBox(
              child: CustomTextFormField(title: "Top up Amount".tr, hintText: "Enter Top up Amount".tr, controller: controller.topupController.value),
            ),
          ],
          bottomWidgetList: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButtonWidget(
                  buttonTitle: "Close".tr,
                  buttonColor: themeChange.isDarkTheme() ? AppThemData.greyShade900 : AppThemData.greyShade100,
                  onPress: () {
                    controller.topupController.value.text = "";
                    Navigator.pop(context);
                  },
                ),
                spaceW(),
                CustomButtonWidget(
                  buttonTitle: "Top up".tr,
                  onPress: () {
                    // if (Constant.isDemo) {
                    //   DialogBox.demoDialogBox();
                    // } else {
                    controller.completeOrder(DateTime.now().millisecondsSinceEpoch.toString());
                    // }
                  },
                ),
              ],
            ),
          ],
          controller: controller,
        );
      },
    );
  }

}

class TransactionHistoryDialog extends StatelessWidget {
  const TransactionHistoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<DriverDetailScreenController>(
      init: DriverDetailScreenController(),
      builder: (controller) {
        return CustomDialog(
          title: "Transaction History",
          widgetList: [
            Obx(
              () => controller.currentPageWalletTransaction.isEmpty
                  ? const TextCustom(title: "Transaction History not available")
                  : ListView.builder(
                      itemCount: controller.currentPageWalletTransaction.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        WalletTransactionModel walletTransactionModel = controller.currentPageWalletTransaction[index];
                        return Container(
                          width: 358,
                          height: 80,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.only(right: 16),
                                decoration: ShapeDecoration(
                                  color: (walletTransactionModel.isCredit ?? false)
                                      ? themeChange.isDarkTheme()
                                          ? AppThemData.green950
                                          : AppThemData.green50
                                      : themeChange.isDarkTheme()
                                          ? AppThemData.secondary950
                                          : AppThemData.secondary50,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    // "assets/icon/ic_my_wallet.svg",
                                    "assets/icons/ic_my_wallet.svg",
                                    colorFilter: ColorFilter.mode(
                                        (walletTransactionModel.isCredit ?? false) ? AppThemData.green500 : AppThemData.red500, BlendMode.srcIn),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        width: 1,
                                        color: themeChange.isDarkTheme() ? AppThemData.greyShade800 : AppThemData.greyShade100,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: TextCustom(
                                              title: walletTransactionModel.note ?? '',
                                              fontSize: 16,
                                              fontFamily: AppThemeData.medium,
                                              color: themeChange.isDarkTheme() ? AppThemData.greyShade50 : AppThemData.greyShade950,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          TextCustom(
                                            title: Constant.amountToShow(amount: walletTransactionModel.amount ?? ''),
                                            fontSize: 16,
                                            fontFamily: AppThemeData.bold,
                                            color: (walletTransactionModel.isCredit ?? false) ? AppThemData.green500 : AppThemData.red500,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                TextCustom(
                                                  title: (walletTransactionModel.createdDate ?? Timestamp.now()).toDate().dateMonthYear(),
                                                  fontFamily: AppThemeData.medium,
                                                  fontSize: 14,
                                                  color: themeChange.isDarkTheme() ? AppThemData.greyShade400 : AppThemData.greyShade500,
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  height: 16,
                                                  decoration: ShapeDecoration(
                                                    shape: RoundedRectangleBorder(
                                                      side: BorderSide(
                                                        width: 1,
                                                        strokeAlign: BorderSide.strokeAlignCenter,
                                                        color: themeChange.isDarkTheme() ? AppThemData.greyShade800 : AppThemData.greyShade100,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                TextCustom(
                                                  title: (walletTransactionModel.createdDate ?? Timestamp.now()).toDate().time(),
                                                  fontSize: 14,
                                                  fontFamily: AppThemeData.medium,
                                                  color: themeChange.isDarkTheme() ? AppThemData.greyShade400 : AppThemData.greyShade500,
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
                            ],
                          ),
                        );
                      },
                    ),
            )
          ],
          bottomWidgetList: [
            Visibility(
              visible: controller.totalPage.value > 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: WebPagination(
                        currentPage: controller.currentPage.value,
                        totalPage: controller.totalPage.value,
                        displayItemCount: controller.pageValue("3"),
                        onPageChanged: (page) {
                          controller.currentPage.value = page;
                          controller.setPaginationForTransactionHistory(controller.totalItemPerPage.value);
                        }),
                  ),
                ],
              ),
            )
          ],
          controller: controller,
        );
      },
    );
  }
}
