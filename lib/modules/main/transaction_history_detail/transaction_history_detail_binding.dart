import 'package:app/modules/auth/auth.dart';
import 'package:get/get.dart';
import 'transaction_history_detail_controller.dart';

class TransactionHistoryDetailBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransactionHistoryDetailController>(
      () => TransactionHistoryDetailController(
        apiRepository: Get.find(),
      ),
    );
    Get.lazyPut<AuthController>(
      () => AuthController(
        apiRepository: Get.find(),
      ),
    );
  }
}
