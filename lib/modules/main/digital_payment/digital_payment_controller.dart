// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison, avoid_print

import 'dart:io';
import 'package:app/api/api_constants.dart';
import 'package:app/app_controller.dart';
import 'package:app/models/request/amount.dart';
import 'package:app/models/request/digital_payment_request/digital_payment_request.dart';
import 'package:app/models/request/payment_method.dart';
import 'package:app/models/request/payment_source.dart';
import 'package:app/models/request/unified_order_request/unified_order_request.dart';
import 'package:app/routes/app_pages.dart';
import 'package:app/shared/constants/common.dart';
import 'package:app/shared/constants/constants_o7lite.dart';
import 'package:app/shared/secure_shared_preferences/secure_shared_preferences.dart';
import 'package:app/shared/services/storage_service.dart';
import 'package:app/shared/widgets/custom_dialog/custom_dialog.dart';
import 'package:app/shared/widgets/string_utils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../../models/request/querry_receipt_infor_request/querry_receipt_infor_request.dart';
import '../../../models/response/querry_receipt_infor_response/querry_receipt_infor_response.dart';
import '../../../models/route_payment_model.dart';
import '../../../api/api_repository.dart';
import '../../../models/request/unified_order_v6_request/unified_order_v6_request.dart';
import '../../../shared/secure_shared_preferences/sharepreference.dart';
import '../../../shared/mixins/auto_polling_mixin.dart';
import '../../../shared/utils/enum/app_dialog_type.dart';
import '../home_controller.dart';
import 'package:app/shared/utils/log_utils.dart';

class DigitalPaymentController extends GetxController with AutoPollingMixin {
  final ApiRepository apiRepository;
  DigitalPaymentController({required this.apiRepository});

  final RoutePaymentModel routePaymentModel = Get.arguments;

  // Currency selection state - initialized immediately from routePaymentModel
  RxString get selectedCurrency => _selectedCurrency;
  late final RxString _selectedCurrency = _initSelectedCurrency();

  RxString _initSelectedCurrency() {
    final currency = routePaymentModel.currency ??
        routePaymentModel.supportedCurrencies?.firstOrNull ??
        '';
    return currency.obs;
  }

  /// Returns the list of supported currencies from the route payment model
  List<String> get supportedCurrencies =>
      routePaymentModel.supportedCurrencies ??
      (routePaymentModel.currency != null ? [routePaymentModel.currency!] : []);

  TextEditingController amountDigitalDetailController = TextEditingController();
  TextEditingController descriptionDigitalDetailController =
      TextEditingController();

  final FocusNode amountDigitalDetailFocus = FocusNode();
  final FocusNode descriptionDigitalDetailFocus = FocusNode();

  // Using for GW3 data
  TextEditingController phoneNumController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  final FocusNode phoneNumFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode nameFocus = FocusNode();

  final GlobalKey<FormState> digitalPaymentDetailFormKey =
      GlobalKey<FormState>();

  RxBool isBtnScanQRVisible = true.obs;
  RxBool isBtnGenerateQRVisible = true.obs;

  String? mDescription;
  String? mTotalAmount;

  RxString mAuthCode = CommonConstants.textEmpty.obs;
  RxString mTransactionId = CommonConstants.textEmpty.obs;
  RxString terminalID = "".obs;
  RxString userType = "".obs;
  RxString setServiceChargeAmount = CommonConstants.textEmpty.obs;

  bool refreshInterval = false;
  RxBool isPollingActive = false.obs;
  RxBool isNavigating = false.obs;
  late AudioPlayer player = AudioPlayer();

  final HomeController homeController = Get.find();
  final AppController appController = Get.find();

  RxBool isGrabPayOnline = false.obs;

  @override
  void onInit() async {
    super.onInit();
    player = AudioPlayer();
    refreshInterval = await SharedPrefManager.instance.getRefreshInterval();
    LogUtils.debugLog(
        '[DigitalPaymentController] onInit: refreshInterval=$refreshInterval');

    amountDigitalDetailFocus.requestFocus();
    isGrabPayOnline.value =
        routePaymentModel.acquirer?.toLowerCase() == 'grabpay-online';
  }

