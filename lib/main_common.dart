// ignore_for_file: unused_field, unused_element, unused_local_variable

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import 'app_binding.dart';
import 'app_controller.dart';
import 'di.dart';
import 'lang/translation_service.dart';
import 'modules/splash/splash_binding.dart';
import 'modules/splash/splash_view.dart';
import 'routes/app_pages.dart';
import 'shared/constants/colors.dart';
import 'shared/secure_storage/secure_storage_service.dart';
import 'shared/security/root_detection_service.dart';
import 'shared/services/local_data_upgrade_migration_service.dart';
import 'shared/services/login_deep_link_service.dart';
import 'shared/utils/app_flavor_helper.dart';
import 'shared/utils/responsive_util.dart';
import 'shared/utils/device_performance_detector.dart';
import 'shared/utils/memory_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> mainCommon(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Hide system navigation bar for full-screen display on Android mobile devices.
  // Uses immersiveSticky mode to completely hide the navigation buttons,
  // preventing them from overlapping app UI elements.
  // The navigation bar temporarily reappears on swipe from the bottom edge.
  if (Platform.isAndroid) {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top],
    );
  }

  // Root / Jailbreak detection: if device is compromised, wipe sensitive
  // tokens and show a blocking warning screen instead of launching the app.
  // Uses multi-layered detection (primary library + secondary checks) to
  // prevent bypass via disabling a single detection method.
  // This MUST run BEFORE DenpendencyInjection.init() and SecureStorageService.getInstance().
  // TODO(security): Set to false before final release — only for pentest data inspection.
  const bool kSkipRootDetection = bool.fromEnvironment('SKIP_ROOT_DETECTION');

  bool isRooted = false;
  if (!kSkipRootDetection) {
    try {
      isRooted = await RootDetectionService.instance.isDeviceRooted();
    } catch (e) {
      // If detection fails entirely, assume not rooted to avoid false positives.
      isRooted = false;
    }
  }

  if (isRooted) {
    // Ensure secure storage is initialized and aggressively wipe ALL app data.
    try {
      final svc = await SecureStorageService.getInstance();
      await svc.clearSecureSharedPef(aggressiveWipe: true);
    } catch (e) {
      // Swallow errors - we're already on a compromised device.
    }

    // Launch a minimal app that informs the user and prevents normal use.
    runApp(MaterialApp(home: _RootedWarningScreen()));
    return;
  }

  await LocalDataUpgradeMigrationService().runPreflight();

  await Future.wait([
    DenpendencyInjection.init(),
    DenpendencyInjection.inject(flavor),
    DevicePerformanceDetector.instance
        .initialize(), // Initialize device detection
    MemoryManager.instance.initialize(), // Initialize memory management
    // Initialize secure storage and trigger migration from legacy AES-CBC to AES-GCM
    SecureStorageService.getInstance(),
    Get.put(LoginDeepLinkService(), permanent: true).init(),
  ]);

  // Restore user's saved language preference before building the app
  await TranslationService.initFromSavedPreference();

  runApp(App(flavor));
}

class App extends StatelessWidget {
  final AppFlavor flavor;
  final AppController controller;

  App(this.flavor, {Key? key})
      : controller = Get.put(AppController(flavor)),
        super(key: key);

  final mainTheme = ThemeData(
    scaffoldBackgroundColor: ColorConstants.backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
    ),
  );

  final darkTheme = ThemeData.dark();

  @override
  Widget build(BuildContext context) {
    ResponsiveUtil().init(context);

    AppController appController = Get.find();

    return Obx(() {
      configLoading(controller);

      return GetMaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        enableLog: true,
        initialRoute: Routes.SPLASH,
        defaultTransition: Transition.fade,
        getPages: AppPages.routes,
        unknownRoute: GetPage(
          name: Routes.SPLASH,
          page: () => const SplashView(),
          binding: SplashBinding(),
        ),
        initialBinding: AppBinding(),
        smartManagement: SmartManagement.keepFactory,
        title: 'appTitle'.tr,
        theme: controller.isDarkModeOn.value ? darkTheme : mainTheme,
        locale: TranslationService.locale,
        fallbackLocale: TranslationService.fallbackLocale,
        translations: TranslationService(),
        builder: EasyLoading.init(),
      );
    });
  }
}

void configLoading(AppController controller) {
  var isDarkModeOn = controller.isDarkModeOn.value;
  EasyLoading.instance
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = ResponsiveUtil().getSize(40)
    ..radius = 10.0
    // ..progressColor = Colors.yellow
    ..backgroundColor =
        isDarkModeOn ? ColorConstants.grey : ColorConstants.lightGray
    ..indicatorColor =
        isDarkModeOn ? ColorConstants.white : ColorConstants.grey800
    ..textColor = isDarkModeOn ? ColorConstants.white : ColorConstants.grey800
    // ..maskColor = Colors.red
    ..fontSize = ResponsiveUtil().getSize(16)
    ..userInteractions = false
    ..dismissOnTap = false
    ..animationStyle = EasyLoadingAnimationStyle.scale;
}

/// Hardened screen shown when a device is detected as rooted/jailbroken.
/// This screen cannot be dismissed — the only available action is exiting the app.
class _RootedWarningScreen extends StatelessWidget {
  // Hardcoded fallback strings in case .tr translations aren't loaded
  // on rooted device minimal app (no DI or locale setup runs).
  static const String _fallbackTitle = 'Security Warning';
  static const String _fallbackMessage =
      'This device appears to be rooted or jailbroken. '
      'For your security, this application cannot run on compromised devices. '
      'All locally stored data has been wiped.';
  static const String _fallbackExitLabel = 'Exit';
  static const String _appName = 'Oxygen7 Lite';
  static const String _appVersion = 'Version 3.0';
  static const String _poweredBy = 'Powered by Oxygen7';

  @override
  Widget build(BuildContext context) {
    // Attempt .tr translation; fall back to hardcoded English strings.
    final String title = _safeTranslate('securityWarning', _fallbackTitle);
    final String message = _safeTranslate(
      'rootedDeviceBlockedMessage',
      _fallbackMessage,
    );
    final String exitLabel = _safeTranslate('exit', _fallbackExitLabel);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),
                // App logo
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                    ),
                    child: Image.asset(
                      'assets/o7lite/images/oxpay_logo_transparent_background_small.png',
                      width: 72,
                      height: 72,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.lock_outline,
                        size: 72,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // App name
                const Text(
                  _appName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Warning title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 24, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Warning message
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Exit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => SystemNavigator.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      exitLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Footer: version + powered by
                Text(
                  _appVersion,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _poweredBy,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Safely attempts GetX translation; returns [fallback] if translation
  /// framework is not initialized or key is missing.
  String _safeTranslate(String key, String fallback) {
    try {
      final translated = key.tr;
      // If .tr returns the key itself, translations aren't loaded.
      if (translated == key) return fallback;
      return translated;
    } catch (_) {
      return fallback;
    }
  }
}
