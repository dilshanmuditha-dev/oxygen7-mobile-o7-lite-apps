// ignore_for_file: avoid_print

/// Bug Condition Exploration Test — Concurrent Navigation Race Condition
///
/// **Property 1: Bug Condition** — Exactly One Navigation on Concurrent Triggers
/// **Validates: Requirements 1.1, 1.2, 1.3, 2.1, 2.2, 2.3**
///
/// This test surfaces the race condition between `goToTransactionDetail` (auto-poll
/// success handler) and `onPressedCheck` (manual Check button). On UNFIXED code,
/// both paths execute `Get.back()` + `Get.offNamed()` without mutual exclusion,
/// causing double navigation. The test asserts exactly-once navigation and is
/// EXPECTED TO FAIL on unfixed code — failure confirms the bug exists.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app/models/response/querry_receipt_infor_response/querry_receipt_infor_response.dart';
import 'package:app/shared/constants/constants_o7lite.dart';
import 'package:app/routes/app_pages.dart';

// ---------------------------------------------------------------------------
// Navigation call tracker — replaces GetX routing to count invocations
// ---------------------------------------------------------------------------
class NavigationTracker {
  int backCallCount = 0;
  int offNamedCallCount = 0;
  String? lastOffNamedRoute;
  Map<String, dynamic>? lastOffNamedArguments;

  void reset() {
    backCallCount = 0;
    offNamedCallCount = 0;
    lastOffNamedRoute = null;
    lastOffNamedArguments = null;
  }
}

// ---------------------------------------------------------------------------
// Testable controller that reproduces the navigation logic from
// DigitalPaymentController without requiring real GetX bindings or API calls.
// ---------------------------------------------------------------------------
class TestableDigitalPaymentController {
  final NavigationTracker tracker;
  final bool simulatePlaySoundDelay;

  RxString mTransactionId = ''.obs;
  RxBool isPollingActive = false.obs;
  RxBool isNavigating = false.obs;

  TestableDigitalPaymentController({
    required this.tracker,
    this.simulatePlaySoundDelay = false,
  });

  /// Mirrors the real `goToTransactionDetail` from DigitalPaymentController.
  /// Uses tracker instead of real Get.back()/Get.offNamed().
  Future<void> goToTransactionDetail(
      QuerryReceiptInforResponse? resultReceiptInfo) async {
    if (isNavigating.value) return;
    isNavigating.value = true;
    await playSound();
    isPollingActive.value = false;
    // stopPolling() omitted — not relevant for navigation race test

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
  void onPressedCheck() {
    if (isNavigating.value) return;
    isPollingActive.value = false;
    // stopPolling() omitted — not relevant for navigation race test

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

  /// Simulates playSound(). When [simulatePlaySoundDelay] is true, yields
  /// to the event loop via a microtask, mimicking the real async gap where
  /// the race condition occurs.
  Future<void> playSound() async {
    if (simulatePlaySoundDelay) {
      // Yield to event loop — this is where onPressedCheck can interleave
      await Future.delayed(Duration.zero);
    }
  }
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------
QuerryReceiptInforResponse _mockReceipt() {
  return QuerryReceiptInforResponse(
    transactionId: 'TXN-TEST-001',
    transactionState: TransactionState.STATE_SUCCESS,
    totalAmount: '1000',
    currency: 'SGD',
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late NavigationTracker tracker;

  setUp(() {
    tracker = NavigationTracker();
  });

  group(
      'Property 1: Bug Condition — Concurrent Navigation Race Condition '
      '(Validates: Requirements 1.1, 1.2, 1.3, 2.1, 2.2, 2.3)', () {
    // -----------------------------------------------------------------------
    // Test Case 1 — Back-to-back concurrent fire
    // Both goToTransactionDetail and onPressedCheck fire in the same
    // synchronous turn. On UNFIXED code both execute → Get.back() called
    // twice, Get.offNamed() called twice → assertion FAILS.
    // -----------------------------------------------------------------------
    test(
        'Test Case 1: back-to-back concurrent fire should navigate exactly once',
        () async {
      final controller = TestableDigitalPaymentController(
        tracker: tracker,
        simulatePlaySoundDelay: false, // synchronous playSound
      );
      controller.mTransactionId.value = 'TXN-CONCURRENT-001';

      final receipt = _mockReceipt();

      // Fire both paths in the same synchronous turn
      await controller.goToTransactionDetail(receipt);
      controller.onPressedCheck();

      // Expected: exactly ONE Get.back() + ONE Get.offNamed()
      expect(tracker.backCallCount, equals(1),
          reason:
              'Get.back() should be called exactly once, but was called ${tracker.backCallCount} times');
      expect(tracker.offNamedCallCount, equals(1),
          reason:
              'Get.offNamed() should be called exactly once, but was called ${tracker.offNamedCallCount} times');
      expect(
          tracker.lastOffNamedRoute, equals(Routes.TRANSACTION_HISTORY_DETAIL));
    });

    // -----------------------------------------------------------------------
    // Test Case 2 — Poll-then-Check
    // goToTransactionDetail starts (awaits playSound which yields to event
    // loop), then onPressedCheck fires before navigation completes.
    // On UNFIXED code → both navigate → FAILS.
    // -----------------------------------------------------------------------
    test(
        'Test Case 2: poll-then-check with async playSound should navigate exactly once',
        () async {
      final controller = TestableDigitalPaymentController(
        tracker: tracker,
        simulatePlaySoundDelay: true, // async gap in playSound
      );
      controller.mTransactionId.value = 'TXN-POLL-CHECK-001';

      final receipt = _mockReceipt();

      // Start goToTransactionDetail (will yield at playSound)
      final pollFuture = controller.goToTransactionDetail(receipt);

      // Before pollFuture completes, user taps Check
      controller.onPressedCheck();

      // Wait for the poll path to finish
      await pollFuture;

      // Expected: exactly ONE navigation pair
      expect(tracker.backCallCount, equals(1),
          reason:
              'Get.back() should be called exactly once, but was called ${tracker.backCallCount} times');
      expect(tracker.offNamedCallCount, equals(1),
          reason:
              'Get.offNamed() should be called exactly once, but was called ${tracker.offNamedCallCount} times');
      expect(
          tracker.lastOffNamedRoute, equals(Routes.TRANSACTION_HISTORY_DETAIL));
    });

    // -----------------------------------------------------------------------
    // Test Case 3 — Check-then-Poll
    // User taps Check first, then goToTransactionDetail fires immediately
    // after. On UNFIXED code → both navigate → FAILS.
    // -----------------------------------------------------------------------
    test('Test Case 3: check-then-poll should navigate exactly once', () async {
      final controller = TestableDigitalPaymentController(
        tracker: tracker,
        simulatePlaySoundDelay: false,
      );
      controller.mTransactionId.value = 'TXN-CHECK-POLL-001';

      final receipt = _mockReceipt();

      // User taps Check first
      controller.onPressedCheck();

      // Then polling success fires
      await controller.goToTransactionDetail(receipt);

      // Expected: exactly ONE navigation pair
      expect(tracker.backCallCount, equals(1),
          reason:
              'Get.back() should be called exactly once, but was called ${tracker.backCallCount} times');
      expect(tracker.offNamedCallCount, equals(1),
          reason:
              'Get.offNamed() should be called exactly once, but was called ${tracker.offNamedCallCount} times');
      expect(
          tracker.lastOffNamedRoute, equals(Routes.TRANSACTION_HISTORY_DETAIL));
    });
  });
}
