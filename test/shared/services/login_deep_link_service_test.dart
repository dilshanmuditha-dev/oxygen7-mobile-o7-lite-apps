import 'package:app/shared/services/login_deep_link_service.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

String _jwtFor({required String operatorId, required DateTime expiresAt}) {
  String encode(Map<String, dynamic> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  return '${encode({'alg': 'none'})}.${encode({
        'operator_id': operatorId,
        'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
      })}.';
}

void main() {
  group('LoginDeepLinkCredentials', () {
    test('parses valid native credential payload', () {
      final credentials = LoginDeepLinkCredentials.fromPlatformMap({
        'operatorId': 'drgw3',
        'pswd': '123456',
      });

      expect(credentials, isNotNull);
      expect(credentials!.operatorId, 'drgw3');
      expect(credentials.password, '123456');
    });

    test('rejects blank operatorId', () {
      final credentials = LoginDeepLinkCredentials.fromPlatformMap({
        'operatorId': '',
        'pswd': '123456',
      });

      expect(credentials, isNull);
    });

    test('rejects missing password', () {
      final credentials = LoginDeepLinkCredentials.fromPlatformMap({
        'operatorId': 'drgw3',
      });

      expect(credentials, isNull);
    });
  });

  group('LoginDeepLinkError', () {
    test('builds friendly message for missing operatorId', () {
      final error = LoginDeepLinkError.fromPlatformMap({
        'missingOperatorId': true,
        'missingPassword': false,
      });

      expect(error, isNotNull);
      expect(error!.message, contains('verify your login details'));
      expect(error.message, isNot(contains('pswd')));
    });

    test('builds friendly message for missing password', () {
      final error = LoginDeepLinkError.fromPlatformMap({
        'missingOperatorId': false,
        'missingPassword': true,
      });

      expect(error, isNotNull);
      expect(error!.message, contains('verify your login details'));
      expect(error.message, isNot(contains('pswd')));
    });
  });

  group('LoginDeepLinkGuard', () {
    const credentials = LoginDeepLinkCredentials(
      operatorId: 'Operator001',
      password: 'secret',
    );

    test('ignores the same credentials while their login is running', () {
      const submittingCredentials = LoginDeepLinkCredentials(
        operatorId: 'operator001',
        password: 'secret',
      );

      expect(
        LoginDeepLinkGuard.shouldIgnore(
          credentials: credentials,
          submittingCredentials: submittingCredentials,
        ),
        isTrue,
      );
    });

    test('ignores a deep link for the active operator session', () {
      final token = _jwtFor(
        operatorId: 'OPERATOR001',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(
        LoginDeepLinkGuard.shouldIgnore(
          credentials: credentials,
          accessToken: token,
        ),
        isTrue,
      );
    });

    test('accepts the deep link when the active token is expired', () {
      final token = _jwtFor(
        operatorId: 'operator001',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(
        LoginDeepLinkGuard.shouldIgnore(
          credentials: credentials,
          accessToken: token,
        ),
        isFalse,
      );
    });

    test('accepts credentials for a different active operator', () {
      final token = _jwtFor(
        operatorId: 'operator002',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(
        LoginDeepLinkGuard.shouldIgnore(
          credentials: credentials,
          accessToken: token,
        ),
        isFalse,
      );
    });
  });
}
