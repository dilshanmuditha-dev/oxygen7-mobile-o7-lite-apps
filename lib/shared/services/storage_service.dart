import 'package:get/get.dart';

import '../secure_shared_preferences/secure_shared_preferences.dart';

class StorageService extends GetxService {
  static bool _isGw3 = false;

  Future<StorageService> init() async {
    _isGw3 = await SecureSharedPreferences.instance.getIsGw3();
    return this;
  }

  static bool get isGw3 => _isGw3;

  static set isGw3(bool value) {
    _isGw3 = value;
    SecureSharedPreferences.instance.setIsGw3(value);
  }
}
