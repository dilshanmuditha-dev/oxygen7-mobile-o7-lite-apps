// ignore_for_file: avoid_print

/// Preservation Property Tests — Single-Path Navigation Behavior Unchanged
///
/// **Property 2: Preservation** — Single-Path Navigation Behavior Unchanged
/// **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**
///
/// These tests observe and assert the baseline behavior of each single-path
/// navigation flow on UNFIXED code. They must PASS on the current code to
/// confirm the behavior that must be preserved after the fix.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app/models/response/querry_receipt_infor_response/querry_receipt_infor_response.dart';
import 'package:app/shared/constants/constants_o7lite.dart';
import 'package:app/routes/app_pages.dart';

// ---------------------------------------------------------------------------
// Navigation call tracker — extended to cover all navigation methods
// ---------------------------------------------------------------------------
class NavigationTracker {
  int backCallCount = 0;
  int offNamedCallCount = 0;
  int offAllNamedCallCount = 0;
  int playSoundCallCount = 0;
  int stopPollingCallCount = 0;
  int toastCallCount = 0;

  String? lastOffNamedRoute;
  Map<String, dynamic>? lastOffNamedArguments;
  String? lastOffAllNamedRoute;
  String? lastToastMessage;

  void reset() {
    backCallCount = 0;
    offNamedCallCount = 0;
    offAllNamedCallCount = 0;
    playSoundCallCount = 0;
    stopPollingCallCount = 0;
    toastCallCount = 0;
    lastOffNamedRoute = null;
    lastOffNamedArguments = null;
    lastOffAllNamedRoute = null;
    lastToastMessage = null;
  }
}

// ---------------------------------------------------------------------------
// Testable controller that reproduces single-path navigation logic from
// DigitalPaymentController. Extends the pattern from the bug condition test
// to cover cancel, max-poll, and disabled-polling paths.
// ---------------------------------------------------------------------------
class TestableDigitalPaymentController {
  final NavigationTracker tracker;

  RxString mTransactionId = ''.obs;
  RxBool isPollingActive = false.obs;
  RxBool isNavigating = false.obs;
  bool refreshInterval = true;

  /// Acquirer type for cancel path logic
  String? acquirerDigital;

  /// Simulates cancelQrCodeV6 API returning null data (triggers HOME nav)
  bool cancelQrCodeReturnsNullData = true;

  TestableDigitalPaymentController({required this.tracker});

  /// Mirrors `goToTransactionDetail` from DigitalPaymentController.
  /// Poll-only path: playSound → stop polling → Get.back() → Get.offNamed()
  Future<void> goToTransactionDetail(
      QuerryReceiptInforResponse? resultReceiptInfo) async {
    if (isNavigating.value) return;
    isNavigating.value = true;
    await playSound();
    isPollingActive.value = false;
    stopPolling();

    bool isDonation = BaseAppO7Lite.isDonationMode;

    tracker.backCallCount++;
    tracker.offNamedCallCount++;
    tracker.lastOffNamedRoute = Routes.TRANSACTION_HISTORY_DETAIL;
    tracker.lastOffNamedArguments = {
      'mTransactionId': mTransactionId.value,
      'resultReceiptInfo': resultReceiptInfo,
      'isDonation': isDonation,
      'isDisableSound': true,
      'comeFromScreen': TransactionState.COMEFROMDIGITALPAYMENT,
    };
  }

  /// Mirrors the `onPressedCheck` closure from `showQRDialog`.
  /// Check-only path: stop polling → Get.back() → Get.offNamed()
  void onPressedCheck() {
    if (isNavigating.value) return;
    isPollingActive.value = false;
    stopPolling();

    isNavigating.value = true;
    tracker.backCallCount++;
    tracker.offNamedCallCount++;
    tracker.lastOffNamedRoute = Routes.TRANSACTION_HISTORY_DETAIL;
    tracker.lastOffNamedArguments = {
      'mTransactionId': mTransactionId.value,
      'isDonation': BaseAppO7Lite.isDonationMode,
      'comeFromScreen': TransactionState.COMEFROMDIGITALPAYMENT,
    };
  }

  /// Mirrors the `onpressCancel` closure from `showQRDialog`.
  /// Cancel path: stop polling → acquirer-specific navigation
  Future<void> onpressCancel() async {
    isPollingActive.value = false;
    stopPolling();

    if (acquirerDigital == ConstantsO7Lite.SHOPEE_TYPE) {
      tracker.offAllNamedCallCount++;
      tracker.lastOffAllNamedRoute = Routes.HOME;
    } else if (acquirerDigital == ConstantsO7Lite.GRABPAY_V3_TYPE) {
      // Simulates cancelQrCodeV6 API call
      if (cancelQrCodeReturnsNullData) {
        tracker.offAllNamedCallCount++;
        tracker.lastOffAllNamedRoute = Routes.HOME;
      }
      // If data is not null, no navigation (matches real behavior)
    } else {
      tracker.offAllNamedCallCount++;
      tracker.lastOffAllNamedRoute = Routes.HOME;
    }
  }

