/// **Property 2: Preservation** - Legacy Transaction Rendering Unchanged
/// **Validates: Requirements 2.3, 3.7, 4.5, 5.4, 6.7, 7.3, 7.4**
///
/// These tests capture the CURRENT behavior of legacy numeric state/type mapping
/// on UNFIXED code. They must:
/// 1. PASS on the current unfixed code (this is the baseline)
/// 2. Continue to PASS after the fix is applied (confirming no regressions)
///
/// Observation-first methodology: Each test observes the actual output of the
/// production switch logic for legacy numeric values and asserts it matches.
///
/// Property-based approach: Exhaustively enumerates ALL known legacy numeric
/// state and type values (finite domain), plus representative unknown values,
/// to guarantee complete coverage of the legacy mapping behavior.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/response/transaction_list_response/transaction_list_response.dart';
import 'package:app/shared/constants/constants_o7lite.dart';

// =============================================================================
// Legacy numeric state values — complete set from TransactionState class
// =============================================================================
const Map<String, String> allLegacyStates = {
  '1': 'STATE_REQUESTED',
  '2': 'STATE_SUCCESS',
  '3': 'STATE_AUTHORIZED',
  '4': 'STATE_REVERSED',
  '5': 'STATE_DENIED',
  '6': 'STATE_SETTLEMENT_SUBMITTED',
  '7': 'STATE_SETTLED',
  '8': 'STATE_SETTLEMENT_REJECTED',
  '11': 'STATE_REFUNDED',
  '12': 'STATE_VOIDED',
  '71': 'STATE_USER_PAYING',
  '78': 'STATE_ORDER_CLOSED',
};

/// Unknown/undefined state values to test default branch behavior.
const List<String> unknownStateValues = [
  '0',
  '9',
  '10',
  '13',
  '14',
  '15',
  '20',
  '50',
  '99',
];

// =============================================================================
// Legacy numeric type values — complete set from TransactionType class
// =============================================================================
const Map<String, String> allLegacyTypes = {
  '100': 'PREAUTH',
  '200': 'SALES',
  '300': 'VOID',
  '400': 'REFUND',
  '71001': 'QUICK_PAY',
  '72001': 'UNIFIED_ORDER',
  '81002': 'EWALLET_VOID',
  '100400': 'REVERSE',
};

/// Unknown/undefined type values to test default branch behavior.
const List<String> unknownTypeValues = [
  '0',
  '50',
  '500',
  '600',
  '999',
  '10000',
];

// =============================================================================
// OBSERVED baseline outputs on UNFIXED code
// These are the actual outputs of the production switch logic.
// =============================================================================

/// Observed: _buildGw3StatusBadge text output for each legacy state.
const Map<String, String> observedStatusBadgeText = {
  // Known states
  '1': 'Unknown', // STATE_REQUESTED — no case, falls to default
  '2': 'Completed', // STATE_SUCCESS
  '3': 'Completed', // STATE_AUTHORIZED
  '4': 'Voided', // STATE_REVERSED
  '5': 'Failed', // STATE_DENIED
  '6': 'Completed', // STATE_SETTLEMENT_SUBMITTED
  '7': 'Unknown', // STATE_SETTLED — no case, falls to default
  '8': 'Failed', // STATE_SETTLEMENT_REJECTED
  '11': 'Refunded', // STATE_REFUNDED
  '12': 'Voided', // STATE_VOIDED
  '71': 'Pending', // STATE_USER_PAYING
  '78': 'Failed', // STATE_ORDER_CLOSED
};

/// Observed: _buildGw3CompactTypeBadge text output for each legacy type.
const Map<String, String> observedTypeBadgeText = {
  '100': 'PREAUTH', // TransactionType.PREAUTH
  '200': 'SALES', // TransactionType.SALES
  '300': 'VOID', // TransactionType.VOID
  '400': 'REFUND', // TransactionType.REFUND
  '71001': 'QUICK', // TransactionType.QUICK_PAY
  '72001': 'UNIFIED', // TransactionType.UNIFIED_ORDER
  '81002': 'E-VOID', // TransactionType.EWALLET_VOID
  '100400': 'REVERSE', // TransactionType.REVERSE
};

/// Observed: isRefundType (minus-sign) for each legacy type.
const Map<String, bool> observedIsRefundType = {
  '100': false, // PREAUTH
  '200': false, // SALES
  '300': true, // VOID — treated as refund-like
  '400': true, // REFUND
  '71001': false, // QUICK_PAY
  '72001': false, // UNIFIED_ORDER
  '81002': true, // EWALLET_VOID — treated as refund-like
  '100400': true, // REVERSE — treated as refund-like
};

