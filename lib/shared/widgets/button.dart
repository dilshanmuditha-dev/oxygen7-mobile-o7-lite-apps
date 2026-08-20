import 'package:flutter/material.dart';

import '../../theme/theme_helper.dart';
import '../utils/responsive_util.dart';
import 'custom_text_style.dart';

class CommonWidgets {
  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    Color? color,
    TextStyle? style,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? appTheme.backgroundButtonLogin,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: Padding(
          padding: ResponsiveUtil().getPadding(top: 12, bottom: 12),
          child: Text(
            text,
            style: style ?? CustomTextStyles.labelWhite700Size16Fw600,
          ),
        ),
      ),
    );
  }
}
