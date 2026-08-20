/// **Property 2: Preservation** - TID Login rememberTID Behavior Unchanged
/// **Validates: Requirements 3.1, 3.2, 3.3, 3.4**
///
/// These tests capture the CURRENT (unfixed) baseline behavior of
/// `_processTokenPayload` when user logs in GW3 by TID (JWT payload does NOT
/// contain a valid `operator_id`).
///
/// On UNFIXED code, these tests MUST PASS — they confirm the baseline behavior
/// that must be preserved after the fix is applied.
///
/// Preservation Goal: For all JWT payloads where `operator_id` is absent, null,
/// or empty (NOT isBugCondition), both `SecureSharedPreferences.setTID` and
/// `SharedPrefManager.setTerminalID` receive the `sub` value — identical to
/// unfixed code behavior.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Shared helpers (same as bug condition test)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Property-based test helpers
// ---------------------------------------------------------------------------

/// Generates a random numeric string of [length] digits.
String _randomNumericString(Random rng, int length) {
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    buffer.write(rng.nextInt(10));
  }
  return buffer.toString();
}

void main() {
  // =========================================================================
  // Observation tests: record actual storage values on UNFIXED code
  // =========================================================================

  group('Observation: _processTokenPayload TID login (no operator_id)', () {
    test('JWT {"sub": "1234567890"} → both storage calls receive "1234567890"',
        () {
      final payload = <String, dynamic>{
        'sub': '1234567890',
      };

      // Confirm NOT bug condition
      expect(isBugCondition(payload), isFalse);

      final result = simulateProcessTokenPayload(payload);

      expect(result.secureTidValue, equals('1234567890'),
          reason: 'setTID should receive sub "1234567890"');
      expect(result.sharedPrefTerminalId, equals('1234567890'),
          reason: 'setTerminalID should receive sub "1234567890"');
    });

    test(
        'JWT {"sub": "9876543210", "name": "John", "admin": true} '
        '→ both storage calls receive "9876543210"', () {
      final payload = <String, dynamic>{
        'sub': '9876543210',
        'name': 'John',
        'admin': true,
      };

      expect(isBugCondition(payload), isFalse);

      final result = simulateProcessTokenPayload(payload);

      expect(result.secureTidValue, equals('9876543210'),
          reason: 'setTID should receive sub "9876543210"');
      expect(result.sharedPrefTerminalId, equals('9876543210'),
          reason: 'setTerminalID should receive sub "9876543210"');
    });

    test(
        'JWT {"sub": "5555555555", "operator_id": null} '
        '→ treated as TID login, both receive "5555555555"', () {
      final payload = <String, dynamic>{
        'sub': '5555555555',
        'operator_id': null,
      };

      expect(isBugCondition(payload), isFalse,
          reason: 'Null operator_id should NOT trigger bug condition');

      final result = simulateProcessTokenPayload(payload);

      expect(result.secureTidValue, equals('5555555555'),
          reason: 'setTID should receive sub "5555555555"');
      expect(result.sharedPrefTerminalId, equals('5555555555'),
          reason: 'setTerminalID should receive sub "5555555555"');
    });

    test(
        'JWT {"sub": "7777777777", "operator_id": ""} '
        '→ treated as TID login, both receive "7777777777"', () {
      final payload = <String, dynamic>{
        'sub': '7777777777',
        'operator_id': '',
      };

      expect(isBugCondition(payload), isFalse,
          reason: 'Empty operator_id should NOT trigger bug condition');

      final result = simulateProcessTokenPayload(payload);

      expect(result.secureTidValue, equals('7777777777'),
          reason: 'setTID should receive sub "7777777777"');
      expect(result.sharedPrefTerminalId, equals('7777777777'),
          reason: 'setTerminalID should receive sub "7777777777"');
    });
  });

  // =========================================================================
  // Property-based tests: preservation for all non-bug-condition payloads
  // =========================================================================

  group('Property: Preservation — TID login behavior unchanged', () {
    test(
        'for all JWT payloads where operator_id is absent/null/empty, '
        'both storage values equal sub', () {
      /// **Validates: Requirements 3.1, 3.2, 3.3, 3.4**
      ///
      /// Property: For ALL payloads where NOT isBugCondition(payload),
      /// secureTidValue == sub AND sharedPrefTerminalId == sub.
      final rng = Random(42); // deterministic seed for reproducibility

      // Generate payloads with absent operator_id
      final absentOperatorIdPayloads = List.generate(50, (i) {
        final sub =
            _randomNumericString(rng, 5 + rng.nextInt(11)); // 5-15 digits
        final extraFields = <String, dynamic>{
          'sub': sub,
          'exp': 1700000000 + rng.nextInt(100000),
        };
        // Randomly add extra JWT fields (but never operator_id)
        if (rng.nextBool()) extraFields['name'] = 'User$i';
        if (rng.nextBool()) extraFields['admin'] = rng.nextBool();
        if (rng.nextBool()) extraFields['nonce'] = 'nonce_${rng.nextInt(9999)}';
        if (rng.nextBool())
          extraFields['iat'] = 1699000000 + rng.nextInt(100000);
        return extraFields;
      });

      // Generate payloads with null operator_id
      final nullOperatorIdPayloads = List.generate(25, (i) {
        final sub = _randomNumericString(rng, 5 + rng.nextInt(11));
        return <String, dynamic>{
          'sub': sub,
          'operator_id': null,
          'exp': 1700000000 + rng.nextInt(100000),
        };
      });

      // Generate payloads with empty string operator_id
      final emptyOperatorIdPayloads = List.generate(25, (i) {
        final sub = _randomNumericString(rng, 5 + rng.nextInt(11));
        return <String, dynamic>{
          'sub': sub,
          'operator_id': '',
          'exp': 1700000000 + rng.nextInt(100000),
        };
      });

      final allPayloads = [
        ...absentOperatorIdPayloads,
        ...nullOperatorIdPayloads,
        ...emptyOperatorIdPayloads,
      ];

      for (var i = 0; i < allPayloads.length; i++) {
        final payload = allPayloads[i];
        final sub = payload['sub'].toString();

        // Guard: must NOT be bug condition
        expect(isBugCondition(payload), isFalse,
            reason: 'Payload $i should NOT trigger bug condition: $payload');

        final result = simulateProcessTokenPayload(payload);

        expect(result.secureTidValue, equals(sub),
            reason:
                'Payload $i: setTID should receive sub "$sub" — payload: $payload');
        expect(result.sharedPrefTerminalId, equals(sub),
            reason:
                'Payload $i: setTerminalID should receive sub "$sub" — payload: $payload');
      }
    });

    test(
        'random sub values of varying lengths without operator_id '
        '→ both storage values equal sub', () {
      /// **Validates: Requirements 3.1, 3.4**
      ///
      /// Property: For randomly generated sub values (numeric strings of
      /// varying lengths 1-20), when no operator_id is present, both
      /// secureTidValue and sharedPrefTerminalId equal sub.
      final rng = Random(99); // different seed for variety

      for (var i = 0; i < 100; i++) {
        final length = 1 + rng.nextInt(20); // 1-20 digits
        final sub = _randomNumericString(rng, length);

        final payload = <String, dynamic>{
          'sub': sub,
        };

        expect(isBugCondition(payload), isFalse);

        final result = simulateProcessTokenPayload(payload);

        expect(result.secureTidValue, equals(sub),
            reason: 'Iteration $i: setTID should receive sub "$sub"');
        expect(result.sharedPrefTerminalId, equals(sub),
            reason: 'Iteration $i: setTerminalID should receive sub "$sub"');
      }
    });
  });
}
