import 'dart:convert';
import 'dart:math';
import 'package:app/modules/auth/auth_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:app/models/request/amount.dart';
import 'package:app/models/request/auth_request/login_request/login_request_gw3.dart';
import 'package:app/models/request/credit_card_purchase/credit_card_purchase.dart';
import 'package:app/models/request/payment_method.dart';
import 'package:app/models/request/payment_request.dart';
import 'package:app/models/request/refund_void_request.dart';
import 'package:app/models/request/send_email_request/send_email_request.dart';
import 'package:app/models/response/termnial_detail.dart';
import 'package:app/routes/app_pages.dart';
import 'package:app/shared/secure_shared_preferences/sharepreference.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/request/auth_request/login_request/login_request.dart';
import '../models/request/cancel_qr_code_v6_request/cancel_qr_code_v6_request.dart';
import '../models/request/credit_card_void_request/credit_card_void_request.dart';
import '../models/request/digital_payment_request/digital_payment_request.dart';
import '../models/request/donation_terminal_detail_request/donation_terminal_detail_request.dart';
import '../models/request/ewallet_void_request/ewallet_void_request.dart';
import '../models/request/get_payment_code_request/get_payment_code_request.dart';
import '../models/request/get_transacion_summary_AFG_request/get_transacion_summary_AFG_request.dart';
import '../models/request/querry_receipt_infor_request/querry_receipt_infor_request.dart';
import '../models/request/querry_transaction_list_request/querry_transaction_list_request.dart';
import '../models/request/query_detail_request/query_detail_request.dart';
import '../models/request/refund_shopee_request/refund_shopee_request.dart';
import '../models/request/refund_transaction_request/refund_transaction_request.dart';
import '../models/request/unified_order_request/unified_order_request.dart';
import '../models/request/unified_order_v6_request/unified_order_v6_request.dart';
import '../shared/constants/constants_o7lite.dart';
import '../shared/secure_shared_preferences/secure_shared_preferences.dart';
import '../shared/services/storage_service.dart';
import '../shared/utils/app_flavor_helper.dart';
import '../shared/utils/log_utils.dart';
import 'api_constants.dart';
import 'base_provider.dart';
import 'package:http/http.dart' as http;

class ApiProvider extends BaseProvider {
  ApiProvider(AppFlavor flavor) : super(flavor);
  static ApiProvider get to => Get.find();

  String appType = "o7lite3";
  String appVersion = "";
  String version = "";

  @override
  void onInit() async {
    getVersionCode();

    super.onInit();
  }

