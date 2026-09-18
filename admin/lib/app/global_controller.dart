import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/routes/app_pages.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';
import 'package:get/get.dart';

class GlobalController extends GetxController {
  RxBool isLoading = true.obs;

  @override
  Future<void> onInit() async {
    await getData();
    Constant.getLanguageData();
    super.onInit();
  }

  Future<void> getData() async {
    isLoading.value = false;

    // Check token-based auth (REST API backend — no Firebase Auth needed)
    final String adminToken = await AppSharedPreference.getString('adminToken');
    final bool isLogin = adminToken.isNotEmpty;

    if (Get.currentRoute != Routes.ERROR_SCREEN) {
      if (!isLogin) {
        Get.offAllNamed(Routes.LOGIN_PAGE);
      } else {
        Constant.isLogin = true;
        Get.offAllNamed(Routes.DASHBOARD_SCREEN);
      }
    }
  }
}
