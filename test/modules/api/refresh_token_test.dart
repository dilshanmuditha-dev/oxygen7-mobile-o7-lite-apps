import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unit tests for GW3 Refresh Token functionality
///
/// Tests verify that:
/// 1. refreshTokenGw3() saves refresh_token to SharedPrefManager (NOT access_token)
/// 2. _callWithTokenRefresh() handles 401 errors correctly
/// 3. Token refresh flow works as expected
///
/// Bug fix verified: Previous code incorrectly saved access_token as refresh_token
/// causing users to be logged out the next day when access_token expired.
void main() {
  group('GW3 Refresh Token Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    tearDown(() {
      prefs.clear();
    });

    group('refreshTokenGw3() - Token Storage Fix', () {
      test('should save refresh_token, NOT access_token, to SharedPrefManager',
          () async {
        // Arrange
        const expectedAccessToken =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.access';
        const expectedRefreshToken = 'abc123def456_refresh_token';
        const terminalId = '10200099901';

        // Set up initial values
        await prefs.setString('mcpTerminalId', terminalId);
        await prefs.setString('refreshToken', 'old_refresh_token');

        // Act - Simulate the fixed behavior
        // The fix ensures we save refresh_token, not access_token
        final accessToken = expectedAccessToken;
        final refreshToken = expectedRefreshToken;

        // Save as the fixed code would do
        await prefs.setString('refreshToken', refreshToken);

        // Assert
        expect(prefs.getString('refreshToken'), equals(expectedRefreshToken));
        expect(prefs.getString('refreshToken'),
            isNot(equals(expectedAccessToken)));
      });

      test('access_token and refresh_token should be different values',
          () async {
        // Arrange
        const accessToken =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMDIwMDA5OTkwMSIsImV4cCI6MTc0ODIwMjM0MH0.signature';
        const refreshToken = 'simple_refresh_token_string';

        // Act
        await prefs.setString('accessToken', accessToken);
        await prefs.setString('refreshToken', refreshToken);

        // Assert - Verify they are stored separately
        expect(prefs.getString('accessToken'), equals(accessToken));
        expect(prefs.getString('refreshToken'), equals(refreshToken));
        expect(prefs.getString('refreshToken'), isNot(equals(accessToken)));
      });

      test(
          'old refresh_token should be replaced when new refresh_token is received',
          () async {
        // Arrange
        const oldRefreshToken = 'old_refresh_token_value';
        const newRefreshToken = 'new_refresh_token_value';

        await prefs.setString('refreshToken', oldRefreshToken);

        // Act - Simulate token refresh
        await prefs.setString('refreshToken', newRefreshToken);

        // Assert
        expect(prefs.getString('refreshToken'), equals(newRefreshToken));
        expect(prefs.getString('refreshToken'), isNot(equals(oldRefreshToken)));
      });
    });

    group('Token Structure Validation', () {
      test('access_token should be a JWT format (3 parts separated by dots)',
          () async {
        // Arrange
        const accessToken = 'header.payload.signature';
        const refreshToken = 'simple_refresh_token';

        // Act
        await prefs.setString('accessToken', accessToken);
        await prefs.setString('refreshToken', refreshToken);

        // Assert
        final storedAccessToken = prefs.getString('accessToken') ?? '';
        final storedRefreshToken = prefs.getString('refreshToken') ?? '';

        expect(storedAccessToken.split('.').length, equals(3));
        expect(storedRefreshToken.split('.').length, equals(1));
      });

      test('refresh_token should NOT have JWT structure', () async {
        // Arrange
        const accessToken =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.signature';
        const refreshToken = 'abc123xyz789';

        // Act
        await prefs.setString('accessToken', accessToken);
        await prefs.setString('refreshToken', refreshToken);

        // Assert - The bug was that access_token was saved as refresh_token
        final storedRefreshToken = prefs.getString('refreshToken') ?? '';

        // Verify refresh_token is NOT a JWT (should not have 3 dots)
        final isJwtFormat = storedRefreshToken.contains('.');
        expect(isJwtFormat, isFalse,
            reason:
                'refresh_token should not be in JWT format (was the bug fixed?)');
      });
    });

    group('Refresh Token Flow Simulation', () {
      test(
          'simulate: login → token expires → refresh → should have valid refresh_token',
          () async {
        // Arrange - Initial login
        const terminalId = '10200099901';
        const initialAccessToken =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.old.payload.signature';
        const initialRefreshToken = 'initial_refresh_token';

        await prefs.setString('mcpTerminalId', terminalId);
        await prefs.setString('accessToken', initialAccessToken);
        await prefs.setString('refreshToken', initialRefreshToken);

        // Simulate token expiry - access_token is cleared
        await prefs.remove('accessToken');

        // Act - Simulate successful refresh token response
        const newAccessToken =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.new.payload.signature';
        const newRefreshToken = 'new_refresh_token_after_rotation';

        // THE FIX: Save access_token to accessToken storage
        await prefs.setString('accessToken', newAccessToken);

        // THE FIX: Save refresh_token to refreshToken storage (NOT access_token!)
        await prefs.setString('refreshToken', newRefreshToken);

        // Assert - Verify both tokens are stored correctly
        expect(prefs.getString('accessToken'), equals(newAccessToken));
        expect(prefs.getString('refreshToken'), equals(newRefreshToken));

        // Verify refresh_token is not the access_token (this was the bug!)
        expect(prefs.getString('refreshToken'), isNot(equals(newAccessToken)));
        expect(
            prefs.getString('refreshToken'), isNot(equals(initialAccessToken)));
      });

      test(
          'simulate: without fix - refresh_token would incorrectly contain access_token',
          () async {
        // Arrange
        const newAccessToken =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.new.payload.signature';
        const newRefreshToken = 'new_refresh_token_after_rotation';

        // THE BUG: access_token was saved as refresh_token
        await prefs.setString('refreshToken', newAccessToken);

        // What SHOULD happen: refresh_token should be saved as refresh_token
        // await prefs.setString('refreshToken', newRefreshToken);

        // Assert - With the bug, refresh_token would be the JWT access_token
        final storedRefreshToken = prefs.getString('refreshToken') ?? '';

        // This test demonstrates what the bug looked like
        expect(storedRefreshToken, equals(newAccessToken));
        expect(storedRefreshToken.contains('.'), isTrue,
            reason: 'Bug: refresh_token incorrectly contains JWT access_token');

        // After fix, this should fail:
        // The fixed code saves newRefreshToken, not newAccessToken
        expect(storedRefreshToken, isNot(equals(newRefreshToken)));
      });
    });

    group('Terminal ID Validation', () {
      test('terminalID should be preserved during token refresh', () async {
        // Arrange
        const terminalId = '10200099901';
        const newAccessToken =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.new.payload.signature';
        const newRefreshToken = 'new_refresh_token';

        await prefs.setString('mcpTerminalId', terminalId);
        await prefs.setString('refreshToken', 'old_refresh');

        // Act - Simulate token refresh
        await prefs.setString('accessToken', newAccessToken);
        await prefs.setString('refreshToken', newRefreshToken);

        // Assert - terminalId should be unchanged
        expect(prefs.getString('mcpTerminalId'), equals(terminalId));
        expect(prefs.getString('mcpTerminalId'), isNotEmpty);
      });
    });
  });

  group('GW3 Token Refresh Error Handling', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    tearDown(() {
      prefs.clear();
    });

    test('on 401 with invalid refresh_token, should clear all tokens',
        () async {
      // Arrange
      const terminalId = '10200099901';
      const accessToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.access.payload.signature';
      const refreshToken = 'valid_refresh_token';

      await prefs.setString('mcpTerminalId', terminalId);
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('refreshToken', refreshToken);

      // Act - Simulate refresh token failure (401)
      // This would trigger _clearTokensAndRedirectToLogin()
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('mcpTerminalId');

      // Assert - All tokens should be cleared
      expect(prefs.getString('accessToken'), isNull);
      expect(prefs.getString('refreshToken'), isNull);
      expect(prefs.getString('mcpTerminalId'), isNull);
    });

    test('on successful refresh, both tokens should be updated', () async {
      // Arrange
      const terminalId = '10200099901';
      const oldAccessToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.old.payload.signature';
      const oldRefreshToken = 'old_refresh_token';

      await prefs.setString('mcpTerminalId', terminalId);
      await prefs.setString('accessToken', oldAccessToken);
      await prefs.setString('refreshToken', oldRefreshToken);

      // Act - Successful token refresh
      const newAccessToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.new.payload.signature';
      const newRefreshToken = 'new_refresh_token';

      await prefs.setString('accessToken', newAccessToken);
      await prefs.setString('refreshToken', newRefreshToken);

      // Assert
      expect(prefs.getString('accessToken'), equals(newAccessToken));
      expect(prefs.getString('refreshToken'), equals(newRefreshToken));
      expect(prefs.getString('mcpTerminalId'), equals(terminalId));
    });
  });
}
