// ignore_for_file: must_call_super, deprecated_member_use

/// Controller-level tests for the Scan_Timeout, camera lifecycle, and detection
/// gating added in Requirements 12 / 13 / 14.
///
/// _Requirements: 6.7, 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7, 14.2, 14.3_
///
/// ## Test seam
///
/// The live camera cannot run under `flutter test`, so [ScanQrCodeController]
/// exposes an injectable [MobileScannerController]. These tests pass a
/// hand-written [_FakeMobileScannerController] (a real subclass of
/// `MobileScannerController`, so no platform channel is ever touched) that:
///   * records `start()` / `stop()` / `pause()` / `dispose()` invocations by
///     overriding each with the exact package signature and returning
///     `Future<void>.value()`, and
///   * exposes a settable camera permission through [setCameraPermission],
///     which drives `value.hasCameraPermission` by toggling the inherited
///     `MobileScannerState` (`hasCameraPermission` is derived from
///     `isInitialized` and the absence of a `permissionDenied` error).
///
/// `mocktail` / `mockito` are not in `dev_dependencies`, so no mocking package
/// is added — the hand-written fake covers every seam the tests need.
///
/// The controller resolves an [AppController] via `Get.find()` in a field
/// initializer, so a lifecycle-neutralized [_FakeAppController] (same pattern as
/// `scan_qr_code_screen_test.dart`) is registered before it is constructed.
/// `handleBarcode` fires the tick sound fire-and-forget, so
/// `ScannerSoundService.instance` is swapped for a no-op fake to keep the tests
/// off the audio platform channel.
///
/// Timer-driven cases advance `ScanQrCodeController.scanTimeout` with
/// `package:fake_async` (no real waiting, no pending-timer noise). The single
/// navigation case (Cancel returns null) uses a `GetMaterialApp` + a pushed
/// route so `Get.back()`'s null result is genuinely observed; every other case
/// asserts against the fake's counters and the reactive `uiState`.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:app/app_controller.dart';
import 'package:app/modules/main/scan_qr_code/scan_qr_code_controller.dart';
import 'package:app/shared/services/scanner_sound_service.dart';
import 'package:app/shared/utils/app_flavor_helper.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// [AppController] whose lifecycle does no platform work.
class _FakeAppController extends AppController {
  _FakeAppController() : super(AppFlavor.development);

  @override
  void onInit() {}

  @override
  void onClose() {}
}

/// No-op [ScannerSoundService] so `handleBarcode`'s fire-and-forget tick never
/// touches the audio platform channel during a controller test.
class _FakeScannerSoundService extends ScannerSoundService {
  @override
  Future<void> playTick() async {}
}

/// Hand-written fake camera controller. It subclasses the real
/// `MobileScannerController` and overrides only the lifecycle methods so no
/// platform channel is ever invoked; each override records the call count and
/// returns an already-completed future to match the package signatures.
class _FakeMobileScannerController extends MobileScannerController {
  _FakeMobileScannerController() : super(autoStart: false);

  int startCount = 0;
  int stopCount = 0;
  int pauseCount = 0;
  int disposeCount = 0;

  /// Drives `value.hasCameraPermission`. `hasCameraPermission` is
  /// `isInitialized && error?.errorCode != permissionDenied`, so an initialized
  /// state with no error reports permission granted, and the default
  /// uninitialized state reports permission denied.
  void setCameraPermission(bool granted) {
    value = value.copyWith(isInitialized: granted, error: null);
  }

