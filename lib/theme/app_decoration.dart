import 'package:flutter/material.dart';
import '../shared/constants/colors.dart';
import '../shared/utils/responsive_util.dart';
import 'theme_helper.dart';

class AppDecoration {
  static BoxDecoration get fill => BoxDecoration(
        color: appTheme.gray100,
      );
  static BoxDecoration get fill4 => BoxDecoration(
        color: theme.colorScheme.inverseSurface,
      );
  static BoxDecoration get fill1 => BoxDecoration(
        color: theme.colorScheme.onPrimary,
      );
  static BoxDecoration get fill3 => BoxDecoration(
        color: appTheme.gray300,
      );
  static BoxDecoration get outline => BoxDecoration(
        color: ColorConstants.kPrimaryColor,
        border: Border.all(
          color: theme.colorScheme.onPrimary,
          width: ResponsiveUtil().getHorizontalSize(2),
          strokeAlign: strokeAlignOutside,
        ),
      );

  static BoxDecoration get fill2 => BoxDecoration(
        color: theme.colorScheme.primary,
      );
  static BoxDecoration get txtFill => const BoxDecoration(
        color: ColorConstants.kPrimaryColor,
      );
}

class BorderRadiusStyle {
  static BorderRadius roundedBorder16 = BorderRadius.circular(
    ResponsiveUtil().getHorizontalSize(
      16,
    ),
  );

  static BorderRadius circleBorder24 = BorderRadius.circular(
    ResponsiveUtil().getHorizontalSize(
      24,
    ),
  );

  static BorderRadius circleBorder10 = BorderRadius.circular(
    ResponsiveUtil().getHorizontalSize(
      10,
    ),
  );

  static BorderRadius circleBorder32 = BorderRadius.circular(
    ResponsiveUtil().getHorizontalSize(
      32,
    ),
  );

  static BorderRadius roundedBorder20 = BorderRadius.circular(
    ResponsiveUtil().getHorizontalSize(
      20,
    ),
  );

  static BorderRadius txtRoundedBorder8 = BorderRadius.circular(
    ResponsiveUtil().getHorizontalSize(
      8,
    ),
  );
}

// Comment/Uncomment the below code based on your Flutter SDK version.

// For Flutter SDK Version 3.7.2 or greater.

double get strokeAlignInside => BorderSide.strokeAlignInside;

double get strokeAlignCenter => BorderSide.strokeAlignCenter;

double get strokeAlignOutside => BorderSide.strokeAlignOutside;

// For Flutter SDK Version 3.7.1 or less.

// StrokeAlign get strokeAlignInside => StrokeAlign.inside;
//
// StrokeAlign get strokeAlignCenter => StrokeAlign.center;
//
// StrokeAlign get strokeAlignOutside => StrokeAlign.outside;
