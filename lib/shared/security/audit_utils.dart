import 'dependency_audit.dart';

/// Utility functions for security auditing
///
/// Feature: legacy-encryption-remediation
/// Validates: Requirements 1.1, 1.3

/// Patterns that indicate legacy/vulnerable encryption algorithms
const List<String> legacyEncryptionPatterns = [
  'DES',
  'RC4',
  'ECB',
  '3DES',
  'MD5',
  'SHA1',
];

/// Detects legacy encryption patterns in a string (e.g., code content)
///
/// Returns a list of detected patterns
List<String> detectLegacyPatterns(String content) {
  final detected = <String>[];
  final upperContent = content.toUpperCase();

  for (final pattern in legacyEncryptionPatterns) {
    if (upperContent.contains(pattern.toUpperCase())) {
      detected.add(pattern);
    }
  }

  return detected;
}

/// Classifies the severity of a finding based on context
///
/// [algorithm] The detected algorithm
/// [isDirectUsage] Whether it's direct usage or just a reference
/// [isInAppCode] Whether it's in application code vs dependency
AuditSeverity classifySeverity({
  required String algorithm,
  required bool isDirectUsage,
  required bool isInAppCode,
}) {
  // Direct usage in app code is always critical
  if (isDirectUsage && isInAppCode) {
    return AuditSeverity.critical;
  }

  // Direct usage in dependency is high
  if (isDirectUsage && !isInAppCode) {
    return AuditSeverity.high;
  }

  // Reference in app code (e.g., comments, strings) is medium
  if (!isDirectUsage && isInAppCode) {
    return AuditSeverity.medium;
  }

  // Reference in dependency is low (informational)
  return AuditSeverity.low;
}

/// Creates a CryptoFinding from detected pattern
CryptoFinding createFinding({
  required String algorithm,
  required String filePath,
  required bool isDirectUsage,
  String? context,
}) {
  final description = isDirectUsage
      ? 'Direct usage of $algorithm detected'
      : 'Reference to $algorithm found (may be informational)';

  return CryptoFinding(
    algorithm: algorithm,
    location: filePath,
    description: context ?? description,
    isDirectUsage: isDirectUsage,
  );
}

/// Determines if a pattern match is likely direct usage vs informational
///
/// Heuristics:
/// - Cipher.getInstance("...") is direct usage
/// - SDK version checks are informational
/// - Comments are informational
bool isLikelyDirectUsage(String content, String pattern, int matchIndex) {
  // Check for common direct usage patterns
  final directUsagePatterns = [
    'Cipher.getInstance',
    'SecretKeySpec',
    'KeyGenerator',
    'encrypt',
    'decrypt',
  ];

  // Check surrounding context (100 chars before and after)
  final start = (matchIndex - 100).clamp(0, content.length);
  final end = (matchIndex + pattern.length + 100).clamp(0, content.length);
  final context = content.substring(start, end);

  // Check if it's in a comment
  if (context.contains('//') ||
      context.contains('/*') ||
      context.contains('*')) {
    // Might be a comment, check more carefully
    final beforeMatch = content.substring(start, matchIndex);
    if (beforeMatch.contains('//') && !beforeMatch.contains('\n')) {
      return false; // Single-line comment
    }
  }

  // Check for direct usage patterns
  for (final usagePattern in directUsagePatterns) {
    if (context.contains(usagePattern)) {
      return true;
    }
  }

  // Check for SDK version checks (informational)
  if (context.contains('VERSION') ||
      context.contains('SDK') ||
      context.contains('Build.')) {
    return false;
  }

  // Default to informational for safety
  return false;
}

/// Aggregates findings into a DependencyAuditResult
DependencyAuditResult createAuditResult({
  required String packageName,
  required String version,
  required List<CryptoFinding> findings,
  String? recommendedVersion,
  String? mitigationStrategy,
}) {
  // Determine overall severity (highest among findings)
  AuditSeverity severity = AuditSeverity.low;

  for (final finding in findings) {
    final findingSeverity = classifySeverity(
      algorithm: finding.algorithm,
      isDirectUsage: finding.isDirectUsage,
      isInAppCode: false, // Dependencies are not app code
    );

    if (findingSeverity.index < severity.index) {
      severity = findingSeverity;
    }
  }

  return DependencyAuditResult(
    packageName: packageName,
    version: version,
    findings: findings,
    severity: findings.isEmpty ? AuditSeverity.low : severity,
    recommendedVersion: recommendedVersion,
    mitigationStrategy: mitigationStrategy,
  );
}
