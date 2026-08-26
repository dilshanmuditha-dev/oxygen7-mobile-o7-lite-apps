// ignore_for_file: deprecated_member_use, unnecessary_null_comparison, use_build_context_synchronously
import 'package:app/shared/constants/constants.dart';
import 'package:app/shared/utils/invoke.dart';
import 'package:app/shared/secure_shared_preferences/sharepreference.dart';
import 'package:app/shared/widgets/icon_button_custom.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:easy_loading_button/easy_loading_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:material_dialogs/shared/types.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../app_controller.dart';
import '../../../models/route_payment_model.dart';
import '../../../modules/main/digital_payment/digital_payment_controller.dart';
import '../../constants/colors.dart';
import '../../constants/common.dart';
import '../../constants/constants_o7lite.dart';
import '../../constants/image_constant.dart';
import '../../secure_shared_preferences/secure_shared_preferences.dart';
import '../../utils/enum/app_dialog_type.dart';
import '../../utils/responsive_util.dart';
import '../custom_text_style.dart';
import 'package:material_dialogs/material_dialogs.dart';

import '../input_field.dart';
import '../../services/storage_service.dart';
import '../qr_scanning_indicator.dart';

class CustomDialog {
  static DigitalPaymentController digitalPaymentController = Get.find();
  static AppController appController = Get.find();

