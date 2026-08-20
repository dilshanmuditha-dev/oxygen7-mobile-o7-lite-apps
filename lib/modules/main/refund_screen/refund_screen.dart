import 'package:app/shared/constants/constants_o7lite.dart';
import 'package:app/shared/constants/image_constant.dart';
import 'package:app/shared/shared.dart';
import 'package:app/shared/utils/responsive_util.dart';
import 'package:app/shared/widgets/custom_text_style.dart';
import 'package:app/shared/widgets/normal_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../app_controller.dart';
import '../../../shared/widgets/button.dart';
import '../../../shared/services/storage_service.dart';
import 'refund_controller.dart';

class RefundScreen extends GetView<RefundController> {
  RefundScreen({Key? key}) : super(key: key);
  final AppController appController = Get.find();

  @override
  Widget build(BuildContext context) {
    return NormalButton(
      onPressed: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: StorageService.isGw3
            ? (appController.isDarkModeOn.value
                ? ColorConstants.darkScaffoldBackgroundColor
                : Color(0xFFFBFBFB))
            : (appController.isDarkModeOn.value ? null : Colors.white),
        appBar: StorageService.isGw3 ? _buildGw3AppBar() : _buildLegacyAppBar(),
        body: StorageService.isGw3
            ? _buildGw3Layout(context)
            : _buildLegacyLayout(context),
      ),
    );
  }

  // GW3 AppBar following Figma design
  PreferredSizeWidget _buildGw3AppBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
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
        onPressed: () => Get.back(),
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
      leading: IconButton(
        onPressed: () {
          Get.back();
        },
        icon: Icon(
          Icons.arrow_back,
          color: appController.isDarkModeOn.value
              ? ColorConstants.white
              : ColorConstants.black,
          size: ResponsiveUtil().getSize(24),
        ),
      ),
      title: Text(
        CommonConstants.refund.tr,
        style: CustomTextStyles.labelBlack500Size18Fw700,
      ),
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
    );
  }

  // GW3 Layout following Figma design patterns
  Widget _buildGw3Layout(BuildContext context) {
    return Column(
      children: [
        // Content area
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: controller.transactionIdRefundFormKey,
              child: Column(
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),

                  // Refund Icon Display - Centered
                  // _buildRefundIconDisplay(),
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

  Widget _buildRefundIconDisplay() {
    return Center(
      child: controller.setImageTransactionRefundGw3(),
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Transaction ID Label
        Text(
          CommonConstants.transactionId.tr,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: appController.isDarkModeOn.value
                ? Colors.white
                : Color(0xFF382F41),
          ),
        ),

        SizedBox(height: 12),

        // Transaction ID Input Row
        _buildTransactionIdRow(),
      ],
    );
  }

  Widget _buildTransactionIdRow() {
    return Row(
      children: [
        // Transaction ID Input Field
        Expanded(
          child: _buildTransactionIdField(),
        ),

        SizedBox(width: 12),

        // Scan Button
        _buildGw3ScanButton(),
      ],
    );
  }

  Widget _buildTransactionIdField() {
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
        controller: controller.transactionIdRefundController,
        focusNode: controller.transactionIdRefundFocus,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return CommonConstants.transactionIdRequired.tr;
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
          hintText: CommonConstants.transactionId.tr,
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
        ),
      ),
    );
  }

  Widget _buildGw3ScanButton() {
    return Container(
      width: 52,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => controller.scan(),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF7E01D7),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF7E01D7).withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                ImageConstant.iconScanTransactionId,
                height: 24,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
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
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              controller.refundTransaction(Get.context!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7E01D7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(80),
              ),
              elevation: 0,
            ),
            child: Text(
              CommonConstants.refund.tr,
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
    );
  }

  // Legacy Layout for non-GW3 users
  Widget _buildLegacyLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      child: Form(
        key: controller.transactionIdRefundFormKey,
        child: Column(
          children: [
            controller.setImageTransactionRefund(),
            SizedBox(
              height: ResponsiveUtil().getSize(12),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Text(CommonConstants.transactionId.tr,
                  style: CustomTextStyles.labelBlack500Size16Fw500),
            ),
            SizedBox(
              height: ResponsiveUtil().getSize(8),
            ),
            Row(
              children: [
                Expanded(
                  child: InputField(
                    controller: controller.transactionIdRefundController,
                    hintText: CommonConstants.transactionId.tr,
                    focusNode: controller.transactionIdRefundFocus,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    checkBackgroundColorTextfield: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return CommonConstants.transactionIdRequired.tr;
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  width: ResponsiveUtil().getSize(8),
                ),
                NormalButton(
                  onPressed: () => controller.scan(),
                  child: Container(
                    padding: ResponsiveUtil().getPadding(all: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(200),
                      color: appController.isDarkModeOn.value
                          ? ColorConstants.grey800
                          : ColorConstants.backgroundColorButtonPrint,
                    ),
                    child: SvgPicture.asset(
                      ImageConstant.iconScanTransactionId,
                      height: ResponsiveUtil().getSize(20),
                    ),
                  ),
                ),
              ],
            ),
            Spacer(),
            CommonWidgets.primaryButton(
              width: double.infinity,
              text: CommonConstants.refund.tr,
              onPressed: () => controller.refundTransaction(context),
            ),
            SizedBox(
              height: ResponsiveUtil().getSize(16),
            )
          ],
        ),
      ),
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

  Widget _getPaymentMethodImage() {
    switch (controller.routePaymentModel.acquirerDigital) {
      case ConstantsO7Lite.ALIPAY_TYPE:
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.WECHAT_TYPE:
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.GRABPAY_TYPE:
      case ConstantsO7Lite.GRABPAY_V3_TYPE:
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.ATOME_TYPE:
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.PAYNOW_TYPE:
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.THAIQR_TYPE:
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.DASH_TYPE:
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.BOOST_TYPE:
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.TOUCHNGO_TYPE:
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.SHOPEE_TYPE:
        return getBrandImageWidgetV2(
          controller.routePaymentModel,
          height: 80,
          isSGPLocation: appController.isSGPLocation(),
        );
      case ConstantsO7Lite.IOUPAY_TYPE:
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
}
