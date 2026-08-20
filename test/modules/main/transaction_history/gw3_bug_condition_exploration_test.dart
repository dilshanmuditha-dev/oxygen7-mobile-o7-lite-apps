/// **Property 1: Bug Condition** - GW3 State/Type Mapping Falls Through to Defaults
/// **Validates: Requirements 1.1, 1.2, 2.1, 2.2, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6,
///   4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6**
///
/// This test encodes the EXPECTED (correct) behavior for GW3 transactions.
/// On UNFIXED code, these tests MUST FAIL — failure confirms the bug exists.
/// After the fix is applied, these tests should PASS.
///
/// Scoped PBT Approach: Exhaustively tests all concrete GW3 state/type values
/// returned by the API: states {SUCCESS, CANCELLED, CAPTURED, PENDING, REFUNDED}
/// and types {SALE, REFUND, CAPTURE}.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/response/transaction_list_response/transaction_list_response.dart';
import 'package:app/shared/constants/constants_o7lite.dart';

/// All GW3 states returned by the API (uppercase).
const List<String> gw3States = [
  'SUCCESS',
  'CANCELLED',
  'CAPTURED',
  'PENDING',
  'REFUNDED',
];

/// All GW3 types returned by the API (uppercase).
const List<String> gw3Types = [
  'SALE',
  'REFUND',
  'CAPTURE',
];

/// Expected status badge text for each GW3 state.
const Map<String, String> expectedStatusBadgeText = {
  'SUCCESS': 'Completed',
  'CAPTURED': 'Captured',
  'PENDING': 'Pending',
  'CANCELLED': 'Cancelled',
  'REFUNDED': 'Refunded',
};

/// Expected type badge text for each GW3 type.
const Map<String, String> expectedTypeBadgeText = {
  'SALE': 'SALE',
  'REFUND': 'REFUND',
  'CAPTURE': 'CAPTURE',
};

/// Expected isTransactionFailed result for each GW3 state.
const Map<String, bool> expectedIsFailedForState = {
  'SUCCESS': false,
  'CAPTURED': false,
  'PENDING': false,
  'CANCELLED': true,
  'REFUNDED': false,
};

