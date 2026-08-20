import 'package:get/get.dart';
import 'shared/secure_shared_preferences/sharepreference.dart';
import 'shared/services/services.dart';
import 'shared/utils/app_flavor_helper.dart';
import 'shared/utils/pref_utils.dart';

class DenpendencyInjection {
  static Future<void> init() async {
    await Get.putAsync(() => StorageService().init());
    await Get.putAsync(() => SharedPrefManager.init());

    // Migrate terminalID from plain SharedPreferences to SecureSharedPreferences.
    // This must run after SharedPrefManager.init() so _sharedPreferences is available.
    await SharedPrefManager.migrateTerminalID();

    // Migrate all app settings (language, dark mode, sounds, etc.) from plain
    // SharedPreferences to encrypted secure storage. One-time operation per device.
    await SharedPrefManager.migrateAppSettings();

    await PrefUtils().init();
  }

  static Future<void> inject(AppFlavor appFlavor) async {
    Get.put<AppFlavor>(appFlavor);
  }
}
