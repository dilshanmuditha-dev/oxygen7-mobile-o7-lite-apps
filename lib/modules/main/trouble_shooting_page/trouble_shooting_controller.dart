// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison

import 'dart:async';

import 'package:app/app_controller.dart';
import 'package:app/shared/constants/image_constant.dart';
import 'package:app/shared/utils/log_utils.dart';
import 'package:app/shared/services/bluetooth_printer/bluetooth_printer_service.dart';
import 'package:app/shared/services/bluetooth_printer/models.dart';
import 'package:app/shared/services/printer.dart';
import 'package:app/shared/services/diagnostics/diagnostic_service.dart';
import 'package:app/shared/services/diagnostics/models/diagnostic_models.dart'
    as diag;
import 'package:app/shared/services/diagnostics/utils/formatters.dart';
import 'package:app/shared/widgets/terminal_diagnostic_view.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart' show Rect;
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import '../../../api/api_repository.dart';
import '../../../routes/app_pages.dart';
import '../../../shared/constants/common.dart';
import '../../../shared/widgets/common_widget.dart';

class TroubleShootingController extends GetxController {
  final ApiRepository apiRepository;
  TroubleShootingController({required this.apiRepository});

  // Diagnostic Service
  late final DiagnosticService _diagnosticService;

  var listStatus = [
    CommonConstants.notConnect.tr, // 0: Printer
    CommonConstants.notConnect.tr, // 1: Network/WiFi
    CommonConstants.good.tr, // 2: Touch/Display
    CommonConstants.notConnect.tr, // 3: Battery
    CommonConstants.notConnect.tr, // 4: Bluetooth
    CommonConstants.good.tr, // 5: Sound
    CommonConstants.good.tr, // 6: QR Scanner
    CommonConstants.good.tr, // 7: Barcode Scanner
    CommonConstants.notConnect.tr, // 8: Cloud Print (Bluetooth)
  ].obs;

  List<String> listIconTrouble = [
    ImageConstant.iconTroublePrinter,
    ImageConstant.iconTroubleNetwork,
    ImageConstant.iconTroubleTouch,
    ImageConstant.iconTroubleBattery,
    ImageConstant.iconTroubleBluetooth,
    ImageConstant.iconTroubleSound,
    ImageConstant.iconTroubleQRScanner,
    ImageConstant.iconTroubleBarcodeScanner,
    ImageConstant.iconTroubleCloudPrint,
  ];

  // Device Info
  RxString getDeviceBrand = ''.obs;
  RxString getOSInformation = ''.obs;
  RxString getDeviceInfor = ''.obs;
  RxString getDeviceSN = ''.obs;
  RxString getDeviceModelNumber = ''.obs;
  RxString getBatteryLevel = ''.obs;
  RxString versionCode = ''.obs;
  RxString versionName = ''.obs;
  RxString appName = ''.obs;

  // Diagnostic Info (new)
  final Rx<diag.StorageInfo> storageInfo = diag.StorageInfo.empty().obs;
  final Rx<diag.MemoryInfo> memoryInfo = diag.MemoryInfo.empty().obs;
  final Rx<diag.BatteryInfo> batteryInfo = diag.BatteryInfo.empty().obs;
  final Rx<diag.NetworkInfo> networkInfo = diag.NetworkInfo.empty().obs;
  final Rx<diag.PrinterInfo> printerInfo = diag.PrinterInfo.empty().obs;
  final Rx<diag.BluetoothInfo> bluetoothInfo = diag.BluetoothInfo.empty().obs;
  final Rx<diag.AudioInfo> audioInfo = diag.AudioInfo.empty().obs;
  final Rx<diag.ScannerInfo> scannerInfo = diag.ScannerInfo.empty().obs;
  final Rx<diag.DiagnosticReport?> lastReport =
      Rx<diag.DiagnosticReport?>(null);

  // Status flags
  final ischeckConnect = false.obs;
  final isConnectedPrinter = false.obs;
  final isRunFullTest = false.obs;
  final isDataLoaded = false.obs;
  final isRunningTest = false.obs;

  // Progress tracking
  final currentTestIndex = 0.obs;
  final totalTests = 9.obs;
  final currentTestName = ''.obs;

  // Terminal output
  final terminalLines = <TerminalLine>[].obs;
  final showTerminal = false.obs;

