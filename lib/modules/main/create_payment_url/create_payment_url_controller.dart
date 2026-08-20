import 'package:app/api/api_constants.dart';
import 'package:app/api/api_repository.dart';
import 'package:app/app_controller.dart';
import 'package:app/models/create_payment_passing_data.dart';
import 'package:app/models/request/get_payment_code_request/get_payment_code_request.dart';
import 'package:app/modules/main/home_controller.dart';
import 'package:app/routes/app_pages.dart';
import 'package:app/shared/constants/colors.dart';
import 'package:app/shared/constants/common.dart';
import 'package:app/shared/secure_shared_preferences/secure_shared_preferences.dart';
import 'package:app/shared/widgets/string_utils.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:flutter/services.dart';

import '../../../models/request/amount.dart';
import '../../../shared/secure_shared_preferences/sharepreference.dart';
import '../../../shared/services/storage_service.dart';

class CreatePaymentUrlController extends GetxController {
  final ApiRepository apiRepository;

  CreatePaymentUrlController({required this.apiRepository});

  final AppController appController = Get.find();
  final HomeController homeController = Get.find();

  // Currency selection state - initialized immediately
  RxString get selectedCurrency => _selectedCurrency;
  late final RxString _selectedCurrency = _initSelectedCurrency();

  RxString _initSelectedCurrency() {
    final currency = paymentPassingData?.currency ??
        paymentPassingData?.supportedCurrencies?.firstOrNull ??
        'SGD';
    return currency.obs;
  }

  /// Returns the list of supported currencies from the payment data
  List<String> get supportedCurrencies {
    final currencies = paymentPassingData?.supportedCurrencies;
    if (currencies != null && currencies.isNotEmpty) {
      return currencies;
    }
    // Fallback to single currency if supportedCurrencies not available
    final currency = paymentPassingData?.currency;
    return currency != null ? [currency] : ['SGD'];
  }

  // Get payment data and mode from arguments
  CreatePaymentPassingData? get paymentPassingData {
    final args = Get.arguments;
    if (args is CreatePaymentPassingData) {
      // Legacy: direct payment data
      return args;
    } else if (args is Map<String, dynamic>) {
      // New: structured arguments with paymentData and mode
      return args['paymentData'] as CreatePaymentPassingData?;
    }
    return null;
  }