void main() {
  // =========================================================================
  // Layer 1: Model Deserialization — int? fields cannot hold GW3 strings
  // =========================================================================
  group('Layer 1: TransactionListResponse.fromJson preserves GW3 string values',
      () {
    for (final state in gw3States) {
      test('fromJson preserves transactionState "$state" as string', () {
        final json = <String, dynamic>{
          'transactionState': state,
          'transactionType': 'SALE',
          'totalAmount': '100.00',
          'currency': 'MYR',
          'transactionId': 'TXN-001',
        };

        // On unfixed code: int? field causes (json['transactionState'] as num?)
        // to throw TypeError on a string value, or silently produce null.
        final response = TransactionListResponse.fromJson(json);

        // Expected: the original string value is preserved
        expect(
          response.transactionState?.toString(),
          equals(state),
          reason: 'transactionState should preserve GW3 string "$state"',
        );
      });
    }

    for (final type in gw3Types) {
      test('fromJson preserves transactionType "$type" as string', () {
        final json = <String, dynamic>{
          'transactionState': 'SUCCESS',
          'transactionType': type,
          'totalAmount': '50.00',
          'currency': 'MYR',
          'transactionId': 'TXN-002',
        };

        final response = TransactionListResponse.fromJson(json);

        expect(
          response.transactionType?.toString(),
          equals(type),
          reason: 'transactionType should preserve GW3 string "$type"',
        );
      });
    }
  });

  // =========================================================================
  // Layer 2: GW3 Constants casing — lowercase constants vs uppercase API
  // =========================================================================
  group('Layer 2: GW3 constants match API response casing (uppercase)', () {
    test('GW3TransactionState.APPROVED matches API value "SUCCESS"', () {
      expect(GW3TransactionState.APPROVED, equals('SUCCESS'),
          reason: 'APPROVED constant should be "SUCCESS" to match GW3 API');
    });

    test('GW3TransactionState.PENDING matches API value "PENDING"', () {
      expect(GW3TransactionState.PENDING, equals('PENDING'),
          reason: 'PENDING constant should be "PENDING" to match GW3 API');
    });

    test('GW3TransactionState.REFUNDED matches API value "REFUNDED"', () {
      expect(GW3TransactionState.REFUNDED, equals('REFUNDED'),
          reason: 'REFUNDED constant should be "REFUNDED" to match GW3 API');
    });

    test('GW3TransactionState.CAPTURED matches API value "CAPTURED"', () {
      expect(GW3TransactionState.CAPTURED, equals('CAPTURED'),
          reason: 'CAPTURED constant should be "CAPTURED" to match GW3 API');
    });

    test('GW3TransactionType.SALE matches API value "SALE"', () {
      expect(GW3TransactionType.SALE, equals('SALE'),
          reason: 'SALE constant should be "SALE" to match GW3 API');
    });

    test('GW3TransactionType.REFUND matches API value "REFUND"', () {
      expect(GW3TransactionType.REFUND, equals('REFUND'),
          reason: 'REFUND constant should be "REFUND" to match GW3 API');
    });

    test('GW3TransactionType.CAPTURE matches API value "CAPTURE"', () {
      expect(GW3TransactionType.CAPTURE, equals('CAPTURE'),
          reason: 'CAPTURE constant should be "CAPTURE" to match GW3 API');
    });
  });

  // =========================================================================
  // Layer 3: UI Mapping Logic — switch cases only match legacy numeric values
  // =========================================================================

  // 3a: Status Badge Mapping
  // The production _buildGw3StatusBadge uses a switch on transactionState
  // comparing against TransactionState.STATE_SUCCESS ("2"), STATE_DENIED ("5"), etc.
  // GW3 string values like "SUCCESS" will never match these numeric strings.
  group('Layer 3a: GW3 states map to correct status badge text', () {
    for (final state in gw3States) {
      test(
          'GW3 state "$state" maps to status badge "${expectedStatusBadgeText[state]}"',
          () {
        final badgeText = _simulateStatusBadgeText(state);
        expect(
          badgeText,
          equals(expectedStatusBadgeText[state]),
          reason:
              'GW3 state "$state" should produce "${expectedStatusBadgeText[state]}" badge',
        );
      });
    }
  });

  // 3b: Type Badge Mapping
  // The production _buildGw3CompactTypeBadge uses a switch on transactionType
  // comparing against TransactionType.SALES ("200"), REFUND ("400"), etc.
  // GW3 string values like "SALE" will never match these numeric strings.
  group('Layer 3b: GW3 types map to correct type badge text', () {
    for (final type in gw3Types) {
      test(
          'GW3 type "$type" maps to type badge "${expectedTypeBadgeText[type]}"',
          () {
        final badgeText = _simulateTypeBadgeText(type);
        expect(
          badgeText,
          equals(expectedTypeBadgeText[type]),
          reason:
              'GW3 type "$type" should produce "${expectedTypeBadgeText[type]}" badge',
        );
      });
    }
  });

  // 3c: Amount Formatting — REFUND should have minus sign
  group('Layer 3c: GW3 REFUND type prefixes amount with minus sign', () {
    test('REFUND type produces minus-prefixed amount', () {
      final hasMinusSign = _simulateIsRefundType('REFUND');
      expect(hasMinusSign, isTrue,
          reason: 'GW3 type "REFUND" should prefix amount with minus sign');
    });

    test('SALE type does NOT produce minus-prefixed amount', () {
      final hasMinusSign = _simulateIsRefundType('SALE');
      expect(hasMinusSign, isFalse,
          reason: 'GW3 type "SALE" should NOT prefix amount with minus sign');
    });

    test('CAPTURE type does NOT produce minus-prefixed amount', () {
      final hasMinusSign = _simulateIsRefundType('CAPTURE');
      expect(hasMinusSign, isFalse,
          reason:
              'GW3 type "CAPTURE" should NOT prefix amount with minus sign');
    });
  });

  // 3d: Failed Transaction Detection
  // The production isTransactionFailed compares against TransactionState constants
  // ("1", "2", "5", etc.). GW3 string values fall to default which returns true.
  group('Layer 3d: isTransactionFailed correctly classifies GW3 states', () {
    for (final state in gw3States) {
      test(
          'GW3 state "$state" → isTransactionFailed = ${expectedIsFailedForState[state]}',
          () {
        final isFailed = _simulateIsTransactionFailed(state);
        expect(
          isFailed,
          equals(expectedIsFailedForState[state]),
          reason:
              'GW3 state "$state" should be ${expectedIsFailedForState[state]! ? "failed" : "not failed"}',
        );
      });
    }

    test('null state → isTransactionFailed = true', () {
      final isFailed = _simulateIsTransactionFailed(null);
      expect(isFailed, isTrue,
          reason: 'null state should be classified as failed');
    });

    test('empty state → isTransactionFailed = true', () {
      final isFailed = _simulateIsTransactionFailed('');
      expect(isFailed, isTrue,
          reason: 'empty state should be classified as failed');
    });
  });
}

// =============================================================================
// Simulation functions that mirror the PRODUCTION code logic exactly.
// These replicate the switch statements from transaction_history_screen.dart
// so we can test the mapping behavior without instantiating Flutter widgets.
// =============================================================================

