import 'package:get/get.dart';
import 'package:app/api/api_repository.dart';
import 'card_reader_controller.dart';

class CardReaderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CardReaderController>(
      () => CardReaderController(
        apiRepository: Get.find<ApiRepository>(),
      ),
    );
  }
}
