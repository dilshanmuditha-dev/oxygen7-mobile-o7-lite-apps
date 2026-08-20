// ignore_for_file: unnecessary_null_comparison

import 'package:app/api/api_repository.dart';
import 'package:app/app_controller.dart';
import 'package:app/models/request/credit_card_purchase/credit_card_purchase.dart';
import 'package:app/routes/app_pages.dart';
import 'package:app/shared/constants/common.dart';
import 'package:app/shared/constants/constants_o7lite.dart';
import 'package:app/shared/secure_shared_preferences/secure_shared_preferences.dart';
import 'package:app/shared/widgets/custom_dialog/custom_dialog.dart';
import 'package:app/shared/widgets/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../shared/secure_shared_preferences/sharepreference.dart';
import '../../../shared/utils/focus.dart';
import '../home_controller.dart';

class CreditCardController extends GetxController {
  final ApiRepository apiRepository;
  CreditCardController({required this.apiRepository});
  TextEditingController amountController = TextEditingController();
  TextEditingController cardNumberController = TextEditingController();
  TextEditingController cardHolderController = TextEditingController();
  TextEditingController expiryDateController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController cvcController = TextEditingController();

  final FocusNode amountFocus = FocusNode();
  final FocusNode cardNumberFocus = FocusNode();
  final FocusNode cardHolderFocus = FocusNode();
  final FocusNode expiryDateFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode();
  final FocusNode cvcFocus = FocusNode();

  final GlobalKey<FormState> creditCardFormKey = GlobalKey<FormState>();

  RxInt currentLength = 0.obs;
  RxInt currentCVCLength = 0.obs;

  String? mCardHolderName;
  String? mPlainPan;
  String? mTotalAmount;
  String? mExpireMM;
  String? mExpireYY;
  String? mCurrency;
  String? mCVC;
  String? mItemDescription;
  RxString mTransactionId = ''.obs;
  RxString terminalID = CommonConstants.textEmpty.obs;
  RxString expiry = CommonConstants.textEmpty.obs;
  RxString setServiceChargeAmout = CommonConstants.textEmpty.obs;
  final String intentCurrency = Get.arguments ?? '';

  final HomeController homeController = Get.find();
  final AppController appController = Get.find();

  void payNow(BuildContext context) async {
    AppFocus.unfocus(context);
    if (creditCardFormKey.currentState!.validate() && validateInput()) {
      await EasyLoading.show(
        status: '${CommonConstants.loading.tr}...',
      );
      processPayment();
    } else {}
  }

  void processPayment() async {
    mCardHolderName = cardHolderController.text;
    mItemDescription = descriptionController.text;
    mPlainPan = cardNumberController.text;
    mCVC = cvcController.text;

    final getTerminalID = SharedPrefManager.terminalID;
    terminalID.value = getTerminalID;

    String referenceNo = terminalID + StringUtils.getTimeStampGW2();
    await SecureSharedPreferences.instance.setReferenceNo(referenceNo);
    String expiryDateValue = expiryDateController.text.replaceAll('/', '');

    var saleAmount = StringUtils.toCents(mTotalAmount?.trim() ?? '');
    var serviceChargeAmout = StringUtils.toCents(setServiceChargeAmout.value);

    final totalAmountLimo =
        int.parse(saleAmount) + int.parse(serviceChargeAmout);

    final receiptInfo = appController.isMobileUser.value
        ? await apiRepository.getcreditCardPurchaseLimo(
            CreditCardPurchaseRequest(
              salesAmount: saleAmount,
              serviceAmount: serviceChargeAmout,
              serviceRate: homeController.getServiceChargeRate.value.toString(),
              currency: intentCurrency,
              pan: mPlainPan ?? '',
              cardExpiryDate: expiryDateValue,
              cardHolderName: mCardHolderName ?? '',
              cvv: mCVC ?? '',
              description: mItemDescription ?? '',
              totalAmount: totalAmountLimo.toString(),
              referenceNo: referenceNo,
            ),
          )
        : await apiRepository.getcreditCardPurchase(
            CreditCardPurchaseRequest(
              currency: intentCurrency,
              pan: mPlainPan ?? '',
              cardExpiryDate: expiryDateValue,
              cardHolderName: mCardHolderName ?? '',
              cvv: mCVC ?? '',
              description: mItemDescription ?? '',
              totalAmount: saleAmount,
              referenceNo: referenceNo,
            ),
          );

    if (receiptInfo != null) {
      final transactionState = receiptInfo["transactionState"];
      final transactionId = receiptInfo["transactionId"];

      if (TransactionState.STATE_SUCCESS == transactionState ||
          TransactionState.STATE_AUTHORIZED == transactionState) {
        mTransactionId.value = transactionId ?? '';
        goToReceiptDetail();
      } else if (TransactionState.STATE_USER_PAYING == transactionState) {
        //TODO: Add 3DS Logic here
      }
    }
  }

  void goToReceiptDetail() {
    if (mTransactionId.value != null) {
      Get.toNamed(
        Routes.TRANSACTION_HISTORY_DETAIL,
        arguments: {
          'mTransactionId': mTransactionId.value,
          'originalRemarks': null,
        },
      );
    }
  }

  void updateLength(String value) {
    currentLength.value = value.length;
  }

  void updateCVCLength(String value) {
    currentCVCLength.value = value.length;
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
    if (double.parse(mTotalAmount ?? '') == 0) {
      CustomDialog.showToast(
        CommonConstants.amountGreatThan.tr,
      );
      return false;
    }
    return true;
  }

  String getFormattedExpireMM(String dateText) {
    try {
      DateTime selectedDate = DateFormat('MM/dd/yyyy').parseStrict(dateText);

      int month = selectedDate.month;
      int year = selectedDate.year % 100;

      String formattedExpireMM =
          '${month.toString().padLeft(2, '0')}${year.toString().padLeft(2, '0')}';

      return formattedExpireMM;
    } catch (e) {
      return '';
    }
  }
}