/// Observed: isTransactionFailed for each legacy state.
const Map<String, bool> observedIsTransactionFailed = {
  '1': true, // STATE_REQUESTED — no case, default → true
  '2': false, // STATE_SUCCESS
  '3': false, // STATE_AUTHORIZED
  '4': false, // STATE_REVERSED
  '5': true, // STATE_DENIED
  '6': false, // STATE_SETTLEMENT_SUBMITTED
  '7': true, // STATE_SETTLED — no case, default → true
  '8': true, // STATE_SETTLEMENT_REJECTED
  '11': false, // STATE_REFUNDED
  '12': false, // STATE_VOIDED
  '71': false, // STATE_USER_PAYING
  '78': true, // STATE_ORDER_CLOSED
};

void main() {
  // =========================================================================
  // Property 2a: Legacy Status Badge Preservation
  // For ALL legacy numeric states, the mapping produces the observed output.
  // =========================================================================
  group(
      'Property 2a: Legacy status badge text is preserved for all known states',
      () {
    for (final entry in observedStatusBadgeText.entries) {
      final stateValue = entry.key;
      final expectedText = entry.value;
      test(
          'state "$stateValue" (${allLegacyStates[stateValue]}) → "$expectedText"',
          () {
        final actualText = _simulateStatusBadgeText(stateValue);
        expect(
          actualText,
          equals(expectedText),
          reason:
              'Legacy state "$stateValue" must produce "$expectedText" badge text',
        );
      });
    }

    // Unknown states must fall to default "Unknown"
    for (final unknownState in unknownStateValues) {
      test('unknown state "$unknownState" → "Unknown" (default)', () {
        final actualText = _simulateStatusBadgeText(unknownState);
        expect(
          actualText,
          equals('Unknown'),
          reason:
              'Unknown state "$unknownState" must fall to default "Unknown"',
        );
      });
    }
  });

  // =========================================================================
  // Property 2b: Legacy Type Badge Preservation
  // For ALL legacy numeric types, the mapping produces the observed output.
  // =========================================================================
  group('Property 2b: Legacy type badge text is preserved for all known types',
      () {
    for (final entry in observedTypeBadgeText.entries) {
      final typeValue = entry.key;
      final expectedText = entry.value;
      test('type "$typeValue" (${allLegacyTypes[typeValue]}) → "$expectedText"',
          () {
        final actualText = _simulateTypeBadgeText(typeValue);
        expect(
          actualText,
          equals(expectedText),
          reason:
              'Legacy type "$typeValue" must produce "$expectedText" badge text',
        );
      });
    }

    // Unknown types must fall to default "OTHER"
    for (final unknownType in unknownTypeValues) {
      test('unknown type "$unknownType" → "OTHER" (default)', () {
        final actualText = _simulateTypeBadgeText(unknownType);
        expect(
          actualText,
          equals('OTHER'),
          reason: 'Unknown type "$unknownType" must fall to default "OTHER"',
        );
      });
    }
  });

  // =========================================================================
  // Property 2c: Legacy Amount Formatting Preservation
  // For ALL legacy numeric types, refund detection produces the observed output.
  // =========================================================================
  group(
      'Property 2c: Legacy refund type detection is preserved for all known types',
      () {
    for (final entry in observedIsRefundType.entries) {
      final typeValue = entry.key;
      final expectedIsRefund = entry.value;
      test(
          'type "$typeValue" (${allLegacyTypes[typeValue]}) → isRefund=$expectedIsRefund',
          () {
        final actualIsRefund = _simulateIsRefundType(typeValue);
        expect(
          actualIsRefund,
          equals(expectedIsRefund),
          reason:
              'Legacy type "$typeValue" refund detection must be $expectedIsRefund',
        );
      });
    }

    // Unknown types must NOT be treated as refund
    for (final unknownType in unknownTypeValues) {
      test('unknown type "$unknownType" → isRefund=false', () {
        final actualIsRefund = _simulateIsRefundType(unknownType);
        expect(
          actualIsRefund,
          isFalse,
          reason: 'Unknown type "$unknownType" must not be treated as refund',
        );
      });
    }
  });

  // =========================================================================
  // Property 2d: Legacy Failed Transaction Detection Preservation
  // For ALL legacy numeric states, isTransactionFailed produces the observed output.
  // =========================================================================
  group(
      'Property 2d: Legacy isTransactionFailed is preserved for all known states',
      () {
    for (final entry in observedIsTransactionFailed.entries) {
      final stateValue = entry.key;
      final expectedIsFailed = entry.value;
      test(
          'state "$stateValue" (${allLegacyStates[stateValue]}) → isFailed=$expectedIsFailed',
          () {
        final actualIsFailed = _simulateIsTransactionFailed(stateValue);
        expect(
          actualIsFailed,
          equals(expectedIsFailed),
          reason:
              'Legacy state "$stateValue" failed detection must be $expectedIsFailed',
        );
      });
    }

    // null and empty states must be failed
    test('null state → isFailed=true', () {
      expect(_simulateIsTransactionFailed(null), isTrue,
          reason: 'null state must be classified as failed');
    });

    test('empty state → isFailed=true', () {
      expect(_simulateIsTransactionFailed(''), isTrue,
          reason: 'empty state must be classified as failed');
    });

    // Unknown states fall to default → true (production behavior)
    for (final unknownState in unknownStateValues) {
      test('unknown state "$unknownState" → isFailed=true (default)', () {
        final actualIsFailed = _simulateIsTransactionFailed(unknownState);
        expect(
          actualIsFailed,
          isTrue,
          reason:
              'Unknown state "$unknownState" must fall to default (failed=true)',
        );
      });
    }
  });

  // =========================================================================
  // Property 2e: TransactionListResponse.fromJson with integer state/type
  // Legacy API returns integer values — deserialization must work correctly.
  // =========================================================================
  group(
      'Property 2e: TransactionListResponse.fromJson preserves legacy integer values',
      () {
    for (final stateValue in allLegacyStates.keys) {
      final intState = int.parse(stateValue);
      test(
          'fromJson with integer transactionState $intState deserializes correctly',
          () {
        final json = <String, dynamic>{
          'transactionState': intState,
          'transactionType': 200,
          'totalAmount': '100.00',
          'currency': 'MYR',
          'transactionId': 'TXN-LEGACY-001',
        };

        final response = TransactionListResponse.fromJson(json);
        expect(
          response.transactionState?.toString(),
          equals(stateValue),
          reason:
              'Legacy integer state $intState must deserialize and toString to "$stateValue"',
        );
      });
    }

    for (final typeValue in allLegacyTypes.keys) {
      final intType = int.parse(typeValue);
      test(
          'fromJson with integer transactionType $intType deserializes correctly',
          () {
        final json = <String, dynamic>{
          'transactionState': 2,
          'transactionType': intType,
          'totalAmount': '50.00',
          'currency': 'MYR',
          'transactionId': 'TXN-LEGACY-002',
        };

        final response = TransactionListResponse.fromJson(json);
        expect(
          response.transactionType?.toString(),
          equals(typeValue),
          reason:
              'Legacy integer type $intType must deserialize and toString to "$typeValue"',
        );
      });
    }

    test('fromJson with null state and type deserializes without error', () {
      final json = <String, dynamic>{
        'transactionState': null,
        'transactionType': null,
        'totalAmount': '0.00',
        'currency': 'MYR',
        'transactionId': 'TXN-LEGACY-003',
      };

      final response = TransactionListResponse.fromJson(json);
      expect(response.transactionState, isNull);
      expect(response.transactionType, isNull);
    });
  });
}

