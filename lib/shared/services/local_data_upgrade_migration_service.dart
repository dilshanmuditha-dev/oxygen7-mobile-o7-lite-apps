import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PosDeviceType {
  sunmi,
  landi,
  castle,
  anfu,
  wizarpos,
  coherent,
  mobile,
  unknown,
}

enum LocalDataUpgradeDecision {
  skip,
  markHandledOnly,
  wipeAndMarkHandled,
}

class LocalDataWipeRule {
  final PosDeviceType deviceType;
  final int encryptedBaselineVersionCode;
  final String markerKey;

  const LocalDataWipeRule({
    required this.deviceType,
    required this.encryptedBaselineVersionCode,
    required this.markerKey,
  });
}

class PosDeviceTypeDetector {
  static Future<PosDeviceType> detect() async {
    if (!Platform.isAndroid) {
      return PosDeviceType.unknown;
    }

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    return fromBrandModel(
      brand: androidInfo.brand,
      model: androidInfo.model,
    );
  }

  static PosDeviceType fromBrandModel({
    required String brand,
    required String model,
  }) {
    final normalizedBrand = brand.toLowerCase();
    final normalizedModel = model.toLowerCase();
    final combined = '$normalizedBrand $normalizedModel';

    if (combined.contains('sunmi')) {
      return PosDeviceType.sunmi;
    }
    if (combined.contains('landi')) {
      return PosDeviceType.landi;
    }
    if (combined.contains('castles') || combined.contains('castle')) {
      return PosDeviceType.castle;
    }
    if (combined.contains('anfu')) {
      return PosDeviceType.anfu;
    }
    if (combined.contains('wizarpos') ||
        combined.contains('wizar pos') ||
        combined.contains('wizar')) {
      return PosDeviceType.wizarpos;
    }
    if (combined.contains('coherent') || combined.contains('centerm')) {
      return PosDeviceType.coherent;
    }

    return PosDeviceType.mobile;
  }
}

class LocalDataUpgradeMigrationService {
  static const String _secureStorageMigrationCompleteKey =
      '_secure_storage_migrated_v2';
  static const String _lastSeenVersionPrefix = '_last_seen_version_code_';

  static const Map<PosDeviceType, LocalDataWipeRule> rules = {
    PosDeviceType.sunmi: LocalDataWipeRule(
      deviceType: PosDeviceType.sunmi,
      encryptedBaselineVersionCode: 78,
      markerKey: '_local_data_wipe_sunmi_v78_done',
    ),
    PosDeviceType.landi: LocalDataWipeRule(
      deviceType: PosDeviceType.landi,
      encryptedBaselineVersionCode: 78,
      markerKey: '_local_data_wipe_landi_v78_done',
    ),
    PosDeviceType.castle: LocalDataWipeRule(
      deviceType: PosDeviceType.castle,
      encryptedBaselineVersionCode: 60,
      markerKey: '_local_data_wipe_castle_v60_done',
    ),
    PosDeviceType.wizarpos: LocalDataWipeRule(
      deviceType: PosDeviceType.wizarpos,
      encryptedBaselineVersionCode: 59,
      markerKey: '_local_data_wipe_wizarpos_v59_done',
    ),
  };

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<void> runPreflight() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceType = await PosDeviceTypeDetector.detect();
      final currentVersionCode = await _getCurrentVersionCode();
      final lastSeenVersionKey = _lastSeenVersionKey(deviceType);
      final lastSeenVersionCode = prefs.getInt(lastSeenVersionKey);
      final rule = rules[deviceType];

      if (currentVersionCode <= 0) {
        return;
      }

      if (rule == null) {
        await prefs.setInt(lastSeenVersionKey, currentVersionCode);
        return;
      }

