import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// WebView Security Configuration for Legacy Encryption Remediation
///
/// This class provides secure default settings for InAppWebView components
/// to prevent exploitation via weak ciphers and legacy protocols.
///
/// Feature: legacy-encryption-remediation
/// Validates: Requirements 3.1, 3.2, 3.4
class WebViewSecurityConfig {
  /// Returns secure InAppWebViewSettings with hardened security defaults
  ///
  /// Security measures:
  /// - Blocks mixed content (HTTP in HTTPS pages)
  /// - Enables safe browsing
  /// - Disables file access from URLs
  /// - Disables geolocation by default
  static InAppWebViewSettings getSecureSettings({
    bool javaScriptEnabled = true,
    bool domStorageEnabled = true,
  }) {
    return InAppWebViewSettings(
      // === TLS/SSL Security ===
      // Disable mixed content (HTTP resources in HTTPS pages)
      mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,

      // Enable safe browsing to protect against malicious sites
      safeBrowsingEnabled: true,

      // === File Access Security ===
      // Disable file access from URLs to prevent local file theft
      allowFileAccessFromFileURLs: false,
      allowUniversalAccessFromFileURLs: false,

      // === JavaScript and Storage ===
      javaScriptEnabled: javaScriptEnabled,
      domStorageEnabled: domStorageEnabled,

      // === Privacy ===
      // Disable geolocation by default
      geolocationEnabled: false,

      // === Additional Security ===
      // Disable content URL access
      allowContentAccess: false,

      // Use wide viewport for better rendering
      useWideViewPort: true,

      // Support zoom for accessibility
      supportZoom: true,
      builtInZoomControls: true,
      displayZoomControls: false,
    );
  }

  /// Returns settings optimized for payment-related WebViews
  ///
  /// More restrictive settings for handling sensitive payment data
  static InAppWebViewSettings getPaymentSecureSettings() {
    return InAppWebViewSettings(
      // === Maximum TLS/SSL Security ===
      mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
      safeBrowsingEnabled: true,

      // === Strict File Access ===
      allowFileAccessFromFileURLs: false,
      allowUniversalAccessFromFileURLs: false,
      allowContentAccess: false,

      // === JavaScript (required for payment forms) ===
      javaScriptEnabled: true,
      domStorageEnabled: true,

      // === Privacy (strict for payments) ===
      geolocationEnabled: false,

      // === Caching (disabled for sensitive data) ===
      cacheEnabled: false,

      // === User Agent ===
      // Use default user agent to avoid fingerprinting

      // === Viewport ===
      useWideViewPort: true,
      supportZoom: false, // Disable zoom for payment forms
    );
  }

  /// Validates that settings meet security requirements
  ///
  /// Returns true if all security requirements are met
  static bool validateSettings(InAppWebViewSettings settings) {
    // Check mixed content is blocked
    if (settings.mixedContentMode !=
        MixedContentMode.MIXED_CONTENT_NEVER_ALLOW) {
      return false;
    }

    // Check safe browsing is enabled
    if (settings.safeBrowsingEnabled != true) {
      return false;
    }

    // Check file access is disabled
    if (settings.allowFileAccessFromFileURLs == true ||
        settings.allowUniversalAccessFromFileURLs == true) {
      return false;
    }

    return true;
  }
}
