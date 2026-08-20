import 'package:get/get.dart';
import 'trouble_shooting_controller.dart';

class TroubleShootingBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TroubleShootingController>(
      () => TroubleShootingController(
        apiRepository: Get.find(),
      ),
    );
  }
}
