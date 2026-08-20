import 'package:app/modules/main/app_setting/app_setting_controller.dart';
import 'package:get/get.dart';

import 'home_controller.dart';

class HomeBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(HomeController(apiRepository: Get.find()));
    Get.put(AppSettingController());
  }
}
