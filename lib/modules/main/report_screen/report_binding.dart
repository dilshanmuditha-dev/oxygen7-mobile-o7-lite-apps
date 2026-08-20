import 'package:get/get.dart';
import 'report_controller.dart';

class ReportBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportController>(
      () => ReportController(
        apiRepository: Get.find(),
      ),
    );
  }
}
