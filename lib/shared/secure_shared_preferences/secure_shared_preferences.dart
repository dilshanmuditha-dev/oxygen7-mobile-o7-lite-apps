// ignore_for_file: depend_on_referenced_packages, constant_identifier_names, avoid_print

import '../secure_storage/secure_storage_service.dart';

// Legacy constants kept for backward compatibility
const String TERMINAL_SETTING_PREFERENCES = "TerminalSettingPreferences";
const String KEY_GEO_BLOCK = "geoBlock";
const String MCP_TERMINAL_ID = "mcpTerminalId";
const String MCP_MERCHANT_OID = "mcpMerchantOId";
const String DONATION_TERMINAL_ID = "donationMcptid";
const String TOKEN_LOGIN = "tokenLogin";
const String ROOT_TERMINAL_ID = "rootMcptid";
const String REFERENCE_NO = "referenceNo";
const String SIGN_KEY = "signKey";
const String SHORT_NAME = "shortName";
const String ROUTE_LIST = "routeList";
const String DONATION_ROUTE_LIST = "donationRouteList";
const String ROOT_ROUTE_LIST = "rootRouteList";
const String ROOT_BRAND_LIST = "rootBrandList";
const String BRAND_LIST = "brandList";
const String DONATION_BRAND_LIST = "donationBrandList";
const String TERMINAL_ADDRESS = "address";
const String TERMINAL_COUNTRY_CODE_ALPHA = "countryCodeAlpha";
const String TERMINAL_MERCHANT_NAME = "merchantName";
const String TERMINAL_ACRA_NO = "acraNo";
const String REMEMBER_TID = "remmemberTid";
const String TID = "tid";
const String PASSWORD = "password";
const String CARPLACENUMBER = "carplaceNumber";
const String SERVICECHARGERATE = "serviceChargeRate";
const String EMAIL_CC = "EMAIL_CC";

/// Secure storage wrapper that delegates to SecureStorageService.
///
/// This class maintains the same API as the original SecureSharedPreferences
/// but now uses flutter_secure_storage with AES-GCM encryption instead of
/// the vulnerable AES-CBC implementation.
///
/// Security improvements:
/// - AES-GCM authenticated encryption (confidentiality + integrity)
/// - RSA-OAEP key wrapping on Android
/// - iOS Keychain storage
/// - Automatic migration from legacy storage
class SecureSharedPreferences {
  SecureSharedPreferences._privateConstructor();

  static final SecureSharedPreferences instance =
      SecureSharedPreferences._privateConstructor();

  /// Gets the underlying SecureStorageService instance.
  Future<SecureStorageService> _getService() async {
    return await SecureStorageService.getInstance();
  }

  // ============================================================
  // Route List Methods
  // ============================================================

  Future<void> setRouteList(String? routeList) async {
    final service = await _getService();
    await service.setRouteList(routeList);
  }

  Future<String?> getRouteList() async {
    final service = await _getService();
    return await service.getRouteList();
  }

  Future<void> setRootRouteList(String? routeList) async {
    final service = await _getService();
    await service.setRootRouteList(routeList);
  }

  Future<String?> getRootRouteList() async {
    final service = await _getService();
    return await service.getRootRouteList();
  }

  Future<void> setDonationRouteList(String? routeList) async {
    final service = await _getService();
    await service.setDonationRouteList(routeList);
  }

  Future<String?> getDonationRouteList() async {
    final service = await _getService();
    return await service.getDonationRouteList();
  }

  // ============================================================
  // Brand List Methods
  // ============================================================

  Future<void> setBrandList(String? brandList) async {
    final service = await _getService();
    await service.setBrandList(brandList);
  }

  Future<String?> getBrandList() async {
    final service = await _getService();
    return await service.getBrandList();
  }

  Future<void> setRootBrandList(String? brandList) async {
    final service = await _getService();
    await service.setRootBrandList(brandList);
  }

  Future<String?> getRootBrandList() async {
    final service = await _getService();
    return await service.getRootBrandList();
  }

