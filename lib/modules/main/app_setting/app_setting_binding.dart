import 'package:get/get.dart';
import 'app_setting_controller.dart';

class AppSettingBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppSettingController>(
      () => AppSettingController(),
    );
  }
}
