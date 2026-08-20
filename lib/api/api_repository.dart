import 'dart:async';
import 'dart:convert';
import 'package:app/models/response/refund_txn_response.dart';
import 'package:app/modules/auth/auth_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:app/models/request/amount.dart';
import 'package:app/models/request/auth_request/login_request/login_request_gw3.dart';
import 'package:app/models/request/cancel_qr_code_v6_request/cancel_qr_code_v6_request.dart';
import 'package:app/models/request/ewallet_void_request/ewallet_void_request.dart';
import 'package:app/models/request/payment_method.dart';
import 'package:app/models/request/querry_transaction_list_request/querry_transaction_list_request.dart';
import 'package:app/models/request/send_email_request/send_email_request.dart';
import 'package:app/models/response/ewallet_void_response/ewallet_void_response.dart';
import 'package:app/models/response/login_response/login_response_gw3.dart';
import 'package:app/models/response/payment_response.dart';
import 'package:app/models/response/querry_receipt_infor_response/address_response/address_response.dart';
import 'package:app/models/response/querry_receipt_infor_response/merchant_response/merchant_response.dart';
import 'package:app/models/response/termnial_detail.dart';
import 'package:app/models/response/transaction.dart';
import 'package:app/models/response/unifield_order_v6_response/unifield_order_v6_response.dart';
import 'package:app/routes/app_pages.dart';
import 'package:app/shared/secure_shared_preferences/secure_shared_preferences.dart';
import 'package:app/shared/secure_shared_preferences/sharepreference.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../models/request/auth_request/login_request/login_request.dart';
import '../models/request/credit_card_purchase/credit_card_purchase.dart';
import '../models/request/credit_card_void_request/credit_card_void_request.dart';
import '../models/request/digital_payment_request/digital_payment_request.dart';
import '../models/request/donation_terminal_detail_request/donation_terminal_detail_request.dart';
import '../models/request/get_payment_code_request/get_payment_code_request.dart';
import '../models/request/get_transacion_summary_AFG_request/get_transacion_summary_AFG_request.dart';
import '../models/request/querry_receipt_infor_request/querry_receipt_infor_request.dart';
import '../models/request/query_detail_request/query_detail_request.dart';
import '../models/request/refund_shopee_request/refund_shopee_request.dart';
import '../models/request/refund_transaction_request/refund_transaction_request.dart';
import '../models/request/unified_order_request/unified_order_request.dart';
import '../models/request/unified_order_v6_request/unified_order_v6_request.dart';
import '../models/response/base_response.dart';
import '../models/response/digital_response/digital_response.dart';
import '../models/response/donation_terminal_detail_response/donation_terminal_detail_response.dart';
import '../models/response/login_response/login_response.dart';
import '../models/response/querry_receipt_infor_response/querry_receipt_infor_response.dart';
import '../models/response/querry_transaction_list_response/querry_transaction_list_response.dart';
import '../models/response/transaction_list_response/transaction_list_response.dart';
import '../models/response/transaction_summary_AFG_response/transaction_summary_AFG_response.dart';
import '../models/response/transaction_summary_list_response/transaction_summary_list_response.dart';
import '../models/response/unifield_order_response/unifield_order_response.dart';
import '../shared/constants/common.dart';
import '../shared/services/storage_service.dart';
import '../shared/utils/enum/app_dialog_type.dart';
import '../shared/utils/enum/payment_error_code.dart';
import '../shared/widgets/custom_dialog/custom_dialog.dart';
import '../shared/widgets/dialog_common.dart';
import 'api.dart';
import 'package:app/shared/utils/log_utils.dart';

class ApiRepository extends GetxService {
  ApiRepository();

  final ApiProvider apiProvider = Get.find();

  Future<LoginResponse?> login(LoginRequest data) async {
    final res = await apiProvider.login('/v5/auth/terminal', data);
    if (res.statusCode == 200 &&
        res.body["header"]["status"]["responseCode"] == '0000') {
      var loginResponse = LoginResponse.fromJson(res.body);
      var jsonString = JsonEncoder().convert(loginResponse);
      if (kDebugMode) {
        print('loginResponse: $jsonString');
      }

      return loginResponse;
    }
    return null;
  }

