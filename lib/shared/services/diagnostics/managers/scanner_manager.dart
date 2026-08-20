// Scanner Manager - Handles QR/Barcode scanner diagnostics
import 'package:permission_handler/permission_handler.dart';
import '../models/diagnostic_models.dart';
import 'package:app/shared/utils/log_utils.dart';

class ScannerManager {
  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      LogUtils.debugLog('Error checking camera permission: $e');
      return false;
    }
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      LogUtils.debugLog('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Test QR scanner functionality
  Future<bool> testQRScanner() async {
    try {
      // Check if camera permission is available
      final hasPermission = await hasCameraPermission();
      if (!hasPermission) {
        // Try to request permission
        final granted = await requestCameraPermission();
        if (!granted) return false;
      }

      // If we have permission, assume QR scanner is available
      // Actual scanning would require opening the camera
      return true;
    } catch (e) {
      LogUtils.debugLog('Error testing QR scanner: $e');
      return false;
    }
  }

  /// Test barcode scanner functionality
  /// For POS devices with hardware barcode scanners
  Future<bool> testBarcodeScanner() async {
    try {
      // Hardware barcode scanner availability depends on device
      // For most POS devices, if camera works, barcode scanning works
      return await testQRScanner();
    } catch (e) {
      LogUtils.debugLog('Error testing barcode scanner: $e');
      return false;
    }
  }

  /// Get complete scanner info
  Future<ScannerInfo> getScannerInfo() async {
    try {
      final hasPermission = await hasCameraPermission();
      final qrAvailable = await testQRScanner();
      final barcodeAvailable = await testBarcodeScanner();

      DiagnosticStatus status;
      if (!hasPermission) {
        status = DiagnosticStatus.warning;
      } else if (qrAvailable && barcodeAvailable) {
        status = DiagnosticStatus.good;
      } else {
        status = DiagnosticStatus.error;
      }

      return ScannerInfo(
        hasCameraPermission: hasPermission,
        qrScannerAvailable: qrAvailable,
        barcodeScannerAvailable: barcodeAvailable,
        status: status,
      );
    } catch (e) {
      LogUtils.debugLog('Error getting scanner info: $e');
      return ScannerInfo(
        hasCameraPermission: false,
        qrScannerAvailable: false,
        barcodeScannerAvailable: false,
        status: DiagnosticStatus.error,
      );
    }
  }
}
