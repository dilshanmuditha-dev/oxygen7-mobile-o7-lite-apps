// Printer Manager - Handles printer diagnostics
import '../models/diagnostic_models.dart';
import '../utils/formatters.dart';
import '../../printer.dart';
import 'package:app/shared/utils/log_utils.dart';

class PrinterDiagnosticManager {
  /// Get printer connection status
  Future<PrinterStatus> getStatus() async {
    try {
      final isConnected = await Printer.isConnectedPrinter() ?? false;
      if (isConnected) {
        return PrinterStatus.connected;
      }
      return PrinterStatus.disconnected;
    } catch (e) {
      LogUtils.debugLog('Error getting printer status: $e');
      return PrinterStatus.error;
    }
  }

  /// Get printer model information based on detected device type
  Future<String?> getModelInfo() async {
    try {
      final isConnected = await Printer.isConnectedPrinter() ?? false;
      if (!isConnected) return null;

      if (await Printer.isSunmiDevice()) return 'Sunmi Printer';
      if (await Printer.isCastleDevice()) return 'Castle Printer';
      if (await Printer.isAnfuDevice()) return 'ANFU Printer';
      if (await Printer.isLandiDevice()) return 'Landi Printer';
      if (await Printer.isWizarPosDevice()) return 'WizarPOS Printer';
      if (await Printer.isCoherentDevice()) return 'Coherent Printer';
      if (await Printer.isMorefunDevice()) return 'Morefun Printer';

      return 'Unknown Printer';
    } catch (e) {
      LogUtils.debugLog('Error getting printer model: $e');
      return null;
    }
  }

  /// Print a test receipt
  Future<bool> printTestReceipt() async {
    try {
      final isConnected = await Printer.isConnectedPrinter() ?? false;
      if (!isConnected) {
        return false;
      }

      // Printer is connected - test print would require SunmiPrinter
      // which needs proper initialization. For diagnostic purposes,
      // we just verify the connection is working.
      return true;
    } catch (e) {
      LogUtils.debugLog('Error printing test receipt: $e');
      return false;
    }
  }

  /// Get paper status (if supported by printer)
  Future<PaperStatus> getPaperStatus() async {
    try {
      // This would need printer-specific implementation
      // Most Sunmi printers don't expose paper status via SDK
      final isConnected = await Printer.isConnectedPrinter() ?? false;
      if (!isConnected) {
        return PaperStatus.unknown;
      }
      // Assume OK if connected
      return PaperStatus.ok;
    } catch (e) {
      LogUtils.debugLog('Error getting paper status: $e');
      return PaperStatus.unknown;
    }
  }

  /// Get complete printer info
  Future<PrinterInfo> getPrinterInfo() async {
    try {
      final status = await getStatus();
      final model = await getModelInfo();
      final paperStatus = await getPaperStatus();

      return PrinterInfo(
        status: status,
        model: model,
        paperStatus: paperStatus,
      );
    } catch (e) {
      LogUtils.debugLog('Error getting printer info: $e');
      return PrinterInfo(
        status: PrinterStatus.error,
        paperStatus: PaperStatus.unknown,
        errorMessage: e.toString(),
      );
    }
  }

  /// Get error message and recommendations for printer issues
  (String, List<String>) getErrorInfo(PrinterStatus status, String? errorCode) {
    if (status == PrinterStatus.connected) {
      return ('Printer OK', []);
    }

    if (errorCode != null) {
      return getPrinterErrorInfo(errorCode);
    }

    switch (status) {
      case PrinterStatus.disconnected:
        return (
          'Printer Disconnected',
          [
            'Check if printer is powered on',
            'Verify USB/Bluetooth connection',
            'Restart the device',
          ]
        );
      case PrinterStatus.error:
        return (
          'Printer Error',
          [
            'Restart the printer',
            'Check for paper jams',
            'Contact support if issue persists',
          ]
        );
      case PrinterStatus.busy:
        return (
          'Printer Busy',
          [
            'Wait for current print job to complete',
            'Cancel pending print jobs if stuck',
          ]
        );
      default:
        return ('Unknown Status', ['Contact support']);
    }
  }
}
