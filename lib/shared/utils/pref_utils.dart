import 'package:flutter/services.dart';
import 'package:app/shared/secure_shared_preferences/secure_shared_preferences.dart';
import 'package:app/shared/utils/log_utils.dart';

class PrefUtils {
  static String _cachedThemeData = 'primary';
  static int _cachedLastUptime = 0;

  Future<void> init() async {
    _cachedThemeData =
        await SecureSharedPreferences.instance.getThemeData() ?? 'primary';
    LogUtils.debugLog('Encrypted preferences initialized');
  }

  /// Clears only non-session preference values managed by this utility.
  void clearPreferencesData() async {
    _cachedThemeData = 'primary';
    _cachedLastUptime = 0;
    await SecureSharedPreferences.instance.setThemeData(null);
  }

  Future<void> setThemeData(String value) async {
    _cachedThemeData = value;
    await SecureSharedPreferences.instance.setThemeData(value);
  }

  String getThemeData() => _cachedThemeData;

  Future<bool> hasDeviceReboot() async {
    final uptime = await SystemInfo.getUptime();

    var hasReboot = false;
    if (uptime < _cachedLastUptime) {
      LogUtils.debugLog('Device rebooted');
      hasReboot = true;
    } else {
      LogUtils.debugLog('Device not rebooted');
      hasReboot = false;
    }

    _cachedLastUptime = uptime;

    return hasReboot;
  }
}

class SystemInfo {
  static const platform = const MethodChannel('CHANNEL_ANDROID_SYSTEM');

  static Future<bool> openWizarPosCardPaymentApp() async {
    try {
      return await platform.invokeMethod<bool>('openWizarPosCardPaymentApp') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<int> getUptime() async {
    try {
      final int result = await platform.invokeMethod('getUptime');
      return result;
    } on PlatformException catch (e) {
      LogUtils.debugLog("Failed to get uptime: '${e.message}'.");
      return 0;
    }
  }
}
