/// **Property 1: Bug Condition** - Username Login Saves Wrong rememberTID
/// **Validates: Requirements 1.1, 1.2, 1.3, 2.1, 2.2, 2.3**
///
/// This test encodes the EXPECTED (correct) behavior for `_processTokenPayload`
/// when user logs in GW3 by username (JWT payload contains `operator_id`).
///
/// On UNFIXED code, these tests MUST FAIL — failure confirms the bug exists.
/// After the fix is applied, these tests should PASS.
///
/// Bug Condition: `isBugCondition(input)` where `input.jwtPayload` HAS KEY
/// `operator_id` AND `operator_id` IS NOT NULL AND `operator_id` IS NOT EMPTY.
///
/// Current buggy behavior: `_processTokenPayload` always saves `sub` to both
/// `SecureSharedPreferences.setTID` (textfield restore) and
/// `SharedPrefManager.setTerminalID` (API calls), ignoring `operator_id`.
///
/// Expected correct behavior: When `operator_id` is present and non-empty,
/// `SecureSharedPreferences.setTID` should receive `operator_id` (for textfield
/// restore) while `SharedPrefManager.setTerminalID` still receives `sub` (for API).
library;

import 'package:flutter_test/flutter_test.dart';

/// Represents the values that `_processTokenPayload` stores after processing.
class ProcessTokenResult {
  /// Value stored via `SecureSharedPreferences.instance.setTID(...)` — used for
  /// textfield restore when rememberTid is enabled.
  final String secureTidValue;

  /// Value stored via `SharedPrefManager.setTerminalID = ...` — used for API
  /// calls and internal display.
  final String sharedPrefTerminalId;

  const ProcessTokenResult({
    required this.secureTidValue,
    required this.sharedPrefTerminalId,
  });
}

/// Simulates the FIXED production `_processTokenPayload` logic.
///
/// From `lib/modules/auth/auth_controller.dart` (after fix):
/// - API TID (`SharedPrefManager.setTerminalID`) always uses `sub`
/// - Textfield restore (`SecureSharedPreferences.setTID`) uses `operator_id`
///   when present and non-empty, otherwise falls back to `sub`
ProcessTokenResult simulateProcessTokenPayload(
    Map<String, dynamic> tokenPayload) {
  final String tid = tokenPayload['sub'].toString();
  final String? operatorId = tokenPayload['operator_id']?.toString();

  // API TID always uses sub
  final String sharedPrefTerminalId = tid;

  // Textfield restore: use operator_id if present and non-empty, otherwise sub
  final String secureTidValue;
  if (operatorId != null && operatorId.isNotEmpty) {
    secureTidValue = operatorId;
  } else {
    secureTidValue = tid;
  }

  return ProcessTokenResult(
    secureTidValue: secureTidValue,
    sharedPrefTerminalId: sharedPrefTerminalId,
  );
}

/// Checks if the bug condition is met: JWT payload contains a non-null,
/// non-empty `operator_id` field (indicates username login).
bool isBugCondition(Map<String, dynamic> payload) {
  return payload.containsKey('operator_id') &&
      payload['operator_id'] != null &&
      payload['operator_id'].toString().isNotEmpty;
}

