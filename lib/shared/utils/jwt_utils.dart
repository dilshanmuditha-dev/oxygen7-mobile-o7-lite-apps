import 'dart:convert';
import 'package:app/shared/utils/log_utils.dart';

class JwtUtils {
  /// Decodes the JWT token and returns the payload data
  static Map<String, dynamic>? decodeToken(String token) {
    try {
      // Split the token into parts
      final parts = token.split('.');
      if (parts.length != 3) {
        LogUtils.debugLog('Invalid JWT token format');
        return null;
      }

      // Decode the payload (second part)
      String payload = parts[1];

      // Add padding if needed
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      // Convert base64Url to base64
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');

      // Decode base64 to string and parse JSON
      final decoded = utf8.decode(base64Url.decode(payload));
      return json.decode(decoded);
    } catch (e) {
      LogUtils.debugLog('Error decoding JWT token: $e');
      return null;
    }
  }

  /// Checks whether a JWT token is valid (non-null payload, has `exp`, not expired).
  /// Returns `false` for null payload, missing `exp`, or expired tokens.
  /// This is a local-only check — no network request is made.
  static bool isTokenValid(String token) {
    final payload = decodeToken(token);
    if (payload == null) return false;
    final exp = payload['exp'];
    if (exp == null) return false;
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return expiryDate.isAfter(DateTime.now());
  }

  /// Checks whether a JWT token is expiring soon (within [bufferSeconds]) or already expired.
  /// Returns `true` for malformed tokens (fail-safe) or if `exp` is missing.
  /// Returns `true` if the token will expire within [bufferSeconds] of now.
  static bool isTokenExpiringSoon(String token, {int bufferSeconds = 60}) {
    final payload = decodeToken(token);
    if (payload == null) return true;
    final exp = payload['exp'];
    if (exp == null) return true;
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return expiryDate
        .isBefore(DateTime.now().add(Duration(seconds: bufferSeconds)));
  }
}
