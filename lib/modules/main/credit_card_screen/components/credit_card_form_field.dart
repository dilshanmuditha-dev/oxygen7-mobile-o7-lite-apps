// ignore_for_file: deprecated_member_use
import 'package:app/modules/main/home_controller.dart';
import 'package:app/shared/constants/colors.dart';
import 'package:app/shared/constants/common.dart';
import 'package:app/shared/utils/responsive_util.dart';
import 'package:app/shared/widgets/custom_text_style.dart';
import 'package:app/shared/widgets/text_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/credit_card_expiration_input_formatter.dart';
import 'package:get/get.dart';
import '../../../../app_controller.dart';
import '../../../../shared/widgets/input_field.dart';
import '../../../../shared/widgets/string_utils.dart';
import '../credit_card_controller.dart';

// ignore: use_key_in_widget_constructors
class CreditCardForm extends GetView<CreditCardController> {
  final AppController appController = Get.find();
  final String intentCurrency = Get.arguments ?? '';
  final HomeController homeController = Get.find();
  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.creditCardFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '${CommonConstants.currency.tr}: ',
                  style: CustomTextStyles.labelBlack500Size14Fw400,
                ),
                Text(
                  intentCurrency,
                  style: CustomTextStyles.labelBlack500Size16Fw700,
                ),
              ],
            ),
            SizedBox(
              height: ResponsiveUtil().getSize(8),
            ),
            InputField(
              inputFormatters: [DecimalTextInputFormatter()],
              controller: controller.amountController,
              hintText: CommonConstants.amount.tr,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              focusNode: controller.amountFocus,
              checkBackgroundColorTextfield: true,
              onChanged: (value) async {
                controller.setServiceChargeAmout.value =
                    await StringUtils.setServiceChargeAmout(value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return CommonConstants.amountIsrequired.tr;
                }
                return null;
              },
            ),
            SizedBox(
              height: ResponsiveUtil().getSize(20),
            ),
            Obx(
              // Hide service charge UI when rate is 0 or not set
              () => appController.isMobileUser.value &&
                      homeController.getServiceChargeRate.value > 0
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'serviceChargeLabel'.tr,
                          style: CustomTextStyles.labelBlack500Size14Fw400,
                        ),
                        Text(
                          "$intentCurrency ${controller.setServiceChargeAmout.value} (${homeController.getServiceChargeRate.value}%)",
                          style: CustomTextStyles.labelBlack500Size14Fw600,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(
              height: ResponsiveUtil().getSize(16),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                CommonConstants.cardNumber.tr,
                style: CustomTextStyles.labelBlack500Size14Fw400,
              ),
            ),
            SizedBox(
              height: ResponsiveUtil().getSize(8),
            ),
            InputField(
              controller: controller.cardNumberController,
              hintText: CommonConstants.cardNumber.tr,
              focusNode: controller.cardNumberFocus,
              checkBackgroundColorTextfield: true,
              onChanged: (value) {
                controller.updateLength(value);
              },
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              maxLength: 16,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return CommonConstants.cardNumberIsRequired.tr;
                }
                if (value.length < 16) {
                  return CommonConstants.cardNumberLimit.tr;
                }
                return null;
              },
            ),
            SizedBox(
              height: ResponsiveUtil().getSize(8),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                CommonConstants.cardHolder.tr,
                style: CustomTextStyles.labelBlack500Size14Fw400,
              ),
            ),
            SizedBox(
              height: ResponsiveUtil().getSize(8),
            ),
            InputField(
              controller: controller.cardHolderController,
              hintText: CommonConstants.cardHolder.tr,
              focusNode: controller.cardHolderFocus,
              checkBackgroundColorTextfield: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return CommonConstants.cardHolderIsRequired.tr;
                }
                return null;
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CommonConstants.expridate.tr,
                          style: CustomTextStyles.labelBlack500Size14Fw400,
                        ),
                        SizedBox(
                          height: ResponsiveUtil().getSize(8),
                        ),
                        textfieldCustom(
                          hintText: 'MM/YY',
                          focusNode: controller.expiryDateFocus,
                          textEditingController:
                              controller.expiryDateController,
                          inputFormatters: CreditCardExpirationDateFormatter(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return CommonConstants.expridateIsRequired.tr;
                            }

                            var parts = value.split('/');
                            if (parts.length != 2) {
                              return CommonConstants.expiryDate.tr;
                            }

                            var enteredMonth = int.tryParse(parts[0]);
                            var enteredYear = int.tryParse(parts[1]);

                            if (enteredMonth == null || enteredYear == null) {
                              return CommonConstants.expiryDate.tr;
                            }

                            if (enteredYear == 0 || enteredMonth == 0) {
                              return CommonConstants.expiryDate.tr;
                            }

                            var now = DateTime.now();
                            var currentYear = now.year % 100;
                            var currentMonth = now.month;

                            if (enteredYear < currentYear ||
                                (enteredYear == currentYear &&
                                    enteredMonth < currentMonth)) {
                              return CommonConstants.expiryDate.tr;
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveUtil().getSize(20),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'creditCardCvc'.tr,
                          style: CustomTextStyles.labelBlack500Size14Fw400,
                        ),
                        SizedBox(
                          height: ResponsiveUtil().getSize(8),
                        ),
                        InputField(
                          controller: controller.cvcController,
                          hintText: '***',
                          focusNode: controller.cvcFocus,
                          checkBackgroundColorTextfield: true,
                          obscureText: true,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          maxLength: 3,
                          onChanged: (value) {
                            controller.updateCVCLength(value);
                          },
                          counterText: '',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return CommonConstants.cvcIsRequired.tr;
                            }
                            if (value.length < 3) {
                              return CommonConstants.cvcLimit.tr;
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Obx(
                () {
                  return Text(
                    '${controller.currentCVCLength}/3',
                    style: CustomTextStyles.labelBlack500Size14Fw400,
                  );
                },
              ),
            ),
            SizedBox(
              height: ResponsiveUtil().getSize(20),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                CommonConstants.description.tr,
                style: CustomTextStyles.labelBlack500Size14Fw400,
              ),
            ),
            SizedBox(
              height: ResponsiveUtil().getSize(8),
            ),
            TextArea(
              maxLength: 50,
              textEditingController: controller.descriptionController,
              borderColor: ColorConstants.grey800,
            ),
            SizedBox(height: ResponsiveUtil().getSize(124)),
          ],
        ),
      ),
    );
  }

  Widget textfieldCustom({
    String? hintText,
    TextEditingController? textEditingController,
    String? Function(String?)? validator,
    required TextInputFormatter inputFormatters,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: textEditingController,
      focusNode: focusNode,
      style: TextStyle(
        color: appController.isDarkModeOn.value
            ? ColorConstants.white
            : ColorConstants.black,
      ),
      validator: validator,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: Colors.black,
      inputFormatters: [inputFormatters],
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        errorStyle: CustomTextStyles.labelRed400Size12Fw400,
        suffixIconConstraints:
            const BoxConstraints(maxHeight: 60, maxWidth: 60),
        contentPadding: ResponsiveUtil().getPadding(all: 10),
        hintText: hintText,
        hintStyle: CustomTextStyles.labelGray600Size16Fw400,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(
            width: 1,
            color: ColorConstants.colorBorderTextFieldBold,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(width: 1, color: ColorConstants.red),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(width: 1, color: ColorConstants.red),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide:
              BorderSide(width: 1, color: ColorConstants.colorBorderTextField),
        ),
        filled: true,
        fillColor: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : ColorConstants.white,
      ),
    );
  }
}