  Future<void> setDonationBrandList(String? brandList) async {
    final service = await _getService();
    await service.setDonationBrandList(brandList);
  }

  Future<String?> getDonationBrandList() async {
    final service = await _getService();
    return await service.getDonationBrandList();
  }

  // ============================================================
  // Terminal ID Methods
  // ============================================================

  Future<void> setMCPTerminalId(String? mcpTerminalID) async {
    final service = await _getService();
    await service.setMCPTerminalId(mcpTerminalID);
  }

  Future<String?> getMCPTerminalId() async {
    final service = await _getService();
    return await service.getMCPTerminalId();
  }

  /// Convenience alias for [setMCPTerminalId].
  ///
  /// Stores the terminal ID in encrypted secure storage (flutter_secure_storage).
  Future<void> setTerminalID(String? terminalID) async {
    await setMCPTerminalId(terminalID);
  }

  /// Convenience alias for [getMCPTerminalId].
  ///
  /// Retrieves the terminal ID from encrypted secure storage.
  Future<String?> getTerminalID() async {
    return await getMCPTerminalId();
  }

  Future<void> setMerchantOid(String? mcpTerminalID) async {
    final service = await _getService();
    await service.setMerchantOid(mcpTerminalID);
  }

  Future<String?> getMcpMerchantOid() async {
    final service = await _getService();
    return await service.getMcpMerchantOid();
  }

  Future<void> setRootTerminalId(String? terminalId) async {
    final service = await _getService();
    await service.setRootTerminalId(terminalId);
  }

  Future<String?> getRootTerminalId() async {
    final service = await _getService();
    return await service.getRootTerminalId();
  }

  Future<void> setDonationTerminalId(String? donationTerminalId) async {
    final service = await _getService();
    await service.setDonationTerminalId(donationTerminalId);
  }

  Future<String?> getDonationTerminalId() async {
    final service = await _getService();
    return await service.getDonationTerminalId();
  }

  Future<void> setTID(String? oxpayTidKey) async {
    final service = await _getService();
    await service.setTID(oxpayTidKey);
  }

  Future<String?> getTID() async {
    final service = await _getService();
    return await service.getTID();
  }

  // ============================================================
  // Operator ID Methods (for username login textfield restore)
  // ============================================================

  Future<void> setOperatorId(String? operatorId) async {
    final service = await _getService();
    await service.setOperatorId(operatorId);
  }

  Future<String?> getOperatorId() async {
    final service = await _getService();
    return await service.getOperatorId();
  }

  // ============================================================
  // Merchant Info Methods
  // ============================================================

  Future<void> setMerchantName(String? merchantName) async {
    final service = await _getService();
    await service.setMerchantName(merchantName);
  }

  Future<String?> getMerchantName() async {
    final service = await _getService();
    return await service.getMerchantName();
  }

  Future<void> setAddress(String? address) async {
    final service = await _getService();
    await service.setAddress(address);
  }

  Future<String?> getAdress() async {
    final service = await _getService();
    return await service.getAdress();
  }

  Future<void> setCountryCodeAlpha(String? countryCodeAlpha) async {
    final service = await _getService();
    await service.setCountryCodeAlpha(countryCodeAlpha);
  }

  Future<String?> getCountryCodeAlpha() async {
    final service = await _getService();
    return await service.getCountryCodeAlpha();
  }

  Future<void> setMerchantShorName(String? setMerchantShorNameKey) async {
    final service = await _getService();
    await service.setMerchantShorName(setMerchantShorNameKey);
  }

  Future<String?> getMerchantShorName() async {
    final service = await _getService();
    return await service.getMerchantShorName();
  }

  // ============================================================
  // Authentication Methods
  // ============================================================

  Future<void> setAccessToken(String? tokenLogin) async {
    final service = await _getService();
    await service.setAccessToken(tokenLogin);
  }

  Future<String?> getAccessToken() async {
    final service = await _getService();
    return await service.getAccessToken();
  }

  Future<void> setRefreshToken(String? token) async {
    final service = await _getService();
    await service.setRefreshToken(token);
  }

