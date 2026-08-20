import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/constants/colors.dart';
import '../../shared/utils/responsive_util.dart';
import '../../shared/constants/image_constant.dart';
import '../../shared/constants/common.dart';
import '../../app_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CreateAccountController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxString emailError = ''.obs;
  final RxString passwordError = ''.obs;
  final RxString confirmPasswordError = ''.obs;
  final RxBool isFormValid = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;

  // Password rules
  final RxBool isPassword8Char = false.obs;
  final RxBool isPasswordUpperLower = false.obs;
  final RxBool isPasswordDigit = false.obs;
  final RxBool isPasswordNoWhitespace = false.obs;

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(_validateForm);
    passwordController.addListener(_validateForm);
    passwordController.addListener(_validatePasswordRules);
    confirmPasswordController.addListener(_validateForm);
  }

  void _validatePasswordRules() {
    final value = passwordController.text;
    isPassword8Char.value = value.length >= 8;
    isPasswordUpperLower.value =
        RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(value);
    isPasswordDigit.value = RegExp(r'(?=.*\d)').hasMatch(value);
    isPasswordNoWhitespace.value = !RegExp(r'\s').hasMatch(value);
  }

  void _validateForm() {
    emailError.value = _validateEmail(emailController.text) ?? '';
    passwordError.value = _validatePassword(passwordController.text) ?? '';
    confirmPasswordError.value =
        _validateConfirmPassword(confirmPasswordController.text) ?? '';
    isFormValid.value = emailError.value.isEmpty &&
        passwordError.value.isEmpty &&
        confirmPasswordError.value.isEmpty &&
        emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        isPassword8Char.value &&
        isPasswordUpperLower.value &&
        isPasswordDigit.value &&
        isPasswordNoWhitespace.value;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return CommonConstants.authEmailRequired.tr;
    }
    if (!GetUtils.isEmail(value)) {
      return CommonConstants.authInvalidEmail.tr;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return CommonConstants.passwordIsRequired.tr;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return CommonConstants.authConfirmPasswordRequired.tr;
    }
    if (value != passwordController.text) {
      return CommonConstants.authPasswordsDoNotMatch.tr;
    }
    return null;
  }

  Future<void> submit() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 2));
    isLoading.value = false;
    Get.back();
    Get.snackbar(
        CommonConstants.success.tr, CommonConstants.msgAccountCreatedSuccess.tr,
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}

