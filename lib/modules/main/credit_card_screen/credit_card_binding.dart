import 'package:get/get.dart';

import 'credit_card_controller.dart';

class CreditCardBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreditCardController>(
      () => CreditCardController(
        apiRepository: Get.find(),
      ),
    );
  }
}
