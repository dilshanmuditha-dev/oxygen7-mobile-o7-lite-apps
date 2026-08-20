import 'package:app/models/response/termnial_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'secure_shared_preferences.dart';

class SharedPrefManager {
  SharedPrefManager._privateConstructor();

  static final SharedPrefManager instance =
      SharedPrefManager._privateConstructor();

  static SharedPreferences? _sharedPreferences;

  /// In-memory cache for terminalID.
  ///
  /// This allows synchronous access to the terminal ID value while the
  /// actual data is stored in encrypted secure storage (flutter_secure_storage).
  /// The cache is populated during [migrateTerminalID] at app startup.
  static String _cachedTerminalID = '';

  static Future<SharedPreferences> init() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();

    return _sharedPreferences!;
  }

  /// Migrates terminalID from plain SharedPreferences to SecureSharedPreferences.
  ///
  /// This method should be called once during app initialization (after [init]).
  /// It performs the following:
  /// 1. Reads the terminal ID from SecureSharedPreferences (if already migrated)
  /// 2. If not found in secure storage, reads from old SharedPreferences location
  /// 3. If found in SharedPreferences, writes to SecureStorage and deletes from SharedPreferences
  /// 4. Populates the in-memory cache for synchronous access
  ///
  /// This ensures no re-login is required after migration — the value is preserved.
  static Future<void> migrateTerminalID() async {
    // First, check if the value already exists in secure storage
    final secureValue = await SecureSharedPreferences.instance.getTerminalID();
    if (secureValue != null && secureValue.isNotEmpty) {
      _cachedTerminalID = secureValue;

      // Clean up old SharedPreferences entry if it still exists
      final oldKey = MCP_TERMINAL_ID;
      if (_sharedPreferences?.containsKey(oldKey) == true) {
        await _sharedPreferences?.remove(oldKey);
      }
      return;
    }

    // Not in secure storage — check old SharedPreferences location for migration
    final oldKey = MCP_TERMINAL_ID;
    final plainValue = _sharedPreferences?.getString(oldKey);
    if (plainValue != null && plainValue.isNotEmpty) {
      // Migrate: write to secure storage, then delete from SharedPreferences
      await SecureSharedPreferences.instance.setTerminalID(plainValue);
      await _sharedPreferences?.remove(oldKey);
      _cachedTerminalID = plainValue;
    }
  }

  /// Migrates all app settings from plain SharedPreferences to encrypted
  /// secure storage. Called once at app startup after [init].
  ///
  /// For each key, if the value exists in plain SharedPreferences but not
  /// in secure storage, it is migrated and then removed from SharedPreferences.
  static Future<void> migrateAppSettings() async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();

    // Migrate string settings
    await _migrateString(
        prefs,
        'saveLanguage',
        () => SecureSharedPreferences.instance.getSaveLanguage(),
        (v) => SecureSharedPreferences.instance.setSaveLanguage(v));
    await _migrateString(
        prefs,
        'locateChangeLanguage',
        () => SecureSharedPreferences.instance.getLocateChangeLanguage(),
        (v) => SecureSharedPreferences.instance.setLocateChangeLanguage(v));
    await _migrateString(
        prefs,
        'localTitle',
        () => SecureSharedPreferences.instance.getLocalTitle(),
        (v) => SecureSharedPreferences.instance.setLocalTitle(v));
    await _migrateString(
        prefs,
        'approveSound',
        () => SecureSharedPreferences.instance.getApproveSound(),
        (v) => SecureSharedPreferences.instance.setApproveSound(v));
    await _migrateString(
        prefs,
        'selectedAnimationStyle',
        () => SecureSharedPreferences.instance.getSelectedAnimationStyle(),
        (v) => SecureSharedPreferences.instance.setSelectedAnimationStyle(v));

    // Migrate int settings
    final indexVal = prefs.getInt('indexChangeLanguage');
    if (indexVal != null) {
      await SecureSharedPreferences.instance.setIndexChangeLanguage(indexVal);
      await prefs.remove('indexChangeLanguage');
    }

    // Migrate bool settings
    await _migrateBool(prefs, 'isCheckDarkMode',
        (v) => SecureSharedPreferences.instance.setIsCheckDarkMode(v));
    await _migrateBool(prefs, 'isEnableSound',
        (v) => SecureSharedPreferences.instance.setIsEnableSound(v));
    await _migrateBool(prefs, 'isEnableAppAnimation',
        (v) => SecureSharedPreferences.instance.setIsEnableAppAnimation(v));
    await _migrateBool(prefs, 'isEnableRefundPassword',
        (v) => SecureSharedPreferences.instance.setIsEnableRefundPassword(v));
    await _migrateBool(prefs, 'isEnableEmailReceipt',
        (v) => SecureSharedPreferences.instance.setIsEnableEmailReceipt(v));
    await _migrateBool(prefs, 'isEnableEmailCC',
        (v) => SecureSharedPreferences.instance.setIsEnableEmailCC(v));
    await _migrateBool(prefs, 'isEnableMinesec',
        (v) => SecureSharedPreferences.instance.setIsEnableMinesec(v));
    await _migrateBool(prefs, 'isEnableRefreshInterval',
        (v) => SecureSharedPreferences.instance.setIsEnableRefreshInterval(v));
  }

  static Future<void> _migrateString(
    SharedPreferences prefs,
    String key,
    Future<String?> Function() getSecure,
    Future<void> Function(String) setSecure,
  ) async {
    final secureValue = await getSecure();
    if (secureValue != null && secureValue.isNotEmpty) {
      // Already migrated — just clean up old key
      if (prefs.containsKey(key)) {
        await prefs.remove(key);
      }
      return;
    }
    final plainValue = prefs.getString(key);
    if (plainValue != null && plainValue.isNotEmpty) {
      await setSecure(plainValue);
      await prefs.remove(key);
    }
  }

  static Future<void> _migrateBool(
    SharedPreferences prefs,
    String key,
    Future<void> Function(bool) setSecure,
  ) async {
    final plainValue = prefs.getBool(key);
    if (plainValue != null) {
      await setSecure(plainValue);
      await prefs.remove(key);
    }
  }

  // ============================================================
  // Generic methods — now delegate to SecureSharedPreferences
  // ============================================================

  Future<void> setString(String key, String value) async {
    switch (key) {
      case 'saveLanguage':
        await SecureSharedPreferences.instance.setSaveLanguage(value);
        break;
      case 'approveSound':
        await SecureSharedPreferences.instance.setApproveSound(value);
        break;
      case 'selectedAnimationStyle':
        await SecureSharedPreferences.instance.setSelectedAnimationStyle(value);
        break;
      case 'locateChangeLanguage':
        await SecureSharedPreferences.instance.setLocateChangeLanguage(value);
        break;
      case 'localTitle':
        await SecureSharedPreferences.instance.setLocalTitle(value);
        break;
      default:
        await SecureSharedPreferences.instance.setThemeData(value);
        break;
    }
  }

  Future<String?> getString(String key) async {
    switch (key) {
      case 'saveLanguage':
        return await SecureSharedPreferences.instance.getSaveLanguage();
      case 'approveSound':
        return await SecureSharedPreferences.instance.getApproveSound();
      case 'selectedAnimationStyle':
        return await SecureSharedPreferences.instance
            .getSelectedAnimationStyle();
      case 'locateChangeLanguage':
        return await SecureSharedPreferences.instance.getLocateChangeLanguage();
      case 'localTitle':
        return await SecureSharedPreferences.instance.getLocalTitle();
      default:
        return null;
    }
  }

  Future<void> setBool(String key, bool value) async {
    switch (key) {
      case 'isCheckDarkMode':
        await SecureSharedPreferences.instance.setIsCheckDarkMode(value);
        break;
      case 'isEnableSound':
        await SecureSharedPreferences.instance.setIsEnableSound(value);
        break;
      case 'isEnableAppAnimation':
        await SecureSharedPreferences.instance.setIsEnableAppAnimation(value);
        break;
      case 'isEnableRefundPassword':
        await SecureSharedPreferences.instance.setIsEnableRefundPassword(value);
        break;
      case 'isEnableEmailReceipt':
        await SecureSharedPreferences.instance.setIsEnableEmailReceipt(value);
        break;
      case 'isEnableEmailCC':
        await SecureSharedPreferences.instance.setIsEnableEmailCC(value);
        break;
      case 'isEnableMinesec':
        await SecureSharedPreferences.instance.setIsEnableMinesec(value);
        break;
      case 'isEnableRefreshInterval':
        await SecureSharedPreferences.instance
            .setIsEnableRefreshInterval(value);
        break;
      default:
        break;
    }
  }

  Future<bool?> getBool(String key) async {
    switch (key) {
      case 'isCheckDarkMode':
        return await SecureSharedPreferences.instance.getIsCheckDarkMode();
      case 'isEnableSound':
        return await SecureSharedPreferences.instance.getIsEnableSound();
      case 'isEnableAppAnimation':
        return await SecureSharedPreferences.instance.getIsEnableAppAnimation();
      case 'isEnableRefundPassword':
        return await SecureSharedPreferences.instance
            .getIsEnableRefundPassword();
      case 'isEnableEmailReceipt':
        return await SecureSharedPreferences.instance.getIsEnableEmailReceipt();
      case 'isEnableEmailCC':
        return await SecureSharedPreferences.instance.getIsEnableEmailCC();
      case 'isEnableMinesec':
        return await SecureSharedPreferences.instance.getIsEnableMinesec();
      case 'isEnableRefreshInterval':
        return await SecureSharedPreferences.instance
            .getIsEnableRefreshInterval();
      default:
        return null;
    }
  }

  Future<void> setInt(String key, int value) async {
    switch (key) {
      case 'indexChangeLanguage':
        await SecureSharedPreferences.instance.setIndexChangeLanguage(value);
        break;
      default:
        break;
    }
  }

  Future<int?> getInt(String key) async {
    switch (key) {
      case 'indexChangeLanguage':
        return await SecureSharedPreferences.instance.getIndexChangeLanguage();
      default:
        return null;
    }
  }

  Future<void> clear(String key) async {
    // For clearing, delegate to the appropriate secure storage setter with null
    switch (key) {
      case 'saveLanguage':
        await SecureSharedPreferences.instance.setSaveLanguage(null);
        break;
      case 'approveSound':
        await SecureSharedPreferences.instance.setApproveSound(null);
        break;
      default:
        break;
    }
  }

  Future<int> getIndexChangeLanguage() async {
    return await SecureSharedPreferences.instance.getIndexChangeLanguage();
  }

  Future<void> setLocalTitleChangeLanguage(String localTitle) async {
    await SecureSharedPreferences.instance.setLocalTitle(localTitle);
  }

  Future<String> getLocalTitleChangeLanguage() async {
    return await SecureSharedPreferences.instance.getLocalTitle() ?? 'English';
  }

  Future<void> setIndexChangeLanguage(int index) async {
    await SecureSharedPreferences.instance.setIndexChangeLanguage(index);
  }

  Future<void> setChangeLanguage(String locate) async {
    await SecureSharedPreferences.instance.setLocateChangeLanguage(locate);
  }

  Future<String?> getChangeLanguage() async {
    return await SecureSharedPreferences.instance.getLocateChangeLanguage() ??
        'en_US';
  }

  Future<String> getCashierSound() async {
    return await SecureSharedPreferences.instance.getApproveSound();
  }

  Future<bool> getRefreshInterval() async {
    return await SecureSharedPreferences.instance.getIsEnableRefreshInterval();
  }

  // save terminal detail
  Future<void> setTerminalDetail(TerminalDetail terminalDetail) async {
    await SecureSharedPreferences.instance
        .setCountryCodeAlpha(terminalDetail.merchant.countryCodeAlpha ?? '');
    await SecureSharedPreferences.instance
        .setMerchantShorName(terminalDetail.merchant.name);

    var terminalDetailJson = jsonEncode(terminalDetail.toJson());
    await SecureSharedPreferences.instance
        .setTerminalDetail(terminalDetailJson);
  }

  // get terminal detail
  Future<TerminalDetail?> getTerminalDetail() async {
    var terminalDetailJson =
        await SecureSharedPreferences.instance.getTerminalDetail();
    if (terminalDetailJson != null) {
      return TerminalDetail.fromJson(jsonDecode(terminalDetailJson));
    }
    return null;
  }

  /// Returns the terminal ID from the in-memory cache.
  static String get terminalID => _cachedTerminalID;

  /// Stores the terminal ID in both the in-memory cache and SecureSharedPreferences.
  static set setTerminalID(String value) {
    _cachedTerminalID = value;
    SecureSharedPreferences.instance.setTerminalID(value);
  }

  /// Stores the refresh token in encrypted secure storage.
  static Future<void> setRefreshTokenSecure(String? token) async {
    await SecureSharedPreferences.instance.setRefreshToken(token);
  }

  /// Retrieves the refresh token from encrypted secure storage.
  static Future<String?> getRefreshTokenSecure() async {
    return await SecureSharedPreferences.instance.getRefreshToken();
  }

  /// Clears only session-related data while preserving app settings.
  Future<void> clearSessionOnly() async {
    // Clean up any remaining plain SharedPreferences legacy data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('terminalDetail');
    await prefs.remove('refreshToken');

    // Clear from secure storage
    await SecureSharedPreferences.instance.setTerminalDetail(null);
    await SecureSharedPreferences.instance.setRefreshToken(null);

    // Reset the in-memory terminal ID cache
    _cachedTerminalID = '';
  }
}
