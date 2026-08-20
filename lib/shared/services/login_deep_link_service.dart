import 'package:app/modules/auth/auth_controller.dart';
import 'package:app/routes/app_pages.dart';
import 'package:app/shared/secure_shared_preferences/secure_shared_preferences.dart';
import 'package:app/shared/utils/log_utils.dart';
import 'package:app/shared/utils/jwt_utils.dart';
import 'package:app/shared/widgets/custom_dialog/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class LoginDeepLinkCredentials {
  const LoginDeepLinkCredentials({
    required this.operatorId,
    required this.password,
  });

  final String operatorId;
  final String password;

  static LoginDeepLinkCredentials? fromPlatformMap(dynamic value) {
    if (value is! Map) return null;

    final operatorId = value['operatorId']?.toString().trim();
    final password = value['pswd']?.toString().trim();

    if (operatorId == null || operatorId.isEmpty) return null;
    if (password == null || password.isEmpty) return null;

    return LoginDeepLinkCredentials(
      operatorId: operatorId,
      password: password,
    );
  }
}

class LoginDeepLinkGuard {
  const LoginDeepLinkGuard._();

  static bool shouldIgnore({
    required LoginDeepLinkCredentials credentials,
    LoginDeepLinkCredentials? submittingCredentials,
    String? accessToken,
  }) {
    if (_sameCredentials(credentials, submittingCredentials)) {
      return true;
    }

    if (accessToken == null ||
        accessToken.isEmpty ||
        !JwtUtils.isTokenValid(accessToken)) {
      return false;
    }

    final payload = JwtUtils.decodeToken(accessToken);
    final activeOperatorId =
        (payload?['operator_id'] ?? payload?['sub'])?.toString().trim();
    if (activeOperatorId == null || activeOperatorId.isEmpty) {
      return false;
    }

    return activeOperatorId.toLowerCase() ==
        credentials.operatorId.toLowerCase();
  }

  static bool _sameCredentials(
    LoginDeepLinkCredentials credentials,
    LoginDeepLinkCredentials? other,
  ) {
    return other != null &&
        credentials.operatorId.toLowerCase() ==
            other.operatorId.toLowerCase() &&
        credentials.password == other.password;
  }
}

class LoginDeepLinkError {
  const LoginDeepLinkError({
    required this.missingOperatorId,
    required this.missingPassword,
  });

  final bool missingOperatorId;
  final bool missingPassword;

  String get message {
    // if (missingOperatorId && missingPassword) {
    //   return 'The login link is missing the Operator ID and password. Please try again from OxPay.';
    // }
    // if (missingOperatorId) {
    //   return 'The login link is missing the Operator ID. Please try again from OxPay.';
    // }
    // if (missingPassword) {
    //   return 'The login link is missing the password. Please try again from OxPay.';
    // }
    // return 'The login link is invalid. Please try again from OxPay.';
    return 'We couldn\'t verify your login details. Please double-check and try again.';
  }

  static LoginDeepLinkError? fromPlatformMap(dynamic value) {
    if (value is! Map) return null;

    final missingOperatorId = value['missingOperatorId'] == true;
    final missingPassword = value['missingPassword'] == true;

    if (!missingOperatorId && !missingPassword) return null;

    return LoginDeepLinkError(
      missingOperatorId: missingOperatorId,
      missingPassword: missingPassword,
    );
  }
}

class LoginDeepLinkService extends GetxService {
  static const MethodChannel _channel =
      MethodChannel('com.o7lite3.app/login_deep_link');

  LoginDeepLinkCredentials? _pendingCredentials;
  LoginDeepLinkCredentials? _submittingCredentials;
  LoginDeepLinkError? _pendingError;
  bool _initialized = false;
  bool _isSubmitting = false;

  bool get hasPendingCredentials => _pendingCredentials != null;
  bool get hasPendingError => _pendingError != null;

