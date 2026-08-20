// ignore_for_file: depend_on_referenced_packages

import 'package:app/app_controller.dart';
import 'package:app/models/response/report_model/report_model.dart';
import 'package:app/shared/widgets/custom_dialog/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../../models/route_payment_model.dart';
import '../../../routes/app_pages.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/constants_o7lite.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/utils/responsive_util.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/custom_text_style.dart';
import '../../../shared/widgets/string_utils.dart';
import '../../../shared/constants/common.dart';
import '../../../shared/constants/image_constant.dart';
import '../../../theme/theme_helper.dart';
import '../home_controller.dart';
import '../../../shared/widgets/animation/wave_animation_widget.dart';
import '../../../shared/utils/animation/animation_style.dart' as app_animation;
import '../app_setting/app_setting_controller.dart';

class SelectRefundPaymentMethodScreen extends GetView<HomeController> {
  SelectRefundPaymentMethodScreen({Key? key}) : super(key: key);
  final AppController appController = Get.find();
  final AppSettingController appSettingController = Get.find();
  final bool isCheckBack = Get.arguments ?? false;

  // Note: selectedPaymentIndex removed as we navigate directly on tap

  // View mode tracking (true = grid view, false = list view)
  final RxBool isGridView = true.obs;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isAnimationEnabled =
          appSettingController.isEnableAppAnimation.value;

