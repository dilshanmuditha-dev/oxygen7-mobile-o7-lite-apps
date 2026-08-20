import 'package:get/get.dart';
import 'refund_controller.dart';

class RefundBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RefundController>(
      () => RefundController(
        apiRepository: Get.find(),
      ),
    );
  }
}