  static showMaterialDialog({
    required BuildContext context,
    required Function() onPressedCheck,
    Function()? onpressCancel,
    RoutePaymentModel? routePaymentModel,
    required String? qrUrl,
    bool? isCheckEnableCloseIcon = false,
    bool? isShowLoading = false,
    RxBool? isPollingActive,
  }) {
    // Use new GW3 design for GW3 users
    if (StorageService.isGw3) {
      return _showGw3QrDialog(
        context: context,
        onPressedCheck: onPressedCheck,
        onpressCancel: onpressCancel,
        qrUrl: qrUrl,
        isShowLoading: isShowLoading ?? false,
        isPollingActive: isPollingActive,
      );
    }

    // Legacy dialog for non-GW3 users
    Dialogs.materialDialog(
      barrierDismissible: isCheckEnableCloseIcon == true ? false : true,
      context: context,
      color: appController.isDarkModeOn.value
          ? ColorConstants.grey800!
          : ColorConstants.white,
      actions: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: TextButton(
                onPressed: onpressCancel,
                style: ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(
                    appController.isDarkModeOn.value
                        ? ColorConstants.grey800
                        : ColorConstants.white,
                  ),
                  padding: MaterialStateProperty.all(
                    EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                  ),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(
                        width: 1,
                        color: appController.isDarkModeOn.value
                            ? ColorConstants.grey800!
                            : ColorConstants.backgroundColorButtonPrint,
                      ),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    CommonConstants.cancel.tr,
                    style: CustomTextStyles.labelBlue600Size16Fw500,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: ResponsiveUtil().getSize(16),
            ),
            Expanded(
              flex: 1,
              child: TextButton(
                onPressed: onPressedCheck,
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(
                    EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                  ),
                  backgroundColor: MaterialStatePropertyAll(
                    ColorConstants.backgroundColorButtonPrint,
                  ),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    CommonConstants.check.tr,
                    style: CustomTextStyles.labelWhite700Size16Fw600,
                  ),
                ),
              ),
            ),
          ],
        )
      ],
      customView: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: ResponsiveUtil().getSize(16),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              CommonConstants.customerConfirm.tr,
              textAlign: TextAlign.center,
              style: CustomTextStyles.labelBlack500Size20Fw600,
            ),
          ),
          SizedBox(
            height: ResponsiveUtil().getSize(16),
          ),
          if (qrUrl != null && qrUrl.isNotEmpty)
            QrScanningIndicator(
              lightweight: true,
              borderRadius: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: appController.isDarkModeOn.value
                      ? ColorConstants.grey800!
                      : ColorConstants.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  backgroundColor: appController.isDarkModeOn.value
                      ? Colors.white
                      : Colors.transparent,
                  data: qrUrl,
                  version: QrVersions.auto,
                  size: ResponsiveUtil().getSize(260),
                ),
              ),
            ),
          if (qrUrl == null || qrUrl.isEmpty)
            Container(
              decoration: BoxDecoration(
                color: appController.isDarkModeOn.value
                    ? ColorConstants.grey800!
                    : ColorConstants.white,
                border: Border.all(
                  color: appController.isDarkModeOn.value
                      ? ColorConstants.white
                      : Colors.black,
                  width: 6,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                ImageConstant.oxygen7IconTransparentBackgroundSmall,
                width: ResponsiveUtil().getSize(200),
                height: ResponsiveUtil().getSize(200),
              ),
            ),
          isShowLoading == true
              ? Padding(
                  padding: ResponsiveUtil().getPadding(top: 12),
                  child: CircularProgressIndicator(),
                )
              : const SizedBox.shrink()
        ],
      ),
    );
  }

  // New GW3 QR Dialog following Figma design
  static _showGw3QrDialog({
    required BuildContext context,
    required Function() onPressedCheck,
    Function()? onpressCancel,
    required String? qrUrl,
    required bool isShowLoading,
    RxBool? isPollingActive,
  }) {
    final isPosDevice = appController.isSunmiDevice.value ||
        appController.isWizarPosDevice.value ||
        appController.isLandiDevice.value;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = (screenWidth * 0.85).clamp(280.0, 400.0);
        final qrSize = (dialogWidth - 60).clamp(200.0, 320.0);
        final qrInnerSize = qrSize - 12;
        final qrImageSize = qrInnerSize - 16;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: dialogWidth,
            decoration: BoxDecoration(
              color: appController.isDarkModeOn.value
                  ? ColorConstants.grey800
                  : Color(0xFFFBFBFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  height: 48,
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'dialogWaitingCustomerConfirm'.tr,
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
                      ),
                    ],
                  ),
                ),

                // QR Code Container
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.5),
                  child: Obx(() {
                    final hasQrData = qrUrl != null && qrUrl.isNotEmpty;
                    final polling = isPollingActive?.value ?? false;
                    final showAnimation = hasQrData && polling;
                    final qrContainer = Container(
                      width: qrSize,
                      height: qrSize,
                      decoration: BoxDecoration(
                        color: appController.isDarkModeOn.value
                            ? ColorConstants.grey800
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: showAnimation
                              ? Colors.transparent
                              : (appController.isDarkModeOn.value
                                  ? Color(0xFF4A5568)
                                  : Color(0xFFCFD3D0)),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: !hasQrData
                            ? Image.asset(
                                ImageConstant
                                    .oxygen7IconTransparentBackgroundSmall,
                                width: qrInnerSize,
                                height: qrInnerSize,
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Container(
                                  width: qrInnerSize,
                                  height: qrInnerSize,
                                  color: Colors.white,
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: QrImageView(
                                      backgroundColor: Colors.white,
                                      data: qrUrl,
                                      version: QrVersions.auto,
                                      size: qrImageSize,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    );

                    // Show animated border when polling is active
                    if (showAnimation) {
                      return QrScanningIndicator(
                        lightweight: isPosDevice,
                        child: qrContainer,
                      );
                    }
                    return qrContainer;
                  }),
                ),

                // Bottom Buttons
                Container(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: onpressCancel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appController.isDarkModeOn.value
                                  ? ColorConstants.grey800
                                  : Colors.white,
                              side: BorderSide(
                                color: Color(0xFF7E01D7),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(80),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              CommonConstants.cancel.tr,
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7E01D7),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 16),

                      // Check Button
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: onPressedCheck,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF7E01D7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(80),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              CommonConstants.check.tr,
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // New GW3 Custom Dialog following Figma design
  static _showGw3CustomDialog({
    required BuildContext context,
    required Function() onPressedCheck,
    Function()? onpressCancel,
    required String? content,
    required String? titleButton,
    required AppDialogType dialogType,
    bool? isCheckEnableCloseIcon = false,
    bool? isCheckIconPng = false,
    bool? isCheckDisplayTitle = false,
    bool? isShowLoading = false,
    bool? isBarrierDismissible = false,
  }) {
    // Determine dialog properties based on type
    Color titleColor = ColorConstants.black;
    String icon = 'assets/o7lite/icons/ic_success.png';
    String title = '';
    bool isCheckBtnConfirm = false;

    switch (dialogType) {
      case AppDialogType.success:
        titleColor = Color(0xFF10B981);
        icon = 'assets/o7lite/icons/ic_success.png';
        title = CommonConstants.thankYou.tr;
        isCheckIconPng = true;
        break;
      case AppDialogType.failed:
        titleColor = Color(0xFFF75145);
        icon = 'assets/o7lite/icons/ic_fail_refund.svg';
        title = CommonConstants.failed.tr;
        break;
      case AppDialogType.confirm:
        titleColor = Color(0xFF7E01D7);
        icon = 'assets/o7lite/icons/ic_confirm.svg';
        title = CommonConstants.confirm.tr;
        isCheckBtnConfirm = true;
        break;
      case AppDialogType.warning:
        titleColor = Color(0xFFF59E0B);
        icon = 'assets/o7lite/icons/ic_warning.svg';
        title = CommonConstants.warning.tr;
        break;
      case AppDialogType.waiting_payment:
        titleColor = Color(0xFFF59E0B);
        icon = 'assets/o7lite/icons/ic_waiting_payment.png';
        title = CommonConstants.warning.tr;
        isCheckIconPng = true;
        isCheckBtnConfirm = true;
        break;
      default:
        titleColor = Color(0xFF7E01D7);
    }

    showDialog(
      context: context,
      barrierDismissible: isBarrierDismissible != true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: appController.isDarkModeOn.value
                  ? ColorConstants.grey800
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close button (if enabled)
                  if (isCheckEnableCloseIcon != true)
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () {
                          Get.back();
                        },
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.close,
                          color: appController.isDarkModeOn.value
                              ? Colors.white
                              : Color(0xFF6B7280),
                          size: 24,
                        ),
                      ),
                    ),

                  // Icon
                  isCheckIconPng == true
                      ? Image.asset(
                          icon,
                          width: 80,
                          height: 80,
                        )
                      : SvgPicture.asset(
                          icon,
                          width: 80,
                          height: 80,
                        ),

                  SizedBox(height: 16),

                  // Title (if not disabled)
                  if (isCheckDisplayTitle != true)
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: appController.isDarkModeOn.value
                            ? Colors.white
                            : Color(0xFF111827),
                      ),
                    ),

                  SizedBox(height: 8),

                  // Content
                  if (content != null && content.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        content,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: appController.isDarkModeOn.value
                              ? Colors.white.withOpacity(0.8)
                              : Color(0xFF6B7280),
                        ),
                      ),
                    ),

                  // Loading indicator
                  if (isShowLoading == true) ...[
                    SizedBox(height: 16),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF7E01D7),
                      ),
                    ),
                  ],

                  SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      // Cancel Button (only for confirm dialogs)
                      if (isCheckBtnConfirm) ...[
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: onpressCancel,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                side: BorderSide(
                                  color: Color(0xFF7E01D7),
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(80),
                                ),
                              ),
                              child: Text(
                                CommonConstants.cancel.tr,
                                style: TextStyle(
                                  fontFamily: 'Open Sans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7E01D7),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                      ],

                      // Main Action Button
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: dialogType != AppDialogType.waiting_payment
                              ? ElevatedButton(
                                  onPressed: onPressedCheck,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF7E01D7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(80),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    titleButton ?? CommonConstants.ok.tr,
                                    style: TextStyle(
                                      fontFamily: 'Open Sans',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : EasyButton(
                                  idleStateWidget: Text(
                                    titleButton ?? CommonConstants.ok.tr,
                                    style: TextStyle(
                                      fontFamily: 'Open Sans',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  loadingStateWidget: CircularProgressIndicator(
                                    strokeWidth: 3.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                  useWidthAnimation: true,
                                  useEqualLoadingStateWidgetDimension: true,
                                  width: double.infinity,
                                  borderRadius: 80.0,
                                  height: 48.0,
                                  contentGap: 6.0,
                                  buttonColor: Color(0xFF7E01D7),
                                  onPressed: onPressedCheck,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // New GW3 Confirm Password Dialog following Figma design
  static _showGw3ConfirmPasswordDialog({
    required BuildContext context,
    required Function() onPressedCheck,
    Function()? onpressCancel,
    Function()? onPressPassword,
    required String? content,
    required String? titleButton,
    required AppDialogType dialogType,
    required GlobalKey<FormState> formKey,
    required TextEditingController currentPasswordController,
    bool? isCheckEnableCloseIcon = false,
    required RxBool isPasswordVisible,
  }) async {
    final password = await SecureSharedPreferences.instance.getPassword();

    // Determine dialog properties based on type
    Color titleColor = ColorConstants.black;
    String icon = 'assets/o7lite/icons/ic_success.png';
    String title = '';
    bool isCheckIconPng = false;

    switch (dialogType) {
      case AppDialogType.success:
        titleColor = Color(0xFF10B981);
        icon = 'assets/o7lite/icons/ic_success.png';
        title = CommonConstants.thankYou.tr;
        isCheckIconPng = true;
        break;
      case AppDialogType.failed:
        titleColor = Color(0xFFF75145);
        icon = 'assets/o7lite/icons/ic_fail_refund.svg';
        title = CommonConstants.failed.tr;
        break;
      case AppDialogType.confirm:
        titleColor = Color(0xFF7E01D7);
        icon = 'assets/o7lite/icons/ic_confirm.svg';
        title = CommonConstants.confirmRefund.tr;
        break;
      case AppDialogType.on_off_password:
        titleColor = Color(0xFF7E01D7);
        icon = 'assets/o7lite/icons/ic_confirm.svg';
        title = 'dialogConfirmRefundWithPassword'.tr;
        break;
      case AppDialogType.warning:
        titleColor = Color(0xFFF59E0B);
        icon = 'assets/o7lite/icons/ic_warning.svg';
        title = CommonConstants.warning.tr;
        break;
      default:
        titleColor = Color(0xFF7E01D7);
        icon = 'assets/o7lite/icons/ic_confirm.svg';
        title = CommonConstants.confirm.tr;
    }

    showDialog(
      context: context,
      barrierDismissible: isCheckEnableCloseIcon != true,
      builder: (BuildContext context) {
        final viewInsets = MediaQuery.of(context).viewInsets;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            width: 400,
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height - viewInsets.bottom - 48,
            ),
            decoration: BoxDecoration(
              color: appController.isDarkModeOn.value
                  ? ColorConstants.grey800
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button (if enabled)
                    if (isCheckEnableCloseIcon != true)
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () {
                            Get.back();
                            currentPasswordController.clear();
                            isPasswordVisible.value = true;
                          },
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.close,
                            color: appController.isDarkModeOn.value
                                ? Colors.white
                                : Color(0xFF6B7280),
                            size: 24,
                          ),
                        ),
                      ),

                    // Icon
                    isCheckIconPng
                        ? Image.asset(
                            icon,
                            width: 80,
                            height: 80,
                          )
                        : SvgPicture.asset(
                            icon,
                            width: 80,
                            height: 80,
                          ),

                    SizedBox(height: 16),

                    // Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: appController.isDarkModeOn.value
                            ? Colors.white
                            : Color(0xFF111827),
                      ),
                    ),

                    SizedBox(height: 8),

                    // Content
                    if (content != null && content.isNotEmpty)
                      Text(
                        content,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: appController.isDarkModeOn.value
                              ? Colors.white.withOpacity(0.8)
                              : Color(0xFF6B7280),
                        ),
                      ),

                    SizedBox(height: 24),

                    // Password Input
                    Form(
                      key: formKey,
                      child: Obx(
                        () => Container(
                          decoration: BoxDecoration(
                            color: appController.isDarkModeOn.value
                                ? ColorConstants.grey800
                                : Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: appController.isDarkModeOn.value
                                  ? Color(0xFF4B5563)
                                  : Color(0xFFD1D5DB),
                              width: 1,
                            ),
                          ),
                          child: TextFormField(
                            controller: currentPasswordController,
                            obscureText: isPasswordVisible.value,
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontSize: 16,
                              color: appController.isDarkModeOn.value
                                  ? Colors.white
                                  : Color(0xFF111827),
                            ),
                            decoration: InputDecoration(
                              hintText: CommonConstants.currentPassword.tr,
                              hintStyle: TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 16,
                                color: appController.isDarkModeOn.value
                                    ? Colors.white.withOpacity(0.5)
                                    : Color(0xFF9CA3AF),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              suffixIcon: IconButton(
                                onPressed: onPressPassword,
                                icon: SvgPicture.asset(
                                  isPasswordVisible.value
                                      ? ImageConstant.imgHiddenPassWord
                                      : ImageConstant.icShowPassWord,
                                  colorFilter: ColorFilter.mode(
                                    appController.isDarkModeOn.value
                                        ? Colors.white.withOpacity(0.7)
                                        : Color(0xFF6B7280),
                                    BlendMode.srcIn,
                                  ),
                                  height: 20,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return CommonConstants.passwordIsRequired.tr;
                              }
                              // GW3 stores password as plain text, so compare directly
                              if (value != password) {
                                return CommonConstants.passwordDoesNotMatch.tr;
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 32),

                    // Buttons
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                if (onpressCancel != null) {
                                  onpressCancel();
                                }
                                isPasswordVisible.value = true;
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                side: BorderSide(
                                  color: Color(0xFF7E01D7),
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(80),
                                ),
                              ),
                              child: Text(
                                CommonConstants.cancel.tr,
                                style: TextStyle(
                                  fontFamily: 'Open Sans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7E01D7),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 16),

                        // Confirm Button
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                if (onPressedCheck != null) {
                                  onPressedCheck();
                                }
                                isPasswordVisible.value = true;
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF7E01D7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(80),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                titleButton ?? CommonConstants.confirm.tr,
                                style: TextStyle(
                                  fontFamily: 'Open Sans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static showDialogConfirmVoidTransaction({
    required BuildContext context,
    required Function() onPressedCheck,
    required String title,
    required String titleButton,
  }) {
    Dialogs.materialDialog(
      context: context,
      color: appController.isDarkModeOn.value
          ? ColorConstants.grey800!
          : ColorConstants.white,
      customViewPosition: CustomViewPosition.BEFORE_ACTION,
      customView: Text(
        title,
        textAlign: TextAlign.center,
        style: CustomTextStyles.labelBlack500Size18Fw500,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: TextButton(
                onPressed: () => Get.back(),
                style: ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(
                    appController.isDarkModeOn.value
                        ? ColorConstants.grey800
                        : ColorConstants.white,
                  ),
                  padding: MaterialStateProperty.all(
                    EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                  ),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(
                        width: 1,
                        color: appController.isDarkModeOn.value
                            ? ColorConstants.grey800!
                            : ColorConstants.backgroundColorButtonPrint,
                      ),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    CommonConstants.cancel.tr,
                    style: CustomTextStyles.labelBlue600Size16Fw500,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: ResponsiveUtil().getSize(16),
            ),
            Expanded(
              flex: 1,
              child: TextButton(
                onPressed: onPressedCheck,
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(
                    EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                  ),
                  backgroundColor: MaterialStatePropertyAll(
                    ColorConstants.backgroundColorButtonPrint,
                  ),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    titleButton,
                    style: CustomTextStyles.labelWhite700Size16Fw600,
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  //Dialogs
  static Future showAlertDialog(
    BuildContext? context,
    String text, {
    Function? onPressed,
    String? btnText,
    Widget? textTitle,
  }) async {
    await showDialog(
      context: context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: textTitle,
        backgroundColor: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : Colors.white,
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            text,
            style: TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.backgroundColorButtonPrint,
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: Text(
              btnText ?? 'ok'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ColorConstants.white,
              ),
            ),
            onPressed: () {
              if (onPressed == null) {
                Navigator.of(context).pop();
              } else {
                onPressed();
              }
            },
          )
        ],
      ),
    );
  }

  //Custom Dialog
  static showCustomDialog({
    required BuildContext context,
    required Function() onPressedCheck,
    Function()? onpressCancel,
    required String? content,
    required String? titleButton,
    required AppDialogType dialogType,
    bool? isCheckEnableCloseIcon = false,
    bool? isCheckIconPng = false,
    bool? isCheckDisplayTitle = false,
    bool? isShowLoading = false,
    bool? isBarrierDismissible = false,
  }) {
    // Use new GW3 design for GW3 users
    if (StorageService.isGw3) {
      return _showGw3CustomDialog(
        context: context,
        onPressedCheck: onPressedCheck,
        onpressCancel: onpressCancel,
        content: content,
        titleButton: titleButton,
        dialogType: dialogType,
        isCheckEnableCloseIcon: isCheckEnableCloseIcon,
        isCheckIconPng: isCheckIconPng,
        isCheckDisplayTitle: isCheckDisplayTitle,
        isShowLoading: isShowLoading,
        isBarrierDismissible: isBarrierDismissible,
      );
    }

    // Legacy dialog for non-GW3 users
    Color titleColor = ColorConstants.black;
    String icon = 'assets/o7lite/icons/ic_success.png';
    String title = '';
    bool isCheckBtnConfirm = false;

    switch (dialogType) {
      case AppDialogType.success:
        titleColor = Color(0xFF14C15A);
        icon = 'assets/o7lite/icons/ic_success.png';
        title = CommonConstants.thankYou.tr;
        isCheckIconPng = true;
        break;
      case AppDialogType.failed:
        titleColor = ColorConstants.redColor;
        icon = 'assets/o7lite/icons/ic_fail_refund.svg';
        title = CommonConstants.failed.tr;
        break;
      case AppDialogType.confirm:
        titleColor = ColorConstants.backgroundColorButtonPrint;
        icon = 'assets/o7lite/icons/ic_confirm.svg';
        title = CommonConstants.confirm.tr;
        isCheckBtnConfirm = true;
        break;
      case AppDialogType.warning:
        titleColor = ColorConstants.orangerRewardColor;
        icon = 'assets/o7lite/icons/ic_warning.svg';
        title = CommonConstants.warning.tr;
        break;
      case AppDialogType.waiting_payment:
        titleColor = ColorConstants.orangerRewardColor;
        icon = 'assets/o7lite/icons/ic_waiting_payment.png';
        title = CommonConstants.warning.tr;
        isCheckIconPng = true;
        isCheckBtnConfirm = true;
        break;

      default:
        titleColor = ColorConstants.black;
    }

    Dialogs.materialDialog(
      barrierDismissible: isBarrierDismissible == true ? false : true,
      context: context,
      color: appController.isDarkModeOn.value
          ? ColorConstants.grey800!
          : ColorConstants.white,
      actions: [
        Row(
          children: [
            isCheckBtnConfirm
                ? Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: onpressCancel,
                      style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll(
                          appController.isDarkModeOn.value
                              ? ColorConstants.grey800
                              : ColorConstants.white,
                        ),
                        padding: MaterialStateProperty.all(
                          EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                        ),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(
                              width: 1,
                              color: appController.isDarkModeOn.value
                                  ? ColorConstants.grey800!
                                  : ColorConstants.backgroundColorButtonPrint,
                            ),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          CommonConstants.cancel.tr,
                          style: CustomTextStyles.labelBlue600Size16Fw500,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(),
            isCheckBtnConfirm
                ? SizedBox(
                    width: ResponsiveUtil().getSize(16),
                  )
                : const SizedBox(),
            Expanded(
              flex: 1,
              child: dialogType != AppDialogType.waiting_payment
                  ? TextButton(
                      onPressed: onPressedCheck,
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(
                          EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                        ),
                        backgroundColor: MaterialStatePropertyAll(
                          ColorConstants.backgroundColorButtonPrint,
                        ),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          titleButton ?? '',
                          style: CustomTextStyles.labelWhite700Size16Fw600,
                        ),
                      ),
                    )
                  : EasyButton(
                      idleStateWidget: Text(
                        titleButton ?? '',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      loadingStateWidget: const CircularProgressIndicator(
                        strokeWidth: 3.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                      useWidthAnimation: true,
                      useEqualLoadingStateWidgetDimension: true,
                      width: double.infinity,
                      borderRadius: 8.0,
                      height: 40.0,
                      contentGap: 6.0,
                      buttonColor: ColorConstants.backgroundColorButtonPrint,
                      onPressed: onPressedCheck,
                    ),
            ),
          ],
        ),
      ],
      customView: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isCheckEnableCloseIcon == true
              ? const SizedBox.shrink()
              : Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    padding: ResponsiveUtil().getPadding(all: 4),
                    icon: Icon(
                      Icons.close,
                      color: appController.isDarkModeOn.value
                          ? ColorConstants.white
                          : ColorConstants.grey800,
                      size: ResponsiveUtil().getSize(24),
                    ),
                  ),
                ),
          SizedBox(
            height: ResponsiveUtil().getSize(10),
          ),
          isCheckIconPng == true
              ? Image.asset(
                  icon,
                  fit: BoxFit.fitHeight,
                  height: ResponsiveUtil().getSize(80),
                )
              : SvgPicture.asset(
                  icon,
                  fit: BoxFit.fitWidth,
                  width: ResponsiveUtil().getSize(80),
                ),
          SizedBox(
            height: ResponsiveUtil().getSize(8),
          ),
          isCheckDisplayTitle == true
              ? const SizedBox.shrink()
              : Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: ResponsiveUtil().getSize(20),
                    fontWeight: FontWeight.w600,
                  ),
                ),
          SizedBox(
            height: ResponsiveUtil().getSize(8),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              content ?? '',
              textAlign: TextAlign.center,
              style: CustomTextStyles.labelBlack500Size14Fw400,
            ),
          ),
          SizedBox(
            height: isShowLoading == true ? ResponsiveUtil().getSize(8) : 0,
          ),
          isShowLoading == true
              ? CircularProgressIndicator()
              : const SizedBox.shrink()
        ],
      ),
    );
  }

  //Custom Dialog
  static showCustomDialogConfirmPassword({
    required BuildContext context,
    required Function() onPressedCheck,
    Function()? onpressCancel,
    Function()? onPressPassword,
    required String? content,
    required String? titleButton,
    required AppDialogType dialogType,
    required GlobalKey<FormState> formKey,
    required TextEditingController currentPasswordController,
    bool? isCheckEnableCloseIcon = false,
    bool? isCheckIconPng = false,
    bool? isCheckDisplayTitle = false,
    required RxBool isPasswordVisible,
  }) async {
    // Use new GW3 design for GW3 users
    if (StorageService.isGw3) {
      return _showGw3ConfirmPasswordDialog(
        context: context,
        onPressedCheck: onPressedCheck,
        onpressCancel: onpressCancel,
        onPressPassword: onPressPassword,
        content: content,
        titleButton: titleButton,
        dialogType: dialogType,
        formKey: formKey,
        currentPasswordController: currentPasswordController,
        isCheckEnableCloseIcon: isCheckEnableCloseIcon,
        isPasswordVisible: isPasswordVisible,
      );
    }

    // Legacy dialog for non-GW3 users
    Color titleColor = ColorConstants.black;
    String icon = 'assets/o7lite/icons/ic_success.png';
    String title = '';
    bool isCheckBtnConfirm = false;
    final password = await SecureSharedPreferences.instance.getPassword();
    switch (dialogType) {
      case AppDialogType.success:
        titleColor = Color(0xFF14C15A);
        icon = 'assets/o7lite/icons/ic_success.png';
        title = CommonConstants.thankYou.tr;
        isCheckIconPng = true;
        break;
      case AppDialogType.failed:
        titleColor = ColorConstants.redColor;
        icon = 'assets/o7lite/icons/ic_fail_refund.svg';
        title = CommonConstants.failed.tr;
        break;
      case AppDialogType.confirm:
        titleColor = ColorConstants.backgroundColorButtonPrint;
        icon = 'assets/o7lite/icons/ic_confirm.svg';
        title = CommonConstants.confirmRefund.tr;
        isCheckBtnConfirm = true;
        break;
      case AppDialogType.on_off_password:
        titleColor = ColorConstants.backgroundColorButtonPrint;
        icon = 'assets/o7lite/icons/ic_confirm.svg';
        title = 'dialogConfirmRefundWithPassword'.tr;
        isCheckBtnConfirm = true;
        break;
      case AppDialogType.warning:
        titleColor = ColorConstants.orangerRewardColor;
        icon = 'assets/o7lite/icons/ic_warning.svg';
        title = CommonConstants.warning.tr;
        break;
      default:
        titleColor = ColorConstants.black;
    }

    Dialogs.materialDialog(
      barrierDismissible: isCheckEnableCloseIcon == true ? false : true,
      context: context,
      color: appController.isDarkModeOn.value
          ? ColorConstants.grey800!
          : ColorConstants.white,
      useSafeArea: false,
      actions: [
        Row(
          children: [
            isCheckBtnConfirm
                ? Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () {
                        if (onpressCancel != null) {
                          onpressCancel();
                        }
                        isPasswordVisible.value = true;
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll(
                          appController.isDarkModeOn.value
                              ? ColorConstants.grey800
                              : ColorConstants.white,
                        ),
                        padding: MaterialStateProperty.all(
                          EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                        ),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(
                              width: 1,
                              color: appController.isDarkModeOn.value
                                  ? ColorConstants.grey800!
                                  : ColorConstants.backgroundColorButtonPrint,
                            ),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          CommonConstants.cancel.tr,
                          style: CustomTextStyles.labelBlue600Size16Fw500,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(),
            isCheckBtnConfirm
                ? SizedBox(
                    width: ResponsiveUtil().getSize(16),
                  )
                : const SizedBox(),
            Expanded(
              flex: 1,
              child: TextButton(
                onPressed: () {
                  if (onPressedCheck != null) {
                    onPressedCheck();
                  }
                  isPasswordVisible.value = true;
                },
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(
                    EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                  ),
                  backgroundColor: MaterialStatePropertyAll(
                    ColorConstants.backgroundColorButtonPrint,
                  ),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    titleButton ?? '',
                    style: CustomTextStyles.labelWhite700Size16Fw600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
      customView: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isCheckEnableCloseIcon == true
              ? const SizedBox.shrink()
              : Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () {
                      Get.back();
                      currentPasswordController.clear();
                      isPasswordVisible.value = true;
                    },
                    icon: Icon(
                      Icons.close,
                      color: appController.isDarkModeOn.value
                          ? ColorConstants.white
                          : ColorConstants.grey800,
                      size: ResponsiveUtil().getSize(24),
                    ),
                  ),
                ),
          isCheckIconPng == true
              ? Image.asset(
                  icon,
                  fit: BoxFit.fitHeight,
                  height: ResponsiveUtil().getSize(100),
                )
              : SvgPicture.asset(
                  icon,
                  fit: BoxFit.fitWidth,
                  width: ResponsiveUtil().getSize(100),
                ),
          SizedBox(
            height: ResponsiveUtil().getSize(10),
          ),
          isCheckDisplayTitle == true
              ? const SizedBox.shrink()
              : Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: ResponsiveUtil().getSize(20),
                    fontWeight: FontWeight.w600,
                  ),
                ),
          SizedBox(
            height: ResponsiveUtil().getSize(10),
          ),
          Padding(
            padding: ResponsiveUtil().getPadding(
              left: 20,
              right: 20,
            ),
            child: Form(
              key: formKey,
              child: Obx(
                () => InputField(
                  counterText: '',
                  suffixIcon: IconButtonCustom(
                    onPressed: onPressPassword,
                    child: Padding(
                      padding: ResponsiveUtil().getPadding(right: 12),
                      child: SvgPicture.asset(
                        isPasswordVisible.value
                            ? ImageConstant.imgHiddenPassWord
                            : ImageConstant.icShowPassWord,
                        colorFilter: ColorFilter.mode(
                          appController.isDarkModeOn.value
                              ? ColorConstants.white
                              : ColorConstants.black,
                          BlendMode.srcIn,
                        ),
                        height: ResponsiveUtil().getSize(32),
                      ),
                    ),
                  ),
                  obscureText: isPasswordVisible.value,
                  controller: currentPasswordController,
                  hintText: CommonConstants.currentPassword.tr,
                  maxLength: AppConstants.MAX_LENGTH_PASSWORD,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return CommonConstants.passwordIsRequired.tr;
                    }
                    final passwordEncrypt =
                        encryptionHmacSHA512(value, BaseAppO7Lite.hmacKey);
                    if (passwordEncrypt != password) {
                      return CommonConstants.passwordDoesNotMatch.tr;
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static showSendReceiptEmailDialog({
    required BuildContext context,
    Function()? onCancelClicked,
    Function()? onSubmitClicked,
    required GlobalKey<FormState> formKey,
  }) {
    Dialogs.materialDialog(
      barrierDismissible: false,
      context: context,
      color: appController.isDarkModeOn.value
          ? ColorConstants.grey800!
          : ColorConstants.white,
      useSafeArea: false,
      actions: [
        Expanded(
          flex: 1,
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  if (onCancelClicked != null) {
                    onCancelClicked();
                  }
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(
                    appController.isDarkModeOn.value
                        ? ColorConstants.grey800
                        : ColorConstants.white,
                  ),
                  padding: MaterialStateProperty.all(
                    EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                  ),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(
                        width: 1,
                        color: appController.isDarkModeOn.value
                            ? ColorConstants.grey800!
                            : ColorConstants.backgroundColorButtonPrint,
                      ),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    CommonConstants.cancel.tr,
                    style: CustomTextStyles.labelBlue600Size16Fw500,
                  ),
                ),
              )
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: TextButton(
            onPressed: () {
              if (onSubmitClicked != null) {
                onSubmitClicked();
              }
            },
            style: ButtonStyle(
              padding: MaterialStateProperty.all(
                EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
              ),
              backgroundColor: MaterialStatePropertyAll(
                ColorConstants.backgroundColorButtonPrint,
              ),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Text(
                'dialogSubmit'.tr,
                style: CustomTextStyles.labelWhite700Size16Fw600,
              ),
            ),
          ),
        ),
      ],
      customView: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: Icon(
                Icons.close,
                color: appController.isDarkModeOn.value
                    ? ColorConstants.white
                    : ColorConstants.grey800,
                size: ResponsiveUtil().getSize(24),
              ),
            ),
          ),
          Text(
            'dialogSendReceipt'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorConstants.black,
              fontSize: ResponsiveUtil().getSize(20),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            height: ResponsiveUtil().getSize(10),
          ),
          Padding(
            padding: ResponsiveUtil().getPadding(
              left: 20,
              right: 20,
            ),
            child: Row(
              children: [
                Form(
                  key: formKey,
                  child: InputField(
                    counterText: '',
                    // controller: currentPasswordController,
                    hintText: 'dialogEnterEmailAddress'.tr,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'dialogEmailRequired'.tr;
                      }

                      // if value is not empty and not a valid email address then show error
                      if (value.isNotEmpty && !GetUtils.isEmail(value)) {
                        return 'dialogInvalidEmailAddress'.tr;
                      }

                      return null;
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> showSendReceiptEmailDialogV2({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required VoidCallback onCancelClicked,
    required Function(List<String>) onSubmitClicked,
  }) async {
    var isEnableCCEmail =
        await SharedPrefManager.instance.getBool('isEnableEmailCC') ?? false;
    var emailCC = null;

    if (isEnableCCEmail) {
      emailCC = await SecureSharedPreferences.instance.getEmailCC() ?? null;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Disable touch outside to dismiss
      builder: (BuildContext context) {
        return _SendReceiptEmailDialog(
          formKey: formKey,
          emailCC: emailCC,
          onCancelClicked: onCancelClicked,
          onSubmitClicked: onSubmitClicked,
          isDarkMode: appController.isDarkModeOn.value,
        );
      },
    );
  }

  // Toast
  static Future showToast(
    String message, {
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) async {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: gravity,
      timeInSecForIosWeb: 1,
      backgroundColor: ColorConstants.black.withOpacity(0.8),
      textColor: ColorConstants.white,
      fontSize: 16.0,
    );
  }

  //Dialogs
  static Future showMaterial(
    BuildContext? context,
    String text, {
    Function? onPressed,
    String? btnText,
    Widget? textTitle,
  }) async {
    await showDialog(
      context: context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: textTitle,
        backgroundColor: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : Colors.white,
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: appController.isDarkModeOn.value
                  ? ColorConstants.white
                  : ColorConstants.black,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppLogin.isO7LiteLogin
                  ? ColorConstants.secondaryColor
                  : ColorConstants.bottomSelectedColor,
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: Text(
              btnText ?? 'ok'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: appController.isDarkModeOn.value
                    ? ColorConstants.white
                    : ColorConstants.black,
              ),
            ),
            onPressed: () {
              if (onPressed == null) {
                Navigator.of(context).pop();
              } else {
                onPressed();
              }
            },
          )
        ],
      ),
    );
  }
}

class _SendReceiptEmailDialog extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final VoidCallback onCancelClicked;
  final Function(List<String>) onSubmitClicked;
  final String? emailCC;
  bool isDarkMode = false;

  _SendReceiptEmailDialog({
    required this.formKey,
    required this.emailCC,
    required this.onCancelClicked,
    required this.onSubmitClicked,
    this.isDarkMode = false,
  });

  @override
  _SendReceiptEmailDialogState createState() => _SendReceiptEmailDialogState();
}

class _SendReceiptEmailDialogState extends State<_SendReceiptEmailDialog> {
  List<TextEditingController> _controllers = [TextEditingController()];

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addEmailField() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removeEmailField(int index) {
    setState(() {
      _controllers.removeAt(index);
    });
  }

  void _submit() {
    if (widget.formKey.currentState!.validate()) {
      List<String> emails =
          _controllers.map((controller) => controller.text).toList();
      widget.onSubmitClicked(emails);
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  'dialogSendReceipt'.tr,
                  style: CustomTextStyles.labelBlack500Size24Fw600,
                ),
              ),
              Form(
                key: widget.formKey,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        widget.emailCC != null
                            ? Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 20, 0, 10),
                                child: Container(
                                  width: double
                                      .infinity, // Make the container full width
                                  decoration: BoxDecoration(
                                    color: ColorConstants
                                        .backgroundColorButtonPrint, // Background color for highlight
                                    border: Border.all(
                                      color: ColorConstants
                                          .backgroundColorButtonPrint, // Border color for highlight
                                      width: 1.0, // Border width
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        8.0), // Rounded corners
                                  ),
                                  padding: const EdgeInsets.all(
                                      10.0), // Inner padding
                                  child: Text(
                                    'dialogCcEmail'.trParams(
                                        {'email': widget.emailCC ?? ''}),
                                    style: TextStyle(
                                      fontSize: 16.0, // Text size
                                      color: Colors.white, // Text color
                                      fontWeight: FontWeight.bold, // Bold text
                                    ),
                                    textAlign: TextAlign.center, // Center text
                                  ),
                                ),
                              )
                            : SizedBox.shrink(),
                        ..._controllers.asMap().entries.map((entry) {
                          int index = entry.key;
                          TextEditingController controller = entry.value;
                          return Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: TextFormField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      labelText: 'dialogEmailAddressLabel'.tr,
                                      hintText: 'dialogEnterEmailAddress'.tr,
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                      ),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: ColorConstants
                                              .backgroundColorButtonPrint,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        borderSide: BorderSide(
                                          color: ColorConstants
                                              .backgroundColorButtonPrint, // Change focused border color
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        borderSide: BorderSide(
                                          color: Colors
                                              .redAccent, // Change error border color
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        borderSide: BorderSide(
                                          color: ColorConstants
                                              .backgroundColorButtonPrint, // Change focused error border color
                                        ),
                                      ),
                                      errorStyle: TextStyle(
                                        color: Colors.red[
                                            600], // Change error text color
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'dialogPleaseEnterEmail'.tr;
                                      }

                                      // if value is not empty and not a valid email address then show error
                                      if (value.isNotEmpty &&
                                          !GetUtils.isEmail(value)) {
                                        return 'dialogInvalidEmailAddress'.tr;
                                      }

                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              if (_controllers.length > 1)
                                IconButton(
                                  icon: Icon(Icons.remove_circle_rounded,
                                      color: Colors.red[400]),
                                  onPressed: () => _removeEmailField(index),
                                ),
                            ],
                          );
                        }).toList(),
                        IconButton(
                          icon: Icon(Icons.add_circle,
                              color: ColorConstants.backgroundColorButtonPrint,
                              size: 32),
                          onPressed: _addEmailField,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: widget.onCancelClicked,
                              style: ButtonStyle(
                                backgroundColor: widget.isDarkMode
                                    ? MaterialStatePropertyAll(
                                        Colors.transparent,
                                      )
                                    : MaterialStatePropertyAll(
                                        ColorConstants.white,
                                      ),
                                padding: MaterialStateProperty.all(
                                  EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                ),
                                shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    side: BorderSide(
                                      width: 1,
                                      color: ColorConstants
                                          .backgroundColorButtonPrint,
                                    ),
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  CommonConstants.cancel.tr,
                                  style:
                                      CustomTextStyles.labelBlue600Size16Fw500,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            TextButton(
                              onPressed: _submit,
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all(
                                  EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                ),
                                backgroundColor: MaterialStateProperty.all(
                                  ColorConstants.backgroundColorButtonPrint,
                                ),
                                shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'dialogSubmit'.tr,
                                  style:
                                      CustomTextStyles.labelWhite700Size16Fw600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.end,
              //   children: [
              //     TextButton(
              //       onPressed: widget.onCancelClicked,
              //       style: ButtonStyle(
              //         backgroundColor: MaterialStatePropertyAll(
              //           ColorConstants.white,
              //         ),
              //         padding: MaterialStateProperty.all(
              //           EdgeInsets.symmetric(
              //             horizontal: 12,
              //             vertical: 0,
              //           ),
              //         ),
              //         shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              //           RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(8.0),
              //             side: BorderSide(
              //               width: 1,
              //               color: ColorConstants.backgroundColorButtonPrint,
              //             ),
              //           ),
              //         ),
              //       ),
              //       child: Padding(
              //         padding: const EdgeInsets.symmetric(
              //           horizontal: 12,
              //           vertical: 8,
              //         ),
              //         child: Text(
              //           'Cancel',
              //           style: CustomTextStyles.labelBlue600Size16Fw500,
              //         ),
              //       ),
              //     ),
              //     SizedBox(width: 8),
              //     TextButton(
              //       onPressed: _submit,
              //       style: ButtonStyle(
              //         padding: MaterialStateProperty.all(
              //           EdgeInsets.symmetric(
              //             horizontal: 12,
              //             vertical: 0,
              //           ),
              //         ),
              //         backgroundColor: MaterialStateProperty.all(
              //           ColorConstants.backgroundColorButtonPrint,
              //         ),
              //         shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              //           RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(8.0),
              //           ),
              //         ),
              //       ),
              //       child: Padding(
              //         padding: const EdgeInsets.symmetric(
              //           horizontal: 12,
              //           vertical: 8,
              //         ),
              //         child: Text(
              //           'Submit',
              //           style: CustomTextStyles.labelWhite700Size16Fw600,
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
