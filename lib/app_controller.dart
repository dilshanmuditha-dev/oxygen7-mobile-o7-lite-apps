import 'dart:async';
import 'dart:io';

import 'package:app/api/api_provider.dart';
import 'package:app/routes/app_pages.dart';
import 'package:app/shared/constants/country.dart';
import 'package:app/shared/secure_shared_preferences/secure_shared_preferences.dart';
import 'package:app/shared/secure_shared_preferences/sharepreference.dart';
import 'package:app/shared/secure_storage/secure_storage_service.dart';
import 'package:app/shared/security/root_detection_service.dart';
import 'package:app/shared/services/bluetooth_printer/bluetooth_printer_service.dart';
import 'package:app/shared/services/printer.dart';
import 'package:app/shared/services/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:get/get.dart';
import 'shared/utils/app_flavor_helper.dart';
import 'shared/utils/log_utils.dart';

class AppController extends GetxController with WidgetsBindingObserver {
  RxBool isDarkModeOn = false.obs;
  RxBool isNotificationOn = true.obs;
  RxBool isPasswordVisible = true.obs;

  RxBool isLandiDevice = false.obs;
  RxBool isSunmiDevice = false.obs;
  RxBool isCastleDevice = false.obs;
  RxBool isWizarPosDevice = false.obs;
  RxBool isAnfuDevice = false.obs;
  RxBool isCoherentDevice = false.obs;
  RxBool isMorefunDevice = false.obs;

  /// True if running on a regular mobile device (not a POS terminal)
  /// False if running on POS devices (Sunmi, Castle, Anfu, Landi, WizarPos, Coherent, Morefun)
  RxBool isMobileUser = false.obs;

  RxBool isEnableMineSec = false.obs;

  RxString currentRoute = ''.obs;

  /// Set to true while a security check is in progress to prevent concurrent checks.
  bool _securityCheckInProgress = false;

  final Rx<AppFlavor> currentFlavor;
  AppController(AppFlavor flavor) : currentFlavor = flavor.obs;

  /// Terminal country code alpha
  /// SGP = Singapore (default)
  /// MYS = Malaysia
  /// THA = Thailand
  RxString countryCodeAlpha = ''.obs;

  /// Current country as type-safe enum (defaults to Singapore)
  /// Use this for country-specific business logic
  final Rx<Country> _currentCountry = Country.singapore.obs;

  /// Gets the current country as enum
  Country get currentCountry => _currentCountry.value;

  /// Sets the country from alpha-3 code string.
  /// Defaults to Singapore if code is invalid or empty.
  /// Synchronizes the countryCodeAlpha string with the enum value.
  void setCountryFromAlpha3(String? code) {
    final country = Country.fromAlpha3(code) ?? Country.singapore;
    _currentCountry.value = country;
    countryCodeAlpha.value = country.alpha3Code;
  }

  void updateCurrentRoute() {
    currentRoute.value = Get.currentRoute;
  }

