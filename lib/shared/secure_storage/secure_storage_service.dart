// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'flutter_secure_storage_adapter.dart';
import 'i_secure_storage.dart';
import 'legacy_storage_adapter.dart';
import 'migration_service.dart';
import 'storage_key.dart';
import '../constants/constants_o7lite.dart';
import '../utils/invoke.dart';
import 'package:app/shared/utils/log_utils.dart';

/// Main service for secure storage operations.
///
/// This service provides a drop-in replacement for SecureSharedPreferences
/// with improved security using AES-GCM encryption.
///
/// Features:
/// - AES-GCM authenticated encryption (confidentiality + integrity)
/// - Automatic migration from legacy storage on first access
/// - Uniform error responses to prevent information leakage
/// - Singleton pattern with async initialization
class SecureStorageService {
  static SecureStorageService? _instance;
  static bool _initialized = false;

  final ISecureStorage _storage;
  final MigrationService _migrationService;

  SecureStorageService._({
    required ISecureStorage storage,
    required MigrationService migrationService,
  })  : _storage = storage,
        _migrationService = migrationService;

  /// Gets the singleton instance, initializing if necessary.
  ///
  /// This method handles migration automatically on first access.
  static Future<SecureStorageService> getInstance() async {
    if (_instance == null || !_initialized) {
      final storage = FlutterSecureStorageAdapter();
      final legacyStorage = LegacyStorageAdapter();
      final migrationService = MigrationService(
        legacyStorage: legacyStorage,
        newStorage: storage,
      );

      _instance = SecureStorageService._(
        storage: storage,
        migrationService: migrationService,
      );

      // Perform migration on first access
      await _instance!._migrationService.migrateIfNeeded();
      _initialized = true;
    }
    return _instance!;
  }

  /// Creates an instance with custom dependencies (for testing).
  static SecureStorageService createWithDependencies({
    required ISecureStorage storage,
    required MigrationService migrationService,
  }) {
    return SecureStorageService._(
      storage: storage,
      migrationService: migrationService,
    );
  }

  /// Resets the singleton instance (for testing).
  static void resetInstance() {
    _instance = null;
    _initialized = false;
  }

  // ============================================================
  // Route List Methods
  // ============================================================

  Future<void> setRouteList(String? routeList) async {
    await _storage.write(key: StorageKey.routeList.value, value: routeList);
  }

  Future<String?> getRouteList() async {
    return await _storage.read(key: StorageKey.routeList.value);
  }

  Future<void> setRootRouteList(String? routeList) async {
    await _storage.write(key: StorageKey.rootRouteList.value, value: routeList);
  }

  Future<String?> getRootRouteList() async {
    return await _storage.read(key: StorageKey.rootRouteList.value);
  }

  Future<void> setDonationRouteList(String? routeList) async {
    await _storage.write(
        key: StorageKey.donationRouteList.value, value: routeList);
  }

  Future<String?> getDonationRouteList() async {
    return await _storage.read(key: StorageKey.donationRouteList.value);
  }

  // ============================================================
  // Brand List Methods
  // ============================================================

  Future<void> setBrandList(String? brandList) async {
    await _storage.write(key: StorageKey.brandList.value, value: brandList);
  }

  Future<String?> getBrandList() async {
    return await _storage.read(key: StorageKey.brandList.value);
  }

  Future<void> setRootBrandList(String? brandList) async {
    await _storage.write(key: StorageKey.rootBrandList.value, value: brandList);
  }

  Future<String?> getRootBrandList() async {
    return await _storage.read(key: StorageKey.rootBrandList.value);
  }

  Future<void> setDonationBrandList(String? brandList) async {
    await _storage.write(
        key: StorageKey.donationBrandList.value, value: brandList);
  }

  Future<String?> getDonationBrandList() async {
    return await _storage.read(key: StorageKey.donationBrandList.value);
  }

  // ============================================================
  // Terminal ID Methods
  // ============================================================

