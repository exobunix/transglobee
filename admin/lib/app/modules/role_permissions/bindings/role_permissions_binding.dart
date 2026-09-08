import 'package:get/get.dart';
import '../controllers/role_permissions_controller.dart';

class RolePermissionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RolePermissionsController>(
      () => RolePermissionsController(),
    );
  }
}