  Future<String?> getRefreshToken() async {
    final service = await _getService();
    return await service.getRefreshToken();
  }

  Future<void> setSignKey(String? signKey) async {
    final service = await _getService();
    await service.setSignKey(signKey);
  }

  Future<String?> getSignKey() async {
    final service = await _getService();
    return await service.getSignKey();
  }

  Future<String?> signature() async {
    final service = await _getService();
    return await service.signature();
  }

  Future<void> setPassword(String? password) async {
    final service = await _getService();
    await service.setPassword(password);
  }

  Future<String?> getPassword() async {
    final service = await _getService();
    return await service.getPassword();
  }

  Future<void> setRememberTid(bool? tidKey) async {
    final service = await _getService();
    await service.setRememberTid(tidKey);
  }

  Future<bool?> getRememberTid() async {
    final service = await _getService();
    return await service.getRememberTid();
  }

  // ============================================================
  // Transaction Methods
  // ============================================================

  Future<void> setReferenceNo(String? referenceNo) async {
    final service = await _getService();
    await service.setReferenceNo(referenceNo);
  }

  Future<String?> getReferenceNo() async {
    final service = await _getService();
    return await service.getReferenceNo();
  }

  Future<void> setTerminalDetail(String? terminalDetailJson) async {
    final service = await _getService();
    await service.setTerminalDetail(terminalDetailJson);
  }

  Future<String?> getTerminalDetail() async {
    final service = await _getService();
    return await service.getTerminalDetail();
  }

  // ============================================================
  // Settings Methods
  // ============================================================

  Future<void> setCarplaceNumber(String? carplateNumber) async {
    final service = await _getService();
    await service.setCarplaceNumber(carplateNumber);
  }

  Future<String?> getCarplaceNumber() async {
    final service = await _getService();
    return await service.getCarplaceNumber();
  }

  Future<void> setServiceChargeRate(int? serviceChargeRate) async {
    final service = await _getService();
    await service.setServiceChargeRate(serviceChargeRate);
  }

  Future<int?> getServiceChargeRate() async {
    final service = await _getService();
    return await service.getServiceChargeRate();
  }

  Future<void> setEmailCC(String? emailCC) async {
    final service = await _getService();
    await service.setEmailCC(emailCC);
  }

  Future<String?> getEmailCC() async {
    final service = await _getService();
    return await service.getEmailCC();
  }

  // ============================================================
  // Bluetooth Printer Methods
  // ============================================================

  Future<void> setBtPrinterName(String? name) async {
    final service = await _getService();
    await service.setBtPrinterName(name);
  }

  Future<String?> getBtPrinterName() async {
    final service = await _getService();
    return await service.getBtPrinterName();
  }

  Future<void> setBtPrinterMac(String? mac) async {
    final service = await _getService();
    await service.setBtPrinterMac(mac);
  }

  Future<String?> getBtPrinterMac() async {
    final service = await _getService();
    return await service.getBtPrinterMac();
  }

  Future<void> clearBtPrinter() async {
    final service = await _getService();
    await service.clearBtPrinter();
  }

  // ============================================================
  // App Preferences Methods (UI settings)
  // ============================================================

  Future<void> setSaveLanguage(String? value) async {
    final service = await _getService();
    await service.setSaveLanguage(value);
  }

  Future<String?> getSaveLanguage() async {
    final service = await _getService();
    return await service.getSaveLanguage();
  }

  Future<void> setLocateChangeLanguage(String? value) async {
    final service = await _getService();
    await service.setLocateChangeLanguage(value);
  }

  Future<String?> getLocateChangeLanguage() async {
    final service = await _getService();
    return await service.getLocateChangeLanguage();
  }

  Future<void> setIndexChangeLanguage(int value) async {
    final service = await _getService();
    await service.setIndexChangeLanguage(value);
  }

  Future<int> getIndexChangeLanguage() async {
    final service = await _getService();
    return await service.getIndexChangeLanguage();
  }

  Future<void> setLocalTitle(String? value) async {
    final service = await _getService();
    await service.setLocalTitle(value);
  }

