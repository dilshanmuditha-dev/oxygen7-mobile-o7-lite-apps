import 'package:animate_do/animate_do.dart';
import 'package:app/app_controller.dart';
import 'package:app/modules/main/home_controller.dart';
import 'package:app/shared/constants/colors.dart';
import 'package:app/shared/constants/common.dart';
// import 'package:app/shared/services/storage_service.dart'; // Unused - using GW3 layout for all users

import 'package:app/shared/utils/responsive_util.dart';
import 'package:app/shared/widgets/custom_text_style.dart';
import 'package:app/shared/widgets/normal_button.dart';
import 'package:app/shared/widgets/storage_memory_card.dart';
import 'package:app/shared/widgets/terminal_diagnostic_view.dart';
import 'package:app/shared/widgets/test_result_card.dart';
import 'package:app/shared/services/bluetooth_printer/bluetooth_printer_service.dart';
import 'package:app/shared/services/bluetooth_printer/models.dart';
import 'package:app/routes/app_pages.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'trouble_item_page/youtube_player.dart';
import 'trouble_shooting_controller.dart';

class TroubleShootingPage extends StatefulWidget {
  const TroubleShootingPage({Key? key}) : super(key: key);

  @override
  State<TroubleShootingPage> createState() => _TroubleShootingPageState();
}

