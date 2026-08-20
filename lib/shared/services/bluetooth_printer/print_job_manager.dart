import 'dart:typed_data';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import '../../../models/response/transaction_summary_AFG_response/transaction_summary_AFG_response.dart';
import '../../utils/bytes_util.dart';
import '../../utils/log_utils.dart';
import '../../widgets/custom_dialog/custom_dialog.dart';
import '../../widgets/string_utils.dart';
import 'bluetooth_printer_service.dart';
import 'models.dart';

/// Manages print job formatting and dispatch to the connected Bluetooth printer.
///
/// Captures receipt widgets as image bitmaps, converts them to ESC/POS
/// raster image commands, and sends them via [BluetoothPrinterService].
class PrintJobManager {
  /// Maximum number of retry attempts for transient send failures.
  static const int _maxRetries = 3;

  /// Delay between retry attempts.
  static const Duration _retryDelay = Duration(seconds: 1);

  /// Standard paper width for 58mm thermal printers (in pixels).
  static const int _paperWidthPx = 384;

  /// Print a transaction receipt via Bluetooth.
  ///
  /// Captures the receipt widget identified by [receiptKey] as a PNG image,
  /// converts it to ESC/POS raster commands, and sends it to the connected
  /// Bluetooth printer.
  ///
  /// Shows a success toast on completion or an error with retry on failure.
  /// Returns `true` if the receipt was printed successfully.
  ///
  /// Requirements: 4.1, 4.3, 4.4, 4.5
  static Future<bool> printReceipt({
    required BuildContext context,
    required GlobalKey receiptKey,
  }) async {
    final service = BluetoothPrinterService.instance;

    // Check if a Bluetooth printer is connected (Requirement 4.2)
    if (service.status.value != BluetoothPrinterStatus.connected) {
      CustomDialog.showToast('btPrinterNotConnected'.tr);
      LogUtils.debugLog(
        'PrintJobManager: Cannot print - no Bluetooth printer connected',
      );
      return false;
    }

    try {
      CustomDialog.showToast('btPrinterPrintingStarted'.tr);
      LogUtils.debugLog('PrintJobManager: Capturing receipt image...');

      // Step 1: Capture the receipt widget as a PNG image
      final Uint8List pngBytes = await BytesUtil.capturePng(receiptKey);
      LogUtils.debugLog(
        'PrintJobManager: Captured PNG (${pngBytes.length} bytes)',
      );

      // Step 2: Convert PNG to ESC/POS raster image commands
      final List<int> escPosBytes = await _convertToEscPos(pngBytes);
      LogUtils.debugLog(
        'PrintJobManager: Generated ESC/POS data (${escPosBytes.length} bytes)',
      );

      // Step 3: Send formatted bytes with retry logic
      final bool success = await _sendWithRetry(escPosBytes);

      if (success) {
        CustomDialog.showToast('btPrinterPrintSuccess'.tr);
        LogUtils.debugLog('PrintJobManager: Receipt printed successfully');
        return true;
      }

      // All retries exhausted — show error with retry option
      _showRetryDialog(context, receiptKey);
      return false;
    } catch (e) {
      LogUtils.debugLog('PrintJobManager: Print receipt error - $e');
      _showRetryDialog(context, receiptKey);
      return false;
    }
  }