  getVersionCode() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      version = packageInfo.buildNumber;
      appVersion = packageInfo.version;
    });
  }

  Future<Response> login(String path, LoginRequest data) {
    var dataRequest = json.encode(
      {
        "data": {
          "fcmTokenId": "",
          "ipAddress": "",
          "password": data.password,
          "userId": data.username,
        },
        "header": {
          "appType": appType,
          "appVersion": appVersion,
          "version": version,
        },
      },
    );

    if (kDebugMode) {
      print("Login Request:: $dataRequest");
    }

    return post(
      path,
      dataRequest,
    );
  }

  Future<Response> loginGw3(String path, LoginRequestGw3 data) {
    var dataRequest = json.encode(
      {"username": data.operatorName, "password": data.operatorPassword},
    );

    if (kDebugMode) {
      print("Login Request:: $dataRequest");
    }

    return post(
      path,
      dataRequest,
    );
  }

  /// Logout for GW3 gateway
  ///
  /// Invalidates the current access token on the server side so it cannot
  /// be reused. This should be called before clearing local session data.
  ///
  /// Request payload:
  /// - access_token: The current JWT access token
  ///
  /// Returns:
  /// - 200 on successful logout
  /// - Error response if token is already invalid (safe to ignore)
  Future<Response> logOutGw3() async {
    final accessToken =
        await SecureSharedPreferences.instance.getAccessToken() ?? '';

    var dataRequest = json.encode({"access_token": accessToken});

    if (kDebugMode) {
      print("Logout GW3 Request:: $dataRequest");
    }

    return post(
      '/terminal/auth/logout',
      dataRequest,
    );
  }

  /// Refresh JWT access token for GW3 gateway
  ///
  /// This method calls the GW3 refresh token endpoint to obtain a new access token
  /// when the current one has expired. It uses the stored refresh token and the
  /// correct login identifier (operatorId for username-based login, terminal ID otherwise).
  ///
  /// Request payload:
  /// - username: Operator ID (if username-based login) or Terminal ID
  /// - refresh_token: Stored refresh token from SharedPrefManager
  ///
  /// Returns:
  /// - Response containing new access_token and refresh_token on success
  /// - 401/403 response if refresh token is invalid or expired
  Future<Response> refreshTokenGw3() async {
    // For username-based login (e.g. "WATSONLOYANG"), the operatorId is the
    // actual login credential, not the terminal ID. We must use operatorId
    // when available so the refresh endpoint recognises the user.
    final String? operatorId =
        await SecureSharedPreferences.instance.getOperatorId();
    final String loginName = (operatorId != null && operatorId.isNotEmpty)
        ? operatorId
        : SharedPrefManager.terminalID;

    final storedRefreshToken =
        await SharedPrefManager.getRefreshTokenSecure() ?? '';
    var dataRequest = json
        .encode({"username": loginName, "refresh_token": storedRefreshToken});

    if (kDebugMode) {
      print("Refresh Token Request:: $dataRequest");
    }

    return post(
      '/terminal/auth/refresh-token',
      dataRequest,
    );
  }

  /// Wrapper method that automatically handles JWT token refresh for GW3 API calls
  ///
  /// This method provides transparent token refresh functionality by:
  /// 1. Executing the API call with current token
  /// 2. Detecting 401 Unauthorized responses
  /// 3. Automatically calling refreshTokenGw3() to get new tokens
  /// 4. Updating stored tokens in SecureSharedPreferences
  /// 5. Retrying the original API call with new token
  ///
  /// Features:
  /// - Only applies to GW3 requests (checked via StorageService.isGw3)
  /// - Single retry attempt to prevent infinite loops
  /// - Graceful error handling if refresh fails
  /// - Console logging for debugging token refresh process
  ///
  /// Usage:
  /// ```dart
  /// return await _callWithTokenRefresh(() async {
  ///   // Your API call implementation here
  ///   return post('/endpoint', data, headers: headers);
  /// });
  /// ```
  ///
  /// Parameters:
  /// - apiCall: Function that returns Future<Response> containing the actual API call
  ///
  /// Returns:
  /// - Response from successful API call (either first attempt or retry after refresh)
  /// - Original 401 response if token refresh fails
  Future<Response> _callWithTokenRefresh(
    Future<Response> Function() apiCall,
  ) async {
    if (!StorageService.isGw3) {
      // For non-GW3, just call the API directly
      return await apiCall();
    }

    // First attempt with current access token
    Response response = await apiCall();

    // If unauthorized and we're using GW3, try to refresh token and retry
    if (response.statusCode == 401) {
      if (kDebugMode) {
        print("GW3: Received 401, attempting token refresh...");
      }

      try {
        // Attempt to refresh the token
        final refreshResponse = await refreshTokenGw3();

        if (refreshResponse.statusCode == 200 &&
            refreshResponse.bodyString != null) {
          // Token refresh successful, update stored tokens
          final refreshData = refreshResponse.body;
          final newAccessToken = refreshData['access_token'];
          final newRefreshToken = refreshData['refresh_token'];

          if (newAccessToken != null) {
            // Update access token in secure storage
            await SecureSharedPreferences.instance
                .setAccessToken(newAccessToken);

            // Update refresh token if provided (token rotation)
            // If refresh_token is not in response, keep the old one
            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              await SharedPrefManager.setRefreshTokenSecure(newRefreshToken);
              if (kDebugMode) {
                print("GW3: Token rotation - refresh_token updated");
              }
            } else {
              if (kDebugMode) {
                print(
                    "GW3: No new refresh_token in response, keeping existing one");
              }
            }

            if (kDebugMode) {
              print(
                  "GW3: Token refreshed successfully, retrying original request");
            }

            // Retry the original API call with new token
            response = await apiCall();

            if (response.statusCode == 200) {
              if (kDebugMode) {
                print("GW3: Retry successful - API call completed");
              }
            } else {
              if (kDebugMode) {
                print("GW3: Retry failed with status: ${response.statusCode}");
              }
            }
          }
        } else {
          if (kDebugMode) {
            print(
                "GW3: Token refresh failed with status: ${refreshResponse.statusCode}");
            print("GW3: Response body: ${refreshResponse.bodyString}");
          }
          // if refresh token is invalid, we need to logout the user and redirect to the login screen and show a message to the user
          _clearTokensAndRedirectToLogin();
        }
      } catch (e) {
        if (kDebugMode) {
          print("GW3: Error during token refresh: $e");
          print("GW3: Stack trace: ${StackTrace.current}");
        }
        // Propagate the error to be handled by caller
        rethrow;
      }
    }

    return response;
  }

  Future<void> _clearTokensAndRedirectToLogin() async {
    await SecureSharedPreferences.instance.clearSecureSharedPef();
    await SharedPrefManager.setRefreshTokenSecure('');
    SharedPrefManager.setTerminalID = '';
    Get.delete<AuthController>(force: true);
    await Get.offAllNamed(Routes.LOG_IN, arguments: {'isLogout': true});
    Fluttertoast.showToast(
      msg: 'Session expired. Please login again.',
      toastLength: Toast.LENGTH_SHORT,
      timeInSecForIosWeb: 1,
    );
  }

  Future<Response> creditCardPurchase(
      String path, CreditCardPurchaseRequest data) async {
    return post(
      path,
      json.encode(
        {
          "data": {
            "cardExpiryDate": data.cardExpiryDate,
            "cardHolderName": data.cardHolderName,
            "currency": data.currency,
            "cvv": data.cvv,
            "description": data.description,
            "totalAmount": data.totalAmount,
            "referenceNo": data.referenceNo,
            "pan": data.pan,
          },
          "header": {
            "appType": appType,
            "appVersion": appVersion,
            "version": version,
            ConstantsO7Lite.MCP_TERMINAL_ID: SharedPrefManager.terminalID,
            ConstantsO7Lite.SIGNATURE:
                await SecureSharedPreferences.instance.signature(),
          }
        },
      ),
    );
  }

  Future<Response> creditCardPurchaseLimo(
      String path, CreditCardPurchaseRequest data) async {
    return post(
      path,
      json.encode(
        {
          "data": {
            "salesAmount": data.salesAmount,
            "serviceAmount": data.serviceAmount,
            "serviceRate": data.serviceRate,
            "cardExpiryDate": data.cardExpiryDate,
            "cardHolderName": data.cardHolderName,
            "currency": data.currency,
            "cvv": data.cvv,
            "description": data.description,
            "totalAmount": data.totalAmount,
            "referenceNo": data.referenceNo,
            "pan": data.pan,
          },
          "header": {
            "appType": appType,
            "appVersion": appVersion,
            "version": version,
            ConstantsO7Lite.MCP_TERMINAL_ID: SharedPrefManager.terminalID,
            ConstantsO7Lite.SIGNATURE:
                await SecureSharedPreferences.instance.signature(),
          }
        },
      ),
    );
  }

  Future<Response> digitalPayment(
      String path, DigitalPaymentRequest data) async {
    var dataRequest = json.encode(
      {
        "data": {
          "additionalText": "Deprecated",
          "authCode": data.authCode,
          "currency": data.currency,
          "description": data.description,
          "eType": data.eType,
          "ipAddress": data.ipAddress,
          "itemDetails": "Deprecated",
          "totalAmount": data.totalAmount
        },
        "header": {
          "appType": appType,
          "appVersion": appVersion,
          "version": version,
          ConstantsO7Lite.MCP_TERMINAL_ID: SharedPrefManager.terminalID,
          ConstantsO7Lite.SIGNATURE:
              await SecureSharedPreferences.instance.signature(),
        }
      },
    );

    LogUtils.debugLog('digitalPayment::: $dataRequest');

    return post(
      path,
      dataRequest,
    );
  }

  Future<Response> digitalPaymentLimo(
      String path, DigitalPaymentRequest data) async {
    var dataRequest = json.encode(
      {
        "data": {
          "salesAmount": data.salesAmount,
          "serviceAmount": data.serviceAmount,
          "serviceRate": data.serviceRate,
          "additionalText": "Deprecated",
          "authCode": data.authCode,
          "currency": data.currency,
          "description": data.description,
          "eType": data.eType,
          "ipAddress": data.ipAddress,
          "itemDetails": "Deprecated",
          "totalAmount": data.totalAmount
        },
        "header": {
          "appType": appType,
          "appVersion": appVersion,
          "version": version,
          ConstantsO7Lite.MCP_TERMINAL_ID: SharedPrefManager.terminalID,
          ConstantsO7Lite.SIGNATURE:
              await SecureSharedPreferences.instance.signature(),
        }
      },
    );

    LogUtils.debugLog('digitalPaymentLimo::: $dataRequest');

    return post(
      path,
      dataRequest,
    );
  }

  Future<Response> getPaymentCode(
      String path, GetPaymentCodeRequest data) async {
    var dataRequest = json.encode(
      {
        "currency": data.currency,
        "description": data.description,
        "itemDetail": data.description,
        "mcptid": data.mcptid,
        "referenceNo": data.referenceNo,
        "remarks": data.remarks,
        "returnUrl": data.returnUrl,
        "statusUrl": data.statusUrl,
        "tokenize": data.tokenize,
        "totalAmount": data.totalAmount,
      },
    );

    LogUtils.debugLog('getPaymentCode::: $dataRequest');

    return post(
      path,
      dataRequest,
    );
  }

  Future<Response> getPaymentCodeLimo(
      String path, GetPaymentCodeRequest data) async {
    var dataRequest = json.encode(
      {
        "currency": data.currency,
        "description": data.description,
        "itemDetail": data.description,
        "mcptid": data.mcptid,
        "referenceNo": data.referenceNo,
        "remarks": data.remarks,
        "returnUrl": data.returnUrl,
        "statusUrl": data.statusUrl,
        "tokenize": data.tokenize,
        "totalAmount": data.totalAmount,
        "salesAmount": data.salesAmount,
        "serviceAmount": data.serviceAmount,
        "serviceRate": data.serviceRate,
      },
    );

    LogUtils.debugLog('getPaymentCodeLimo::: $dataRequest');

    return post(
      path,
      dataRequest,
    );
  }

  Future<Response> unifiedOrderV6(
      String path, UnifiedOrderV6Request data) async {
    /// This is the request body for unifiedOrderV6 (GRABV3)
    var dataRequest = json.encode({
      "mcptid": data.mcptid,
      "referenceNo": data.referenceNo,
      "statusUrl": ApiConstants.STATUS_URL,
      "eType": data.eType,
      "description": data.description,
      "currency": data.currency,
      "formattedAmount": data.totalAmount,
      "customerEmailAddress": "no-reply@oxpayfinancial.com",
      "customerGivenName": "unknown",
      "customerSurName": "unknown"
    });

    LogUtils.debugLog('unifiedOrderV6::: $dataRequest');

    return post(
      path,
      dataRequest,
    );
  }

  Future<Response> unifiedOrderV6Limo(
      String path, UnifiedOrderV6Request data) async {
    var dataRequest = json.encode(
      {
        "salesAmount": data.salesAmount,
        "serviceAmount": data.serviceAmount,
        "serviceRate": data.serviceRate,
        "mcptid": data.mcptid,
        "currency": data.currency,
        "amountSettled": data.totalAmount,
        "formattedAmount": data.totalAmount,
        "referenceNo": data.referenceNo,
        "statusUrl": ApiConstants.STATUS_URL,
        "returnUrl": ApiConstants.RETURN_URL,
        "eType": data.eType,
        "description": data.description,
        "customerEmailAddress": "no-reply@oxpayfinancial.com",
        "customerGivenName": "unknown",
        "customerSurName": "unknown",
        "buyerPhone": "65468468651321",
        "billingAddress": "unknown",
        "billingAddress2": "unknown",
        "billingAddress3": "unknown",
        "reqKey": data.reqKey,
      },
    );

    LogUtils.debugLog('unifiedOrderV6Limo::: $dataRequest');

    return post(
      path,
      dataRequest,
    );
  }

  Future<Response> unifiedOrder(
    String path,
    UnifiedOrderRequest data,
  ) async {
    var jsonRequest = json.encode(
      {
        "data": {
          "amountInCNY": "0", // default is 0
          "amountSettled": data.totalAmount,
          "currency": data.currency,
          "currencySettled": data.currency,
          "description": data.description,
          "eType": data.eType,
          "totalAmount": data.totalAmount,
          "referenceNo": data.referenceNo,
          "statusUrl": data.statusUrl,
        },
        "header": {
          "appType": appType,
          "appVersion": appVersion,
          "version": version,
          ConstantsO7Lite.MCP_TERMINAL_ID: SharedPrefManager.terminalID,
          ConstantsO7Lite.SIGNATURE:
              await SecureSharedPreferences.instance.signature(),
        }
      },
    );
    LogUtils.debugLog('unifiedOrder::: $jsonRequest');

    return post(
      path,
      jsonRequest,
    );
  }

  Future<Response> unifiedOrderLimo(
    String path,
    UnifiedOrderRequest data,
  ) async {
    var jsonRequest = json.encode(
      {
        "data": {
          "salesAmount": data.salesAmount,
          "serviceAmount": data.serviceAmount,
          "serviceRate": data.serviceRate,
          "amountInCNY": "0", // default is 0
          "amountSettled": data.totalAmount,
          "currency": data.currency,
          "currencySettled": data.currency,
          "description": data.description,
          "eType": data.eType,
          "totalAmount": data.totalAmount,
          "referenceNo": data.referenceNo,
          "statusUrl": data.statusUrl,
        },
        "header": {
          "appType": appType,
          "appVersion": appVersion,
          "version": version,
          ConstantsO7Lite.MCP_TERMINAL_ID: SharedPrefManager.terminalID,
          ConstantsO7Lite.SIGNATURE:
              await SecureSharedPreferences.instance.signature(),
        }
      },
    );
    LogUtils.debugLog('unifiedOrderLimo::: $jsonRequest');

    return post(
      path,
      jsonRequest,
    );
  }

  Future<Response> ewalletVoid(
    String path,
    EwalletVoidRequest data,
  ) async {
    var dataRequest = json.encode(
      {
        "data": {
          "tradeNo": data.tradeNo,
          "eType": data.eType,
          "currency": data.currencySelected,
        },
        "header": {
          "appType": appType,
          "appVersion": appVersion,
          "version": version,
          ConstantsO7Lite.MCP_TERMINAL_ID: SharedPrefManager.terminalID,
          ConstantsO7Lite.SIGNATURE:
              await SecureSharedPreferences.instance.signature(),
        }
      },
    );
    LogUtils.debugLog('ewalletVoid::: $dataRequest');

    return post(
      path,
      dataRequest,
    );
  }

  Future<Response> cancelQRCodeV6(
    String path,
    CancelQrCodeV6Request data,
  ) async {
    return post(
      path,
      json.encode(
        {
          "data": {
            "mcptid": data.mcptid,
            "currency": data.currency,
            "eType": data.eType,
            "transactionId": data.transactionId,
          },
          "header": {
            "appType": appType,
            "appVersion": appVersion,
            "version": version,
            ConstantsO7Lite.MCP_TERMINAL_ID: SharedPrefManager.terminalID,
            ConstantsO7Lite.SIGNATURE:
                await SecureSharedPreferences.instance.signature(),
          }
        },
      ),
    );
  }

  Future<Response> querryTransactionList(
    String path,
    QuerryTransactionListRequest data,
  ) async {
    var dataRequest = json.encode(
      {
        "data": {
          "currentPage": data.page,
          "endDate": data.endDate,
          "filter": "",
          "startDate": data.startDate
        },
        "header": {
          "appType": appType,
          "appVersion": appVersion,
          "version": version,
          ConstantsO7Lite.MCP_TERMINAL_ID: SharedPrefManager.terminalID,
          ConstantsO7Lite.SIGNATURE:
              await SecureSharedPreferences.instance.signature(),
        }
      },
    );

    LogUtils.debugLog(dataRequest);

    return post(
      path,
      dataRequest,
    );
  }

  Future<Response> querryReceiptInfor(
    String path,
    QuerryReceiptInforRequest data,
  ) async {
    var jsonRequest = json.encode(
      {
        "data": {
          "filter": "",
          "queryType": "V",
          "transactionId": data.transactionId
        },
        "header": {
          "appType": appType,
          "appVersion": appVersion,
          "version": version,
          ConstantsO7Lite.MCP_TERMINAL_ID: SharedPrefManager.terminalID,
          ConstantsO7Lite.SIGNATURE:
              await SecureSharedPreferences.instance.signature(),
        }
      },
    );

    return post(
      path,
      jsonRequest,
    );
  }

  Future<Response> creditCardVoid(
    String path,
    CreditCardVoidRequest data,
  ) async {
    var dataRequest = json.encode(
      {
        "data": {
          "originalTransactionId": data.originalId,
          "currency": data.currency,
          "totalAmount": data.totalAmount,
        },
        "header": {
          "appType": appType,
          "appVersion": appVersion,
          "version": version,
          ConstantsO7Lite.MCP_TERMINAL_ID: SharedPrefManager.terminalID,
          ConstantsO7Lite.SIGNATURE:
              await SecureSharedPreferences.instance.signature(),
        }
      },
    );

    LogUtils.debugLog('creditCardVoid::: $dataRequest');

    return post(
      path,
      dataRequest,
    );
  }

  Future<Response> refundShopee(
    String path,
    RefundShopeeRequest data,
  ) async {
    var dataRequest = json.encode(
      {
        "data": {
          "originalTransactionId": data.originalTransactionId,
          "currency": data.currency,
          "totalAmount": data.totalAmount,
        },
        "header": {
          "appType": appType,
          "appVersion": appVersion,
          "version": version,
          ConstantsO7Lite.MCP_TERMINAL_ID: SharedPrefManager.terminalID,
          ConstantsO7Lite.SIGNATURE:
              await SecureSharedPreferences.instance.signature(),
        }
      },
    );
    LogUtils.debugLog('refundShopee::: $dataRequest');

    return post(
      path,
      dataRequest,
    );
  }

  Future<Response> refundTransaction(
    String path,
    RefundTransactionRequest data,
  ) async {
    var dataRequest = json.encode(
      {
        "data": {
          "currency": data.currency,
          "eType": data.eType,
          "tradeNo": data.tradeNo,
          "totalAmount": data.totalAmount,
        },
        "header": {
          "appType": appType,
          "appVersion": appVersion,
          "version": version,
          ConstantsO7Lite.MCP_TERMINAL_ID: SharedPrefManager.terminalID,
          ConstantsO7Lite.SIGNATURE:
              await SecureSharedPreferences.instance.signature(),
        }
      },
    );
    LogUtils.debugLog('refundTransaction::: $dataRequest');

    return post(
      path,
      dataRequest,
    );
  }

  Future<Response> getTransacionSummaryAFG(
    String path,
    GetTransacionSummaryAFGRequest data,
  ) async {
    var mcpTerminalId = SharedPrefManager.terminalID;
    var signature = await SecureSharedPreferences.instance.signature();

    var dataRequest = json.encode(
      {
        "data": {
          "acquirer": data.acquirer,
          "currency": data.currency,
          "endDate": data.endDate,
          "mcpTerminalId": mcpTerminalId,
          "order": "true", // default is true
          "startDate": data.startDate
        },
        "header": {
          "appType": appType,
          "appVersion": appVersion,
          "version": version,
          "mcpTerminalId": mcpTerminalId,
          "signature": signature,
        }
      },
    );

    LogUtils.debugLog('getTransacionSummaryAFG::: $dataRequest');

    return post(
      path,
      dataRequest,
    );
  }

  Future<Response> voidQueryDetail(
    String path,
    QueryDetailRequest data,
  ) async {
    var dataRequest = json.encode(
      {
        "data": {
          "filter": "",
          "queryType": "V",
          "transactionId": data.transactionId,
        },
        "header": {
          "appType": appType,
          "appVersion": appVersion,
          "version": version,
          ConstantsO7Lite.MCP_TERMINAL_ID: SharedPrefManager.terminalID,
          ConstantsO7Lite.SIGNATURE:
              await SecureSharedPreferences.instance.signature(),
        }
      },
    );
    LogUtils.debugLog('voidQueryDetail::: $dataRequest');

    return post(
      path,
      dataRequest,
    );
  }

  Future<Response> getDonationTerminalDetail(
    String path,
    DonationTerminalDetailRequest data,
  ) async {
    return post(
      path,
      json.encode(
        {
          "data": {
            "mcpTerminalId": data.mcpTerminalId,
          },
          "header": {
            "appType": appType,
            "appVersion": appVersion,
            "version": version,
            ConstantsO7Lite.MCP_TERMINAL_ID: SharedPrefManager.terminalID,
            ConstantsO7Lite.SIGNATURE:
                await SecureSharedPreferences.instance.signature(),
          }
        },
      ),
    );
  }

  Future<bool> sendEmailReceipt(
    String path,
    SendEmailRequest sendEmailRequest,
  ) async {
    if (StorageService.isGw3) {
      var fullPath = ApiConstants.BASE_API_URL_GW3 + '/terminal/email';

      Map<String, String> headers = {
        'Content-Type': 'multipart/form-data',
        'appType': appType,
        'appVersion': appVersion,
        'version': version,
        // Note: Email endpoint doesn't require Authorization header
      };

      // Create a multipart request
      var request = http.MultipartRequest('POST', Uri.parse(fullPath));

      // Add headers
      request.headers.addAll(headers);

      // Add fields
      request.fields['to'] = sendEmailRequest.emailTo;
      if (sendEmailRequest.emailCc != null) {
        request.fields['cc'] = sendEmailRequest.emailCc!;
      }
      request.fields['oxpay_txn_id'] = sendEmailRequest.transactionId;
      request.fields['transaction_state'] = sendEmailRequest.paymentStatus;
      request.fields['transaction_datetime'] = sendEmailRequest.paymentDate;
      request.fields['payment_method'] = sendEmailRequest.paymentMethod;
      request.fields['transaction_amount'] = sendEmailRequest.paymentAmount;
      request.fields['transaction_currency'] = sendEmailRequest.paymentCurrency;
      request.fields['transaction_type'] = sendEmailRequest.transactionType;

      // Add file
      var currentDateTime = DateTime.now();
      // get date time in format of yyyy-MM-dd-HH-mm-ss
      var formattedDateTime = currentDateTime.toString().split('.').first;
      var random = Random().nextInt(1000);
      var fileName = 'invoice-$formattedDateTime-$random.pdf';
      request.files.add(
        await http.MultipartFile.fromPath(
          'invoice',
          sendEmailRequest.invoiceFilePath,
          filename: fileName,
        ),
      );

      // print request
      LogUtils.debugLog(
          '@@@ GW3 sendEmailReceipt::: ${json.encode(sendEmailRequest)}');

      // Send request
      var response = await request.send();

      return response.statusCode == 200;
    } else {
      var fullPath = ApiConstants.BASE_API_URL + path;
      // Create a multipart request

      var request = http.MultipartRequest('POST', Uri.parse(fullPath));

      // Add headers
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'appType': appType,
        'appVersion': appVersion,
        'version': version
      });

      // Add fields
      request.fields['to'] = sendEmailRequest.emailTo;
      if (sendEmailRequest.emailCc != null) {
        request.fields['cc'] = sendEmailRequest.emailCc!;
      }
      request.fields['mcpTerminalId'] = sendEmailRequest.mcpTerminalId;
      request.fields['transactionId'] = sendEmailRequest.transactionId;
      request.fields['paymentStatus'] = sendEmailRequest.paymentStatus;
      request.fields['paymentDate'] = sendEmailRequest.paymentDate;
      request.fields['paymentMethod'] = sendEmailRequest.paymentMethod;
      request.fields['paymentAmount'] = sendEmailRequest.paymentAmount;
      request.fields['paymentCurrency'] = sendEmailRequest.paymentCurrency;
      request.fields['merchantName'] = sendEmailRequest.merchantName;
      request.fields['transactionType'] = sendEmailRequest.transactionType;

      var currentDateTime = DateTime.now();
      // get date time in format of yyyy-MM-dd-HH-mm-ss
      var formattedDateTime = currentDateTime.toString().split('.').first;
      var random = Random().nextInt(1000);
      var fileName = 'invoice-$formattedDateTime-$random.pdf';
      request.files.add(
        await http.MultipartFile.fromPath(
          'invoiceFile',
          sendEmailRequest.invoiceFilePath,
          filename: fileName,
        ),
      );

      // print request
      LogUtils.debugLog("email request::: $request");

      // Send request
      var response = await request.send();

      return response.statusCode == 200;
    }
  }

  // Get TerminalDetail by MCP Terminal ID
  Future<Response> getTerminalDetail(String path, String mcpTerminalId) async {
    return await _callWithTokenRefresh(() async {
      var fullPath = path + mcpTerminalId;

      var accessToken =
          await SecureSharedPreferences.instance.getAccessToken() ?? '';
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'appType': appType,
        'appVersion': appVersion,
        'version': version,
        'Authorization': 'Bearer $accessToken',
      };

      return get(fullPath, headers: headers);
    });
  }

  // Sale request
  Future<Response> saleRequest(PaymentMethod paymentMethod, Amount amount,
      {String? description}) async {
    return await _callWithTokenRefresh(() async {
      var accessToken =
          await SecureSharedPreferences.instance.getAccessToken() ?? '';
      // merchantID
      TerminalDetail? terminalDetail =
          await SharedPrefManager.instance.getTerminalDetail();
      String merchantId = terminalDetail?.merchant.merchantId ?? '';
      String terminalId = terminalDetail?.terminalId ?? '';

      // merchantReferenceId is a unique id for each transaction (in this case, we use timestamp)
      String merchantReferenceId =
          DateTime.now().millisecondsSinceEpoch.toString();

      PaymentRequest paymentRequest = PaymentRequest(
        merchantId: merchantId,
        terminalId: terminalId,
        merchantReferenceId: merchantReferenceId,
        successUrl: ApiConstants.SUCCESS_URL,
        failureUrl: ApiConstants.FAILURE_URL,
        notificationUrl: ApiConstants.NOTIFICATION_URL,
        paymentMethod: paymentMethod,
        amount: amount,
        description: description,
      );

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'appType': appType,
        'appVersion': appVersion,
        'version': version,
        'Authorization': 'Bearer $accessToken',
      };

      var bodyRequest = json.encode(paymentRequest);

      LogUtils.jsonLog(bodyRequest, name: 'SALE REQUEST');

      return post('/terminal/payment', bodyRequest, headers: headers);
    });
  }

  Future<Response> getTransactions(
      String startDay,
      String? endDate,
      String? transactionId,
      List<String>? brands,
      List<String>? states,
      String? page,
      int pageSize) async {
    return await _callWithTokenRefresh(() async {
      var accessToken =
          await SecureSharedPreferences.instance.getAccessToken() ?? '';

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'appType': appType,
        'appVersion': appVersion,
        'version': version,
        'Authorization': 'Bearer $accessToken',
      };

      // Only include non-empty parameters
      Map<String, dynamic> data = {
        "start_date": startDay,
        "page": page ?? '1',
        "page_size": pageSize.toString(),
      };

      if (endDate != null && endDate.isNotEmpty) {
        data["end_date"] = endDate;
      }
      if (transactionId != null && transactionId.isNotEmpty) {
        data["oxpay_txn_id"] = transactionId;
      }
      if (brands != null && brands.isNotEmpty) {
        data["brand"] = brands.join(',');
      }
      if (states != null && states.isNotEmpty) {
        data["transaction_state"] = states.join(',');
      }

      return get('/terminal/payment', headers: headers, query: data);
    });
  }

  Future<Response> getTransactionDetail(String txnId) async {
    return await _callWithTokenRefresh(() async {
      var accessToken =
          await SecureSharedPreferences.instance.getAccessToken() ?? '';

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'appType': appType,
        'appVersion': appVersion,
        'version': version,
        'Authorization': 'Bearer $accessToken',
      };

      return get('/terminal/payment/$txnId', headers: headers);
    });
  }

  // Void Transaction request of gw3
  Future<Response> voidTxn(String txnId, Amount amount) async {
    return await _callWithTokenRefresh(() async {
      var accessToken =
          await SecureSharedPreferences.instance.getAccessToken() ?? '';

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'appType': appType,
        'appVersion': appVersion,
        'version': version,
        'Authorization': 'Bearer $accessToken',
      };

      TerminalDetail? terminalDetail =
          await SharedPrefManager.instance.getTerminalDetail();

      RefundVoidRequest data = RefundVoidRequest(
        merchantId: terminalDetail?.merchant.merchantId ?? '',
        terminalId: terminalDetail?.terminalId ?? '',
        merchantReferenceId: DateTime.now().millisecondsSinceEpoch.toString(),
        oxpayOriginalTxnId: txnId,
        amount: amount,
      );

      LogUtils.debugLog('voidTxn::: ${json.encode(data)}');

      return post('/terminal/void', json.encode(data), headers: headers);
    });
  }

  // Refund Transaction request of gw3
  Future<Response> refundTxn(String txnId, Amount amount) async {
    return await _callWithTokenRefresh(() async {
      var accessToken =
          await SecureSharedPreferences.instance.getAccessToken() ?? '';

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'appType': appType,
        'appVersion': appVersion,
        'version': version,
        'Authorization': 'Bearer $accessToken',
      };

      TerminalDetail? terminalDetail =
          await SharedPrefManager.instance.getTerminalDetail();

      RefundVoidRequest data = RefundVoidRequest(
        merchantId: terminalDetail?.merchant.merchantId ?? '',
        terminalId: terminalDetail?.terminalId ?? '',
        merchantReferenceId: DateTime.now().millisecondsSinceEpoch.toString(),
        oxpayOriginalTxnId: txnId,
        amount: amount,
      );

      LogUtils.debugLog('refundTxn::: ${json.encode(data)}');

      return post('/terminal/refund', json.encode(data), headers: headers);
    });
  }

  /// Create payment hosted page [GW3]
  Future<Response> createPaymentHostedPage(Amount amount) async {
    return await _callWithTokenRefresh(() async {
      var accessToken =
          await SecureSharedPreferences.instance.getAccessToken() ?? '';
      // merchantID
      TerminalDetail? terminalDetail =
          await SharedPrefManager.instance.getTerminalDetail();
      String merchantId = terminalDetail?.merchant.merchantId ?? '';
      String terminalId = terminalDetail?.terminalId ?? '';

      // merchantReferenceId is a unique id for each transaction (in this case, we use timestamp)
      String merchantReferenceId =
          DateTime.now().millisecondsSinceEpoch.toString();

      PaymentRequest paymentRequest = PaymentRequest(
        merchantId: merchantId,
        terminalId: terminalId,
        merchantReferenceId: merchantReferenceId,
        successUrl: ApiConstants.SUCCESS_URL,
        failureUrl: ApiConstants.FAILURE_URL,
        notificationUrl: ApiConstants.NOTIFICATION_URL,
        amount: amount,
        capture: true,
      );

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'appType': appType,
        'appVersion': appVersion,
        'version': version,
        'Authorization': 'Bearer $accessToken',
      };

      var bodyRequest = json.encode(paymentRequest);

      LogUtils.jsonLog(bodyRequest, name: 'CREATE PAYMENT HOSTED PAGE');

      return post('/terminal/payment-page', bodyRequest, headers: headers);
    });
  }

  /**
   * curl --location --request POST 'https://api.dev.oxpayfinancial.com/terminal/txn-summary' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer <example-token>' \
--data-raw '{
    "payment-host": "Dci-Host",
    "currency": "SGD",
    "terminal_id": "10200099901",
    "order": true,
    "end_date": "2025-5-6",
    "start_date": "2025-5-5"
}'
   */
  Future<Response> txnSummaryReportGw3(String paymentHost, String currency,
      String startDate, String endDate) async {
    return await _callWithTokenRefresh(() async {
      var accessToken =
          await SecureSharedPreferences.instance.getAccessToken() ?? '';

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'appType': appType,
        'appVersion': appVersion,
        'version': version,
        'Authorization': 'Bearer $accessToken',
      };

      var data = {
        'payment_host': paymentHost,
        'currency': currency,
        'terminal_id': SharedPrefManager.terminalID,
        'order': true,
        'start_date': startDate,
        'end_date': startDate,
      };

      var bodyRequest = json.encode(data);

      LogUtils.debugLog('txnSummaryReportGw3::: $bodyRequest');

      return post('/terminal/txn-summary', bodyRequest, headers: headers);
    });
  }
}