class _TroubleShootingPageState extends State<TroubleShootingPage> {
  final AppController appController = Get.find();
  final TroubleShootingController controller = Get.find();
  HomeController homeController = Get.find();
  late AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
  }

  void listener() {
    // Implementation preserved
  }

  @override
  Widget build(BuildContext context) {
    return NormalButton(
      onPressed: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: appController.isDarkModeOn.value
            ? ColorConstants.darkScaffoldBackgroundColor
            : Color(0xFFFBFBFB),
        appBar: _buildAppBar(),
        // Use new GW3 layout for all users (GW2 and GW3)
        body: _buildGw3Layout(),
      ),
    );
  }

  // Build app bar with consistent GW3 styling
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      title: Text(
        CommonConstants.troubleshootingHelp.tr,
        style: TextStyle(
          fontFamily: 'Open Sans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: appController.isDarkModeOn.value
              ? Colors.white
              : Color(0xFF382F41),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: appController.isDarkModeOn.value
              ? ColorConstants.white
              : Color(0xFF382F41),
          size: 24,
        ),
        onPressed: () => Get.back(),
      ),
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
    );
  }

  // New GW3 layout following Figma design
  Widget _buildGw3Layout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // App Information Card
          Obx(() => _buildGw3InfoCard(
                title: CommonConstants.appInfor.tr,
                children: [
                  _buildGw3InfoRow(
                    controller.isDataLoaded.value
                        ? controller.appName.value
                        : "Loading...",
                  ),
                  _buildGw3InfoRow(
                    controller.isDataLoaded.value
                        ? "${CommonConstants.versionName.tr}: ${controller.versionName.value}"
                        : "${CommonConstants.versionName.tr}: Loading...",
                  ),
                  _buildGw3InfoRow(
                    controller.isDataLoaded.value
                        ? "${CommonConstants.versionCode.tr}: ${controller.versionCode.value}"
                        : "${CommonConstants.versionCode.tr}: Loading...",
                  ),
                ],
              )),

          const SizedBox(height: 16),

          // Device Information Card
          _buildGw3DeviceInfoCard(),

          const SizedBox(height: 16),

          // Terminal View (shows right below Device Info when running)
          Obx(() => controller.showTerminal.value
              ? _buildTerminalView()
              : const SizedBox.shrink()),

          // Storage Card
          Obx(() => StorageMemoryCard(
                title: 'troubleshootStorage'.tr,
                totalBytes: controller.storageInfo.value.totalBytes,
                usedBytes: controller.storageInfo.value.usedBytes,
                freeBytes: controller.storageInfo.value.freeBytes,
                usagePercentage: controller.storageInfo.value.usagePercentage,
                status: controller.storageInfo.value.status,
                onRefresh: controller.refreshStorage,
              )),

          // Memory Card
          Obx(() => StorageMemoryCard(
                title: 'troubleshootMemoryRam'.tr,
                totalBytes: controller.memoryInfo.value.totalBytes,
                usedBytes: controller.memoryInfo.value.usedBytes,
                freeBytes: controller.memoryInfo.value.freeBytes,
                usagePercentage: controller.memoryInfo.value.usagePercentage,
                status: controller.memoryInfo.value.status,
                onRefresh: controller.refreshMemory,
              )),

          // Section Title
          Text(
            CommonConstants.contentSpecific.tr,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: appController.isDarkModeOn.value
                  ? Colors.white
                  : const Color(0xFF382F41),
            ),
          ),

          const SizedBox(height: 16),

          // Bluetooth Printer (mobile users only)
          if (appController.isMobileUser.value) _buildBluetoothPrinterCard(),

          // Test Icons Grid
          _buildGw3TestGrid(),

          const SizedBox(height: 16),

          // Test Results (legacy - only show if terminal is closed)
          Obx(() => controller.isRunFullTest.value &&
                  !controller.isRunningTest.value &&
                  !controller.showTerminal.value
              ? _buildGw3TestResults()
              : const SizedBox.shrink()),

          const SizedBox(height: 16),

          // Action buttons
          _buildActionButtons(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Bluetooth Printer card for mobile users
  Widget _buildBluetoothPrinterCard() {
    return Obx(() {
      final isConnected = BluetoothPrinterService.instance.status.value ==
          BluetoothPrinterStatus.connected;

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
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
            children: [
              // Printer info row — taps to Bluetooth Printer screen
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Get.toNamed(Routes.BLUETOOTH_PRINTER),
                  child: Row(
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
                              'btPrinterSettingsTitle'.tr,
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: appController.isDarkModeOn.value
                                    ? Colors.white
                                    : const Color(0xFF382F41),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isConnected
                                  ? 'btPrinterConnected'.tr
                                  : 'btPrinterDisconnected'.tr,
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: isConnected
                                    ? const Color(0xFF10B981)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 22,
                        color: appController.isDarkModeOn.value
                            ? Colors.white.withOpacity(0.6)
                            : const Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
              ),

              // Test Print button — only when connected
              if (isConnected) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed(Routes.CLOUD_PRINT_TEST),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: Text(
                      'cloudPrintTestButton'.tr,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 14,
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
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  // Build terminal view for diagnostics
  Widget _buildTerminalView() {
    return Column(
      children: [
        Container(
          height: 350,
          margin: const EdgeInsets.only(bottom: 16),
          child: Obx(() => TerminalDiagnosticView(
                lines: controller.terminalLines.toList(),
                isRunning: controller.isRunningTest.value,
                currentCommand: controller.isRunningTest.value
                    ? controller.currentTestName.value
                    : null,
              )),
        ),
        // Close terminal button (only show when test is complete)
        Obx(() => !controller.isRunningTest.value
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.closeTerminal,
                      icon: const Icon(Icons.close, size: 18),
                      label: Text('btnCloseTerminal'.tr),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFF6B7280)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.runFullTest,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text('btnRunAgain'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7E01D7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink()),
        const SizedBox(height: 16),
      ],
    );
  }

  // Build action buttons
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: controller.copyDeviceInfo,
            icon: const Icon(Icons.copy, size: 18),
            label: Text('btnCopyInfo'.tr),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7E01D7),
              side: const BorderSide(color: Color(0xFF7E01D7)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: controller.shareDiagnostics,
            icon: const Icon(Icons.share, size: 18),
            label: Text('btnShareReport'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7E01D7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // Build information card for GW3
  Widget _buildGw3InfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appController.isDarkModeOn.value
              ? Color(0xFF4A5568)
              : Color(0xFFCFD3D0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: appController.isDarkModeOn.value
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: appController.isDarkModeOn.value
                    ? Colors.white
                    : Color(0xFF382F41),
              ),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  // Build info row
  Widget _buildGw3InfoRow(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Open Sans',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: appController.isDarkModeOn.value
              ? Colors.white.withOpacity(0.8)
              : Color(0xFF6B7280),
        ),
      ),
    );
  }

  // Build device info card with run test button
  Widget _buildGw3DeviceInfoCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appController.isDarkModeOn.value
              ? Color(0xFF4A5568)
              : Color(0xFFCFD3D0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: appController.isDarkModeOn.value
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CommonConstants.deviceInfor.tr,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: appController.isDarkModeOn.value
                    ? Colors.white
                    : Color(0xFF382F41),
              ),
            ),
            SizedBox(height: 12),
            Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGw3InfoRow(
                      "${CommonConstants.modeNumber.tr}: ${controller.getDeviceModelNumber.value}",
                    ),
                    _buildGw3InfoRow(
                      "S/N: ${controller.getDeviceSN.value}",
                    ),
                    _buildGw3InfoRow(
                      "${CommonConstants.androidVersion.tr}: ${controller.getOSInformation.value}",
                    ),
                    _buildGw3InfoRow(
                      "${CommonConstants.brand.tr}: ${controller.getDeviceBrand.value}",
                    ),
                  ],
                )),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    controller.runFullTest();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7E01D7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(80),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    CommonConstants.runFullTest.tr,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build test grid for GW3
  Widget _buildGw3TestGrid() {
    final listRouter = _getTestRouters();

    return Container(
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appController.isDarkModeOn.value
              ? Color(0xFF4A5568)
              : Color(0xFFCFD3D0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: appController.isDarkModeOn.value
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Obx(() => GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                // Make cells taller to fit icon + 2 lines of text
                childAspectRatio: 0.85,
              ),
              // Hide Cloud Print (last item) for POS users — only mobile users have Bluetooth printers
              itemCount: appController.isMobileUser.value
                  ? controller.listStatus.length
                  : controller.listStatus.length - 1,
              itemBuilder: (context, index) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => listRouter[index](),
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Color(0xFF7E01D7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                controller.listIconTrouble[index],
                                width: 26,
                                height: 26,
                              ),
                            ),
                          ),
                          SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              controller.listStatus[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: appController.isDarkModeOn.value
                                    ? Colors.white
                                    : Color(0xFF382F41),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )),
      ),
    );
  }

  // Build test results for GW3
  Widget _buildGw3TestResults() {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'troubleshootTestResults'.tr,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: appController.isDarkModeOn.value
                        ? Colors.white
                        : const Color(0xFF382F41),
                  ),
                ),
                Obx(() {
                  final report = controller.lastReport.value;
                  if (report != null) {
                    final passed =
                        report.testResults.values.where((r) => r.passed).length;
                    final total = report.testResults.length;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: passed == total
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'troubleshootPassedCount'.trParams({
                          'passed': '$passed',
                          'total': '$total',
                        }),
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: passed == total
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              final report = controller.lastReport.value;
              if (report != null && report.testResults.isNotEmpty) {
                return Column(
                  children: report.testResults.entries.map((entry) {
                    return FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      child: TestResultCard.fromTestResult(entry.value),
                    );
                  }).toList(),
                );
              }
              // Fallback to old style if no report
              return Column(
                children: [
                  SlideInRight(
                    child: _buildGw3TestResultItem(
                      CommonConstants.printSuccessful.tr,
                      controller.isConnectedPrinter.value,
                    ),
                  ),
                  SlideInRight(
                    delay: const Duration(milliseconds: 600),
                    child: _buildGw3TestResultItem(
                      CommonConstants.touchTest.tr,
                      true,
                    ),
                  ),
                  SlideInRight(
                    delay: const Duration(milliseconds: 800),
                    child: _buildGw3TestResultItem(
                      CommonConstants.bluetoothTest.tr,
                      controller.bluetoothState.value ==
                          BluetoothAdapterState.on,
                    ),
                  ),
                  SlideInRight(
                    delay: const Duration(milliseconds: 1000),
                    child: _buildGw3TestResultItem(
                      CommonConstants.soundTest.tr,
                      true,
                    ),
                  ),
                  SlideInRight(
                    delay: const Duration(milliseconds: 1200),
                    child: _buildGw3TestResultItem(
                      CommonConstants.scanningTest.tr,
                      true,
                    ),
                  ),
                  SlideInRight(
                    delay: const Duration(milliseconds: 1400),
                    child: _buildGw3TestResultItem(
                      CommonConstants.barcodeScanningTest.tr,
                      true,
                      isLast: true,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // Build individual test result item
  Widget _buildGw3TestResultItem(String title, bool status,
      {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: appController.isDarkModeOn.value
                        ? Colors.white
                        : Color(0xFF382F41),
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: status ? Color(0xFF10B981) : Color(0xFFF75145),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  status ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Container(
            height: 1,
            color: appController.isDarkModeOn.value
                ? Color(0xFF374151)
                : Color(0xFFF3F4F6),
          ),
      ],
    );
  }

  // Get test router functions
  List<VoidCallback> _getTestRouters() {
    return [
      () => controller.testPrinter(), // Printer test
      () => controller.testNetwork(), // WiFi/Network test
      () => Navigator.push(
            // YouTube video test
            context,
            MaterialPageRoute(builder: (context) => YoutubePlay()),
          ),
      () => controller.testBattery(), // Battery test
      () => controller.testBluetooth(), // Bluetooth test
      () => controller.testSound(), // Sound test
      () => controller.testQRScanner(), // QR Scanner test
      () => controller.testBarcodeScanner(), // Barcode Scanner test
      () => controller.testCloudPrint(), // Cloud Print (Bluetooth) test
    ];
  }

  // Legacy layout for non-GW3 users
  Widget _buildLegacyLayout() {
    return Padding(
      padding: ResponsiveUtil().getPadding(left: 24, right: 24, top: 10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeviceInfor(),
            SizedBox(height: ResponsiveUtil().getSize(16)),
            _buildDeviceInfoContainer(),
            SizedBox(height: ResponsiveUtil().getSize(16)),
            _buildTapIconText(),
            SizedBox(height: ResponsiveUtil().getSize(16)),
            _buildIconGridView(),
            SizedBox(height: ResponsiveUtil().getSize(16)),
            Obx(() => controller.isRunFullTest.value
                ? _buildTroubleShootingList()
                : const SizedBox.shrink()),
            SizedBox(height: ResponsiveUtil().getSize(100)),
          ],
        ),
      ),
    );
  }

  // Legacy methods preserved
  Widget _buildDeviceInfor() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : ColorConstants.colorDoubleShooting,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              return Align(
                alignment: Alignment.topCenter,
                child: _buildDeviceInfoText(CommonConstants.appInfor.tr),
              );
            }),
            Padding(
              padding: ResponsiveUtil().getPadding(top: 16, left: 16),
              child: Obx(() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDeviceInfoText(controller.isDataLoaded.value
                        ? "${CommonConstants.versionName.tr}: ${controller.versionName.value}"
                        : "${CommonConstants.versionName.tr}: Loading..."),
                    _buildDeviceInfoText(controller.isDataLoaded.value
                        ? "${CommonConstants.versionCode.tr}: ${controller.versionCode.value}"
                        : "${CommonConstants.versionCode.tr}: Loading..."),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : ColorConstants.colorDoubleShooting,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              return Align(
                alignment: Alignment.topCenter,
                child: _buildDeviceInfoText(CommonConstants.deviceInfor.tr),
              );
            }),
            Padding(
              padding: ResponsiveUtil().getPadding(top: 16, left: 16),
              child: Obx(() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDeviceInfoText(
                        "${CommonConstants.modeNumber.tr}: ${controller.getDeviceModelNumber.value}"),
                    _buildDeviceInfoText(
                        "S/N: ${controller.getDeviceSN.value}"),
                    _buildDeviceInfoText(
                        "${CommonConstants.androidVersion.tr}: ${controller.getOSInformation.value}"),
                    _buildDeviceInfoText(
                        "${CommonConstants.brand.tr}: ${controller.getDeviceBrand.value}"),
                  ],
                );
              }),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () {
                    controller.runFullTest();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorConstants.colorGradientNext,
                          ColorConstants.colorGradientFirst.withOpacity(.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: ResponsiveUtil().getPadding(
                      left: 30,
                      right: 30,
                      bottom: 10,
                      top: 10,
                    ),
                    child: Text(
                      CommonConstants.runFullTest.tr,
                      style: CustomTextStyles.labelBlack500Size14Fw600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoText(String text) {
    return Text(
      text,
      style: CustomTextStyles.labelBlack500Size14Fw600,
    );
  }

  Widget _buildTapIconText() {
    return Text(
      CommonConstants.contentSpecific.tr,
      style: CustomTextStyles.labelBlack500Size16Fw700,
    );
  }

  Widget _buildIconGridView() {
    final listRouter = _getTestRouters();

    return Obx(
      () => GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 30.0,
          childAspectRatio: 1.5,
        ),
        itemCount: controller.listStatus.length,
        itemBuilder: (context, index) {
          return InkWell(
            borderRadius: BorderRadius.circular(200),
            onTap: () => listRouter[index](),
            child: Column(
              children: [
                Expanded(
                  child: SvgPicture.asset(
                    controller.listIconTrouble[index],
                    fit: BoxFit.contain,
                    height: ResponsiveUtil().getSize(60),
                  ),
                ),
                SizedBox(height: ResponsiveUtil().getSize(4)),
                Text(
                  controller.listStatus[index],
                  style: CustomTextStyles.labelBlack500Size14,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTroubleShootingList() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xff94A3B8).withOpacity(.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Obx(
          () => Column(
            children: [
              SlideInRight(
                child: itemRunFullTest(
                  CommonConstants.printSuccessful.tr,
                  controller.isConnectedPrinter.value ? true : false,
                ),
              ),
              SlideInRight(
                delay: Duration(milliseconds: 600),
                child: SlideInRight(
                  child: itemRunFullTest(
                    CommonConstants.touchTest.tr,
                    true,
                  ),
                ),
              ),
              SlideInRight(
                delay: Duration(milliseconds: 800),
                child: SlideInRight(
                  child: itemRunFullTest(
                    CommonConstants.bluetoothTest.tr,
                    controller.bluetoothState.value == BluetoothAdapterState.on
                        ? true
                        : false,
                  ),
                ),
              ),
              SlideInRight(
                delay: Duration(milliseconds: 1000),
                child: SlideInRight(
                  child: itemRunFullTest(
                    CommonConstants.soundTest.tr,
                    true,
                  ),
                ),
              ),
              SlideInRight(
                delay: Duration(milliseconds: 1200),
                child: SlideInRight(
                  child: itemRunFullTest(
                    CommonConstants.scanningTest.tr,
                    true,
                  ),
                ),
              ),
              SlideInRight(
                delay: Duration(milliseconds: 1400),
                child: SlideInRight(
                  child: itemRunFullTest(
                    CommonConstants.barcodeScanningTest.tr,
                    true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget itemRunFullTest(String titleTroubleShooting, bool status) {
  return ListTile(
    dense: true,
    title: Text(
      titleTroubleShooting,
      style: CustomTextStyles.labelBlack500Size16Fw700,
    ),
    trailing: Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: status
            ? ColorConstants.greenColorText.withOpacity(.86)
            : ColorConstants.redColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        status ? Icons.check : Icons.close,
        color: ColorConstants.white,
        size: ResponsiveUtil().getSize(24),
      ),
    ),
  );
}
