import 'package:admin/app/components/menu_widget.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/widget/common_ui.dart';
import 'package:admin/widget/container_custom.dart';
import 'package:admin/widget/global_widgets.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:admin/widget/web_pagination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:admin/app/utils/responsive.dart';
import 'package:admin/app/modules/cab_bookings_screen/controllers/cab_booking_controller.dart';
import 'widget/booking_filters_header.dart';
import 'widget/booking_list_view.dart';
import 'widget/booking_status_filter_tabs.dart';
import 'widget/booking_type_tabs.dart';

class CabBookingScreenView extends GetView<CabBookingController> {
  const CabBookingScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder<CabBookingController>(
      init: CabBookingController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemData.greyShade950 : AppThemData.greyShade50,
          appBar: _buildAppBar(context, themeChange),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              BookingFiltersHeader(controller: controller, themeChange: themeChange),
                              spaceH(height: 20),
                              BookingTypeTabs(controller: controller),
                              BookingStatusFilterTabs(controller: controller),
                              spaceH(height: 20),
                              BookingListView(controller: controller, themeChange: themeChange),
                              spaceH(),
                              _buildPagination(context, controller),
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

  PreferredSizeWidget _buildAppBar(BuildContext context, DarkThemeProvider themeChange) {
    return AppBar(
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
    );
  }

  Widget _buildPagination(BuildContext context, CabBookingController controller) {
    return Obx(() {
      if (controller.totalPage.value <= 1) return const SizedBox.shrink();
      return Row(
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
              },
            ),
          ),
        ],
      );
    });
  }
}