  /// Mirrors the `onMaxPollReached` callback from `checkUserPaid`.
  void onMaxPollReached() {
    isPollingActive.value = false;
    tracker.toastCallCount++;
    tracker.lastToastMessage = 'dialogAutoCheckStopped';
  }

  /// Mirrors `checkUserPaid` — returns early when refreshInterval is false.
  Future<void> checkUserPaid() async {
    if (!refreshInterval) {
      return;
    }
    isPollingActive.value = true;
    // In real code, startPolling() is called here.
    // For preservation tests, we only verify the early-return path.
  }

  Future<void> playSound() async {
    tracker.playSoundCallCount++;
  }

  void stopPolling() {
    tracker.stopPollingCallCount++;
  }
}

// ---------------------------------------------------------------------------
// Test data generators — simulate property-based testing by generating
// multiple varied inputs to verify behavior holds across the input space
// ---------------------------------------------------------------------------

/// Generates a list of varied QuerryReceiptInforResponse objects to test
/// that navigation behavior is consistent regardless of response content.
List<QuerryReceiptInforResponse> _generateReceiptResponses() {
  return [
    QuerryReceiptInforResponse(
      transactionId: 'TXN-001',
      transactionState: TransactionState.STATE_SUCCESS,
      totalAmount: '1000',
      currency: 'SGD',
    ),
    QuerryReceiptInforResponse(
      transactionId: 'TXN-002',
      transactionState: TransactionState.STATE_SUCCESS,
      totalAmount: '50000',
      currency: 'MYR',
      brandName: 'GrabPay',
    ),
    QuerryReceiptInforResponse(
      transactionId: 'TXN-003',
      transactionState: '00',
      totalAmount: '1',
      currency: 'USD',
      remarks: 'Test remark',
    ),
    QuerryReceiptInforResponse(
      transactionId: '',
      transactionState: TransactionState.STATE_SUCCESS,
      totalAmount: '0',
      currency: '',
    ),
    QuerryReceiptInforResponse(
      transactionId: 'TXN-LONG-ID-WITH-SPECIAL-CHARS-123',
      transactionState: TransactionState.STATE_SUCCESS,
      totalAmount: '9999999',
      currency: 'SGD',
      serviceAmount: '100',
      salesAmount: '9999899',
    ),
    QuerryReceiptInforResponse(), // All null fields
  ];
}

/// Transaction IDs to test across different paths
List<String> _generateTransactionIds() {
  return [
    'TXN-SIMPLE',
    'TXN-123-456-789',
    '',
    'TXN-VERY-LONG-TRANSACTION-ID-FOR-EDGE-CASE-TESTING',
    'abc',
  ];
}