  Future<LoginResponseGw3> loginGw3(LoginRequestGw3 data) async {
    final res = await apiProvider.loginGw3('/terminal/auth/login', data);
    if (res.statusCode == 200 && res.bodyString != null) {
      var loginResponse = LoginResponseGw3.fromJson(res.body);
      var jsonString = JsonEncoder().convert(loginResponse);
      if (kDebugMode) {
        print('loginResponse: $jsonString');
      }

      return loginResponse;
    }

    return LoginResponseGw3();
  }

  Future<LoginResponseGw3> refreshTokenGw3() async {
    final res = await apiProvider.refreshTokenGw3();
    if (res.statusCode == 200 && res.bodyString != null) {
      // IMPORTANT: Save refresh_token (not access_token) for future token refreshes
      await SharedPrefManager.setRefreshTokenSecure(res.body['refresh_token']);
      return LoginResponseGw3.fromJson(res.body);
    }
    return LoginResponseGw3();
  }

  Future<dynamic> getcreditCardPurchase(CreditCardPurchaseRequest data) async {
    final res = await apiProvider.creditCardPurchase('/v5/sale', data);
    if (res.statusCode == 200 &&
        res.body["header"]["status"]["responseCode"] == '0000') {
      return res.body;
    } else {
      Get.dialog(
        CustomAlertDialog(
          title: res.body["header"]["status"]["message"],
          onPressed: () {
            Get.back();
          },
        ),
      );
    }
    return null;
  }

  Future<dynamic> getcreditCardPurchaseLimo(
      CreditCardPurchaseRequest data) async {
    final res = await apiProvider.creditCardPurchaseLimo('/v5/sale', data);
    if (res.statusCode == 200 &&
        res.body["header"]["status"]["responseCode"] == '0000') {
      return res.body;
    } else {
      Get.dialog(
        CustomAlertDialog(
          title: res.body["header"]["status"]["message"],
          onPressed: () {
            Get.back();
          },
        ),
      );
    }
    return null;
  }

  Future<DigitalResponse?> digitalPayment(DigitalPaymentRequest data) async {
    final res = await apiProvider.digitalPayment('/v5/ewallet/quickPay', data);
    LogUtils.debugLog('digitalPayment Response::: ${res.body}');
    if (res.statusCode == 200 &&
        res.body["header"]["status"]["responseCode"] == '0000') {
      return DigitalResponse.fromJson(res.body);
    } else {
      Get.dialog(
        CustomAlertDialog(
          title: res.body["header"]["status"]["message"],
          onPressed: () {
            Get.back();
          },
        ),
      );
    }
    return null;
  }

  Future<DigitalResponse?> digitalPaymentLimo(
      DigitalPaymentRequest data) async {
    final res =
        await apiProvider.digitalPaymentLimo('/v5/ewallet/quickPay', data);
    LogUtils.debugLog('digitalPaymentLimo Response::: ${res.body}');
    if (res.statusCode == 200 &&
        res.body["header"]["status"]["responseCode"] == '0000') {
      return DigitalResponse.fromJson(res.body);
    } else {
      Get.dialog(
        CustomAlertDialog(
          title: res.body["header"]["status"]["message"],
          onPressed: () {
            Get.back();
          },
        ),
      );
    }
    return null;
  }

  Future<String?> getPaymentCode(GetPaymentCodeRequest data) async {
    final res = await apiProvider.getPaymentCode('/v6/payment', data);
    if (res.statusCode == 200 && res.body != null && res.body != '') {
      return res.body.toString();
    } else {
      Get.dialog(
        CustomAlertDialog(
          title: CommonConstants.paymentPageFailed.tr,
          onPressed: () {
            Get.back();
          },
        ),
      );
    }
    return null;
  }

  Future<String?> getPaymentCodeLimo(GetPaymentCodeRequest data) async {
    final res = await apiProvider.getPaymentCodeLimo('/v6/payment', data);
    if (res.statusCode == 200 && res.body != null && res.body != '') {
      return res.body.toString();
    } else {
      Get.dialog(
        CustomAlertDialog(
          title: CommonConstants.paymentPageFailed.tr,
          onPressed: () {
            Get.back();
          },
        ),
      );
    }
    return null;
  }

