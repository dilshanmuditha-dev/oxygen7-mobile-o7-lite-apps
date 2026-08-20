import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Bug Condition Exploration Tests — Rooted Device Data Protection
///
/// These tests encode the EXPECTED SECURE BEHAVIOR for the rooted device
/// vulnerability. They are written BEFORE implementing fixes and are
/// EXPECTED TO FAIL on unfixed code — failure confirms the vulnerability exists.
///
/// After fixes are applied (Task 3), these same tests should PASS,
/// confirming all vulnerabilities are resolved.
///
/// **Validates: Requirements 1.1, 1.3, 1.4**
///
/// Property 1: Bug Condition — Rooted Device Allows Normal App Usage & Exposes Plaintext Data
///
/// Bug Condition:
///   isBugCondition(input) where input.deviceIsRooted == true
///   AND (appAllowsNormalUsage(input) OR dataIsPlaintext(input.storagePath))
///
/// Two concrete sub-conditions:
///   1. Root detection bypass: Single-library detection can be bypassed;
///      no secondary checks (su binary, Magisk, test-keys) exist
///   2. Plaintext data exposure: clearSecureSharedPef() does not recursively
///      delete ALL files — only specific patterns are matched
void main() {
  // ==========================================================================
  // Sub-Condition 1: Root Detection Bypass — No Multi-Layered Detection
  //
  // The current code relies SOLELY on FlutterJailbreakDetection.jailbroken.
  // Expected behavior: A dedicated RootDetectionService should exist with
  // multiple detection methods (su binary, Magisk, test-keys) so that even
  // if the primary library is bypassed, secondary checks catch rooted devices.
  // ==========================================================================
  group('Sub-Condition 1: Root Detection Bypass — Multi-Layered Detection', () {
    test(
        'A dedicated RootDetectionService exists with multi-layered detection methods',
        () {
      // Expected: lib/shared/security/root_detection_service.dart exists
      final serviceFile =
          File('lib/shared/security/root_detection_service.dart');

      expect(
        serviceFile.existsSync(),
        isTrue,
        reason:
            'RootDetectionService should exist at lib/shared/security/root_detection_service.dart.\n'
            'Counterexample: No multi-layered root detection service exists — '
            'the app relies solely on flutter_jailbreak_detection which is a single-point-of-failure',
      );
    });

    test('RootDetectionService checks su binary paths as secondary detection',
        () {
      final serviceFile =
          File('lib/shared/security/root_detection_service.dart');

      if (!serviceFile.existsSync()) {
        fail(
          'RootDetectionService does not exist.\n'
          'Counterexample: No su binary check — attacker can bypass single-library '
          'detection while /system/bin/su or /system/xbin/su exist on device',
        );
      }

      final content = serviceFile.readAsStringSync();

      // Expected: service checks for su binary at known paths
      final checksSuBinary = content.contains('/system/bin/su') ||
          content.contains('/system/xbin/su') ||
          content.contains('/sbin/su');

      expect(
        checksSuBinary,
        isTrue,
        reason:
            'RootDetectionService should check for su binary at common paths.\n'
            'Counterexample: No su binary existence check — single-library detection '
            'can be fooled while su binary remains accessible at /system/bin/su',
      );
    });

    test(
        'RootDetectionService checks for Magisk presence as secondary detection',
        () {
      final serviceFile =
          File('lib/shared/security/root_detection_service.dart');

      if (!serviceFile.existsSync()) {
        fail(
          'RootDetectionService does not exist.\n'
          'Counterexample: No Magisk check — devices rooted with Magisk can '
          'bypass flutter_jailbreak_detection while /sbin/.magisk exists',
        );
      }

      final content = serviceFile.readAsStringSync();

      // Expected: service checks for Magisk indicators
      final checksMagisk = content.contains('magisk') ||
          content.contains('Magisk') ||
          content.contains('.magisk');

      expect(
        checksMagisk,
        isTrue,
        reason: 'RootDetectionService should check for Magisk presence.\n'
            'Counterexample: No Magisk detection — Magisk Hide can defeat '
            'flutter_jailbreak_detection while /sbin/.magisk or /data/adb/magisk exists',
      );
    });

    test('RootDetectionService checks build properties for test-keys', () {
      final serviceFile =
          File('lib/shared/security/root_detection_service.dart');

      if (!serviceFile.existsSync()) {
        fail(
          'RootDetectionService does not exist.\n'
          'Counterexample: No test-keys check — custom ROMs with test-keys '
          'in ro.build.tags can bypass library detection',
        );
      }

      final content = serviceFile.readAsStringSync();

      // Expected: service checks build tags for test-keys
      final checksTestKeys = content.contains('test-keys') ||
          content.contains('ro.build.tags') ||
          content.contains('getprop');

      expect(
        checksTestKeys,
        isTrue,
        reason:
            'RootDetectionService should check build properties for test-keys.\n'
            'Counterexample: No test-keys check in build properties — '
            'ro.build.tags containing "test-keys" indicates custom/rooted ROM '
            'but is not verified',
      );
    });

    test(
        'mainCommon() uses RootDetectionService instead of direct FlutterJailbreakDetection',
        () {
      final mainCommonFile = File('lib/main_common.dart');
      expect(mainCommonFile.existsSync(), isTrue);

      final content = mainCommonFile.readAsStringSync();

      // Expected: mainCommon uses multi-layered RootDetectionService
      final usesRootDetectionService = content.contains('RootDetectionService');

      expect(
        usesRootDetectionService,
        isTrue,
        reason:
            'mainCommon() should use RootDetectionService for multi-layered detection.\n'
            'Counterexample: mainCommon() directly calls FlutterJailbreakDetection.jailbroken '
            'which is a single-point-of-failure — if this one library is bypassed, '
            'no other detection method catches the rooted device',
      );
    });
  });

  // ==========================================================================
  // Sub-Condition 2: Warning Screen Dismissible via Back Button
  //
  // The current _RootedWarningScreen has a Scaffold with AppBar but no
  // PopScope(canPop: false) wrapper. On Android, pressing the back button
  // can dismiss the screen and potentially allow navigation.
  // ==========================================================================
  group('Sub-Condition 2: Warning Screen — Back Button Not Blocked', () {
    test(
        '_RootedWarningScreen uses PopScope(canPop: false) to block back button',
        () {
      final mainCommonFile = File('lib/main_common.dart');
      expect(mainCommonFile.existsSync(), isTrue);

      final content = mainCommonFile.readAsStringSync();

      // Expected: PopScope with canPop: false wraps the warning screen
      final hasPopScope = content.contains('PopScope') &&
          content.contains('canPop') &&
          content.contains('false');

      // Alternative: WillPopScope for older Flutter versions
      final hasWillPopScope =
          content.contains('WillPopScope') && content.contains('onWillPop');

      expect(
        hasPopScope || hasWillPopScope,
        isTrue,
        reason:
            '_RootedWarningScreen should use PopScope(canPop: false) or WillPopScope '
            'to prevent dismissal via Android back button.\n'
            'Counterexample: _RootedWarningScreen has no PopScope/WillPopScope — '
            'pressing Android back button can dismiss the security warning screen '
            'and potentially allow navigation into the app on a rooted device',
      );
    });

    test(
        '_RootedWarningScreen does not have an AppBar (prevents navigation affordance)',
        () {
      final mainCommonFile = File('lib/main_common.dart');
      expect(mainCommonFile.existsSync(), isTrue);

      final content = mainCommonFile.readAsStringSync();

      // Extract the _RootedWarningScreen class content
      final classStart = content.indexOf('class _RootedWarningScreen');
      expect(classStart, isNot(-1),
          reason: '_RootedWarningScreen class must exist');

      // Find the build method content for _RootedWarningScreen
      final afterClass = content.substring(classStart);

      // Check if AppBar is used within the _RootedWarningScreen class
      // We need to scope this to just the _RootedWarningScreen class
      final nextClassOrEnd = afterClass.indexOf(
        RegExp(r'\nclass [A-Z]'),
        10, // skip past the class declaration itself
      );
      final classContent = nextClassOrEnd > 0
          ? afterClass.substring(0, nextClassOrEnd)
          : afterClass;

      final hasAppBar = classContent.contains('AppBar');

      expect(
        hasAppBar,
        isFalse,
        reason:
            '_RootedWarningScreen should NOT have an AppBar to prevent any navigation affordance.\n'
            'Counterexample: _RootedWarningScreen currently has AppBar with title, '
            'which provides a navigation target and implies the screen is a normal page '
            'rather than a security blocker',
      );
    });
  });

  // ==========================================================================
  // Sub-Condition 3: Incomplete File Cleanup — Not Recursive
  //
  // The current clearSecureSharedPef() only deletes files matching specific
  // patterns (PersistedInstallation, installation, firebase, .json) with
  // non-recursive listing (recursive: false). Files in subdirectories or
  // with other extensions can contain plaintext data and are NOT deleted.
  // ==========================================================================
  group('Sub-Condition 3: Plaintext Data Exposure — Incomplete File Cleanup',
      () {
    test(
        'clearSecureSharedPef() supports aggressive recursive wipe for rooted device context',
        () {
      final storageFile =
          File('lib/shared/secure_storage/secure_storage_service.dart');
      expect(storageFile.existsSync(), isTrue);

      final content = storageFile.readAsStringSync();

      // Expected: An aggressiveWipe parameter or similar mechanism for
      // recursive deletion of ALL files (not just pattern-matched ones)
      final hasAggressiveWipe = content.contains('aggressiveWipe') ||
          content.contains('aggressive') ||
          content.contains('recursiveDelete') ||
          content.contains('recursive: true');

      expect(
        hasAggressiveWipe,
        isTrue,
        reason:
            'clearSecureSharedPef() should support an aggressive recursive wipe mode '
            'for rooted device context that deletes ALL files in app directories.\n'
            'Counterexample: clearSecureSharedPef() uses list(recursive: false) and only '
            'deletes files matching PersistedInstallation/installation/firebase/.json patterns. '
            'Files in subdirectories or with other extensions (e.g., .xml, .db, .log) '
            'that may contain plaintext tokens are NOT deleted.',
      );
    });

    test('File cleanup does not use selective pattern matching (non-recursive)',
        () {
      final storageFile =
          File('lib/shared/secure_storage/secure_storage_service.dart');
      expect(storageFile.existsSync(), isTrue);

      final content = storageFile.readAsStringSync();

      // Bug condition: The code uses `list(recursive: false)` with specific
      // file name pattern checks — this misses files in subdirectories
      final usesNonRecursiveListing =
          content.contains('list(recursive: false)');
      final usesSelectivePatterns =
          content.contains("startsWith('PersistedInstallation')") ||
              content.contains("contains('installation')") ||
              content.contains("contains('firebase')") ||
              content.contains("endsWith('.json')");

      // In fixed code, when called from rooted device context, it should
      // recursively delete ALL files, not just pattern-matched ones.
      // The selective pattern approach is the bug condition for rooted devices.
      final hasRootedDeviceRecursiveWipe =
          content.contains('recursive: true') &&
              (content.contains('aggressiveWipe') ||
                  content.contains('deleteSync'));

      // If code still uses non-recursive selective patterns WITHOUT also having
      // a recursive wipe option, the bug condition exists
      if (usesNonRecursiveListing && usesSelectivePatterns) {
        expect(
          hasRootedDeviceRecursiveWipe,
          isTrue,
          reason:
              'When called from rooted device detection context, file cleanup should '
              'recursively delete ALL files, not just pattern-matched ones.\n'
              'Counterexample: clearSecureSharedPef() lists directories non-recursively '
              'and only deletes files matching specific patterns:\n'
              '  - startsWith("PersistedInstallation")\n'
              '  - contains("installation")\n'
              '  - contains("firebase")\n'
              '  - endsWith(".json")\n'
              'This leaves plaintext data in subdirectories and non-matching files '
              '(e.g., .xml, .db, cache files) intact and readable via adb shell.',
        );
      }
    });

    test(
        'mainCommon() calls clearSecureSharedPef with aggressive wipe on rooted detection',
        () {
      final mainCommonFile = File('lib/main_common.dart');
      expect(mainCommonFile.existsSync(), isTrue);

      final content = mainCommonFile.readAsStringSync();

      // Expected: When rooted device is detected, clearSecureSharedPef is called
      // with aggressiveWipe: true (or equivalent) to recursively delete all data
      final hasAggressiveWipeCall = content.contains('aggressiveWipe: true') ||
          content.contains('aggressiveWipe:true');

      expect(
        hasAggressiveWipeCall,
        isTrue,
        reason:
            'mainCommon() should call clearSecureSharedPef(aggressiveWipe: true) '
            'when a rooted device is detected.\n'
            'Counterexample: mainCommon() calls clearSecureSharedPef() without '
            'aggressive wipe flag — only selective file patterns are deleted, '
            'leaving third-party library files with plaintext tokens intact.',
      );
    });
  });
}
