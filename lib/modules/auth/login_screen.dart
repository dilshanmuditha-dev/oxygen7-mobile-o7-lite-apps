// ignore_for_file: deprecated_member_use

import 'package:app/app_controller.dart';
import 'package:app/lang/translation_service.dart';
import 'package:app/shared/constants/image_constant.dart';
import 'package:app/shared/utils/responsive_util.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../shared/constants/colors.dart';
import '../../shared/constants/common.dart';
import '../../shared/services/login_deep_link_service.dart';
import '../../shared/utils/regex.dart';

import '../../shared/widgets/icon_button_custom.dart';
import '../../shared/widgets/input_field.dart';
import 'auth_controller.dart';

class LoginScreen extends GetView<AuthController> {
  LoginScreen({Key? key}) : super(key: key);

  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final AppController appController = Get.find();
    ResponsiveUtil().init(context);

    if (Get.isRegistered<LoginDeepLinkService>() &&
        Get.find<LoginDeepLinkService>().hasPendingCredentials) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Get.find<LoginDeepLinkService>()
              .submitPendingCredentials(controller, context);
        }
      });
    } else if (Get.isRegistered<LoginDeepLinkService>() &&
        Get.find<LoginDeepLinkService>().hasPendingError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Get.find<LoginDeepLinkService>().showPendingErrorIfAny();
        }
      });
    }

    return WillPopScope(
      onWillPop: () async => true,
      child: GestureDetector(
        onTap: controller.hideKeyboard,
        child: Obx(
          () => Scaffold(
            resizeToAvoidBottomInset: false, // Keep language button at bottom
            backgroundColor: appController.isDarkModeOn.value
                ? ColorConstants.darkScaffoldBackgroundColor
                : Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  // Main content area
                  Expanded(
                    child: Stack(
                      children: [
                        Padding(
                          padding: ResponsiveUtil().getPadding(
                            left: 16,
                            right: 16,
                          ),
                          child: Form(
                            key: loginFormKey,
                            child: SingleChildScrollView(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Logo
                                  Center(
                                    child: Container(
                                      margin: EdgeInsets.only(
                                          top: ResponsiveUtil().getSize(80)),
                                      child: SvgPicture.asset(
                                        ImageConstant
                                            .oxygen7IconTransparentBackgroundSvg,
                                        fit: BoxFit.contain,
                                        width: ResponsiveUtil().getSize(166),
                                        height: ResponsiveUtil().getSize(76),
                                        color: appController.isDarkModeOn.value
                                            ? Colors.white
                                            : null,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: ResponsiveUtil().getSize(40),
                                  ),
                                  // Security warning banner for forced logout
                                  Obx(() => controller.isSecurityLogout.value
                                      ? _buildSecurityWarningBanner(
                                          appController)
                                      : const SizedBox.shrink()),
                                  SizedBox(
                                    height: ResponsiveUtil().getSize(16),
                                  ),
                                  // Sign In Text
                                  Text(
                                    CommonConstants.btnSignIn.tr,
                                    style: TextStyle(
                                      fontFamily: 'IBM Plex Sans',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24,
                                      color: appController.isDarkModeOn.value
                                          ? Colors.white
                                          : const Color(0xFF382F41),
                                    ),
                                  ),
                                  SizedBox(
                                    height: ResponsiveUtil().getSize(24),
                                  ),
                                  // OxPay TID Input Field
                                  InputField(
                                    counterText: '',
                                    controller: controller.loginTIDController,
                                    hintText: CommonConstants.oxpayTID.tr,
                                    focusNode: controller.tidFocus,
                                    maxLength: 23,
                                    checkBackgroundColorTextfield: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return CommonConstants.tidIsRequired.tr;
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(
                                    height: ResponsiveUtil().getSize(16),
                                  ),
                                  // Password Input Field
                                  Obx(
                                    () => InputField(
                                      controller:
                                          controller.loginPasswordController,
                                      hintText: CommonConstants.password.tr,
                                      checkBackgroundColorTextfield: true,
                                      suffixIcon: IconButtonCustom(
                                        onPressed: () =>
                                            controller.togglePasswordVisibility(
                                                controller.isPasswordVisible),
                                        child: Padding(
                                          padding: ResponsiveUtil()
                                              .getPadding(right: 12),
                                          child: Icon(
                                            controller.isPasswordVisible.value
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color:
                                                appController.isDarkModeOn.value
                                                    ? Colors.white
                                                    : const Color(0xFF382F41),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      obscureText:
                                          controller.isPasswordVisible.value,
                                      focusNode: controller.passwordFocus,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return CommonConstants
                                              .passwordIsRequired.tr;
                                        }
                                        if (!Regex.isPasswordAtLeast6Characters(
                                            value)) {
                                          return CommonConstants
                                              .textErrorPassword.tr;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                      height: ResponsiveUtil().getSize(16)),
                                  // Remember TID Checkbox
                                  Obx(
                                    () => GestureDetector(
                                      onTap: () {
                                        controller.toggleCheckBox(!controller
                                            .isRememberTidChecked.value);
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Container(
                                            height:
                                                ResponsiveUtil().getSize(18),
                                            width: ResponsiveUtil().getSize(18),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: (appController
                                                            .isDarkModeOn.value
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF382F41))
                                                    .withOpacity(0.15),
                                                width: 1,
                                              ),
                                              color: controller
                                                      .isRememberTidChecked
                                                      .value
                                                  ? const Color(0xFF7E01D7)
                                                  : Colors.transparent,
                                            ),
                                            child: controller
                                                    .isRememberTidChecked.value
                                                ? const Icon(
                                                    Icons.check,
                                                    size: 14,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                          SizedBox(
                                              width:
                                                  ResponsiveUtil().getSize(8)),
                                          Text(
                                            CommonConstants.rememberTID.tr,
                                            style: TextStyle(
                                              fontFamily: 'Open Sans',
                                              fontWeight: FontWeight.w400,
                                              fontSize: 14,
                                              color: appController
                                                      .isDarkModeOn.value
                                                  ? Colors.white
                                                  : const Color(0xFF382F41),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      height: ResponsiveUtil().getSize(40)),
                                  // Sign In Button
                                  ElevatedButton(
                                    onPressed: () {
                                      if (loginFormKey.currentState!
                                          .validate()) {
                                        controller.login(context);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7E01D7),
                                      minimumSize: Size(double.infinity,
                                          ResponsiveUtil().getSize(56)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(80),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      CommonConstants.btnSignIn.tr,
                                      style: const TextStyle(
                                        fontFamily: 'Open Sans',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      height: ResponsiveUtil().getSize(16)),
                                  // Create Account Text
                                  // Center(
                                  //   child: InkWell(
                                  //     onTap: () => controller.navigateToSignUp(),
                                  //     child: Text(
                                  //       CommonConstants.createAccount.tr,
                                  //       style: TextStyle(
                                  //         fontFamily: 'Open Sans',
                                  //         fontWeight: FontWeight.w400,
                                  //         fontSize: 14,
                                  //         color: appController.isDarkModeOn.value
                                  //             ? Colors.white
                                  //             : const Color(0xFF382F41),
                                  //       ),
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Dark Mode Toggle
                        Positioned(
                          top: 16,
                          right: 16,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(200),
                            onTap: appController.toggleDarkMode,
                            // onLongPress: () =>
                            // throw Exception('Johnny Test Crash!!!'),
                            child: Obx(
                              () => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  appController.isDarkModeOn.value
                                      ? Icons.light_mode
                                      : Icons.dark_mode,
                                  color: appController.isDarkModeOn.value
                                      ? Colors.white
                                      : const Color(0xFF382F41),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Language Selector - Fixed at bottom of Column
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              _showLanguageBottomSheet(context, appController),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: appController.isDarkModeOn.value
                                  ? Colors.white.withOpacity(0.08)
                                  : const Color(0xFFF5F3F7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  controller.selectedApp.value.split('  ')[0],
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  controller.selectedApp.value
                                              .split('  ')
                                              .length >
                                          1
                                      ? controller.selectedApp.value
                                          .split('  ')[1]
                                      : controller.selectedApp.value,
                                  style: TextStyle(
                                    fontFamily: 'Open Sans',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: appController.isDarkModeOn.value
                                        ? Colors.white.withOpacity(0.9)
                                        : const Color(0xFF382F41),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.expand_more_rounded,
                                  color: appController.isDarkModeOn.value
                                      ? Colors.white.withOpacity(0.5)
                                      : const Color(0xFF382F41)
                                          .withOpacity(0.35),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityWarningBanner(AppController appController) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF9800), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFFE65100), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              CommonConstants.securitySessionTerminated.tr,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: const Color(0xFFE65100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show language selection bottom sheet
  void _showLanguageBottomSheet(
      BuildContext context, AppController appController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: appController.isDarkModeOn.value
                ? ColorConstants.darkScaffoldBackgroundColor
                : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appController.isDarkModeOn.value
                      ? Colors.white.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CommonConstants.selectLanguage.tr,
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: appController.isDarkModeOn.value
                            ? Colors.white
                            : const Color(0xFF382F41),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: appController.isDarkModeOn.value
                            ? Colors.white
                            : const Color(0xFF382F41),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Language list
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.listApps.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: appController.isDarkModeOn.value
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFFEEEEEE),
                  ),
                  itemBuilder: (context, index) => _buildLanguageOption(
                    context,
                    controller.listApps[index],
                    controller.listSetLocate[index],
                    controller.selectedApp.value == controller.listApps[index],
                    appController,
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Build individual language option
  Widget _buildLanguageOption(
    BuildContext context,
    String language,
    String locale,
    bool isSelected,
    AppController appController,
  ) {
    return InkWell(
      onTap: () async {
        await controller.saveLanguageSelection(language);
        TranslationService.changeLocale(locale);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          children: [
            // Language display with flag emoji
            Expanded(
              child: Text(
                language,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: appController.isDarkModeOn.value
                      ? Colors.white
                      : const Color(0xFF382F41),
                ),
              ),
            ),

            // Radio button selection indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF7E01D7)
                      : (appController.isDarkModeOn.value
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.5)),
                  width: 2,
                ),
                color:
                    isSelected ? const Color(0xFF7E01D7) : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.circle,
                        color: Colors.white,
                        size: 8,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