      return WaveAnimationWidget(
        enabled: isAnimationEnabled,
        style: app_animation.AnimationStyle.values.firstWhere(
          (s) => s.name == appSettingController.selectedAnimationStyle.value,
          orElse: () => app_animation.AnimationStyle.wave,
        ),
        isDarkMode: appController.isDarkModeOn.value,
        child: Scaffold(
          backgroundColor: isAnimationEnabled
              ? Colors.transparent
              : (appController.isDarkModeOn.value
                  ? ColorConstants.darkScaffoldBackgroundColor
                  : Color(0xFFFBFBFB)),
          extendBodyBehindAppBar: isAnimationEnabled,
          appBar: AppBar(
            centerTitle: true,
            elevation: 0,
            backgroundColor: isAnimationEnabled
                ? Colors.transparent
                : (appController.isDarkModeOn.value
                    ? ColorConstants.grey800
                    : Colors.white),
            title: Text(
              CommonConstants.refund.tr,
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
              onPressed: () {
                isCheckBack
                    ? Get.back()
                    : controller.bottomNavIndex.value != 0
                        ? controller.setValueBottomIndex(0)
                        : null;
              },
            ),
          ),
          body: _buildNewDesign(),
        ),
      );
    });
  }

  Widget _buildNewDesign() {
    final bool isAnimationEnabled =
        appSettingController.isEnableAppAnimation.value;
    final double topPadding = isAnimationEnabled
        ? kToolbarHeight + MediaQuery.of(Get.context!).padding.top
        : 0;

    return Column(
      children: [
        // Content area
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16 + topPadding, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and View Mode Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        CommonConstants.selectPaymentToRefund.tr,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: appController.isDarkModeOn.value
                              ? Colors.white
                              : Color(0xFF382F41),
                        ),
                      ),
                    ),

                    SizedBox(width: 16),

                    // View Mode Toggle Button
                    Obx(() => _buildViewModeToggle()),
                  ],
                ),

                SizedBox(height: 24),

                // Payment Methods Grid
                Obx(() {
                  if (controller.listWalletType.isEmpty) {
                    return Container(
                      height: 300,
                      child: Center(
                        child: Lottie.asset(
                          'assets/o7lite/images/lt_payment.json',
                          height: 160,
                        ),
                      ),
                    );
                  }

                  return Obx(() => GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isGridView.value ? 2 : 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isGridView.value
                              ? 171 / 76 // Grid view ratio from Figma
                              : 343 / 76, // List view ratio (full width)
                        ),
                        itemCount: controller.listWalletType.length,
                        itemBuilder: (context, index) {
                          return Obx(() => _buildPaymentMethodCard(
                                controller.listWalletType[index],
                                index,
                              ));
                        },
                      ));
                }),

                SizedBox(height: 32), // Space at bottom
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(RoutePaymentModel paymentMethod, int index) {
    final isActivated = paymentMethod.isActivated;
    final hasRefundSupport = paymentMethod.acquirerVoid != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: (isActivated && hasRefundSupport)
            ? () => _onPaymentMethodTap(paymentMethod, index)
            : null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive sizing based on available width
            final isSmallScreen = constraints.maxWidth < 180;
            final iconSize = isSmallScreen ? 36.0 : 40.0;
            final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
            final iconSpacing = isSmallScreen ? 12.0 : 16.0;

            return Container(
              height: 76,
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Icon container - Responsive sizing
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: (isActivated && hasRefundSupport)
                            ? Colors.white
                            : (appController.isDarkModeOn.value
                                ? ColorConstants.grey800
                                : Colors.grey.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: (isActivated && hasRefundSupport)
                            ? (StorageService.isGw3
                                ? getBrandImageWidgetV2(
                                    paymentMethod,
                                    height: iconSize,
                                  )
                                : Image.asset(
                                    paymentMethod.image,
                                    width: iconSize,
                                    height: iconSize,
                                    fit: BoxFit.cover,
                                  ))
                            : ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  Colors.grey,
                                  BlendMode.saturation,
                                ),
                                child: StorageService.isGw3
                                    ? getBrandImageWidgetV2(
                                        paymentMethod,
                                        height: iconSize,
                                      )
                                    : Image.asset(
                                        paymentMethod.image,
                                        width: iconSize,
                                        height: iconSize,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                      ),
                    ),

                    SizedBox(width: iconSpacing),

                    // Payment method name - Responsive text
                    Expanded(
                      child: _buildResponsivePaymentTitle(
                        paymentMethod.title?.toUpperCase() ?? '',
                        isActivated && hasRefundSupport,
                        constraints.maxWidth,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => isGridView.value = !isGridView.value,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: appController.isDarkModeOn.value
                ? ColorConstants.grey800
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: appController.isDarkModeOn.value
                  ? Color(0xFF4A5568)
                  : Color(0xFFCFD3D0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isGridView.value
                ? Icons.grid_view_rounded
                : Icons.view_list_rounded,
            size: 20,
            color: appController.isDarkModeOn.value
                ? Colors.white.withOpacity(0.8)
                : Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsivePaymentTitle(
      String title, bool isActivated, double availableWidth) {
    // Calculate optimal font size based on available width and text length
    double baseFontSize = 14.0;

    // Adjust font size based on screen width and text length
    if (availableWidth < 180) {
      // Very small screens
      baseFontSize = title.length > 12 ? 11.0 : 12.0;
    } else if (availableWidth < 200) {
      // Small screens
      baseFontSize = title.length > 15 ? 12.0 : 13.0;
    } else {
      // Normal and large screens
      baseFontSize = title.length > 20 ? 12.0 : 14.0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle = TextStyle(
          fontFamily: 'Open Sans',
          fontSize: baseFontSize,
          fontWeight: FontWeight.w600,
          color: isActivated
              ? (appController.isDarkModeOn.value
                  ? Colors.white
                  : Color(0xFF382F41))
              : (appController.isDarkModeOn.value
                  ? Colors.white.withOpacity(0.5)
                  : Colors.grey),
          height: 1.2, // Tighter line height
        );

        // Check if text fits in one line
        final textPainter = TextPainter(
          text: TextSpan(text: title, style: textStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);

        // If text fits in one line or is very short, use single line
        if (!textPainter.didExceedMaxLines || title.length < 8) {
          return Text(
            title,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
          );
        }

        // For longer text that needs 2 lines, use FittedBox with careful handling
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth *
                  1.2, // Allow slight overflow for better fitting
            ),
            child: Text(
              title,
              style: textStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ),
        );
      },
    );
  }

  // Removed _buildSelectButton as we navigate directly on tap

  void _onPaymentMethodTap(RoutePaymentModel paymentMethod, int index) {
    if (!paymentMethod.isActivated || paymentMethod.acquirerVoid == null) {
      Get.snackbar(
        CommonConstants.oops.tr,
        CommonConstants.paymentMethodNotSupportRefund.tr,
        backgroundColor: ColorConstants.backgroundColorButtonPrint,
        colorText: ColorConstants.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
      );
      return;
    }

    // Navigate directly to refund screen
    _navigateToRefundScreen(paymentMethod);
  }

  void _navigateToRefundScreen(RoutePaymentModel selectedPayment) {
    if (selectedPayment.acquirerVoid == ConstantsO7Lite.DASH_TYPE) {
      CustomDialog.showToast(CommonConstants.textNotSupportVoidDashPAY);
      return;
    } else if (selectedPayment.acquirerVoid == ConstantsO7Lite.IOUPAY_TYPE) {
      CustomDialog.showToast(CommonConstants.textNotSupportVoidIOUPAY);
      return;
    }

    var reportModel = RoutePaymentModel(
      acquireReport: selectedPayment.acquireReport,
      currency: selectedPayment.currency,
      creditCardActivated:
          selectedPayment.creditCardActivated ?? CommonConstants.textEmpty,
      isBoost: selectedPayment.isBoost,
      brand: selectedPayment.brand,
      image: '',
      isActivated: selectedPayment.isActivated,
    );

    Get.toNamed(
      Routes.REFUND_SCREEN,
      arguments: reportModel,
    );
  }

  // Removed _onSelectPressed as we navigate directly on tap

  // Legacy methods - keeping for backward compatibility
  bool isTransactionFailed({required String inputTransactionState}) {
    switch (inputTransactionState) {
      case TransactionState.STATE_USER_PAYING:
        return false;
      case TransactionState.STATE_ORDER_CLOSED:
      case TransactionState.STATE_DENIED:
      case TransactionState.STATE_SETTLEMENT_REJECTED:
        return true;
      case TransactionState.STATE_SUCCESS:
      case TransactionState.STATE_AUTHORIZED:
      case TransactionState.STATE_SETTLEMENT_SUBMITTED:
        return false;
      case TransactionState.STATE_REVERSED:
      case TransactionState.STATE_VOIDED:
        return false;
      case TransactionState.STATE_REFUNDED:
        return false;
      default:
        false;
        break;
    }
    return true;
  }

  Widget setTransactionState({required String inputTransactionState}) {
    Color colorTransactionState = Colors.blue;
    Color colorTextTransactionState = Colors.blue;
    String mTransactionState = '';

    switch (inputTransactionState) {
      case TransactionState.STATE_USER_PAYING:
        mTransactionState = CommonConstants.paying.tr;
        colorTransactionState = Colors.grey.withOpacity(.2);
        colorTextTransactionState = Colors.grey;
        break;
      case TransactionState.STATE_ORDER_CLOSED:
      case TransactionState.STATE_DENIED:
      case TransactionState.STATE_SETTLEMENT_REJECTED:
        mTransactionState = CommonConstants.failed.tr;
        colorTransactionState = Colors.red.withOpacity(.2);
        colorTextTransactionState = Colors.red;
        break;
      case TransactionState.STATE_SUCCESS:
      case TransactionState.STATE_AUTHORIZED:
      case TransactionState.STATE_SETTLEMENT_SUBMITTED:
        mTransactionState = CommonConstants.success.tr;
        colorTransactionState = ColorConstants.greenColorBoder;
        colorTextTransactionState = ColorConstants.greenColorText;
        break;
      case TransactionState.STATE_REVERSED:
      case TransactionState.STATE_VOIDED:
        mTransactionState = CommonConstants.voided.tr;
        colorTransactionState = Colors.red.withOpacity(.2);
        colorTextTransactionState = Colors.red;
        break;
      case TransactionState.STATE_REFUNDED:
        mTransactionState = CommonConstants.refund.tr;
        colorTransactionState = Colors.red.withOpacity(.2);
        colorTextTransactionState = Colors.red;
        break;
      default:
        mTransactionState = CommonConstants.error.tr;
        colorTransactionState = Colors.red.withOpacity(.2);
        colorTextTransactionState = Colors.red;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800!
            : colorTransactionState,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        child: Text(
          mTransactionState,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: appController.isDarkModeOn.value
                ? ColorConstants.nearlyWhite
                : colorTextTransactionState,
            fontSize: ResponsiveUtil().getFontSize(
              12,
            ),
          ),
        ),
      ),
    );
  }

  Widget setImageBrand({required String brandName}) {
    final Map<String, String> brandIcons = {
      ConstantsO7Lite.BRAND_ALIPAY: ImageConstant.imageAlipay,
      ConstantsO7Lite.BRAND_ALIPAY_NEW: ImageConstant.imageAlipay,
      ConstantsO7Lite.BRAND_WECHAT: ImageConstant.imageWechatPay,
      ConstantsO7Lite.BRAND_WECHAT_NEW: ImageConstant.imageWechatPay,
      ConstantsO7Lite.BRAND_GRABPAY: ImageConstant.imageGrabPay,
      ConstantsO7Lite.BRAND_GRABPAY2: ImageConstant.imageGrabPay,
      ConstantsO7Lite.BRAND_GRABPAY3: ImageConstant.imageGrabPay,
      ConstantsO7Lite.BRAND_VISA: ImageConstant.iconVisaTxn,
      ConstantsO7Lite.BRAND_MASTERCARD: ImageConstant.iconMasterCardTxn,
      ConstantsO7Lite.BRAND_AMEX: ImageConstant.iconAmexTxn,
      ConstantsO7Lite.BRAND_DINERS: ImageConstant.iconDinersTxn,
      ConstantsO7Lite.BRAND_DISCOVER: ImageConstant.iconDiscoverTxn,
      ConstantsO7Lite.BRAND_RUPAY: ImageConstant.iconDiscoverTxn,
      ConstantsO7Lite.BRAND_ATOME: ImageConstant.imageAtome,
      ConstantsO7Lite.BRAND_THAIQR: ImageConstant.imageThaiQR,
      ConstantsO7Lite.BRAND_PAYNOW: ImageConstant.imagePaynow,
      ConstantsO7Lite.BRAND_PAYNOW2: ImageConstant.imagePaynow,
      ConstantsO7Lite.BRAND_CUP: ImageConstant.iconCupTxn,
      ConstantsO7Lite.BRAND_QUICKPASS: ImageConstant.iconCupTxn,
      ConstantsO7Lite.BRAND_ENETS: ImageConstant.iconMCPTxn,
      ConstantsO7Lite.BRAND_DASH: ImageConstant.imageSingleDash,
      ConstantsO7Lite.BRAND_BOOST: ImageConstant.imageBoost,
      ConstantsO7Lite.BRAND_TNG: ImageConstant.iconTouchNGoEWallet,
      ConstantsO7Lite.BRAND_SHOPEE: ImageConstant.imageShopeePay,
      ConstantsO7Lite.BRAND_IOUPAY: ImageConstant.imageIOUPay,
    };

    final imageBrand = brandIcons[brandName] ?? ImageConstant.iconMCPTxn;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        imageBrand,
        height: ResponsiveUtil().getSize(60),
        width: ResponsiveUtil().getSize(60),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget setTextTransactionTime({required String inputTransactionTime}) {
    var transactiontime = StringUtils.formatResponeDateTimeToString(
        inputTransactionTime, StringUtils.dateFormatddMMyyyyHHMMss);

    return Text(
      transactiontime,
      maxLines: 1,
      style: CustomTextStyles.labelGray500Size12Fw400,
    );
  }

  Widget setTextTransactionAmount({
    required String inputTransactionAmount,
    required String inputTransactionState,
    required String currency,
  }) {
    var transactionAmount = inputTransactionAmount;
    Color colorTransactionAmount = Colors.black;

    switch (inputTransactionState) {
      case TransactionType.PREAUTH:
      case TransactionType.SALES:
      case TransactionType.QUICK_PAY:
      case TransactionType.UNIFIED_ORDER:
        transactionAmount =
            '$currency ${StringUtils.formatAmount(double.parse(StringUtils.toDollars(inputTransactionAmount)), "#,##0.00")}';

        colorTransactionAmount = Colors.black;
        break;
      case TransactionType.REFUND:
      case TransactionType.VOID:
      case TransactionType.REVERSE:
      case TransactionType.EWALLET_VOID:
        transactionAmount =
            '$currency -${StringUtils.formatAmount(double.parse(StringUtils.toDollars(inputTransactionAmount)), "#,##0.00")}';
        colorTransactionAmount = appTheme.red300;
        break;
      default:
        break;
    }

    return Text(
      transactionAmount,
      maxLines: 1,
      style: TextStyle(
        color: appController.isDarkModeOn.value
            ? appTheme.whiteA700
            : colorTransactionAmount,
        fontSize: ResponsiveUtil().getFontSize(
          14,
        ),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
