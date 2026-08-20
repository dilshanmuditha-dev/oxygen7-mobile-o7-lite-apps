// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

import '../../../app_controller.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/services/bluetooth_printer/models.dart';
import 'bluetooth_printer_controller.dart';

/// Printer selection screen for discovering, connecting to,
/// and managing Bluetooth thermal printers.
///
/// Displays the saved paired printer at the top with status and
/// action buttons, a scan trigger, and a list of discovered printers.
class BluetoothPrinterView extends GetView<BluetoothPrinterController> {
  BluetoothPrinterView({Key? key}) : super(key: key);

  final AppController appController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.darkScaffoldBackgroundColor
          : const Color(0xFFFBFBFB),
      appBar: _buildAppBar(),
      body: Obx(() => _buildBody()),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      title: Text(
        'bluetoothPrinter'.tr,
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

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Saved paired printer section
          if (controller.savedPrinter.value != null)
            _buildSavedPrinterCard(controller.savedPrinter.value!),

          if (controller.savedPrinter.value != null) const SizedBox(height: 16),

          // Scan button
          _buildScanButton(),

          const SizedBox(height: 16),

          // Scanning indicator
          if (controller.isScanning.value) _buildScanningIndicator(),

          // Discovered printers list
          if (!controller.isScanning.value &&
              controller.discoveredPrinters.isNotEmpty)
            _buildDiscoveredPrintersList(),

          // Empty state after scan completes
          if (!controller.isScanning.value &&
              controller.discoveredPrinters.isEmpty &&
              controller.printerStatus.value != BluetoothPrinterStatus.scanning)
            _buildEmptyState(),
        ],
      ),
    );
  }

  /// Card showing the saved paired printer with status and action buttons.
  Widget _buildSavedPrinterCard(PairedPrinterInfo printer) {
    final status = controller.printerStatus.value;
    final isConnected = status == BluetoothPrinterStatus.connected;
    final isConnecting = status == BluetoothPrinterStatus.connecting;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appController.isDarkModeOn.value
              ? const Color(0xFF4A5568)
              : const Color(0xFFCFD3D0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: appController.isDarkModeOn.value
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            Text(
              'bluetoothSavedPrinter'.tr,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: appController.isDarkModeOn.value
                    ? Colors.white
                    : const Color(0xFF382F41),
              ),
            ),
            const SizedBox(height: 16),

            // Printer name and status row
            Row(
              children: [
                Icon(
                  Icons.print,
                  size: 24,
                  color: isConnected
                      ? const Color(0xFF10B981)
                      : appController.isDarkModeOn.value
                          ? Colors.white.withOpacity(0.6)
                          : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer.name,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: appController.isDarkModeOn.value
                              ? Colors.white
                              : const Color(0xFF382F41),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Disconnect / Reconnect button
                Expanded(
                  child: OutlinedButton(
                    onPressed: isConnecting
                        ? null
                        : isConnected
                            ? controller.disconnectPrinter
                            : () => controller.connectToPrinter(
                                  BluetoothDevice.fromId(printer.macAddress),
                                ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isConnected
                          ? const Color(0xFFF75145)
                          : const Color(0xFF7E01D7),
                      side: BorderSide(
                        color: isConnected
                            ? const Color(0xFFF75145)
                            : const Color(0xFF7E01D7),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isConnecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isConnected
                                ? 'bluetoothDisconnect'.tr
                                : 'bluetoothReconnect'.tr,
                            style: const TextStyle(
                              fontFamily: 'Open Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Forget button
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        isConnecting ? null : controller.forgetSavedPrinter,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFF6B7280)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'bluetoothForget'.tr,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Status badge showing connected/disconnected/connecting state.
  Widget _buildStatusBadge(BluetoothPrinterStatus status) {
    Color color;
    String label;

    switch (status) {
      case BluetoothPrinterStatus.connected:
        color = const Color(0xFF10B981);
        label = 'bluetoothStatusConnected'.tr;
        break;
      case BluetoothPrinterStatus.connecting:
        color = const Color(0xFFF59E0B);
        label = 'bluetoothStatusConnecting'.tr;
        break;
      case BluetoothPrinterStatus.disconnected:
      case BluetoothPrinterStatus.error:
      case BluetoothPrinterStatus.scanning:
        color = const Color(0xFFF75145);
        label = 'bluetoothStatusDisconnected'.tr;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Scan button to trigger Bluetooth printer discovery.
  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed:
            controller.isScanning.value ? null : controller.scanForPrinters,
        icon: controller.isScanning.value
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.bluetooth_searching, size: 20),
        label: Text(
          controller.isScanning.value
              ? 'bluetoothScanning'.tr
              : 'bluetoothScanForPrinters'.tr,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7E01D7),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(80),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  /// Loading indicator shown while scanning is in progress.
  Widget _buildScanningIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF7E01D7),
          ),
          const SizedBox(height: 16),
          Text(
            'bluetoothSearching'.tr,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: appController.isDarkModeOn.value
                  ? Colors.white.withOpacity(0.8)
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  /// List of discovered Bluetooth printers with connect buttons.
  Widget _buildDiscoveredPrintersList() {
    final isConnecting =
        controller.printerStatus.value == BluetoothPrinterStatus.connecting;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appController.isDarkModeOn.value
              ? const Color(0xFF4A5568)
              : const Color(0xFFCFD3D0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: appController.isDarkModeOn.value
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'bluetoothAvailablePrinters'.tr,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: appController.isDarkModeOn.value
                    ? Colors.white
                    : const Color(0xFF382F41),
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.discoveredPrinters.length,
              separatorBuilder: (_, __) => Container(
                height: 1,
                color: appController.isDarkModeOn.value
                    ? const Color(0xFF374151)
                    : const Color(0xFFF3F4F6),
              ),
              itemBuilder: (context, index) {
                final result = controller.discoveredPrinters[index];
                final device = result.device;
                final name = device.platformName.isNotEmpty
                    ? device.platformName
                    : 'bluetoothUnknownDevice'.tr;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.print_outlined,
                        size: 22,
                        color: appController.isDarkModeOn.value
                            ? Colors.white.withOpacity(0.6)
                            : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: appController.isDarkModeOn.value
                                    ? Colors.white
                                    : const Color(0xFF382F41),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              device.remoteId.str,
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: appController.isDarkModeOn.value
                                    ? Colors.white.withOpacity(0.5)
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: isConnecting
                              ? null
                              : () => controller.connectToPrinter(device),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7E01D7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: isConnecting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'bluetoothConnect'.tr,
                                  style: const TextStyle(
                                    fontFamily: 'Open Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state shown when scan completes with no printers found.
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.bluetooth_disabled,
            size: 48,
            color: appController.isDarkModeOn.value
                ? Colors.white.withOpacity(0.3)
                : const Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 16),
          Text(
            'bluetoothNoPrintersFound'.tr,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: appController.isDarkModeOn.value
                  ? Colors.white.withOpacity(0.6)
                  : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'bluetoothNoPrintersHint'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: appController.isDarkModeOn.value
                  ? Colors.white.withOpacity(0.4)
                  : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: controller.scanForPrinters,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(
              'bluetoothRetry'.tr,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7E01D7),
              side: const BorderSide(color: Color(0xFF7E01D7)),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(80),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
