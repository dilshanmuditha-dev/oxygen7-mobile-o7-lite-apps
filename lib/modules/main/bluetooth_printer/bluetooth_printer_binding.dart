import 'package:get/get.dart';

import 'bluetooth_printer_controller.dart';

class BluetoothPrinterBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BluetoothPrinterController>(
      () => BluetoothPrinterController(),
    );
  }
}
