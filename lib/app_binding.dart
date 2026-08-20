import 'package:get/get.dart';

import 'api/api_provider.dart';
import 'api/api_repository.dart';
import 'modules/auth/auth_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() async {
    Get.put(ApiProvider(Get.find()), permanent: true);
    Get.put(ApiRepository(), permanent: true);
    Get.put(AuthController(apiRepository: Get.find()), permanent: true);
  }
}