  final Rx<BluetoothAdapterState> bluetoothState =
      BluetoothAdapterState.unknown.obs;
  final RxString networkStatus = CommonConstants.unknown.obs;

  late StreamSubscription<BluetoothAdapterState> adapterStateStateSubscription;
  StreamSubscription<(int, int, String)>? _progressSubscription;

  final AppController appController = Get.find();

  @override
  void onInit() async {
    super.onInit();
    _diagnosticService = DiagnosticService();

    // Listen to progress updates
    _progressSubscription =
        _diagnosticService.progressStream.listen((progress) {
      currentTestIndex.value = progress.$1;
      totalTests.value = progress.$2;
      currentTestName.value = progress.$3;
    });

    await initializeData();
  }

  Future<void> initializeData() async {
    try {
      LogUtils.debugLog('Starting trouble shooting data initialization...');

      // Load device and app info
      final deviceInfo = await _diagnosticService.getDeviceInfo();
      appName.value = deviceInfo.appName;
      getDeviceBrand.value = deviceInfo.brand;
      getOSInformation.value = deviceInfo.osVersion;
      getDeviceInfor.value = deviceInfo.model;
      getDeviceSN.value = deviceInfo.serialNumber;
      getDeviceModelNumber.value = deviceInfo.model;
      versionCode.value = deviceInfo.buildNumber;
      versionName.value = deviceInfo.appVersion;
      LogUtils.debugLog('Device info loaded');

      // Load all diagnostic info
      await refreshAllDiagnostics();
      LogUtils.debugLog('All diagnostics loaded');

      initListeners();
      LogUtils.debugLog('Listeners initialized');

      isDataLoaded.value = true;
      LogUtils.debugLog('All trouble shooting data loaded successfully');
    } catch (e) {
      LogUtils.debugLog('Error initializing trouble shooting data: $e');
      isDataLoaded.value = true;
    }
  }

  Future<void> refreshAllDiagnostics() async {
    try {
      // Load storage info
      storageInfo.value = await _diagnosticService.getStorageInfo();

      // Load memory info
      memoryInfo.value = await _diagnosticService.getMemoryInfo();

      // Load battery info
      batteryInfo.value = await _diagnosticService.getBatteryInfo();
      getBatteryLevel.value = '${batteryInfo.value.level}%';
      _updateBatteryStatus();

      // Load network info
      networkInfo.value = await _diagnosticService.getNetworkInfo();
      _updateNetworkStatus();

      // Load printer info
      printerInfo.value = await _diagnosticService.getPrinterInfo();
      _updatePrinterStatus();

      // Load Bluetooth info
      bluetoothInfo.value = await _diagnosticService.getBluetoothInfo();
      _updateBluetoothStatus();

      // Load audio info
      audioInfo.value = await _diagnosticService.getAudioInfo();
      _updateAudioStatus();

      // Load scanner info
      scannerInfo.value = await _diagnosticService.getScannerInfo();
      _updateScannerStatus();
    } catch (e) {
      LogUtils.debugLog('Error refreshing diagnostics: $e');
    }
  }

  void _updateBatteryStatus() {
    final level = batteryInfo.value.level;
    final state = batteryInfo.value.state;
    String stateText = getBatteryStateDisplay(state);

    if (level > 20) {
      listStatus[3] = '$level% $stateText';
    } else if (level > 10) {
      listStatus[3] =
          CommonConstants.troubleshootBatteryLow.trParams({'level': '$level'});
    } else {
      listStatus[3] = CommonConstants.troubleshootBatteryCritical
          .trParams({'level': '$level'});
    }
  }

  void _updateNetworkStatus() {
    final info = networkInfo.value;
    if (info.connectionType == diag.ConnectionType.none) {
      listStatus[1] = CommonConstants.notConnect.tr;
      networkStatus.value = CommonConstants.troubleshootDisconnected.tr;
    } else {
      String status = getConnectionTypeDisplay(info.connectionType);
      if (info.ssid != null && info.ssid!.isNotEmpty) {
        status += ' (${info.ssid})';
      }
      listStatus[1] = status;
      networkStatus.value = CommonConstants.connected.tr;
    }
  }

  void _updatePrinterStatus() {
    final info = printerInfo.value;
    isConnectedPrinter.value = info.status == diag.PrinterStatus.connected;
    if (info.status == diag.PrinterStatus.connected) {
      listStatus[0] = CommonConstants.connected.tr;
    } else {
      listStatus[0] = CommonConstants.notConnect.tr;
    }
  }

