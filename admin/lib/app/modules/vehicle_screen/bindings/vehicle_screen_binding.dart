import 'package:get/get.dart';
import '../controllers/vehicle_screen_controller.dart';

class VehicleScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VehicleScreenController>(() => VehicleScreenController());
  }
}
