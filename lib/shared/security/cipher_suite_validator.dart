/// Cipher Suite Validator for Legacy Encryption Remediation
///
/// This class provides validation utilities to detect and block legacy
/// encryption algorithms (DES, RC4, ECB) that are vulnerable to attacks.
///
/// Feature: legacy-encryption-remediation
/// Validates: Requirements 2.1, 2.2, 2.3, 5.3
import 'package:app/shared/utils/log_utils.dart';

class CipherSuiteValidator {
  /// Blocked cipher patterns that indicate legacy/vulnerable algorithms
  ///
  /// These patterns are case-insensitive and will cause a cipher suite
  /// to be rejected if found anywhere in the cipher suite name.
  static const List<String> blockedPatterns = [
    'DES', // Data Encryption Standard - broken 56-bit cipher
    'RC4', // Rivest Cipher 4 - deprecated by RFC 7465
    'ECB', // Electronic Codebook mode - reveals patterns
    'MD5', // Message Digest 5 - collision vulnerabilities
    'EXPORT', // Export-grade ciphers - intentionally weak
    'NULL', // No encryption
    'anon', // Anonymous key exchange - no authentication
  ];

  /// Modern cipher suites that are considered secure
  ///
  /// These use AES-GCM or ChaCha20-Poly1305 with strong key exchange.
  static const List<String> allowedCipherSuites = [
    'TLS_AES_256_GCM_SHA384', // TLS 1.3
    'TLS_AES_128_GCM_SHA256', // TLS 1.3
    'TLS_CHACHA20_POLY1305_SHA256', // TLS 1.3
    'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
    'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256',
    'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
    'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256',
  ];

  /// Callback for logging warnings when legacy ciphers are detected
  static void Function(String message)? onWarning;

  /// Checks if a cipher suite is allowed (not blocked)
  ///
  /// Returns true if the cipher suite does not contain any blocked patterns.
  /// Returns false and triggers a warning if a blocked pattern is found.
  ///
  /// [cipherSuite] The cipher suite name to validate (e.g., "TLS_RSA_WITH_DES_CBC_SHA")
  static bool isAllowedCipherSuite(String cipherSuite) {
    final upperCipher = cipherSuite.toUpperCase();

    for (final pattern in blockedPatterns) {
      if (upperCipher.contains(pattern.toUpperCase())) {
        _logWarning(
            'Blocked cipher suite detected: $cipherSuite (contains $pattern)');
        return false;
      }
    }
    return true;
  }

  /// Checks if a cipher suite contains a specific blocked pattern
  ///
  /// [cipherSuite] The cipher suite name to check
  /// [pattern] The specific pattern to look for
  static bool containsBlockedPattern(String cipherSuite, String pattern) {
    return cipherSuite.toUpperCase().contains(pattern.toUpperCase());
  }

  /// Validates a list of cipher suites and returns only the allowed ones
  ///
  /// [cipherSuites] List of cipher suite names to validate
  /// Returns a filtered list containing only allowed cipher suites
  static List<String> filterAllowedCipherSuites(List<String> cipherSuites) {
    return cipherSuites.where(isAllowedCipherSuite).toList();
  }

  /// Gets the reason why a cipher suite is blocked
  ///
  /// Returns the blocked pattern found, or null if the cipher is allowed
  static String? getBlockedReason(String cipherSuite) {
    final upperCipher = cipherSuite.toUpperCase();

    for (final pattern in blockedPatterns) {
      if (upperCipher.contains(pattern.toUpperCase())) {
        return pattern;
      }
    }
    return null;
  }

  static void _logWarning(String message) {
    onWarning?.call(message);
    // ignore: avoid_print
    LogUtils.debugLog('[CipherSuiteValidator] WARNING: $message');
  }
}
