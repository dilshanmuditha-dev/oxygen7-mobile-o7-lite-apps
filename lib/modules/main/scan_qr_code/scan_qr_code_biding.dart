import 'package:get/get.dart';
import 'scan_qr_code_controller.dart';

class ScanQrCodeBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScanQrCodeController>(() => ScanQrCodeController());
  }
}
