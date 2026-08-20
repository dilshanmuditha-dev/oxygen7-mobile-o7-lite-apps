import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/shared/security/dependency_audit.dart';
import 'package:app/shared/security/audit_utils.dart';

/// Tests for Dependency Audit Models and Utilities
///
/// Feature: legacy-encryption-remediation
/// Property 2: Audit Finding Completeness
/// Validates: Requirements 1.1, 1.2, 1.3
void main() {
  group('DependencyAudit Models', () {
    group('Property 2: Audit Finding Completeness', () {
      /// Property test: Every CryptoFinding must have non-empty
      /// algorithm, location, and description
      test('all findings have required fields (100 iterations)', () {
        final random = Random(42);

        for (var i = 0; i < 100; i++) {
          final algorithm = legacyEncryptionPatterns[
              random.nextInt(legacyEncryptionPatterns.length)];
          final filePath = _randomFilePath(random);
          final isDirectUsage = random.nextBool();

          final finding = createFinding(
            algorithm: algorithm,
            filePath: filePath,
            isDirectUsage: isDirectUsage,
          );

          // Property: All required fields must be non-empty
          expect(finding.algorithm, isNotEmpty,
              reason: 'Finding must have algorithm');
          expect(finding.location, isNotEmpty,
              reason: 'Finding must have location');
          expect(finding.description, isNotEmpty,
              reason: 'Finding must have description');
        }
      });

      /// Property test: DependencyAuditResult must have package name and version
      test('audit results have package identification (100 iterations)', () {
        final random = Random(42);

        for (var i = 0; i < 100; i++) {
          final packageName = _randomPackageName(random);
          final version = _randomVersion(random);
          final findings = _generateRandomFindings(random);

          final result = createAuditResult(
            packageName: packageName,
            version: version,
            findings: findings,
          );

          // Property: Package identification must be present
          expect(result.packageName, isNotEmpty,
              reason: 'Result must have package name');
          expect(result.version, isNotEmpty,
              reason: 'Result must have version');
          expect(result.findings, isNotNull,
              reason: 'Result must have findings list');
        }
      });

      /// Property test: Severity is always assigned based on findings
      test('severity classification is consistent (100 iterations)', () {
        final random = Random(42);

        for (var i = 0; i < 100; i++) {
          final findings = _generateRandomFindings(random);

          final result = createAuditResult(
            packageName: 'test_package',
            version: '1.0.0',
            findings: findings,
          );

          // Property: Severity must be a valid enum value
          expect(AuditSeverity.values, contains(result.severity));

          // Property: Empty findings should have low severity
          if (findings.isEmpty) {
            expect(result.severity, equals(AuditSeverity.low));
          }
        }
      });
    });

    group('CryptoFinding', () {
      test('creates finding with all required fields', () {
        const finding = CryptoFinding(
          algorithm: 'DES',
          location: 'lib/crypto.dart',
          description: 'Direct usage of DES detected',
          isDirectUsage: true,
        );

        expect(finding.algorithm, equals('DES'));
        expect(finding.location, equals('lib/crypto.dart'));
        expect(finding.description, isNotEmpty);
        expect(finding.isDirectUsage, isTrue);
      });

      test('toString includes algorithm and location', () {
        const finding = CryptoFinding(
          algorithm: 'RC4',
          location: 'src/encryption.java',
          description: 'RC4 usage found',
          isDirectUsage: false,
        );

        expect(finding.toString(), contains('RC4'));
        expect(finding.toString(), contains('src/encryption.java'));
      });
    });

    group('DependencyAuditResult', () {
      test('hasFindings returns true when findings exist', () {
        final result = DependencyAuditResult(
          packageName: 'test_pkg',
          version: '1.0.0',
          findings: const [
            CryptoFinding(
              algorithm: 'DES',
              location: 'test.dart',
              description: 'Test',
              isDirectUsage: true,
            ),
          ],
          severity: AuditSeverity.high,
        );

        expect(result.hasFindings, isTrue);
      });

      test('hasFindings returns false when no findings', () {
        const result = DependencyAuditResult(
          packageName: 'test_pkg',
          version: '1.0.0',
          findings: [],
          severity: AuditSeverity.low,
        );

        expect(result.hasFindings, isFalse);
      });

      test('requiresAction for critical severity', () {
        const result = DependencyAuditResult(
          packageName: 'test_pkg',
          version: '1.0.0',
          findings: [],
          severity: AuditSeverity.critical,
        );

        expect(result.requiresAction, isTrue);
      });

      test('requiresAction for high severity', () {
        const result = DependencyAuditResult(
          packageName: 'test_pkg',
          version: '1.0.0',
          findings: [],
          severity: AuditSeverity.high,
        );

        expect(result.requiresAction, isTrue);
      });

      test('does not require action for medium/low severity', () {
        const mediumResult = DependencyAuditResult(
          packageName: 'test_pkg',
          version: '1.0.0',
          findings: [],
          severity: AuditSeverity.medium,
        );

        const lowResult = DependencyAuditResult(
          packageName: 'test_pkg',
          version: '1.0.0',
          findings: [],
          severity: AuditSeverity.low,
        );

        expect(mediumResult.requiresAction, isFalse);
        expect(lowResult.requiresAction, isFalse);
      });
    });

    group('SecurityAuditReport', () {
      test('passesCompliance when all secure', () {
        final report = SecurityAuditReport(
          auditDate: DateTime.now(),
          appVersion: '1.0.0',
          dependencyFindings: const [],
          networkStatus: const NetworkSecurityStatus(
            tlsMinVersionEnforced: true,
            legacyCiphersBlocked: true,
            cleartextBlocked: true,
            allowedCipherSuites: ['TLS_AES_256_GCM_SHA384'],
          ),
          webViewStatus: const WebViewSecurityStatus(
            mixedContentBlocked: true,
            safeBrowsingEnabled: true,
            inAppWebViewVersion: '6.0.0',
            hasKnownVulnerabilities: false,
          ),
        );

        expect(report.passesCompliance, isTrue);
      });

      test('fails compliance when network insecure', () {
        final report = SecurityAuditReport(
          auditDate: DateTime.now(),
          appVersion: '1.0.0',
          dependencyFindings: const [],
          networkStatus: const NetworkSecurityStatus(
            tlsMinVersionEnforced: false,
            legacyCiphersBlocked: true,
            cleartextBlocked: true,
            allowedCipherSuites: [],
          ),
          webViewStatus: const WebViewSecurityStatus(
            mixedContentBlocked: true,
            safeBrowsingEnabled: true,
            inAppWebViewVersion: '6.0.0',
            hasKnownVulnerabilities: false,
          ),
        );

        expect(report.passesCompliance, isFalse);
      });

      test('fails compliance with critical findings', () {
        final report = SecurityAuditReport(
          auditDate: DateTime.now(),
          appVersion: '1.0.0',
          dependencyFindings: const [
            DependencyAuditResult(
              packageName: 'bad_pkg',
              version: '1.0.0',
              findings: [],
              severity: AuditSeverity.critical,
            ),
          ],
          networkStatus: const NetworkSecurityStatus(
            tlsMinVersionEnforced: true,
            legacyCiphersBlocked: true,
            cleartextBlocked: true,
            allowedCipherSuites: [],
          ),
          webViewStatus: const WebViewSecurityStatus(
            mixedContentBlocked: true,
            safeBrowsingEnabled: true,
            inAppWebViewVersion: '6.0.0',
            hasKnownVulnerabilities: false,
          ),
        );

        expect(report.passesCompliance, isFalse);
      });

      test('totalFindings counts all findings', () {
        final report = SecurityAuditReport(
          auditDate: DateTime.now(),
          appVersion: '1.0.0',
          dependencyFindings: const [
            DependencyAuditResult(
              packageName: 'pkg1',
              version: '1.0.0',
              findings: [
                CryptoFinding(
                  algorithm: 'DES',
                  location: 'a.dart',
                  description: 'Test',
                  isDirectUsage: false,
                ),
                CryptoFinding(
                  algorithm: 'RC4',
                  location: 'b.dart',
                  description: 'Test',
                  isDirectUsage: false,
                ),
              ],
              severity: AuditSeverity.low,
            ),
            DependencyAuditResult(
              packageName: 'pkg2',
              version: '2.0.0',
              findings: [
                CryptoFinding(
                  algorithm: 'ECB',
                  location: 'c.dart',
                  description: 'Test',
                  isDirectUsage: false,
                ),
              ],
              severity: AuditSeverity.low,
            ),
          ],
          networkStatus: const NetworkSecurityStatus(
            tlsMinVersionEnforced: true,
            legacyCiphersBlocked: true,
            cleartextBlocked: true,
            allowedCipherSuites: [],
          ),
          webViewStatus: const WebViewSecurityStatus(
            mixedContentBlocked: true,
            safeBrowsingEnabled: true,
            inAppWebViewVersion: '6.0.0',
            hasKnownVulnerabilities: false,
          ),
        );

        expect(report.totalFindings, equals(3));
      });
    });
  });

  group('Audit Utilities', () {
    group('detectLegacyPatterns', () {
      test('detects DES pattern', () {
        final patterns = detectLegacyPatterns('Using DES encryption');
        expect(patterns, contains('DES'));
      });

      test('detects RC4 pattern', () {
        final patterns = detectLegacyPatterns('RC4 cipher suite');
        expect(patterns, contains('RC4'));
      });

      test('detects ECB pattern', () {
        final patterns = detectLegacyPatterns('AES/ECB/PKCS5Padding');
        expect(patterns, contains('ECB'));
      });

      test('detects multiple patterns', () {
        final patterns = detectLegacyPatterns('DES and RC4 and ECB modes');
        expect(patterns, containsAll(['DES', 'RC4', 'ECB']));
      });

      test('returns empty for secure content', () {
        final patterns = detectLegacyPatterns('AES-256-GCM encryption');
        expect(patterns, isEmpty);
      });

      test('is case-insensitive', () {
        final patterns = detectLegacyPatterns('des rc4 ecb');
        expect(patterns, containsAll(['DES', 'RC4', 'ECB']));
      });
    });

    group('classifySeverity', () {
      test('critical for direct usage in app code', () {
        final severity = classifySeverity(
          algorithm: 'DES',
          isDirectUsage: true,
          isInAppCode: true,
        );
        expect(severity, equals(AuditSeverity.critical));
      });

      test('high for direct usage in dependency', () {
        final severity = classifySeverity(
          algorithm: 'RC4',
          isDirectUsage: true,
          isInAppCode: false,
        );
        expect(severity, equals(AuditSeverity.high));
      });

      test('medium for reference in app code', () {
        final severity = classifySeverity(
          algorithm: 'ECB',
          isDirectUsage: false,
          isInAppCode: true,
        );
        expect(severity, equals(AuditSeverity.medium));
      });

      test('low for reference in dependency', () {
        final severity = classifySeverity(
          algorithm: 'DES',
          isDirectUsage: false,
          isInAppCode: false,
        );
        expect(severity, equals(AuditSeverity.low));
      });
    });

    group('createFinding', () {
      test('creates finding with direct usage description', () {
        final finding = createFinding(
          algorithm: 'DES',
          filePath: 'lib/crypto.dart',
          isDirectUsage: true,
        );

        expect(finding.algorithm, equals('DES'));
        expect(finding.location, equals('lib/crypto.dart'));
        expect(finding.description, contains('Direct usage'));
        expect(finding.isDirectUsage, isTrue);
      });

      test('creates finding with reference description', () {
        final finding = createFinding(
          algorithm: 'RC4',
          filePath: 'lib/utils.dart',
          isDirectUsage: false,
        );

        expect(finding.description, contains('Reference'));
        expect(finding.isDirectUsage, isFalse);
      });

      test('uses custom context when provided', () {
        final finding = createFinding(
          algorithm: 'ECB',
          filePath: 'lib/test.dart',
          isDirectUsage: true,
          context: 'Custom description',
        );

        expect(finding.description, equals('Custom description'));
      });
    });

    group('isLikelyDirectUsage', () {
      test('detects Cipher.getInstance as direct usage', () {
        const content = 'Cipher cipher = Cipher.getInstance("DES/ECB/PKCS5");';
        final result = isLikelyDirectUsage(content, 'DES', 35);
        expect(result, isTrue);
      });

      test('detects SDK version check as informational', () {
        const content =
            'if (Build.VERSION.SDK_INT >= 23) { // DES deprecated }';
        final result = isLikelyDirectUsage(content, 'DES', 42);
        expect(result, isFalse);
      });
    });

    group('createAuditResult', () {
      test('creates result with correct severity aggregation', () {
        final findings = [
          const CryptoFinding(
            algorithm: 'DES',
            location: 'a.java',
            description: 'Test',
            isDirectUsage: true,
          ),
          const CryptoFinding(
            algorithm: 'RC4',
            location: 'b.java',
            description: 'Test',
            isDirectUsage: false,
          ),
        ];

        final result = createAuditResult(
          packageName: 'test_pkg',
          version: '1.0.0',
          findings: findings,
        );

        // Should be high (direct usage in dependency)
        expect(result.severity, equals(AuditSeverity.high));
      });

      test('empty findings result in low severity', () {
        final result = createAuditResult(
          packageName: 'clean_pkg',
          version: '2.0.0',
          findings: [],
        );

        expect(result.severity, equals(AuditSeverity.low));
      });
    });
  });
}