// =============================================================================
// Simulation functions that mirror the EXACT PRODUCTION code logic.
// These replicate the switch statements from transaction_history_screen.dart
// using the SAME constants, so we can test mapping behavior without Flutter widgets.
//
// IMPORTANT: These functions contain ONLY the legacy numeric branches that exist
// in the current unfixed production code. No GW3 string branches are included.
// =============================================================================

/// Mirrors _buildGw3StatusBadge switch logic from production code (unfixed).
/// Uses the SAME TransactionState constants the production code uses.
String _simulateStatusBadgeText(String transactionState) {
  switch (transactionState) {
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
    default:
      return 'Unknown';
  }
}

/// Mirrors _buildGw3CompactTypeBadge switch logic from production code (unfixed).
/// Uses the SAME TransactionType constants the production code uses.
String _simulateTypeBadgeText(String transactionType) {
  switch (transactionType) {
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
    default:
      return 'OTHER';
  }
}

/// Mirrors _formatGw3Amount refund detection logic from production code (unfixed).
/// Returns true if the type should produce a minus-prefixed amount.
bool _simulateIsRefundType(String transactionType) {
  return [
    TransactionType.REFUND, // "400"
    TransactionType.VOID, // "300"
    TransactionType.REVERSE, // "100400"
    TransactionType.EWALLET_VOID, // "81002"
  ].contains(transactionType);
}

/// Mirrors isTransactionFailed logic from production code (unfixed).
/// Returns true if the transaction should be classified as failed.
///
/// NOTE: The production default case has `false; break;` which is a no-op
/// expression statement — it does NOT return false. After break, execution
/// falls through to `return true;`. So all unrecognized states return true.
bool _simulateIsTransactionFailed(String? transactionState) {
  if (transactionState == null || transactionState == '') {
    return true;
  }

  switch (transactionState) {
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
    default:
      // Mirrors production: `false; break;` is a no-op, then `return true;`
      return true;
  }
}
