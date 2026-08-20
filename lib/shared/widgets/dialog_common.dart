import 'package:app/shared/utils/responsive_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'custom_text_style.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const CustomAlertDialog({
    Key? key,
    required this.title,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: ResponsiveUtil().getPadding(all: 24),
      title: Text(
        title,
        style: CustomTextStyles.labelBlack500Size18Fw500,
      ),
      actions: [
        TextButton(
          onPressed: onPressed,
          child: Text(
            'ok'.tr,
            style: CustomTextStyles.labelPurple500Size14Fw600,
          ),
        ),
      ],
    );
  }
}
