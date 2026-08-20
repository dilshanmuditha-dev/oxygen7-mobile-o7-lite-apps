import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:app/api/api_repository.dart';
import 'package:app/shared/constants/common.dart';
import 'package:app/shared/utils/focus.dart';
import 'package:app/shared/services/mine_soft_pos_service.dart';
import 'package:app/shared/widgets/custom_dialog/custom_dialog.dart';
import 'package:app/routes/app_pages.dart';
import 'package:app/app_controller.dart';
import '../home_controller.dart';
import 'package:app/shared/widgets/string_utils.dart';
import 'package:app/shared/secure_shared_preferences/secure_shared_preferences.dart';
import '../../../shared/secure_shared_preferences/sharepreference.dart';

class CardReaderController extends GetxController {
  final ApiRepository apiRepository;
  CardReaderController({required this.apiRepository});

  TextEditingController amountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  final FocusNode amountFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode();

  final GlobalKey<FormState> cardReaderFormKey = GlobalKey<FormState>();

  String? mDescription;
  String? mTotalAmount;
  RxString mTransactionId = ''.obs;
  RxString terminalID = CommonConstants.textEmpty.obs;
  RxString setServiceChargeAmout = CommonConstants.textEmpty.obs;
  final String intentCurrency = Get.arguments ?? '';

  final HomeController homeController = Get.find();
  final AppController appController = Get.find();

  // Card reader specific properties
  RxBool isCardReaderReady = false.obs;
  RxBool isProcessingPayment = false.obs;
  RxString cardReaderStatus = 'Initializing...'.obs;

  @override
  void onInit() {
    super.onInit();
    initializeCardReader();
  }

  @override
  void onClose() {
    amountController.dispose();
    descriptionController.dispose();
    amountFocus.dispose();
    descriptionFocus.dispose();
    super.onClose();
  }

  /// Initialize the MineSec card reader
  Future<void> initializeCardReader() async {
    try {
      cardReaderStatus.value = 'Initializing card reader...';

      // Get terminal profile ID - you may need to adjust this based on your app's configuration
      final terminalDetail =
          await SharedPrefManager.instance.getTerminalDetail();
      final profileId = terminalDetail?.terminalId ?? 'default_profile';

      final result = await MineSoftPOSService.instance.initialize(profileId);

      result.fold(
        onSuccess: (message) {
          isCardReaderReady.value = true;
          cardReaderStatus.value = 'Card reader ready';
          CustomDialog.showToast('Card reader initialized successfully');
        },
        onError: (error) {
          isCardReaderReady.value = false;
          cardReaderStatus.value = 'Card reader initialization failed';
          CustomDialog.showToast('Card reader initialization failed: $error');
        },
      );
    } catch (e) {
      isCardReaderReady.value = false;
      cardReaderStatus.value = 'Card reader initialization error';
      CustomDialog.showToast('Card reader initialization error: $e');
    }
  }

  /// Process payment using card reader
  void processCardPayment(BuildContext context) async {
    AppFocus.unfocus(context);

    if (!cardReaderFormKey.currentState!.validate() || !validateInput()) {
      return;
    }

    if (!isCardReaderReady.value) {
      CustomDialog.showToast(
          'Card reader not ready. Please wait or try again.');
      return;
    }

    isProcessingPayment.value = true;

    await EasyLoading.show(
      status: '${CommonConstants.loading.tr}...',
    );

    try {
      mDescription = descriptionController.text;
      mTotalAmount = amountController.text;

      final getTerminalID = SharedPrefManager.terminalID;
      terminalID.value = getTerminalID;

      String referenceNo = terminalID.value + StringUtils.getTimeStampGW2();
      await SecureSharedPreferences.instance.setReferenceNo(referenceNo);

      var saleAmount = StringUtils.toCents(mTotalAmount?.trim() ?? '');
      var serviceChargeAmout = StringUtils.toCents(setServiceChargeAmout.value);

      final totalAmountLimo =
          int.parse(saleAmount) + int.parse(serviceChargeAmout);

      // Convert amount to double for MineSec SDK
      final amountDouble =
          double.parse(saleAmount) / 100; // Convert from cents to dollars

      cardReaderStatus.value = 'Please insert or tap your card...';

      // Process payment using MineSec SDK
      final cardResult = await MineSoftPOSService.instance.processCardPayment(
        amount: amountDouble,
        currency: intentCurrency,
        description: mDescription,
      );

      await EasyLoading.dismiss();

      cardResult.fold(
        onSuccess: (paymentResult) {
          if (paymentResult.success) {
            mTransactionId.value = paymentResult.transactionId ?? '';
            cardReaderStatus.value = 'Payment successful';

            // Here you can integrate with your existing payment processing
            // For now, we'll simulate the existing transaction flow
            handleSuccessfulCardPayment(paymentResult);
          } else {
            cardReaderStatus.value = 'Payment failed';
            CustomDialog.showToast(
              paymentResult.errorMessage ?? 'Card payment failed',
            );
          }
        },
        onError: (error) {
          cardReaderStatus.value = 'Payment error';
          CustomDialog.showToast('Card payment error: $error');
        },
      );
    } catch (e) {
      await EasyLoading.dismiss();
      cardReaderStatus.value = 'Payment error';
      CustomDialog.showToast('Unexpected error: $e');
    } finally {
      isProcessingPayment.value = false;
    }
  }

  /// Handle successful card payment
  void handleSuccessfulCardPayment(CardPaymentResult paymentResult) {
    // You can integrate this with your existing payment processing logic
    // For example, you might want to call your backend API to record the transaction

    CustomDialog.showToast('Card payment successful!');

    // Navigate to receipt/transaction detail screen
    goToReceiptDetail();
  }

  void goToReceiptDetail() {
    if (mTransactionId.value.isNotEmpty) {
      Get.toNamed(
        Routes.TRANSACTION_HISTORY_DETAIL,
        arguments: {
          'mTransactionId': mTransactionId.value,
          'originalRemarks': null,
          'paymentMethod': 'card_reader',
        },
      );
    }
  }

  void updateAmount(String value) {
    // You can add amount formatting logic here if needed
  }

  bool validateInput() {
    mTotalAmount = amountController.text;

    if (amountController.text.isNotEmpty) {
      if (!isValidAmount()) {
        return false;
      }
    }
    return true;
  }

  bool isValidAmount() {
    if (mTotalAmount == '.') {
      CustomDialog.showToast(
        CommonConstants.amountGreatThan.tr,
      );
      return false;
    }
    if (double.parse(mTotalAmount ?? '0') == 0) {
      CustomDialog.showToast(
        CommonConstants.amountGreatThan.tr,
      );
      return false;
    }
    return true;
  }

  /// Retry card reader initialization
  void retryInitialization() {
    initializeCardReader();
  }

  /// Check card reader status
  void checkReaderStatus() async {
    final result = await MineSoftPOSService.instance.isReady();
    result.fold(
      onSuccess: (isReady) {
        isCardReaderReady.value = isReady;
        cardReaderStatus.value =
            isReady ? 'Card reader ready' : 'Card reader not ready';
      },
      onError: (error) {
        isCardReaderReady.value = false;
        cardReaderStatus.value = 'Status check failed';
      },
    );
  }
}
