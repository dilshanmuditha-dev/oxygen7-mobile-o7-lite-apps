/// Centralized storage key management to prevent typos and ensure consistency.
///
/// All storage keys used throughout the application are defined here.
/// This enum maps to the exact string keys used in the legacy SecureSharedPreferences.
enum StorageKey {
  // Route lists
  routeList('routeList'),
  rootRouteList('rootRouteList'),
  donationRouteList('donationRouteList'),

  // Brand lists
  brandList('brandList'),
  rootBrandList('rootBrandList'),
  donationBrandList('donationBrandList'),

  // Terminal IDs
  mcpTerminalId('mcpTerminalId'),
  mcpMerchantOid('mcpMerchantOId'),
  donationTerminalId('donationMcptid'),
  rootTerminalId('rootMcptid'),
  tid('tid'),
  operatorId('operatorId'),

  // Merchant info
  terminalMerchantName('merchantName'),
  terminalAddress('address'),
  terminalCountryCodeAlpha('countryCodeAlpha'),
  shortName('shortName'),
  acraNo('acraNo'),

  // Authentication
  tokenLogin('tokenLogin'),
  signKey('signKey'),
  password('password'),
  rememberTid('remmemberTid'),
  refreshToken('refreshToken'),

  // Transaction
  referenceNo('referenceNo'),
  terminalDetail('terminalDetail'),

  // Settings
  carplaceNumber('carplaceNumber'),
  serviceChargeRate('serviceChargeRate'),
  emailCC('EMAIL_CC'),
  geoBlock('geoBlock'),

  // App preferences (UI settings — stored encrypted to prevent readable SharedPreferences)
  saveLanguage('saveLanguage'),
  locateChangeLanguage('locateChangeLanguage'),
  indexChangeLanguage('indexChangeLanguage'),
  localTitle('localTitle'),
  isCheckDarkMode('isCheckDarkMode'),
  isEnableSound('isEnableSound'),
  approveSound('approveSound'),
  isEnableAppAnimation('isEnableAppAnimation'),
  selectedAnimationStyle('selectedAnimationStyle'),
  isEnableRefundPassword('isEnableRefundPassword'),
  isEnableEmailReceipt('isEnableEmailReceipt'),
  isEnableEmailCC('isEnableEmailCC'),
  isEnableMinesec('isEnableMinesec'),
  isEnableRefreshInterval('isEnableRefreshInterval'),
  themeData('themeData'),
  isGw3('isGw3'),

  // Bluetooth printer
  btPrinterName('bt_printer_name'),
  btPrinterMac('bt_printer_mac'),

  // Migration marker
  migrationComplete('_secure_storage_migrated_v2');

  final String value;
  const StorageKey(this.value);

  /// Returns the StorageKey for a given string value, or null if not found.
  static StorageKey? fromValue(String value) {
    for (final key in StorageKey.values) {
      if (key.value == value) {
        return key;
      }
    }
    return null;
  }

  /// Returns all keys that should be encrypted (sensitive data).
  static List<StorageKey> get encryptedKeys => [
        routeList,
        rootRouteList,
        donationRouteList,
        brandList,
        rootBrandList,
        donationBrandList,
        mcpTerminalId,
        mcpMerchantOid,
        donationTerminalId,
        rootTerminalId,
        terminalMerchantName,
        terminalAddress,
        password,
        referenceNo,
      ];

  /// Returns all keys that were stored without encryption in legacy system.
  static List<StorageKey> get unencryptedKeys => [
        terminalCountryCodeAlpha,
        tokenLogin,
        signKey,
        shortName,
        tid,
        rememberTid,
        carplaceNumber,
        serviceChargeRate,
        emailCC,
      ];
}
