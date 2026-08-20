// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison

import 'package:app/app_controller.dart';
import 'package:app/models/create_payment_passing_data.dart';
import 'package:app/routes/app_pages.dart';
import 'package:app/shared/utils/creditcard_follow_type.dart';
import 'package:app/shared/utils/responsive_util.dart';
import 'package:app/shared/widgets/custom_text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../../api/api_constants.dart';
import '../../../api/api_repository.dart';
import '../../../models/request/amount.dart';
import '../../../models/request/get_payment_code_request/get_payment_code_request.dart';
import '../../../shared/constants/common.dart';
import '../../../shared/constants/constants_o7lite.dart';
import '../../../shared/constants/image_constant.dart';
import '../../../shared/secure_shared_preferences/secure_shared_preferences.dart';
import '../../../shared/secure_shared_preferences/sharepreference.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/utils/currency_mapper.dart';
import '../../../shared/widgets/custom_dialog/custom_dialog.dart';
import '../../../shared/widgets/string_utils.dart';
import '../home_controller.dart';

class PaymentPageQrO7LiteController extends GetxController {
  final ApiRepository apiRepository;
  PaymentPageQrO7LiteController({required this.apiRepository});

  TextEditingController amountDigitalDetailController = TextEditingController();
  TextEditingController descriptionDigitalDetailController =
      TextEditingController();

  final FocusNode amountDigitalDetailFocus = FocusNode();
  final FocusNode descriptionDigitalDetailFocus = FocusNode();

  final GlobalKey<FormState> digitalPaymentDetailFormKey =
      GlobalKey<FormState>();

  RxBool isBtnScanQRVisible = true.obs;
  RxBool isBtnGenerateQRVisible = true.obs;
  RxBool isVisaActivated = false.obs;
  RxBool isMastercardActivated = false.obs;
  RxBool isAmexActivated = false.obs;
  RxBool isDinersActivated = false.obs;
  RxBool isDiscoverActivated = false.obs;
  RxBool isJcbActivated = false.obs;
  RxBool isCupActivated = false.obs;

  String? mDescription;
  String? mTotalAmount;
  RxString setServiceChargeAmout = CommonConstants.textEmpty.obs;

  String? mEtype = CommonConstants.textEmpty;
  RxString mCurrency = CommonConstants.textSGDCurrency.obs;
  RxString terminalID = CommonConstants.textEmpty.obs;
  RxString mAuthCode = CommonConstants.textEmpty.obs;
  RxString mTransactionId = CommonConstants.textEmpty.obs;

  // Multi-currency support
  RxList<String> supportedCurrencies = <String>[].obs;

  final HomeController homeController = Get.find();
  final AppController appController = Get.find();

  // Handle both old arguments (CreditCardFollowType) and new arguments (Map with mode)
  CreditCardFollowType? get creditCardFollowType {
    final args = Get.arguments;
    if (args is CreditCardFollowType) {
      return args;
    } else if (args is Map<String, dynamic>) {
      return CreditCardFollowType.DASHBOARD; // Default for new modes
    }
    return args as CreditCardFollowType?;
  }