  /// Called when user selects a different currency from the dropdown
  void onCurrencyChanged(String currency) {
    selectedCurrency.value = currency;
    // Recalculate service charge when currency changes
    _recalculateServiceCharge();
  }

  /// Recalculates service charge based on current amount
  Future<void> _recalculateServiceCharge() async {
    final amount = amountDigitalDetailController.text;
    if (amount.isNotEmpty) {
      setServiceChargeAmount.value =
          await StringUtils.setServiceChargeAmout(amount);
    }
  }

  @override
  void onClose() {
    amountDigitalDetailController.dispose();
    descriptionDigitalDetailController.dispose();
    amountDigitalDetailFocus.dispose();
    descriptionDigitalDetailFocus.dispose();
    player.dispose();
    LogUtils.debugLog(
        '[DigitalPaymentController] onClose: cleaning up polling');
    isPollingActive.value = false;
    isNavigating.value = false;
    resetPolling();
    super.onClose();
  }

  /// Starts the Consumer-Presented Mode (CPQR) scan-to-charge flow.
  ///
  /// Validates the payment form and amount rules before opening the scanner, so
  /// the customer's code is never scanned for an invalid amount. After scanning,
  /// an empty result cancels silently, an invalid code shows a failed dialog,
  /// and a valid code opens the confirm-charge dialog before any charge.
  Future<void> scanQrCode(BuildContext context) async {
    final paymentType = routePaymentModel.acquirerDigital?.toLowerCase();

    // Guard: only proceed when the form and amount rules pass. The form's own
    // validators and validateInput surface the errors; do not open the scanner.
    if (!(digitalPaymentDetailFormKey.currentState!.validate() &&
        validateInput(context, paymentType))) {
      return;
    }

    final result = await Get.toNamed(Routes.SCAN_QR_CODE);

    // Empty or cancelled scan: cancel silently without error and without charge.
    if (result == null || (result as String).isEmpty) {
      return;
    }

    final String paymentCode = result;

    // Reject a value that is not a valid payment code (e.g. a URL QR).
    final error = validatePaymentCode(paymentCode);
    if (error != null) {
      CustomDialog.showCustomDialog(
        context: context,
        dialogType: AppDialogType.failed,
        content: error,
        titleButton: CommonConstants.ok.tr,
        onPressedCheck: () => Get.back(),
      );
      return;
    }

    // Valid code: remember it and confirm before charging the customer's wallet.
    mAuthCode.value = paymentCode;
    _showConfirmChargeDialog(context);
  }

  /// Validates a scanned payment [code] before charging the customer's wallet.
  ///
  /// The value is trimmed of surrounding whitespace, then treated as valid only
  /// when it consists solely of digits with a length in the range [16, 24]
  /// (regex `^\d{16,24}$`).
  ///
  /// Returns `null` when the code is valid, otherwise returns the localized
  /// `'msgInvalidPaymentCode'` error message. The method is pure: it has no
  /// side effects and does not depend on any controller or async state.
  String? validatePaymentCode(String code) {
    final trimmed = code.trim();
    final isValid = RegExp(r'^\d{16,24}$').hasMatch(trimmed);
    return isValid ? null : 'msgInvalidPaymentCode'.tr;
  }

  /// Shows the confirm-charge dialog after a valid scan, before any charge.
  ///
  /// The dialog uses [AppDialogType.confirm] and displays the amount, currency,
  /// and payment-method brand being charged via the localized
  /// `dialogConfirmChargeWallet` content (interpolating `@currency @amount
  /// @brand`).
  ///
  /// Cancelling dismisses the dialog and sends no charge request. Confirming
  /// dismisses the dialog, then initiates the charge: the GW3 sale-request CPQR
  /// path when `StorageService.isGw3` is true, otherwise the existing quick-pay
  /// path.
  void _showConfirmChargeDialog(BuildContext context) {
    CustomDialog.showCustomDialog(
      context: context,
      dialogType: AppDialogType.confirm,
      content: 'dialogConfirmChargeWallet'.trParams({
        'currency': selectedCurrency.value,
        'amount': mTotalAmount ?? '',
        'brand': routePaymentModel.brand ?? '',
      }),
      titleButton: CommonConstants.confirm.tr,
      onpressCancel: () => Get.back(),
      onPressedCheck: () {
        Get.back();
        if (StorageService.isGw3) {
          processScanToPayGw3(context, routePaymentModel);
        } else {
          processQuickPay(context, routePaymentModel);
        }
      },
    );
  }

