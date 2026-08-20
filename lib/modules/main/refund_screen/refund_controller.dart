// ignore_for_file: unnecessary_null_comparison

import 'dart:ffi';

import 'package:app/app_controller.dart';
import 'package:app/models/request/amount.dart';
import 'package:app/models/request/credit_card_void_request/credit_card_void_request.dart';
import 'package:app/models/request/query_detail_request/query_detail_request.dart';
import 'package:app/models/request/refund_shopee_request/refund_shopee_request.dart';
import 'package:app/models/route_payment_model.dart';
import 'package:app/routes/app_pages.dart';
import 'package:app/shared/constants/constants_o7lite.dart';
import 'package:app/shared/shared.dart';
import 'package:app/shared/utils/responsive_util.dart';
import 'package:app/shared/secure_shared_preferences/sharepreference.dart';
import 'package:app/shared/widgets/custom_dialog/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
// import 'package:barcode_scan2/barcode_scan2.dart';
import '../../../api/api_repository.dart';
import '../../../models/request/querry_receipt_infor_request/querry_receipt_infor_request.dart';
import '../../../models/request/refund_transaction_request/refund_transaction_request.dart';
import '../../../shared/constants/image_constant.dart';
import '../../../shared/utils/enum/app_dialog_type.dart';
import '../../../shared/widgets/custom_text_style.dart';

class RefundController extends GetxController {
  final ApiRepository apiRepository;
  RefundController({required this.apiRepository});

  final AppController appController = Get.find();

  TextEditingController transactionIdRefundController = TextEditingController();
  final FocusNode transactionIdRefundFocus = FocusNode();
  final GlobalKey<FormState> transactionIdRefundFormKey =
      GlobalKey<FormState>();
  final GlobalKey<FormState> currentPasswordFormKey = GlobalKey<FormState>();
  TextEditingController currentPasswordController = TextEditingController();

  String mEtype = CommonConstants.textEmpty;
  String mCurrency = CommonConstants.textEmpty;
  String mTotalAmount = CommonConstants.textEmpty;

  bool isWallet = true;
  RxBool isPasswordVisible = true.obs;

  final RoutePaymentModel routePaymentModel = Get.arguments;

  bool isRequiredPassword = true;

  @override
  Future<void> onInit() async {
    mCurrency = routePaymentModel.currency ?? CommonConstants.textEmpty;
    mEtype = routePaymentModel.acquireReport ?? CommonConstants.textEmpty;
    isRequiredPassword =
        await SharedPrefManager.instance.getBool('isEnableRefundPassword') ??
            false;
    super.onInit();
  }

  void togglePasswordVisibility(RxBool isVisible) =>
      isVisible.value = !isVisible.value;

  void refundTransaction(BuildContext context) async {
    final isRequiredPassword =
        await SharedPrefManager.instance.getBool('isEnableRefundPassword') ??
            false;

    if (transactionIdRefundFormKey.currentState!.validate()) {
      isRequiredPassword
          ? CustomDialog.showCustomDialogConfirmPassword(
              isPasswordVisible: isPasswordVisible,
              onPressPassword: () =>
                  togglePasswordVisibility(isPasswordVisible),
              formKey: currentPasswordFormKey,
              currentPasswordController: currentPasswordController,
              titleButton: CommonConstants.ok.tr,
              content: '',
              context: Get.context!,
              onpressCancel: () {
                Get.back();
                currentPasswordController.clear();
              },
              onPressedCheck: () {
                if (currentPasswordFormKey.currentState!.validate()) {
                  Get.back();
                  currentPasswordController.clear();
                  onRefundClick();
                }
              },
              dialogType: AppDialogType.confirm,
            )
          : CustomDialog.showCustomDialog(
              titleButton: 'OK',
              content: CommonConstants.doYouWantRefundTransaction.tr,
              context: Get.context!,
              onpressCancel: () {
                Get.back();
              },
              onPressedCheck: () {
                Get.back();
                onRefundClick();
              },
              dialogType: AppDialogType.confirm,
            );
    }
  }

  void onRefundClick() async {
    if (StorageService.isGw3) {
      processRefundGw3();
    } else {
      processRefund();
    }
  }

