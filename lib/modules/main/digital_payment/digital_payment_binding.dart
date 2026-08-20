import 'package:get/get.dart';
import 'digital_payment_controller.dart';

class DigitalPaymentBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DigitalPaymentController>(
      () => DigitalPaymentController(
        apiRepository: Get.find(),
      ),
    );
  }
}
