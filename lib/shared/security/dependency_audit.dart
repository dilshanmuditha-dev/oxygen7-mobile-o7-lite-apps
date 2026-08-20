/// Dependency Audit Models for Legacy Encryption Remediation
///
/// This file contains data models for tracking and reporting
/// security audit findings related to legacy encryption algorithms.
///
/// Feature: legacy-encryption-remediation
/// Validates: Requirements 1.1, 1.2, 1.3

/// Severity levels for audit findings
enum AuditSeverity {
  /// Direct usage of DES/RC4/ECB in application code
  critical,

  /// Transitive dependency with vulnerability
  high,

  /// Deprecated algorithm available but not actively used
  medium,

  /// Informational finding (e.g., SDK version checks)
  low,
}

/// Represents a single cryptographic finding in a dependency
class CryptoFinding {
  /// The algorithm detected (e.g., "DES", "RC4", "ECB")
  final String algorithm;

  /// File path where the algorithm was found
  final String location;

  /// Description of the finding
  final String description;

  /// Whether this is direct usage or just a reference
  final bool isDirectUsage;

  const CryptoFinding({
    required this.algorithm,
    required this.location,
    required this.description,
    required this.isDirectUsage,
  });

  @override
  String toString() => 'CryptoFinding($algorithm at $location)';
}

/// Result of auditing a single dependency
class DependencyAuditResult {
  /// Package name (e.g., "flutter_inappwebview")
  final String packageName;

  /// Package version
  final String version;

  /// List of cryptographic findings
  final List<CryptoFinding> findings;

  /// Overall severity of findings
  final AuditSeverity severity;

  /// Recommended version to update to (if available)
  final String? recommendedVersion;

  /// Mitigation strategy if update is not possible
  final String? mitigationStrategy;

  const DependencyAuditResult({
    required this.packageName,
    required this.version,
    required this.findings,
    required this.severity,
    this.recommendedVersion,
    this.mitigationStrategy,
  });

  /// Whether this dependency has any findings
  bool get hasFindings => findings.isNotEmpty;

  /// Whether this dependency has critical or high severity findings
  bool get requiresAction =>
      severity == AuditSeverity.critical || severity == AuditSeverity.high;

  @override
  String toString() =>
      'DependencyAuditResult($packageName@$version: ${findings.length} findings)';
}

/// Status of network security configuration
class NetworkSecurityStatus {
  /// Whether TLS 1.2+ is enforced
  final bool tlsMinVersionEnforced;

  /// Whether legacy ciphers are blocked
  final bool legacyCiphersBlocked;

  /// Whether cleartext traffic is blocked
  final bool cleartextBlocked;

  /// List of allowed cipher suites
  final List<String> allowedCipherSuites;

  const NetworkSecurityStatus({
    required this.tlsMinVersionEnforced,
    required this.legacyCiphersBlocked,
    required this.cleartextBlocked,
    required this.allowedCipherSuites,
  });

  /// Whether all security requirements are met
  bool get isSecure =>
      tlsMinVersionEnforced && legacyCiphersBlocked && cleartextBlocked;
}

/// Status of WebView security configuration
class WebViewSecurityStatus {
  /// Whether mixed content is blocked
  final bool mixedContentBlocked;

  /// Whether safe browsing is enabled
  final bool safeBrowsingEnabled;

  /// Version of flutter_inappwebview
  final String inAppWebViewVersion;

  /// Whether the version has known vulnerabilities
  final bool hasKnownVulnerabilities;

  const WebViewSecurityStatus({
    required this.mixedContentBlocked,
    required this.safeBrowsingEnabled,
    required this.inAppWebViewVersion,
    required this.hasKnownVulnerabilities,
  });

  /// Whether WebView security is properly configured
  bool get isSecure =>
      mixedContentBlocked && safeBrowsingEnabled && !hasKnownVulnerabilities;
}

/// Complete security audit report
class SecurityAuditReport {
  /// Date when the audit was performed
  final DateTime auditDate;

  /// Application version audited
  final String appVersion;

  /// Findings from dependency audit
  final List<DependencyAuditResult> dependencyFindings;

  /// Network security configuration status
  final NetworkSecurityStatus networkStatus;

  /// WebView security configuration status
  final WebViewSecurityStatus webViewStatus;

  /// Any errors encountered during audit
  final List<String> auditErrors;

  const SecurityAuditReport({
    required this.auditDate,
    required this.appVersion,
    required this.dependencyFindings,
    required this.networkStatus,
    required this.webViewStatus,
    this.auditErrors = const [],
  });

  /// Whether the application passes compliance requirements
  bool get passesCompliance {
    // Check network security
    if (!networkStatus.isSecure) return false;

    // Check WebView security
    if (!webViewStatus.isSecure) return false;

    // Check for critical/high severity findings
    final hasBlockingFindings = dependencyFindings.any((d) => d.requiresAction);
    if (hasBlockingFindings) return false;

    return true;
  }

  /// Count of total findings across all dependencies
  int get totalFindings =>
      dependencyFindings.fold(0, (sum, d) => sum + d.findings.length);

  /// Count of dependencies requiring action
  int get dependenciesRequiringAction =>
      dependencyFindings.where((d) => d.requiresAction).length;
}
