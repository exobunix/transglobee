import 'package:admin/app/components/menu_widget.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/app/utils/responsive.dart';
import 'package:admin/widget/common_ui.dart';
import 'package:admin/widget/global_widgets.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../controllers/cab_detail_controller.dart';
import 'widget/supervisor_layout_view.dart';
import 'widget/standard_cab_detail_layout_view.dart';

class CabDetailView extends GetView<CabDetailController> {
  const CabDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<CabDetailController>(
      init: CabDetailController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemData.greyShade950 : AppThemData.greyShade50,
          key: controller.scaffoldKey,
          appBar: AppBar(
            backgroundColor: themeChange.isDarkTheme() ? AppThemData.primaryBlack : AppThemData.primaryWhite,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                if (!ResponsiveWidget.isDesktop(context)) ...{
                  IconButton(
                    onPressed: () {
                      controller.scaffoldKey.currentState!.openDrawer();
                    },
                    icon: const Icon(Icons.menu),
                  ),
                },
                TextCustom(
                  title: 'Cab Details'.tr,
                  color: themeChange.isDarkTheme() ? AppThemData.primaryWhite : AppThemData.primaryBlack,
                  fontFamily: AppThemeData.bold,
                  fontSize: 18,
                ),
              ],
            ),
            actions: [
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
                    ? Constant.loader()
                    : controller.bookingModel.value.id == null
                        ? Center(
                            child: TextCustom(
                              title: "Failed to load booking details or permission denied".tr,
                              fontSize: 16,
                            ),
                          )
                        : (controller.bookingModel.value.type == 'logistics' || controller.bookingModel.value.type == 'shuttle')
                            ? SupervisorLayoutView(controller: controller, themeChange: themeChange)
                            : StandardCabDetailLayoutView(controller: controller, themeChange: themeChange),
              ),
            ],
          ),
        );
      },
    );
  }
}