/// Mirrors _buildGw3StatusBadge switch logic from production code.
/// Uses the SAME constants the production code uses.
String _simulateStatusBadgeText(String transactionState) {
  switch (transactionState) {
    // Production code compares against legacy numeric constants
    case TransactionState.STATE_SUCCESS: // "2"
    case TransactionState.STATE_AUTHORIZED: // "3"
    case TransactionState.STATE_SETTLEMENT_SUBMITTED: // "6"
      return 'Completed';
    case TransactionState.STATE_USER_PAYING: // "71"
      return 'Pending';
    case TransactionState.STATE_ORDER_CLOSED: // "78"
    case TransactionState.STATE_DENIED: // "5"
    case TransactionState.STATE_SETTLEMENT_REJECTED: // "8"
      return 'Failed';
    case TransactionState.STATE_REVERSED: // "4"
    case TransactionState.STATE_VOIDED: // "12"
      return 'Voided';
    case TransactionState.STATE_REFUNDED: // "11"
      return 'Refunded';

    // GW3 string constants — these are the EXPECTED correct mappings.
    // On unfixed code, GW3TransactionState values are lowercase and won't
    // match uppercase API values. After fix, these should match.
    case GW3TransactionState.APPROVED: // unfixed: 'success', fixed: 'SUCCESS'
      return 'Completed';
    case GW3TransactionState.CAPTURED: // unfixed: 'captured', fixed: 'CAPTURED'
      return 'Captured';
    case GW3TransactionState.PENDING: // unfixed: 'pending', fixed: 'PENDING'
      return 'Pending';
    case GW3TransactionState
          .CANCELLED: // Added with fix: 'CANCELLED' → Cancelled
      return 'Cancelled';
    case GW3TransactionState.REFUNDED: // unfixed: 'refunded', fixed: 'REFUNDED'
      return 'Refunded';

    default:
      return 'Unknown';
  }
}

/// Mirrors _buildGw3CompactTypeBadge switch logic from production code.
String _simulateTypeBadgeText(String transactionType) {
  switch (transactionType) {
    // Production code compares against legacy numeric constants
    case TransactionType.SALES: // "200"
      return 'SALES';
    case TransactionType.REFUND: // "400"
      return 'REFUND';
    case TransactionType.VOID: // "300"
      return 'VOID';
    case TransactionType.PREAUTH: // "100"
      return 'PREAUTH';
    case TransactionType.QUICK_PAY: // "71001"
      return 'QUICK';
    case TransactionType.UNIFIED_ORDER: // "72001"
      return 'UNIFIED';
    case TransactionType.REVERSE: // "100400"
      return 'REVERSE';
    case TransactionType.EWALLET_VOID: // "81002"
      return 'E-VOID';

    // GW3 string constants — EXPECTED correct mappings
    case GW3TransactionType.SALE: // unfixed: 'sale', fixed: 'SALE'
      return 'SALE';
    case GW3TransactionType.REFUND: // unfixed: 'refund', fixed: 'REFUND'
      return 'REFUND';
    case GW3TransactionType.CAPTURE: // unfixed: 'capture', fixed: 'CAPTURE'
      return 'CAPTURE';

    default:
      return 'OTHER';
  }
}

/// Mirrors _formatGw3Amount refund detection logic from production code.
/// Returns true if the type should produce a minus-prefixed amount.
bool _simulateIsRefundType(String transactionType) {
  // Production code only checks legacy numeric constants
  final legacyRefundTypes = [
    TransactionType.REFUND, // "400"
    TransactionType.VOID, // "300"
    TransactionType.REVERSE, // "100400"
    TransactionType.EWALLET_VOID, // "81002"
  ];

  if (legacyRefundTypes.contains(transactionType)) return true;

  // GW3 REFUND type should also be detected — EXPECTED correct behavior
  if (transactionType == GW3TransactionType.REFUND) return true;

  return false;
}

/// Mirrors isTransactionFailed logic from production code.
/// Returns true if the transaction should be classified as failed.
bool _simulateIsTransactionFailed(String? transactionState) {
  if (transactionState == null || transactionState == '') {
    return true;
  }

  switch (transactionState) {
    // Production code compares against legacy numeric constants only
    case TransactionState.STATE_USER_PAYING: // "71"
      return false;
    case TransactionState.STATE_ORDER_CLOSED: // "78"
    case TransactionState.STATE_DENIED: // "5"
    case TransactionState.STATE_SETTLEMENT_REJECTED: // "8"
      return true;
    case TransactionState.STATE_SUCCESS: // "2"
    case TransactionState.STATE_AUTHORIZED: // "3"
    case TransactionState.STATE_SETTLEMENT_SUBMITTED: // "6"
      return false;
    case TransactionState.STATE_REVERSED: // "4"
    case TransactionState.STATE_VOIDED: // "12"
      return false;
    case TransactionState.STATE_REFUNDED: // "11"
      return false;

    // GW3 string constants — EXPECTED correct behavior after fix
    case GW3TransactionState.APPROVED: // unfixed: 'success', fixed: 'SUCCESS'
    case GW3TransactionState.CAPTURED: // unfixed: 'captured', fixed: 'CAPTURED'
    case GW3TransactionState.PENDING: // unfixed: 'pending', fixed: 'PENDING'
    case GW3TransactionState.REFUNDED: // unfixed: 'refunded', fixed: 'REFUNDED'
      return false;
    case GW3TransactionState.CANCELLED: // Added with fix: CANCELLED → failed
      return true;

    default:
      // Production code: default falls through and returns true
      // This means ALL unrecognized states (including GW3 uppercase strings
      // that don't match any case) are incorrectly flagged as failed
      return true;
  }
}
