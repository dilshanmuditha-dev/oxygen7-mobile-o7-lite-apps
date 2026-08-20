import 'package:app/app_controller.dart';
import 'package:app/shared/constants/constants.dart';
import 'package:app/shared/constants/constants_o7lite.dart';
import 'package:app/shared/utils/responsive_util.dart';
import 'package:app/shared/utils/utils.dart';
import 'package:app/shared/widgets/currency_selector.dart';
import 'package:app/shared/widgets/custom_text_style.dart';
import 'package:app/shared/widgets/input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../shared/constants/image_constant.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/widgets/normal_button.dart';
import '../../../shared/widgets/string_utils.dart';
import '../../../shared/widgets/text_area.dart';
import '../../../shared/constants/colors.dart';
import '../home_controller.dart';
import 'digital_payment_controller.dart';

/// Pure helper function that validates the payment amount.
///
/// Returns an error message string if validation fails, or `null` if valid.
/// Checks: empty input → ShopBack minimum (2) → ATOME minimum (1.5).
String? validateAmount(
    String? value, String? acquirerDigital, String? brand, String? currency) {
  if (value == null || value.isEmpty) {
    return CommonConstants.amountIsrequired.tr;
  }

  final bool isShopBack = brand?.toLowerCase().contains('shopback') ?? false;
  if (isShopBack && double.parse(value) < 2) {
    return 'digitalPaymentMinAmount'
        .trParams({'currency': currency ?? '', 'amount': '2'});
  }

  final bool isAtome = acquirerDigital == ConstantsO7Lite.ATOME_TYPE ||
      (brand?.toLowerCase() == 'atome');
  if (isAtome && double.parse(value) < 1.5) {
    return 'digitalPaymentMinAmount'
        .trParams({'currency': currency ?? '', 'amount': '1.5'});
  }

  return null;
}

/// Pure helper: whether the Scan QR (Consumer-Presented Mode) button should be
/// shown for a payment method. Only Alipay, WeChat, and ShopeePay support
/// scanning the customer's wallet code. Matched case-insensitively against the
/// payment method [brand] or [title] so it stays correct regardless of the
/// acquirer-type mapping (mirrors the legacy layout behavior).
bool isScanQrSupportedBrand(String? brand, String? title) {
  final String b = brand?.toLowerCase() ?? '';
  final String t = title?.toLowerCase() ?? '';
  bool matches(String keyword) => b.contains(keyword) || t.contains(keyword);
  return matches('alipay') || matches('wechat'); //|| matches('shopee')
}

class DigitalPayment extends GetView<DigitalPaymentController> {
  DigitalPayment({Key? key}) : super(key: key);
  final AppController appController = Get.find();
  final HomeController homeController = Get.find();

