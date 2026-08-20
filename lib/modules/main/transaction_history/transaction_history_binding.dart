import 'package:get/get.dart';
import 'transaction_history_controller.dart';

class TransactionHistoryBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransactionHistoryController>(
      () => TransactionHistoryController(
        apiRepository: Get.find(),
      ),
    );
  }
}