  Future<void> setMCPTerminalId(String? mcpTerminalID) async {
    await _storage.write(
        key: StorageKey.mcpTerminalId.value, value: mcpTerminalID);
  }

  Future<String?> getMCPTerminalId() async {
    return await _storage.read(key: StorageKey.mcpTerminalId.value);
  }

  Future<void> setMerchantOid(String? merchantOid) async {
    await _storage.write(
        key: StorageKey.mcpMerchantOid.value, value: merchantOid);
  }

  Future<String?> getMcpMerchantOid() async {
    return await _storage.read(key: StorageKey.mcpMerchantOid.value);
  }

  Future<void> setRootTerminalId(String? terminalId) async {
    await _storage.write(
        key: StorageKey.rootTerminalId.value, value: terminalId);
  }

  Future<String?> getRootTerminalId() async {
    return await _storage.read(key: StorageKey.rootTerminalId.value);
  }

  Future<void> setDonationTerminalId(String? donationTerminalId) async {
    await _storage.write(
        key: StorageKey.donationTerminalId.value, value: donationTerminalId);
  }

  Future<String?> getDonationTerminalId() async {
    return await _storage.read(key: StorageKey.donationTerminalId.value);
  }

  Future<void> setTID(String? tid) async {
    await _storage.write(key: StorageKey.tid.value, value: tid);
  }

  Future<String?> getTID() async {
    return await _storage.read(key: StorageKey.tid.value);
  }

  // ============================================================
  // Operator ID Methods (for username login textfield restore)
  // ============================================================

  Future<void> setOperatorId(String? operatorId) async {
    await _storage.write(key: StorageKey.operatorId.value, value: operatorId);
  }

  Future<String?> getOperatorId() async {
    return await _storage.read(key: StorageKey.operatorId.value);
  }

  // ============================================================
  // Merchant Info Methods
  // ============================================================

  Future<void> setMerchantName(String? merchantName) async {
    await _storage.write(
        key: StorageKey.terminalMerchantName.value, value: merchantName);
  }

  Future<String?> getMerchantName() async {
    return await _storage.read(key: StorageKey.terminalMerchantName.value);
  }

  Future<void> setAddress(String? address) async {
    await _storage.write(key: StorageKey.terminalAddress.value, value: address);
  }

  Future<String?> getAdress() async {
    return await _storage.read(key: StorageKey.terminalAddress.value);
  }

  Future<void> setCountryCodeAlpha(String? countryCodeAlpha) async {
    await _storage.write(
        key: StorageKey.terminalCountryCodeAlpha.value,
        value: countryCodeAlpha);
  }

  Future<String?> getCountryCodeAlpha() async {
    return await _storage.read(key: StorageKey.terminalCountryCodeAlpha.value);
  }

  Future<void> setMerchantShorName(String? shortName) async {
    await _storage.write(key: StorageKey.shortName.value, value: shortName);
  }

  Future<String?> getMerchantShorName() async {
    return await _storage.read(key: StorageKey.shortName.value);
  }

  // ============================================================
  // Authentication Methods
  // ============================================================

