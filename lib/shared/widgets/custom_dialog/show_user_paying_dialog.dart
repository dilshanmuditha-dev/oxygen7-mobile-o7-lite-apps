// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';

import '../../constants/common.dart';
import '../../constants/image_constant.dart';

class ShowUserPayingDialog extends Dialog {
  Function()? onPressCheck;
  Function()? onPressCancel;

  ShowUserPayingDialog({
    Key? key,
    required this.onPressCheck,
    required this.onPressCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CommonConstants.confirm.tr,
              style: TextStyle(
                fontSize: 20.0,
                color: Colors.lightBlue,
              ),
            ),
            SizedBox(height: 10.0),
            Image.asset(
              ImageConstant.iconCheckQRCode,
              width: 150,
              height: 150,
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: onPressCheck,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                  ),
                  child: Text(CommonConstants.check.tr),
                ),
                ElevatedButton(
                  onPressed: onPressCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                  ),
                  child: Text(CommonConstants.cancel.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
