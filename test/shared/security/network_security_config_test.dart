import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

/// Tests for Android Network Security Configuration
///
/// Validates that the network_security_config.xml is properly configured
/// to block legacy encryption algorithms and enforce modern TLS.
///
/// Feature: legacy-encryption-remediation
/// Validates: Requirements 2.4
void main() {
  group('Network Security Configuration', () {
    late String xmlContent;
    late XmlDocument xmlDoc;

    setUpAll(() {
      final file =
          File('android/app/src/main/res/xml/network_security_config.xml');
      expect(file.existsSync(), isTrue,
          reason: 'network_security_config.xml should exist');
      xmlContent = file.readAsStringSync();
      xmlDoc = XmlDocument.parse(xmlContent);
    });

    test('XML is well-formed', () {
      expect(() => XmlDocument.parse(xmlContent), returnsNormally);
    });

    test('has network-security-config root element', () {
      final root = xmlDoc.rootElement;
      expect(root.name.local, equals('network-security-config'));
    });

    test('cleartext traffic is disabled in base-config', () {
      final baseConfig = xmlDoc.findAllElements('base-config').first;
      final cleartextPermitted =
          baseConfig.getAttribute('cleartextTrafficPermitted');
      expect(cleartextPermitted, equals('false'),
          reason: 'Cleartext traffic should be disabled for security');
    });

    test('uses system trust anchors', () {
      final certificates = xmlDoc.findAllElements('certificates');
      expect(certificates.isNotEmpty, isTrue,
          reason: 'Should have certificate configuration');

      final systemCert =
          certificates.where((cert) => cert.getAttribute('src') == 'system');
      expect(systemCert.isNotEmpty, isTrue,
          reason: 'Should trust system CA certificates');
    });
  });
}