  Future<UnifiedOrderV6Response?> unifiedOrderV6(
      UnifiedOrderV6Request data, bool isMobile) async {
    final res;

    if (isMobile) {
      res = await apiProvider.unifiedOrderV6Limo(
          '/v6/ewallet/unified-order', data);
    } else {
      res = await apiProvider.unifiedOrderV6('/v6/ewallet/unified-order', data);
    }

    if (res.statusCode == 200 ||
        res.body["header"]["status"]["responseCode"] == '0000') {
      return UnifiedOrderV6Response.fromJson(res.body);
    } else {
      Get.dialog(
        CustomAlertDialog(
          title: CommonConstants.unifiedOderError.tr,
          onPressed: () {
            Get.back();
          },
        ),
      );
    }
    return null;
  }

  Future<UnifiedOrderResponse?> unifiedOrder(
      UnifiedOrderRequest data, bool isMobile) async {
    final res;
    if (isMobile) {
      res =
          await apiProvider.unifiedOrderLimo('/v5/ewallet/unifiedOrder', data);
    } else {
      res = await apiProvider.unifiedOrder('/v5/ewallet/unifiedOrder', data);
    }

    if (res.statusCode == 200 &&
        res.body["header"]["status"]["responseCode"] == '0000') {
      return UnifiedOrderResponse.fromJson(res.body['data']);
    } else {
      Get.dialog(
        CustomAlertDialog(
          title: CommonConstants.unifiedOderError.tr,
          onPressed: () {
            Get.back();
          },
        ),
      );
    }
    return null;
  }

  Future<EwalletVoidResponse?> ewalletVoid(EwalletVoidRequest data) async {
    final res = await apiProvider.ewalletVoid('/v5/ewallet/revokeOrder', data);
    if (res.statusCode == 200 &&
        res.body["header"]["status"]["responseCode"] == '0000') {
      return EwalletVoidResponse.fromJson(res.body);
    } else {
      Get.dialog(
        CustomAlertDialog(
          title: res.body["header"]["status"]["message"],
          onPressed: () {
            Get.back();
          },
        ),
      );
    }
    return null;
  }

