import 'package:get/get.dart';

import 'auth_controller.dart';
import 'create_account_screen.dart';

class AuthBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
      () => AuthController(
        apiRepository: Get.find(),
      ),
    );
    Get.lazyPut<CreateAccountController>(() => CreateAccountController());
  }
}