  // Get payment mode from arguments
  String get paymentMode {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      return args['mode'] ?? 'scan2pay';
    }
    return 'scan2pay'; // Default mode for legacy calls
  }

  @override
  void onInit() {
    innitialData();
    super.onInit();
  }

  void innitialData() async {
    String routeList =
        await SecureSharedPreferences.instance.getRouteList() ?? '';
    if (routeList.contains(ConstantsO7Lite.FD_HOST) ||
        routeList.contains(ConstantsO7Lite.FDINDIA_HOST) ||
        routeList.contains(ConstantsO7Lite.MIGS_HOST) ||
        routeList.contains(ConstantsO7Lite.TBANK_HOST) ||
        routeList.contains(ConstantsO7Lite.MAYBACK_HOST) ||
        routeList.contains(ConstantsO7Lite.PAYTABS_HOST)) {
      isVisaActivated.value = true;
      isMastercardActivated.value = true;
    }
    if (routeList.contains(ConstantsO7Lite.AMEX_HOST)) {
      isAmexActivated.value = true;
    }
    if (routeList.contains(ConstantsO7Lite.DCI_HOST)) {
      isDinersActivated.value = true;
      isDiscoverActivated.value = true;
    }
    if (routeList.contains(ConstantsO7Lite.SWIFTREM_HOST)) {
      isMastercardActivated.value = true;
      isCupActivated.value = true;
    }

    // Set up supported currencies from terminal detail
    await _setupSupportedCurrenciesFromTerminal();
  }

  /// Sets up supported currencies from terminal detail routes
  Future<void> _setupSupportedCurrenciesFromTerminal() async {
    // Get terminal detail from storage
    final terminalDetail = await SharedPrefManager.instance.getTerminalDetail();

    if (terminalDetail != null && StorageService.isGw3) {
      // Collect all unique currencies from all routes
      final Set<String> allCurrencies = {};
      for (final route in terminalDetail.routes) {
        allCurrencies.addAll(route.currencies);
      }

      if (allCurrencies.isNotEmpty) {
        supportedCurrencies.value = allCurrencies.toList();

        // Get default currency based on merchant's country
        final countryCodeAlpha = terminalDetail.merchant.countryCodeAlpha;
        mCurrency.value = CurrencyMapper.getDefaultCurrency(
          countryCodeAlpha,
          supportedCurrencies.toList(),
        );
        return;
      }
    }

    // Fallback: use country code based default
    final countryCode =
        await SecureSharedPreferences.instance.getCountryCodeAlpha() ?? 'SGP';
    _setupFallbackCurrencies(countryCode);
  }

  /// Fallback currency setup when terminal detail is not available
  void _setupFallbackCurrencies(String countryCode) {
    switch (countryCode) {
      case 'SGP':
        supportedCurrencies.value = ['SGD'];
        mCurrency.value = 'SGD';
        break;
      case 'MYS':
        supportedCurrencies.value = ['MYR'];
        mCurrency.value = 'MYR';
        break;
      case 'THA':
        supportedCurrencies.value = ['THB'];
        mCurrency.value = 'THB';
        break;
      default:
        supportedCurrencies.value = ['SGD'];
        mCurrency.value = 'SGD';
    }
  }

  /// Called when user selects a different currency
  void onCurrencyChanged(String currency) {
    mCurrency.value = currency;
    // Recalculate service charge when currency changes
    _recalculateServiceCharge();
  }

  /// Recalculates service charge based on current amount
  Future<void> _recalculateServiceCharge() async {
    final amount = amountDigitalDetailController.text;
    if (amount.isNotEmpty) {
      setServiceChargeAmout.value =
          await StringUtils.setServiceChargeAmout(amount);
    }
  }

  void paymentQr() async {
    if (digitalPaymentDetailFormKey.currentState!.validate() &&
        validateInput()) {
      await EasyLoading.show(
        status: '${CommonConstants.loading.tr}...',
      );
      final getTerminalID = SharedPrefManager.terminalID;
      terminalID.value = getTerminalID;
      String referenceNo = terminalID + StringUtils.getTimeStampGW2();
      await SecureSharedPreferences.instance.setReferenceNo(referenceNo);

      var saleAmount = StringUtils.toCents(mTotalAmount?.trim() ?? '');
      var serviceChargeAmout = StringUtils.toCents(setServiceChargeAmout.value);
      final totalAmountLimo =
          int.parse(saleAmount) + int.parse(serviceChargeAmout);

      String? qrURL;
      // Gw3 create payment hosted page
      if (StorageService.isGw3) {
        qrURL = await apiRepository.createPaymentHostedPage(Amount(
          value: int.parse(saleAmount),
          currency: mCurrency.value,
        ));
      } else {
        qrURL = appController.isMobileUser.value
            ? await apiRepository.getPaymentCodeLimo(
                GetPaymentCodeRequest(
                  salesAmount: saleAmount,
                  serviceAmount: serviceChargeAmout,
                  serviceRate:
                      homeController.getServiceChargeRate.value.toString(),
                  currency: mCurrency.value,
                  description: mDescription,
                  mcptid: getTerminalID,
                  referenceNo: referenceNo,
                  remarks: mDescription,
                  totalAmount: totalAmountLimo.toString(),
                  statusUrl: ApiConstants.STATUS_URL,
                  returnUrl: ApiConstants.RETURN_URL,
                  tokenize: "N",
                ),
              )
            : await apiRepository.getPaymentCode(
                GetPaymentCodeRequest(
                  currency: mCurrency.value,
                  description: mDescription,
                  mcptid: getTerminalID,
                  referenceNo: referenceNo,
                  remarks: mDescription,
                  totalAmount: saleAmount,
                  statusUrl: ApiConstants.STATUS_URL,
                  returnUrl: ApiConstants.RETURN_URL,
                  tokenize: "N",
                ),
              );
      }

      if (qrURL == null) {
        EasyLoading.dismiss();
        return;
      }

      if (this.creditCardFollowType == CreditCardFollowType.DASHBOARD) {
        var dataPassing = CreatePaymentPassingData(
            qrURL: qrURL,
            amount: mTotalAmount,
            currency: mCurrency.value,
            description: mDescription,
            serviceChargeAmount: serviceChargeAmout);

        // Create arguments with both payment data and mode
        final arguments = {
          'paymentData': dataPassing,
          'mode': paymentMode,
        };

        // Navigate first, then dismiss loading after navigation
        Get.offNamed(Routes.CREATE_PAYMENT_URL, arguments: arguments);

        // Dismiss loading after navigation with delay for smooth transition
        await Future.delayed(Duration(milliseconds: 500));
        EasyLoading.dismiss();
        return;
      }

      // For QR dialog, dismiss loading before showing dialog
      EasyLoading.dismiss();
      showQRDialog(qrURL);
    }
  }

  bool validateInput() {
    mTotalAmount = amountDigitalDetailController.text.trim();
    if (mTotalAmount?.toLowerCase() == ".") {
      CustomDialog.showMaterial(
        Get.context,
        CommonConstants.amountGreatThan.tr,
      );
      return false;
    }
    if (double.parse(mTotalAmount ?? '') == 0) {
      CustomDialog.showMaterial(
        Get.context,
        CommonConstants.amountGreatThan.tr,
      );
      return false;
    }

    mDescription = descriptionDigitalDetailController.text.trim();

    return true;
  }

  void showQRDialog(
    String? qrUrl,
  ) {
    CustomDialog.showMaterialDialog(
      context: Get.context!,
      onPressedCheck: () {
        Get.back();
        Future.delayed(Duration(seconds: 3)).then((_) => paymentQr());
      },
      onpressCancel: () => Get.back(),
      qrUrl: qrUrl,
    );
  }

  Widget setImageCard() {
    List<Map<String, dynamic>> cardTypes = [
      {
        "activated": isVisaActivated.value,
        "icon": ImageConstant.iconAcceptVisa
      },
      {
        "activated": isMastercardActivated.value,
        "icon": ImageConstant.iconAcceptMasterCard
      },
      {
        "activated": isAmexActivated.value,
        "icon": ImageConstant.iconAcceptAmex
      },
      {
        "activated": isDiscoverActivated.value,
        "icon": ImageConstant.iconAcceptdiscover
      },
      {
        "activated": isDinersActivated.value,
        "icon": ImageConstant.iconAcceptdiners
      },
      {"activated": isJcbActivated.value, "icon": ImageConstant.iconAcceptJcb},
    ];

    return Column(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            '${CommonConstants.cardAccept.tr}:',
            style: CustomTextStyles.labelBlack500Size24Fw600,
          ),
        ),
        SizedBox(
          height: ResponsiveUtil().getSize(10),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var cardType in cardTypes)
                if (cardType["activated"])
                  Image.asset(
                    cardType["icon"],
                    height: ResponsiveUtil().getSize(40),
                  ),
              Image.asset(
                ImageConstant.iconAcceptCup,
                height: ResponsiveUtil().getSize(40),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