  Future<BaseResponse?> cancelQrCodeV6(CancelQrCodeV6Request data) async {
    try {
      final res = await apiProvider.cancelQRCodeV6('/v6/ewallet/cancel', data);

      if (res.statusCode == 404) {
        return null;
      }

      if (res.statusCode == 200 ||
          res.body["header"]["status"]["responseCode"] == '0000') {
        return BaseResponse.fromJson(res.body);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<QuerryTransactionListResponse?> querryTransactionList(
      QuerryTransactionListRequest data) async {
    if (StorageService.isGw3) {
      final res = await getTransactions(
        data.startDate!,
        endDate: data.endDate,
        transactionId: data.transactionId,
        brands: data.brands,
        states: data.states,
        page: int.parse(data.page ?? '1'),
        pageSize: data.pageSize ?? 20,
      );

      if (res.isNotEmpty) {
        return QuerryTransactionListResponse(
          transactionList: res
              .map((e) => TransactionListResponse(
                    transactionId: e.oxpayTxnId,
                    transactionState: e.transactionState,
                    gatewayResponseDate: e.transactionDatetime,
                    gatewayRequestDate: e.transactionDatetime,
                    transactionType: e.transactionType ?? '',
                    brandName: e.paymentBrand,
                    totalAmount: e.transactionAmount.toString(),
                    saleAmount: e.transactionAmount.toString(),
                    currency: e.transactionCurrency,
                    hostTxnId: e.hostTxnId,
                  ))
              .toList(),
        );
      } else {
        return QuerryTransactionListResponse(transactionList: []);
      }
    } else {
      final res =
          await apiProvider.querryTransactionList('/v5/query/list', data);
      if (res.statusCode == 200 &&
          res.body["header"]["status"]["responseCode"] == '0000') {
        return QuerryTransactionListResponse.fromJson(res.body);
      } else {
        Get.dialog(
          CustomAlertDialog(
            title: res.body != null
                ? res.body["header"]["status"]["message"]
                : CommonConstants.pleaseTryAgain.tr,
            onPressed: () {
              Get.back();
            },
          ),
        );
      }
      return null;
    }
  }

  bool _isRequestInProgress = false;
  Future<QuerryReceiptInforResponse?> querryReceiptInfor(
      QuerryReceiptInforRequest data, bool isGw3) async {
    if (_isRequestInProgress) {
      return null; // Prevent duplicate request
    }

    _isRequestInProgress =
        true; // Set the flag to indicate a request is in progress

    try {
      if (isGw3) {
        final res = await apiProvider.getTransactionDetail(data.transactionId!);
        if (res.statusCode == 200 && res.body['data'] != null) {
          Transaction transaction = Transaction.fromJson(res.body['data']);

          TerminalDetail? terminalDetail =
              await SharedPrefManager.instance.getTerminalDetail();
          final merchant = MerchantResponse(
            shortName: terminalDetail?.merchant.name,
            address: AddressResponse(
              line1: terminalDetail?.merchant.addressLine1,
              line2: terminalDetail?.merchant.addressLine2,
              line3: terminalDetail?.merchant.addressLine3,
              city: terminalDetail?.merchant.city,
              postalCode: terminalDetail?.merchant.postalCode,
            ),
          );

          return QuerryReceiptInforResponse(
            transactionId: transaction.oxpayTxnId,
            transactionType: transaction.transactionType ?? '',
            transactionState: transaction.transactionState ?? '',
            gatewayRequestDate: transaction.transactionDatetime,
            brandName: transaction.paymentBrand,
            totalAmount: transaction.transactionAmount.toString(),
            currency: transaction.transactionCurrency,
            isAllowRefund: transaction.isAllowRefund,
            isAllowVoid: transaction.isAllowVoid,
            merchant: merchant,
            remarks: transaction.description,
          );
        } else {
          Get.dialog(
            CustomAlertDialog(
              title: res.body?['error_message'] ??
                  CommonConstants.pleaseTryAgain.tr,
              onPressed: () {
                Get.back();
              },
            ),
          );
        }
      } else {
        final res =
            await apiProvider.querryReceiptInfor('/v5/query/detail', data);
        if (res.statusCode == 200 &&
            res.body["header"]["status"]["responseCode"] == '0000') {
          return QuerryReceiptInforResponse.fromJson(res.body);
        } else {
          Get.dialog(
            CustomAlertDialog(
              title: res.body != null
                  ? res.body["header"]["status"]["message"]
                  : CommonConstants.pleaseTryAgain.tr,
              onPressed: () {
                Get.back();
              },
            ),
          );
        }
      }
    } catch (error) {
      // Handle any errors here if necessary
      LogUtils.debugLog("Error: $error");
    } finally {
      _isRequestInProgress = false; // Reset the flag when the request completes
    }

    return null;
  }

  Future<BaseResponse?> creditCardVoid(CreditCardVoidRequest data) async {
    final res = await apiProvider.creditCardVoid('/v5/void', data);
    if (res.statusCode == 200 &&
        res.body["header"]["status"]["responseCode"] == '0000') {
      return BaseResponse.fromJson(res.body);
    } else {
      Get.dialog(
        CustomAlertDialog(
          title: res.body["header"]["status"]["message"],
          onPressed: () {
            Get.back();
          },
        ),
      );
    }
    return null;
  }

  Future<BaseResponse?> refundShopee(RefundShopeeRequest data) async {
    final res = await apiProvider.refundShopee('/v5/refund', data);
    if (res.statusCode == 200 &&
        res.body["header"]["status"]["responseCode"] == '0000') {
      return BaseResponse.fromJson(res.body);
    } else {
      Get.dialog(
        CustomAlertDialog(
          title: res.body["header"]["status"]["message"],
          onPressed: () {
            Get.back();
          },
        ),
      );
    }
    return null;
  }

  Future<BaseResponse?> refundTransaction(RefundTransactionRequest data) async {
    final res = await apiProvider.refundTransaction('/v5/ewallet/refund', data);
    if (res.statusCode == 200 &&
        res.body["header"]["status"]["responseCode"] == '0000') {
      return BaseResponse.fromJson(res.body);
    } else {
      CustomDialog.showCustomDialog(
        dialogType: AppDialogType.failed,
        titleButton: 'Try Again',
        content: res.body["header"]["status"]["message"],
        context: Get.context!,
        onPressedCheck: () {
          Get.back();
        },
      );
    }
    return null;
  }

  Future<TransactionSummaryAFGResponse?> getTransacionSummaryAFG(
      GetTransacionSummaryAFGRequest data) async {
    final res =
        await apiProvider.getTransacionSummaryAFG('/v6/app/txn-summary', data);
    if (res.statusCode == 200 &&
        res.body != null &&
        res.body["header"]["success"] == true &&
        res.body["header"]["errorMessage"] == null) {
      return TransactionSummaryAFGResponse.fromJson(res.body);
    } else {
      if (data.isShowError == true) {
        EasyLoading.dismiss();
        Get.dialog(
          CustomAlertDialog(
            title: res.body != null
                ? res.body["header"]["errorMessage"]
                : CommonConstants.pleaseTryAgain.tr,
            onPressed: () {
              Get.back();
            },
          ),
        );
      }
    }
    return null;
  }

  Future<dynamic> voidQueryDetail(QueryDetailRequest data) async {
    final res = await apiProvider.voidQueryDetail('/v5/query/detail', data);
    if (res.statusCode == 200 &&
        res.body["header"]["status"]["responseCode"] == '0000') {
      return res.body["data"];
    } else {
      try {
        Get.dialog(
          CustomAlertDialog(
            title: res.body["header"]["status"]["message"],
            onPressed: () {
              Get.back();
            },
          ),
        );
      } catch (e) {
        CustomDialog.showMaterial(
          Get.context,
          CommonConstants.pleaseTryAgain.tr,
        );
      }
    }
    return null;
  }

  Future<DionationTerminalDetailResponse?> getDonationTerminalDetail(
      DonationTerminalDetailRequest data) async {
    final res = await apiProvider.getDonationTerminalDetail(
        '/v5/terminal/detail', data);
    if (res.statusCode == 200 &&
        res.body["header"]["status"]["responseCode"] == '0000') {
      return DionationTerminalDetailResponse.fromJson(res.body);
    } else {
      try {
        Get.dialog(
          CustomAlertDialog(
            title: res.body["header"]["status"]["message"],
            onPressed: () {
              Get.back();
            },
          ),
        );
      } catch (e) {
        CustomDialog.showMaterial(
          Get.context,
          CommonConstants.pleaseTryAgain.tr,
        );
      }
    }
    return null;
  }

  Future<bool> sendEmailReceipt(
    SendEmailRequest sendEmailRequest,
  ) async {
    final status = await apiProvider.sendEmailReceipt(
        "/v5/email/invoice", sendEmailRequest);
    if (status) {
      return true;
    } else {
      Get.dialog(
        CustomAlertDialog(
          title: CommonConstants.pleaseTryAgain.tr,
          onPressed: () {
            Get.back();
          },
        ),
      );
    }
    return false;
  }

  Future<TerminalDetail?> getTerminalDetail(String termnialId) async {
    final res = await apiProvider.getTerminalDetail('/terminal/', termnialId);
    if (res.statusCode == 200) {
      LogUtils.debugLog('Terminal Detail Response: ${res.body.toString()}');
      return TerminalDetail.fromJson(res.body);
    }

    // bad request
    if (res.statusCode == 400) {
      Get.dialog(
        CustomAlertDialog(
          title: res.body['error_message'],
          onPressed: () async {
            Get.back();
            await SecureSharedPreferences.instance.clearSecureSharedPef();
            Get.delete<AuthController>(force: true);
            Get.offAllNamed(Routes.LOG_IN, arguments: {'isLogout': true});
          },
        ),
      );
    } else {
      Get.dialog(
        CustomAlertDialog(
          title: CommonConstants.pleaseTryAgain.tr,
          onPressed: () {
            Get.back();
          },
        ),
      );
    }

    return null;
  }

  /// Resolves the most specific, user-friendly error message from a GW3
  /// sale/payment response [body].
  ///
  /// GW3 rejections may not populate `error_message` and instead expose the
  /// reason only through `error_description` (a gateway error code such as
  /// `SOUNDWAVE_PARSER_FAIL`). This inspects both fields at the top level and
  /// inside `data`, maps known error codes to friendly localized messages via
  /// [PaymentErrorCode], and finally falls back to any raw message, then
  /// [fallback].
  String _resolveSaleErrorMessage(dynamic body, {required String fallback}) {
    final Map? data =
        body is Map && body['data'] is Map ? body['data'] as Map : null;

    // GW3 exposes the reason via `error_description` (a code such as
    // `SOUNDWAVE_PARSER_FAIL`) and/or `error_message`, at the top level or
    // inside `data`.
    final errorDescription = (body is Map ? body['error_description'] : null) ??
        data?['error_description'];
    final errorMessage =
        (body is Map ? body['error_message'] : null) ?? data?['error_message'];

    // Map a known gateway error code (from either field) to a friendly message.
    final friendly =
        PaymentErrorCode.messageForCode(errorDescription?.toString()) ??
            PaymentErrorCode.messageForCode(errorMessage?.toString());
    if (friendly != null) return friendly;

    // Otherwise prefer any explicit message text, then the raw code, then the
    // localized fallback.
    final raw = errorMessage ?? errorDescription;
    final message = raw?.toString().trim();
    return (message == null || message.isEmpty) ? fallback : message;
  }

  Future<PaymentResponse?> saleRequest(
      PaymentMethod paymentMethod, Amount amount,
      {String? description}) async {
    final res = await apiProvider.saleRequest(paymentMethod, amount,
        description: description);

    final body = res.body;
    final statusMessage =
        body is Map ? body['status_message']?.toString().toUpperCase() : null;
    final isRejected = statusMessage == 'REJECTED';

    // Success: HTTP 200 with a data payload and not explicitly rejected.
    if (res.statusCode == 200 &&
        body is Map &&
        body['data'] != null &&
        !isRejected) {
      return PaymentResponse.fromJson(body['data']);
    }

    // Rejected or failed: surface the most specific message available.
    Get.dialog(
      CustomAlertDialog(
        title: _resolveSaleErrorMessage(
          body,
          fallback: (isRejected
                  ? CommonConstants.paymentRejected
                  : CommonConstants.paymentFailed)
              .tr,
        ),
        onPressed: () async {
          Get.back();
        },
      ),
    );
    return null;
  }

  // Gw3 Transactions
  Future<List<Transaction>> getTransactions(String startDay,
      {String? endDate,
      String? transactionId,
      List<String>? brands,
      List<String>? states,
      int? page,
      int? pageSize}) async {
    final res = await apiProvider.getTransactions(startDay, endDate,
        transactionId, brands, states, page.toString(), pageSize ?? 20);

    if (res.statusCode == 200) {
      var dataList = res.body['data'];
      if (dataList != null) {
        return dataList
            .map<Transaction>((e) => Transaction.fromJson(e))
            .toList();
      } else {
        return [];
      }
    }

    // bad request
    if (res.statusCode == 400) {
      Get.dialog(
        CustomAlertDialog(
          title: res.body['error_message'],
          onPressed: () async {
            Get.back();
          },
        ),
      );
    } else {
      Get.dialog(
        CustomAlertDialog(
          title: CommonConstants.pleaseTryAgain.tr,
          onPressed: () {
            Get.back();
          },
        ),
      );
    }

    return [];
  }

  // Gw3 Transaction Detail
  Future<Transaction?> getTransactionDetail(String txnId) async {
    final res = await apiProvider.getTransactionDetail(txnId);

    if (res.statusCode == 200) {
      return Transaction.fromJson(res.body['data']);
    }

    // bad request
    if (res.statusCode == 400) {
      Get.dialog(
        CustomAlertDialog(
          title: res.body['error_message'],
          onPressed: () async {
            Get.back();
          },
        ),
      );
    } else {
      Get.dialog(
        CustomAlertDialog(
          title: CommonConstants.pleaseTryAgain.tr,
          onPressed: () {
            Get.back();
          },
        ),
      );
    }

    return null;
  }

  Future<RefundTxnResponse?> refundTxn(String txnId, Amount amount) async {
    try {
      final res = await apiProvider.refundTxn(txnId, amount);
      if (res.statusCode == 200 && res.body['data'] != null) {
        LogUtils.debugLog('REFUND API::: Response data: ${res.body['data']}');
        return RefundTxnResponse.fromJson(res.body['data']);
      } else {
        Get.dialog(
          CustomAlertDialog(
            title: res.body['error_message'] ?? 'Refund failed',
            onPressed: () {
              Get.back();
            },
          ),
        );
      }
    } catch (e) {
      LogUtils.debugLog('REFUND API::: Error: $e');
      Get.dialog(
        CustomAlertDialog(
          title: e.toString(),
          onPressed: () {
            Get.back();
          },
        ),
      );
    }

    return null;
  }

  Future<bool> voidTxn(String txnId, Amount amount) async {
    try {
      final res = await apiProvider.voidTxn(txnId, amount);
      if (res.statusCode == 200) {
        return true;
      } else {
        Get.dialog(
          CustomAlertDialog(
            title: res.body['error_message'],
            onPressed: () {
              Get.back();
            },
          ),
        );
      }
    } catch (e) {
      Get.dialog(
        CustomAlertDialog(
          title: e.toString(),
          onPressed: () {
            Get.back();
          },
        ),
      );
    }
    return false;
  }

  Future<String?> createPaymentHostedPage(Amount amount) async {
    final res = await apiProvider.createPaymentHostedPage(amount);

    final body = res.body;
    final statusMessage =
        body is Map ? body['status_message']?.toString().toUpperCase() : null;
    final isRejected = statusMessage == 'REJECTED';

    if (res.statusCode == 200 &&
        body is Map &&
        body['data'] != null &&
        !isRejected) {
      return body['data']['oxpay_hpp_url'];
    }

    Get.dialog(
      CustomAlertDialog(
        title: _resolveSaleErrorMessage(
          body,
          fallback: (isRejected
                  ? CommonConstants.paymentRejected
                  : CommonConstants.paymentFailed)
              .tr,
        ),
        onPressed: () async {
          Get.back();
        },
      ),
    );
    return null;
  }

  Future<TransactionSummaryAFGResponse?> getTransacionSummaryAFGTest(
      GetTransacionSummaryAFGRequest data) async {
    final res =
        await apiProvider.getTransacionSummaryAFG('/v6/app/txn-summary', data);
    if (res.statusCode == 200 &&
        res.body != null &&
        res.body["header"]["success"] == true &&
        res.body["header"]["errorMessage"] == null) {
      return TransactionSummaryAFGResponse.fromJson(res.body);
    } else {
      if (data.isShowError == true) {
        EasyLoading.dismiss();
        Get.dialog(
          CustomAlertDialog(
            title: res.body != null
                ? res.body["header"]["errorMessage"]
                : CommonConstants.pleaseTryAgain.tr,
            onPressed: () {
              Get.back();
            },
          ),
        );
      }
    }
    return null;
  }

  Future<TransactionSummaryAFGResponse?> getTxnSummaryReportGw3(
      String paymentHost,
      String currency,
      String startDate,
      String endDate) async {
    final res = await apiProvider.txnSummaryReportGw3(
        paymentHost, currency, startDate, endDate);

    if (res.statusCode == 200) {
      TransactionSummaryAFGResponse transactionSummaryAFGResponse =
          new TransactionSummaryAFGResponse();

      var data = res.body['data'];

      if (data != null) {
        transactionSummaryAFGResponse.totalCount =
            int.parse(data['total_count']?.toString() ?? '0');
        transactionSummaryAFGResponse.totalPayAmount =
            double.parse(data['total_pay_amount']?.toString() ?? '0');
        transactionSummaryAFGResponse.totalPayCount =
            int.parse(data['total_pay_count']?.toString() ?? '0');
        transactionSummaryAFGResponse.totalVoidAmount =
            double.parse(data['total_void_amount']?.toString() ?? '0');
        transactionSummaryAFGResponse.totalVoidCount =
            int.parse(data['total_void_count']?.toString() ?? '0');
        transactionSummaryAFGResponse.totalRefundAmount =
            int.parse(data['total_refund_amount']?.toString() ?? '0');
        transactionSummaryAFGResponse.totalRefundCount =
            int.parse(data['total_refund_count']?.toString() ?? '0');

        // parse transaction_list to TransactionSummaryListResponse
        var transactionList = data['transaction_list'];
        if (transactionList != null && transactionList.isNotEmpty) {
          List<TransactionSummaryListResponse> newTransactionList = [];

          transactionList
              .map((e) => {
                    newTransactionList.add(
                      new TransactionSummaryListResponse(
                          id: e['oxpay_txn_id'],
                          merchantId: e['merchant_id'],
                          mcpTerminalId: e['terminal_id'],
                          // paymentHost: e['payment_host'],
                          brandName: e['brand_name'],
                          merchantName: e['merchant_name'],
                          remarks: e['merchant_reference_id'],
                          type: e['transaction_type'],
                          country: e['merchant_country'],
                          gatewayResponseDate: e['transaction_datetime'],
                          gatewayRequestDate: e['transaction_datetime'],
                          totalAmount: e['transaction_amount'],
                          currency: e['transaction_currency'],
                          state: e['transaction_state']),
                    )
                  })
              .toList();

          transactionSummaryAFGResponse.transactionList = newTransactionList;
        }
      }

      return transactionSummaryAFGResponse;
    } else {
      Get.dialog(
        CustomAlertDialog(
          title: res.body['error_message'],
          onPressed: () async {
            Get.back();
          },
        ),
      );
      return null;
    }
  }
}
