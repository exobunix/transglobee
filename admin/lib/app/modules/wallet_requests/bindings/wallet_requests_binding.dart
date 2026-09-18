import 'package:get/get.dart';
import 'package:admin/app/modules/wallet_requests/controllers/wallet_requests_controller.dart';

class WalletRequestsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletRequestsController>(
      () => WalletRequestsController(),
    );
  }
}
