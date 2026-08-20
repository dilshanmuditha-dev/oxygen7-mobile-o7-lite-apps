// ignore_for_file: deprecated_member_use, unnecessary_null_comparison, unused_local_variable, use_build_context_synchronously

import 'dart:async'; // Timer, unawaited

import 'package:flutter/widgets.dart'; // WidgetsBinding, WidgetsBindingObserver, AppLifecycleState
import 'package:app/app_controller.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app/shared/utils/log_utils.dart';
import 'package:app/shared/services/scanner_sound_service.dart';
import 'package:app/modules/main/scan_qr_code/scanner_performance_policy.dart';

/// UI state that gates the Timeout_Prompt. Camera-start / permission errors are
/// surfaced separately by [MobileScanner.errorBuilder] (Camera_Error_State), so
/// they need not live in this enum (Req 12).
enum ScanUiState { scanning, timedOut }

class ScanQrCodeController extends GetxController with WidgetsBindingObserver {
  ScanQrCodeController({MobileScannerController? cameraController})
      : cameraController =
            cameraController ?? MobileScannerController(autoStart: false);

  /// The Camera_Controller (Req 14.1/14.4). Created with `autoStart: false` so
  /// the controller decides exactly when the camera starts. Single stable
  /// instance for the screen lifetime; injectable so tests can pass a fake
  /// (test seam).
  final MobileScannerController cameraController;

  final AppController appController = Get.find();

  final RxBool isFlashOn = false.obs;
  RxBool hasScanned = false.obs;
  final isFrontCamera = true.obs;

  /// Whether the animated Scan_Line should be rendered. Acts as the single gate
  /// for Low_Performance_Device handling (Req 7.2); defaults to the value
  /// resolved by [ScannerPerformancePolicy] so low-density displays render only
  /// the static frame while capable devices animate.
  final RxBool renderScanLine = ScannerPerformancePolicy.animationsEnabled.obs;

  /// Whether the optional Align_Hint is shown below the scan window (Req 9).
  /// Defaults ON so first-time users see the alignment instruction.
  final RxBool showAlignHint = true.obs;

  /// Scan_Timeout default. Single named constant — 45s / 60s is a one-line edit.
  static const Duration scanTimeout = Duration(seconds: 30);

  /// Reactive UI state consumed by the top-most Obx layer (Req 12).
  final Rx<ScanUiState> uiState = ScanUiState.scanning.obs;

  Timer? _timeoutTimer;

  // Add a flag to prevent multiple navigations
  bool _isNavigating = false;

  void toggleCamera() {
    isFrontCamera.value = !isFrontCamera.value;
  }

  bool isScanning = false;

  /// Start (or restart) the Camera_Preview and the Scan_Timeout countdown
  /// (Req 12.1, 14.1). Camera start is fire-and-forget; failures are surfaced by
  /// [MobileScanner.errorBuilder] (Req 13.1).
  void startScan() {
    uiState.value = ScanUiState.scanning;
    unawaited(cameraController.start());
    _startTimeout();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(scanTimeout, _onTimeout);
  }

  void _onTimeout() {
    if (hasScanned.value || _isNavigating) return; // already resolved
    unawaited(cameraController.stop()); // Req 12.2
    uiState.value = ScanUiState.timedOut; // Obx shows Timeout_Prompt (Req 12.2)
  }

  /// Retry from either the Timeout_Prompt or the Camera_Error_State
  /// (Req 12.4, 13.3). Resets state to scanning and restarts camera + timeout.
  void retryScan() {
    hasScanned.value = false;
    _isNavigating = false;
    startScan();
  }

  /// Cancel from the Timeout_Prompt: stop camera, return no result
  /// (Req 12.5, 6.7).
  void cancelFromTimeout() {
    unawaited(cameraController.stop());
    if (!_isNavigating) {
      _isNavigating = true;
      Get.back(); // null result — callers treat as "no scan"
    }
  }

  void handleBarcode(BarcodeCapture barcodes) {
    // Prevent multiple scans and navigation calls; also drop detections while
    // timed-out so the Timeout_Prompt swallows any late detection (Req 12.3).
    if (hasScanned.value ||
        _isNavigating ||
        uiState.value != ScanUiState.scanning) return;

    if (barcodes.barcodes.isNotEmpty) {
      Barcode? _barcode = barcodes.barcodes.first;
      if (_barcode != null &&
          _barcode.displayValue != null &&
          _barcode.displayValue!.isNotEmpty) {
        hasScanned.value = true;
        _isNavigating = true;
        _timeoutTimer?.cancel(); // detection resolves the session (Req 12.6)
        // Fire-and-forget audible confirmation of a successful scan (Req 11).
        // Not awaited so a sound failure can never block detection/navigation.
        ScannerSoundService.instance.playTick();
        var dataResult = _barcode.displayValue!;
        LogUtils.debugLog('QR Code scanned: $dataResult');

        // Use a slight delay to prevent race conditions
        Future.delayed(Duration(milliseconds: 100), () {
          if (Get.isRegistered<ScanQrCodeController>() && _isNavigating) {
            Get.back(result: dataResult);
          }
        });
      }
    }
  }

  // Method to handle manual back navigation
  void navigateBack() {
    if (!_isNavigating) {
      _isNavigating = true;
      Get.back();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Verified v7 guard: ignore lifecycle events until the camera has permission.
    if (!cameraController.value.hasCameraPermission) return;
    switch (state) {
      case AppLifecycleState.resumed:
        // Only resume if the screen is still active and no result was returned.
        if (!hasScanned.value &&
            !_isNavigating &&
            uiState.value == ScanUiState.scanning) {
          unawaited(cameraController.start());
          _startTimeout(); // restart the countdown on resume (Req 12/14.3)
        }
        break;
      case AppLifecycleState.inactive:
        _timeoutTimer?.cancel(); // pause the countdown while backgrounded
        unawaited(cameraController.pause());
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _timeoutTimer?.cancel();
        unawaited(cameraController
            .stop()); // release preview on background (Req 14.3)
        break;
    }
  }

  @override
  void onInit() {
    super.onInit();
    hasScanned.value = false;
    _isNavigating = false;
    WidgetsBinding.instance
        .addObserver(this); // app-lifecycle observer (Req 14.3)
    startScan(); // start camera + timeout on open (Req 12.1, 14.1)
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this); // Req 14 cleanup
    _timeoutTimer?.cancel(); // Req 12.7
    unawaited(cameraController.dispose()); // release camera hardware (Req 14.2)
    hasScanned.value = false;
    _isNavigating = false;
    super.onClose();
  }
}
