// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:app/app_controller.dart';
import 'package:app/modules/main/home_controller.dart';
import 'package:app/shared/secure_shared_preferences/secure_shared_preferences.dart';
import 'package:app/shared/utils/enum/app_dialog_type.dart';
import 'package:app/shared/widgets/common_widget.dart';
import 'package:app/shared/widgets/custom_dialog/custom_dialog.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/constants/common.dart';
import '../../../shared/secure_shared_preferences/sharepreference.dart';
import '../../../shared/utils/animation/animation_style.dart' as app_animation;

class AppSettingController extends GetxController {
  AppController appController = Get.find();

  RxBool isEnableAppAnimation = false.obs;
  RxBool isEnableRefundPassword = true.obs;
  RxBool isEnableSound = false.obs;
  RxBool isEnableRefreshInterval = false.obs;
  RxBool isEnableEmailReceipt = false.obs;
  RxBool isEnableEmailCC = false.obs;

  RxBool isOpenDropdown = false.obs;
  RxBool isMobileUser = false.obs;

  RxString selectedApp = 'cashier'.obs;
  RxString selectedSound = 'o7lite/sound/cashier_sound.mp3'.obs;
  RxString selectedAnimationStyle = 'wave'.obs;

  List<Map<String, String>> appWithSound = [
    {
      'name': 'cashier',
      'sound': 'o7lite/sound/cashier_sound.mp3',
    },
    {
      'name': 'bonus',
      'sound': 'o7lite/sound/bonus_sound.mp3',
    },
    {
      'name': 'coins',
      'sound': 'o7lite/sound/coin_sound.mp3',
    },
    {
      'name': 'soundSuccess',
      'sound': 'o7lite/sound/success_sound.mp3',
    },
    {
      'name': 'tick',
      'sound': 'o7lite/sound/tick_sound.mp3',
    },
  ];

  RxString selectedNameRefreshInterval = '10s'.obs;
  RxString selectedInterval = '10'.obs;
  List<Map<String, String>> refreshInterval = [
    {
      'namerefresh': '10s',
      'interval': '10',
    },
    {
      'namerefresh': '15s',
      'interval': '15',
    },
    {
      'namerefresh': '30s',
      'interval': '30',
    },
    {
      'namerefresh': '60s',
      'interval': '60',
    },
  ];

  List<String> get listApps => appWithSound.map((e) => e['name']!).toList();
  List<String> get listSound => appWithSound.map((e) => e['sound']!).toList();

  List<String> get listNameRefreshInterval =>
      refreshInterval.map((e) => e['namerefresh']!).toList();
  List<String> get listInterval =>
      refreshInterval.map((e) => e['interval']!).toList();
  late AudioPlayer player = AudioPlayer();

  final carplateNumberController = TextEditingController();
  final serviceChargeRateController = TextEditingController();

  final FocusNode carplateNumberFocus = FocusNode();
  final FocusNode serviceChargeRateFocus = FocusNode();

  final GlobalKey<FormState> carplateNumberFormKey = GlobalKey<FormState>();
  final HomeController homeController = Get.find();

  final GlobalKey<FormState> currentPasswordFormKey = GlobalKey<FormState>();
  TextEditingController currentPasswordController = TextEditingController();
  RxBool isPasswordVisible = true.obs;

  final emailCCController = TextEditingController();
  final FocusNode emailCCFocusNode = FocusNode();

  @override
  void onInit() async {
    super.onInit();

    // Run getAppSettings and SecureSharedPreferences reads in parallel
    final settingsFuture = getAppSettings();
    final secureResults = await Future.wait([
      SecureSharedPreferences.instance.getServiceChargeRate(),
      SecureSharedPreferences.instance.getCarplaceNumber(),
      SecureSharedPreferences.instance.getEmailCC(),
    ]);

    // Wait for getAppSettings to complete
    await settingsFuture;

    serviceChargeRateController.text = (secureResults[0] ?? 0).toString();
    carplateNumberController.text = (secureResults[1] as String?) ?? '';
    emailCCController.text = (secureResults[2] as String?) ?? '';

    player = AudioPlayer();
  }

