import 'package:app/app_controller.dart';
import 'package:app/shared/constants/colors.dart';
import 'package:app/shared/constants/common.dart';
import 'package:app/shared/utils/responsive_util.dart';
import 'package:app/shared/widgets/custom_text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_settings_plus/core/open_settings_plus.dart';
import '../trouble_shooting_controller.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';

class WifiScreen extends GetView<TroubleShootingController> {
  WifiScreen({Key? key}) : super(key: key);
  final AppController appController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Wifi",
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
            connected(CommonConstants.notConnect.tr),
            Padding(
              padding: ResponsiveUtil().getPadding(top: 30),
              child: InkWell(
                onTap: () {
                  final settings = OpenSettingsPlus.shared;
                  if (settings is OpenSettingsPlusAndroid) {
                    settings.wifi();
                  } else if (settings is OpenSettingsPlusIOS) {
                    settings.wifi();
                  } else {
                    throw Exception('Platform not supported');
                  }
                },
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
                    CommonConstants.connected.tr,
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

  Widget connected(String type) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Wifi/4G/3G: ",
          style: CustomTextStyles.labelBlack500Size18Fw700,
        ),
        // Obx(
        //   () => Text(
        //     controller.networkStatus.value == ConnectivityResult.mobile ||
        //             controller.networkStatus.value == ConnectivityResult.wifi
        //         ? CommonConstants.connected.tr
        //         : CommonConstants.notConnect.tr,
        //     style: TextStyle(
        //       color: controller.networkStatus.value ==
        //                   ConnectivityResult.mobile ||
        //               controller.networkStatus.value == ConnectivityResult.wifi
        //           ? Colors.green
        //           : ColorConstants.black,
        //       fontSize: 20,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