  /// Convert a PNG image to ESC/POS raster byte commands.
  ///
  /// Decodes the PNG, resizes it to fit the thermal printer paper width,
  /// converts to grayscale, and generates ESC/POS raster image data
  /// with feed and cut commands.
  static Future<List<int>> _convertToEscPos(Uint8List pngBytes) async {
    final CapabilityProfile profile = await CapabilityProfile.load();
    final Generator generator = Generator(PaperSize.mm58, profile);

    List<int> bytes = [];
    bytes += generator.reset();

    // Decode PNG to image
    final img.Image? decodedImage = img.decodeImage(pngBytes);
    if (decodedImage == null) {
      throw Exception('Failed to decode receipt image');
    }

    // Resize to fit paper width while maintaining aspect ratio
    final img.Image resizedImage = _resizeForPaper(decodedImage);

    // Generate raster image ESC/POS commands
    bytes += generator.imageRaster(resizedImage);
    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  /// Resize an image to fit the thermal printer paper width.
  ///
  /// Maintains the original aspect ratio. Only downsizes if the image
  /// is wider than [_paperWidthPx]; images narrower than the paper
  /// width are left unchanged.
  static img.Image _resizeForPaper(img.Image image) {
    if (image.width <= _paperWidthPx) return image;

    return img.copyResize(image, width: _paperWidthPx);
  }

  /// Send ESC/POS data to the Bluetooth printer with automatic retry.
  ///
  /// Attempts up to [_maxRetries] times with a [_retryDelay] between
  /// each attempt. Returns `true` on the first successful send.
  static Future<bool> _sendWithRetry(List<int> data) async {
    final service = BluetoothPrinterService.instance;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      LogUtils.debugLog(
        'PrintJobManager: Send attempt $attempt/$_maxRetries',
      );

      final bool success = await service.sendData(data);
      if (success) return true;

      if (attempt < _maxRetries) {
        LogUtils.debugLog(
          'PrintJobManager: Retrying after ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay);
      }
    }

    LogUtils.debugLog('PrintJobManager: All send attempts failed');
    return false;
  }

  /// Show an error snackbar with a retry action button.
  ///
  /// Allows the user to retry the failed print job without navigating away.
  static void _showRetryDialog(BuildContext context, GlobalKey receiptKey) {
    Get.snackbar(
      'btPrinterPrintFailedTitle'.tr,
      'btPrinterPrintFailedMessage'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          printReceipt(context: context, receiptKey: receiptKey);
        },
        child: Text(
          'btPrinterRetry'.tr,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  /// Print a transaction summary report via Bluetooth.
  ///
  /// Formats the summary report data (acquirer, currency, date range, totals)
  /// as ESC/POS text commands and sends them to the connected Bluetooth printer.
  ///
  /// Shows a success toast on completion or an error with retry on failure.
  /// Returns `true` if the report was printed successfully.
  ///
  /// Requirements: 5.1, 5.2, 5.3
  static Future<bool> printSummaryReport({
    required BuildContext context,
    required String acquirer,
    required TransactionSummaryAFGResponse? dataSource,
  }) async {
    final service = BluetoothPrinterService.instance;

    if (service.status.value != BluetoothPrinterStatus.connected) {
      CustomDialog.showToast('btPrinterNotConnected'.tr);
      LogUtils.debugLog(
        'PrintJobManager: Cannot print report - no Bluetooth printer connected',
      );
      return false;
    }

    try {
      CustomDialog.showToast('printerReportPrintingStarted'.tr);
      LogUtils.debugLog('PrintJobManager: Formatting summary report...');

      final List<int> escPosBytes = await _formatSummaryReport(
        acquirer: acquirer,
        dataSource: dataSource,
      );
      LogUtils.debugLog(
        'PrintJobManager: Generated report ESC/POS data (${escPosBytes.length} bytes)',
      );

      final bool success = await _sendWithRetry(escPosBytes);

      if (success) {
        CustomDialog.showToast('btPrinterPrintSuccess'.tr);
        LogUtils.debugLog(
          'PrintJobManager: Summary report printed successfully',
        );
        return true;
      }

      _showReportRetryDialog(context, acquirer, dataSource);
      return false;
    } catch (e) {
      LogUtils.debugLog('PrintJobManager: Print summary report error - $e');
      _showReportRetryDialog(context, acquirer, dataSource);
      return false;
    }
  }

  /// Format summary report data into ESC/POS text byte commands.
  ///
  /// Generates a text-based report layout with acquirer header, currency,
  /// date, and transaction totals (sale, void, refund counts and amounts).
  static Future<List<int>> _formatSummaryReport({
    required String acquirer,
    required TransactionSummaryAFGResponse? dataSource,
  }) async {
    final CapabilityProfile profile = await CapabilityProfile.load();
    final Generator generator = Generator(PaperSize.mm58, profile);

    List<int> bytes = [];
    bytes += generator.reset();

    // Header: acquirer name
    bytes += generator.text(
      acquirer,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
    );
    bytes += generator.hr(ch: '=');

    // Currency (from first transaction if available)
    final String currency = _extractCurrency(dataSource);
    if (currency.isNotEmpty) {
      bytes += generator.text(
        '${'currency'.tr}: $currency',
        styles: const PosStyles(align: PosAlign.left),
      );
    }

    // Date
    final String dateStr = DateFormat('dd.MM.yyyy').format(DateTime.now());
    bytes += generator.text(
      '${'startDate'.tr}: $dateStr',
      styles: const PosStyles(align: PosAlign.left),
    );
    bytes += generator.hr();

    // Transaction totals
    final int payCount = dataSource?.totalPayCount ?? 0;
    final double payAmount = dataSource?.totalPayAmount ?? 0;
    final int voidCount = dataSource?.totalVoidCount ?? 0;
    final double voidAmount = dataSource?.totalVoidAmount ?? 0;
    final int refundCount = dataSource?.totalRefundCount ?? 0;
    final int refundAmount = dataSource?.totalRefundAmount ?? 0;
    final int totalCount = dataSource?.totalCount ?? 0;

    // Sale section
    bytes += _formatReportRow(
      generator,
      '${'txnCount'.tr}',
      payCount.toString(),
    );
    bytes += _formatReportRow(
      generator,
      '${'txnAmount'.tr}',
      StringUtils.formatAmount(payAmount / 100, '#,##0.00'),
    );
    bytes += generator.emptyLines(1);

    // Void section
    bytes += _formatReportRow(
      generator,
      '${'voidCount'.tr}:',
      voidCount.toString(),
    );
    bytes += _formatReportRow(
      generator,
      '${'voidAmt'.tr}:',
      StringUtils.formatAmount(voidAmount / 100, '#,##0.00'),
    );
    bytes += generator.emptyLines(1);

    // Refund section
    bytes += _formatReportRow(
      generator,
      '${'reportRefundCount'.tr}:',
      refundCount.toString(),
    );
    bytes += _formatReportRow(
      generator,
      '${'reportRefundAmount'.tr}:',
      StringUtils.formatAmount(refundAmount / 100, '#,##0.00'),
    );

    bytes += generator.hr(ch: '=');

    // Total count
    bytes += _formatReportRow(
      generator,
      '${'total'.tr}:',
      totalCount.toString(),
      bold: true,
    );

    bytes += generator.hr();
    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  /// Format a single label-value row for the summary report.
  static List<int> _formatReportRow(
    Generator generator,
    String label,
    String value, {
    bool bold = false,
  }) {
    return generator.row([
      PosColumn(
        text: label,
        width: 7,
        styles: PosStyles(align: PosAlign.left, bold: bold),
      ),
      PosColumn(
        text: value,
        width: 5,
        styles: PosStyles(align: PosAlign.right, bold: bold),
      ),
    ]);
  }

  /// Extract currency code from the first transaction in the data source.
  ///
  /// Returns an empty string if no transactions or currency data is available.
  static String _extractCurrency(TransactionSummaryAFGResponse? dataSource) {
    final transactions = dataSource?.transactionList;
    if (transactions == null || transactions.isEmpty) return '';
    return transactions.first.currency ?? '';
  }

  /// Show an error snackbar with retry for a failed summary report print.
  static void _showReportRetryDialog(
    BuildContext context,
    String acquirer,
    TransactionSummaryAFGResponse? dataSource,
  ) {
    Get.snackbar(
      'btPrinterPrintFailedTitle'.tr,
      'btPrinterPrintFailedMessage'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          printSummaryReport(
            context: context,
            acquirer: acquirer,
            dataSource: dataSource,
          );
        },
        child: Text(
          'btPrinterRetry'.tr,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