  void onChanged(String? newValue) {
    selectedApp.value = newValue!;
    selectedSound.value = appWithSound.firstWhere(
      (element) => element['name'] == newValue,
      orElse: () => {'sound': ''},
    )['sound']!;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Platform.isAndroid) {
        await player.setVolume(0.5);
      }
      await player.setAsset('assets/' + selectedSound.value);
      await player.play();
    });
  }

  void onChangedInterval(String? newValue) {
    selectedNameRefreshInterval.value = newValue!;
    selectedInterval.value = refreshInterval.firstWhere(
      (element) => element['namerefresh'] == newValue,
      orElse: () => {'interval': ''},
    )['interval']!;
  }

  void applySettings() async {
    if (carplateNumberFormKey.currentState!.validate()) {
      // save enable refund password
      await SharedPrefManager.instance
          .setBool('isEnableRefundPassword', isEnableRefundPassword.value);

      await SharedPrefManager.instance
          .setBool('isEnableAppAnimation', isEnableAppAnimation.value);

      await SharedPrefManager.instance
          .setString('approveSound', selectedSound.value);

      await SecureSharedPreferences.instance
          .setCarplaceNumber(carplateNumberController.text);

      await SecureSharedPreferences.instance.setEmailCC(emailCCController.text);

      await SecureSharedPreferences.instance
          .setServiceChargeRate(int.parse(serviceChargeRateController.text));

      await homeController.getUserLimoApp();

      CommonWidget.toast(
          error: 'settingsAppliedSuccessfully'.tr,
          isDarkMode: appController.isDarkModeOn.value);
    }
  }

  void enableAppAnimation() async {
    isEnableAppAnimation.toggle();
    await SharedPrefManager.instance
        .setBool('isEnableAppAnimation', isEnableAppAnimation.value);
  }

  getEnableAppAnimation() async {
    isEnableAppAnimation.value =
        await SharedPrefManager.instance.getBool('isEnableAppAnimation') ??
            false;
  }

  /// Loads the selected animation style from local storage.
  ///
  /// If no style is stored, defaults to 'wave'.
  /// _Requirements: 3.4_
  Future<void> getAnimationStyle() async {
    final storedStyle =
        await SharedPrefManager.instance.getString('selectedAnimationStyle');
    if (storedStyle != null) {
      // Validate that the stored value is a valid AnimationStyle
      final isValid = app_animation.AnimationStyle.values
          .any((style) => style.name == storedStyle);
      if (isValid) {
        selectedAnimationStyle.value = storedStyle;
      } else {
        // Invalid stored value, reset to default
        selectedAnimationStyle.value = 'wave';
      }
    } else {
      selectedAnimationStyle.value = 'wave';
    }
  }

  /// Saves the selected animation style to local storage.
  ///
  /// _Requirements: 3.3_
  Future<void> setAnimationStyle(app_animation.AnimationStyle style) async {
    selectedAnimationStyle.value = style.name;
    await SharedPrefManager.instance
        .setString('selectedAnimationStyle', style.name);
  }

  void enableRefundPassword() async {
    CustomDialog.showCustomDialogConfirmPassword(
      isPasswordVisible: isPasswordVisible,
      onPressPassword: () => togglePasswordVisibility(isPasswordVisible),
      formKey: currentPasswordFormKey,
      currentPasswordController: currentPasswordController,
      titleButton: CommonConstants.ok.tr,
      content: 'settingsEnterPasswordToToggleRefund'.tr,
      context: Get.context!,
      onpressCancel: () {
        Get.back();
        currentPasswordController.clear();
      },
      onPressedCheck: () async {
        if (currentPasswordFormKey.currentState!.validate()) {
          Get.back();
          currentPasswordController.clear();

          isEnableRefundPassword.toggle();
          await SharedPrefManager.instance
              .setBool('isEnableRefundPassword', isEnableRefundPassword.value);
        }
      },
      dialogType: AppDialogType.on_off_password,
    );
  }

  void togglePasswordVisibility(RxBool isVisible) =>
      isVisible.value = !isVisible.value;

  getEnableRefundPassword() async {
    isEnableRefundPassword.value =
        await SharedPrefManager.instance.getBool('isEnableRefundPassword') ??
            false;
  }

  void toggleEnableSound() async {
    isEnableSound.toggle();
    await SharedPrefManager.instance
        .setBool('isEnableSound', isEnableSound.value);
  }

  void toggleEnableEmailReceipt() async {
    isEnableEmailReceipt.toggle();
    await SharedPrefManager.instance
        .setBool('isEnableEmailReceipt', isEnableEmailReceipt.value);
  }

  void toggleEnableEmailCC() async {
    isEnableEmailCC.toggle();
    await SharedPrefManager.instance
        .setBool('isEnableEmailCC', isEnableEmailCC.value);
  }

  void toggleEnableMinsec() async {
    appController.isEnableMineSec.toggle();
    await SharedPrefManager.instance
        .setBool('isEnableMinesec', appController.isEnableMineSec.value);
  }

  void toggleEnableRefreshInterval() async {
    isEnableRefreshInterval.toggle();
    await SharedPrefManager.instance
        .setBool('isEnableRefreshInterval', isEnableRefreshInterval.value);
  }

  getAppSettings() async {
    // Fire non-dependent async calls first (don't await yet)
    getEnableRefundPassword();
    getEnableAppAnimation();
    getAnimationStyle();

    // Use cached value from AppController instead of calling Printer.isMobileUser()
    isMobileUser.value = appController.isMobileUser.value;

    // Run all SharedPref reads in parallel for better performance
    final results = await Future.wait([
      SharedPrefManager.instance.getBool('isEnableSound'),
      SharedPrefManager.instance.getBool('isEnableMinesec'),
      SharedPrefManager.instance.getRefreshInterval(),
      SharedPrefManager.instance.getBool('isEnableEmailReceipt'),
      SharedPrefManager.instance.getBool('isEnableEmailCC'),
    ]);

    isEnableSound.value = (results[0] as bool?) ?? false;
    appController.isEnableMineSec.value = (results[1] as bool?) ?? false;
    isEnableRefreshInterval.value = results[2] as bool;
    isEnableEmailReceipt.value = (results[3] as bool?) ?? false;
    isEnableEmailCC.value = (results[4] as bool?) ?? false;
  }

  @override
  void onClose() {
    // player.dispose();
    // carplateNumberFocus.dispose();
    // serviceChargeRateFocus.dispose();
    // carplateNumberController.dispose();
    // serviceChargeRateController.dispose();
    // emailCCController.dispose();
    // emailCCFocusNode.dispose();
    super.onClose();
  }
}
