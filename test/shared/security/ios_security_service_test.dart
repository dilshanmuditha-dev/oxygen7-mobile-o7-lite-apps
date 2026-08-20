import 'package:flutter_test/flutter_test.dart';
import 'package:app/shared/security/ios_security_service.dart';

void main() {
  group('IOSSecurityAssessment', () {
    test('fromMap creates assessment with all fields', () {
      final map = {
        'overallStatus': 'secure',
        'isJailbroken': false,
        'isDebugging': false,
        'integrityValid': true,
        'runtimeSafe': true,
        'timestamp': 1704067200.0,
        'assessmentId': 'test-123',
        'jailbreakResult': {'isJailbroken': false},
        'debuggerResult': {'isDebugging': false},
        'integrityResult': {'isValid': true},
        'runtimeResult': {'isSafe': true},
      };

      final assessment = IOSSecurityAssessment.fromMap(map);

      expect(assessment.overallStatus, 'secure');
      expect(assessment.isJailbroken, false);
      expect(assessment.isDebugging, false);
      expect(assessment.integrityValid, true);
      expect(assessment.runtimeSafe, true);
      expect(assessment.assessmentId, 'test-123');
      expect(assessment.jailbreakResult, isNotNull);
      expect(assessment.debuggerResult, isNotNull);
      expect(assessment.integrityResult, isNotNull);
      expect(assessment.runtimeResult, isNotNull);
    });

    test('fromMap handles missing fields with defaults', () {
      final map = <String, dynamic>{};

      final assessment = IOSSecurityAssessment.fromMap(map);

      expect(assessment.overallStatus, 'unknown');
      expect(assessment.isJailbroken, false);
      expect(assessment.isDebugging, false);
      expect(assessment.integrityValid, true);
      expect(assessment.runtimeSafe, true);
      expect(assessment.assessmentId, '');
    });

    test('fromMap handles compromised status', () {
      final map = {
        'overallStatus': 'compromised',
        'isJailbroken': true,
        'isDebugging': true,
        'integrityValid': false,
        'runtimeSafe': false,
        'timestamp': 1704067200.0,
        'assessmentId': 'compromised-123',
      };

      final assessment = IOSSecurityAssessment.fromMap(map);

      expect(assessment.overallStatus, 'compromised');
      expect(assessment.isJailbroken, true);
      expect(assessment.isDebugging, true);
      expect(assessment.integrityValid, false);
      expect(assessment.runtimeSafe, false);
      expect(assessment.isCompromised, true);
      expect(assessment.isSecure, false);
    });

    test('compromised factory creates error assessment', () {
      final assessment = IOSSecurityAssessment.compromised(
        reason: 'Test error',
      );

      expect(assessment.overallStatus, 'compromised');
      expect(assessment.integrityValid, false);
      expect(assessment.runtimeSafe, false);
      expect(assessment.isCompromised, true);
      expect(assessment.assessmentId, startsWith('error-'));
    });

    test('isSecure returns true only for secure status', () {
      final secureAssessment = IOSSecurityAssessment.fromMap({
        'overallStatus': 'secure',
      });
      final warningAssessment = IOSSecurityAssessment.fromMap({
        'overallStatus': 'warning',
      });
      final compromisedAssessment = IOSSecurityAssessment.fromMap({
        'overallStatus': 'compromised',
      });

      expect(secureAssessment.isSecure, true);
      expect(warningAssessment.isSecure, false);
      expect(compromisedAssessment.isSecure, false);
    });

    test('isWarning returns true only for warning status', () {
      final secureAssessment = IOSSecurityAssessment.fromMap({
        'overallStatus': 'secure',
      });
      final warningAssessment = IOSSecurityAssessment.fromMap({
        'overallStatus': 'warning',
      });

      expect(secureAssessment.isWarning, false);
      expect(warningAssessment.isWarning, true);
    });

    test('toString returns formatted string', () {
      final assessment = IOSSecurityAssessment.fromMap({
        'overallStatus': 'secure',
        'isJailbroken': false,
        'isDebugging': false,
        'integrityValid': true,
        'runtimeSafe': true,
      });

      final str = assessment.toString();

      expect(str, contains('secure'));
      expect(str, contains('jailbroken: false'));
      expect(str, contains('debugging: false'));
      expect(str, contains('integrity: true'));
      expect(str, contains('runtime: true'));
    });
  });

  group('IOSSecurityEvent', () {
    test('fromMap creates event with all fields', () {
      final map = {
        'id': 'event-123',
        'type': 'jailbreak_detected',
        'severity': 'critical',
        'message': 'Jailbreak detected',
        'details': {'indicator': 'cydia'},
        'timestamp': 1704067200.0,
      };

      final event = IOSSecurityEvent.fromMap(map);

      expect(event.id, 'event-123');
      expect(event.type, 'jailbreak_detected');
      expect(event.severity, 'critical');
      expect(event.message, 'Jailbreak detected');
      expect(event.details['indicator'], 'cydia');
    });

    test('fromMap handles missing fields with defaults', () {
      final map = <String, dynamic>{};

      final event = IOSSecurityEvent.fromMap(map);

      expect(event.id, '');
      expect(event.type, 'unknown');
      expect(event.severity, 'info');
      expect(event.message, '');
      expect(event.details, isEmpty);
    });

    test('isCritical returns true for critical severity', () {
      final criticalEvent = IOSSecurityEvent.fromMap({
        'severity': 'critical',
      });
      final highEvent = IOSSecurityEvent.fromMap({
        'severity': 'high',
      });

      expect(criticalEvent.isCritical, true);
      expect(highEvent.isCritical, false);
    });

    test('isHigh returns true for high severity', () {
      final highEvent = IOSSecurityEvent.fromMap({
        'severity': 'high',
      });
      final mediumEvent = IOSSecurityEvent.fromMap({
        'severity': 'medium',
      });

      expect(highEvent.isHigh, true);
      expect(mediumEvent.isHigh, false);
    });

    test('toString returns formatted string', () {
      final event = IOSSecurityEvent.fromMap({
        'type': 'jailbreak_detected',
        'severity': 'critical',
        'message': 'Test message',
      });

      final str = event.toString();

      expect(str, contains('jailbreak_detected'));
      expect(str, contains('critical'));
      expect(str, contains('Test message'));
    });
  });

  group('IOSSecurityConfiguration', () {
    test('default configuration has expected values', () {
      const config = IOSSecurityConfiguration();

      expect(config.jailbreakDetectionEnabled, true);
      expect(config.debuggerDetectionEnabled, true);
      expect(config.integrityCheckEnabled, true);
      expect(config.runtimeProtectionEnabled, true);
      expect(config.monitoringInterval, 30.0);
      expect(config.allowJailbrokenDevices, false);
      expect(config.expectedBundleIdentifier, isNull);
      expect(config.expectedTeamIdentifier, isNull);
    });

    test('custom configuration preserves values', () {
      const config = IOSSecurityConfiguration(
        jailbreakDetectionEnabled: false,
        debuggerDetectionEnabled: false,
        integrityCheckEnabled: false,
        runtimeProtectionEnabled: false,
        monitoringInterval: 60.0,
        allowJailbrokenDevices: true,
        expectedBundleIdentifier: 'com.test.app',
        expectedTeamIdentifier: 'TESTTEAM',
      );

      expect(config.jailbreakDetectionEnabled, false);
      expect(config.debuggerDetectionEnabled, false);
      expect(config.integrityCheckEnabled, false);
      expect(config.runtimeProtectionEnabled, false);
      expect(config.monitoringInterval, 60.0);
      expect(config.allowJailbrokenDevices, true);
      expect(config.expectedBundleIdentifier, 'com.test.app');
      expect(config.expectedTeamIdentifier, 'TESTTEAM');
    });

    test('toMap includes all fields', () {
      const config = IOSSecurityConfiguration(
        jailbreakDetectionEnabled: false,
        debuggerDetectionEnabled: true,
        integrityCheckEnabled: false,
        runtimeProtectionEnabled: true,
        monitoringInterval: 45.0,
        allowJailbrokenDevices: true,
        expectedBundleIdentifier: 'com.test.app',
        expectedTeamIdentifier: 'TESTTEAM',
      );

      final map = config.toMap();

      expect(map['jailbreakDetectionEnabled'], false);
      expect(map['debuggerDetectionEnabled'], true);
      expect(map['integrityCheckEnabled'], false);
      expect(map['runtimeProtectionEnabled'], true);
      expect(map['monitoringInterval'], 45.0);
      expect(map['allowJailbrokenDevices'], true);
      expect(map['expectedBundleIdentifier'], 'com.test.app');
      expect(map['expectedTeamIdentifier'], 'TESTTEAM');
    });

    test('toMap excludes null optional fields', () {
      const config = IOSSecurityConfiguration();

      final map = config.toMap();

      expect(map.containsKey('expectedBundleIdentifier'), false);
      expect(map.containsKey('expectedTeamIdentifier'), false);
    });
  });
}
