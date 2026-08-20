import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:app/shared/security/webview_security_config.dart';

/// Tests for WebViewSecurityConfig
///
/// Feature: legacy-encryption-remediation
/// Validates: Requirements 3.1, 3.2, 3.4
void main() {
  group('WebViewSecurityConfig', () {
    group('getSecureSettings', () {
      late InAppWebViewSettings settings;

      setUp(() {
        settings = WebViewSecurityConfig.getSecureSettings();
      });

      test('blocks mixed content', () {
        expect(
          settings.mixedContentMode,
          equals(MixedContentMode.MIXED_CONTENT_NEVER_ALLOW),
          reason:
              'Mixed content should be blocked to prevent downgrade attacks',
        );
      });

      test('enables safe browsing', () {
        expect(
          settings.safeBrowsingEnabled,
          isTrue,
          reason:
              'Safe browsing should be enabled to protect against malicious sites',
        );
      });

      test('disables file access from URLs', () {
        expect(
          settings.allowFileAccessFromFileURLs,
          isFalse,
          reason:
              'File access from URLs should be disabled to prevent local file theft',
        );
        expect(
          settings.allowUniversalAccessFromFileURLs,
          isFalse,
          reason: 'Universal file access should be disabled',
        );
      });

      test('disables geolocation by default', () {
        expect(
          settings.geolocationEnabled,
          isFalse,
          reason: 'Geolocation should be disabled by default for privacy',
        );
      });
    });

    group('getPaymentSecureSettings', () {
      late InAppWebViewSettings settings;

      setUp(() {
        settings = WebViewSecurityConfig.getPaymentSecureSettings();
      });

      test('blocks mixed content', () {
        expect(
          settings.mixedContentMode,
          equals(MixedContentMode.MIXED_CONTENT_NEVER_ALLOW),
        );
      });

      test('enables safe browsing', () {
        expect(settings.safeBrowsingEnabled, isTrue);
      });

      test('disables caching for sensitive data', () {
        expect(
          settings.cacheEnabled,
          isFalse,
          reason: 'Caching should be disabled for payment data',
        );
      });

      test('disables zoom for payment forms', () {
        expect(
          settings.supportZoom,
          isFalse,
          reason: 'Zoom should be disabled for payment form integrity',
        );
      });
    });

    group('validateSettings', () {
      test('returns true for secure settings', () {
        final settings = WebViewSecurityConfig.getSecureSettings();
        expect(WebViewSecurityConfig.validateSettings(settings), isTrue);
      });

      test('returns true for payment secure settings', () {
        final settings = WebViewSecurityConfig.getPaymentSecureSettings();
        expect(WebViewSecurityConfig.validateSettings(settings), isTrue);
      });

      test('returns false when mixed content is allowed', () {
        final settings = InAppWebViewSettings(
          mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
          safeBrowsingEnabled: true,
          allowFileAccessFromFileURLs: false,
          allowUniversalAccessFromFileURLs: false,
        );
        expect(WebViewSecurityConfig.validateSettings(settings), isFalse);
      });

      test('returns false when safe browsing is disabled', () {
        final settings = InAppWebViewSettings(
          mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
          safeBrowsingEnabled: false,
          allowFileAccessFromFileURLs: false,
          allowUniversalAccessFromFileURLs: false,
        );
        expect(WebViewSecurityConfig.validateSettings(settings), isFalse);
      });

      test('returns false when file access is enabled', () {
        final settings = InAppWebViewSettings(
          mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
          safeBrowsingEnabled: true,
          allowFileAccessFromFileURLs: true,
          allowUniversalAccessFromFileURLs: false,
        );
        expect(WebViewSecurityConfig.validateSettings(settings), isFalse);
      });
    });
  });
}
