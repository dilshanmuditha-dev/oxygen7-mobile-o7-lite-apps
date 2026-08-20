// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/request/request.dart';

import '../../modules/auth/auth_controller.dart';
import '../../routes/app_pages.dart';
import '../../shared/secure_shared_preferences/secure_shared_preferences.dart';
import '../../shared/secure_shared_preferences/sharepreference.dart';
import '../../shared/services/storage_service.dart';
import '../../shared/utils/log_utils.dart';

/// Global HTTP response interceptor for the O7Lite application
///
/// This interceptor handles all HTTP responses and performs global error handling.
/// For the refresh token flow, it specifically handles 401 responses for non-GW3 requests.
///
/// GW3 vs GW2 Handling:
/// - GW3 (OxPay): 401 responses are handled at the API provider level with automatic token refresh
/// - GW2 (MCPayment): 401 responses are handled here by clearing tokens and redirecting to login
FutureOr<dynamic> responseInterceptor(
  Request request,
  Response response,
) async {
  if (kDebugMode) {
    debugPrint('REQUEST::: ${request.method.toUpperCase()} ${request.url}');
    debugPrint(
        'RESPONSE::: ${response.statusCode} ${response.statusText ?? ''}');
    // Pretty-print the body as indented JSON so it is readable and not
    // truncated; headers are logged too in case a detail is delivered outside
    // the JSON body.
    LogUtils.jsonLog(response.headers, name: 'RESPONSE HEADERS');
    LogUtils.jsonLog(response.bodyString, name: 'RESPONSE BODY');
  }

  // Don't auto-dismiss loading for login endpoints - let the controller handle it
  // This allows smooth transition from login to home screen with loading visible
  final isLoginRequest = request.url.path.contains('/auth/');
  if (!isLoginRequest) {
    await EasyLoading.dismiss();
  }

  handleResponseStatus(response, request);
  return response;
}

/// Clears all stored authentication tokens and redirects user to login screen
///
/// This is called when:
/// - Non-GW3 requests receive 401 Unauthorized responses
/// - GW3 refresh token has also expired (fallback scenario)
///
/// Actions performed:
/// 1. Clear access token from SecureSharedPreferences
/// 2. Clear refresh token from SharedPrefManager
/// 3. Navigate to login screen
/// 4. Show session expired toast message
Future<void> _clearTokensAndRedirectToLogin() async {
  await SecureSharedPreferences.instance.setAccessToken('');
  await SharedPrefManager.setRefreshTokenSecure('');
  Get.delete<AuthController>(force: true);
  Get.offAllNamed(Routes.LOG_IN, arguments: {'isLogout': true});
  Fluttertoast.showToast(
    msg: 'Session expired. Please login again.',
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.CENTER,
    timeInSecForIosWeb: 1,
  );
}

/// Handles HTTP response status codes and performs appropriate actions
///
/// Token Refresh Strategy:
/// - GW3 requests: 401 handling is delegated to API provider level (_callWithTokenRefresh)
/// - Non-GW3 requests: 401 responses trigger immediate token cleanup and login redirect
///
/// This separation ensures that:
/// 1. GW3 requests benefit from automatic token refresh and retry
/// 2. Non-GW3 requests follow traditional authentication failure handling
/// 3. No conflicts between different refresh mechanisms
///
/// Parameters:
/// - response: HTTP response object
/// - request: HTTP request object (for context/debugging)
void handleResponseStatus(
  Response response,
  Request request,
) async {
  final finalValue = jsonDecode(response.bodyString!);
  switch (response.statusCode) {
    case 200:
      return;

    // case 400: // Bad Request
    case 401: // Unauthorized
      // Only handle 401 for non-GW3 requests, as GW3 requests are handled at the API provider level
      if (!StorageService.isGw3) {
        await _clearTokensAndRedirectToLogin();
      }
      // For GW3, the token refresh and retry is handled in the API provider level
      break;

    default:
      break;
  }
  return;
}
