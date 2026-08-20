import 'package:app/shared/constants/colors.dart';
import 'package:app/shared/constants/common.dart';
import 'package:app/shared/utils/responsive_util.dart';
import 'package:app/shared/widgets/button.dart';
import 'package:app/shared/widgets/custom_text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app_controller.dart';
import '../../../shared/widgets/normal_button.dart';
import 'components/credit_card_form_field.dart';
import 'credit_card_controller.dart';

class CreditCard extends GetView<CreditCardController> {
  const CreditCard({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final AppController appController = Get.find();

    return NormalButton(
      onPressed: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Text(
                CommonConstants.creditCard.tr,
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
            body: Padding(
              padding: ResponsiveUtil().getPadding(
                left: 10,
                right: 10,
                top: 20,
                bottom: 0,
              ),
              child: CreditCardForm(),
            ),
          ),
          Padding(
            padding: ResponsiveUtil().getPadding(
              left: 10,
              right: 10,
              top: 20,
              bottom: 20,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: CommonWidgets.primaryButton(
                width: double.infinity,
                text: CommonConstants.payNow.tr,
                onPressed: () => controller.payNow(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