  void processRefund() async {
    EasyLoading.show(
      status: '${CommonConstants.loading.tr}...',
    );

    String transactionId = transactionIdRefundController.text;

    final receiptInfo = await apiRepository.voidQueryDetail(
      QueryDetailRequest(
        transactionId: transactionId,
      ),
    );
    mTotalAmount = receiptInfo != null && receiptInfo.containsKey('totalAmount')
        ? receiptInfo['totalAmount']
        : mTotalAmount;
    if (receiptInfo != null) {
      if (isWallet) {
        if (mEtype == ConstantsO7Lite.SHOPEE_TYPE) {
          dynamic shopeeRefund = await apiRepository.refundShopee(
            RefundShopeeRequest(
              currency: mCurrency,
              totalAmount: mTotalAmount,
              originalTransactionId: transactionId,
            ),
          );

          if (shopeeRefund != null) {
            Future.delayed(Duration(milliseconds: 1500)).then(
              (_) => gotoReceiptDetail(
                transactionID: transactionId,
              ),
            );
          }
        } else {
          final refundResponse = await apiRepository.refundTransaction(
            RefundTransactionRequest(
              currency: mCurrency,
              eType: mEtype,
              totalAmount: mTotalAmount,
              tradeNo: transactionId,
            ),
          );
          if (refundResponse != null) {
            // ignore: use_build_context_synchronously
            Future.delayed(Duration(milliseconds: 1500)).then(
              (_) => gotoReceiptDetail(
                transactionID: transactionId,
              ),
            );
          }
        }
      } else {
        final creditCardVoidResponse = await apiRepository.creditCardVoid(
          CreditCardVoidRequest(
            currency: mCurrency,
            totalAmount: mTotalAmount,
            originalId: transactionId,
          ),
        );
        if (creditCardVoidResponse != null) {
          // ignore: use_build_context_synchronously
          Future.delayed(Duration(milliseconds: 1500)).then(
            (_) => gotoReceiptDetail(
              transactionID: transactionId,
            ),
          );
        } else {
          // Duplicate error message
          // CustomDialog.showMaterial(
          //   Get.context,
          //   CommonConstants.voidFail.tr,
          // );
        }
        // on Void done
      }
    }
    // to do : check invalid signature
    return;
  }

  void processRefundGw3() async {
    EasyLoading.show(
      status: '${CommonConstants.loading.tr}...',
    );

    String transactionId = transactionIdRefundController.text;

    // step 1: get detail transaction by transaction id
    final receiptInfo = await apiRepository.querryReceiptInfor(
      QuerryReceiptInforRequest(
        transactionId: transactionId,
      ),
      StorageService.isGw3,
    );

    if (receiptInfo != null) {
      if (receiptInfo.isAllowRefund == false) {
        CustomDialog.showMaterial(
          Get.context,
          'msgTransactionNotRefundable'.tr,
        );
        return;
      }

      mTotalAmount = receiptInfo.totalAmount.toString();
      mCurrency = receiptInfo.currency ?? CommonConstants.textEmpty;

      Amount amount = Amount(
        value: int.parse(mTotalAmount),
        currency: mCurrency,
      );

      final refundResponse = await apiRepository.refundTxn(
        transactionId,
        amount,
      );

      if (refundResponse?.oxpayTxnId.isNotEmpty == true) {
        // show dialog success
        CustomDialog.showMaterial(
          Get.context,
          'msgRefundSuccess'.tr,
          onPressed: () {
            Get.back();
            gotoReceiptDetail(
              transactionID: refundResponse?.oxpayTxnId ?? transactionId,
            );
          },
        );
      }
    }
    // step 2: check if the transaction is valid
    // step 3: check if the transaction is voidable
    // step 4: void the transaction
    // step 5: show success dialog
    // step 6: navigate to receipt detail
    EasyLoading.dismiss();
  }

  Future<void> scan() async {
    var result = await Get.toNamed(Routes.SCAN_QR_CODE);
    if (result == null || result.isEmpty) {
      return;
    }

    transactionIdRefundController.text = result;

    // isRequiredPassword
    //     ?  CustomDialog.showCustomDialogConfirmPassword(
    //         isPasswordVisible: isPasswordVisible,
    //         onPressPassword: () => togglePasswordVisibility(isPasswordVisible),
    //         formKey: currentPasswordFormKey,
    //         currentPasswordController: currentPasswordController,
    //         titleButton: CommonConstants.ok.tr,
    //         content: '',
    //         context: Get.context!,
    //         onpressCancel: () {
    //           Get.back();
    //           currentPasswordController.clear();
    //         },
    //         onPressedCheck: () {
    //           if (currentPasswordFormKey.currentState!.validate()) {
    //             Get.back();
    //             currentPasswordController.clear();
    //             processVoid();
    //           }
    //         },
    //         dialogType: AppDialogType.confirm,
    //       )
    //     : CustomDialog.showCustomDialog(
    //         titleButton: 'OK',
    //         content: CommonConstants.doYouWantRefundTransaction.tr,
    //         context: Get.context!,
    //         onpressCancel: () {
    //           Get.back();
    //         },
    //         onPressedCheck: () {
    //           Get.back();
    //           processVoid();
    //         },
    //         dialogType: AppDialogType.confirm,
    //       );
  }