  Future<String?> getLocalTitle() async {
    final service = await _getService();
    return await service.getLocalTitle();
  }

  Future<void> setIsCheckDarkMode(bool? value) async {
    final service = await _getService();
    await service.setIsCheckDarkMode(value);
  }

  Future<bool> getIsCheckDarkMode() async {
    final service = await _getService();
    return await service.getIsCheckDarkMode();
  }

  Future<void> setIsEnableSound(bool? value) async {
    final service = await _getService();
    await service.setIsEnableSound(value);
  }

  Future<bool> getIsEnableSound() async {
    final service = await _getService();
    return await service.getIsEnableSound();
  }

  Future<void> setApproveSound(String? value) async {
    final service = await _getService();
    await service.setApproveSound(value);
  }

  Future<String> getApproveSound() async {
    final service = await _getService();
    return await service.getApproveSound();
  }

  Future<void> setIsEnableAppAnimation(bool? value) async {
    final service = await _getService();
    await service.setIsEnableAppAnimation(value);
  }

  Future<bool> getIsEnableAppAnimation() async {
    final service = await _getService();
    return await service.getIsEnableAppAnimation();
  }

  Future<void> setSelectedAnimationStyle(String? value) async {
    final service = await _getService();
    await service.setSelectedAnimationStyle(value);
  }

  Future<String?> getSelectedAnimationStyle() async {
    final service = await _getService();
    return await service.getSelectedAnimationStyle();
  }

  Future<void> setIsEnableRefundPassword(bool? value) async {
    final service = await _getService();
    await service.setIsEnableRefundPassword(value);
  }

  Future<bool> getIsEnableRefundPassword() async {
    final service = await _getService();
    return await service.getIsEnableRefundPassword();
  }

  Future<void> setIsEnableEmailReceipt(bool? value) async {
    final service = await _getService();
    await service.setIsEnableEmailReceipt(value);
  }

  Future<bool> getIsEnableEmailReceipt() async {
    final service = await _getService();
    return await service.getIsEnableEmailReceipt();
  }

  Future<void> setIsEnableEmailCC(bool? value) async {
    final service = await _getService();
    await service.setIsEnableEmailCC(value);
  }

  Future<bool> getIsEnableEmailCC() async {
    final service = await _getService();
    return await service.getIsEnableEmailCC();
  }

  Future<void> setIsEnableMinesec(bool? value) async {
    final service = await _getService();
    await service.setIsEnableMinesec(value);
  }

  Future<bool> getIsEnableMinesec() async {
    final service = await _getService();
    return await service.getIsEnableMinesec();
  }

  Future<void> setIsEnableRefreshInterval(bool? value) async {
    final service = await _getService();
    await service.setIsEnableRefreshInterval(value);
  }

  Future<bool> getIsEnableRefreshInterval() async {
    final service = await _getService();
    return await service.getIsEnableRefreshInterval();
  }

  Future<void> setThemeData(String? value) async {
    final service = await _getService();
    await service.setThemeData(value);
  }

  Future<String?> getThemeData() async {
    final service = await _getService();
    return await service.getThemeData();
  }

  Future<void> setIsGw3(bool? value) async {
    final service = await _getService();
    await service.setIsGw3(value);
  }

  Future<bool> getIsGw3() async {
    final service = await _getService();
    return await service.getIsGw3();
  }

  // ============================================================
  // Clear Methods
  // ============================================================

  /// Clears all secure storage data.
  ///
  /// If rememberTid is true, preserves the TID value.
  Future<void> clearSecureSharedPef() async {
    final service = await _getService();
    await service.clearSecureSharedPef();
  }

  /// Clears only session-related data while preserving app settings.
  ///
  /// Session data cleared:
  /// - Route lists, brand lists, terminal IDs, merchant info
  /// - Authentication tokens, passwords, sign keys
  /// - Transaction references
  ///
  /// Settings preserved:
  /// - carplaceNumber, serviceChargeRate, emailCC, rememberTid
  Future<void> clearSessionOnly() async {
    final service = await _getService();
    await service.clearSessionOnly();
  }
}