// Helper functions for property tests

String _randomFilePath(Random random) {
  final dirs = ['lib', 'src', 'android', 'ios'];
  final extensions = ['.dart', '.java', '.kt', '.swift'];
  final dir = dirs[random.nextInt(dirs.length)];
  final name = _randomString(random, 8);
  final ext = extensions[random.nextInt(extensions.length)];
  return '$dir/$name$ext';
}

String _randomPackageName(Random random) {
  final prefixes = ['flutter', 'dart', 'android', 'ios'];
  final suffixes = ['utils', 'crypto', 'security', 'network'];
  return '${prefixes[random.nextInt(prefixes.length)]}_${suffixes[random.nextInt(suffixes.length)]}';
}

String _randomVersion(Random random) {
  return '${random.nextInt(10)}.${random.nextInt(10)}.${random.nextInt(10)}';
}

List<CryptoFinding> _generateRandomFindings(Random random) {
  final count = random.nextInt(5);
  return List.generate(count, (_) {
    final algorithm = legacyEncryptionPatterns[
        random.nextInt(legacyEncryptionPatterns.length)];
    return createFinding(
      algorithm: algorithm,
      filePath: _randomFilePath(random),
      isDirectUsage: random.nextBool(),
    );
  });
}

String _randomString(Random random, int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz';
  return String.fromCharCodes(
    Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
  );
}
