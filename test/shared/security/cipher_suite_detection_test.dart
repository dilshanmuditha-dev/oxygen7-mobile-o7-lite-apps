import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/shared/security/cipher_suite_validator.dart';

/// Property Test for Legacy Cipher Detection
///
/// Feature: legacy-encryption-remediation
/// Property 3: Legacy Cipher Detection and Warning
/// Validates: Requirements 5.2, 5.3
void main() {
  group('Property 3: Legacy Cipher Detection and Warning', () {
    late List<String> warnings;

    setUp(() {
      warnings = [];
      CipherSuiteValidator.onWarning = (msg) => warnings.add(msg);
    });

    tearDown(() {
      CipherSuiteValidator.onWarning = null;
    });

    /// Property test: For any cipher suite containing a blocked pattern,
    /// the function should return false and trigger a warning
    test('blocked patterns trigger warnings (100 iterations)', () {
      final random = Random(123);

      for (var i = 0; i < 100; i++) {
        warnings.clear();

        // Pick a random blocked pattern
        final pattern = CipherSuiteValidator.blockedPatterns[
            random.nextInt(CipherSuiteValidator.blockedPatterns.length)];

        // Generate cipher suite with the pattern
        final cipherSuite = 'TLS_TEST_WITH_${pattern}_CIPHER';

        final result = CipherSuiteValidator.isAllowedCipherSuite(cipherSuite);

        expect(result, isFalse,
            reason: 'Cipher with "$pattern" should be blocked');
        expect(warnings.isNotEmpty, isTrue,
            reason: 'Warning should be triggered for blocked cipher');
        expect(warnings.first.contains(pattern), isTrue,
            reason: 'Warning should mention the blocked pattern');
      }
    });

    /// Property test: For any cipher suite NOT containing blocked patterns,
    /// the function should return true and NOT trigger a warning
    test('allowed ciphers do not trigger warnings (100 iterations)', () {
      final random = Random(456);
      final safeComponents = [
        'AES',
        'GCM',
        'SHA256',
        'SHA384',
        'ECDHE',
        'RSA',
        'POLY1305'
      ];

      for (var i = 0; i < 100; i++) {
        warnings.clear();

        // Generate a safe cipher suite
        final comp1 = safeComponents[random.nextInt(safeComponents.length)];
        final comp2 = safeComponents[random.nextInt(safeComponents.length)];
        final cipherSuite = 'TLS_${comp1}_WITH_${comp2}_CIPHER';

        final result = CipherSuiteValidator.isAllowedCipherSuite(cipherSuite);

        expect(result, isTrue,
            reason: 'Cipher "$cipherSuite" should be allowed');
        expect(warnings.isEmpty, isTrue,
            reason: 'No warning should be triggered for allowed cipher');
      }
    });

    test('getBlockedReason returns correct pattern', () {
      for (final pattern in CipherSuiteValidator.blockedPatterns) {
        final cipherSuite = 'TLS_TEST_WITH_${pattern}_CIPHER';
        final reason = CipherSuiteValidator.getBlockedReason(cipherSuite);

        expect(reason, equals(pattern),
            reason: 'Should return "$pattern" as the blocked reason');
      }
    });

    test('filterAllowedCipherSuites removes all blocked ciphers', () {
      final mixedList = [
        'TLS_AES_256_GCM_SHA384', // allowed
        'TLS_RSA_WITH_DES_CBC_SHA', // blocked (DES)
        'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256', // allowed
        'TLS_RSA_WITH_RC4_128_SHA', // blocked (RC4)
        'TLS_CHACHA20_POLY1305_SHA256', // allowed
      ];

      final filtered =
          CipherSuiteValidator.filterAllowedCipherSuites(mixedList);

      expect(filtered.length, equals(3));
      expect(filtered, contains('TLS_AES_256_GCM_SHA384'));
      expect(filtered, contains('TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'));
      expect(filtered, contains('TLS_CHACHA20_POLY1305_SHA256'));
      expect(filtered, isNot(contains('TLS_RSA_WITH_DES_CBC_SHA')));
      expect(filtered, isNot(contains('TLS_RSA_WITH_RC4_128_SHA')));
    });
  });
}