  void gotoReceiptDetail({required String transactionID}) {
    Get.toNamed(
      Routes.TRANSACTION_HISTORY_DETAIL,
      arguments: {
        'mTransactionId': transactionID,
        'comeFromScreen': TransactionState.COMEFROMVOID,
        'originalRemarks': null,
      },
    );
  }

  Widget setImageTransactionRefund() {
    var ivVoidWalletIcon = ImageConstant.oxpayIconTransparentBackground;
    var titlePayment = '';

    switch (mEtype) {
      case ConstantsO7Lite.ALIPAY_TYPE:
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: appController.isDarkModeOn.value
                      ? ColorConstants.grey800
                      : ColorConstants.darkGray.withAlpha(50),
                ),
                padding: EdgeInsets.all(1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    ImageConstant.imageAlipay,
                    width: ResponsiveUtil().getSize(120),
                    height: ResponsiveUtil().getSize(120),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtil().getSize(10)),
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                'digitalPaymentAlipayQr'.tr,
                style: CustomTextStyles.labelBlack500Size24Fw600,
              ),
            ),
            SizedBox(height: ResponsiveUtil().getSize(10)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  10,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Image.asset(
                      ImageConstant
                          .imageAlipay, // Use existing alipay logo instead,
                      width: ResponsiveUtil().getSize(40),
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtil().getSize(10)),
          ],
        );
      case ConstantsO7Lite.WECHAT_TYPE:
        ivVoidWalletIcon = ImageConstant.imageWechatPay;
        titlePayment = 'paymentMethodWeChatPay'.tr;
        break;
      case ConstantsO7Lite.GRABPAY_TYPE:
      case ConstantsO7Lite.GRABPAY_V3_TYPE:
        ivVoidWalletIcon = ImageConstant.imageGrabPay;
        titlePayment = 'paymentMethodGrabPay'.tr;
        break;
      case ConstantsO7Lite.ATOME_TYPE:
        ivVoidWalletIcon = ImageConstant.imageAtome;
        titlePayment = 'paymentMethodAtome'.tr;
        break;
      case ConstantsO7Lite.PAYNOW_TYPE:
        ivVoidWalletIcon = ImageConstant.imagePaynow;
        titlePayment = 'paymentMethodPayNow'.tr;
        break;
      case ConstantsO7Lite.THAIQR_TYPE:
        ivVoidWalletIcon = ImageConstant.imageThaiQR;
        titlePayment = 'paymentMethodThaiQr'.tr;
        break;
      case ConstantsO7Lite.BOOST_TYPE:
        ivVoidWalletIcon = ImageConstant.imageBoost;
        titlePayment = 'paymentMethodBoost'.tr;
        break;
      case ConstantsO7Lite.TOUCHNGO_TYPE:
        ivVoidWalletIcon = ImageConstant.iconTouchNGoEWallet;
        titlePayment = 'paymentMethodTouchNGo'.tr;
        break;
      case ConstantsO7Lite.IOUPAY_TYPE:
        ivVoidWalletIcon = ImageConstant.imageIOUPay;
        break;
      case ConstantsO7Lite.DASH_TYPE:
        ivVoidWalletIcon = ImageConstant.imageSingleDash;
        titlePayment = 'paymentMethodDash'.tr;
        break;
      case ConstantsO7Lite.SHOPEE_TYPE:
        ivVoidWalletIcon = ImageConstant.imageShopeePay;
        titlePayment = 'paymentMethodShopeePay'.tr;
        break;
      case ConstantsO7Lite.QUICKPASS_TYPE:
        ivVoidWalletIcon = ImageConstant.imageIOUPay;
        titlePayment = 'paymentMethodIouPay'.tr;
        break;
      default:
        isWallet = false;
        break;
    }

    return isWallet
        ? Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: appController.isDarkModeOn.value
                        ? ColorConstants.grey800
                        : ColorConstants.darkGray.withAlpha(50),
                  ),
                  padding: EdgeInsets.all(1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      ivVoidWalletIcon,
                      width: ResponsiveUtil().getSize(120),
                      height: ResponsiveUtil().getSize(120),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtil().getSize(4)),
              Text(
                titlePayment,
                style: CustomTextStyles.labelBlack500Size24Fw600,
              ),
            ],
          )
        : (mEtype == ConstantsO7Lite.DASH_TYPE)
            ? Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: appController.isDarkModeOn.value
                            ? ColorConstants.grey800
                            : ColorConstants.darkGray.withAlpha(50),
                      ),
                      padding: EdgeInsets.all(1),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          ImageConstant.oxpayIconTransparentBackground,
                          width: ResponsiveUtil().getSize(120),
                          height: ResponsiveUtil().getSize(120),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtil().getSize(4)),
                  Text(
                    titlePayment,
                    style: CustomTextStyles.labelBlack500Size24Fw600,
                  ),
                ],
              )
            : Column(
                // TODO: card accept has been hidden following requirement
                // children: [
                //   Align(
                //     alignment: Alignment.topLeft,
                //     child: Text(
                //       'Card Accept:',
                //       style: CustomTextStyles.labelBlack500Size24Fw600,
                //     ),
                //   ),
                //   SizedBox(
                //     height: ResponsiveUtil().getSize(10),
                //   ),
                //   SingleChildScrollView(
                //     scrollDirection: Axis.horizontal,
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       children: [
                //         ImageConstant.iconAcceptVisa,
                //         ImageConstant.iconAcceptMasterCard,
                //         ImageConstant.iconAcceptAmex,
                //         ImageConstant.iconAcceptdiscover,
                //         ImageConstant.iconAcceptdiners,
                //         ImageConstant.iconAcceptJcb,
                //         ImageConstant.iconAcceptCup,
                //       ]
                //           .map((icon) => Image.asset(
                //                 icon,
                //                 height: ResponsiveUtil().getSize(40),
                //               ))
                //           .toList(),
                //     ),
                //   ),
                //   SizedBox(
                //     height: ResponsiveUtil().getSize(10),
                //   ),
                // ],
                );
  }

  Widget setImageTransactionRefundGw3() {
    var ivVoidWalletIcon = ImageConstant.oxpayIconTransparentBackground;
    var titlePayment = '';

    switch (mEtype) {
      case 'AliPay-GW2':
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: appController.isDarkModeOn.value
                      ? ColorConstants.grey800
                      : ColorConstants.darkGray.withAlpha(50),
                ),
                padding: EdgeInsets.all(1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    ImageConstant.imageAlipay,
                    width: ResponsiveUtil().getSize(120),
                    height: ResponsiveUtil().getSize(120),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtil().getSize(10)),
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                'digitalPaymentAlipayQr'.tr,
                style: CustomTextStyles.labelBlack500Size24Fw600,
              ),
            ),
            SizedBox(height: ResponsiveUtil().getSize(10)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  10,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Image.asset(
                      ImageConstant
                          .imageAlipay, // Use existing alipay logo instead,
                      width: ResponsiveUtil().getSize(40),
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtil().getSize(10)),
          ],
        );
      case 'WeChat':
        ivVoidWalletIcon = ImageConstant.imageWechatPay;
        titlePayment = 'paymentMethodWeChatPay'.tr;
        break;
      case 'GrabPay-SG':
        ivVoidWalletIcon = ImageConstant.imageGrabPay;
        titlePayment = 'paymentMethodGrabPay'.tr;
        break;
      case 'Atome':
        ivVoidWalletIcon = ImageConstant.imageAtome;
        titlePayment = 'paymentMethodAtome'.tr;
        break;
      case 'SCB':
        ivVoidWalletIcon = ImageConstant.imagePaynow;
        titlePayment = 'paymentMethodPayNow'.tr;
        break;
      case 'ThaiQR':
        ivVoidWalletIcon = ImageConstant.imageThaiQR;
        titlePayment = 'paymentMethodThaiQr'.tr;
        break;
      case 'Boost':
        ivVoidWalletIcon = ImageConstant.imageBoost;
        titlePayment = 'paymentMethodBoost'.tr;
        break;
      case 'TouchNGo':
        ivVoidWalletIcon = ImageConstant.iconTouchNGoEWallet;
        titlePayment = 'paymentMethodTouchNGo'.tr;
        break;
      case 'IOUPay':
        ivVoidWalletIcon = ImageConstant.imageIOUPay;
        break;
      case 'Dash':
        ivVoidWalletIcon = ImageConstant.imageSingleDash;
        titlePayment = 'paymentMethodDash'.tr;
        break;
      case 'ShopeePay':
        ivVoidWalletIcon = ImageConstant.imageShopeePay;
        titlePayment = 'paymentMethodShopeePay'.tr;
        break;
      case 'QuickPass':
        ivVoidWalletIcon = ImageConstant.imageIOUPay;
        titlePayment = 'paymentMethodIouPay'.tr;
        break;
      case 'Shopback':
        ivVoidWalletIcon = ImageConstant.iconShopback;
        titlePayment = 'paymentMethodShopback'.tr;
        break;
      case 'Shopback-MY':
        ivVoidWalletIcon = ImageConstant.iconShopback;
        titlePayment = 'paymentMethodShopback'.tr;
        break;
      default:
        isWallet = false;
        break;
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: appController.isDarkModeOn.value
                  ? ColorConstants.grey800
                  : ColorConstants.darkGray.withAlpha(50),
            ),
            padding: EdgeInsets.all(1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                ivVoidWalletIcon,
                width: ResponsiveUtil().getSize(120),
                height: ResponsiveUtil().getSize(120),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtil().getSize(4)),
        Text(
          titlePayment,
          style: CustomTextStyles.labelBlack500Size24Fw600,
        ),
      ],
    );
  }
}