class CreateAccountScreen extends GetView<CreateAccountController> {
  const CreateAccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveUtil().init(context);
    final node = FocusScope.of(context);
    final appController = Get.find<AppController>();
    final isDark = appController.isDarkModeOn.value;
    final bgColor =
        isDark ? ColorConstants.darkScaffoldBackgroundColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark
        ? ColorConstants.grey800 ?? Colors.grey
        : const Color(0xFFBDBDBD);
    final hintColor = isDark ? Colors.white70 : const Color(0xFF757575);
    final fillColor =
        isDark ? ColorConstants.grey800 ?? Colors.grey[900]! : Colors.white;
    final errorColor = Colors.red;
    final ruleTextColor = isDark ? Colors.white : const Color(0xFF222222);
    final ruleCheckColor = const Color(0xFF22C55E);
    final ruleXColor = const Color(0xFFF04438);
    final buttonColor = const Color(0xFF7E01D7);
    final signInTextColor = buttonColor;
    final subTextColor = isDark ? Colors.white54 : const Color(0xFFBDBDBD);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: () => Get.back(),
                ),
              ),
              // const Center(
              //   child: Text(
              //     'Create Account',
              //     style: TextStyle(
              //       color: Colors.black,
              //       fontWeight: FontWeight.w700,
              //       fontSize: 20,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // const SizedBox(height: 32),
                        // Logo
                        Center(
                          child: Container(
                            // margin: EdgeInsets.only(
                            //     top: ResponsiveUtil().getSize(0)),
                            child: SvgPicture.asset(
                              ImageConstant.oxpayIconTransparentBackgroundSvg,
                              fit: BoxFit.contain,
                              width: ResponsiveUtil().getSize(166),
                              height: ResponsiveUtil().getSize(76),
                              color: isDark ? Colors.white : null,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveUtil().getSize(40),
                        ),
                        Text(
                          CommonConstants.authCreateAccount.tr,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Obx(() => Column(
                              children: [
                                _buildTextField(
                                  controller: controller.emailController,
                                  hintText: CommonConstants.emailLabel.tr,
                                  keyboardType: TextInputType.emailAddress,
                                  errorText: controller.emailError.value,
                                  onEditingComplete: () => node.nextFocus(),
                                  textColor: textColor,
                                  borderColor: borderColor,
                                  fillColor: fillColor,
                                  hintColor: hintColor,
                                  errorColor: errorColor,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: controller.passwordController,
                                  hintText: CommonConstants.password.tr,
                                  obscureText:
                                      !controller.isPasswordVisible.value,
                                  errorText: controller.passwordError.value,
                                  onEditingComplete: () => node.nextFocus(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      controller.isPasswordVisible.value
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: hintColor,
                                    ),
                                    onPressed: () =>
                                        controller.isPasswordVisible.toggle(),
                                  ),
                                  textColor: textColor,
                                  borderColor: borderColor,
                                  fillColor: fillColor,
                                  hintColor: hintColor,
                                  errorColor: errorColor,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller:
                                      controller.confirmPasswordController,
                                  hintText:
                                      CommonConstants.authConfirmPassword.tr,
                                  obscureText: !controller
                                      .isConfirmPasswordVisible.value,
                                  errorText:
                                      controller.confirmPasswordError.value,
                                  onEditingComplete: () => node.unfocus(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      controller.isConfirmPasswordVisible.value
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: hintColor,
                                    ),
                                    onPressed: () => controller
                                        .isConfirmPasswordVisible
                                        .toggle(),
                                  ),
                                  textColor: textColor,
                                  borderColor: borderColor,
                                  fillColor: fillColor,
                                  hintColor: hintColor,
                                  errorColor: errorColor,
                                ),
                                const SizedBox(height: 18),
                                _PasswordRuleBlock(
                                  controller: controller,
                                  textColor: ruleTextColor,
                                  checkColor: ruleCheckColor,
                                  xColor: ruleXColor,
                                ),
                              ],
                            )),
                        const Spacer(),
                        Obx(() => Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: controller.isFormValid.value &&
                                            !controller.isLoading.value
                                        ? controller.submit
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: buttonColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(80),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: controller.isLoading.value
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(
                                            CommonConstants
                                                .authCreateAccount.tr,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      CommonConstants.authAlreadyHaveAccount.tr,
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 15,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        CommonConstants.btnSignIn.tr,
                                        style: TextStyle(
                                          color: signInTextColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? errorText,
    VoidCallback? onEditingComplete,
    Widget? suffixIcon,
    required Color textColor,
    required Color borderColor,
    required Color fillColor,
    required Color hintColor,
    required Color errorColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onEditingComplete: onEditingComplete,
          style: TextStyle(fontSize: 16, color: textColor),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
                color: hintColor, fontSize: 16, fontWeight: FontWeight.w400),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: borderColor == Colors.white
                      ? const Color(0xFF7E01D7)
                      : borderColor,
                  width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 1),
            ),
            filled: true,
            fillColor: fillColor,
            errorStyle: TextStyle(fontSize: 13, color: errorColor, height: 1.2),
            suffixIcon: suffixIcon,
          ),
        ),
        if (errorText != null && errorText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              errorText,
              style: TextStyle(fontSize: 13, color: errorColor, height: 1.2),
            ),
          ),
      ],
    );
  }
}

class _PasswordRuleBlock extends StatelessWidget {
  final CreateAccountController controller;
  final Color textColor;
  final Color checkColor;
  final Color xColor;
  const _PasswordRuleBlock(
      {required this.controller,
      required this.textColor,
      required this.checkColor,
      required this.xColor});

  Widget _buildItem(bool valid, String text) {
    return Row(
      children: [
        Icon(
          valid ? Icons.check_circle : Icons.cancel,
          color: valid ? checkColor : xColor,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CommonConstants.authPasswordMustHave.tr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            _buildItem(controller.isPassword8Char.value,
                CommonConstants.authRule8Characters.tr),
            _buildItem(controller.isPasswordUpperLower.value,
                CommonConstants.authRuleUpperLower.tr),
            _buildItem(controller.isPasswordDigit.value,
                CommonConstants.authRuleNumericDigit.tr),
            _buildItem(controller.isPasswordNoWhitespace.value,
                CommonConstants.authRuleNoWhitespace.tr),
          ],
        ));
  }
}
