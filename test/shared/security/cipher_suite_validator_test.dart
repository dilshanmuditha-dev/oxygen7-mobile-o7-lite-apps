import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/shared/security/cipher_suite_validator.dart';

/// Tests for CipherSuiteValidator
///
/// Feature: legacy-encryption-remediation
/// Property 1: Cipher Suite Exclusion
/// Validates: Requirements 2.1, 2.2, 2.3
void main() {
  group('CipherSuiteValidator', () {
    group('Property 1: Cipher Suite Exclusion', () {
      /// Property test: For any cipher suite in the allowed list,
      /// it should NOT contain any blocked patterns
      test('allowed cipher suites do not contain blocked patterns', () {
        for (final cipherSuite in CipherSuiteValidator.allowedCipherSuites) {
          for (final pattern in CipherSuiteValidator.blockedPatterns) {
            expect(
              cipherSuite.toUpperCase().contains(pattern.toUpperCase()),
              isFalse,
              reason:
                  'Allowed cipher "$cipherSuite" should not contain blocked pattern "$pattern"',
            );
          }
        }
      });

      /// Property test with random cipher suite generation
      /// Validates: Requirements 2.1, 2.2, 2.3
      test('blocked patterns are always detected (100 iterations)', () {
        final random = Random(42); // Fixed seed for reproducibility

        for (var i = 0; i < 100; i++) {
          // Pick a random blocked pattern
          final pattern = CipherSuiteValidator.blockedPatterns[
              random.nextInt(CipherSuiteValidator.blockedPatterns.length)];

          // Generate a cipher suite containing the pattern
          final prefix = _randomString(random, 5);
          final suffix = _randomString(random, 5);
          final cipherSuite = 'TLS_${prefix}_WITH_${pattern}_$suffix';

          expect(
            CipherSuiteValidator.isAllowedCipherSuite(cipherSuite),
            isFalse,
            reason:
                'Cipher "$cipherSuite" containing "$pattern" should be blocked',
          );
        }
      });
    });

    group('Unit Tests - DES blocking', () {
      test('blocks DES cipher suites', () {
        expect(
            CipherSuiteValidator.isAllowedCipherSuite(
                'TLS_RSA_WITH_DES_CBC_SHA'),
            isFalse);
        expect(
            CipherSuiteValidator.isAllowedCipherSuite(
                'TLS_RSA_WITH_3DES_EDE_CBC_SHA'),
            isFalse);
      });
    });

    group('Unit Tests - RC4 blocking', () {
      test('blocks RC4 cipher suites', () {
        expect(
            CipherSuiteValidator.isAllowedCipherSuite(
                'TLS_RSA_WITH_RC4_128_SHA'),
            isFalse);
        expect(
            CipherSuiteValidator.isAllowedCipherSuite(
                'TLS_RSA_WITH_RC4_128_MD5'),
            isFalse);
      });
    });

    group('Unit Tests - ECB blocking', () {
      test('blocks ECB mode ciphers', () {
        expect(
            CipherSuiteValidator.isAllowedCipherSuite(
                'TLS_RSA_WITH_AES_128_ECB'),
            isFalse);
      });
    });

    group('Unit Tests - Modern ciphers allowed', () {
      test('allows modern GCM ciphers', () {
        expect(
            CipherSuiteValidator.isAllowedCipherSuite('TLS_AES_256_GCM_SHA384'),
            isTrue);
        expect(
            CipherSuiteValidator.isAllowedCipherSuite(
                'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'),
            isTrue);
      });

      test('allows ChaCha20 ciphers', () {
        expect(
            CipherSuiteValidator.isAllowedCipherSuite(
                'TLS_CHACHA20_POLY1305_SHA256'),
            isTrue);
      });
    });

    group('Unit Tests - Case insensitivity', () {
      test('detection is case-insensitive', () {
        expect(
            CipherSuiteValidator.isAllowedCipherSuite(
                'tls_rsa_with_des_cbc_sha'),
            isFalse);
        expect(
            CipherSuiteValidator.isAllowedCipherSuite(
                'TLS_RSA_WITH_des_CBC_SHA'),
            isFalse);
      });
    });

    group('getBlockedReason', () {
      test('returns the blocked pattern', () {
        expect(
            CipherSuiteValidator.getBlockedReason('TLS_RSA_WITH_DES_CBC_SHA'),
            equals('DES'));
        expect(
            CipherSuiteValidator.getBlockedReason('TLS_RSA_WITH_RC4_128_SHA'),
            equals('RC4'));
      });

      test('returns null for allowed ciphers', () {
        expect(CipherSuiteValidator.getBlockedReason('TLS_AES_256_GCM_SHA384'),
            isNull);
      });
    });
  });
}

String _randomString(Random random, int length) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  return String.fromCharCodes(
    Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
  );
}
