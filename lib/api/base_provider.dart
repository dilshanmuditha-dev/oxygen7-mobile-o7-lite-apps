// ignore_for_file: unnecessary_this

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../shared/utils/app_flavor_helper.dart';
import 'api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/request_interceptor.dart';
import 'interceptors/response_interceptor.dart';
import 'ssl_pinning.dart';
import 'tls_config.dart';

/// Custom [HttpOverrides] that enforces SSL certificate pinning and
/// strong TLS configuration on all outgoing HTTPS connections.
///
/// Uses [TlsConfig.createSecurityContext] to enforce TLS 1.2 minimum
/// and prefer ECDHE+AES-GCM cipher suites, then delegates certificate
/// validation to [SslPinning.validateCertificate].
///
/// On older devices (API 22) where [SecurityContext] configuration may
/// fail, falls back to platform defaults while relying on
/// `network_security_config.xml` for TLS enforcement.
class _SslPinningHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // Use TLS-configured SecurityContext for strong cipher enforcement.
    // Falls back to platform default if configuration fails (older devices).
    final securityContext = TlsConfig.createSecurityContext();
    final client = super.createHttpClient(securityContext ?? context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) =>
            SslPinning.validateCertificate(cert, host);
    return client;
  }
}

class BaseProvider extends GetConnect {
  AppFlavor flavor;
  String? _httpBaseUrl;

  RxString versionCode = ''.obs;
  RxString versionName = ''.obs;

  BaseProvider(this.flavor) {
    setupEnvironment(flavor);
  }

  void updateEnvironment(AppFlavor newFlavor) {
    this.flavor = newFlavor;
    setupEnvironment(newFlavor);
  }

  String? get httpBaseUrl => _httpBaseUrl;

  @override
  void onInit() {
    // Enable SSL certificate pinning in release builds only.
    // Debug builds skip pinning to allow dev/staging servers.
    if (!kDebugMode) {
      HttpOverrides.global = _SslPinningHttpOverrides();
    }

    setupEnvironment(flavor);
    _httpBaseUrl = httpClient.baseUrl;
    httpClient.addAuthenticator(authInterceptor);
    httpClient.addRequestModifier(requestInterceptor);
    httpClient.addResponseModifier(responseInterceptor);
    httpClient.timeout = const Duration(seconds: 15);
  }

  void setupEnvironment(AppFlavor flavor) {
    switch (flavor) {
      case AppFlavor.development:
        httpClient.baseUrl = ApiConstants.API_DEV;
        break;
      case AppFlavor.production:
        httpClient.baseUrl = ApiConstants.API_PRO;
        break;
      case AppFlavor.developmentGW3:
        httpClient.baseUrl = ApiConstants.API_GW3_DEV;
        break;
      case AppFlavor.productionGW3:
        httpClient.baseUrl = ApiConstants.API_GW3_PRO;
        break;
    }
    _httpBaseUrl = httpClient.baseUrl;
  }
}
