// ignore_for_file: must_be_immutable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../app_controller.dart';
import '../../theme/theme_helper.dart';
import '../constants/colors.dart';
import '../utils/responsive_util.dart';
import 'custom_text_style.dart';

class InputField extends StatelessWidget {
  final void Function(String?)? onSaved;

  final String hintText;
  final String? icon;
  final bool obscureText;
  final bool? enableTexfield;
  final bool? isBorder;
  final Color? leadingIconColor;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final IconButton? iconButton;
  final Widget? suffixIcon;
  final String? initValue;
  final void Function(String)? onChanged;
  final bool digitsOnly;
  final double? paddingIcon;
  bool validate = false;
  bool checkBackgroundColorTextfield;
  String? counterText;
  List<TextInputFormatter>? inputFormatters;
  int? maxLength;

  InputField({
    Key? key,
    required this.hintText,
    this.icon,
    this.leadingIconColor,
    this.obscureText = false,
    this.enableTexfield = true,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.onSaved,
    this.focusNode,
    this.isBorder,
    this.validator,
    this.iconButton,
    this.suffixIcon,
    this.initValue,
    this.inputFormatters,
    this.onChanged,
    this.digitsOnly = false,
    this.paddingIcon,
    this.counterText,
    this.checkBackgroundColorTextfield = false,
    this.maxLength,
  }) : super(key: key);

  PrimaryColors get appTheme => ThemeHelper().themeColor();
  final AppController appController = Get.find();

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      validator: validator,
      keyboardType: digitsOnly ? TextInputType.number : keyboardType,
      textInputAction: textInputAction,
      cursorColor: ColorConstants.kPrimaryColor,
      controller: controller,
      onSaved: onSaved,
      focusNode: focusNode,
      obscureText: obscureText,
      initialValue: initValue,
      style: TextStyle(
        fontSize: ResponsiveUtil().getFontSize(
          16,
        ),
        color: appController.isDarkModeOn.value
            ? ColorConstants.white
            : ColorConstants.black,
      ),
      decoration: InputDecoration(
        errorStyle: CustomTextStyles.labelRed400Size12Fw400,
        suffixIconConstraints:
            const BoxConstraints(maxHeight: 60, maxWidth: 60),
        contentPadding: ResponsiveUtil().getPadding(all: 10),
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: CustomTextStyles.labelGray600Size16Fw400,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(
            width: 1,
            color: ColorConstants.colorBorderTextFieldBold,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(width: 1, color: ColorConstants.red),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(width: 1, color: ColorConstants.red),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide:
              BorderSide(width: 1, color: ColorConstants.colorBorderTextField),
        ),
        filled: true,
        counterText: counterText,
        fillColor: checkBackgroundColorTextfield == true
            ? appController.isDarkModeOn.value
                ? ColorConstants.grey800
                : ColorConstants.white
            : appController.isDarkModeOn.value
                ? ColorConstants.grey800
                : ColorConstants.colorFullTextField,
      ),
      enabled: enableTexfield,
      maxLength: maxLength,
    );
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;

  DecimalTextInputFormatter({this.decimalRange = 2});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String newText = newValue.text.replaceAll(',', '.');

    if (newText == '.') {
      return newValue.copyWith(text: '0.');
    }

    // Allow only digits and a single dot
    final regex = RegExp(r'^\d*\.?\d{0,' + decimalRange.toString() + r'}$');
    if (regex.hasMatch(newText)) {
      return newValue.copyWith(text: newText, selection: newValue.selection);
    }

    return oldValue;
  }
}

class EmailTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(RegExp(r'[^a-zA-Z0-9@.]'), '');
    return newValue.copyWith(text: newText);
  }
}

class PhoneNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    return newValue.copyWith(text: newText);
  }
}

class AlphaNumericTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return newValue.copyWith(text: newText);
  }
}