  @override
  void onInit() async {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    getDarkMode();

    // Run all independent device checks in parallel for better performance
    final results = await Future.wait([
      Printer.isCastleDevice(),
      Printer.isSunmiDevice(),
      Printer.isLandiDevice(),
      Printer.isWizarPosDevice(),
      Printer.isAnfuDevice(),
      Printer.isCoherentDevice(),
      Printer.isMorefunDevice(),
      SecureSharedPreferences.instance.getCountryCodeAlpha(),
    ]);

    isCastleDevice.value = results[0] as bool;
    isSunmiDevice.value = results[1] as bool;
    isLandiDevice.value = results[2] as bool;
    isWizarPosDevice.value = results[3] as bool;
    isAnfuDevice.value = results[4] as bool;
    isCoherentDevice.value = results[5] as bool;
    isMorefunDevice.value = results[6] as bool;
    setCountryFromAlpha3((results[7] as String?) ?? 'SGP');

    // isMobileUser: true if NOT any known POS device (regular mobile user)
    isMobileUser.value = !isSunmiDevice.value &&
        !isCastleDevice.value &&
        !isAnfuDevice.value &&
        !isLandiDevice.value &&
        !isWizarPosDevice.value &&
        !isCoherentDevice.value &&
        !isMorefunDevice.value;

    // Auto-reconnect to saved Bluetooth printer for mobile users (fire-and-forget)
    if (isMobileUser.value) {
      BluetoothPrinterService.instance.autoReconnect();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // Window metrics change when the soft keyboard shows/hides. Android forces
    // the navigation bar back into view at that moment, and immersiveSticky does
    // not auto-hide it while the keyboard is up — so it overlaps app UI. Re-apply
    // immersive mode here to push the nav bar back out.
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [SystemUiOverlay.top],
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Re-apply immersive mode on Android
      if (Platform.isAndroid) {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.immersiveSticky,
          overlays: [SystemUiOverlay.top],
        );
      }

      // Check developer mode on every app resume — catches devices that were
      // unlocked after the user logged in while the device was clean.
      await _checkDeveloperModeOnResume();

      // Check root/jailbreak on every app resume — catches devices that
      // attach root tools after initial launch (timing attack prevention).
      _checkRootDetectionOnResume();
    }
  }

  /// Checks developer mode each time the app resumes from background.
  ///
  /// If developer mode / USB debugging is detected, the session is immediately
  /// invalidated and the user is redirected to the login screen. This closes
  /// the attack window where a device becomes compromised after login.
  Future<void> _checkDeveloperModeOnResume() async {
    // Skip in debug mode (developer tools are expected during development)
    if (kDebugMode) return;

    // Skip if a check is already running
    if (_securityCheckInProgress) return;

    _securityCheckInProgress = true;
    try {
      bool developerMode = false;
      try {
        developerMode = await FlutterJailbreakDetection.developerMode;
      } on PlatformException {
        developerMode = true;
      }

      if (developerMode) {
        await _forceSecurityLogout();
      }
    } finally {
      _securityCheckInProgress = false;
    }
  }

  /// Checks root/jailbreak status each time the app resumes from background.
  ///
  /// This prevents bypass via timing attacks where root tools are attached
  /// after the initial app launch passes detection. If rooted, wipes all
  /// sensitive data and navigates to the warning screen.
  void _checkRootDetectionOnResume() async {
    // Skip in debug mode (root detection is expected to fail during dev)
    if (kDebugMode) return;

    // Skip if a security check is already running
    if (_securityCheckInProgress) return;

    _securityCheckInProgress = true;
    try {
      final isRooted = await RootDetectionService.instance.isDeviceRooted();

      if (isRooted) {
        LogUtils.debugLog(
            '[SecurityMonitor] Rooted device detected on resume — wiping data');

        // Wipe all sensitive data aggressively
        try {
          final svc = await SecureStorageService.getInstance();
          await svc.clearSecureSharedPef(aggressiveWipe: true);
        } catch (e) {
          // Swallow errors — device is compromised, best-effort wipe
          if (kDebugMode) {
            debugPrint('[SecurityMonitor] Data wipe failed: $e');
          }
        }

        // Navigate to rooted warning screen, replacing entire navigation stack
        Get.offAll(() => _RootedWarningResumeScreen());
      }
    } finally {
      _securityCheckInProgress = false;
    }
  }

  /// Invalidates the local session and navigates to the login screen when a
  /// security violation is detected. For GW3 gateways, also calls the server
  /// to invalidate the token so the stolen session cannot be used elsewhere.
  Future<void> _forceSecurityLogout() async {
    LogUtils.debugLog(
        '[SecurityMonitor] Developer mode detected — forcing session logout');

    // Notify server to invalidate the token (best-effort, don't block)
    if (StorageService.isGw3) {
      try {
        final apiProvider = Get.find<ApiProvider>();
        await apiProvider.logOutGw3();
        if (kDebugMode) {
          debugPrint('[SecurityMonitor] Server token invalidation: ok');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SecurityMonitor] Server token invalidation failed: $e');
        }
      }
    }

    // Clear all local session data
    await SecureSharedPreferences.instance.clearSessionOnly();
    await SharedPrefManager.instance.clearSessionOnly();

    // Navigate to login with a flag that tells the login screen to show a
    // security message explaining why the session was terminated.
    if (Get.currentRoute != Routes.LOG_IN) {
      Get.offAllNamed(
        Routes.LOG_IN,
        arguments: {'isLogout': true, 'securityLogout': true},
      );
    }
  }

  void togglePasswordVisibility(RxBool isVisible) =>
      isVisible.value = !isVisible.value;

  void toggleDarkMode() async {
    isDarkModeOn.toggle();
    await SharedPrefManager.instance
        .setBool('isCheckDarkMode', isDarkModeOn.value);
  }

  void getDarkMode() async {
    isDarkModeOn.value =
        await SharedPrefManager.instance.getBool('isCheckDarkMode') ?? false;
  }

  void toggleNotificationMode() {
    isNotificationOn.toggle();
  }

  String get environmentLabel {
    switch (currentFlavor.value) {
      case AppFlavor.development:
        return "UAT";
      case AppFlavor.production:
        return "";
      default:
        return "";
    }
  }

  /// Returns true if current country is Singapore.
  /// Also returns true when country is not set (empty string) for backward compatibility.
  bool isSGPLocation() =>
      _currentCountry.value == Country.singapore ||
      countryCodeAlpha.value.isEmpty;

  /// Returns true if current country is Malaysia
  bool isMYSLocation() => _currentCountry.value == Country.malaysia;

  /// Returns true if current country is Thailand
  bool isTHALocation() => _currentCountry.value == Country.thailand;

  /// Returns true if current country is Bhutan
  bool isBTNLocation() => _currentCountry.value == Country.bhutan;
}

/// Minimal warning screen shown when root/jailbreak is detected on app resume.
/// Cannot be dismissed — the only available action is exiting the app.
class _RootedWarningResumeScreen extends StatelessWidget {
  static const String _title = 'Security Warning';
  static const String _message =
      'This device appears to be rooted or jailbroken. '
      'For your security, this application cannot run on compromised devices. '
      'All locally stored data has been wiped.';
  static const String _exitLabel = 'Exit';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_outline,
                    size: 72, color: Colors.redAccent),
                const SizedBox(height: 24),
                const Text(
                  _title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  _message,
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(_exitLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