  @override
  Widget build(BuildContext context) {
    return NormalButton(
      onPressed: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: appController.isDarkModeOn.value
            ? ColorConstants.darkScaffoldBackgroundColor
            : Color(0xFFFBFBFB),
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(),
        body: StorageService.isGw3 ? _buildGw3Layout() : _buildLegacyLayout(),
        floatingActionButtonLocation: !StorageService.isGw3
            ? FloatingActionButtonLocation.centerFloat
            : null,
        floatingActionButton: !StorageService.isGw3
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Secondary action (on top): scan the customer's wallet
                    // code (Consumer-Presented Mode). Gated by the same
                    // reactive flag used in the GW3 layout.
                    Obx(
                      () => controller.isBtnScanQRVisible.value
                          ? SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () => controller.scanQrCode(context),
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all(
                                    EdgeInsets.symmetric(
                                      vertical: 0,
                                    ),
                                  ),
                                  backgroundColor: MaterialStatePropertyAll(
                                    appController.isDarkModeOn.value
                                        ? ColorConstants.grey800
                                        : ColorConstants.white,
                                  ),
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      side: BorderSide(
                                        width: 1,
                                        color: appController.isDarkModeOn.value
                                            ? ColorConstants.grey800!
                                            : ColorConstants
                                                .backgroundColorButtonPrint,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        ImageConstant.iconScanTransactionId,
                                        height: 20,
                                        color: ColorConstants
                                            .backgroundColorButtonPrint,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        CommonConstants.scanQR.tr,
                                        style: CustomTextStyles
                                            .labelBlue600Size16Fw500,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox(),
                    ),
                    // Gap between the Scan QR and Generate QR buttons so they
                    // don't touch when both are visible.
                    SizedBox(
                      height: ResponsiveUtil().getSize(16),
                    ),
                    // Primary action: generate a merchant-presented QR.
                    Obx(
                      () => controller.isBtnGenerateQRVisible.value
                          ? SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () =>
                                    controller.makePayment(context),
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all(
                                    EdgeInsets.symmetric(
                                      vertical: 0,
                                    ),
                                  ),
                                  backgroundColor: MaterialStatePropertyAll(
                                    appController.isDarkModeOn.value
                                        ? ColorConstants.grey800
                                        : ColorConstants.white,
                                  ),
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      side: BorderSide(
                                        width: 1,
                                        color: appController.isDarkModeOn.value
                                            ? ColorConstants.grey800!
                                            : ColorConstants
                                                .backgroundColorButtonPrint,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    CommonConstants.generateQR.tr,
                                    style: CustomTextStyles
                                        .labelBlue600Size16Fw500,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox(),
                    ),
                    SizedBox(
                      height: ResponsiveUtil().getSize(16),
                    ),
                    SizedBox(
                      height: ResponsiveUtil().getSize(20),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      title: Text(
        CommonConstants.digitalPayment.tr,
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
        icon: Icon(
          Icons.arrow_back,
          color: appController.isDarkModeOn.value
              ? ColorConstants.white
              : Color(0xFF382F41),
          size: 24,
        ),
        onPressed: () => Get.back(),
      ),
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
    );
  }

  Widget _buildGw3Layout() {
    return Column(
      children: [
        // Content area
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: controller.digitalPaymentDetailFormKey,
              child: Column(
                children: [
                  SizedBox(height: 10),

                  // Payment Method Display - Centered
                  _buildPaymentMethodDisplay(),

                  SizedBox(height: 32),

                  // Form Section
                  _buildFormSection(),

                  SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ),

        // Bottom Button
        _buildBottomButton(),
      ],
    );
  }

  Widget _buildPaymentMethodDisplay() {
    return Column(
      children: [
        // Payment Method Icon
        Container(
          width: 100,
          height: 102,
          decoration: BoxDecoration(
            color: appController.isDarkModeOn.value
                ? ColorConstants.grey800
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: appController.isDarkModeOn.value
                  ? Color(0xFF4A5568)
                  : Color(0xFFCFD3D0),
              width: 1,
            ),
          ),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Obx(() => _getPaymentMethodImage()),
            ),
          ),
        ),

        SizedBox(height: 16),

        // Payment Method Name
        Text(
          _getPaymentMethodTitle(),
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: appController.isDarkModeOn.value
                ? Colors.white
                : Color(0xFF382F41),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  selectedCurrency: controller.selectedCurrency.value,
                  supportedCurrencies: controller.supportedCurrencies,
                  onCurrencyChanged: controller.onCurrencyChanged,
                  isDarkMode: appController.isDarkModeOn.value,
                )),
          ],
        ),

        SizedBox(height: 16),

        // Amount Input Field
        _buildAmountField(),

        SizedBox(height: 16),

        // Service Charge Display
        Obx(() => _buildServiceChargeDisplay()),

        SizedBox(height: 16),

        // Description Field
        _buildDescriptionField(),
      ],
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appController.isDarkModeOn.value
              ? Color(0xFF4A5568)
              : Color(0xFFCFD3D0),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller.amountDigitalDetailController,
        focusNode: controller.amountDigitalDetailFocus,
        inputFormatters: [DecimalTextInputFormatter()],
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        maxLength: AppConstants.MAX_LENGTH_PASSWORD,
        onChanged: (value) async {
          controller.setServiceChargeAmount.value =
              await StringUtils.setServiceChargeAmout(value);
        },
        validator: (value) => validateAmount(
          value,
          controller.routePaymentModel.acquirerDigital,
          controller.routePaymentModel.brand,
          controller.routePaymentModel.currency,
        ),
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
            color: appController.isDarkModeOn.value
                ? Colors.white.withOpacity(0.5)
                : Color(0xFF827F85),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildServiceChargeDisplay() {
    // Hide service charge UI when rate is 0 or not set
    if (!appController.isMobileUser.value ||
        homeController.getServiceChargeRate.value <= 0) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'serviceChargeLabel'.tr,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: appController.isDarkModeOn.value
                ? Colors.white
                : Color(0xFF382F41),
          ),
        ),
        Text(
          "${controller.selectedCurrency.value} ${controller.setServiceChargeAmount.value} (${homeController.getServiceChargeRate.value}%)",
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: appController.isDarkModeOn.value
                ? Colors.white
                : Color(0xFF382F41),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: appController.isDarkModeOn.value
                ? ColorConstants.grey800
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: appController.isDarkModeOn.value
                  ? Color(0xFF4A5568)
                  : Color(0xFFCFD3D0),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller.descriptionDigitalDetailController,
            maxLength: 200,
            maxLines: 4,
            minLines: 4,
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
                color: appController.isDarkModeOn.value
                    ? Colors.white.withOpacity(0.5)
                    : Color(0xFF827F85),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              counterStyle: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: appController.isDarkModeOn.value
                    ? Colors.white.withOpacity(0.7)
                    : Color(0xFF8D918D),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        // Observe BOTH reactive flags in a single Obx so the button stack
        // rebuilds when either the Scan QR or Generate QR visibility changes.
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Secondary action (on top): scan the customer's wallet code.
              if (controller.isBtnScanQRVisible.value) _buildGw3ScanButton(),

              // Gap only when both buttons are visible.
              if (controller.isBtnScanQRVisible.value &&
                  controller.isBtnGenerateQRVisible.value)
                const SizedBox(height: 12),

              // Primary action: generate a merchant-presented QR.
              if (controller.isBtnGenerateQRVisible.value)
                _buildGw3GenerateButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Primary action for the GW3 layout: the filled Generate QR button
  /// (Merchant-Presented Mode). Styling is unchanged from the original layout.
  Widget _buildGw3GenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          controller.makePayment(Get.context!);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF7E01D7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(80),
          ),
          elevation: 0,
        ),
        child: Text(
          CommonConstants.generateQR.tr,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Secondary action for the GW3 layout: an outlined Scan QR button
  /// (Consumer-Presented Mode). Visually distinct from the primary filled
  /// Generate QR button — purple outline and purple content on the surface.
  Widget _buildGw3ScanButton() {
    const Color primaryPurple = Color(0xFF7E01D7);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () => controller.scanQrCode(Get.context!),
        style: OutlinedButton.styleFrom(
          backgroundColor: appController.isDarkModeOn.value
              ? ColorConstants.grey800
              : Colors.white,
          side: BorderSide(width: 1, color: primaryPurple),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(80),
          ),
        ),
        icon: SvgPicture.asset(
          ImageConstant.iconScanTransactionId,
          height: 20,
          color: primaryPurple,
        ),
        label: Text(
          CommonConstants.scanQR.tr,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryPurple,
          ),
        ),
      ),
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

  Widget _getPaymentMethodImage() {
    controller.isBtnScanQRVisible.value = isScanQrSupportedBrand(
      controller.routePaymentModel.brand,
      controller.routePaymentModel.title,
    );
    switch (controller.routePaymentModel.acquirerDigital) {
      case ConstantsO7Lite.ALIPAY_TYPE:
        controller.isBtnGenerateQRVisible.value = true;
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.WECHAT_TYPE:
        controller.isBtnGenerateQRVisible.value = true;
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.GRABPAY_TYPE:
      case ConstantsO7Lite.GRABPAY_V3_TYPE:
        controller.isBtnGenerateQRVisible.value = true;
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.ATOME_TYPE:
        controller.isBtnGenerateQRVisible.value = true;
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.PAYNOW_TYPE:
        controller.isBtnGenerateQRVisible.value = true;
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.THAIQR_TYPE:
        controller.isBtnGenerateQRVisible.value = true;
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.DASH_TYPE:
        controller.isBtnGenerateQRVisible.value = true;
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.BOOST_TYPE:
        controller.isBtnGenerateQRVisible.value = true;
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.TOUCHNGO_TYPE:
        controller.isBtnGenerateQRVisible.value = true;
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.SHOPEE_TYPE:
        controller.isBtnGenerateQRVisible.value = true;
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.IOUPAY_TYPE:
        controller.isBtnGenerateQRVisible.value = true;
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      default:
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
    }
  }

  String _getPaymentMethodTitle() {
    return controller.routePaymentModel.brand ??
        controller.routePaymentModel.title ??
        '';
  }

  // Legacy layout for non-GW3 users
  Widget _buildLegacyLayout() {
    return Padding(
      padding: ResponsiveUtil().getPadding(
        left: 16,
        right: 16,
        top: 10,
      ),
      child: Form(
        key: controller.digitalPaymentDetailFormKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Obx(
                  () => getImageBrand(),
                ),
              ),
              SizedBox(
                height: ResponsiveUtil().getSize(20),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Row(
                  children: [
                    Text(
                      '${CommonConstants.currency.tr}: ',
                      style: CustomTextStyles.labelBlack500Size14Fw400,
                    ),
                    Obx(() => CurrencySelectorWidget(
                          selectedCurrency: controller.selectedCurrency.value,
                          supportedCurrencies: controller.supportedCurrencies,
                          onCurrencyChanged: controller.onCurrencyChanged,
                          isDarkMode: appController.isDarkModeOn.value,
                        )),
                  ],
                ),
              ),
              SizedBox(
                height: ResponsiveUtil().getSize(20),
              ),
              InputField(
                inputFormatters: [DecimalTextInputFormatter()],
                controller: controller.amountDigitalDetailController,
                hintText: CommonConstants.amountForPayment.tr,
                focusNode: controller.amountDigitalDetailFocus,
                checkBackgroundColorTextfield: true,
                maxLength: AppConstants.MAX_LENGTH_PASSWORD,
                onChanged: (value) async {
                  controller.setServiceChargeAmount.value =
                      await StringUtils.setServiceChargeAmout(value);
                },
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) => validateAmount(
                  value,
                  controller.routePaymentModel.acquirerDigital,
                  controller.routePaymentModel.brand,
                  controller.routePaymentModel.currency,
                ),
              ),
              SizedBox(height: ResponsiveUtil().getSize(10)),
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
                            "${controller.selectedCurrency.value} ${controller.setServiceChargeAmount.value} (${homeController.getServiceChargeRate.value}%)",
                            style: CustomTextStyles.labelBlack500Size14Fw600,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              Column(
                children: [
                  SizedBox(height: ResponsiveUtil().getSize(10)),
                  TextArea(
                    maxLength: 200,
                    textEditingController:
                        controller.descriptionDigitalDetailController,
                    borderColor: ColorConstants.grey800,
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtil().getSize(200)),
            ],
          ),
        ),
      ),
    );
  }

  Widget getImageBrand() {
    var ivWalletIcon = ImageConstant.oxpayIconTransparentBackground;
    var titlePayment = '';

    switch (controller.routePaymentModel.acquirerDigital) {
      case ConstantsO7Lite.ALIPAY_TYPE:
        controller.isBtnScanQRVisible.value = true;
        controller.isBtnGenerateQRVisible.value = true;
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: appController.isDarkModeOn.value
                      ? ColorConstants.grey800
                      : ColorConstants.darkGray.withAlpha(50),
                ),
                padding: EdgeInsets.all(1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    ImageConstant.imageAlipay,
                    width: ResponsiveUtil().getSize(120),
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtil().getSize(10)),
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                'digitalPaymentAlipayQr'.tr,
                style: CustomTextStyles.labelBlack500Size24Fw600,
              ),
            ),
            SizedBox(height: ResponsiveUtil().getSize(10)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  10,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Image.asset(
                      'assets/o7lite/images/img_aplipay_plush_${index + 1}.png',
                      width: ResponsiveUtil().getSize(40),
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case ConstantsO7Lite.WECHAT_TYPE:
        ivWalletIcon = ImageConstant.imageWechatPay;
        controller.isBtnScanQRVisible.value = true;
        controller.isBtnGenerateQRVisible.value = true;
        titlePayment = 'paymentMethodWeChatPay'.tr;
        break;
      case ConstantsO7Lite.GRABPAY_TYPE:
        ivWalletIcon = ImageConstant.imageGrabPay;
        controller.isBtnScanQRVisible.value = false;
        controller.isBtnGenerateQRVisible.value = true;
        titlePayment = 'paymentMethodGrabPay'.tr;
        break;
      case ConstantsO7Lite.GRABPAY_V3_TYPE:
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: appController.isDarkModeOn.value
                      ? ColorConstants.grey800
                      : ColorConstants.darkGray.withAlpha(50),
                ),
                padding: EdgeInsets.all(1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    resolveImageFromModel(controller.routePaymentModel,
                        isSGPLocation: appController.isSGPLocation()),
                    width: ResponsiveUtil().getSize(120),
                    height: ResponsiveUtil().getSize(120),
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtil().getSize(10)),
            Text(
              'paymentMethodGrabPay'.tr,
              style: CustomTextStyles.labelBlack500Size24Fw600,
            ),
            SizedBox(height: ResponsiveUtil().getSize(10)),
            // !appController.isSGPLocation()
            //     ? Image.asset(
            //         ImageConstant.imgDuitNow,
            //         width: ResponsiveUtil().getSize(40),
            //         fit: BoxFit.fitWidth,
            //       )
            //     : const SizedBox.shrink(),
          ],
        );
      case ConstantsO7Lite.ATOME_TYPE:
        ivWalletIcon = ImageConstant.imageAtome;
        controller.isBtnScanQRVisible.value = false;
        controller.isBtnGenerateQRVisible.value = true;
        titlePayment = 'paymentMethodAtome'.tr;
        break;
      case ConstantsO7Lite.PAYNOW_TYPE:
        ivWalletIcon = ImageConstant.imagePaynow;
        controller.isBtnScanQRVisible.value = false;
        controller.isBtnGenerateQRVisible.value = true;
        titlePayment = 'paymentMethodPayNow'.tr;
        break;
      case ConstantsO7Lite.THAIQR_TYPE:
        ivWalletIcon = ImageConstant.imageThaiQR;
        controller.isBtnScanQRVisible.value = false;
        controller.isBtnGenerateQRVisible.value = true;
        titlePayment = 'paymentMethodThaiQr'.tr;
        break;
      case ConstantsO7Lite.DASH_TYPE:
        ivWalletIcon = ImageConstant.imageSingleDash;
        controller.isBtnScanQRVisible.value = false;
        controller.isBtnGenerateQRVisible.value = true;
        titlePayment = 'paymentMethodDash'.tr;
        break;
      case ConstantsO7Lite.BOOST_TYPE:
        ivWalletIcon = ImageConstant.imageBoost;
        controller.isBtnScanQRVisible.value = false;
        controller.isBtnGenerateQRVisible.value = true;
        titlePayment = 'paymentMethodBoost'.tr;
        break;
      case ConstantsO7Lite.TOUCHNGO_TYPE:
        controller.isBtnScanQRVisible.value = false;
        controller.isBtnGenerateQRVisible.value = true;
        ivWalletIcon = ImageConstant.iconTouchNGoEWallet;
        titlePayment =
            controller.routePaymentModel.title ?? 'paymentMethodTouchNGo'.tr;
        break;
      case ConstantsO7Lite.SHOPEE_TYPE:
        ivWalletIcon = ImageConstant.imageShopeePay;
        controller.isBtnScanQRVisible.value =
            false; // johnny: comment out by Kevin
        controller.isBtnGenerateQRVisible.value = true;
        titlePayment = 'paymentMethodShopeePay'.tr;
        break;
      case ConstantsO7Lite.IOUPAY_TYPE:
        ivWalletIcon = ImageConstant.imageIOUPay;
        controller.isBtnScanQRVisible.value = false;
        controller.isBtnGenerateQRVisible.value = true;
        titlePayment = 'paymentMethodIouPay'.tr;
        break;
      default:
        break;
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: appController.isDarkModeOn.value
                  ? ColorConstants.grey800
                  : ColorConstants.darkGray.withAlpha(50),
            ),
            padding: EdgeInsets.all(1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: StorageService.isGw3
                  ? getBrandImageWidgetV2(controller.routePaymentModel,
                      height: ResponsiveUtil().getSize(120),
                      isSGPLocation: appController.isSGPLocation())
                  : Image.asset(
                      ivWalletIcon,
                      width: ResponsiveUtil().getSize(120),
                      height: ResponsiveUtil().getSize(120),
                      fit: BoxFit.fitHeight,
                    ),
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtil().getSize(4)),
        Text(
          StorageService.isGw3
              ? controller.routePaymentModel.brand ?? ''
              : titlePayment,
          style: CustomTextStyles.labelBlack500Size24Fw600,
        ),
      ],
    );
  }
}
