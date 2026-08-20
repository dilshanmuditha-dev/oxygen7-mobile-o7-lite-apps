import 'package:app/shared/utils/responsive_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app_controller.dart';
import '../../theme/theme_helper.dart';
import '../constants/colors.dart';

class AppDecoration {
  static AppController appController = Get.find();

  static BoxDecoration get fill => BoxDecoration(
        color: appTheme.gray100,
      );
  static BoxDecoration get fill1 => BoxDecoration(
        color: appTheme.blue900,
      );
  static BoxDecoration get fillBlue => BoxDecoration(
        color: appTheme.blue100,
      );
  static BoxDecoration get fill12 => BoxDecoration(
        color: theme.colorScheme.onPrimary,
      );
  static BoxDecoration get outlineGray => BoxDecoration(
        color: appTheme.whiteA700,
        border: Border.all(
          color: appTheme.gray300,
          width: ResponsiveUtil().getHorizontalSize(1),
        ),
      );
  static BoxDecoration get fillGray90099 => BoxDecoration(
        color: appTheme.gray90099,
      );
  static BoxDecoration get fill13 => BoxDecoration(
        color: appTheme.blue900,
      );

  static BoxDecoration get fillWhiteA => BoxDecoration(
        color: appTheme.whiteA700,
      );
  static BoxDecoration get outlineBlue => BoxDecoration(
        border: Border.all(
          color: appTheme.blue900,
          width: ResponsiveUtil().getHorizontalSize(1),
        ),
      );
  static BoxDecoration get gradientBlueToBlue => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0.5, 0),
          end: const Alignment(0.5, 1),
          colors: [
            appTheme.blue900,
            appTheme.blue600,
          ],
        ),
      );
  static BoxDecoration get outline => BoxDecoration(
        color: appTheme.blue900,
        boxShadow: [
          BoxShadow(
            color: appTheme.black900.withOpacity(0.04),
            spreadRadius: ResponsiveUtil().getHorizontalSize(
              2,
            ),
            blurRadius: ResponsiveUtil().getHorizontalSize(
              2,
            ),
            offset: const Offset(
              0,
              2,
            ),
          ),
        ],
      );
  static BoxDecoration get fill3 => BoxDecoration(
        color: appTheme.blueGray100,
      );
  static BoxDecoration get fill2 => BoxDecoration(
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : ColorConstants.nearlyWhite,
      );
  static BoxDecoration get txtOutline => BoxDecoration(
        color: appTheme.blue900,
        border: Border.all(
          color: appTheme.whiteA700,
          width: ResponsiveUtil().getHorizontalSize(
            2,
          ),
          strokeAlign: strokeAlignOutside,
        ),
      );
  static BoxDecoration get txtFill => BoxDecoration(
        color: appTheme.blue900,
      );

  static BoxDecoration get txtTransparent => const BoxDecoration(
        color: Colors.transparent,
      );
}

class BorderRadiusStyle {
  static BorderRadius circleBorder22 = BorderRadius.circular(
    ResponsiveUtil().getHorizontalSize(
      22,
    ),
  );
  static BorderRadius get circleBorder30 => BorderRadius.circular(
        ResponsiveUtil().getHorizontalSize(30),
      );
  static BorderRadius roundedBorder16 = BorderRadius.circular(
    ResponsiveUtil().getHorizontalSize(
      16,
    ),
  );
  static BorderRadius get roundedBorder8 => BorderRadius.circular(
        ResponsiveUtil().getHorizontalSize(8),
      );
  static BorderRadius circleBorder12 = BorderRadius.circular(
    ResponsiveUtil().getHorizontalSize(
      12,
    ),
  );
  static BorderRadius get roundedBorder20 => BorderRadius.circular(
        ResponsiveUtil().getHorizontalSize(20),
      );
  static BorderRadius txtCircleBorder20 = BorderRadius.circular(
    ResponsiveUtil().getHorizontalSize(
      20,
    ),
  );

  static BorderRadius txtRoundedBorder8 = BorderRadius.circular(
    ResponsiveUtil().getHorizontalSize(
      8,
    ),
  );

  static BorderRadius circleBorder10 = BorderRadius.circular(
    ResponsiveUtil().getHorizontalSize(
      10,
    ),
  );
}

double get strokeAlignInside => BorderSide.strokeAlignInside;

double get strokeAlignCenter => BorderSide.strokeAlignCenter;

double get strokeAlignOutside => BorderSide.strokeAlignOutside;