      final decision = decide(
        rule: rule,
        currentVersionCode: currentVersionCode,
        lastSeenVersionCode: lastSeenVersionCode,
        migrationDone: prefs.getBool(rule.markerKey) ?? false,
        legacyLocalDataExists: _hasLegacyLocalData(
          prefs,
          ignoredKeys: {
            rule.markerKey,
            lastSeenVersionKey,
          },
        ),
        secureStorageMigrationComplete:
            prefs.getBool(_secureStorageMigrationCompleteKey) ?? false,
      );

      switch (decision) {
        case LocalDataUpgradeDecision.wipeAndMarkHandled:
          await _wipeLocalData();
          final freshPrefs = await SharedPreferences.getInstance();
          await _markHandled(
            freshPrefs,
            rule: rule,
            lastSeenVersionKey: lastSeenVersionKey,
            currentVersionCode: currentVersionCode,
          );
          break;
        case LocalDataUpgradeDecision.markHandledOnly:
          await _markHandled(
            prefs,
            rule: rule,
            lastSeenVersionKey: lastSeenVersionKey,
            currentVersionCode: currentVersionCode,
          );
          break;
        case LocalDataUpgradeDecision.skip:
          await prefs.setInt(lastSeenVersionKey, currentVersionCode);
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocalDataUpgradeMigration] preflight failed: $e');
      }
    }
  }

  static LocalDataUpgradeDecision decide({
    required LocalDataWipeRule? rule,
    required int currentVersionCode,
    required int? lastSeenVersionCode,
    required bool migrationDone,
    required bool legacyLocalDataExists,
    required bool secureStorageMigrationComplete,
  }) {
    if (rule == null || migrationDone) {
      return LocalDataUpgradeDecision.skip;
    }

    if (currentVersionCode < rule.encryptedBaselineVersionCode) {
      return LocalDataUpgradeDecision.skip;
    }

    if (secureStorageMigrationComplete) {
      return LocalDataUpgradeDecision.markHandledOnly;
    }

    final crossedBaseline = lastSeenVersionCode != null &&
        lastSeenVersionCode < rule.encryptedBaselineVersionCode;
    final firstRunLegacyUpgrade =
        lastSeenVersionCode == null && legacyLocalDataExists;

    if (crossedBaseline || firstRunLegacyUpgrade) {
      return LocalDataUpgradeDecision.wipeAndMarkHandled;
    }

    return LocalDataUpgradeDecision.markHandledOnly;
  }

  static String _lastSeenVersionKey(PosDeviceType deviceType) {
    return '$_lastSeenVersionPrefix${deviceType.name}';
  }

  static bool _hasLegacyLocalData(
    SharedPreferences prefs, {
    required Set<String> ignoredKeys,
  }) {
    final ignored = {
      _secureStorageMigrationCompleteKey,
      ...ignoredKeys,
    };

    return prefs.getKeys().any((key) => !ignored.contains(key));
  }

  static Future<int> _getCurrentVersionCode() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return int.tryParse(packageInfo.buildNumber) ?? 0;
  }

  static Future<void> _markHandled(
    SharedPreferences prefs, {
    required LocalDataWipeRule rule,
    required String lastSeenVersionKey,
    required int currentVersionCode,
  }) async {
    await prefs.setBool(rule.markerKey, true);
    await prefs.setInt(lastSeenVersionKey, currentVersionCode);
  }

  static Future<void> _wipeLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.deleteAll();
    await prefs.clear();

    await _clearDirectoryContents(() => getTemporaryDirectory());
    await _clearDirectoryContents(() => getApplicationSupportDirectory());
    await _clearDirectoryContents(() => getApplicationDocumentsDirectory());
  }

  static Future<void> _clearDirectoryContents(
    Future<Directory> Function() getDirectory,
  ) async {
    try {
      final dir = await getDirectory();
      if (!dir.existsSync()) {
        return;
      }

      await for (final entity in dir.list(recursive: false)) {
        try {
          if (entity is File) {
            await entity.delete();
          } else if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        } catch (_) {
          // Best-effort cleanup. One locked file should not block app startup.
        }
      }
    } catch (_) {
      // Some platform directories may be unavailable during early startup.
    }
  }
}
