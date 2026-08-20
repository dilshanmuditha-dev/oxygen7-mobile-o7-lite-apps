import 'package:app/app_controller.dart';
import 'package:app/shared/constants/colors.dart';
import 'package:app/shared/constants/common.dart';
import 'package:app/shared/utils/responsive_util.dart';
import 'package:app/shared/widgets/custom_text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../trouble_shooting_controller.dart';

class PrintScreen extends GetView<TroubleShootingController> {
  PrintScreen({Key? key}) : super(key: key);
  final AppController appController = Get.find();

  @override
  Widget build(BuildContext context) {
    final AppController appController = Get.find();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          CommonConstants.print.tr,
          style: CustomTextStyles.labelBlack500Size18Fw700,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: appController.isDarkModeOn.value
                ? ColorConstants.white
                : ColorConstants.grey800,
            size: ResponsiveUtil().getSize(24),
          ),
          onPressed: () => Get.back(),
        ),
        backgroundColor: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : Colors.white,
      ),
      backgroundColor: appController.isDarkModeOn.value ? null : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(
              () => Text(
                "${CommonConstants.status.tr}: ${controller.isConnectedPrinter.value ? CommonConstants.connected.tr : CommonConstants.notConnect.tr}",
                style: CustomTextStyles.labelBlack500Size18Fw700,
              ),
            ),
            Padding(
              padding: ResponsiveUtil().getPadding(top: 30),
              child: InkWell(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorConstants.colorGradientNext,
                        ColorConstants.colorGradientFirst.withOpacity(.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: ResponsiveUtil().getPadding(
                    left: 30,
                    right: 30,
                    bottom: 10,
                    top: 10,
                  ),
                  child: Text(
                    CommonConstants.printTest.tr,
                    style: CustomTextStyles.labelBlack500Size14Fw600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
