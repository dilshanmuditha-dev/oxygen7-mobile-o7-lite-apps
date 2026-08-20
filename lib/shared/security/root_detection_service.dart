import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

/// Multi-layered root/jailbreak detection service.
///
/// Combines multiple detection methods to provide robust detection that
/// cannot be easily bypassed by disabling a single library or check.
/// Returns `true` if ANY detection method returns positive (device is rooted).
///
/// Detection layers:
/// 1. Primary: `flutter_jailbreak_detection` library
/// 2. Secondary: Su binary existence check
/// 3. Secondary: Magisk presence check
/// 4. Secondary: Build properties test-keys check
/// 5. Secondary: Dangerous root management apps check
///
/// Each check is wrapped in try-catch so individual failures don't prevent
/// other checks from running.
class RootDetectionService {
  static RootDetectionService? _instance;

  RootDetectionService._();

  /// Gets the singleton instance.
  static RootDetectionService get instance {
    _instance ??= RootDetectionService._();
    return _instance!;
  }

  /// Resets the singleton instance (for testing).
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  /// Known paths where the `su` binary may exist on rooted Android devices.
  static const List<String> _suBinaryPaths = [
    '/system/bin/su',
    '/system/xbin/su',
    '/sbin/su',
    '/system/su',
    '/system/bin/.ext/.su',
    '/system/usr/we-need-root/su-backup',
    '/system/xbin/mu',
  ];

  /// Known paths indicating Magisk is installed.
  static const List<String> _magiskPaths = [
    '/sbin/.magisk',
    '/data/adb/magisk',
    '/data/adb/magisk.db',
    '/cache/.disable_magisk',
  ];

  /// Package names of common root management apps.
  static const List<String> _dangerousAppPackages = [
    'com.noshufou.android.su', // SuperSU
    'com.noshufou.android.su.elite', // SuperSU Elite
    'eu.chainfire.supersu', // SuperSU (ChainFire)
    'com.koushikdutta.superuser', // Superuser
    'com.thirdparty.superuser', // Superuser (third-party)
    'com.topjohnwu.magisk', // Magisk Manager
    'com.kingroot.kinguser', // KingRoot
    'com.kingo.root', // KingoRoot
    'com.smedialink.oneclickroot', // One Click Root
    'com.zhiqupk.root.global', // Root Master
    'com.alephzain.framaroot', // Framaroot
  ];

  /// Performs multi-layered root/jailbreak detection.
  ///
  /// Callable from multiple entry points: startup, app resume, or before
  /// sensitive operations. Returns `true` if ANY detection method returns
  /// positive, indicating the device is compromised.
  Future<bool> isDeviceRooted() async {
    // On iOS, only use the primary library check since secondary
    // checks are Android-specific.
    if (Platform.isIOS) {
      return await _checkPrimaryLibrary();
    }

    // On Android, run all detection layers.
    if (await _checkPrimaryLibrary()) return true;
    if (_checkSuBinaryExists()) return true;
    if (_checkMagiskPresence()) return true;
    if (await _checkBuildTestKeys()) return true;
    if (_checkDangerousApps()) return true;

    return false;
  }

  /// Primary detection: Uses `flutter_jailbreak_detection` library.
  Future<bool> _checkPrimaryLibrary() async {
    try {
      return await FlutterJailbreakDetection.jailbroken;
    } catch (e) {
      debugPrint('[RootDetection] Primary library check failed: $e');
      return false;
    }
  }

  /// Secondary detection: Checks for su binary existence at known paths.
  bool _checkSuBinaryExists() {
    try {
      for (final path in _suBinaryPaths) {
        if (File(path).existsSync()) {
          debugPrint('[RootDetection] Su binary found at: $path');
          return true;
        }
      }
    } catch (e) {
      debugPrint('[RootDetection] Su binary check failed: $e');
    }
    return false;
  }

  /// Secondary detection: Checks for Magisk presence at known paths.
  bool _checkMagiskPresence() {
    try {
      for (final path in _magiskPaths) {
        if (File(path).existsSync() || Directory(path).existsSync()) {
          debugPrint('[RootDetection] Magisk presence found at: $path');
          return true;
        }
      }
    } catch (e) {
      debugPrint('[RootDetection] Magisk presence check failed: $e');
    }
    return false;
  }

  /// Secondary detection: Checks build properties for test-keys.
  ///
  /// Production Android builds use "release-keys". Rooted or custom ROMs
  /// often have "test-keys" in `ro.build.tags`.
  Future<bool> _checkBuildTestKeys() async {
    try {
      final result = await Process.run('getprop', ['ro.build.tags']);
      final output = result.stdout.toString().trim().toLowerCase();
      if (output.contains('test-keys')) {
        debugPrint('[RootDetection] Build tags contain test-keys: $output');
        return true;
      }
    } catch (e) {
      debugPrint('[RootDetection] Build properties check failed: $e');
    }
    return false;
  }

  /// Secondary detection: Checks for dangerous root management apps.
  ///
  /// Looks for known root management app data directories under
  /// `/data/data/` which indicates they are or were installed.
  bool _checkDangerousApps() {
    try {
      for (final packageName in _dangerousAppPackages) {
        final appDir = Directory('/data/data/$packageName');
        if (appDir.existsSync()) {
          debugPrint('[RootDetection] Dangerous app found: $packageName');
          return true;
        }
      }
    } catch (e) {
      debugPrint('[RootDetection] Dangerous apps check failed: $e');
    }
    return false;
  }
}