  /// SALE REQUEST::: Charges the customer's wallet via the GW3 Consumer-Presented
  /// Mode (CPQR) sale request.
  ///
  /// This mirrors [generateQrCodeGw3] (the MPQR flow) but sets
  /// `payment_channel: 'CPQR'` and carries the scanned payment code in
  /// `source.consumer_identifier`. It sends the same amount, currency, and
  /// description as the Generate QR flow via `apiRepository.saleRequest`
  /// (`POST /terminal/payment`).
  ///
  /// A loading indicator is shown while the request is in flight and dismissed
  /// on completion (both success and error). On a non-null response with a
  /// non-empty `oxpayTxnId`, it stores the transaction id and navigates to the
  /// receipt/detail. A null response performs no navigation — `saleRequest`
  /// already surfaces REJECTED/failed outcomes via its own dialog.
  Future<void> processScanToPayGw3(
      BuildContext context, RoutePaymentModel routePaymentModel) async {
    await EasyLoading.show(
      status: '${CommonConstants.loading.tr}...',
    );

    PaymentMethod paymentMethod = PaymentMethod(
      brand: routePaymentModel.brand ?? '',
      paymentChannel:
          'CPQR', // Enum: "MPQR" "CPQR" - Consumer-Presented Mode charge
      source: PaymentSource(consumerIdentifier: mAuthCode.value),
    );

    mTotalAmount = amountDigitalDetailController.text.trim();
    mDescription = descriptionDigitalDetailController.text.trim();
    var saleAmount = StringUtils.toCents(mTotalAmount?.trim() ?? '');

    Amount amount = Amount(
      currency: selectedCurrency.value,
      value: int.tryParse(saleAmount) ?? 0,
    );

    try {
      var saleRequestRes = await apiRepository
          .saleRequest(paymentMethod, amount, description: mDescription);

      await EasyLoading.dismiss();

      if (saleRequestRes != null) {
        var oxpayTxnId = saleRequestRes.oxpayTxnId;

        // Check if oxpayTxnId is empty
        if (oxpayTxnId.isEmpty) {
          CustomDialog.showMaterial(
            context,
            'msgFailedGenerateQr'.tr,
          );
          return;
        }

        mTransactionId.value = oxpayTxnId;
        goToReceiptDetail();
      }
      // A null response means saleRequest already surfaced the failure/rejection
      // via its own dialog, so no navigation is performed here.
    } catch (e) {
      await EasyLoading.dismiss();
      LogUtils.debugLog(e);
      CustomDialog.showMaterial(
        context,
        CommonConstants.unknown.tr,
      );
    }
  }

  Future<void> processQuickPay(
    BuildContext context,
    RoutePaymentModel routePaymentModel,
  ) async {
    String ip = '';

    try {
      ip = await getIPAddress();
    } catch (e) {
      LogUtils.debugLog(e);
      CustomDialog.showToast(
        CommonConstants.errorGetIpAddress.tr,
      );
    }
    await EasyLoading.show(
      status: '${CommonConstants.loading.tr}...',
    );
    var saleAmount = StringUtils.toCents(mTotalAmount?.trim() ?? '');
    var serviceChargeAmount = StringUtils.toCents(setServiceChargeAmount.value);
    final totalAmountLimo =
        int.parse(saleAmount) + int.parse(serviceChargeAmount);

    final res = appController.isMobileUser.value
        ? await apiRepository.digitalPaymentLimo(
            DigitalPaymentRequest(
              salesAmount: saleAmount,
              serviceAmount: serviceChargeAmount,
              serviceRate: homeController.getServiceChargeRate.value.toString(),
              description: mDescription ?? '',
              totalAmount: totalAmountLimo.toString(),
              currency: selectedCurrency.value,
              authCode: mAuthCode.value,
              eType: routePaymentModel.acquirerDigital,
              ipAddress: ip,
            ),
          )
        : await apiRepository.digitalPayment(
            DigitalPaymentRequest(
              description: mDescription ?? '',
              totalAmount: saleAmount,
              currency: selectedCurrency.value,
              authCode: mAuthCode.value,
              eType: routePaymentModel.acquirerDigital,
              ipAddress: ip,
            ),
          );
    if (res != null) {
      final transactionState = res.transactionState;
      final transactionId = res.transactionId;
      mTransactionId.value = transactionId ?? '';

      if (TransactionState.STATE_SUCCESS == transactionState ||
          TransactionState.STATE_USER_PAYING == transactionState) {
        CustomDialog.showToast(
          'msgTransactionSuccess'.tr,
        );
        goToReceiptDetail();
      } else {
        CustomDialog.showMaterial(
          context,
          CommonConstants.transactionFailed.tr,
        );
      }
    }
  }

