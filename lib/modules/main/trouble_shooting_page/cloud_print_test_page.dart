// ignore_for_file: deprecated_member_use

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app_controller.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/services/bluetooth_printer/bluetooth_printer_service.dart';
import '../../../shared/services/bluetooth_printer/models.dart';
import '../../../shared/utils/log_utils.dart';
import '../../../shared/widgets/custom_dialog/custom_dialog.dart';

/// Test page for verifying Bluetooth cloud printer connectivity
/// by printing a sample receipt.
class CloudPrintTestPage extends StatefulWidget {
  const CloudPrintTestPage({Key? key}) : super(key: key);

  @override
  State<CloudPrintTestPage> createState() => _CloudPrintTestPageState();
}

class _CloudPrintTestPageState extends State<CloudPrintTestPage> {
  final AppController appController = Get.find();
  final BluetoothPrinterService _btService = BluetoothPrinterService.instance;
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.darkScaffoldBackgroundColor
          : const Color(0xFFFBFBFB),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildPrinterStatusCard(),
            const SizedBox(height: 16),
            _buildReceiptPreview(),
            const SizedBox(height: 24),
            _buildPrintButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      title: Text(
        'cloudPrintTestTitle'.tr,
        style: TextStyle(
          fontFamily: 'Open Sans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: appController.isDarkModeOn.value
              ? Colors.white
              : const Color(0xFF382F41),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: appController.isDarkModeOn.value
              ? ColorConstants.white
              : const Color(0xFF382F41),
          size: 24,
        ),
        onPressed: () => Get.back(),
      ),
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
    );
  }

  Widget _buildPrinterStatusCard() {
    return Obx(() {
      final status = _btService.status.value;
      final isConnected = status == BluetoothPrinterStatus.connected;
      final device = _btService.connectedDevice;
      final printerName = device?.platformName ?? 'cloudPrintUnknown'.tr;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: appController.isDarkModeOn.value
              ? ColorConstants.grey800
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isConnected ? const Color(0xFF10B981) : const Color(0xFFF75145),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isConnected ? Icons.print : Icons.print_disabled,
                size: 28,
                color: isConnected
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF75145),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      printerName,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: appController.isDarkModeOn.value
                            ? Colors.white
                            : const Color(0xFF382F41),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isConnected
                          ? 'cloudPrintStatusConnected'.tr
                          : 'cloudPrintStatusDisconnected'.tr,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 13,
                        color: isConnected
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF75145),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildReceiptPreview() {
    final now = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            Text(
              'cloudPrintPreviewTitle'.tr,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: appController.isDarkModeOn.value
                    ? const Color(0xFF382F41)
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            // Receipt content preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    '*** TEST RECEIPT ***',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'OxPay Lite',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Divider(color: Color(0xFF9CA3AF)),
                  _receiptRow('cloudPrintDate'.tr, now),
                  _receiptRow('cloudPrintMerchant'.tr, 'OxPay Lite Test'),
                  _receiptRow('cloudPrintTerminal'.tr, 'CLOUD-001'),
                  const Divider(color: Color(0xFF9CA3AF)),
                  _receiptRow('cloudPrintItem'.tr, 'Test Print'),
                  _receiptRow('cloudPrintQty'.tr, '1'),
                  _receiptRow('cloudPrintAmount'.tr, '0.00'),
                  const Divider(color: Color(0xFF9CA3AF)),
                  const SizedBox(height: 4),
                  const Text(
                    '*** END OF TEST ***',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 13,
              color: Color(0xFF4B5563),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintButton() {
    return Obx(() {
      final isConnected =
          _btService.status.value == BluetoothPrinterStatus.connected;

      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: (isConnected && !_isPrinting) ? _printTestReceipt : null,
          icon: _isPrinting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.print, size: 20),
          label: Text(
            _isPrinting ? 'cloudPrintPrinting'.tr : 'cloudPrintTestButton'.tr,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7E01D7),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF7E01D7).withOpacity(0.5),
            disabledForegroundColor: Colors.white.withOpacity(0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(80),
            ),
            elevation: 0,
          ),
        ),
      );
    });
  }

  Future<void> _printTestReceipt() async {
    setState(() => _isPrinting = true);

    try {
      LogUtils.debugLog('CloudPrintTestPage: Generating test receipt...');

      final escPosBytes = await _generateTestReceipt();
      LogUtils.debugLog(
        'CloudPrintTestPage: Generated ${escPosBytes.length} bytes',
      );

      final success = await _btService.sendData(escPosBytes);

      if (success) {
        CustomDialog.showToast('cloudPrintSuccess'.tr);
        LogUtils.debugLog('CloudPrintTestPage: Test receipt printed');
      } else {
        CustomDialog.showToast('cloudPrintFailed'.tr);
        LogUtils.debugLog('CloudPrintTestPage: Print failed');
      }
    } catch (e) {
      LogUtils.debugLog('CloudPrintTestPage: Error - $e');
      CustomDialog.showToast('cloudPrintFailed'.tr);
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  /// Generate ESC/POS byte commands for a test receipt.
  Future<List<int>> _generateTestReceipt() async {
    final CapabilityProfile profile = await CapabilityProfile.load();
    final Generator generator = Generator(PaperSize.mm58, profile);
    final now = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

    List<int> bytes = [];
    bytes += generator.reset();

    // Header
    bytes += generator.text(
      '*** TEST RECEIPT ***',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
    );
    bytes += generator.text(
      'OxPay Lite',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
      ),
    );
    bytes += generator.hr(ch: '=');

    // Info rows
    bytes += generator.row([
      PosColumn(
          text: 'Date:',
          width: 4,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: now, width: 8, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Merchant:',
          width: 4,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: 'OxPay Lite Test',
          width: 8,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Terminal:',
          width: 4,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: 'CLOUD-001',
          width: 8,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.hr();

    // Items
    bytes += generator.row([
      PosColumn(
          text: 'Item:',
          width: 4,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: 'Test Print',
          width: 8,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Qty:',
          width: 4,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: '1', width: 8, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Amount:',
          width: 4,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: '0.00',
          width: 8,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.hr(ch: '=');

    // Footer
    bytes += generator.text(
      '*** END OF TEST ***',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
      ),
    );
    bytes += generator.text(
      'cloudPrintFooter'.tr,
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }
}
