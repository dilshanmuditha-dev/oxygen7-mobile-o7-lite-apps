import 'package:app/app_controller.dart';
import 'package:app/modules/main/payment_page_qr_o7lite/payment_page_qr_o7lite_controller.dart';
import 'package:app/shared/constants/colors.dart';
import 'package:app/shared/constants/common.dart';
import 'package:app/shared/utils/creditcard_follow_type.dart';
import 'package:app/shared/utils/responsive_util.dart';
import 'package:app/shared/widgets/currency_selector.dart';
import 'package:app/shared/widgets/custom_text_style.dart';
import 'package:app/shared/widgets/input_field.dart';
import 'package:app/shared/widgets/normal_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../shared/widgets/string_utils.dart';
import '../../../shared/widgets/text_area.dart';
import '../../../shared/services/storage_service.dart';
import '../home_controller.dart';

class PaymentPageQrO7Lite extends GetView<PaymentPageQrO7LiteController> {
  PaymentPageQrO7Lite({Key? key}) : super(key: key);
  final AppController appController = Get.find();
  final HomeController homeController = Get.find();

  // Get payment mode for UI display
  String get paymentMode => controller.paymentMode;

  @override
  Widget build(BuildContext context) {
    final AppController appController = Get.find();
    return NormalButton(
      onPressed: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: appController.isDarkModeOn.value
            ? ColorConstants.darkScaffoldBackgroundColor
            : Color(0xFFFBFBFB),
        appBar: StorageService.isGw3 ? _buildGw3AppBar() : _buildLegacyAppBar(),
        body: StorageService.isGw3 ? _buildGw3Layout() : _buildLegacyLayout(),
        floatingActionButtonLocation: StorageService.isGw3
            ? null
            : FloatingActionButtonLocation.centerFloat,
        floatingActionButton:
            StorageService.isGw3 ? null : _buildLegacyFloatingButton(),
      ),
    );
  }

  // GW3 AppBar following Figma design
  PreferredSizeWidget _buildGw3AppBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      title: Text(
        controller.creditCardFollowType == CreditCardFollowType.DASHBOARD
            ? (paymentMode == 'scan2pay'
                ? 'generateQrPaymentTitle'.tr
                : 'generateLinkPaymentTitle'.tr)
            : CommonConstants.digitalPayment.tr,
        style: TextStyle(
          fontFamily: 'Open Sans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: appController.isDarkModeOn.value
              ? Colors.white
              : Color(0xFF382F41),
        ),
      ),
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: Icon(
          Icons.arrow_back,
          color: appController.isDarkModeOn.value
              ? ColorConstants.white
              : Color(0xFF382F41),
          size: 24,
        ),
      ),
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
    );
  }

  // Legacy AppBar
  PreferredSizeWidget _buildLegacyAppBar() {
    return AppBar(
      centerTitle: true,
      title: Text(
        controller.creditCardFollowType == CreditCardFollowType.DASHBOARD
            ? (paymentMode == 'scan2pay'
                ? 'scan2PaySetup'.tr
                : 'click2PaySetup'.tr)
            : CommonConstants.digitalPayment.tr,
        style: CustomTextStyles.labelBlack500Size18Fw700,
      ),
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: Icon(
          Icons.arrow_back,
          color: appController.isDarkModeOn.value
              ? ColorConstants.white
              : ColorConstants.black,
          size: ResponsiveUtil().getSize(24),
        ),
      ),
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
    );
  }

  // GW3 Layout following Figma design
  Widget _buildGw3Layout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: controller.digitalPaymentDetailFormKey,
        child: Column(
          children: [
            // Content area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24),

                    // Currency Selector
                    Row(
                      children: [
                        Text(
                          '${CommonConstants.currency.tr}: ',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: appController.isDarkModeOn.value
                                ? Colors.white
                                : Color(0xFF382F41),
                          ),
                        ),
                        Obx(() => CurrencySelectorWidget(
                              selectedCurrency: controller.mCurrency.value,
                              supportedCurrencies:
                                  controller.supportedCurrencies.isNotEmpty
                                      ? controller.supportedCurrencies.toList()
                                      : [controller.mCurrency.value],
                              onCurrencyChanged: controller.onCurrencyChanged,
                              isDarkMode: appController.isDarkModeOn.value,
                            )),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Amount Field
                    _buildGw3AmountField(),

                    SizedBox(height: 16),

                    // Service Charge (if applicable and rate > 0)
                    Obx(() => appController.isMobileUser.value &&
                            homeController.getServiceChargeRate.value > 0
                        ? _buildGw3ServiceCharge()
                        : SizedBox.shrink()),

                    SizedBox(height: 16),

                    // Description Field
                    _buildGw3DescriptionField(),

                    SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),

            // Bottom Generate QR Button
            _buildGw3GenerateButton(),
          ],
        ),
      ),
    );
  }

  // Legacy Layout (unchanged)
  Widget _buildLegacyLayout() {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 30),
      child: Form(
        key: controller.digitalPaymentDetailFormKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: ResponsiveUtil().getSize(20)),
              Row(
                children: [
                  Text(
                    '${CommonConstants.currency.tr}: ',
                    style: CustomTextStyles.labelBlack500Size14Fw400,
                  ),
                  Obx(() => CurrencySelectorWidget(
                        selectedCurrency: controller.mCurrency.value,
                        supportedCurrencies:
                            controller.supportedCurrencies.isNotEmpty
                                ? controller.supportedCurrencies.toList()
                                : [controller.mCurrency.value],
                        onCurrencyChanged: controller.onCurrencyChanged,
                        isDarkMode: appController.isDarkModeOn.value,
                      )),
                ],
              ),
              SizedBox(height: ResponsiveUtil().getSize(20)),
              InputField(
                inputFormatters: [DecimalTextInputFormatter()],
                controller: controller.amountDigitalDetailController,
                hintText: CommonConstants.amountForPayment.tr,
                focusNode: controller.amountDigitalDetailFocus,
                checkBackgroundColorTextfield: true,
                onChanged: (value) async {
                  controller.setServiceChargeAmout.value =
                      await StringUtils.setServiceChargeAmout(value);
                },
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return CommonConstants.amountIsrequired.tr;
                  }
                  return null;
                },
              ),
              SizedBox(height: ResponsiveUtil().getSize(16)),
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
                            "${controller.mCurrency.value} ${controller.setServiceChargeAmout.value} (${homeController.getServiceChargeRate.value}%)",
                            style: CustomTextStyles.labelBlack500Size14Fw600,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              SizedBox(height: ResponsiveUtil().getSize(20)),
              TextArea(
                maxLength: 50,
                textEditingController:
                    controller.descriptionDigitalDetailController,
                borderColor: ColorConstants.grey800,
              ),
              SizedBox(height: ResponsiveUtil().getSize(54)),
            ],
          ),
        ),
      ),
    );
  }

  // Legacy Floating Action Button
  Widget? _buildLegacyFloatingButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Obx(
        () => controller.isBtnGenerateQRVisible.value
            ? SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => controller.paymentQr(),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(vertical: 0),
                    ),
                    backgroundColor: MaterialStatePropertyAll(
                      appController.isDarkModeOn.value
                          ? ColorConstants.grey800
                          : ColorConstants.backgroundColorButtonPrint,
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Text(
                      CommonConstants.paymentQr.tr,
                      style: CustomTextStyles.labelWhite700Size16Fw600,
                    ),
                  ),
                ),
              )
            : const SizedBox(),
      ),
    );
  }

  // GW3 Amount Field following Figma design
  Widget _buildGw3AmountField() {
    return Container(
      height: 52,
      child: TextFormField(
        inputFormatters: [DecimalTextInputFormatter()],
        controller: controller.amountDigitalDetailController,
        focusNode: controller.amountDigitalDetailFocus,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
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
        style: TextStyle(
          fontFamily: 'Open Sans',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: appController.isDarkModeOn.value
              ? Colors.white
              : Color(0xFF3A413A),
        ),
        decoration: InputDecoration(
          hintText: CommonConstants.amountForPayment.tr,
          hintStyle: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF827F85),
          ),
          filled: true,
          fillColor: appController.isDarkModeOn.value
              ? ColorConstants.grey800
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: appController.isDarkModeOn.value
                  ? Color(0xFF4A5568)
                  : Color(0xFFCFD3D0),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: appController.isDarkModeOn.value
                  ? Color(0xFF4A5568)
                  : Color(0xFFCFD3D0),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color(0xFF7E01D7),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.red,
              width: 1,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // GW3 Service Charge Display
  Widget _buildGw3ServiceCharge() {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '${'serviceChargeLabel'.tr}${controller.mCurrency.value} ${controller.setServiceChargeAmout.value} (${homeController.getServiceChargeRate.value}%)',
        style: TextStyle(
          fontFamily: 'Open Sans',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: appController.isDarkModeOn.value
              ? Colors.white
              : Color(0xFF382F41),
        ),
      ),
    );
  }

  // GW3 Description Field following Figma design
  Widget _buildGw3DescriptionField() {
    return Column(
      children: [
        Container(
          height: 114,
          child: TextFormField(
            controller: controller.descriptionDigitalDetailController,
            maxLength: 200,
            maxLines: 4,
            minLines: 4,
            onChanged: (value) {
              // Trigger rebuild for character counter
            },
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r"[a-zA-Z0-9 .,-_/()&'@#]"),
              ),
            ],
            validator: _validateDescription,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: appController.isDarkModeOn.value
                  ? Colors.white
                  : Color(0xFF3A413A),
            ),
            decoration: InputDecoration(
              hintText: 'digitalPaymentItemDescriptions'.tr,
              hintStyle: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF827F85),
              ),
              filled: true,
              fillColor: appController.isDarkModeOn.value
                  ? ColorConstants.grey800
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: appController.isDarkModeOn.value
                      ? Color(0xFF4A5568)
                      : Color(0xFFCFD3D0),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: appController.isDarkModeOn.value
                      ? Color(0xFF4A5568)
                      : Color(0xFFCFD3D0),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Color(0xFF7E01D7),
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.all(16),
              counterText: '', // Hide default counter
            ),
          ),
        ),

        // Custom character counter
        Padding(
          padding: EdgeInsets.only(top: 4, right: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller.descriptionDigitalDetailController,
              builder: (context, value, child) {
                return Text(
                  '${value.text.length}/200',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8D918D),
                    letterSpacing: -0.1,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Local strict allow-list validator for payment description.
  /// Description is optional, but if provided, it validates against strict allow-list.
  /// Blocks HTML/script injection patterns and enforces safe character set.
  String? _validateDescription(String? value) {
    final input = (value ?? '').trim();

    // Description is optional - allow empty
    if (input.isEmpty) {
      return null;
    }

    if (input.length > 200) {
      return 'Description must be 200 characters or less';
    }

    // Block obvious HTML / script injection patterns
    final blockedPattern = RegExp(
      r'(<[^>]*>|javascript:|data:text/html|on\w+\s*=|<|>)',
      caseSensitive: false,
    );
    if (blockedPattern.hasMatch(input)) {
      return 'Invalid description format';
    }

    // Allow-list: letters, numbers, spaces, and common punctuation only
    final allowList = RegExp(r"^[a-zA-Z0-9 .,-_/()&'@#]*$");
    if (!allowList.hasMatch(input)) {
      return 'Only letters, numbers, and basic punctuation are allowed';
    }

    return null;
  }

  // GW3 Generate QR Button
  Widget _buildGw3GenerateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      margin: EdgeInsets.only(bottom: 16),
      child: Obx(
        () => ElevatedButton(
          onPressed: controller.isBtnGenerateQRVisible.value
              ? () => controller.paymentQr()
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: controller.isBtnGenerateQRVisible.value
                ? Color(0xFF7E01D7)
                : (appController.isDarkModeOn.value
                    ? Colors.grey.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(80),
            ),
            elevation: 0,
          ),
          child: Text(
            paymentMode == 'scan2pay'
                ? CommonConstants.generateQR.tr
                : 'btnGenerateLink'.tr,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: controller.isBtnGenerateQRVisible.value
                  ? Colors.white
                  : (appController.isDarkModeOn.value
                      ? Colors.white.withOpacity(0.5)
                      : Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}
