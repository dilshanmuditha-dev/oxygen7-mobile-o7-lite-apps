import 'dart:async';

import 'package:app/api/api_provider.dart';
import 'package:app/shared/secure_shared_preferences/secure_shared_preferences.dart';
import 'package:app/shared/secure_shared_preferences/sharepreference.dart';
import 'package:app/shared/services/storage_service.dart';
import 'package:app/shared/utils/jwt_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/request/request.dart';

FutureOr<Request> requestInterceptor(Request request) async {
  final accessToken = await SecureSharedPreferences.instance.getAccessToken();

  request.headers['X-Requested-With'] = 'XMLHttpRequest';

  // Pre-flight JWT expiry check — GW3 only
  // Skip for refresh-token and auth endpoints to avoid infinite loop
  final isAuthRequest = request.url.path.contains('/auth/');
  if (!isAuthRequest &&
      StorageService.isGw3 &&
      accessToken != null &&
      accessToken.isNotEmpty) {
    if (JwtUtils.isTokenExpiringSoon(accessToken, bufferSeconds: 60)) {
      try {
        final apiProvider = Get.find<ApiProvider>();
        final refreshResponse = await apiProvider.refreshTokenGw3();

        if (refreshResponse.statusCode == 200 && refreshResponse.body != null) {
          final newAccessToken = refreshResponse.body['access_token'];
          final newRefreshToken = refreshResponse.body['refresh_token'];

          if (newAccessToken != null) {
            await SecureSharedPreferences.instance
                .setAccessToken(newAccessToken);

            // Update refresh token if provided (token rotation)
            if (newRefreshToken != null &&
                newRefreshToken.toString().isNotEmpty) {
              await SharedPrefManager.setRefreshTokenSecure(newRefreshToken);
            }

            if (kDebugMode) {
              print(
                  'RequestInterceptor: Token refreshed pre-flight, attaching new token');
            }

            request.headers['Authorization'] = 'Bearer $newAccessToken';
            return request;
          }
        }
      } catch (_) {
        // Fall through — use existing token, let server 401 handle it
        if (kDebugMode) {
          print(
              'RequestInterceptor: Pre-flight token refresh failed, using existing token');
        }
      }
    }
  }

  request.headers['Authorization'] = 'Bearer $accessToken';
  return request;
}