  Future<void> setAccessToken(String? tokenLogin) async {
    await _storage.write(key: StorageKey.tokenLogin.value, value: tokenLogin);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: StorageKey.tokenLogin.value);
  }

  Future<void> setRefreshToken(String? token) async {
    await _storage.write(key: StorageKey.refreshToken.value, value: token);
  }

  /// Gets the refresh token from secure storage.
  ///
  /// On first read, performs a one-time migration: if secure storage has no
  /// refresh token but SharedPreferences does, migrates it to secure storage
  /// and deletes it from SharedPreferences.
  Future<String?> getRefreshToken() async {
    final secureValue = await _storage.read(key: StorageKey.refreshToken.value);
    if (secureValue != null && secureValue.isNotEmpty) {
      return secureValue;
    }

    // One-time migration from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final plainValue = prefs.getString('refreshToken');
    if (plainValue != null && plainValue.isNotEmpty) {
      await _storage.write(
          key: StorageKey.refreshToken.value, value: plainValue);
      await prefs.remove('refreshToken');
      return plainValue;
    }

    return null;
  }

  Future<void> setSignKey(String? signKey) async {
    await _storage.write(key: StorageKey.signKey.value, value: signKey);
  }

  Future<String?> getSignKey() async {
    return await _storage.read(key: StorageKey.signKey.value);
  }

  Future<String?> signature() async {
    String? signKey = await getSignKey();
    String? encryptSignature;
    if (signKey == null) {
      LogUtils.debugLog("No Signature");
    }

    if (signKey != null && signKey.isNotEmpty) {
      encryptSignature = encryptionHmacSHA512(signKey, BaseAppO7Lite.hmacKey);
    }
    return encryptSignature;
  }

  Future<void> setPassword(String? password) async {
    await _storage.write(key: StorageKey.password.value, value: password);
  }

  Future<String?> getPassword() async {
    return await _storage.read(key: StorageKey.password.value);
  }

  Future<void> setRememberTid(bool? rememberTid) async {
    await _storage.write(
        key: StorageKey.rememberTid.value,
        value: rememberTid?.toString() ?? 'false');
  }

  Future<bool?> getRememberTid() async {
    final value = await _storage.read(key: StorageKey.rememberTid.value);
    if (value == null) return null;
    return value == 'true';
  }

  // ============================================================
  // Transaction Methods
  // ============================================================

  Future<void> setReferenceNo(String? referenceNo) async {
    await _storage.write(key: StorageKey.referenceNo.value, value: referenceNo);
  }

  Future<String?> getReferenceNo() async {
    return await _storage.read(key: StorageKey.referenceNo.value);
  }

  // ============================================================
  // Settings Methods
  // ============================================================

  Future<void> setCarplaceNumber(String? carplateNumber) async {
    await _storage.write(
        key: StorageKey.carplaceNumber.value, value: carplateNumber);
  }

  Future<String?> getCarplaceNumber() async {
    return await _storage.read(key: StorageKey.carplaceNumber.value);
  }

  Future<void> setServiceChargeRate(int? serviceChargeRate) async {
    await _storage.write(
        key: StorageKey.serviceChargeRate.value,
        value: serviceChargeRate?.toString() ?? '0');
  }

  Future<int?> getServiceChargeRate() async {
    final value = await _storage.read(key: StorageKey.serviceChargeRate.value);
    if (value == null) return 0;
    return int.tryParse(value) ?? 0;
  }

  Future<void> setEmailCC(String? emailCC) async {
    await _storage.write(key: StorageKey.emailCC.value, value: emailCC);
  }

  Future<String?> getEmailCC() async {
    return await _storage.read(key: StorageKey.emailCC.value);
  }

  // ============================================================
  // Terminal Detail Methods
  // ============================================================

  /// Stores the terminal detail JSON string in encrypted secure storage.
  Future<void> setTerminalDetail(String? terminalDetailJson) async {
    await _storage.write(
        key: StorageKey.terminalDetail.value, value: terminalDetailJson);
  }

  /// Retrieves the terminal detail JSON string from encrypted secure storage.
  ///
  /// On first read, performs a one-time migration: if secure storage has no
  /// value but SharedPreferences does, migrates it to secure storage and
  /// deletes it from SharedPreferences.
  Future<String?> getTerminalDetail() async {
    final secureValue =
        await _storage.read(key: StorageKey.terminalDetail.value);
    if (secureValue != null && secureValue.isNotEmpty) {
      return secureValue;
    }

    // One-time migration from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final plainValue = prefs.getString('terminalDetail');
    if (plainValue != null && plainValue.isNotEmpty) {
      await _storage.write(
          key: StorageKey.terminalDetail.value, value: plainValue);
      await prefs.remove('terminalDetail');
      if (kDebugMode) {
        debugPrint(
            '[SecureStorage] Migrated terminalDetail to encrypted storage');
      }
      return plainValue;
    }

    return null;
  }

  // ============================================================
  // Bluetooth Printer Methods
  // ============================================================

  Future<void> setBtPrinterName(String? name) async {
    await _storage.write(key: StorageKey.btPrinterName.value, value: name);
  }

  Future<String?> getBtPrinterName() async {
    return await _storage.read(key: StorageKey.btPrinterName.value);
  }

  Future<void> setBtPrinterMac(String? mac) async {
    await _storage.write(key: StorageKey.btPrinterMac.value, value: mac);
  }

  Future<String?> getBtPrinterMac() async {
    return await _storage.read(key: StorageKey.btPrinterMac.value);
  }

  Future<void> clearBtPrinter() async {
    await _storage.delete(key: StorageKey.btPrinterName.value);
    await _storage.delete(key: StorageKey.btPrinterMac.value);
  }

  // ============================================================
  // App Preferences Methods (UI settings — stored encrypted)
  // ============================================================

  Future<void> setSaveLanguage(String? value) async {
    await _storage.write(key: StorageKey.saveLanguage.value, value: value);
  }

  Future<String?> getSaveLanguage() async {
    return await _storage.read(key: StorageKey.saveLanguage.value);
  }

  Future<void> setLocateChangeLanguage(String? value) async {
    await _storage.write(
        key: StorageKey.locateChangeLanguage.value, value: value);
  }

  Future<String?> getLocateChangeLanguage() async {
    return await _storage.read(key: StorageKey.locateChangeLanguage.value);
  }

  Future<void> setIndexChangeLanguage(int value) async {
    await _storage.write(
        key: StorageKey.indexChangeLanguage.value, value: value.toString());
  }

  Future<int> getIndexChangeLanguage() async {
    final value =
        await _storage.read(key: StorageKey.indexChangeLanguage.value);
    return int.tryParse(value ?? '0') ?? 0;
  }

  Future<void> setLocalTitle(String? value) async {
    await _storage.write(key: StorageKey.localTitle.value, value: value);
  }

  Future<String?> getLocalTitle() async {
    return await _storage.read(key: StorageKey.localTitle.value);
  }

  Future<void> setIsCheckDarkMode(bool? value) async {
    await _storage.write(
        key: StorageKey.isCheckDarkMode.value,
        value: value?.toString() ?? 'false');
  }

  Future<bool> getIsCheckDarkMode() async {
    final value = await _storage.read(key: StorageKey.isCheckDarkMode.value);
    return value == 'true';
  }

  Future<void> setIsEnableSound(bool? value) async {
    await _storage.write(
        key: StorageKey.isEnableSound.value,
        value: value?.toString() ?? 'true');
  }

  Future<bool> getIsEnableSound() async {
    final value = await _storage.read(key: StorageKey.isEnableSound.value);
    return value != 'false'; // defaults to true
  }

  Future<void> setApproveSound(String? value) async {
    await _storage.write(key: StorageKey.approveSound.value, value: value);
  }

  Future<String> getApproveSound() async {
    return await _storage.read(key: StorageKey.approveSound.value) ??
        'o7lite/sound/cashier_sound.mp3';
  }

  Future<void> setIsEnableAppAnimation(bool? value) async {
    await _storage.write(
        key: StorageKey.isEnableAppAnimation.value,
        value: value?.toString() ?? 'true');
  }

  Future<bool> getIsEnableAppAnimation() async {
    final value =
        await _storage.read(key: StorageKey.isEnableAppAnimation.value);
    return value != 'false'; // defaults to true
  }

  Future<void> setSelectedAnimationStyle(String? value) async {
    await _storage.write(
        key: StorageKey.selectedAnimationStyle.value, value: value);
  }

  Future<String?> getSelectedAnimationStyle() async {
    return await _storage.read(key: StorageKey.selectedAnimationStyle.value);
  }

  Future<void> setIsEnableRefundPassword(bool? value) async {
    await _storage.write(
        key: StorageKey.isEnableRefundPassword.value,
        value: value?.toString() ?? 'false');
  }

  Future<bool> getIsEnableRefundPassword() async {
    final value =
        await _storage.read(key: StorageKey.isEnableRefundPassword.value);
    return value == 'true';
  }

  Future<void> setIsEnableEmailReceipt(bool? value) async {
    await _storage.write(
        key: StorageKey.isEnableEmailReceipt.value,
        value: value?.toString() ?? 'false');
  }

  Future<bool> getIsEnableEmailReceipt() async {
    final value =
        await _storage.read(key: StorageKey.isEnableEmailReceipt.value);
    return value == 'true';
  }

  Future<void> setIsEnableEmailCC(bool? value) async {
    await _storage.write(
        key: StorageKey.isEnableEmailCC.value,
        value: value?.toString() ?? 'false');
  }

  Future<bool> getIsEnableEmailCC() async {
    final value = await _storage.read(key: StorageKey.isEnableEmailCC.value);
    return value == 'true';
  }

  Future<void> setIsEnableMinesec(bool? value) async {
    await _storage.write(
        key: StorageKey.isEnableMinesec.value,
        value: value?.toString() ?? 'false');
  }

  Future<bool> getIsEnableMinesec() async {
    final value = await _storage.read(key: StorageKey.isEnableMinesec.value);
    return value == 'true';
  }

  Future<void> setIsEnableRefreshInterval(bool? value) async {
    await _storage.write(
        key: StorageKey.isEnableRefreshInterval.value,
        value: value?.toString() ?? 'false');
  }

  Future<bool> getIsEnableRefreshInterval() async {
    final value =
        await _storage.read(key: StorageKey.isEnableRefreshInterval.value);
    return value == 'true';
  }

  Future<void> setThemeData(String? value) async {
    await _storage.write(key: StorageKey.themeData.value, value: value);
  }

  Future<String?> getThemeData() async {
    return await _storage.read(key: StorageKey.themeData.value);
  }

  Future<void> setIsGw3(bool? value) async {
    await _storage.write(
        key: StorageKey.isGw3.value, value: value?.toString() ?? 'false');
  }

  Future<bool> getIsGw3() async {
    final value = await _storage.read(key: StorageKey.isGw3.value);
    return value == 'true';
  }

  // ============================================================
  // Clear Methods
  // ============================================================

  /// Clears all secure storage data and session SharedPreferences.
  ///
  /// Preserves user-configured app settings (defined in [_appSettingsKeys])
  /// across the clear operation. If rememberTid is true, also preserves
  /// the TID value.
  ///
  /// When [aggressiveWipe] is true (used for rooted device detection),
  /// recursively deletes ALL files in app data directories to ensure no
  /// plaintext artifacts remain. When false (default, for normal logout
  /// flows), only selectively removes known library-persisted files
  /// (Firebase, PersistedInstallation, JSON).
  Future<void> clearSecureSharedPef({bool aggressiveWipe = false}) async {
    final localPrefs = await SharedPreferences.getInstance();
    final rememberTid = await getRememberTid() ?? false;

    final saveLanguage = await getSaveLanguage();
    final locateChangeLanguage = await getLocateChangeLanguage();
    final indexChangeLanguage = await getIndexChangeLanguage();
    final localTitle = await getLocalTitle();
    final isCheckDarkMode = await getIsCheckDarkMode();
    final isEnableSound = await getIsEnableSound();
    final approveSound = await getApproveSound();
    final isEnableAppAnimation = await getIsEnableAppAnimation();
    final selectedAnimationStyle = await getSelectedAnimationStyle();
    final isEnableRefundPassword = await getIsEnableRefundPassword();
    final isEnableEmailReceipt = await getIsEnableEmailReceipt();
    final isEnableEmailCC = await getIsEnableEmailCC();
    final isEnableMinesec = await getIsEnableMinesec();
    final isEnableRefreshInterval = await getIsEnableRefreshInterval();
    final themeData = await getThemeData();
    final isGw3 = await getIsGw3();

    // Save TID and operatorId if rememberTid is enabled
    String? tid;
    String? operatorId;
    if (rememberTid) {
      tid = await getTID();
      operatorId = await getOperatorId();
    }

    // Clear everything
    await _storage.deleteAll();
    await localPrefs.clear();

    // File cleanup in app data directories
    try {
      final appDirs = <Directory>[];
      try {
        final appSupport = await getApplicationSupportDirectory();
        appDirs.add(appSupport);
      } catch (_) {}
      try {
        final appDoc = await getApplicationDocumentsDirectory();
        appDirs.add(appDoc);
      } catch (_) {}
      try {
        final temp = await getTemporaryDirectory();
        appDirs.add(temp);
      } catch (_) {}

      if (aggressiveWipe) {
        // Rooted device context: recursively delete ALL files in app
        // directories to ensure no plaintext data remains accessible.
        for (final dir in appDirs) {
          try {
            if (dir.existsSync()) {
              await for (final entity in dir.list(recursive: false)) {
                try {
                  if (entity is File) {
                    await entity.delete();
                  } else if (entity is Directory) {
                    await entity.delete(recursive: true);
                  }
                } catch (_) {
                  // ignore individual file deletion errors
                }
              }
            }
          } catch (_) {
            // ignore errors for individual directories
          }
        }
      } else {
        // Normal logout flow: selectively delete known library-persisted
        // files that may contain tokens (e.g., Firebase PersistedInstallation
        // JSON files) under the app's files directories.
        for (final dir in appDirs) {
          try {
            if (dir.existsSync()) {
              await for (final entity in dir.list(recursive: false)) {
                final name = entity.path.split(Platform.pathSeparator).last;
                if (name.startsWith('PersistedInstallation') ||
                    name.contains('installation') ||
                    name.contains('firebase') ||
                    name.endsWith('.json')) {
                  try {
                    if (entity is File) await entity.delete();
                    if (entity is Directory) {
                      await entity.delete(recursive: true);
                    }
                  } catch (_) {
                    // ignore
                  }
                }
              }
            }
          } catch (_) {
            // ignore errors for individual directories
          }
        }
      }
    } catch (_) {
      // Don't fail the clear operation because of file deletions.
    }

    // Restore app settings to encrypted secure storage
    await setSaveLanguage(saveLanguage);
    await setLocateChangeLanguage(locateChangeLanguage);
    await setIndexChangeLanguage(indexChangeLanguage);
    await setLocalTitle(localTitle);
    await setIsCheckDarkMode(isCheckDarkMode);
    await setIsEnableSound(isEnableSound);
    await setApproveSound(approveSound);
    await setIsEnableAppAnimation(isEnableAppAnimation);
    await setSelectedAnimationStyle(selectedAnimationStyle);
    await setIsEnableRefundPassword(isEnableRefundPassword);
    await setIsEnableEmailReceipt(isEnableEmailReceipt);
    await setIsEnableEmailCC(isEnableEmailCC);
    await setIsEnableMinesec(isEnableMinesec);
    await setIsEnableRefreshInterval(isEnableRefreshInterval);
    await setThemeData(themeData);
    await setIsGw3(isGw3);

    // Restore rememberTid, TID, and operatorId
    if (rememberTid) {
      await setRememberTid(true);
      await setTID(tid);
      if (operatorId != null && operatorId.isNotEmpty) {
        await setOperatorId(operatorId);
      }
    }
  }

  /// Clears only session-related data while preserving app settings.
  ///
  /// Session data cleared:
  /// - Route lists (routeList, rootRouteList, donationRouteList)
  /// - Brand lists (brandList, rootBrandList, donationBrandList)
  /// - Terminal IDs (mcpTerminalId, mcpMerchantOid, donationTerminalId, rootTerminalId, tid)
  /// - Merchant info (merchantName, address, countryCodeAlpha, shortName)
  /// - Authentication (tokenLogin, signKey, password)
  /// - Transaction reference (referenceNo)
  /// - Terminal detail (terminalDetail — contains merchant info, addresses, etc.)
  ///
  /// Settings preserved:
  /// - carplaceNumber, serviceChargeRate, emailCC, rememberTid
  Future<void> clearSessionOnly() async {
    // First, save settings that need to be preserved
    final rememberTid = await getRememberTid();
    final tid = await getTID();
    final operatorId = await getOperatorId();
    final carplaceNumber = await getCarplaceNumber();
    final serviceChargeRate = await getServiceChargeRate();
    final emailCC = await getEmailCC();

    LogUtils.debugLog(
        '[RememberTID] clearSessionOnly START → rememberTid=$rememberTid, TID=$tid, operatorId=$operatorId');

    // Delete all session-related keys
    await _storage.delete(key: StorageKey.routeList.value);
    await _storage.delete(key: StorageKey.rootRouteList.value);
    await _storage.delete(key: StorageKey.donationRouteList.value);
    await _storage.delete(key: StorageKey.brandList.value);
    await _storage.delete(key: StorageKey.rootBrandList.value);
    await _storage.delete(key: StorageKey.donationBrandList.value);
    await _storage.delete(key: StorageKey.mcpTerminalId.value);
    await _storage.delete(key: StorageKey.mcpMerchantOid.value);
    await _storage.delete(key: StorageKey.donationTerminalId.value);
    await _storage.delete(key: StorageKey.rootTerminalId.value);
    await _storage.delete(key: StorageKey.tid.value);
    await _storage.delete(key: StorageKey.operatorId.value);
    await _storage.delete(key: StorageKey.terminalMerchantName.value);
    await _storage.delete(key: StorageKey.terminalAddress.value);
    await _storage.delete(key: StorageKey.terminalCountryCodeAlpha.value);
    await _storage.delete(key: StorageKey.shortName.value);
    await _storage.delete(key: StorageKey.tokenLogin.value);
    await _storage.delete(key: StorageKey.signKey.value);
    await _storage.delete(key: StorageKey.password.value);
    await _storage.delete(key: StorageKey.refreshToken.value);
    await _storage.delete(key: StorageKey.referenceNo.value);
    await _storage.delete(key: StorageKey.terminalDetail.value);

    // Restore the preserved settings
    if (rememberTid != null) {
      await setRememberTid(rememberTid);
    }
    // Restore TID and operatorId if rememberTid is enabled
    if (rememberTid == true && tid != null && tid.isNotEmpty) {
      await setTID(tid);
      LogUtils.debugLog('[RememberTID] clearSessionOnly → RESTORED TID=$tid');
    } else {
      LogUtils.debugLog(
          '[RememberTID] clearSessionOnly → TID NOT restored (rememberTid=$rememberTid, tid=$tid)');
    }
    if (rememberTid == true && operatorId != null && operatorId.isNotEmpty) {
      await setOperatorId(operatorId);
      LogUtils.debugLog(
          '[RememberTID] clearSessionOnly → RESTORED operatorId=$operatorId');
    }
    if (carplaceNumber != null) {
      await setCarplaceNumber(carplaceNumber);
    }
    if (serviceChargeRate != null && serviceChargeRate > 0) {
      await setServiceChargeRate(serviceChargeRate);
    }
    if (emailCC != null && emailCC.isNotEmpty) {
      await setEmailCC(emailCC);
    }

    // Verify final state
    final verifyRememberTid = await getRememberTid();
    final verifyTid = await getTID();
    LogUtils.debugLog(
        '[RememberTID] clearSessionOnly END → rememberTid=$verifyRememberTid, TID=$verifyTid');
  }
}
