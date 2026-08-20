import 'package:app/app_controller.dart';
import 'package:app/shared/constants/colors.dart';
import 'package:app/shared/constants/image_constant.dart';
import 'package:app/shared/utils/responsive_util.dart';
import 'package:app/shared/widgets/custom_text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/services/storage_service.dart';

import 'create_payment_url_controller.dart';

class CreatePaymentUrlPage2 extends GetView<CreatePaymentUrlController> {
  final AppController appController = Get.find();

  // Get the mode from arguments (scan2pay or click2pay)
  String get paymentMode {
    final args = Get.arguments as Map<String, dynamic>?;
    return args?['mode'] ?? 'scan2pay'; // Default to scan2pay
  }

  bool get isScan2PayMode => paymentMode == 'scan2pay';
  bool get isClick2PayMode => paymentMode == 'click2pay';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.darkScaffoldBackgroundColor
          : Color(0xFFFBFBFB),
      appBar: StorageService.isGw3 ? _buildGw3AppBar() : _buildLegacyAppBar(),
      body: StorageService.isGw3
          ? _buildGw3Layout(context)
          : _buildLegacyLayout(),
      floatingActionButtonLocation: StorageService.isGw3
          ? null
          : FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          StorageService.isGw3 ? null : _buildLegacyFloatingButton(),
    );
  }

  // GW3 AppBar following Figma design
  PreferredSizeWidget _buildGw3AppBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      title: Text(
        isScan2PayMode ? 'qrPaymentTitle'.tr : 'linkPaymentTitle'.tr,
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
        isScan2PayMode ? 'qrPaymentTitle'.tr : 'linkPaymentTitle'.tr,
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
    );
  }

  // GW3 Layout following Figma design
  Widget _buildGw3Layout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Content area
          Expanded(
            child: SingleChildScrollView(
              child: Obx(
                () => controller.obxQRCodeValue.value.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 24),

                          // QR Code Container (only for Scan2Pay)
                          if (isScan2PayMode) ...[
                            _buildGw3QRContainer(),
                            SizedBox(height: 24),
                            // Share Via Section (only for Scan2Pay)
                            _buildGw3ShareSection(),
                          ],

                          // Click2Pay specific content
                          if (isClick2PayMode) ...[
                            // URL Field (only for Click2Pay)
                            _buildGw3URLField(context),
                            SizedBox(height: 16),
                            _buildClick2PayContent(),
                          ],

                          SizedBox(height: 100), // Space for bottom buttons
                        ],
                      )
                    : SizedBox.shrink(),
              ),
            ),
          ),

          // Bottom Buttons
          _buildGw3BottomButtons(),
        ],
      ),
    );
  }

  // GW3 QR Container following Figma design
  Widget _buildGw3QRContainer() {
    return Container(
      width: double.infinity,
      height: 325,
      padding: EdgeInsets.all(16),
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
        child: QrImageView(
          backgroundColor: Colors.transparent,
          data: controller.obxQRCodeValue.value,
          version: QrVersions.auto,
        ),
      ),
    );
  }

  // GW3 URL Field following Figma design (only for Click2Pay)
  Widget _buildGw3URLField(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'paymentLinkTitle'.tr,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: appController.isDarkModeOn.value
                  ? Colors.white
                  : Color(0xFF382F41),
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appController.isDarkModeOn.value
                  ? Color(0xFF374151)
                  : Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: appController.isDarkModeOn.value
                    ? Color(0xFF4A5568)
                    : Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.obxQRCodeValue.value,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: appController.isDarkModeOn.value
                          ? Colors.white.withOpacity(0.8)
                          : Color(0xFF374151),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(
                            text: controller.obxQRCodeValue.value))
                        .then((_) {
                      Get.snackbar(
                        'success'.tr,
                        'msgLinkCopied'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    });
                  },
                  child: Icon(
                    Icons.content_copy,
                    size: 20,
                    color: Color(0xFF7E01D7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // GW3 Share Section following Figma design
  Widget _buildGw3ShareSection() {
    // POS devices: show scan-to-pay instruction instead of share icons
    if (!appController.isMobileUser.value) {
      return _buildPosInstructionNote();
    }

    return Obx(() {
      if (controller.isCheckingAppAvailability.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'shareVia'.tr,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: appController.isDarkModeOn.value
                    ? Colors.white
                    : Color(0xFF382F41),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      appController.isDarkModeOn.value
                          ? ColorConstants.white
                          : ColorConstants.grey800!,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'msgCheckingApps'.tr,
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
            ),
          ],
        );
      }

      List<Widget> availableApps = [];

      // Always show email (doesn't require specific app)
      availableApps.add(_buildGw3AppIcon(
        ImageConstant.iconEmail,
        () => controller.sendEmail(),
      ));

      // Conditionally add WhatsApp
      if (controller.isWhatsAppAvailable.value) {
        availableApps.add(_buildGw3AppIcon(
          ImageConstant.iconWhatsapp,
          () => _shareQRWithLink(),
        ));
      }

      // Conditionally add Facebook Messenger
      if (controller.isFacebookMessengerAvailable.value) {
        availableApps.add(_buildGw3AppIcon(
          ImageConstant.iconMessenger,
          () => _shareQRWithLink(),
        ));
      }

      // Always show iMessage/SMS (available on all devices)
      availableApps.add(_buildGw3AppIcon(
        ImageConstant.iconIMessage,
        () => _shareQRWithLink(),
      ));

      // Conditionally add Telegram
      if (controller.isTelegramAvailable.value) {
        availableApps.add(_buildGw3AppIcon(
          ImageConstant.iconTelegram,
          () => _shareQRWithLink(),
        ));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'shareVia'.tr,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: appController.isDarkModeOn.value
                  ? Colors.white
                  : Color(0xFF382F41),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: availableApps
                .take(5)
                .map((app) => Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: app,
                    ))
                .toList(),
          ),
        ],
      );
    });
  }

  // GW3 App Icon with gradient background
  Widget _buildGw3AppIcon(String iconPath, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Image.asset(
          iconPath,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // Method to share QR code with link text
  Future<void> _shareQRWithLink() async {
    try {
      final shareText = '''
🔗 Payment Link: ${controller.obxQRCodeValue.value}

📱 Scan the QR code or click the link above to make payment.
''';

      await Share.share(shareText);
    } catch (e) {
      // Fallback to simple link sharing
      await Share.share(controller.obxQRCodeValue.value);
    }
  }

  // Click2Pay specific content
  Widget _buildClick2PayContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action Buttons for Click2Pay
        Row(
          children: [
            // Open Link Button
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final urlString =
                        controller.paymentPassingData?.qrURL ?? '';
                    if (urlString.isNotEmpty) {
                      try {
                        final uri = Uri.parse(urlString);
                        bool canLaunch = await canLaunchUrl(uri);
                        if (canLaunch) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        } else {
                          Get.snackbar(
                            'error'.tr,
                            'msgCannotOpenBrowserManual'.tr,
                            backgroundColor: ColorConstants.orangeColor,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      } catch (e) {
                        Get.snackbar(
                          'error'.tr,
                          'msgInvalidUrlFormat'.tr,
                          backgroundColor: ColorConstants.orangeColor,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7E01D7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(
                    Icons.open_in_new,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: Text(
                    'btnOpenLink'.tr,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: 12),

            // Share Button
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _shareQRWithLink(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appController.isDarkModeOn.value
                        ? Color(0xFF374151)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Color(0xFF7E01D7),
                        width: 1,
                      ),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(
                    Icons.share,
                    size: 20,
                    color: Color(0xFF7E01D7),
                  ),
                  label: Text(
                    'btnShare'.tr,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7E01D7),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        // Instructions for Click2Pay
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: appController.isDarkModeOn.value
                ? Color(0xFF1F2937).withOpacity(0.5)
                : Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: appController.isDarkModeOn.value
                  ? Color(0xFF374151)
                  : Color(0xFFBAE6FD),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: appController.isDarkModeOn.value
                    ? Color(0xFF60A5FA)
                    : Color(0xFF0284C7),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'msgSharePaymentLink'.tr,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: appController.isDarkModeOn.value
                        ? Colors.white.withOpacity(0.8)
                        : Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // GW3 Bottom Buttons following Figma design
  Widget _buildGw3BottomButtons() {
    if (isClick2PayMode) {
      // For Click2Pay: Just show View Histories button (actions are above)
      return Container(
        padding: EdgeInsets.all(16),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => controller.gotoTxnHistories(),
              style: ElevatedButton.styleFrom(
                backgroundColor: appController.isDarkModeOn.value
                    ? ColorConstants.grey800
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(80),
                  side: BorderSide(
                    color: Color(0xFF7E01D7),
                    width: 1,
                  ),
                ),
                elevation: 0,
              ),
              child: Text(
                'btnHistories'.tr,
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
      );
    } else {
      // For Scan2Pay: Conditional rendering based on device type
      if (appController.isMobileUser.value) {
        // Mobile: Show both Histories + Share QR buttons
        return Container(
          padding: EdgeInsets.all(16),
          child: SafeArea(
            child: Row(
              children: [
                // View Histories Button (Outlined)
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => controller.gotoTxnHistories(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appController.isDarkModeOn.value
                            ? ColorConstants.grey800
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(80),
                          side: BorderSide(
                            color: Color(0xFF7E01D7),
                            width: 1,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'btnHistories'.tr,
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

                // Share Button (Filled)
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _shareQRWithLink(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF7E01D7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(80),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'btnShareQr'.tr,
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
        );
      } else {
        // POS: Show only full-width Histories button
        return Container(
          padding: EdgeInsets.all(16),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => controller.gotoTxnHistories(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appController.isDarkModeOn.value
                      ? ColorConstants.grey800
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(80),
                    side: BorderSide(
                      color: Color(0xFF7E01D7),
                      width: 1,
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'btnHistories'.tr,
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
        );
      }
    }
  }

  // Legacy Layout (unchanged for backward compatibility)
  Widget _buildLegacyLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Obx(
          () => controller.obxQRCodeValue.value.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: ResponsiveUtil().getSize(20)),
                    Center(
                      child: QrImageView(
                        backgroundColor: appController.isDarkModeOn.value
                            ? Colors.white
                            : Colors.transparent,
                        data: controller.obxQRCodeValue.value,
                        version: QrVersions.auto,
                        size: ResponsiveUtil().getSize(200),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtil().getSize(20)),
                    Text(
                      'URL',
                      style: CustomTextStyles.labelBlack700Size18Fw600,
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: ResponsiveUtil().getSize(10)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: appController.isDarkModeOn.value
                            ? ColorConstants.grey800
                            : ColorConstants.white,
                        border: Border.all(
                          color: appController.isDarkModeOn.value
                              ? ColorConstants.white
                              : ColorConstants.grey800 ?? Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          TextButton(
                            onPressed: () async {
                              final urlString =
                                  controller.paymentPassingData?.qrURL ?? '';
                              if (urlString.isNotEmpty) {
                                try {
                                  final uri = Uri.parse(urlString);
                                  bool canLaunch = await canLaunchUrl(uri);
                                  if (canLaunch) {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  } else {
                                    await Clipboard.setData(
                                        ClipboardData(text: urlString));
                                    Get.snackbar(
                                      'info'.tr,
                                      'cannotOpenBrowser'.tr,
                                      backgroundColor:
                                          ColorConstants.orangeColor,
                                      colorText: Colors.white,
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  }
                                } catch (e) {
                                  await Clipboard.setData(
                                      ClipboardData(text: urlString));
                                  Get.snackbar(
                                    'info'.tr,
                                    'cannotOpenURL'.tr,
                                    backgroundColor: ColorConstants.orangeColor,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              }
                            },
                            child: Text(
                              controller.obxQRCodeValue.value,
                              style: CustomTextStyles
                                  .labelBlue500Size16Fw500Underline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Positioned(
                            right: 2,
                            top: 2,
                            bottom: 2,
                            child: GestureDetector(
                              child: Icon(
                                Icons.copy,
                                size: 20,
                                color: appController.isDarkModeOn.value
                                    ? ColorConstants.white
                                    : ColorConstants.grey800,
                              ),
                              onTap: () {
                                Clipboard.setData(ClipboardData(
                                        text: controller.obxQRCodeValue.value))
                                    .then((_) {
                                  Get.snackbar(
                                    'success'.tr,
                                    'msgCopiedToClipboard'.tr,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                });
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: ResponsiveUtil().getSize(40)),
                    _buildLegacyShareSection(),
                  ],
                )
              : SizedBox.shrink(),
        ),
      ),
    );
  }

  // Legacy Floating Action Button
  Widget? _buildLegacyFloatingButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => controller.gotoTxnHistories(),
              style: ButtonStyle(
                padding: MaterialStateProperty.all(
                  EdgeInsets.symmetric(vertical: 0),
                ),
                backgroundColor: MaterialStatePropertyAll(
                  appController.isDarkModeOn.value
                      ? ColorConstants.grey800
                      : ColorConstants.white,
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
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Text(
                  'btnHistories'.tr,
                  style: CustomTextStyles.labelBlue600Size16Fw500,
                ),
              ),
            ),
          ),
          if (appController.isMobileUser.value) ...[
            SizedBox(height: ResponsiveUtil().getSize(16)),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _shareQRWithLink(),
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
                    'btnShareMore'.tr,
                    style: CustomTextStyles.labelWhite700Size16Fw600,
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: ResponsiveUtil().getSize(20)),
        ],
      ),
    );
  }

  // POS Instruction Note — reusable across GW3 and Legacy layouts
  Widget _buildPosInstructionNote() {
    final isDark = appController.isDarkModeOn.value;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1F2937).withOpacity(0.5) : Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Color(0xFF374151) : Color(0xFFBAE6FD),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: isDark ? Color(0xFF60A5FA) : Color(0xFF0284C7),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'msgScanToPayInstruction'.tr,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color:
                    isDark ? Colors.white.withOpacity(0.8) : Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Legacy Share Section
  Widget _buildLegacyShareSection() {
    // POS devices: show scan-to-pay instruction instead of share icons
    if (!appController.isMobileUser.value) {
      return _buildPosInstructionNote();
    }

    return Obx(() {
      if (controller.isCheckingAppAvailability.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'shareViaLower'.tr,
              style: CustomTextStyles.labelBlack700Size18Fw600,
              textAlign: TextAlign.left,
            ),
            SizedBox(height: ResponsiveUtil().getSize(10)),
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      appController.isDarkModeOn.value
                          ? ColorConstants.white
                          : ColorConstants.grey800!,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'msgCheckingApps'.tr,
                  style: CustomTextStyles.labelBlack500Size14Fw600,
                ),
              ],
            ),
          ],
        );
      }

      List<Widget> availableApps = [];

      // Always show email (doesn't require specific app)
      availableApps.add(
        InkWell(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            ImageConstant.iconEmail,
            width: 44,
            height: 44,
          ),
          onTap: () => controller.sendEmail(),
        ),
      );

      // Conditionally add WhatsApp
      if (controller.isWhatsAppAvailable.value) {
        availableApps.add(
          InkWell(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              ImageConstant.iconWhatsapp,
              width: 44,
              height: 44,
            ),
            onTap: () => _shareQRWithLink(),
          ),
        );
      }

      // Conditionally add Facebook Messenger
      if (controller.isFacebookMessengerAvailable.value) {
        availableApps.add(
          InkWell(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              ImageConstant.iconMessenger,
              width: 44,
              height: 44,
            ),
            onTap: () => _shareQRWithLink(),
          ),
        );
      }

      // Always show iMessage/SMS (available on all devices)
      availableApps.add(
        InkWell(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            ImageConstant.iconIMessage,
            width: 44,
            height: 44,
          ),
          onTap: () => _shareQRWithLink(),
        ),
      );

      // Conditionally add Telegram
      if (controller.isTelegramAvailable.value) {
        availableApps.add(
          InkWell(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              ImageConstant.iconTelegram,
              width: 44,
              height: 44,
            ),
            onTap: () => _shareQRWithLink(),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'shareViaLower'.tr,
            style: CustomTextStyles.labelBlack700Size18Fw600,
            textAlign: TextAlign.left,
          ),
          SizedBox(height: ResponsiveUtil().getSize(10)),
          availableApps.length > 4
              ? Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 12,
                  runSpacing: 12,
                  children: availableApps,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: availableApps
                      .map(
                        (app) => Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: app,
                        ),
                      )
                      .toList(),
                ),
        ],
      );
    });
  }
}
