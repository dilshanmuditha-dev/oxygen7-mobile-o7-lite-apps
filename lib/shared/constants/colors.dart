import 'package:flutter/material.dart';

class ColorConstants {
  static Color lightScaffoldBackgroundColor = hexToColor('#F9F9F9');
  static Color darkScaffoldBackgroundColor = hexToColor('#2F2E2E');
  static Color hyperlinkColor = hexToColor('#0000EE');
  static Color secondaryAppColor = hexToColor('#22DDA6');
  static Color secondaryDarkAppColor = Colors.white;
  static Color tipColor = hexToColor('#B6B6B6');
  static Color lightGray = const Color(0xFFF6F6F6);
  static Color darkGray = const Color(0xFF9F9F9F);
  static Color black = const Color(0xFF000000);
  static Color blackText = const Color.fromARGB(255, 17, 17, 17);
  static Color white = const Color(0xFFFFFFFF);
  static Color colorFullTextField = const Color(0xFFF5F5FF);
  static Color colorBorderTextField = const Color(0xFFEAE6F0);
  static Color colorBorderTextFieldBold = Color.fromARGB(255, 215, 196, 244);
  static Color red = Colors.red;
  static Color orangerRewardColor = const Color(0xFFF88344);
  static Color greenLightRewardColor = const Color(0xFF2BD2AB);
  static Color greenRewardColor = const Color(0XFF94E059);
  static Color purpleRewardColor = const Color(0XFF8989D6);
  static Color yellowRewardColor = const Color(0XFFFFAD0E);
  static Color lightBlueRewardColor = const Color(0XFF5C9CE4);
  static Color colorBackgroundDigital = const Color(0XFFF0F0FF);
  static Color colorBackgroundDigitalRed = const Color(0XFFfeedee);
  static var primaryColor = const Color(0xff296e48);
  static var greenColorText = const Color(0xff52C41A);
  static var greenColorBoder = const Color(0xfff1faed);
  static var blackColor = Colors.black54;
  static Color backgroundColor = const Color(0xFFF5F5F5);
  static Color backgroundColorButtonBlue = const Color(0xFF0256D9);
  static Color backgroundColorButtonPrint = const Color(0xFF635BFF);
  static Color backgroundColorButtonRefund = const Color(0xFFAAACBD);
  static var grey800 = Colors.grey[800];
  static Color colorDarkModeBlue = const Color(0xFF5C9CE4);
  static Color colorDarkModeDisable = const Color(0xFF262626);
  static Color colorDoubleShooting = const Color(0xFFF5F5FF);
  static Color colorGradientNext = const Color(0xFF9d99ff);
  static Color colorGradientFirst = const Color(0xFF635BFF);

  static const Color kPrimaryColor = Color(0xFF0043AB);
  static const Color kPrimaryLightColor = Color(0xFFF1E6FF);
  static const Color nearlyDarkBlue = Color(0xFF2633C5);
  static const Color nearlyWhite = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF3A5160);
  static const Color darkerText = Color(0xFF17262A);
  static const Color nearlyBlue = Color(0xFF00B6F0);
  static const Color nearlyBlack = Color(0xFF213333);
  static const Color greenColor = Color(0xff00FF00);
  static const Color greyColor = Color(0xffC0C0C0);
  static const Color redColor = Color(0xffFF0000);
  static const Color lightGreenColor = Color(0xFF94E059);
  static const Color orangeColor = Color(0xFFFF5630);
  static const Color lightBlueColor = Color(0xFF5C9CE4);
  static const Color secondaryColor = Color(0xffa250c4);
  static const Color bottomSelectedColor = Color(0xFF2B4A98);
}

Color hexToColor(String hex) {
  assert(RegExp(r'^#([0-9a-fA-F]{6})|([0-9a-fA-F]{8})$').hasMatch(hex),
      'hex color must be #rrggbb or #rrggbbaa');

  return Color(
    int.parse(hex.substring(1), radix: 16) +
        (hex.length == 7 ? 0xff000000 : 0x00000000),
  );
}
