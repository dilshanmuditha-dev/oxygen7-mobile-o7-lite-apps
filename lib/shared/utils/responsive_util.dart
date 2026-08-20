// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

class ResponsiveUtil {
  late MediaQueryData mediaQueryData;
  ResponsiveUtil._();
  static final ResponsiveUtil _instance = ResponsiveUtil._();
  factory ResponsiveUtil() => _instance;

  static const num FIGMA_DESIGNWIDTH = 428;
  static const num FIGMA_DESIGN_HEIGHT = 926;

  static const num FIGMA_DESIGN_STATUS_BAR = 0;
  late double width = 20;
  late double height;

  void init(BuildContext context) {
    mediaQueryData = MediaQuery.of(context);
    width = mediaQueryData.size.width;
    height = mediaQueryData.size.height;
  }

  double getScaleFactor() {
    if (width <= 320) {
      return 1.5;
    } else if (width <= 375) {
      return 1.2;
    }
    return 1.0;
  }

  double get _height {
    double statusBar = mediaQueryData.viewPadding.top;
    double bottomBar = mediaQueryData.viewPadding.bottom;
    double screenHeight = mediaQueryData.size.height - statusBar - bottomBar;
    return screenHeight;
  }

  double getHorizontalSize(double px) {
    return ((px * width) / FIGMA_DESIGNWIDTH) * getScaleFactor();
  }

  double getVerticalSize(double px) {
    return ((px * _height) /
            (ResponsiveUtil().width == 720.0
                ? 800
                : FIGMA_DESIGN_HEIGHT - FIGMA_DESIGN_STATUS_BAR)) *
        getScaleFactor();
  }

  double getSize(double px) {
    var height = getVerticalSize(px);
    var width = getHorizontalSize(px);
    return height < width ? height.toDoubleValue() : width.toDoubleValue();
  }

  double getFontSize(double px) {
    return getSize(px);
  }

  EdgeInsets getPadding({
    double? all,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return getMarginOrPadding(
      all: all,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  EdgeInsets getMarginOrPadding({
    double? all,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (all != null) {
      left = all;
      top = all;
      right = all;
      bottom = all;
    }
    return EdgeInsets.only(
      left: getHorizontalSize(left ?? 0),
      top: getVerticalSize(top ?? 0),
      right: getHorizontalSize(right ?? 0),
      bottom: getVerticalSize(bottom ?? 0),
    );
  }
}

extension FormatExtension on double {
  double toDoubleValue({int fractionDigits = 2}) {
    return double.parse(toStringAsFixed(fractionDigits));
  }
}
