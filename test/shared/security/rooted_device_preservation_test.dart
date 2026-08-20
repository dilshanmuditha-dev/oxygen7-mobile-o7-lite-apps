import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/shared/secure_storage/i_secure_storage.dart';
import 'package:app/shared/secure_storage/secure_storage_service.dart';
import 'package:app/shared/secure_storage/migration_service.dart';
import 'package:app/shared/secure_storage/legacy_storage_adapter.dart';
import 'package:app/shared/secure_storage/storage_key.dart';

/// In-memory implementation of ISecureStorage for testing.
class MockSecureStorage implements ISecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      _storage.remove(key);
    } else {
      _storage[key] = value;
    }
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map.from(_storage);
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey(key);
  }
}

/// Preservation Property Tests — Rooted Device Data Protection (Spec 28)
///
/// These tests capture BASELINE BEHAVIOR of non-rooted device operations
/// on UNFIXED code. They are written BEFORE implementing fixes and are
/// EXPECTED TO PASS on unfixed code — passing confirms the behavior we
/// must preserve.
///
/// After fixes are applied (Task 3), these same tests should STILL PASS,
/// confirming no regressions were introduced.
///
/// **Validates: Requirements 3.1, 3.2, 3.3, 3.4**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // ==========================================================================
  // Property 2.1 — Storage Round-Trip Integrity
  // For all valid key-value pairs, write(key, value) → read(key) returns the
  // same value on a non-rooted device (storage round-trip integrity).
  // Validates: Requirements 3.1, 3.2
  // ==========================================================================
  group('Preservation 2.1 — Storage Round-Trip Integrity', () {
    late MockSecureStorage mockStorage;
    late SecureStorageService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockStorage = MockSecureStorage();
      final migrationService = MigrationService(
        legacyStorage: LegacyStorageAdapter(),
        newStorage: mockStorage,
      );
      service = SecureStorageService.createWithDependencies(
        storage: mockStorage,
        migrationService: migrationService,
      );
    });

    test('setAccessToken → getAccessToken returns same value', () async {
      // Observe: setAccessToken("test_token") → getAccessToken() returns "test_token"
      const token = 'test_token_abc123';
      await service.setAccessToken(token);
      final result = await service.getAccessToken();
      expect(result, equals(token));
    });

    test('setRefreshToken → getRefreshToken returns same value', () async {
      // Observe: setRefreshToken("refresh_123") → getRefreshToken() returns "refresh_123"
      const token = 'refresh_123';
      await service.setRefreshToken(token);
      final result = await service.getRefreshToken();
      expect(result, equals(token));
    });

    test('setTerminalDetail → getTerminalDetail returns same JSON', () async {
      // Observe: setTerminalDetail(jsonString) → getTerminalDetail() returns same JSON
      const jsonString =
          '{"terminalId":"T001","merchantName":"Test Shop","address":"123 Main St"}';
      await service.setTerminalDetail(jsonString);
      final result = await service.getTerminalDetail();
      expect(result, equals(jsonString));
    });

    test('setTID → getTID returns same value', () async {
      const tid = 'TID_12345';
      await service.setTID(tid);
      final result = await service.getTID();
      expect(result, equals(tid));
    });

    test('setOperatorId → getOperatorId returns same value', () async {
      const operatorId = 'operator_001';
      await service.setOperatorId(operatorId);
      final result = await service.getOperatorId();
      expect(result, equals(operatorId));
    });

    test('setPassword → getPassword returns same value', () async {
      const password = 'secureP@ss123!';
      await service.setPassword(password);
      final result = await service.getPassword();
      expect(result, equals(password));
    });

    test('setSignKey → getSignKey returns same value', () async {
      const signKey = 'hmac_key_abc_xyz_123';
      await service.setSignKey(signKey);
      final result = await service.getSignKey();
      expect(result, equals(signKey));
    });

    test(
        'property: for all valid string values, write then read returns same value',
        () async {
      // Property-based: test multiple diverse values to cover input space
      final testValues = [
        'simple',
        '',
        'with spaces and tabs\t',
        'unicode: 你好世界 🎉 日本語',
        'special: !@#\$%^&*()_+-=[]{}|;:,.<>?',
        'json: {"key":"value","num":42}',
        'a' * 5000, // Long string
        'line1\nline2\nline3', // Multi-line
        'token_eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0',
      ];

      for (final value in testValues) {
        await service.setAccessToken(value);
        final result = await service.getAccessToken();
        expect(result, equals(value),
            reason:
                'Round-trip failed for value: "${value.substring(0, value.length.clamp(0, 50))}"');
      }
    });

    test('property: multiple keys maintain isolation', () async {
      // Write to multiple different keys
      await service.setAccessToken('access_token_value');
      await service.setRefreshToken('refresh_token_value');
      await service.setTID('tid_value');
      await service.setOperatorId('operator_value');
      await service.setPassword('password_value');

      // All should return correct isolated values
      expect(await service.getAccessToken(), equals('access_token_value'));
      expect(await service.getRefreshToken(), equals('refresh_token_value'));
      expect(await service.getTID(), equals('tid_value'));
      expect(await service.getOperatorId(), equals('operator_value'));
      expect(await service.getPassword(), equals('password_value'));
    });

    test('setRememberTid → getRememberTid returns correct boolean', () async {
      await service.setRememberTid(true);
      expect(await service.getRememberTid(), equals(true));

      await service.setRememberTid(false);
      expect(await service.getRememberTid(), equals(false));
    });

    test('bluetooth printer settings round-trip correctly', () async {
      const name = 'Printer XP-80';
      const mac = 'AA:BB:CC:DD:EE:FF';
      await service.setBtPrinterName(name);
      await service.setBtPrinterMac(mac);
      expect(await service.getBtPrinterName(), equals(name));
      expect(await service.getBtPrinterMac(), equals(mac));
    });
  });

  // ==========================================================================
  // Property 2.2 — clearSecureSharedPef Preserves App Settings
  // For all clearSecureSharedPef() calls, app settings keys are always
  // preserved (language, darkMode, sound, animation, refundPassword,
  // emailReceipt, emailCC, minesec, refreshInterval, themeData, isGw3).
  // Validates: Requirements 3.1, 3.3
  // ==========================================================================
  group('Preservation 2.2 — clearSecureSharedPef Preserves App Settings', () {
    late MockSecureStorage mockStorage;
    late SecureStorageService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockStorage = MockSecureStorage();
      final migrationService = MigrationService(
        legacyStorage: LegacyStorageAdapter(),
        newStorage: mockStorage,
      );
      service = SecureStorageService.createWithDependencies(
        storage: mockStorage,
        migrationService: migrationService,
      );
    });

    test(
        'clearSecureSharedPef preserves all app settings while clearing session data',
        () async {
      // Observe: clearSecureSharedPef() preserves app settings while clearing session data

      // Set up app settings (should be preserved)
      await service.setSaveLanguage('en');
      await service.setLocateChangeLanguage('en_US');
      await service.setIndexChangeLanguage(2);
      await service.setLocalTitle('English');
      await service.setIsCheckDarkMode(true);
      await service.setIsEnableSound(true);
      await service.setApproveSound('custom_sound.mp3');
      await service.setIsEnableAppAnimation(true);
      await service.setSelectedAnimationStyle('fade');
      await service.setIsEnableRefundPassword(true);
      await service.setIsEnableEmailReceipt(true);
      await service.setIsEnableEmailCC(true);
      await service.setIsEnableMinesec(false);
      await service.setIsEnableRefreshInterval(true);
      await service.setThemeData('blue_theme');
      await service.setIsGw3(true);

      // Set up session data (should be cleared)
      await service.setAccessToken('session_token_xyz');
      await service.setRefreshToken('refresh_session_abc');
      await service.setPassword('my_password');
      await service.setTID('TID_999');

      // Execute clear
      await service.clearSecureSharedPef();

      // Verify app settings are PRESERVED
      expect(await service.getSaveLanguage(), equals('en'),
          reason: 'Language setting must be preserved');
      expect(await service.getLocateChangeLanguage(), equals('en_US'),
          reason: 'Locale setting must be preserved');
      expect(await service.getIndexChangeLanguage(), equals(2),
          reason: 'Language index must be preserved');
      expect(await service.getLocalTitle(), equals('English'),
          reason: 'Local title must be preserved');
      expect(await service.getIsCheckDarkMode(), equals(true),
          reason: 'Dark mode setting must be preserved');
      expect(await service.getIsEnableSound(), equals(true),
          reason: 'Sound setting must be preserved');
      expect(await service.getApproveSound(), equals('custom_sound.mp3'),
          reason: 'Approve sound must be preserved');
      expect(await service.getIsEnableAppAnimation(), equals(true),
          reason: 'Animation setting must be preserved');
      expect(await service.getSelectedAnimationStyle(), equals('fade'),
          reason: 'Animation style must be preserved');
      expect(await service.getIsEnableRefundPassword(), equals(true),
          reason: 'Refund password setting must be preserved');
      expect(await service.getIsEnableEmailReceipt(), equals(true),
          reason: 'Email receipt setting must be preserved');
      expect(await service.getIsEnableEmailCC(), equals(true),
          reason: 'Email CC setting must be preserved');
      expect(await service.getIsEnableMinesec(), equals(false),
          reason: 'Minesec setting must be preserved');
      expect(await service.getIsEnableRefreshInterval(), equals(true),
          reason: 'Refresh interval setting must be preserved');
      expect(await service.getThemeData(), equals('blue_theme'),
          reason: 'Theme data must be preserved');
      expect(await service.getIsGw3(), equals(true),
          reason: 'isGw3 setting must be preserved');

      // Verify session data is CLEARED
      expect(await service.getAccessToken(), isNull,
          reason: 'Access token must be cleared');
      expect(await service.getRefreshToken(), isNull,
          reason: 'Refresh token must be cleared');
      expect(await service.getPassword(), isNull,
          reason: 'Password must be cleared');
    });

    test(
        'property: for any combination of app settings values, all are preserved after clear',
        () async {
      // Property-based: test with various settings combinations
      final settingsCombinations = [
        {'language': 'zh', 'darkMode': false, 'sound': false, 'theme': 'dark'},
        {'language': 'ms', 'darkMode': true, 'sound': true, 'theme': 'red'},
        {'language': 'en', 'darkMode': false, 'sound': true, 'theme': null},
      ];

      for (final combo in settingsCombinations) {
        // Reset storage
        await mockStorage.deleteAll();

        // Set app settings
        await service.setSaveLanguage(combo['language'] as String?);
        await service.setIsCheckDarkMode(combo['darkMode'] as bool?);
        await service.setIsEnableSound(combo['sound'] as bool?);
        await service.setThemeData(combo['theme'] as String?);

        // Also set session data that should be cleared
        await service.setAccessToken('token_to_clear');
        await service.setSignKey('sign_key_to_clear');

        // Execute clear
        await service.clearSecureSharedPef();

        // Verify settings preserved
        expect(await service.getSaveLanguage(), equals(combo['language']),
            reason: 'Language must be preserved for combo: $combo');
        expect(await service.getIsCheckDarkMode(), equals(combo['darkMode']),
            reason: 'Dark mode must be preserved for combo: $combo');

        // Verify session cleared
        expect(await service.getAccessToken(), isNull,
            reason: 'Access token must be cleared for combo: $combo');
        expect(await service.getSignKey(), isNull,
            reason: 'Sign key must be cleared for combo: $combo');
      }
    });
  });

  // ==========================================================================
  // Property 2.3 — clearSessionOnly Preserves TID When rememberTid=true
  // For all clearSessionOnly() calls with rememberTid=true, TID and
  // operatorId are preserved.
  // Validates: Requirements 3.2, 3.4
  // ==========================================================================
  group('Preservation 2.3 — clearSessionOnly Preserves TID', () {
    late MockSecureStorage mockStorage;
    late SecureStorageService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockStorage = MockSecureStorage();
      final migrationService = MigrationService(
        legacyStorage: LegacyStorageAdapter(),
        newStorage: mockStorage,
      );
      service = SecureStorageService.createWithDependencies(
        storage: mockStorage,
        migrationService: migrationService,
      );
    });

    test('clearSessionOnly preserves TID and operatorId when rememberTid=true',
        () async {
      // Observe: clearSessionOnly() preserves rememberTid + TID + operatorId
      // when rememberTid is enabled

      // Set up session data
      await service.setRememberTid(true);
      await service.setTID('TID_PRESERVED');
      await service.setOperatorId('OP_PRESERVED');
      await service.setAccessToken('token_to_clear');
      await service.setRefreshToken('refresh_to_clear');
      await service.setPassword('password_to_clear');
      await service.setTerminalDetail('{"detail":"to_clear"}');

      // Execute session clear
      await service.clearSessionOnly();

      // Verify TID and operatorId are PRESERVED
      expect(await service.getRememberTid(), equals(true),
          reason: 'rememberTid must be preserved');
      expect(await service.getTID(), equals('TID_PRESERVED'),
          reason: 'TID must be preserved when rememberTid=true');
      expect(await service.getOperatorId(), equals('OP_PRESERVED'),
          reason: 'operatorId must be preserved when rememberTid=true');

      // Verify session data is CLEARED
      expect(await service.getAccessToken(), isNull,
          reason: 'Access token must be cleared');
      expect(await service.getRefreshToken(), isNull,
          reason: 'Refresh token must be cleared');
      expect(await service.getPassword(), isNull,
          reason: 'Password must be cleared');
      expect(await service.getTerminalDetail(), isNull,
          reason: 'Terminal detail must be cleared');
    });

    test('clearSessionOnly does NOT preserve TID when rememberTid=false',
        () async {
      // Set up with rememberTid disabled
      await service.setRememberTid(false);
      await service.setTID('TID_NOT_PRESERVED');
      await service.setOperatorId('OP_NOT_PRESERVED');
      await service.setAccessToken('token_to_clear');

      // Execute session clear
      await service.clearSessionOnly();

      // TID and operatorId should NOT be preserved when rememberTid=false
      expect(await service.getTID(), isNull,
          reason: 'TID must NOT be preserved when rememberTid=false');
      expect(await service.getOperatorId(), isNull,
          reason: 'operatorId must NOT be preserved when rememberTid=false');
    });

    test(
        'property: for all TID/operatorId values with rememberTid=true, values are preserved',
        () async {
      // Property-based: test with various TID and operatorId combinations
      final testCases = [
        {'tid': 'T001', 'operator': 'admin'},
        {'tid': 'T999', 'operator': 'user_123'},
        {'tid': 'TERMINAL_XYZ', 'operator': 'op_special!@#'},
        {'tid': '12345678', 'operator': '1'},
      ];

      for (final testCase in testCases) {
        // Reset
        await mockStorage.deleteAll();

        await service.setRememberTid(true);
        await service.setTID(testCase['tid']);
        await service.setOperatorId(testCase['operator']);
        await service.setAccessToken('some_token');
        await service.setRefreshToken('some_refresh');

        await service.clearSessionOnly();

        expect(await service.getTID(), equals(testCase['tid']),
            reason: 'TID "${testCase['tid']}" must be preserved');
        expect(await service.getOperatorId(), equals(testCase['operator']),
            reason: 'OperatorId "${testCase['operator']}" must be preserved');
        expect(await service.getAccessToken(), isNull,
            reason: 'Access token must be cleared');
      }
    });

    test(
        'clearSessionOnly preserves carplaceNumber, serviceChargeRate, emailCC',
        () async {
      await service.setCarplaceNumber('SGX1234A');
      await service.setServiceChargeRate(5);
      await service.setEmailCC('test@example.com');
      await service.setAccessToken('token_to_clear');

      await service.clearSessionOnly();

      expect(await service.getCarplaceNumber(), equals('SGX1234A'),
          reason: 'carplaceNumber must be preserved');
      expect(await service.getServiceChargeRate(), equals(5),
          reason: 'serviceChargeRate must be preserved');
      expect(await service.getEmailCC(), equals('test@example.com'),
          reason: 'emailCC must be preserved');
    });
  });

  // ==========================================================================
  // Property 2.4 — Non-Rooted Device Launch Proceeds Normally
  // For all non-rooted device launches, mainCommon() proceeds to
  // runApp(App(flavor)) without showing warning screen.
  // Validates: Requirements 3.1, 3.4
  // ==========================================================================
  group('Preservation 2.4 — Non-Rooted Device Normal Launch Flow', () {
    test(
        'mainCommon() has root detection that only blocks when jailbroken is true',
        () {
      // Observe: on non-rooted devices, mainCommon() proceeds to runApp(App(flavor))
      // without showing warning screen.
      //
      // We verify this by inspecting the main_common.dart source to confirm:
      // 1. Root detection only triggers when device is rooted (isRooted/isJailbroken == true)
      // 2. The fallback on exception is false (safe default - not blocking non-rooted devices)
      // 3. When NOT rooted, code proceeds to DependencyInjection.init()
      //    and runApp(App(flavor))

      final mainCommonFile = File('lib/main_common.dart');
      expect(mainCommonFile.existsSync(), isTrue,
          reason: 'main_common.dart must exist');

      final content = mainCommonFile.readAsStringSync();

      // Verify root detection exists (multi-layered via RootDetectionService)
      expect(
          content.contains('RootDetectionService') ||
              content.contains('FlutterJailbreakDetection.jailbroken'),
          isTrue,
          reason:
              'Root detection must exist (via RootDetectionService or FlutterJailbreakDetection)');

      // Verify safe default: on exception, assume NOT rooted to avoid false positives
      expect(
          content.contains('isRooted = false') ||
              content.contains('isJailbroken = false'),
          isTrue,
          reason:
              'On detection failure, must default to false (not blocking non-rooted devices)');

      // Verify the blocking only happens when device IS rooted
      expect(
          content.contains('if (isRooted)') ||
              content.contains('if (isJailbroken)'),
          isTrue,
          reason:
              'Blocking logic must be gated on root detection result == true');

      // Verify normal flow proceeds to runApp(App(flavor))
      expect(content.contains('runApp(App(flavor))'), isTrue,
          reason: 'Non-rooted devices must proceed to runApp(App(flavor))');

      // Verify DependencyInjection.init() runs in normal flow
      expect(content.contains('DenpendencyInjection.init()'), isTrue,
          reason: 'Dependency injection must be initialized for normal flow');

      // Verify SecureStorageService.getInstance() runs in normal flow
      expect(content.contains('SecureStorageService.getInstance()'), isTrue,
          reason: 'SecureStorageService must be initialized for normal flow');
    });

    test('_RootedWarningScreen is only shown when device IS rooted', () {
      // Verify the warning screen is only instantiated in the rooted branch
      final mainCommonFile = File('lib/main_common.dart');
      final content = mainCommonFile.readAsStringSync();

      // The warning screen runApp must be inside the `if (isRooted)` block
      // Verify it exists after the root detection check
      final rootedBlockIndex = content.indexOf('if (isRooted)') > -1
          ? content.indexOf('if (isRooted)')
          : content.indexOf('if (isJailbroken)');
      final warningScreenIndex = content.indexOf('_RootedWarningScreen');
      final normalRunAppIndex = content.indexOf('runApp(App(flavor))');

      expect(rootedBlockIndex, greaterThan(-1),
          reason: 'Root/Jailbroken check must exist');
      expect(warningScreenIndex, greaterThan(rootedBlockIndex),
          reason:
              '_RootedWarningScreen must appear after the root detection check');
      expect(normalRunAppIndex, greaterThan(warningScreenIndex),
          reason:
              'Normal runApp must appear after the warning screen (in the else/after branch)');
    });

    test('non-rooted flow initializes all required services', () {
      // Verify that the normal (non-rooted) flow initializes all services
      final mainCommonFile = File('lib/main_common.dart');
      final content = mainCommonFile.readAsStringSync();

      // After the jailbroken check (and return), the normal flow should:
      // 1. Initialize dependencies
      expect(content.contains('DenpendencyInjection.init()'), isTrue);
      expect(content.contains('DenpendencyInjection.inject(flavor)'), isTrue);

      // 2. Initialize device detection and memory management
      expect(content.contains('DevicePerformanceDetector.instance'), isTrue);
      expect(content.contains('MemoryManager.instance'), isTrue);

      // 3. Initialize secure storage
      expect(content.contains('SecureStorageService.getInstance()'), isTrue);

      // 4. Restore language preference
      expect(content.contains('TranslationService.initFromSavedPreference()'),
          isTrue);

      // 5. Launch app
      expect(content.contains('runApp(App(flavor))'), isTrue);
    });
  });
}