  void _updateBluetoothStatus() {
    final info = bluetoothInfo.value;
    if (info.state == diag.BluetoothState.on) {
      listStatus[4] =
          '${CommonConstants.connected.tr} (${info.pairedDeviceCount} devices)';
    } else {
      listStatus[4] = CommonConstants.notConnect.tr;
    }
  }

  void _updateAudioStatus() {
    final info = audioInfo.value;
    if (info.isMuted) {
      listStatus[5] = CommonConstants.troubleshootMuted.tr;
    } else {
      listStatus[5] = CommonConstants.troubleshootVolume
          .trParams({'level': '${info.volumeLevel}'});
    }
  }

  void _updateScannerStatus() {
    final info = scannerInfo.value;
    if (info.hasCameraPermission && info.qrScannerAvailable) {
      listStatus[6] = CommonConstants.good.tr;
      listStatus[7] = CommonConstants.good.tr;
    } else {
      listStatus[6] = CommonConstants.troubleshootPermissionNeeded.tr;
      listStatus[7] = CommonConstants.troubleshootPermissionNeeded.tr;
    }
  }

  void initListeners() async {
    // Check printer connection
    isConnectedPrinter.value = await Printer.isConnectedPrinter() ?? false;
    if (isConnectedPrinter.value == true) {
      listStatus[0] = CommonConstants.connected.tr;
    }

    // Monitor Bluetooth state
    adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        listStatus[4] = CommonConstants.connected.tr;
      } else {
        listStatus[4] = CommonConstants.notConnect.tr;
      }
      bluetoothState.value = state;
    });
  }

  // Test functions
  void testPrinter() async {
    try {
      printerInfo.value = await _diagnosticService.getPrinterInfo();
      _updatePrinterStatus();

      final status = printerInfo.value.status;

      // Morefun only: push a physical self-test print when the printer is
      // connected. Gated on isMorefunDevice so no other device flow is affected.
      if (appController.isMorefunDevice.value &&
          status == diag.PrinterStatus.connected) {
        await Printer.printMorefunTestReceipt();
      }

      CommonWidget.toast(
        error: CommonConstants.troubleshootPrinterStatus
            .trParams({'status': getPrinterStatusDisplay(status)}),
        isDarkMode: appController.isDarkModeOn.value,
      );
    } catch (e) {
      LogUtils.debugLog('Error testing printer: $e');
      listStatus[0] = CommonConstants.notConnect.tr;
    }
  }

  void testNetwork() async {
    try {
      networkInfo.value = await _diagnosticService.getNetworkInfo();
      _updateNetworkStatus();

      final type = networkInfo.value.connectionType;
      if (type != diag.ConnectionType.none) {
        CommonWidget.toast(
          error: CommonConstants.troubleshootNetworkStatus
              .trParams({'status': getConnectionTypeDisplay(type)}),
          isDarkMode: appController.isDarkModeOn.value,
        );
      } else {
        CommonWidget.toast(
          error: CommonConstants.troubleshootNetworkDisconnected.tr,
          isDarkMode: appController.isDarkModeOn.value,
        );
      }
    } catch (e) {
      LogUtils.debugLog('Error testing network: $e');
      listStatus[1] = CommonConstants.notConnect.tr;
    }
  }

  void testTouch() {
    listStatus[2] = CommonConstants.good.tr;
    CommonWidget.toast(
      error: CommonConstants.troubleshootTouchGood
          .trParams({'status': CommonConstants.good.tr}),
      isDarkMode: appController.isDarkModeOn.value,
    );
  }

  void testBattery() async {
    try {
      batteryInfo.value = await _diagnosticService.getBatteryInfo();
      getBatteryLevel.value = '${batteryInfo.value.level}%';
      _updateBatteryStatus();

      final level = batteryInfo.value.level;
      final state = getBatteryStateDisplay(batteryInfo.value.state);

      CommonWidget.toast(
        error: CommonConstants.troubleshootBatteryStatus
            .trParams({'level': '$level', 'state': state}),
        isDarkMode: appController.isDarkModeOn.value,
      );
    } catch (e) {
      LogUtils.debugLog('Error testing battery: $e');
      listStatus[3] = CommonConstants.notConnect.tr;
    }
  }

  void testBluetooth() async {
    try {
      bluetoothInfo.value = await _diagnosticService.getBluetoothInfo();
      _updateBluetoothStatus();

      final state = bluetoothInfo.value.state;
      if (state == diag.BluetoothState.on) {
        CommonWidget.toast(
          error: CommonConstants.troubleshootBluetoothConnected
              .trParams({'status': CommonConstants.connected.tr}),
          isDarkMode: appController.isDarkModeOn.value,
        );
      } else {
        CommonWidget.toast(
          error: CommonConstants.troubleshootBluetoothStatus
              .trParams({'status': getBluetoothStateDisplay(state)}),
          isDarkMode: appController.isDarkModeOn.value,
        );
      }
      bluetoothState.value = state == diag.BluetoothState.on
          ? BluetoothAdapterState.on
          : BluetoothAdapterState.off;
    } catch (e) {
      LogUtils.debugLog('Error testing bluetooth: $e');
      listStatus[4] = CommonConstants.notConnect.tr;
    }
  }

  void testSound() async {
    try {
      audioInfo.value = await _diagnosticService.getAudioInfo();
      _updateAudioStatus();

      // Play test sound
      final played = await _diagnosticService.playTestSound();

      if (played) {
        CommonWidget.toast(
          error: CommonConstants.troubleshootSoundPlaying
              .trParams({'level': '${audioInfo.value.volumeLevel}'}),
          isDarkMode: appController.isDarkModeOn.value,
        );
      } else {
        CommonWidget.toast(
          error: CommonConstants.troubleshootSoundFailed.tr,
          isDarkMode: appController.isDarkModeOn.value,
        );
      }
    } catch (e) {
      LogUtils.debugLog('Error testing sound: $e');
      listStatus[5] = CommonConstants.notConnect.tr;
    }
  }

  void testQRScanner() async {
    try {
      scannerInfo.value = await _diagnosticService.getScannerInfo();
      _updateScannerStatus();

      if (scannerInfo.value.hasCameraPermission) {
        listStatus[6] = CommonConstants.good.tr;
        CommonWidget.toast(
          error: CommonConstants.troubleshootQrGood
              .trParams({'status': CommonConstants.good.tr}),
          isDarkMode: appController.isDarkModeOn.value,
        );
      } else {
        listStatus[6] = CommonConstants.troubleshootPermissionNeeded.tr;
        CommonWidget.toast(
          error: CommonConstants.troubleshootQrPermission.tr,
          isDarkMode: appController.isDarkModeOn.value,
        );
      }
    } catch (e) {
      LogUtils.debugLog('Error testing QR scanner: $e');
      listStatus[6] = CommonConstants.notConnect.tr;
    }
  }

  void testBarcodeScanner() async {
    try {
      scannerInfo.value = await _diagnosticService.getScannerInfo();
      _updateScannerStatus();

      if (scannerInfo.value.barcodeScannerAvailable) {
        listStatus[7] = CommonConstants.good.tr;
        CommonWidget.toast(
          error: CommonConstants.troubleshootBarcodeGood
              .trParams({'status': CommonConstants.good.tr}),
          isDarkMode: appController.isDarkModeOn.value,
        );
      } else {
        CommonWidget.toast(
          error: CommonConstants.troubleshootBarcodeNotAvailable.tr,
          isDarkMode: appController.isDarkModeOn.value,
        );
      }
    } catch (e) {
      LogUtils.debugLog('Error testing barcode scanner: $e');
      listStatus[7] = CommonConstants.notConnect.tr;
    }
  }

  /// Test Bluetooth cloud printer connectivity.
  ///
  /// Checks if a Bluetooth printer is saved and its current connection status.
  /// Updates the cloud print grid item status accordingly.
  /// When connected, navigates to the Cloud Print Test page for test printing.
  void testCloudPrint() async {
    try {
      final btService = BluetoothPrinterService.instance;
      final savedPrinter = await btService.getSavedPrinter();
      final status = btService.status.value;

      if (status == BluetoothPrinterStatus.connected && savedPrinter != null) {
        listStatus[8] =
            '${CommonConstants.connected.tr} (${savedPrinter.name})';
        // Navigate to test print page when connected
        Get.toNamed(Routes.CLOUD_PRINT_TEST);
      } else if (savedPrinter != null) {
        listStatus[8] = 'troubleshootCloudPrintSaved'.tr;
        // Printer saved but not connected — navigate to Bluetooth Printer page to reconnect
        Get.toNamed(Routes.BLUETOOTH_PRINTER);
      } else {
        listStatus[8] = CommonConstants.notConnect.tr;
        // Navigate to Bluetooth Printer page so user can pair a printer
        Get.toNamed(Routes.BLUETOOTH_PRINTER);
      }
    } catch (e) {
      LogUtils.debugLog('Error testing cloud print: $e');
      listStatus[8] = CommonConstants.notConnect.tr;
    }
  }

  // Run full diagnostic test with terminal UI
  void runFullTest() async {
    isRunFullTest.value = true;
    isRunningTest.value = true;
    showTerminal.value = true;
    currentTestIndex.value = 0;

    // Clear previous terminal output
    terminalLines.clear();

    // Add initial terminal lines
    _addTerminalLine(TerminalLine.header(CommonConstants.terminalHeader.tr));
    _addTerminalLine(TerminalLine.info(CommonConstants.terminalStarting.tr));
    _addTerminalLine(TerminalLine.info(CommonConstants.terminalDevice
        .trParams({'device': getDeviceModelNumber.value})));
    _addTerminalLine(TerminalLine.info(
        CommonConstants.terminalOs.trParams({'os': getOSInformation.value})));
    _addTerminalLine(TerminalLine.divider());

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      // Test 1: Storage
      await _runStorageTest();

      // Test 2: Memory
      await _runMemoryTest();

      // Test 3: Battery
      await _runBatteryTest();

      // Test 4: Network
      await _runNetworkTest();

      // Test 5: Printer
      await _runPrinterTest();

      // Test 6: Bluetooth
      await _runBluetoothTest();

      // Test 7: Scanner
      await _runScannerTest();

      // Test 8: Audio
      await _runAudioTest();

      // Test 9: Cloud Print (Bluetooth Printer) — mobile users only
      if (appController.isMobileUser.value) {
        await _runCloudPrintTest();
      }

      // Run full diagnostics to get the report
      lastReport.value = await _diagnosticService.runFullDiagnostics();

      // Summary
      _addTerminalLine(TerminalLine.divider());
      final results = lastReport.value!.testResults;
      final passedCount = results.values.where((r) => r.passed).length;
      final totalCount = results.length;

      _addTerminalLine(
          TerminalLine.header(CommonConstants.terminalDiagnosticSummary.tr));
      _addTerminalLine(TerminalLine.info(CommonConstants.terminalTestsCompleted
          .trParams({'count': '$totalCount'})));

      if (passedCount == totalCount) {
        _addTerminalLine(TerminalLine.success(CommonConstants.terminalAllPassed
            .trParams({'passed': '$passedCount', 'total': '$totalCount'})));
      } else {
        _addTerminalLine(TerminalLine.warning(CommonConstants.terminalSomeFailed
            .trParams({'passed': '$passedCount', 'total': '$totalCount'})));
        final failedTests = results.entries.where((e) => !e.value.passed);
        for (var test in failedTests) {
          _addTerminalLine(TerminalLine.error(CommonConstants.terminalFailedItem
              .trParams({
            'name': test.value.testName,
            'error': test.value.errorMessage ?? ''
          })));
        }
      }

      _addTerminalLine(TerminalLine.divider());
      _addTerminalLine(TerminalLine.info(CommonConstants.terminalCompletedAt
          .trParams({'time': DateTime.now().toString().substring(0, 19)})));
    } catch (e) {
      LogUtils.debugLog('Error running full test: $e');
      _addTerminalLine(TerminalLine.error('Error: $e'));
    } finally {
      isRunningTest.value = false;
      currentTestName.value = '';
    }
  }

  // Individual test methods for terminal output
  Future<void> _runStorageTest() async {
    currentTestIndex.value++;
    currentTestName.value = 'check_storage';
    _addTerminalLine(TerminalLine.command('check_storage'));
    _addTerminalLine(
        TerminalLine.progress(CommonConstants.terminalCheckingStorage.tr));
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final info = await _diagnosticService.getStorageInfo();
      storageInfo.value = info;
      final passed = info.status != diag.DiagnosticStatus.error;
      final msg = CommonConstants.terminalStorageResult.trParams({
        'used': formatBytes(info.usedBytes),
        'total': formatBytes(info.totalBytes),
        'percent': info.usagePercentage.toStringAsFixed(1),
      });
      _addTerminalLine(
          passed ? TerminalLine.success(msg) : TerminalLine.warning(msg));
    } catch (e) {
      _addTerminalLine(TerminalLine.error(CommonConstants.terminalCheckFailed
          .trParams({'name': 'Storage', 'error': '$e'})));
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _runMemoryTest() async {
    currentTestIndex.value++;
    currentTestName.value = 'check_memory';
    _addTerminalLine(TerminalLine.command('check_memory'));
    _addTerminalLine(
        TerminalLine.progress(CommonConstants.terminalCheckingMemory.tr));
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final info = await _diagnosticService.getMemoryInfo();
      memoryInfo.value = info;
      final passed = info.status != diag.DiagnosticStatus.error;
      final msg = CommonConstants.terminalMemoryResult.trParams({
        'used': formatBytes(info.usedBytes),
        'total': formatBytes(info.totalBytes),
        'percent': info.usagePercentage.toStringAsFixed(1),
      });
      _addTerminalLine(
          passed ? TerminalLine.success(msg) : TerminalLine.warning(msg));
    } catch (e) {
      _addTerminalLine(TerminalLine.error(CommonConstants.terminalCheckFailed
          .trParams({'name': 'Memory', 'error': '$e'})));
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _runBatteryTest() async {
    currentTestIndex.value++;
    currentTestName.value = 'check_battery';
    _addTerminalLine(TerminalLine.command('check_battery'));
    _addTerminalLine(
        TerminalLine.progress(CommonConstants.terminalCheckingBattery.tr));
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final info = await _diagnosticService.getBatteryInfo();
      batteryInfo.value = info;
      getBatteryLevel.value = '${info.level}%';
      _updateBatteryStatus();
      final passed = info.level > 10;
      final msg = CommonConstants.terminalBatteryResult.trParams({
        'level': '${info.level}',
        'state': getBatteryStateDisplay(info.state),
      });
      _addTerminalLine(
          passed ? TerminalLine.success(msg) : TerminalLine.warning(msg));
    } catch (e) {
      _addTerminalLine(TerminalLine.error(CommonConstants.terminalCheckFailed
          .trParams({'name': 'Battery', 'error': '$e'})));
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _runNetworkTest() async {
    currentTestIndex.value++;
    currentTestName.value = 'check_network';
    _addTerminalLine(TerminalLine.command('check_network'));
    _addTerminalLine(
        TerminalLine.progress(CommonConstants.terminalCheckingNetwork.tr));
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final info = await _diagnosticService.getNetworkInfo();
      networkInfo.value = info;
      _updateNetworkStatus();
      final passed = info.connectionType != diag.ConnectionType.none;
      final ssidPart = info.ssid != null ? ' (${info.ssid})' : '';
      final msg = passed
          ? CommonConstants.terminalNetworkConnected.trParams({
              'type': getConnectionTypeDisplay(info.connectionType),
              'ssid': ssidPart
            })
          : CommonConstants.terminalNetworkDisconnected.tr;
      _addTerminalLine(
          passed ? TerminalLine.success(msg) : TerminalLine.warning(msg));
    } catch (e) {
      _addTerminalLine(TerminalLine.error(CommonConstants.terminalCheckFailed
          .trParams({'name': 'Network', 'error': '$e'})));
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _runPrinterTest() async {
    currentTestIndex.value++;
    currentTestName.value = 'check_printer';
    _addTerminalLine(TerminalLine.command('check_printer'));
    _addTerminalLine(
        TerminalLine.progress(CommonConstants.terminalCheckingPrinter.tr));
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final info = await _diagnosticService.getPrinterInfo();
      printerInfo.value = info;
      _updatePrinterStatus();
      final passed = info.status == diag.PrinterStatus.connected;
      final modelPart = info.model != null ? ' (${info.model})' : '';
      final msg = CommonConstants.terminalPrinterResult.trParams(
          {'status': getPrinterStatusDisplay(info.status), 'model': modelPart});
      _addTerminalLine(
          passed ? TerminalLine.success(msg) : TerminalLine.warning(msg));
    } catch (e) {
      _addTerminalLine(TerminalLine.error(CommonConstants.terminalCheckFailed
          .trParams({'name': 'Printer', 'error': '$e'})));
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _runBluetoothTest() async {
    currentTestIndex.value++;
    currentTestName.value = 'check_bluetooth';
    _addTerminalLine(TerminalLine.command('check_bluetooth'));
    _addTerminalLine(
        TerminalLine.progress(CommonConstants.terminalCheckingBluetooth.tr));
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final info = await _diagnosticService.getBluetoothInfo();
      bluetoothInfo.value = info;
      _updateBluetoothStatus();
      final passed = info.state == diag.BluetoothState.on;
      final msg = CommonConstants.terminalBluetoothResult.trParams({
        'state': getBluetoothStateDisplay(info.state),
        'count': '${info.pairedDeviceCount}',
      });
      _addTerminalLine(
          passed ? TerminalLine.success(msg) : TerminalLine.warning(msg));
    } catch (e) {
      _addTerminalLine(TerminalLine.error(CommonConstants.terminalCheckFailed
          .trParams({'name': 'Bluetooth', 'error': '$e'})));
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _runScannerTest() async {
    currentTestIndex.value++;
    currentTestName.value = 'check_scanner';
    _addTerminalLine(TerminalLine.command('check_scanner'));
    _addTerminalLine(
        TerminalLine.progress(CommonConstants.terminalCheckingScanner.tr));
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final info = await _diagnosticService.getScannerInfo();
      scannerInfo.value = info;
      _updateScannerStatus();
      final passed = info.hasCameraPermission;
      final msg = passed
          ? CommonConstants.terminalScannerAccessible.tr
          : CommonConstants.terminalScannerPermission.tr;
      _addTerminalLine(
          passed ? TerminalLine.success(msg) : TerminalLine.warning(msg));
    } catch (e) {
      _addTerminalLine(TerminalLine.error(CommonConstants.terminalCheckFailed
          .trParams({'name': 'Scanner', 'error': '$e'})));
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _runAudioTest() async {
    currentTestIndex.value++;
    currentTestName.value = 'check_audio';
    _addTerminalLine(TerminalLine.command('check_audio'));
    _addTerminalLine(
        TerminalLine.progress(CommonConstants.terminalCheckingAudio.tr));
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final info = await _diagnosticService.getAudioInfo();
      audioInfo.value = info;
      _updateAudioStatus();
      final passed = !info.isMuted && info.volumeLevel > 0;
      final mutedPart =
          info.isMuted ? ' (${CommonConstants.troubleshootMuted.tr})' : '';
      final msg = CommonConstants.terminalAudioResult.trParams({
        'level': '${info.volumeLevel}',
        'muted': mutedPart,
      });
      _addTerminalLine(
          passed ? TerminalLine.success(msg) : TerminalLine.warning(msg));
    } catch (e) {
      _addTerminalLine(TerminalLine.error(CommonConstants.terminalCheckFailed
          .trParams({'name': 'Audio', 'error': '$e'})));
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Terminal test step for Bluetooth cloud printer during full diagnostics.
  Future<void> _runCloudPrintTest() async {
    currentTestIndex.value++;
    currentTestName.value = 'check_cloud_print';
    _addTerminalLine(TerminalLine.command('check_cloud_print'));
    _addTerminalLine(
        TerminalLine.progress('troubleshootTerminalCheckingCloudPrint'.tr));
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final btService = BluetoothPrinterService.instance;
      final savedPrinter = await btService.getSavedPrinter();
      final status = btService.status.value;
      final isConnected = status == BluetoothPrinterStatus.connected;

      if (isConnected && savedPrinter != null) {
        listStatus[8] =
            '${CommonConstants.connected.tr} (${savedPrinter.name})';
        _addTerminalLine(TerminalLine.success(
            'troubleshootTerminalCloudPrintConnected'
                .trParams({'name': savedPrinter.name})));
      } else if (savedPrinter != null) {
        listStatus[8] = 'troubleshootCloudPrintSaved'.tr;
        _addTerminalLine(TerminalLine.warning(
            'troubleshootTerminalCloudPrintSaved'
                .trParams({'name': savedPrinter.name})));
      } else {
        listStatus[8] = CommonConstants.notConnect.tr;
        _addTerminalLine(
            TerminalLine.warning('troubleshootTerminalCloudPrintNone'.tr));
      }
    } catch (e) {
      listStatus[8] = CommonConstants.notConnect.tr;
      _addTerminalLine(TerminalLine.error(CommonConstants.terminalCheckFailed
          .trParams({'name': 'Cloud Print', 'error': '$e'})));
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Add a line to terminal output
  void _addTerminalLine(TerminalLine line) {
    terminalLines.add(line);
  }

  // Close terminal view
  void closeTerminal() {
    showTerminal.value = false;
  }

  // Print test receipt
  void printTestReceipt() async {
    try {
      CommonWidget.toast(
        error: CommonConstants.troubleshootPrintingReceipt.tr,
        isDarkMode: appController.isDarkModeOn.value,
      );

      final success = await _diagnosticService.printTestReceipt();

      if (success) {
        CommonWidget.toast(
          error: CommonConstants.troubleshootPrintSuccess.tr,
          isDarkMode: appController.isDarkModeOn.value,
        );
      } else {
        CommonWidget.toast(
          error: CommonConstants.troubleshootPrintFailed.tr,
          isDarkMode: appController.isDarkModeOn.value,
        );
      }
    } catch (e) {
      LogUtils.debugLog('Error printing test receipt: $e');
      CommonWidget.toast(
        error: "${CommonConstants.error.tr}: $e",
        isDarkMode: appController.isDarkModeOn.value,
      );
    }
  }

  // Measure network latency
  void measureLatency() async {
    try {
      CommonWidget.toast(
        error: CommonConstants.troubleshootMeasuringLatency.tr,
        isDarkMode: appController.isDarkModeOn.value,
      );

      final latency = await _diagnosticService.measureLatency('google.com');

      if (latency > 0) {
        CommonWidget.toast(
          error: CommonConstants.troubleshootLatencyResult
              .trParams({'latency': '$latency'}),
          isDarkMode: appController.isDarkModeOn.value,
        );
      } else {
        CommonWidget.toast(
          error: CommonConstants.troubleshootLatencyFailed.tr,
          isDarkMode: appController.isDarkModeOn.value,
        );
      }
    } catch (e) {
      LogUtils.debugLog('Error measuring latency: $e');
    }
  }

  // Copy device info to clipboard
  void copyDeviceInfo() async {
    try {
      await _diagnosticService.copyDeviceInfo();
      CommonWidget.toast(
        error: CommonConstants.troubleshootDeviceInfoCopied.tr,
        isDarkMode: appController.isDarkModeOn.value,
      );
    } catch (e) {
      LogUtils.debugLog('Error copying device info: $e');
      CommonWidget.toast(
        error: CommonConstants.troubleshootDeviceInfoCopyError.tr,
        isDarkMode: appController.isDarkModeOn.value,
      );
    }
  }

  // Share diagnostic report
  void shareDiagnostics() async {
    try {
      if (lastReport.value != null) {
        final text = lastReport.value!.toShareableText();
        await SharePlus.instance.share(ShareParams(
          text: text,
          subject: CommonConstants.troubleshootDiagnosticReport.tr,
          // Required for iPad - provide a share origin rect
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
        ));
      } else {
        // Run diagnostics first
        CommonWidget.toast(
          error: CommonConstants.troubleshootRunningDiagnostics.tr,
          isDarkMode: appController.isDarkModeOn.value,
        );
        await _diagnosticService.shareDiagnostics();
      }
    } catch (e) {
      LogUtils.debugLog('Error sharing diagnostics: $e');
      CommonWidget.toast(
        error: CommonConstants.troubleshootShareError.tr,
        isDarkMode: appController.isDarkModeOn.value,
      );
    }
  }

  // Refresh storage info
  void refreshStorage() async {
    try {
      storageInfo.value = await _diagnosticService.getStorageInfo();
    } catch (e) {
      LogUtils.debugLog('Error refreshing storage: $e');
    }
  }

  // Refresh memory info
  void refreshMemory() async {
    try {
      memoryInfo.value = await _diagnosticService.getMemoryInfo();
    } catch (e) {
      LogUtils.debugLog('Error refreshing memory: $e');
    }
  }

  void scan() async {
    try {
      CommonWidget.toast(
        error: CommonConstants.troubleshootOpeningScanner.tr,
        isDarkMode: appController.isDarkModeOn.value,
      );
      listStatus[7] = CommonConstants.good.tr;
    } catch (e) {
      LogUtils.debugLog('Error scanning: $e');
      CommonWidget.toast(
        error: "${CommonConstants.error.tr}: $e",
        isDarkMode: appController.isDarkModeOn.value,
      );
    }
  }

  @override
  void onClose() {
    _progressSubscription?.cancel();
    adapterStateStateSubscription.cancel();
    _diagnosticService.dispose();
    super.onClose();
  }
}