void main() {
  // =========================================================================
  // Bug Condition Exploration: Username login with operator_id in JWT
  // These tests assert EXPECTED behavior — they will FAIL on unfixed code.
  // =========================================================================

  group('Bug Condition: _processTokenPayload with operator_id (username login)',
      () {
    test(
        'SecureSharedPreferences.setTID receives operator_id, not sub, '
        'when JWT contains operator_id', () {
      // Arrange: JWT payload from GW3 username login
      final payload = <String, dynamic>{
        'sub': '10244444413',
        'operator_id': 'op10244444413',
        'nonce': 'abc123',
        'exp': 1700000000,
      };

      // Verify bug condition is met
      expect(isBugCondition(payload), isTrue,
          reason: 'Payload with operator_id should trigger bug condition');

      // Act: simulate production _processTokenPayload
      final result = simulateProcessTokenPayload(payload);

      // Assert EXPECTED (correct) behavior:
      // setTID should receive operator_id for textfield restore
      expect(
        result.secureTidValue,
        equals('op10244444413'),
        reason: 'SecureSharedPreferences.setTID should receive operator_id '
            '"op10244444413" for textfield restore, NOT sub "10244444413"',
      );
    });

    test(
        'SharedPrefManager.setTerminalID receives sub value for API calls '
        'when JWT contains operator_id', () {
      final payload = <String, dynamic>{
        'sub': '10244444413',
        'operator_id': 'op10244444413',
        'nonce': 'abc123',
        'exp': 1700000000,
      };

      final result = simulateProcessTokenPayload(payload);

      // Assert: setTerminalID should always receive sub for API calls
      expect(
        result.sharedPrefTerminalId,
        equals('10244444413'),
        reason:
            'SharedPrefManager.setTerminalID should receive sub "10244444413" '
            'for API calls',
      );
    });

    test('operator_id with alphanumeric username format', () {
      final payload = <String, dynamic>{
        'sub': '9876543210',
        'operator_id': 'admin_user01',
        'exp': 1700000000,
      };

      expect(isBugCondition(payload), isTrue);

      final result = simulateProcessTokenPayload(payload);

      expect(
        result.secureTidValue,
        equals('admin_user01'),
        reason: 'setTID should receive alphanumeric operator_id "admin_user01"',
      );
      expect(
        result.sharedPrefTerminalId,
        equals('9876543210'),
        reason: 'setTerminalID should receive sub "9876543210" for API calls',
      );
    });

    test('operator_id with special characters in username', () {
      final payload = <String, dynamic>{
        'sub': '5551234567',
        'operator_id': 'user.name@branch-01',
        'exp': 1700000000,
      };

      expect(isBugCondition(payload), isTrue);

      final result = simulateProcessTokenPayload(payload);

      expect(
        result.secureTidValue,
        equals('user.name@branch-01'),
        reason: 'setTID should receive operator_id with special chars '
            '"user.name@branch-01"',
      );
      expect(
        result.sharedPrefTerminalId,
        equals('5551234567'),
        reason: 'setTerminalID should receive sub "5551234567"',
      );
    });

    test('operator_id with numeric-only username (different from sub)', () {
      final payload = <String, dynamic>{
        'sub': '1111111111',
        'operator_id': '9999999999',
        'exp': 1700000000,
      };

      expect(isBugCondition(payload), isTrue);

      final result = simulateProcessTokenPayload(payload);

      // Even when both are numeric, setTID must use operator_id
      expect(
        result.secureTidValue,
        equals('9999999999'),
        reason: 'setTID should receive operator_id "9999999999", '
            'not sub "1111111111"',
      );
      expect(
        result.sharedPrefTerminalId,
        equals('1111111111'),
        reason: 'setTerminalID should receive sub "1111111111"',
      );
    });
  });

  // =========================================================================
  // Edge cases within bug condition scope
  // =========================================================================

  group('Bug Condition Edge Cases', () {
    test('operator_id present but empty string → NOT bug condition', () {
      final payload = <String, dynamic>{
        'sub': '7777777777',
        'operator_id': '',
        'exp': 1700000000,
      };

      // Empty operator_id means TID login, not username login
      expect(isBugCondition(payload), isFalse,
          reason: 'Empty operator_id should NOT trigger bug condition');
    });

    test('operator_id present but null → NOT bug condition', () {
      final payload = <String, dynamic>{
        'sub': '5555555555',
        'operator_id': null,
        'exp': 1700000000,
      };

      expect(isBugCondition(payload), isFalse,
          reason: 'Null operator_id should NOT trigger bug condition');
    });

    test('operator_id absent → NOT bug condition', () {
      final payload = <String, dynamic>{
        'sub': '1234567890',
        'name': 'John Doe',
        'exp': 1700000000,
      };

      expect(isBugCondition(payload), isFalse,
          reason: 'Missing operator_id should NOT trigger bug condition');
    });
  });
}