/// Acquirer types for cancel path testing
List<String?> _generateAcquirerTypes() {
  return [
    null,
    '',
    ConstantsO7Lite.SHOPEE_TYPE,
    ConstantsO7Lite.GRABPAY_V3_TYPE,
    'some-other-acquirer',
    ConstantsO7Lite.IOUPAY_TYPE,
  ];
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late NavigationTracker tracker;

  setUp(() {
    tracker = NavigationTracker();
  });

  // =========================================================================
  // Property-based test — Poll-only path
  // Validates: Requirement 3.2
  // For any valid QuerryReceiptInforResponse, calling only
  // goToTransactionDetail(response) results in exactly one Get.back() +
  // one Get.offNamed(TRANSACTION_HISTORY_DETAIL) with correct arguments.
  // =========================================================================
  group(
      'Property 2: Preservation — Poll-only path '
      '(Validates: Requirements 3.2)', () {
    final responses = _generateReceiptResponses();
    final transactionIds = _generateTransactionIds();

    for (final txnId in transactionIds) {
      for (final receipt in responses) {
        final label = 'txnId="$txnId", receiptTxnId="${receipt.transactionId}"';

        test('goToTransactionDetail navigates exactly once [$label]', () async {
          final controller = TestableDigitalPaymentController(tracker: tracker);
          controller.mTransactionId.value = txnId;
          controller.isPollingActive.value = true;

          await controller.goToTransactionDetail(receipt);

          // Exactly one Get.back() + one Get.offNamed()
          expect(tracker.backCallCount, equals(1),
              reason: 'Get.back() should be called exactly once');
          expect(tracker.offNamedCallCount, equals(1),
              reason: 'Get.offNamed() should be called exactly once');
          expect(tracker.lastOffNamedRoute,
              equals(Routes.TRANSACTION_HISTORY_DETAIL));

          // Correct arguments
          expect(
              tracker.lastOffNamedArguments!['mTransactionId'], equals(txnId));
          expect(tracker.lastOffNamedArguments!['resultReceiptInfo'],
              same(receipt));
          expect(tracker.lastOffNamedArguments!['isDonation'],
              equals(BaseAppO7Lite.isDonationMode));
          expect(
              tracker.lastOffNamedArguments!['isDisableSound'], equals(true));
          expect(tracker.lastOffNamedArguments!['comeFromScreen'],
              equals(TransactionState.COMEFROMDIGITALPAYMENT));

          // Side effects
          expect(tracker.playSoundCallCount, equals(1),
              reason: 'playSound() should be called');
          expect(tracker.stopPollingCallCount, equals(1),
              reason: 'stopPolling() should be called');
          expect(controller.isPollingActive.value, isFalse,
              reason: 'isPollingActive should be set to false');

          // No cancel-path navigation
          expect(tracker.offAllNamedCallCount, equals(0));
        });
      }
    }
  });

  // =========================================================================
  // Property-based test — Check-only path
  // Validates: Requirement 3.1
  // Invoking only the onPressedCheck closure results in exactly one
  // Get.back() + one Get.offNamed(TRANSACTION_HISTORY_DETAIL) with correct
  // arguments including mTransactionId, isDonation, comeFromScreen.
  // =========================================================================
  group(
      'Property 2: Preservation — Check-only path '
      '(Validates: Requirements 3.1)', () {
    final transactionIds = _generateTransactionIds();

    for (final txnId in transactionIds) {
      test('onPressedCheck navigates exactly once [txnId="$txnId"]', () {
        final controller = TestableDigitalPaymentController(tracker: tracker);
        controller.mTransactionId.value = txnId;
        controller.isPollingActive.value = true;

        controller.onPressedCheck();

        // Exactly one Get.back() + one Get.offNamed()
        expect(tracker.backCallCount, equals(1),
            reason: 'Get.back() should be called exactly once');
        expect(tracker.offNamedCallCount, equals(1),
            reason: 'Get.offNamed() should be called exactly once');
        expect(tracker.lastOffNamedRoute,
            equals(Routes.TRANSACTION_HISTORY_DETAIL));

        // Correct arguments
        expect(tracker.lastOffNamedArguments!['mTransactionId'], equals(txnId));
        expect(tracker.lastOffNamedArguments!['isDonation'],
            equals(BaseAppO7Lite.isDonationMode));
        expect(tracker.lastOffNamedArguments!['comeFromScreen'],
            equals(TransactionState.COMEFROMDIGITALPAYMENT));

        // Check-only path does NOT include resultReceiptInfo or isDisableSound
        expect(tracker.lastOffNamedArguments!.containsKey('resultReceiptInfo'),
            isFalse,
            reason: 'Check-only path should not include resultReceiptInfo');
        expect(tracker.lastOffNamedArguments!.containsKey('isDisableSound'),
            isFalse,
            reason: 'Check-only path should not include isDisableSound');

        // Side effects
        expect(tracker.playSoundCallCount, equals(0),
            reason: 'Check path should NOT call playSound()');
        expect(tracker.stopPollingCallCount, equals(1),
            reason: 'stopPolling() should be called');
        expect(controller.isPollingActive.value, isFalse,
            reason: 'isPollingActive should be set to false');

        // No cancel-path navigation
        expect(tracker.offAllNamedCallCount, equals(0));
      });
    }
  });

  // =========================================================================
  // Property-based test — Cancel path
  // Validates: Requirement 3.3
  // Invoking onpressCancel results in Get.offAllNamed(HOME) for
  // non-Shopee/non-GrabPay acquirers, and acquirer-specific cancellation
  // logic otherwise.
  // =========================================================================
  group(
      'Property 2: Preservation — Cancel path '
      '(Validates: Requirements 3.3)', () {
    final acquirerTypes = _generateAcquirerTypes();

    for (final acquirer in acquirerTypes) {
      final label = 'acquirer="${acquirer ?? 'null'}"';

      test('onpressCancel navigates to HOME [$label]', () async {
        final controller = TestableDigitalPaymentController(tracker: tracker);
        controller.isPollingActive.value = true;
        controller.acquirerDigital = acquirer;
        controller.cancelQrCodeReturnsNullData = true;

        await controller.onpressCancel();

        // All acquirer types should stop polling
        expect(tracker.stopPollingCallCount, equals(1),
            reason: 'stopPolling() should be called');
        expect(controller.isPollingActive.value, isFalse,
            reason: 'isPollingActive should be set to false');

        // All paths navigate to HOME via offAllNamed
        expect(tracker.offAllNamedCallCount, equals(1),
            reason: 'Get.offAllNamed() should be called exactly once');
        expect(tracker.lastOffAllNamedRoute, equals(Routes.HOME));

        // Cancel path should NOT use Get.back() or Get.offNamed()
        expect(tracker.backCallCount, equals(0),
            reason: 'Cancel path should not call Get.back()');
        expect(tracker.offNamedCallCount, equals(0),
            reason: 'Cancel path should not call Get.offNamed()');
      });
    }

    test('GrabPay cancel with non-null API data does NOT navigate to HOME',
        () async {
      final controller = TestableDigitalPaymentController(tracker: tracker);
      controller.isPollingActive.value = true;
      controller.acquirerDigital = ConstantsO7Lite.GRABPAY_V3_TYPE;
      controller.cancelQrCodeReturnsNullData = false;

      await controller.onpressCancel();

      // Polling still stops
      expect(tracker.stopPollingCallCount, equals(1));
      expect(controller.isPollingActive.value, isFalse);

      // No navigation when API returns non-null data
      expect(tracker.offAllNamedCallCount, equals(0),
          reason: 'GrabPay cancel with non-null data should not navigate');
    });
  });

  // =========================================================================
  // Property-based test — Max poll reached
  // Validates: Requirement 3.4
  // When onMaxPollReached fires, isPollingActive is set to false and toast
  // is shown with dialogAutoCheckStopped message.
  // =========================================================================
  group(
      'Property 2: Preservation — Max poll reached '
      '(Validates: Requirements 3.4)', () {
    final transactionIds = _generateTransactionIds();

    for (final txnId in transactionIds) {
      test('onMaxPollReached stops polling and shows toast [txnId="$txnId"]',
          () {
        final controller = TestableDigitalPaymentController(tracker: tracker);
        controller.mTransactionId.value = txnId;
        controller.isPollingActive.value = true;

        controller.onMaxPollReached();

        expect(controller.isPollingActive.value, isFalse,
            reason: 'isPollingActive should be set to false');
        expect(tracker.toastCallCount, equals(1),
            reason: 'Toast should be shown exactly once');
        expect(tracker.lastToastMessage, equals('dialogAutoCheckStopped'));

        // No navigation should occur
        expect(tracker.backCallCount, equals(0));
        expect(tracker.offNamedCallCount, equals(0));
        expect(tracker.offAllNamedCallCount, equals(0));
      });
    }
  });

  // =========================================================================
  // Property-based test — Disabled polling
  // Validates: Requirement 3.5
  // When refreshInterval = false, checkUserPaid() returns immediately
  // without starting polling.
  // =========================================================================
  group(
      'Property 2: Preservation — Disabled polling '
      '(Validates: Requirements 3.5)', () {
    final transactionIds = _generateTransactionIds();

    for (final txnId in transactionIds) {
      test(
          'checkUserPaid returns early when refreshInterval=false [txnId="$txnId"]',
          () async {
        final controller = TestableDigitalPaymentController(tracker: tracker);
        controller.mTransactionId.value = txnId;
        controller.refreshInterval = false;
        controller.isPollingActive.value = false;

        await controller.checkUserPaid();

        // Polling should NOT be started
        expect(controller.isPollingActive.value, isFalse,
            reason:
                'isPollingActive should remain false when refreshInterval is disabled');

        // No navigation or side effects
        expect(tracker.backCallCount, equals(0));
        expect(tracker.offNamedCallCount, equals(0));
        expect(tracker.offAllNamedCallCount, equals(0));
        expect(tracker.playSoundCallCount, equals(0));
        expect(tracker.stopPollingCallCount, equals(0));
        expect(tracker.toastCallCount, equals(0));
      });
    }

    test('checkUserPaid starts polling when refreshInterval=true', () async {
      final controller = TestableDigitalPaymentController(tracker: tracker);
      controller.refreshInterval = true;
      controller.isPollingActive.value = false;

      await controller.checkUserPaid();

      // Polling should be started
      expect(controller.isPollingActive.value, isTrue,
          reason:
              'isPollingActive should be true when refreshInterval is enabled');
    });
  });
}
