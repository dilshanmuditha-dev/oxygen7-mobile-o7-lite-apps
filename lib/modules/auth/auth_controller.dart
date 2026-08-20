// ignore_for_file: deprecated_member_use, unused_local_variable, avoid_print, unrelated_type_equality_checks, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/api/api_provider.dart';
import 'package:app/models/request/auth_request/login_request/login_request_gw3.dart';
import 'package:app/models/response/login_response/login_response.dart';
import 'package:app/models/response/login_response/user_login_model/address_model.dart';
import 'package:app/shared/constants/common.dart';
import 'package:app/shared/constants/constants_o7lite.dart';
import 'package:app/shared/secure_shared_preferences/secure_shared_preferences.dart';
import 'package:app/shared/utils/app_flavor_helper.dart';
import 'package:app/shared/utils/invoke.dart';
import 'package:app/shared/utils/network_utils.dart';
import 'package:app/shared/secure_shared_preferences/sharepreference.dart';
import 'package:app/lang/translation_service.dart';
import 'package:app/shared/widgets/custom_dialog/custom_dialog.dart';
import 'package:app/shared/widgets/dialog_common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../api/api_repository.dart';
import '../../models/request/auth_request/login_request/login_request.dart';
import '../../routes/app_pages.dart';
import '../../shared/services/storage_service.dart';
import '../../shared/utils/focus.dart';
import '../../shared/utils/regex.dart';
import '../../shared/utils/jwt_utils.dart';
import 'package:app/shared/utils/log_utils.dart';

class AuthController extends GetxController {
  // Constants
  static const String _loadingMessage = 'Logging in...';

  // Dependencies
  final ApiRepository apiRepository;
  final ApiProvider apiProvider = Get.find();

  AuthController({required this.apiRepository});

  // UI State Management
  final Rx<bool> validate = false.obs;
  final RxBool isPasswordVisible = true.obs;

  /// True when the user was redirected here because developer mode was detected
  /// while their session was active. Used to show a security warning banner.
  final RxBool isSecurityLogout = false.obs;
  final RxBool isEmailEntered = false.obs;
  final RxBool isEmail = false.obs;
  final RxBool isPhoneNumber = false.obs;
  final RxBool isRememberTidChecked = false.obs;
  final RxBool rememberPassword = false.obs;
  final RxBool isCheckAnimation = false.obs;

  // Language and Localization
  final RxString selectedApp = '🇺🇸  English'.obs;
  final RxString language = '🇺🇸'.obs;

  final List<String> listApps = [
    '🇺🇸  English',
    '🇨🇳  简体中文',
    '🇮🇳  हिन्दी',
    '🇪🇸  Español',
    '🇫🇷  Français',
    '🇸🇦  العربية',
    '🇧🇩  বাংলা',
    '🇷🇺  Русский',
    '🇵🇹  Português',
    '🇵🇰  اردو',
    '🇹🇭  ไทย',
    '🇲🇾  Bahasa Melayu',
    '🇰🇷  한국어',
    '🇻🇳  Tiếng Việt',
    '🇯🇵  日本語',
  ];

  final List<String> listSetLocate = [
    'en',
    'cn',
    'hi',
    'es',
    'fr',
    'ar',
    'bn',
    'ru',
    'pt',
    'ur',
    'th',
    'ms',
    'ko',
    'vi',
    'ja',
  ];

  // Form Controllers
  final loginTIDController = TextEditingController();
  final loginPasswordController = TextEditingController();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode tidFocus = FocusNode();

  // Rate Limiting State (Requirement 9)
  int _failedAttempts = 0;
  DateTime? _cooldownUntil;
  Timer? _cooldownTimer;
  final RxInt cooldownSeconds = 0.obs;