  String get paymentMode {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      return args['mode'] ?? 'scan2pay';
    }
    return 'scan2pay'; // Default mode for legacy calls
  }

  RxString obxQRCodeValue = ''.obs;

  // App availability reactive variables
  RxBool isWhatsAppAvailable = false.obs;
  RxBool isFacebookMessengerAvailable = false.obs;
  RxBool isTelegramAvailable = false.obs;
  RxBool isWeChatAvailable = false.obs;
  RxBool isCheckingAppAvailability = true.obs;

  @override
  void onInit() {
    if (paymentPassingData?.qrURL != null) {
      obxQRCodeValue.value = paymentPassingData!.qrURL!;
    } else {
      // If no payment data provided (coming from dashboard), generate default payment
      _generateDefaultPayment();
    }
    _checkAppAvailability();
    super.onInit();
  }

  /// Called when user selects a different currency from the dropdown
  void onCurrencyChanged(String currency) {
    selectedCurrency.value = currency;
    // Regenerate payment URL with new currency
    _regeneratePaymentWithNewCurrency();
  }

  /// Regenerate payment URL when currency changes
  Future<void> _regeneratePaymentWithNewCurrency() async {
    if (paymentPassingData != null) {
      final updatedData = CreatePaymentPassingData(
        amount: paymentPassingData!.amount,
        currency: selectedCurrency.value,
        description: paymentPassingData!.description,
        serviceChargeAmount: paymentPassingData!.serviceChargeAmount,
        qrURL: '', // Will be regenerated
        supportedCurrencies: paymentPassingData!.supportedCurrencies,
      );
      await _generatePaymentURLWithData(updatedData);
    }
  }

  /// Generate default payment when coming from dashboard
  void _generateDefaultPayment() async {
    // Create default payment data for demo/testing
    final defaultPaymentData = CreatePaymentPassingData(
      amount: '10.00', // Default amount
      currency: 'SGD',
      description:
          paymentMode == 'scan2pay' ? 'Scan2Pay Payment' : 'Click2Pay Payment',
      serviceChargeAmount: '0.00',
      qrURL: '', // Will be generated
    );

    // Generate payment URL
    await _generatePaymentURLWithData(defaultPaymentData);
  }

  /// Generate payment URL with specific data
  Future<void> _generatePaymentURLWithData(
      CreatePaymentPassingData data) async {
    await EasyLoading.show(
      status: paymentMode == 'scan2pay'
          ? 'msgGeneratingPaymentQr'.tr
          : 'msgGeneratingPaymentLink'.tr,
    );

    try {
      final getTerminalID = SharedPrefManager.terminalID;
      if (getTerminalID.isEmpty) {
        await EasyLoading.dismiss();
        Get.snackbar(
          'error'.tr,
          'msgTerminalIdNotFound'.tr,
          backgroundColor: ColorConstants.orangeColor,
          colorText: ColorConstants.white,
        );
        return;
      }

      String referenceNo = getTerminalID + StringUtils.getTimeStampGW2();
      await SecureSharedPreferences.instance.setReferenceNo(referenceNo);

      var saleAmount = StringUtils.toCents(data.amount?.trim() ?? '10.00');
      var currency = selectedCurrency.value;
      var description = data.description ?? 'Payment';

      // Generate URL based on gateway version
      String? qrURL;
      if (StorageService.isGw3) {
        qrURL = await apiRepository.createPaymentHostedPage(Amount(
          value: int.parse(saleAmount),
          currency: currency,
        ));
      } else {
        qrURL = await apiRepository.getPaymentCode(
          GetPaymentCodeRequest(
            currency: currency,
            description: description,
            mcptid: getTerminalID,
            referenceNo: referenceNo,
            remarks: description,
            totalAmount: saleAmount,
            statusUrl: ApiConstants.STATUS_URL,
            returnUrl: ApiConstants.RETURN_URL,
            tokenize: "N",
          ),
        );
      }

      EasyLoading.dismiss();

      if (qrURL != null) {
        obxQRCodeValue.value = qrURL;
      } else {
        Get.snackbar(
          'error'.tr,
          paymentMode == 'scan2pay'
              ? 'msgFailedGeneratePaymentQr'.tr
              : 'msgFailedGeneratePaymentLink'.tr,
          backgroundColor: ColorConstants.orangeColor,
          colorText: ColorConstants.white,
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'error'.tr,
        paymentMode == 'scan2pay'
            ? 'msgFailedGeneratePaymentQr'.tr
            : 'msgFailedGeneratePaymentLink'.tr,
        backgroundColor: ColorConstants.orangeColor,
        colorText: ColorConstants.white,
      );
    }
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    obxQRCodeValue.close();
    isWhatsAppAvailable.close();
    isFacebookMessengerAvailable.close();
    isTelegramAvailable.close();
    isWeChatAvailable.close();
    isCheckingAppAvailability.close();
    EasyLoading.dismiss();
    super.onClose();
  }

  void generatePaymentQR() async {
    await EasyLoading.show(
      status: '${CommonConstants.loading.tr}...',
    );
    final getTerminalID = SharedPrefManager.terminalID;
    if (getTerminalID.isEmpty) {
      await EasyLoading.dismiss();
      return;
    }
    String referenceNo = getTerminalID + StringUtils.getTimeStampGW2();
    await SecureSharedPreferences.instance.setReferenceNo(referenceNo);

    var saleAmount =
        StringUtils.toCents(paymentPassingData?.amount?.trim() ?? '');
    var serviceChargeAmout =
        StringUtils.toCents(paymentPassingData?.serviceChargeAmount ?? '');
    final totalAmountLimo =
        int.parse(saleAmount) + int.parse(serviceChargeAmout);

    var currency = selectedCurrency.value;
    var description = paymentPassingData?.description ?? '';

    // Gw3 create payment hosted page
    if (StorageService.isGw3) {
      final qrURL = await apiRepository.createPaymentHostedPage(Amount(
        value: int.parse(saleAmount),
        currency: currency,
      ));

      EasyLoading.dismiss();
      if (qrURL != null) {
        obxQRCodeValue.value = qrURL;
      }
      return;
    }

    final qrURL = appController.isMobileUser.value
        ? await apiRepository.getPaymentCodeLimo(
            GetPaymentCodeRequest(
              salesAmount: saleAmount,
              serviceAmount: serviceChargeAmout,
              serviceRate: homeController.getServiceChargeRate.value.toString(),
              currency: currency,
              description: description,
              mcptid: getTerminalID,
              referenceNo: referenceNo,
              remarks: description,
              totalAmount: totalAmountLimo.toString(),
              statusUrl: ApiConstants.STATUS_URL,
              returnUrl: ApiConstants.RETURN_URL,
              tokenize: "N",
            ),
          )
        : await apiRepository.getPaymentCode(
            GetPaymentCodeRequest(
              currency: currency,
              description: description,
              mcptid: getTerminalID,
              referenceNo: referenceNo,
              remarks: description,
              totalAmount: saleAmount,
              statusUrl: ApiConstants.STATUS_URL,
              returnUrl: ApiConstants.RETURN_URL,
              tokenize: "N",
            ),
          );

    if (qrURL == null) {
      EasyLoading.dismiss();
      return;
    }

    obxQRCodeValue.value = qrURL;
  }

  Future<void> sendEmail({String? email}) async {
    String? encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map((MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      // path: email,
      query: encodeQueryParameters(<String, String>{
        'subject': 'emailSubjectPaymentUrl'.tr,
        'body': obxQRCodeValue.value
      }),
    );

    try {
      bool canLaunch = await canLaunchUrl(emailLaunchUri);
      if (canLaunch) {
        await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy email content to clipboard
        final emailContent = 'Subject: Payment URL\n\n${obxQRCodeValue.value}';
        await Clipboard.setData(ClipboardData(text: emailContent));
        Get.snackbar(
          'info'.tr,
          'msgCannotOpenEmailCopied'.tr,
          backgroundColor: ColorConstants.orangeColor,
          colorText: ColorConstants.white,
        );
      }
    } catch (e) {
      // Fallback: copy email content to clipboard
      final emailContent = 'Subject: Payment URL\n\n${obxQRCodeValue.value}';
      await Clipboard.setData(ClipboardData(text: emailContent));
      Get.snackbar(
        'error'.tr,
        'msgCannotOpenEmailCopied'.tr,
        backgroundColor: ColorConstants.orangeColor,
        colorText: ColorConstants.white,
      );
    }
  }

  Future<void> shareViaWhatsApp() async {
    final Uri whatsappUri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '',
      queryParameters: {
        'text': obxQRCodeValue.value, // pre-filled message
      },
    );

    try {
      bool isCanLaunchApp = await canLaunchUrl(whatsappUri);
      if (isCanLaunchApp) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy message to clipboard
        await Clipboard.setData(ClipboardData(text: obxQRCodeValue.value));
        Get.snackbar(
          'info'.tr,
          'msgWhatsAppNotAvailable'.tr,
          backgroundColor: ColorConstants.orangeColor,
          colorText: ColorConstants.white,
        );
      }
    } catch (e) {
      // Fallback: copy message to clipboard
      await Clipboard.setData(ClipboardData(text: obxQRCodeValue.value));
      Get.snackbar(
        'error'.tr,
        'msgWhatsAppNotAvailable'.tr,
        backgroundColor: ColorConstants.orangeColor,
        colorText: ColorConstants.white,
      );
    }
  }

  Future<void> shareViaFacebookMessenger() async {
    final Uri fbMessengerUri = Uri(
      scheme: 'fb-messenger',
      host: 'share',
      queryParameters: {
        'link': obxQRCodeValue.value, // pre-filled message
      },
    );

    try {
      bool isCanLaunchApp = await canLaunchUrl(fbMessengerUri);
      if (isCanLaunchApp) {
        await launchUrl(fbMessengerUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy message to clipboard
        await Clipboard.setData(ClipboardData(text: obxQRCodeValue.value));
        Get.snackbar(
          'info'.tr,
          'msgMessengerNotAvailable'.tr,
          backgroundColor: ColorConstants.orangeColor,
          colorText: ColorConstants.white,
        );
      }
    } catch (e) {
      // Fallback: copy message to clipboard
      await Clipboard.setData(ClipboardData(text: obxQRCodeValue.value));
      Get.snackbar(
        'error'.tr,
        'msgMessengerNotAvailable'.tr,
        backgroundColor: ColorConstants.orangeColor,
        colorText: ColorConstants.white,
      );
    }
  }

  Future<void> shareViaIMessage({String? recipient}) async {
    final Uri iMessageUri = Uri(
      scheme: 'sms',
      path: recipient, // phone number of the recipient
      queryParameters: <String, String>{
        'body': obxQRCodeValue.value, // pre-filled message
      },
    );

    try {
      bool isCanLaunchApp = await canLaunchUrl(iMessageUri);
      if (isCanLaunchApp) {
        await launchUrl(iMessageUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy message to clipboard
        await Clipboard.setData(ClipboardData(text: obxQRCodeValue.value));
        Get.snackbar(
          'info'.tr,
          'msgSmsNotAvailable'.tr,
          backgroundColor: ColorConstants.orangeColor,
          colorText: ColorConstants.white,
        );
      }
    } catch (e) {
      // Fallback: copy message to clipboard
      await Clipboard.setData(ClipboardData(text: obxQRCodeValue.value));
      Get.snackbar(
        'error'.tr,
        'msgSmsNotAvailable'.tr,
        backgroundColor: ColorConstants.orangeColor,
        colorText: ColorConstants.white,
      );
    }
  }

  Future<void> shareViaTelegram() async {
    final Uri telegramUri = Uri(
      scheme: 'tg',
      host: 'msg',
      queryParameters: {
        'text': obxQRCodeValue.value, // pre-filled message
      },
    );

    try {
      bool isCanLaunchApp = await canLaunchUrl(telegramUri);
      if (isCanLaunchApp) {
        await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy message to clipboard
        await Clipboard.setData(ClipboardData(text: obxQRCodeValue.value));
        Get.snackbar(
          'info'.tr,
          'msgTelegramNotAvailable'.tr,
          backgroundColor: ColorConstants.orangeColor,
          colorText: ColorConstants.white,
        );
      }
    } catch (e) {
      // Fallback: copy message to clipboard
      await Clipboard.setData(ClipboardData(text: obxQRCodeValue.value));
      Get.snackbar(
        'error'.tr,
        'msgTelegramNotAvailable'.tr,
        backgroundColor: ColorConstants.orangeColor,
        colorText: ColorConstants.white,
      );
    }
  }

  Future<void> shareViaWeChat() async {
    final Uri weChatUri = Uri(
      scheme: 'weixin',
      path: 'dl/business',
      queryParameters: {
        'target': 'openapi',
        'url': obxQRCodeValue.value,
      },
    );

    try {
      bool isCanLaunchApp = await canLaunchUrl(weChatUri);
      if (isCanLaunchApp) {
        await launchUrl(weChatUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy message to clipboard
        await Clipboard.setData(ClipboardData(text: obxQRCodeValue.value));
        Get.snackbar(
          'info'.tr,
          'msgWeChatNotAvailable'.tr,
          backgroundColor: ColorConstants.orangeColor,
          colorText: ColorConstants.white,
        );
      }
    } catch (e) {
      // Fallback: copy message to clipboard
      await Clipboard.setData(ClipboardData(text: obxQRCodeValue.value));
      Get.snackbar(
        'error'.tr,
        'msgWeChatNotAvailable'.tr,
        backgroundColor: ColorConstants.orangeColor,
        colorText: ColorConstants.white,
      );
    }
  }

  void gotoTxnHistories({String? transactionID}) {
    Get.toNamed(
      Routes.TRANSACTION_HISTORY,
      //  Routes.TRANSACTION_HISTORY_DETAIL,
      arguments: {
        'isReturnHome': false,
      },
    );
  }

  Future<void> _checkAppAvailability() async {
    // Check WhatsApp availability
    try {
      Uri whatsappUri;
      if (Platform.isIOS) {
        // iOS specific schemes
        whatsappUri = Uri.parse('whatsapp://send');
      } else {
        // Android specific schemes
        whatsappUri = Uri(scheme: 'whatsapp', host: 'send');
      }
      isWhatsAppAvailable.value = await canLaunchUrl(whatsappUri);
    } catch (e) {
      isWhatsAppAvailable.value = false;
    }

    // Check Facebook Messenger availability
    try {
      Uri messengerUri;
      if (Platform.isIOS) {
        // iOS specific schemes
        messengerUri = Uri.parse('fb-messenger://');
      } else {
        // Android specific schemes
        messengerUri = Uri(scheme: 'fb-messenger', host: 'share');
      }
      isFacebookMessengerAvailable.value = await canLaunchUrl(messengerUri);
    } catch (e) {
      isFacebookMessengerAvailable.value = false;
    }

    // Check Telegram availability
    try {
      Uri telegramUri;
      if (Platform.isIOS) {
        // iOS specific schemes
        telegramUri = Uri.parse('tg://msg');
      } else {
        // Android specific schemes
        telegramUri = Uri(scheme: 'tg', host: 'msg');
      }
      isTelegramAvailable.value = await canLaunchUrl(telegramUri);
    } catch (e) {
      isTelegramAvailable.value = false;
    }

    // Check WeChat availability
    try {
      Uri weChatUri;
      if (Platform.isIOS) {
        // iOS specific schemes
        weChatUri = Uri.parse('weixin://');
      } else {
        // Android specific schemes
        weChatUri = Uri(scheme: 'weixin', path: 'dl/business');
      }
      isWeChatAvailable.value = await canLaunchUrl(weChatUri);
    } catch (e) {
      isWeChatAvailable.value = false;
    }

    isCheckingAppAvailability.value = false;
  }

  /// Manually refresh app availability checking
  /// Can be called when user returns from installing an app
  Future<void> refreshAppAvailability() async {
    isCheckingAppAvailability.value = true;
    await _checkAppAvailability();
  }
}