  Future<LoginDeepLinkService> init() async {
    if (_initialized) return this;
    _initialized = true;

    _channel.setMethodCallHandler(_handleNativeCall);
    await _loadInitialCredentials();
    return this;
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method != 'onLoginDeepLink') return null;

    await _handlePayload(call.arguments, shouldNavigate: true);
    return null;
  }

  Future<void> _handlePayload(
    dynamic payload, {
    required bool shouldNavigate,
  }) async {
    final credentials = LoginDeepLinkCredentials.fromPlatformMap(payload);
    if (credentials == null) {
      final error = LoginDeepLinkError.fromPlatformMap(payload);
      if (error != null) {
        _pendingError = error;
        LogUtils.debugLog(
            '[LoginDeepLink] Invalid credential deep link received');
        if (shouldNavigate) {
          Get.offAllNamed(Routes.LOG_IN);
        }
      } else {
        LogUtils.debugLog('[LoginDeepLink] Ignored invalid credential payload');
      }
      return;
    }

    if (_isDuplicateOfPendingOrSubmitting(credentials)) {
      LogUtils.debugLog(
          '[LoginDeepLink] Ignored duplicate credential deep link');
      return;
    }

    String? accessToken;
    try {
      accessToken = await SecureSharedPreferences.instance.getAccessToken();
    } catch (e) {
      LogUtils.debugLog('[LoginDeepLink] Could not inspect active session: $e');
    }

    // Another payload may have been accepted while secure storage was read.
    if (_isDuplicateOfPendingOrSubmitting(credentials)) {
      LogUtils.debugLog(
          '[LoginDeepLink] Ignored duplicate credential deep link');
      return;
    }

    if (LoginDeepLinkGuard.shouldIgnore(
      credentials: credentials,
      accessToken: accessToken,
    )) {
      LogUtils.debugLog(
          '[LoginDeepLink] Ignored credentials for active operator session');
      return;
    }

    _pendingCredentials = credentials;
    LogUtils.debugLog('[LoginDeepLink] Credential deep link received');

    if (shouldNavigate) {
      Get.offAllNamed(Routes.LOG_IN);
    }
  }

  Future<void> _loadInitialCredentials() async {
    try {
      final payload = await _channel.invokeMethod('getInitialLoginCredentials');
      await _handlePayload(payload, shouldNavigate: false);
    } on MissingPluginException {
      // Non-Android/test environments have no native login deep-link channel.
    } catch (e) {
      LogUtils.debugLog(
          '[LoginDeepLink] Failed to load initial credentials: $e');
    }
  }

  Future<bool> submitPendingCredentials(
    AuthController authController,
    BuildContext context,
  ) async {
    if (_isSubmitting || _pendingCredentials == null) return false;

    final credentials = _pendingCredentials!;
    _pendingCredentials = null;
    _isSubmitting = true;
    _submittingCredentials = credentials;

    try {
      authController.loginTIDController.text = credentials.operatorId;
      authController.loginPasswordController.text = credentials.password;
      authController.isRememberTidChecked.value = true;

      await SecureSharedPreferences.instance.setRememberTid(true);
      await SecureSharedPreferences.instance
          .setOperatorId(credentials.operatorId);

      await authController.login(context);
      return true;
    } finally {
      _isSubmitting = false;
      _submittingCredentials = null;
    }
  }

  bool _isDuplicateOfPendingOrSubmitting(
    LoginDeepLinkCredentials credentials,
  ) {
    return LoginDeepLinkGuard.shouldIgnore(
          credentials: credentials,
          submittingCredentials: _pendingCredentials,
        ) ||
        LoginDeepLinkGuard.shouldIgnore(
          credentials: credentials,
          submittingCredentials: _submittingCredentials,
        );
  }

  void showPendingErrorIfAny() {
    final error = _pendingError;
    if (error == null) return;

    _pendingError = null;
    CustomDialog.showMaterial(
      Get.context,
      error.message,
    );
  }
}
