import 'package:get/get.dart';

import 'payment_page_qr_o7lite_controller.dart';

class PaymentPageQrO7LiteBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentPageQrO7LiteController>(
      () => PaymentPageQrO7LiteController(
        apiRepository: Get.find(),
      ),
    );
  }
}