  /// Whether login is currently blocked due to rate limiting cooldown
  bool get isLoginBlocked =>
      _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);

  // Internal State
  int? type;

  @override
  Future<void> onInit() async {
    await _initializeController();
    super.onInit();
  }

  @override
  void onClose() {
    _disposeResources();
    super.onClose();
  }

  /// Initialize controller with necessary data and handle arguments
  Future<void> _initializeController() async {
    final bool isLogout = Get.arguments?["isLogout"] ?? false;
    final bool securityLogoutArg = Get.arguments?["securityLogout"] ?? false;
    if (securityLogoutArg) {
      isSecurityLogout.value = true;
    }

    if (kDebugMode) {
      print('[RememberTID] _initializeController START | isLogout=$isLogout');
    }

    if (isLogout) {
      // Clear password field always on logout
      loginPasswordController.clear();

      // Check if remember TID is enabled BEFORE loading data
      final bool shouldRememberTid =
          await SecureSharedPreferences.instance.getRememberTid() ?? false;
      final String? savedTid = await SecureSharedPreferences.instance.getTID();

      if (kDebugMode) {
        print(
            '[RememberTID] After logout → rememberTid=$shouldRememberTid, savedTid=$savedTid');
      }

      if (shouldRememberTid) {
        // Load saved operatorId (username login) or TID for textfield restore
        final String? savedOperatorId =
            await SecureSharedPreferences.instance.getOperatorId();
        if (savedOperatorId != null && savedOperatorId.isNotEmpty) {
          loginTIDController.text = savedOperatorId;
          if (kDebugMode) {
            print(
                '[RememberTID] Restored operatorId to field: "$savedOperatorId"');
          }
        } else {
          loginTIDController.text = savedTid ?? '';
          if (kDebugMode) {
            print(
                '[RememberTID] Restored TID to field: "${loginTIDController.text}"');
          }
        }
      } else {
        // Clear TID if remember is not checked
        loginTIDController.clear();
        if (kDebugMode) {
          print('[RememberTID] rememberTid=false → cleared TID field');
        }
      }

      // Update checkbox state
      isRememberTidChecked.value = shouldRememberTid;

      // Load language preferences
      language.value =
          await SharedPrefManager.instance.getString('saveLanguage') ?? '🇺🇸';
      selectedApp.value = _getLanguageDisplayName(language.value);

      // Restore saved locale so the login screen uses the user's chosen language
      final savedLangCode =
          await SharedPrefManager.instance.getChangeLanguage();
      if (savedLangCode != null && savedLangCode != 'en_US') {
        TranslationService.changeLocale(savedLangCode);
      }
    } else {
      // Normal initialization (not from logout)
      await getDataLocal();
    }

    _handleResetCredentialParameter();
  }

  /// Handle reset credential parameter from navigation
  void _handleResetCredentialParameter() {
    final String? needToResetCredential =
        Get.parameters["needToResetCredential"];
    if (needToResetCredential == 'true') {
      CustomDialog.showMaterial(
        Get.context,
        'Authentication failed. Please check your credentials and try again.',
        btnText: CommonConstants.ok.tr.toUpperCase(),
      );
    }
  }

  /// Dispose of resources to prevent memory leaks
  void _disposeResources() {
    _cooldownTimer?.cancel();
    loginTIDController.dispose();
    loginPasswordController.dispose();
    passwordFocus.dispose();
    tidFocus.dispose();
  }

  /// Main login method - orchestrates the login process with fallback mechanism
  Future<void> login(BuildContext context) async {
    AppFocus.unfocus(context);

    // Rate limiting: block login if cooldown is active (Requirement 9.2, 9.3)
    if (isLoginBlocked) {
      return;
    }

    if (!await _validateLoginPreconditions(context)) {
      return;
    }

    await _showLoadingIndicator();

    try {
      // First attempt: Try with production environment
      if (await _attemptLoginWithEnvironment(AppFlavor.production)) {
        await _handleLoginSuccess();
        return;
      }

      // Second attempt: Try with productionGW3 environment
      if (await _attemptLoginWithEnvironment(AppFlavor.productionGW3)) {
        await _handleLoginSuccess();
        return;
      }

      // Both attempts failed
      await _handleLoginFailure();
    } catch (error) {
      await _handleLoginError(error);
    }
  }

  /// Validate preconditions before attempting login
  Future<bool> _validateLoginPreconditions(BuildContext context) async {
    if (!await NetworkUtils.hasConnection(context)) {
      return false;
    }
    return true;
  }

  /// Show loading indicator for login process
  Future<void> _showLoadingIndicator() async {
    await EasyLoading.show(status: _loadingMessage);
  }

  /// Attempt login with specific environment flavor
  Future<bool> _attemptLoginWithEnvironment(AppFlavor flavor) async {
    try {
      // Set the environment
      apiProvider.updateEnvironment(flavor);

      // Determine which login method to use based on environment
      if (flavor == AppFlavor.productionGW3 ||
          flavor == AppFlavor.developmentGW3) {
        return await _performGW3Login();
      } else {
        return await _performGW2Login();
      }
    } catch (error) {
      LogUtils.debugLog('Login attempt failed with $flavor: $error');
      return false;
    }
  }

  /// Perform GW3 login
  Future<bool> _performGW3Login() async {
    final response = await apiRepository.loginGw3(
      LoginRequestGw3(
        operatorName: loginTIDController.text,
        operatorPassword: loginPasswordController.text,
      ),
    );

    if (response.access_token != null) {
      return await _handleGW3LoginSuccess(response);
    }

    return false;
  }

  /// Handle successful GW3 login.
  /// Returns `false` if credential storage fails (e.g. hashing error).
  Future<bool> _handleGW3LoginSuccess(dynamic response) async {
    StorageService.isGw3 = true;

    final bool saved = await _saveGW3Credentials(response);
    if (!saved) {
      return false;
    }

    await _processTokenPayload(response.access_token);

    if (kDebugMode) {
      print('loginResponse: ${JsonEncoder().convert(response)}');
    }
    return true;
  }

  /// Save GW3 credentials to secure storage.
  Future<bool> _saveGW3Credentials(dynamic response) async {
    if (kDebugMode) {
      print(
          '[RememberTID] _saveGW3Credentials → rememberTid=${isRememberTidChecked.value}, TID="${loginTIDController.text}"');
    }

    // Store GW3 password as plaintext in secure storage.
    // Unlike GW2 (which sends hashed passwords to the server), GW3 server
    // expects plaintext passwords for re-login/re-authentication.
    // flutter_secure_storage provides AES encryption at rest.
    await SecureSharedPreferences.instance
        .setPassword(loginPasswordController.text);
    await SecureSharedPreferences.instance
        .setRememberTid(isRememberTidChecked.value);
    await SecureSharedPreferences.instance
        .setAccessToken(response.access_token ?? '');
    await SharedPrefManager.setRefreshTokenSecure(response.refresh_token ?? '');
    return true;
  }

  /// Process JWT token payload
  Future<void> _processTokenPayload(String accessToken) async {
    final tokenPayload = JwtUtils.decodeToken(accessToken);
    if (tokenPayload != null) {
      if (kDebugMode) {
        print('Token payload: $tokenPayload');
      }
      final String tid = tokenPayload['sub'].toString();
      final String? operatorId = tokenPayload['operator_id']?.toString();

      // TID always uses sub for both storage and API
      SharedPrefManager.setTerminalID = tid;
      await SecureSharedPreferences.instance.setTID(tid);

      // Store operatorId separately when present (username login)
      if (operatorId != null && operatorId.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
              '[RememberTID] Login type: username (operator_id=$operatorId, sub=$tid)');
        }
        await SecureSharedPreferences.instance.setOperatorId(operatorId);
      } else {
        if (kDebugMode) {
          debugPrint('[RememberTID] Login type: TID (sub=$tid)');
        }
        await SecureSharedPreferences.instance.setOperatorId(null);
      }
    }
  }

  /// Perform GW2 login
  Future<bool> _performGW2Login() async {
    final String passwordEncrypt = encryptionHmacSHA512(
            loginPasswordController.text, BaseAppO7Lite.hmacKey) ??
        '';

    final response = await apiRepository.login(
      LoginRequest(
        username: loginTIDController.text,
        password: passwordEncrypt,
      ),
    );

    if (response != null) {
      await _handleGW2LoginSuccess(response, passwordEncrypt);
      return true;
    }

    return false;
  }

  /// Handle successful GW2 login
  Future<void> _handleGW2LoginSuccess(
      LoginResponse response, String passwordEncrypt) async {
    await setPreferences(response);
    await _configureDonationSettings(response);

    StorageService.isGw3 = false;
    await SecureSharedPreferences.instance.setPassword(passwordEncrypt);
  }

  /// Configure donation settings based on login response
  Future<void> _configureDonationSettings(LoginResponse response) async {
    final bool? loginType = response.isDonation;
    if (loginType == true) {
      BaseAppO7Lite.setLoginDonation(true);
      BaseAppO7Lite.setDonation(true);
    } else {
      BaseAppO7Lite.setLoginPayment(true);
      BaseAppO7Lite.setDonation(false);
    }
  }

  /// Handle successful login completion
  Future<void> _handleLoginSuccess() async {
    // Reset rate limiter on successful login (Requirement 9.4)
    _resetFailures();

    // Log state before clearing
    final rememberTidState = isRememberTidChecked.value;
    final tidFieldValue = loginTIDController.text;
    final storedRememberTid =
        await SecureSharedPreferences.instance.getRememberTid();
    final storedTid = await SecureSharedPreferences.instance.getTID();
    if (kDebugMode) {
      print(
          '[RememberTID] _handleLoginSuccess → rememberTidCheckbox=$rememberTidState, tidField="$tidFieldValue", storedRememberTid=$storedRememberTid, storedTID="$storedTid"');
    }

    // Clear password before navigation
    loginPasswordController.clear();

    // Navigate to home screen - this clears all previous routes
    // Keep loading visible during navigation for smooth UX
    Get.offAllNamed(Routes.HOME);

    // Dismiss loading after a short delay to ensure home screen is rendered
    // This prevents the login screen from showing without loading indicator
    Future.delayed(const Duration(milliseconds: 800), () {
      EasyLoading.dismiss();
    });
  }

  /// Handle login failure - both production and productionGW3 failed
  Future<void> _handleLoginFailure() async {
    // Record failed attempt for rate limiting (Requirement 9.1)
    _recordFailure();

    EasyLoading.dismiss();
    _showInvalidCredentialsDialog();
  }

  /// Handle login errors during the process
  Future<void> _handleLoginError(dynamic error) async {
    EasyLoading.dismiss();
    _showGenericErrorDialog();
    LogUtils.debugLog('Login error occurred: $error');
  }

  /// Show invalid credentials dialog
  void _showInvalidCredentialsDialog() {
    Get.dialog(
      CustomAlertDialog(
        title: CommonConstants.invalidUserNameOrPassword.tr,
        onPressed: () => Get.back(),
      ),
    );
  }

  /// Show generic error dialog
  void _showGenericErrorDialog() {
    Get.dialog(
      CustomAlertDialog(
        title: CommonConstants.someThingWrongPlsTryAgain,
        onPressed: () => Get.back(),
      ),
    );
  }

  /// Record a failed login attempt and activate cooldown at threshold (Requirement 9.1, 9.2)
  void _recordFailure() {
    _failedAttempts++;
    if (_failedAttempts >= 5) {
      _cooldownUntil = DateTime.now().add(const Duration(seconds: 30));
      cooldownSeconds.value = 30;
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_cooldownUntil == null || DateTime.now().isAfter(_cooldownUntil!)) {
          _cooldownUntil = null;
          cooldownSeconds.value = 0;
          _failedAttempts = 0;
          timer.cancel();
          _cooldownTimer = null;
        } else {
          cooldownSeconds.value =
              _cooldownUntil!.difference(DateTime.now()).inSeconds;
        }
      });
    }
  }

  /// Reset failed attempt counter and cancel cooldown (Requirement 9.4)
  void _resetFailures() {
    _failedAttempts = 0;
    _cooldownUntil = null;
    cooldownSeconds.value = 0;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
  }

  /// Attempt to re-login with stored credentials
  Future<bool> reLogin() async {
    if (!await NetworkUtils.hasConnection(Get.context)) {
      return false;
    }

    final String? tid = await SecureSharedPreferences.instance.getTID();
    final String? password =
        await SecureSharedPreferences.instance.getPassword();

    if (tid == null || password == null) {
      return false;
    }

    try {
      if (StorageService.isGw3) {
        // For username-based login (e.g. "WATSONLOYANG"), the operatorId
        // is stored separately from the TID (which is the JWT 'sub' field).
        // We must use operatorId as operatorName when available, otherwise
        // the server rejects the re-login because the TID is not a valid username.
        final String? operatorId =
            await SecureSharedPreferences.instance.getOperatorId();
        final String loginName =
            (operatorId != null && operatorId.isNotEmpty) ? operatorId : tid;
        return await _attemptGW3ReLogin(loginName, password);
      } else {
        return await _attemptGW2ReLogin(tid, password);
      }
    } catch (e) {
      return false;
    }
  }

  /// Attempt GW3 re-login
  Future<bool> _attemptGW3ReLogin(String operatorName, String password) async {
    final response = await apiRepository.loginGw3(
      LoginRequestGw3(
        operatorName: operatorName,
        operatorPassword: password,
      ),
    );
    return response.access_token != null;
  }

  /// Attempt GW2 re-login
  Future<bool> _attemptGW2ReLogin(String tid, String password) async {
    final response = await apiRepository.login(
      LoginRequest(
        username: tid,
        password: password,
      ),
    );
    return response != null;
  }

  /// Check if internet connection is available
  Future<bool> checkInternetConnection() async {
    return NetworkUtils.checkInternetConnection();
  }

  /// Set user preferences after successful login
  Future<void> setPreferences(LoginResponse res) async {
    await _saveRouteAndBrandPreferences(res);
    await _saveMerchantPreferences(res);
    await _saveAuthenticationPreferences(res);
  }

  /// Save route and brand related preferences
  Future<void> _saveRouteAndBrandPreferences(LoginResponse res) async {
    final String? routes = res.enabledRoutes?.join(',');
    final String? brands = res.enabledBrands?.join(',');

    await SecureSharedPreferences.instance.setRouteList(routes);
    await SecureSharedPreferences.instance.setRootRouteList(routes);
    await SecureSharedPreferences.instance.setBrandList(brands);
    await SecureSharedPreferences.instance.setRootBrandList(brands);
  }

  /// Save merchant related preferences
  Future<void> _saveMerchantPreferences(LoginResponse res) async {
    SharedPrefManager.setTerminalID = res.mcpTerminalId ?? '';
    await SecureSharedPreferences.instance
        .setMerchantOid(res.merchant?.id?.toString());
    await SecureSharedPreferences.instance.setRootTerminalId(res.mcpTerminalId);
    await SecureSharedPreferences.instance
        .setMerchantName(res.merchant?.shortName);
    await SecureSharedPreferences.instance
        .setAddress(getAddress(res.merchant?.address));
    await SecureSharedPreferences.instance
        .setCountryCodeAlpha(getCountryCodeAlpha(res.merchant?.address));
    await SecureSharedPreferences.instance
        .setMerchantShorName(res.merchant?.shortName ?? '');

    if (res.donationMcptid != null) {
      await SecureSharedPreferences.instance
          .setDonationTerminalId(res.donationMcptid);
    }
  }

  /// Save authentication related preferences
  Future<void> _saveAuthenticationPreferences(LoginResponse res) async {
    if (kDebugMode) {
      print(
          '[RememberTID] _saveAuthenticationPreferences → rememberTid=${isRememberTidChecked.value}, TID="${loginTIDController.text}"');
    }
    AppLogin.cashierID = loginTIDController.text;
    await SecureSharedPreferences.instance.setAccessToken('');
    await SharedPrefManager.setRefreshTokenSecure('');
    await SecureSharedPreferences.instance.setSignKey(res.signKey);
    await SecureSharedPreferences.instance.setTID(loginTIDController.text);
    await SecureSharedPreferences.instance
        .setRememberTid(isRememberTidChecked.value);
  }

  /// Hide keyboard by unfocusing text fields
  void hideKeyboard() {
    tidFocus.unfocus();
    passwordFocus.unfocus();
  }

  /// Load local data including language and remember TID preferences
  Future<void> getDataLocal() async {
    language.value =
        await SharedPrefManager.instance.getString('saveLanguage') ?? '🇺🇸';

    // Set selectedApp based on saved language flag
    String savedFlag = language.value;
    selectedApp.value = _getLanguageDisplayName(savedFlag);

    isRememberTidChecked.value =
        await SecureSharedPreferences.instance.getRememberTid() ?? false;

    if (isRememberTidChecked.value) {
      // Prefer operatorId (username login) over TID for textfield restore
      final String? savedOperatorId =
          await SecureSharedPreferences.instance.getOperatorId();
      if (savedOperatorId != null && savedOperatorId.isNotEmpty) {
        loginTIDController.text = savedOperatorId;
      } else {
        loginTIDController.text =
            await SecureSharedPreferences.instance.getTID() ?? '';
      }
    }
    if (kDebugMode) {
      print(
          '[RememberTID] getDataLocal → rememberTid=${isRememberTidChecked.value}, restoredTID="${loginTIDController.text}"');
    }
  }

  /// Get display name from flag emoji
  String _getLanguageDisplayName(String flagEmoji) {
    Map<String, String> flagToLanguage = {
      '🇺🇸': '🇺🇸  English',
      '🇨🇳': '🇨🇳  简体中文',
      '🇮🇳': '🇮🇳  हिन्दी',
      '🇪🇸': '🇪🇸  Español',
      '🇫🇷': '🇫🇷  Français',
      '🇸🇦': '🇸🇦  العربية',
      '🇧🇩': '🇧🇩  বাংলা',
      '🇷🇺': '🇷🇺  Русский',
      '🇵🇹': '🇵🇹  Português',
      '🇵🇰': '🇵🇰  اردو',
      '🇹🇭': '🇹🇭  ไทย',
      '🇲🇾': '🇲🇾  Bahasa Melayu',
      '🇰🇷': '🇰🇷  한국어',
      '🇻🇳': '🇻🇳  Tiếng Việt',
      '🇯🇵': '🇯🇵  日本語',
    };
    return flagToLanguage[flagEmoji] ?? '🇺🇸  English';
  }

  /// Toggle password visibility
  void togglePasswordVisibility(RxBool isVisible) =>
      isVisible.value = !isVisible.value;

  /// Toggle remember TID checkbox and persist to storage immediately
  /// This ensures the correct state is used when logout clears preferences
  Future<void> toggleCheckBox(bool turnOn) async {
    isRememberTidChecked.value = turnOn;
    if (kDebugMode) {
      print(
          '[RememberTID] toggleCheckBox → turnOn=$turnOn, currentTID="${loginTIDController.text}"');
    }
    // Persist immediately so clearSecureSharedPef() reads the correct value on logout
    await SecureSharedPreferences.instance.setRememberTid(turnOn);
  }

  /// Validate if input is a valid email
  bool isEmailRegrex(String input) => Regex.isEmail(input);

  /// Construct address string from address model
  String getAddress(AddressModel? responseData) {
    if (responseData == null) return '';

    final List<String> addressParts = [
      responseData.line1,
      responseData.line2,
      responseData.line3,
      responseData.line4,
      responseData.line5,
      responseData.city,
    ].where((part) => part != null && part.isNotEmpty).cast<String>().toList();

    return addressParts.join(' ');
  }

  /// Get country code from address model
  String getCountryCodeAlpha(AddressModel? responseData) {
    return responseData?.countryCodeAlpha ?? '';
  }

  /// Request necessary Bluetooth permissions for Android
  Future<void> requestBluetoothPermissions() async {
    if (!Platform.isAndroid) return;

    await _requestLocationPermission();
    await _requestBluetoothPermission();
  }

  /// Request location permission
  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      LogUtils.debugLog('Location permission granted');
    } else {
      LogUtils.debugLog('Location permission denied');
    }
  }

  /// Request Bluetooth permission
  Future<void> _requestBluetoothPermission() async {
    final status = await Permission.bluetooth.request();
    if (status.isGranted) {
      LogUtils.debugLog('Bluetooth permission granted');
    } else {
      LogUtils.debugLog('Bluetooth permission denied');
    }
  }

  /// Navigate to signup webpage
  void navigateToSignUp() {
    Get.toNamed('/create_account');
  }

  /// Save selected language to SharedPreferences
  Future<void> saveLanguageSelection(String selectedLanguage) async {
    selectedApp.value = selectedLanguage;

    // Extract flag emoji from selected language to save as language.value
    // Safe extraction: take first part before double space, fallback to first 4 chars
    String flagEmoji;
    if (selectedLanguage.contains('  ')) {
      flagEmoji = selectedLanguage.split('  ')[0];
    } else {
      // Fallback: assume first 2-4 characters are flag emoji
      flagEmoji = selectedLanguage.length >= 2
          ? selectedLanguage.substring(0, 2)
          : '🇺🇸';
    }

    language.value = flagEmoji;

    // Save to SharedPreferences
    await SharedPrefManager.instance.setString('saveLanguage', flagEmoji);
  }

  /// Handle back button press while loading is shown
  bool handleBackWhileLoading() {
    if (EasyLoading.isShow) {
      EasyLoading.dismiss();
      return true;
    }
    return false;
  }
}
