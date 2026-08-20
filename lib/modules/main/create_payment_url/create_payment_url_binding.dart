import 'package:get/get.dart';

import 'create_payment_url_controller.dart';

class CreatePaymentUrlBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreatePaymentUrlController>(
      () => CreatePaymentUrlController(apiRepository: Get.find()),
    );
  }
}