  @override
  Future<void> start({
    CameraFacing? cameraDirection,
    CameraLensType? cameraLensType,
  }) async {
    startCount++;
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> pause() async {
    pauseCount++;
  }

  @override
  Future<void> dispose() async {
    // Intentionally does NOT call super.dispose(): the real implementation
    // reaches the platform channel. Recording the call is all the tests need.
    disposeCount++;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const BarcodeCapture _validCapture = BarcodeCapture(
  barcodes: <Barcode>[Barcode(displayValue: 'X')],
);

/// Registers the neutralized [AppController] then constructs and registers the
/// [ScanQrCodeController] with the given [fake]. `Get.put` triggers `onInit`
/// synchronously (verified against GetX's `_startController`), so the camera is
/// started and the Scan_Timeout timer is scheduled in the current zone.
ScanQrCodeController _putController(_FakeMobileScannerController fake) {
  Get.put<AppController>(_FakeAppController());
  final ScanQrCodeController controller =
      ScanQrCodeController(cameraController: fake);
  Get.put<ScanQrCodeController>(controller);
  return controller;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Re-assert testMode every test: pumping a GetMaterialApp (the Cancel case)
    // swaps GetX's root controller, which resets the flag and would otherwise
    // make a later contextless Get.back throw instead of no-op.
    Get.testMode = true;
    ScannerSoundService.instance = _FakeScannerSoundService();
  });

  tearDown(() {
    // Delete first so onClose runs (cancels the timer, removes the observer,
    // disposes the fake); then reset the rest of the container.
    if (Get.isRegistered<ScanQrCodeController>()) {
      Get.delete<ScanQrCodeController>(force: true);
    }
    Get.reset();
    ScannerSoundService.instance = ScannerSoundService();
  });

  group('Scan timeout (Req 12.1, 12.2)', () {
    test('timeout fires -> uiState timedOut and camera stopped', () {
      fakeAsync((FakeAsync async) {
        final _FakeMobileScannerController fake =
            _FakeMobileScannerController();
        final ScanQrCodeController controller = _putController(fake);

        // onInit started the camera and the countdown.
        expect(fake.startCount, 1);
        expect(controller.uiState.value, ScanUiState.scanning);

        async.elapse(ScanQrCodeController.scanTimeout);

        expect(controller.uiState.value, ScanUiState.timedOut);
        expect(fake.stopCount, 1);
      });
    });
  });

  group('Retry from the Timeout_Prompt (Req 12.4)', () {
    test('retryScan resets state, restarts camera, and re-arms the timer', () {
      fakeAsync((FakeAsync async) {
        final _FakeMobileScannerController fake =
            _FakeMobileScannerController();
        final ScanQrCodeController controller = _putController(fake);

        async.elapse(ScanQrCodeController.scanTimeout);
        expect(controller.uiState.value, ScanUiState.timedOut);
        expect(fake.startCount, 1);

        controller.retryScan();

        expect(controller.hasScanned.value, isFalse);
        expect(controller.uiState.value, ScanUiState.scanning);
        expect(fake.startCount, 2); // camera restarted

        // A fresh timer is running: advancing again re-flips to timedOut.
        async.elapse(ScanQrCodeController.scanTimeout);
        expect(controller.uiState.value, ScanUiState.timedOut);
        expect(fake.stopCount, 2); // stopped on the first and second timeout
      });
    });
  });

  group('Cancel from the Timeout_Prompt (Req 12.5, 6.7)', () {
    testWidgets('cancelFromTimeout stops the camera and pops with null result',
        (WidgetTester tester) async {
      final _FakeMobileScannerController fake = _FakeMobileScannerController();
      Get.put<AppController>(_FakeAppController());
      final ScanQrCodeController controller =
          ScanQrCodeController(cameraController: fake);

      await tester.pumpWidget(
        const GetMaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pump();

      // Register now (runs onInit -> startScan + timer) inside the widget zone.
      Get.put<ScanQrCodeController>(controller);
      expect(fake.startCount, 1);

      // Push a route so Get.back() has something to pop, and capture its result.
      const Object sentinel = Object();
      Object? popResult = sentinel;
      unawaited(
        Get.to<dynamic>(() => const Scaffold(body: SizedBox()))!
            .then((dynamic value) => popResult = value),
      );
      await tester.pumpAndSettle();

      controller.cancelFromTimeout();
      await tester.pumpAndSettle();

      expect(fake.stopCount, greaterThanOrEqualTo(1));
      // The pushed route was popped with no result (null), i.e. "no scan".
      expect(popResult, isNull);
      expect(popResult, isNot(same(sentinel)));

      // Clean up the pending Scan_Timeout timer before the test ends.
      Get.delete<ScanQrCodeController>(force: true);
      await tester.pump(const Duration(milliseconds: 200));
    });
  });

  group('Detection vs timeout interplay (Req 12.3, 12.6)', () {
    test('a successful detection cancels the timeout timer', () {
      fakeAsync((FakeAsync async) {
        final _FakeMobileScannerController fake =
            _FakeMobileScannerController();
        final ScanQrCodeController controller = _putController(fake);

        controller.handleBarcode(_validCapture);
        expect(controller.hasScanned.value, isTrue);

        // Advancing well past the timeout must NOT flip to timedOut, because
        // the timer was cancelled on detection.
        async.elapse(ScanQrCodeController.scanTimeout * 2);

        expect(controller.uiState.value, ScanUiState.scanning);
        expect(fake.stopCount, 0); // the timeout never stopped the camera
      });
    });

    test('detections are ignored while timed-out', () {
      fakeAsync((FakeAsync async) {
        final _FakeMobileScannerController fake =
            _FakeMobileScannerController();
        final ScanQrCodeController controller = _putController(fake);

        async.elapse(ScanQrCodeController.scanTimeout);
        expect(controller.uiState.value, ScanUiState.timedOut);

        // A late detection must be swallowed by the extended guard.
        controller.handleBarcode(_validCapture);

        expect(controller.hasScanned.value, isFalse);
        expect(controller.uiState.value, ScanUiState.timedOut);
      });
    });
  });

  group('App lifecycle transitions (Req 14.3)', () {
    test('with permission: inactive pauses, paused stops, resumed restarts',
        () {
      fakeAsync((FakeAsync async) {
        final _FakeMobileScannerController fake = _FakeMobileScannerController()
          ..setCameraPermission(true);
        final ScanQrCodeController controller = _putController(fake);
        expect(fake.startCount, 1); // onInit start

        // inactive -> pause + cancel countdown.
        controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
        expect(fake.pauseCount, 1);
        async.elapse(ScanQrCodeController.scanTimeout);
        expect(
            controller.uiState.value, ScanUiState.scanning); // timer cancelled

        // paused -> stop.
        controller.didChangeAppLifecycleState(AppLifecycleState.paused);
        expect(fake.stopCount, 1);

        // resumed (still active, no result) -> restart camera + countdown.
        controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(fake.startCount, 2);
        async.elapse(ScanQrCodeController.scanTimeout);
        expect(controller.uiState.value, ScanUiState.timedOut); // fresh timer
      });
    });

    test('without permission: every lifecycle transition is a no-op', () {
      fakeAsync((FakeAsync async) {
        final _FakeMobileScannerController fake =
            _FakeMobileScannerController();
        // Default state => hasCameraPermission == false.
        final ScanQrCodeController controller = _putController(fake);

        final int start0 = fake.startCount;
        final int stop0 = fake.stopCount;
        final int pause0 = fake.pauseCount;

        controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
        controller.didChangeAppLifecycleState(AppLifecycleState.paused);
        controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

        expect(fake.startCount, start0);
        expect(fake.stopCount, stop0);
        expect(fake.pauseCount, pause0);
      });
    });
  });

  group('Dispose cleanup (Req 12.7, 14.2)', () {
    test('onClose cancels the timer and disposes the camera', () {
      fakeAsync((FakeAsync async) {
        final _FakeMobileScannerController fake =
            _FakeMobileScannerController();
        _putController(fake);

        // Get.delete triggers onClose (remove observer + cancel timer +
        // dispose camera).
        Get.delete<ScanQrCodeController>(force: true);

        expect(fake.disposeCount, 1);

        // The countdown was cancelled, so advancing time stops nothing.
        async.elapse(ScanQrCodeController.scanTimeout);
        expect(fake.stopCount, 0);
      });
    });
  });
}