  Future<String> getIPAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      LogUtils.debugLog('Failed to get IP address: $e');
    }
    return CommonConstants.unknown.tr;
  }

  void makePayment(BuildContext context) {
    if (StorageService.isGw3) {
      generateQrCodeGw3(context, routePaymentModel);
    } else {
      generateQrCode(context, routePaymentModel);
    }
  }

  /// SALE REQUEST::: Generate QR code for GW3 payment
  void generateQrCodeGw3(
      BuildContext context, RoutePaymentModel routePaymentModel) async {
    if (digitalPaymentDetailFormKey.currentState!.validate() == false) return;

    await EasyLoading.show(
      status: '${CommonConstants.loading.tr}...',
    );

    // Demo build: the Ripple acquirer is not configured yet, so build the
    // payment request locally and reuse the standard QR dialog.
    if (routePaymentModel.acquirerDigital == ConstantsO7Lite.RIPPLE_TYPE) {
      await _showRippleDemoQr(context, routePaymentModel);
      return;
    }

    // PaymentSource paymentSource = PaymentSource(
    //   name: nameController.text,
    //   email: emailController.text,
    //   phone: phoneNumController.text,
    // );

    PaymentSource paymentSource = PaymentSource(
      name: descriptionDigitalDetailController.text, // fake description
      email: 'support@oxpayfinancial.com',
      phone: '6562990030',
    );

    PaymentMethod paymentMethod = PaymentMethod(
      brand: routePaymentModel.brand ?? '',
      paymentChannel:
          'MPQR', // Enum: "MPQR" "CPQR" - This is only applicable for QR transaction
      // [GW3] source is not required for QR transaction
      // source: paymentSource,
    );

    mTotalAmount = amountDigitalDetailController.text.trim();
    mDescription = descriptionDigitalDetailController.text.trim();
    var saleAmount = StringUtils.toCents(mTotalAmount?.trim() ?? '');

    Amount amount = Amount(
      currency: selectedCurrency.value,
      value: int.tryParse(saleAmount) ?? 0,
    );

    try {
      var saleRequestRes = await apiRepository
          .saleRequest(paymentMethod, amount, description: mDescription);

      if (saleRequestRes != null) {
        var qrString = saleRequestRes.qrString;
        var oxpayTxnId = saleRequestRes.oxpayTxnId;

        // Check if qrString or oxpayTxnId is null or empty
        if (qrString.isEmpty || oxpayTxnId.isEmpty) {
          CustomDialog.showMaterial(
            context,
            'msgFailedGenerateQr'.tr,
          );
          return;
        }

        mTransactionId.value = oxpayTxnId;
        checkUserPaid();
        showQRDialog(context, qrString, routePaymentModel);
      }
    } catch (e) {
      LogUtils.debugLog(e);
      CustomDialog.showMaterial(
        context,
        CommonConstants.unknown.tr,
      );
    }
  }

  /// Demo build: renders the standard QR dialog for Ripple from a locally
  /// generated payment request. Status polling is skipped because there is no
  /// gateway transaction to query until the Ripple configuration lands.
  Future<void> _showRippleDemoQr(
    BuildContext context,
    RoutePaymentModel routePaymentModel,
  ) async {
    mTotalAmount = amountDigitalDetailController.text.trim();
    mDescription = descriptionDigitalDetailController.text.trim();

    // Keep the loading state visible briefly so the flow matches the live one.
    await Future.delayed(const Duration(milliseconds: 600));
    await EasyLoading.dismiss();

    mTransactionId.value = 'RPL${DateTime.now().millisecondsSinceEpoch}';

    final qrString = Uri(
      scheme: 'ripple',
      path: ConstantsO7Lite.RIPPLE_DEMO_ADDRESS,
      queryParameters: {
        'amount': mTotalAmount ?? '0',
        'currency': selectedCurrency.value,
        'dt': mTransactionId.value,
      },
    ).toString();

    showQRDialog(context, qrString, routePaymentModel);
  }

  void generateQrCode(
    BuildContext context,
    RoutePaymentModel routePaymentModel,
  ) async {
    var paymentType = routePaymentModel.acquirerDigital?.toLowerCase();
    if (digitalPaymentDetailFormKey.currentState!.validate() &&
        validateInput(context, paymentType)) {
      await EasyLoading.show(
        status: '${CommonConstants.loading.tr}...',
      );
      final getTerminalID = SharedPrefManager.terminalID;
      terminalID.value = getTerminalID;
      String referenceNo = terminalID + StringUtils.getTimeStampGW2();
      await SecureSharedPreferences.instance.setReferenceNo(referenceNo);

      var saleAmount = StringUtils.toCents(mTotalAmount?.trim() ?? '');
      var serviceChargeAmout =
          StringUtils.toCents(setServiceChargeAmount.value);
      final totalAmountLimo =
          int.parse(saleAmount) + int.parse(serviceChargeAmout);

      bool isMobile = appController.isMobileUser.value;
      var paymentType = routePaymentModel.acquirerDigital?.toLowerCase();
      switch (paymentType) {
        case ConstantsO7Lite.IOUPAY_TYPE:
        case ConstantsO7Lite.GRABPAY_V3_TYPE:
          await Future(
            () async {
              try {
                var request = UnifiedOrderV6Request(
                    description: mDescription ?? '',
                    totalAmount: saleAmount,
                    currency: selectedCurrency.value,
                    eType: routePaymentModel.acquirerDigital,
                    referenceNo: referenceNo,
                    reqKey: '',
                    mcptid: terminalID.value,
                    statusUrl: ApiConstants.STATUS_URL);

                if (isMobile) {
                  request.salesAmount = saleAmount;
                  request.serviceAmount = serviceChargeAmout;
                  request.serviceRate =
                      homeController.getServiceChargeRate.value.toString();
                  var totalAmountValue =
                      int.parse(saleAmount) + int.parse(serviceChargeAmout);
                  request.totalAmount = totalAmountValue.toString();
                }

                final unifiedOrderV6 =
                    await apiRepository.unifiedOrderV6(request, isMobile);

                if (unifiedOrderV6 == null) {
                  CustomDialog.showMaterial(
                    context,
                    CommonConstants.unifiedOderError.tr,
                  );
                  return;
                }

                // Check if qrUrl or transactionId is null or empty
                final qrUrl = unifiedOrderV6.qrUrl ?? '';
                final transactionId = unifiedOrderV6.transactionId ?? '';

                if (qrUrl.isEmpty || transactionId.isEmpty) {
                  CustomDialog.showMaterial(
                    context,
                    'msgFailedGenerateQr'.tr,
                  );
                  return;
                }

                mTransactionId.value = transactionId;

                checkUserPaid();
                showQRDialog(
                  context,
                  qrUrl,
                  routePaymentModel,
                );
              } catch (e) {
                LogUtils.debugLog(e);
              }
            },
          );
          break;
        default:
          var requestData = UnifiedOrderRequest(
              description: mDescription ?? '',
              totalAmount: saleAmount,
              currency: selectedCurrency.value,
              eType: routePaymentModel.acquirerDigital ?? '',
              referenceNo: referenceNo,
              statusUrl: ApiConstants.STATUS_URL);

          if (isMobile) {
            requestData.salesAmount = saleAmount;
            requestData.serviceAmount = serviceChargeAmout;
            requestData.serviceRate =
                homeController.getServiceChargeRate.value.toString();
            var totalAmountValue =
                int.parse(saleAmount) + int.parse(serviceChargeAmout);
            requestData.totalAmount = totalAmountValue.toString();
          }

          final unifiedOrderInfo =
              await apiRepository.unifiedOrder(requestData, isMobile);

          if (unifiedOrderInfo == null) {
            CustomDialog.showAlertDialog(
              context,
              CommonConstants.unifiedOderError.tr,
            );
            return;
          }

          final transactionState = unifiedOrderInfo.transactionState ?? '';
          final transactionId = unifiedOrderInfo.transactionId ?? '';
          final qrUrl = unifiedOrderInfo.qrUrl ?? '';

          // Check if qrUrl or transactionId is empty
          if (qrUrl.isEmpty || transactionId.isEmpty) {
            CustomDialog.showAlertDialog(
              context,
              'msgFailedGenerateQr'.tr,
            );
            return;
          }

          // final tempUrl =
          //"00020201021226600014A0000006150001010689004602282xDd3l3H
          //GI1M0ufC9MY4n2L3s9WQ52045499530345854040.015802MY5922Web
          //Creative Resources6006Ampang61056800062400507ish2r1S0725
          //tEfSvy0nwl9rkl17AGDPdRM0J64320002EN0122Web Creative Resources63044620";

          if (transactionState == TransactionState.STATE_USER_PAYING) {
            mTransactionId.value = transactionId;
            checkUserPaid();

            showQRDialog(
              context,
              qrUrl,
              routePaymentModel,
            );
          }
          break;
      }
    }
  }

  bool validateInput(BuildContext context, String? paymentType) {
    mTotalAmount = amountDigitalDetailController.text.trim();

    var isAtom = paymentType == ConstantsO7Lite.ATOME_TYPE;

    // When user input amount is empty or 0 or less than 1.5 for Atome, show alert dialog and return false
    if (mTotalAmount?.toLowerCase() == "." ||
        double.parse(mTotalAmount ?? '') == 0 ||
        isAtom && double.parse(mTotalAmount ?? '') < 1.5) {
      var message = isAtom
          ? 'msgAmountMoreThan150'.tr
          : CommonConstants.amountGreatThan.tr;
      CustomDialog.showAlertDialog(
        context,
        message,
      );
      return false;
    }

    mDescription = descriptionDigitalDetailController.text.trim();

    if (mDescription?.isEmpty ?? true) {
      if (BaseAppO7Lite.isDonationMode) {
        mDescription = CommonConstants.communityChestDonation.tr;
      } else {
        mDescription = CommonConstants.textOxPay;
      }
    }

    return true;
  }

  void goToReceiptDetail() {
    if (mTransactionId.value != null) {
      Get.offNamed(
        Routes.TRANSACTION_HISTORY_DETAIL,
        arguments: {
          'mTransactionId': mTransactionId.value,
        },
      );
    }
  }

  void showQRDialog(
    BuildContext context,
    String? qrUrl,
    RoutePaymentModel routePaymentModel,
  ) {
    CustomDialog.showMaterialDialog(
      isShowLoading: false,
      isCheckEnableCloseIcon: true,
      isPollingActive: isPollingActive,
      context: context,
      onPressedCheck: () {
        if (isNavigating.value) return;
        isPollingActive.value = false;
        stopPolling();
        isNavigating.value = true;
        Get.back();

        Get.offNamed(
          Routes.TRANSACTION_HISTORY_DETAIL,
          arguments: {
            'mTransactionId': mTransactionId.value,
            'isDonation': BaseAppO7Lite.isDonationMode,
            'comeFromScreen': TransactionState.COMEFROMDIGITALPAYMENT,
          },
        );
      },
      onpressCancel: () async {
        isPollingActive.value = false;
        stopPolling();

        if (routePaymentModel.acquirerDigital == ConstantsO7Lite.SHOPEE_TYPE) {
          // await EasyLoading.show(
          //   status: '${CommonConstants.loading.tr}...',
          // );
          // final ewalletVoidResult = await apiRepository.ewalletVoid(
          //   EwalletVoidRequest(
          //     tradeNo: mTransactionId.value,
          //     eType: routePaymentModel.acquirerDigital,
          //     currencySelected: routePaymentModel.currency,
          //   ),
          // );

          // if (ewalletVoidResult != null) {
          //   CustomDialog.showToast(
          //     CommonConstants.inValidatePaymentSuccess.tr,
          //   );
          //   Get.offAllNamed(Routes.HOME);
          // } else {
          //   CustomDialog.showToast(
          //     CommonConstants.inValidatePaymentFailed.tr,
          //   );
          // }

          // Just go back to home screen
          Get.offAllNamed(Routes.HOME);
        } else {
          Get.offAllNamed(Routes.HOME);
        }
      },
      routePaymentModel: routePaymentModel,
      qrUrl: qrUrl,
    );
  }

  Future<void> checkUserPaid() async {
    if (!refreshInterval) {
      LogUtils.debugLog(
          '[DigitalPaymentController] checkUserPaid: refreshInterval disabled, skipping');
      return;
    }
    LogUtils.debugLog(
        '[DigitalPaymentController] checkUserPaid: starting auto-poll for txn=${mTransactionId.value}');
    isPollingActive.value = true;
    startPolling(
      () => _pollTransactionStatus(),
      onMaxPollReached: () {
        isPollingActive.value = false;
        CustomDialog.showToast(
          'dialogAutoCheckStopped'.tr,
        );
      },
    );
  }

  /// Polls the payment gateway for transaction status.
  /// Returns `true` to stop polling on success/failure states,
  /// `false` to continue polling on STATE_USER_PAYING or null response.
  Future<bool> _pollTransactionStatus() async {
    LogUtils.debugLog(
        '[DigitalPaymentController] _pollTransactionStatus: querying txn=${mTransactionId.value}');
    final resultReceiptInfo = await apiRepository.querryReceiptInfor(
      QuerryReceiptInforRequest(
        transactionId: mTransactionId.value,
      ),
      StorageService.isGw3,
    );

    if (resultReceiptInfo == null) {
      LogUtils.debugLog(
          '[DigitalPaymentController] _pollTransactionStatus: null response, continue polling');
      return false;
    }

    LogUtils.debugLog(
        '[DigitalPaymentController] _pollTransactionStatus: state=${resultReceiptInfo.transactionState}');

    if (resultReceiptInfo.transactionState ==
        TransactionState.STATE_USER_PAYING) {
      return false;
    }

    // Success or terminal state — navigate to detail
    await goToTransactionDetail(resultReceiptInfo);
    return true;
  }

  Future<void> goToTransactionDetail(
      QuerryReceiptInforResponse? resultReceiptInfo) async {
    if (isNavigating.value) return;
    isNavigating.value = true;
    await playSound();
    isPollingActive.value = false;
    stopPolling();
    bool isDonation = false;
    if (BaseAppO7Lite.isDonationMode) {
      isDonation = true;
    } else {
      isDonation = false;
    }
    Get.back();
    Get.offNamed(
      Routes.TRANSACTION_HISTORY_DETAIL,
      arguments: {
        'mTransactionId': mTransactionId.value,
        'resultReceiptInfo': resultReceiptInfo,
        'isDonation': isDonation,
        'isDisableSound': true,
        'comeFromScreen': TransactionState.COMEFROMDIGITALPAYMENT,
      },
    );
  }

  playSound() async {
    final isEnableSound =
        await SharedPrefManager.instance.getBool('isEnableSound') ?? false;

    if (!isEnableSound) return;

    final sound = await SharedPrefManager.instance.getCashierSound();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await player.setAsset('assets/' + sound);
      await player.play();
    });
  }
}

bool isHTML(String str) {
  final RegExp htmlRegExp =
      RegExp('<[^>]*>', multiLine: true, caseSensitive: false);
  return htmlRegExp.hasMatch(str);
}
