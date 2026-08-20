// ignore_for_file: deprecated_member_use
import 'package:app/routes/app_pages.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import 'package:qr_flutter/qr_flutter.dart';
import '../../../app_controller.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/constants_o7lite.dart';
import '../../../shared/utils/responsive_util.dart';
import '../../../shared/widgets/custom_text_style.dart';
import '../../../shared/widgets/string_utils.dart';
import '../../../shared/constants/common.dart';
import '../../../shared/constants/image_constant.dart';
import '../../../shared/services/storage_service.dart';
import 'transaction_history_detail_controller.dart';

class TransactionHistoryDetail
    extends GetView<TransactionHistoryDetailController> {
  TransactionHistoryDetail({Key? key}) : super(key: key);
  final AppController appController = Get.find();

  /// Checks if the transaction has a non-zero service charge
  bool _hasServiceCharge() {
    final serviceAmount =
        controller.resultReceiptInfoData.value?.serviceAmount ?? '0';
    try {
      final amount = double.tryParse(serviceAmount) ?? 0;
      return amount > 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.back();
        return false;
      },
      child: Obx(
        () => Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: StorageService.isGw3
              ? (appController.isDarkModeOn.value
                  ? ColorConstants.darkScaffoldBackgroundColor
                  : Color(0xFFFBFBFB))
              : (appController.isDarkModeOn.value ? null : Color(0xffD9D9D9)),
          appBar: StorageService.isGw3
              ? _buildGw3AppBar(context)
              : _buildLegacyAppBar(context),
          body: StorageService.isGw3
              ? _buildGw3Layout(context)
              : _buildLegacyLayout(context),
        ),
      ),
    );
  }

  // GW3 AppBar following Figma design
  PreferredSizeWidget _buildGw3AppBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      title: Text(
        CommonConstants.transactionDetail.tr,
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
      actions: [
        Obx(
          () => controller.isBtnReceiptRefundEnable.value
              ? TextButton(
                  child: Text(
                    CommonConstants.refund.tr,
                    style: TextStyle(
                      color: Color(0xFFF75145),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                  onPressed: () => controller.onRefundClicked(context),
                )
              : SizedBox(),
        )
      ],
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
    );
  }

  // Legacy AppBar
  PreferredSizeWidget _buildLegacyAppBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: Text(
        CommonConstants.transactionDetail.tr,
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
      actions: [
        Obx(
          () => controller.isBtnReceiptRefundEnable.value
              ? TextButton(
                  child: Text(
                    CommonConstants.refund.tr,
                    style: TextStyle(
                        color: ColorConstants.red,
                        fontSize: ResponsiveUtil().getFontSize(16),
                        fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => controller.onRefundClicked(context),
                )
              : SizedBox(),
        )
      ],
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
    );
  }

  // GW3 Layout following Figma design
  Widget _buildGw3Layout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RefreshIndicator(
        onRefresh: () async {
          controller.onRefresh();
        },
        child: Column(
          children: [
            // Content area
            Expanded(
              child: SingleChildScrollView(
                controller: controller.scrollController,
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 16),

                    // Main receipt card
                    RepaintBoundary(
                      key: controller.cardKey,
                      child: Container(
                        width: double.infinity,
                        color: appController.isDarkModeOn.value
                            ? ColorConstants.grey800
                            : Colors.white,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: appController.isDarkModeOn.value
                                ? ColorConstants.grey800
                                : Colors.white,
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
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                // Brand logo - smaller size
                                RepaintBoundary(
                                  child: _buildGw3Logo(),
                                ),

                                SizedBox(height: 16),

                                // Merchant info
                                _buildGw3MerchantInfo(),

                                SizedBox(height: 16),

                                // Transaction details
                                _buildGw3TransactionDetails(),

                                SizedBox(height: 16),

                                // Divider
                                Divider(
                                  color: appController.isDarkModeOn.value
                                      ? Color(0xFF4A5568)
                                      : Color(0xFFCFD3D0),
                                  thickness: 1,
                                ),

                                SizedBox(height: 16),

                                // QR/Barcode with container
                                RepaintBoundary(
                                  key: controller.barCodeKey,
                                  child: _buildGw3Barcode(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 100), // Space for bottom buttons
                  ],
                ),
              ),
            ),

            // Hidden print layout with larger fonts for thermal printer output.
            // Uses ClipRect+Align(heightFactor:0) so the widget is laid out and
            // painted (capturable by toImage) but takes zero visible space.
            // Offstage skips painting entirely, breaking capturePng.
            ClipRect(
              child: Align(
                alignment: Alignment.topLeft,
                heightFactor: 0,
                child: RepaintBoundary(
                  key: controller.printCardKey,
                  child: Container(
                    width: 380,
                    color: Colors.white,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                            height: 90,
                            child: controller.setImageBrandForPrint()),
                        SizedBox(height: 16),
                        _buildPrintMerchantInfo(),
                        SizedBox(height: 16),
                        _buildPrintTransactionDetails(),
                        SizedBox(height: 16),
                        Divider(color: Color(0xFFCFD3D0), thickness: 1),
                        SizedBox(height: 16),
                        _buildPrintBarcode(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom buttons
            _buildGw3BottomButtons(context),
          ],
        ),
      ),
    );
  }

  // Legacy Layout (unchanged)
  Widget _buildLegacyLayout(BuildContext context) {
    return Padding(
      padding: ResponsiveUtil().getPadding(all: 8),
      child: RefreshIndicator(
        onRefresh: () async {
          controller.onRefresh();
        },
        child: Column(
          children: [
            Expanded(
              flex: 9,
              child: Scrollbar(
                controller: controller.scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: controller.scrollController,
                  child: RepaintBoundary(
                    key: controller.cardKey,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: appController.isDarkModeOn.value
                            ? ColorConstants.white
                            : ColorConstants.white,
                      ),
                      child: Padding(
                        padding: ResponsiveUtil().getPadding(all: 12),
                        child: Column(
                          children: [
                            Center(
                              child: controller.setImageBrand(),
                            ),
                            SizedBox(height: ResponsiveUtil().getSize(10)),
                            controller.setMerchantName(),
                            _buildLegacyMerchantAddress(),
                            SizedBox(height: ResponsiveUtil().getSize(10)),
                            Divider(
                                color: appController.isDarkModeOn.value
                                    ? Colors.black
                                    : Colors.black),
                            rowInput(
                              title: controller.setTextTransactionType(),
                              description: controller.setTextTransactionState(),
                              textTitleSize: ResponsiveUtil().getFontSize(30),
                              textDescriptionSize:
                                  ResponsiveUtil().getFontSize(23),
                              padding: ResponsiveUtil().getSize(50),
                              textFontWeight: FontWeight.w400,
                            ),
                            Divider(
                                color: appController.isDarkModeOn.value
                                    ? Colors.black
                                    : Colors.black),
                            Padding(
                              padding: ResponsiveUtil().getPadding(
                                top: 5.0,
                                bottom: 5.0,
                              ),
                              child: rowInput(
                                textTitleSize: ResponsiveUtil().getFontSize(21),
                                textDescriptionSize:
                                    ResponsiveUtil().getFontSize(19),
                                title: CommonConstants.time.tr,
                                description:
                                    StringUtils.formatResponeDateTimeToString(
                                        controller.setTextTransactionTime(),
                                        StringUtils.dateFormatddMMyyyyHHMMss),
                                padding: ResponsiveUtil().getSize(50),
                                textFontWeight: FontWeight.w400,
                              ),
                            ),
                            Divider(
                                color: appController.isDarkModeOn.value
                                    ? Colors.black
                                    : Colors.black),
                            Obx(
                              () => rowInputRightTextBottom(
                                title: CommonConstants.itemDescription.tr,
                                textTitleSize: ResponsiveUtil().getFontSize(21),
                                textDescriptionSize:
                                    ResponsiveUtil().getFontSize(19),
                                description: controller.getItemDescription(),
                                padding: ResponsiveUtil().getSize(10),
                                textFontWeight: FontWeight.w400,
                              ),
                            ),
                            Divider(
                                color: appController.isDarkModeOn.value
                                    ? Colors.black
                                    : Colors.black),
                            controller.isMobileUser.value && _hasServiceCharge()
                                ? Column(
                                    children: [
                                      rowInput(
                                        title:
                                            CommonConstants.saleAmountLabel.tr,
                                        description: controller.saleAmount(),
                                        padding: ResponsiveUtil().getSize(60),
                                        textFontWeight: FontWeight.w500,
                                        textTitleSize:
                                            ResponsiveUtil().getFontSize(16),
                                        textDescriptionSize:
                                            ResponsiveUtil().getFontSize(23),
                                      ),
                                      Divider(
                                          color:
                                              appController.isDarkModeOn.value
                                                  ? Colors.black
                                                  : Colors.black),
                                      rowInput(
                                        title: CommonConstants.serviceCharge.tr,
                                        description: controller.serviceCharge(),
                                        padding: ResponsiveUtil().getSize(60),
                                        textFontWeight: FontWeight.w500,
                                        textTitleSize:
                                            ResponsiveUtil().getFontSize(16),
                                        textDescriptionSize:
                                            ResponsiveUtil().getFontSize(23),
                                      ),
                                      Divider(
                                          color:
                                              appController.isDarkModeOn.value
                                                  ? Colors.black
                                                  : Colors.black),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                            controller.messageTransactionState.value ==
                                        CommonConstants.voided.tr ||
                                    controller.messageTransactionState.value ==
                                        CommonConstants.refunded.tr
                                ? rowInput(
                                    title: CommonConstants.total.tr,
                                    textTitleSize:
                                        ResponsiveUtil().getFontSize(32),
                                    textDescriptionSize:
                                        ResponsiveUtil().getFontSize(24),
                                    description: controller.getTxnAmount(),
                                    descriptionTextColor:
                                        controller.colorTextTransactionAmount,
                                    titleTextColor: Colors.red[700],
                                    padding: ResponsiveUtil().getSize(60),
                                    textFontWeight: FontWeight.w600,
                                    lineThrough: true,
                                  )
                                : rowInput(
                                    title: CommonConstants.total.tr,
                                    textTitleSize:
                                        ResponsiveUtil().getFontSize(32),
                                    textDescriptionSize:
                                        ResponsiveUtil().getFontSize(24),
                                    description: controller.getTxnAmount(),
                                    descriptionTextColor:
                                        controller.colorTextTransactionAmount,
                                    padding: ResponsiveUtil().getSize(60),
                                    textFontWeight: FontWeight.w600,
                                  ),
                            Divider(
                                color: appController.isDarkModeOn.value
                                    ? Colors.black
                                    : Colors.black),
                            rowInput(
                              title: CommonConstants.textTID,
                              description: controller.getTermialID(),
                              padding: ResponsiveUtil().getSize(60),
                              textFontWeight: FontWeight.w400,
                              textTitleSize: ResponsiveUtil().getFontSize(28),
                              textDescriptionSize:
                                  ResponsiveUtil().getFontSize(23),
                            ),
                            Divider(
                                color: appController.isDarkModeOn.value
                                    ? Colors.black
                                    : Colors.black),
                            rowInput(
                              textTitleSize: ResponsiveUtil().getFontSize(23),
                              textDescriptionSize:
                                  ResponsiveUtil().getFontSize(20),
                              title: "${CommonConstants.transactionId.tr} : ",
                              description: controller.getTransactionID(),
                              padding: ResponsiveUtil().getSize(60),
                              textFontWeight: FontWeight.w400,
                            ),
                            SizedBox(height: ResponsiveUtil().getSize(10)),
                            Padding(
                              padding: ResponsiveUtil().getPadding(
                                top: 10.0,
                                bottom: 10.0,
                              ),
                              child: setBarcode(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtil().getSize(8)),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  controller.isMobileUser.value ||
                          controller.isUserPayingOrNotPaid()
                      ? const SizedBox.shrink()
                      : Expanded(
                          flex: 1,
                          child: buttonWidget(
                            title: CommonConstants.print.tr,
                            onPress: () {
                              controller.onPrintClicked(context);
                            },
                            icon: ImageConstant.iconPrint,
                            isEnable: controller.isActiveBtn.value,
                          ),
                        ),
                  controller.isMobileUser.value
                      ? const SizedBox.shrink()
                      : SizedBox(width: ResponsiveUtil().getSize(6)),
                  controller.isEnableEmailReceipt.value
                      ? Expanded(
                          flex: 1,
                          child: buttonWidget(
                            title: CommonConstants.emailLabel.tr,
                            onPress: () async {
                              controller.onSendEmailReceiptClicked(context);
                            },
                            icon: ImageConstant.iconSendEmail,
                            isEnable: controller.isActiveBtn.value,
                          ),
                        )
                      : const SizedBox.shrink(),
                  controller.isEnableEmailReceipt.value
                      ? SizedBox(width: ResponsiveUtil().getSize(6))
                      : const SizedBox.shrink(),
                  Expanded(
                    flex: 1,
                    child: buttonWidget(
                      title: CommonConstants.home.tr,
                      icon: ImageConstant.iconBottomHome,
                      onPress: () {
                        Get.offAllNamed(Routes.HOME);
                      },
                      isEnable: controller.isActiveBtn.value,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // GW3 Logo with smaller size
  Widget _buildGw3Logo() {
    return SizedBox(
      height: 90, // Reduced from larger default size
      child: controller.setImageBrand(),
    );
  }

  // GW3 Merchant Info Section
  Widget _buildGw3MerchantInfo() {
    final merchantInfo = controller.resultReceiptInfoData.value?.merchant;
    final address = merchantInfo?.address;

    // Build address lines, filtering out null/empty values
    final List<String> addressLines = [];

    final line1 = address?.line1?.trim() ?? '';
    final line2 = address?.line2?.trim() ?? '';
    final line3 = address?.line3?.trim() ?? '';

    if (line1.isNotEmpty) addressLines.add(line1);
    if (line2.isNotEmpty) addressLines.add(line2);
    if (line3.isNotEmpty) addressLines.add(line3);

    // Build location/postal line
    final postalCode = address?.postalCode?.trim() ?? '';
    final city = address?.city?.trim() ?? '';
    final country = address?.country?.trim() ?? '';
    final location = country.isNotEmpty ? country : city;

    String locationPostal = '';
    if (location.isNotEmpty && postalCode.isNotEmpty) {
      locationPostal = "$location, $postalCode";
    } else if (location.isNotEmpty) {
      locationPostal = location;
    } else if (postalCode.isNotEmpty) {
      locationPostal = postalCode;
    }

    if (locationPostal.isNotEmpty) addressLines.add(locationPostal);

    return Column(
      children: [
        // Merchant name with smaller font
        _buildMerchantName(),
        if (addressLines.isNotEmpty) ...[
          SizedBox(height: 4),
          _buildMerchantAddressLines(addressLines),
        ],
      ],
    );
  }

  Widget _buildMerchantName() {
    // Use controller method but with GW3 styling
    return DefaultTextStyle.merge(
      style: TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color:
            appController.isDarkModeOn.value ? Colors.white : Color(0xFF382F41),
      ),
      textAlign: TextAlign.center,
      child: controller.setMerchantName(),
    );
  }

  TextStyle _getMerchantAddressStyle() {
    return TextStyle(
      fontFamily: 'Open Sans',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: appController.isDarkModeOn.value
          ? Colors.white.withOpacity(0.8)
          : Colors.black,
    );
  }

  Widget _buildMerchantAddressLines(List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: lines.asMap().entries.map((entry) {
        final index = entry.key;
        final line = entry.value;
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 2),
          child: Text(
            line,
            textAlign: TextAlign.center,
            style: _getMerchantAddressStyle(),
          ),
        );
      }).toList(),
    );
  }

  // GW3 Transaction Details Section
  Widget _buildGw3TransactionDetails() {
    return Column(
      children: [
        // Transaction type and status in same row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Transaction type
            Text(
              controller.setTextTransactionType(),
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: appController.isDarkModeOn.value
                    ? Colors.white
                    : Color(0xFF382F41),
              ),
            ),

            // Transaction status container
            _buildGw3StatusContainer(),
          ],
        ),

        SizedBox(height: 12),

        // Divider
        Divider(
          color: appController.isDarkModeOn.value
              ? Color(0xFF4A5568)
              : Color(0xFFCFD3D0),
          thickness: 1,
        ),

        SizedBox(height: 12),

        // Time
        _buildGw3DetailRow(
          title: CommonConstants.time.tr,
          value: StringUtils.formatResponeDateTimeToString(
            controller.setTextTransactionTime(),
            StringUtils.dateFormatddMMyyyyHHMMss,
          ),
        ),

        SizedBox(height: 12),

        Divider(
          color: appController.isDarkModeOn.value
              ? Color(0xFF4A5568)
              : Color(0xFFCFD3D0),
          thickness: 1,
        ),

        SizedBox(height: 12),

        // Item description
        Obx(() => _buildGw3DetailColumn(
              title: CommonConstants.itemDescription.tr,
              value: controller.getItemDescription(),
            )),

        SizedBox(height: 12),

        Divider(
          color: appController.isDarkModeOn.value
              ? Color(0xFF4A5568)
              : Color(0xFFCFD3D0),
          thickness: 1,
        ),

        SizedBox(height: 12),

        // Service charge section (if applicable and has value)
        if (controller.isMobileUser.value && _hasServiceCharge()) ...[
          _buildGw3DetailRow(
            title: CommonConstants.saleAmountLabel.tr,
            value: controller.saleAmount(),
          ),
          SizedBox(height: 12),
          _buildGw3DetailRow(
            title: CommonConstants.serviceCharge.tr,
            value: controller.serviceCharge(),
          ),
          SizedBox(height: 12),
          Divider(
            color: appController.isDarkModeOn.value
                ? Color(0xFF4A5568)
                : Color(0xFFCFD3D0),
            thickness: 1,
          ),
          SizedBox(height: 12),
        ],

        // Total amount
        _buildGw3DetailRow(
          title: CommonConstants.total.tr,
          value: controller.getTxnAmount(),
          isTotal: true,
          isVoided: controller.messageTransactionState.value ==
                  CommonConstants.voided.tr ||
              controller.messageTransactionState.value ==
                  CommonConstants.refunded.tr ||
              controller.messageTransactionState.value ==
                  CommonConstants.statusCancelled.tr,
          valueColor: controller.colorTextTransactionAmount,
        ),

        SizedBox(height: 12),

        Divider(
          color: appController.isDarkModeOn.value
              ? Color(0xFF4A5568)
              : Color(0xFFCFD3D0),
          thickness: 1,
        ),

        SizedBox(height: 12),

        // Terminal ID
        _buildGw3DetailRow(
          title: CommonConstants.textTID,
          value: controller.getTermialID(),
        ),

        SizedBox(height: 12),

        Divider(
          color: appController.isDarkModeOn.value
              ? Color(0xFF4A5568)
              : Color(0xFFCFD3D0),
          thickness: 1,
        ),

        SizedBox(height: 12),

        // Transaction ID
        _buildGw3DetailRow(
          title: "${CommonConstants.transactionId.tr}:",
          value: controller.getTransactionID(),
        ),
      ],
    );
  }

  // GW3 Detail Row Widget
  Widget _buildGw3DetailRow({
    required String title,
    required String value,
    bool isLarge = false,
    bool isTotal = false,
    bool isVoided = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: isLarge ? 18 : (isTotal ? 20 : 14),
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: (isVoided && isTotal)
                  ? Colors.red[700]
                  : (appController.isDarkModeOn.value
                      ? Colors.white
                      : Color(0xFF382F41)),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: isLarge ? 16 : (isTotal ? 18 : 14),
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: valueColor ??
                  (appController.isDarkModeOn.value
                      ? Colors.white
                      : Color(0xFF382F41)),
              decoration:
                  (isVoided && isTotal) ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
  }

  // GW3 Detail Column Widget (for long descriptions)
  Widget _buildGw3DetailColumn({
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: appController.isDarkModeOn.value
                ? Colors.white
                : Color(0xFF382F41),
          ),
        ),
        SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            value.isNotEmpty ? value : CommonConstants.textEmpty,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: appController.isDarkModeOn.value
                  ? Colors.white
                  : Color(0xFF382F41),
            ),
          ),
        ),
      ],
    );
  }

  // GW3 Status Container with border and color
  Widget _buildGw3StatusContainer() {
    final status = controller.setTextTransactionState();
    Color borderColor;
    Color backgroundColor;

    // Use raw transaction state for color determination (i18n-safe)
    final rawState = controller.transactionState.value;

    if (rawState == GW3TransactionState.APPROVED ||
        rawState == GW3TransactionState.CAPTURED ||
        rawState == GW3TransactionState.AUTHORIZED) {
      // Green for success states including Captured
      borderColor = Color(0xFF10B981);
      backgroundColor = Color(0xFF10B981).withOpacity(0.1);
    } else if (rawState == GW3TransactionState.VOIDED ||
        rawState == GW3TransactionState.REFUNDED ||
        rawState == GW3TransactionState.REJECTED ||
        rawState == GW3TransactionState.ERROR ||
        rawState == GW3TransactionState.EXPIRED ||
        rawState == GW3TransactionState.CANCELLED) {
      // Red for failed/voided/refunded/cancelled states
      borderColor = Color(0xFFF75145);
      backgroundColor = Color(0xFFF75145).withOpacity(0.1);
    } else {
      // Amber for pending/requested/unknown states
      borderColor = Color(0xFFF59E0B);
      backgroundColor = Color(0xFFF59E0B).withOpacity(0.1);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        // border: Border.all(color: borderColor, width: 0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: 'Open Sans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: borderColor,
        ),
      ),
    );
  }

  // GW3 Barcode/QR Section with container
  Widget _buildGw3Barcode() {
    final BarcodeType barcodeType = controller.convertToBarcodeType(3);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? (ColorConstants.grey800 ?? Colors.grey[800])!.withOpacity(0.5)
            : Color(0xFFF8F9FA),
        border: Border.all(
          color: appController.isDarkModeOn.value
              ? Color(0xFF4A5568)
              : Color(0xFFE5E7EB),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (controller.setQrUrl().isNotEmpty) ...[
            QrImageView(
              data: controller.setQrUrl(),
              version: QrVersions.auto,
              size: 160, // Reduced size
            ),
            SizedBox(height: 12),
            Text(
              CommonConstants.thankDonation.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: appController.isDarkModeOn.value
                    ? Colors.white
                    : Color(0xFF382F41),
              ),
            ),
          ] else ...[
            BarcodeWidget(
              barcode: Barcode.fromType(barcodeType),
              data: controller.resultReceiptInfoData.value?.transactionId ?? '',
              width: 160,
              height: 60,
              color: appController.isDarkModeOn.value
                  ? Colors.white
                  : Colors.black,
              drawText: false,
            ),
          ],
        ],
      ),
    );
  }

  // GW3 Bottom Buttons
  Widget _buildGw3BottomButtons(BuildContext context) {
    List<Widget> buttons = [];

    // Home button - outlined style (always on the left)
    buttons.add(
      Expanded(
        child: _buildGw3Button(
          title: CommonConstants.home.tr,
          icon: ImageConstant.iconBottomHome,
          onPressed: controller.isActiveBtn.value
              ? () => Get.offAllNamed(Routes.HOME)
              : null,
          buttonType: 'outlined',
        ),
      ),
    );

    // Print button - filled style
    if (!controller.isMobileUser.value && !controller.isUserPayingOrNotPaid()) {
      buttons.add(SizedBox(width: 12));
      buttons.add(
        Expanded(
          child: _buildGw3Button(
            title: CommonConstants.print.tr,
            icon: ImageConstant.iconPrint,
            onPressed: controller.isActiveBtn.value
                ? () => controller.onPrintClicked(context)
                : null,
            buttonType: 'filled',
          ),
        ),
      );
    }

    // Email button - filled style (same as print)
    if (controller.isEnableEmailReceipt.value) {
      buttons.add(SizedBox(width: 12));
      buttons.add(
        Expanded(
          child: _buildGw3Button(
            title: CommonConstants.emailLabel.tr,
            icon: ImageConstant.iconSendEmail,
            onPressed: controller.isActiveBtn.value
                ? () => controller.onSendEmailReceiptClicked(context)
                : null,
            buttonType: 'filled',
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      child: SafeArea(
        child: Row(children: buttons),
      ),
    );
  }

  // GW3 Button Widget following Figma design
  Widget _buildGw3Button({
    required String title,
    required String icon,
    required VoidCallback? onPressed,
    required String buttonType, // 'filled' or 'outlined'
  }) {
    final isEnabled = onPressed != null;

    if (buttonType == 'filled') {
      // Filled buttons (Print, Email) - with background
      return SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isEnabled ? Color(0xFF7E01D7) : Colors.grey.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                icon,
                color: isEnabled ? Colors.white : Colors.grey,
                height: 16,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? Colors.white : Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Outlined buttons (Home) - no background, with border
      return SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: BorderSide(
              color:
                  isEnabled ? Color(0xFF7E01D7) : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                icon,
                color: isEnabled ? Color(0xFF7E01D7) : Colors.grey,
                height: 16,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? Color(0xFF7E01D7) : Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Legacy Merchant Address - filters out empty lines
  Widget _buildLegacyMerchantAddress() {
    final address = controller.resultReceiptInfoData.value?.merchant?.address;

    final List<String> addressLines = [];

    final line1 = address?.line1?.trim() ?? '';
    final line2 = address?.line2?.trim() ?? '';
    final line3 = address?.line3?.trim() ?? '';

    if (line1.isNotEmpty) addressLines.add(line1);
    if (line2.isNotEmpty) addressLines.add(line2);
    if (line3.isNotEmpty) addressLines.add(line3);

    // Build location/postal line
    final postalCode = address?.postalCode?.trim() ?? '';
    final country = address?.country?.trim() ?? '';

    String locationPostal = '';
    if (country.isNotEmpty && postalCode.isNotEmpty) {
      locationPostal = "$country, $postalCode";
    } else if (country.isNotEmpty) {
      locationPostal = country;
    } else if (postalCode.isNotEmpty) {
      locationPostal = postalCode;
    }

    if (locationPostal.isNotEmpty) addressLines.add(locationPostal);

    if (addressLines.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: addressLines.map((line) {
        return Text(
          line,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ResponsiveUtil().getFontSize(20),
            fontWeight: FontWeight.w400,
            fontFamily: ConstantsO7Lite.ARIAL_TYPE,
            color: Colors.black,
          ),
        );
      }).toList(),
    );
  }

  Widget buttonWidget({
    String? title,
    Function()? onPress,
    String? icon,
    Color? color,
    bool isEnable = true,
  }) {
    color = isEnable
        ? ColorConstants.backgroundColorButtonPrint
        : ColorConstants.greyColor;
    return SizedBox(
      height: ResponsiveUtil().getSize(60),
      child: TextButton(
        onPressed: onPress,
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(
            color,
          ),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon ?? '',
              color: Colors.white,
              height: ResponsiveUtil().getSize(24),
            ),
            SizedBox(
              width: ResponsiveUtil().getSize(8),
            ),
            Text(
              title ?? ''.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: CustomTextStyles.labelWhite700Size16Fw600,
            )
          ],
        ),
      ),
    );
  }

  Widget setBarcode() {
    final BarcodeType barcodeType = controller.convertToBarcodeType(3);

    if (controller.setQrUrl().isNotEmpty) {
      return Column(
        children: [
          RepaintBoundary(
            key: controller.barCodeKey,
            child: QrImageView(
              data: controller.setQrUrl(),
              version: QrVersions.auto,
              size: ResponsiveUtil().getSize(200),
            ),
          ),
          Text(
            CommonConstants.thankDonation.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveUtil().getFontSize(20),
              fontWeight: FontWeight.w400,
              fontFamily: 'Arial',
            ),
          ),
        ],
      );
    } else {
      return RepaintBoundary(
        key: controller.barCodeKey,
        child: BarcodeWidget(
          barcode: Barcode.fromType(barcodeType),
          data: controller.resultReceiptInfoData.value?.transactionId ?? '',
          width: ResponsiveUtil().getSize(200),
          height: ResponsiveUtil().getSize(80),
          color: appController.isDarkModeOn.value ? Colors.black : Colors.black,
          drawText: false,
        ),
      );
    }
  }

  Widget rowInputRightTextBottom({
    required String title,
    required String? description,
    Color? descriptionTextColor,
    Color? titleTextColor,
    required double padding,
    double? textTitleSize,
    double? textDescriptionSize,
    FontWeight? textFontWeight,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            title,
            style: TextStyle(
              fontSize: textTitleSize ?? ResponsiveUtil().getFontSize(18),
              color: titleTextColor ?? Colors.black,
              fontWeight: textFontWeight,
              fontFamily: ConstantsO7Lite.ARIAL_TYPE,
            ),
          ),
        ),
        Padding(
          padding: ResponsiveUtil().getPadding(
            top: 0.0,
          ),
          child: Align(
            alignment: Alignment.topRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: ResponsiveUtil().getSize(250),
              ),
              child: Text(
                description ?? CommonConstants.textEmpty,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize:
                      textDescriptionSize ?? ResponsiveUtil().getFontSize(16),
                  color: descriptionTextColor ?? Colors.black,
                  fontWeight: textFontWeight,
                  fontFamily: ConstantsO7Lite.ARIAL_TYPE,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget rowInput({
    required String title,
    required String? description,
    Color? descriptionTextColor,
    Color? titleTextColor,
    required double padding,
    double? textTitleSize,
    double? textDescriptionSize,
    FontWeight? textFontWeight,
    bool lineThrough = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: textTitleSize ?? ResponsiveUtil().getFontSize(18),
            color: titleTextColor ?? Colors.black,
            fontWeight: textFontWeight,
            fontFamily: ConstantsO7Lite.ARIAL_TYPE,
          ),
        ),
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtil().getSize(200),
            ),
            child: Text(
              description ?? CommonConstants.textEmpty,
              style: TextStyle(
                fontSize:
                    textDescriptionSize ?? ResponsiveUtil().getFontSize(18),
                color: descriptionTextColor ?? Colors.black,
                fontWeight: textFontWeight,
                fontFamily: ConstantsO7Lite.ARIAL_TYPE,
                decoration: lineThrough ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // Print-specific layout methods (20% larger fonts for thermal printer)
  // These render in a ClipRect(heightFactor:0) widget — painted but invisible, captured for print.
  // =========================================================================

  static const double _printScale = 1.2;

  Widget _buildPrintMerchantInfo() {
    final merchantInfo = controller.resultReceiptInfoData.value?.merchant;
    final address = merchantInfo?.address;
    final List<String> addressLines = [];
    final line1 = address?.line1?.trim() ?? '';
    final line2 = address?.line2?.trim() ?? '';
    final line3 = address?.line3?.trim() ?? '';
    if (line1.isNotEmpty) addressLines.add(line1);
    if (line2.isNotEmpty) addressLines.add(line2);
    if (line3.isNotEmpty) addressLines.add(line3);
    final postalCode = address?.postalCode?.trim() ?? '';
    final city = address?.city?.trim() ?? '';
    final country = address?.country?.trim() ?? '';
    final location = country.isNotEmpty ? country : city;
    String locationPostal = '';
    if (location.isNotEmpty && postalCode.isNotEmpty) {
      locationPostal = "$location, $postalCode";
    } else if (location.isNotEmpty) {
      locationPostal = location;
    } else if (postalCode.isNotEmpty) {
      locationPostal = postalCode;
    }
    if (locationPostal.isNotEmpty) addressLines.add(locationPostal);

    return Column(
      children: [
        DefaultTextStyle.merge(
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 14 * _printScale,
            fontWeight: FontWeight.w600,
            color: Color(0xFF382F41),
          ),
          textAlign: TextAlign.center,
          child: controller.setMerchantName(),
        ),
        if (addressLines.isNotEmpty) ...[
          SizedBox(height: 4),
          ...addressLines.map((line) => Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(line,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 12 * _printScale,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    )),
              )),
        ],
      ],
    );
  }

  Widget _buildPrintTransactionDetails() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(controller.setTextTransactionType(),
                style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 18 * _printScale,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF382F41))),
            // Status container with border for thermal printer visibility
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 12 * _printScale, vertical: 4 * _printScale),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(controller.setTextTransactionState(),
                  style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 14 * _printScale,
                      fontWeight: FontWeight.w600,
                      color: Colors.black)),
            ),
          ],
        ),
        SizedBox(height: 12),
        Divider(color: Color(0xFFCFD3D0), thickness: 1),
        SizedBox(height: 12),
        _buildPrintRow(
            CommonConstants.time.tr,
            StringUtils.formatResponeDateTimeToString(
                controller.setTextTransactionTime(),
                StringUtils.dateFormatddMMyyyyHHMMss)),
        SizedBox(height: 12),
        Divider(color: Color(0xFFCFD3D0), thickness: 1),
        SizedBox(height: 12),
        _buildPrintRow(CommonConstants.itemDescription.tr,
            controller.getItemDescription()),
        SizedBox(height: 12),
        Divider(color: Color(0xFFCFD3D0), thickness: 1),
        SizedBox(height: 12),
        if (controller.isMobileUser.value && _hasServiceCharge()) ...[
          _buildPrintRow(
              CommonConstants.saleAmountLabel.tr, controller.saleAmount()),
          SizedBox(height: 12),
          _buildPrintRow(
              CommonConstants.serviceCharge.tr, controller.serviceCharge()),
          SizedBox(height: 12),
          Divider(color: Color(0xFFCFD3D0), thickness: 1),
          SizedBox(height: 12),
        ],
        _buildPrintRow(CommonConstants.total.tr, controller.getTxnAmount(),
            isTotal: true),
        SizedBox(height: 12),
        Divider(color: Color(0xFFCFD3D0), thickness: 1),
        SizedBox(height: 12),
        _buildPrintRow(CommonConstants.textTID, controller.getTermialID()),
        SizedBox(height: 12),
        Divider(color: Color(0xFFCFD3D0), thickness: 1),
        SizedBox(height: 12),
        _buildPrintRow("${CommonConstants.transactionId.tr}:",
            controller.getTransactionID()),
      ],
    );
  }

  Widget _buildPrintRow(String title, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: (isTotal ? 20 : 14) * _printScale,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: Color(0xFF382F41),
            )),
        SizedBox(width: 8),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: (isTotal ? 18 : 14) * _printScale,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                color: Color(0xFF382F41),
              )),
        ),
      ],
    );
  }

  Widget _buildPrintBarcode() {
    final BarcodeType barcodeType = controller.convertToBarcodeType(3);
    if (controller.setQrUrl().isNotEmpty) {
      return Column(
        children: [
          QrImageView(
              data: controller.setQrUrl(), version: QrVersions.auto, size: 160),
          SizedBox(height: 12),
          Text(CommonConstants.thankDonation.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 14 * _printScale,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF382F41))),
        ],
      );
    } else {
      return BarcodeWidget(
        barcode: Barcode.fromType(barcodeType),
        data: controller.resultReceiptInfoData.value?.transactionId ?? '',
        width: 160,
        height: 60,
        color: Colors.black,
        drawText: false,
      );
    }
  }
}
