// Diagnostic Service - Central coordinator for all device diagnostics
import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Rect;
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;

import 'models/diagnostic_models.dart';
import 'managers/storage_manager.dart';
import 'managers/memory_manager.dart';
import 'managers/battery_manager.dart';
import 'managers/network_manager.dart';
import 'managers/printer_manager.dart';
import 'managers/bluetooth_manager.dart';
import 'managers/scanner_manager.dart';
import 'managers/audio_manager.dart';
import 'package:app/shared/utils/log_utils.dart';

class DiagnosticService {
  final StorageManager _storageManager = StorageManager();
  final MemoryManager _memoryManager = MemoryManager();
  final BatteryManager _batteryManager = BatteryManager();
  final NetworkManager _networkManager = NetworkManager();
  final PrinterDiagnosticManager _printerManager = PrinterDiagnosticManager();
  final BluetoothDiagnosticManager _bluetoothManager =
      BluetoothDiagnosticManager();
  final ScannerManager _scannerManager = ScannerManager();
  final AudioManager _audioManager = AudioManager();

  // Progress tracking for full diagnostics
  final _progressController = StreamController<(int, int, String)>.broadcast();
  Stream<(int, int, String)> get progressStream => _progressController.stream;

  // Getters for managers (for direct access if needed)
  StorageManager get storageManager => _storageManager;
  MemoryManager get memoryManager => _memoryManager;
  BatteryManager get batteryManager => _batteryManager;
  NetworkManager get networkManager => _networkManager;
  PrinterDiagnosticManager get printerManager => _printerManager;
  BluetoothDiagnosticManager get bluetoothManager => _bluetoothManager;
  ScannerManager get scannerManager => _scannerManager;
  AudioManager get audioManager => _audioManager;

  /// Get device information
  Future<DeviceInfo> getDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return DeviceInfo(
          appName: packageInfo.appName,
          model: androidInfo.model,
          brand: androidInfo.brand,
          serialNumber: androidInfo.serialNumber,
          osVersion: 'Android ${androidInfo.version.release}',
          appVersion: packageInfo.version,
          buildNumber: packageInfo.buildNumber,
        );
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return DeviceInfo(
          appName: packageInfo.appName,
          model: iosInfo.model,
          brand: 'Apple',
          serialNumber: iosInfo.identifierForVendor ?? 'Unknown',
          osVersion: 'iOS ${iosInfo.systemVersion}',
          appVersion: packageInfo.version,
          buildNumber: packageInfo.buildNumber,
        );
      }

      return DeviceInfo.empty();
    } catch (e) {
      LogUtils.debugLog('Error getting device info: $e');
      return DeviceInfo.empty();
    }
  }

  /// Get storage info
  Future<StorageInfo> getStorageInfo() => _storageManager.getStorageInfo();

  /// Get memory info
  Future<MemoryInfo> getMemoryInfo() => _memoryManager.getMemoryInfo();

  /// Get battery info
  Future<BatteryInfo> getBatteryInfo() => _batteryManager.getBatteryInfo();

  /// Get network info
  Future<NetworkInfo> getNetworkInfo() => _networkManager.getNetworkInfo();

  /// Get printer info
  Future<PrinterInfo> getPrinterInfo() => _printerManager.getPrinterInfo();

  /// Get Bluetooth info
  Future<BluetoothInfo> getBluetoothInfo() =>
      _bluetoothManager.getBluetoothInfo();

  /// Get scanner info
  Future<ScannerInfo> getScannerInfo() => _scannerManager.getScannerInfo();

  /// Get audio info
  Future<AudioInfo> getAudioInfo() => _audioManager.getAudioInfo();

  /// Run full diagnostics with progress tracking
  Future<DiagnosticReport> runFullDiagnostics() async {
    final testResults = <String, TestResult>{};
    const totalTests = 8;
    var currentTest = 0;

    void updateProgress(String testName) {
      currentTest++;
      _progressController.add((currentTest, totalTests, testName));
    }

    // Test 1: Storage
    updateProgress('Storage');
    final storageStopwatch = Stopwatch()..start();
    final storageInfo = await getStorageInfo();
    storageStopwatch.stop();
    testResults['storage'] = TestResult(
      testName: 'Storage',
      passed: storageInfo.status != DiagnosticStatus.error,
      errorMessage: storageInfo.status == DiagnosticStatus.error
          ? 'Unable to retrieve storage info'
          : null,
      recommendations: storageInfo.status == DiagnosticStatus.critical
          ? ['Clear app cache', 'Delete unused files']
          : [],
      duration: storageStopwatch.elapsed,
    );

    // Test 2: Memory
    updateProgress('Memory');
    final memoryStopwatch = Stopwatch()..start();
    final memoryInfo = await getMemoryInfo();
    memoryStopwatch.stop();
    testResults['memory'] = TestResult(
      testName: 'Memory',
      passed: memoryInfo.status != DiagnosticStatus.error,
      errorMessage: memoryInfo.status == DiagnosticStatus.error
          ? 'Unable to retrieve memory info'
          : null,
      recommendations: memoryInfo.status == DiagnosticStatus.critical
          ? ['Close background apps', 'Restart device']
          : [],
      duration: memoryStopwatch.elapsed,
    );

    // Test 3: Battery
    updateProgress('Battery');
    final batteryStopwatch = Stopwatch()..start();
    final batteryInfo = await getBatteryInfo();
    batteryStopwatch.stop();
    testResults['battery'] = TestResult(
      testName: 'Battery',
      passed: batteryInfo.status != DiagnosticStatus.error &&
          batteryInfo.level > 10,
      errorMessage: batteryInfo.level <= 10 ? 'Battery critically low' : null,
      recommendations: batteryInfo.level <= 20
          ? ['Connect charger', 'Reduce screen brightness']
          : [],
      duration: batteryStopwatch.elapsed,
    );

    // Test 4: Network
    updateProgress('Network');
    final networkStopwatch = Stopwatch()..start();
    final networkInfo = await getNetworkInfo();
    networkStopwatch.stop();
    testResults['network'] = TestResult(
      testName: 'Network',
      passed: networkInfo.connectionType != ConnectionType.none,
      errorMessage: networkInfo.connectionType == ConnectionType.none
          ? 'No network connection'
          : null,
      recommendations: networkInfo.connectionType == ConnectionType.none
          ? ['Check WiFi connection', 'Enable mobile data']
          : [],
      duration: networkStopwatch.elapsed,
    );

    // Test 5: Printer
    updateProgress('Printer');
    final printerStopwatch = Stopwatch()..start();
    final printerInfo = await getPrinterInfo();
    printerStopwatch.stop();
    testResults['printer'] = TestResult(
      testName: 'Printer',
      passed: printerInfo.status == PrinterStatus.connected,
      errorMessage: printerInfo.status != PrinterStatus.connected
          ? 'Printer not connected'
          : null,
      recommendations: printerInfo.status != PrinterStatus.connected
          ? ['Check printer connection', 'Restart printer']
          : [],
      duration: printerStopwatch.elapsed,
    );

    // Test 6: Bluetooth
    updateProgress('Bluetooth');
    final bluetoothStopwatch = Stopwatch()..start();
    final bluetoothInfo = await getBluetoothInfo();
    bluetoothStopwatch.stop();
    testResults['bluetooth'] = TestResult(
      testName: 'Bluetooth',
      passed: bluetoothInfo.state == BluetoothState.on,
      errorMessage:
          bluetoothInfo.state != BluetoothState.on ? 'Bluetooth is off' : null,
      recommendations: bluetoothInfo.state != BluetoothState.on
          ? ['Enable Bluetooth in settings']
          : [],
      duration: bluetoothStopwatch.elapsed,
    );

    // Test 7: Scanner
    updateProgress('Scanner');
    final scannerStopwatch = Stopwatch()..start();
    final scannerInfo = await getScannerInfo();
    scannerStopwatch.stop();
    testResults['scanner'] = TestResult(
      testName: 'Scanner',
      passed: scannerInfo.hasCameraPermission,
      errorMessage: !scannerInfo.hasCameraPermission
          ? 'Camera permission not granted'
          : null,
      recommendations: !scannerInfo.hasCameraPermission
          ? ['Grant camera permission in settings']
          : [],
      duration: scannerStopwatch.elapsed,
    );

    // Test 8: Audio
    updateProgress('Audio');
    final audioStopwatch = Stopwatch()..start();
    final audioInfo = await getAudioInfo();
    audioStopwatch.stop();
    testResults['audio'] = TestResult(
      testName: 'Audio',
      passed: !audioInfo.isMuted && audioInfo.volumeLevel > 0,
      errorMessage: audioInfo.isMuted ? 'Device is muted' : null,
      recommendations: audioInfo.isMuted || audioInfo.volumeLevel < 20
          ? ['Increase volume', 'Unmute device']
          : [],
      duration: audioStopwatch.elapsed,
    );

    // Get device info
    final deviceInfo = await getDeviceInfo();

    return DiagnosticReport(
      timestamp: DateTime.now(),
      deviceInfo: deviceInfo,
      storageInfo: storageInfo,
      memoryInfo: memoryInfo,
      batteryInfo: batteryInfo,
      networkInfo: networkInfo,
      printerInfo: printerInfo,
      bluetoothInfo: bluetoothInfo,
      audioInfo: audioInfo,
      scannerInfo: scannerInfo,
      testResults: testResults,
    );
  }

  /// Copy device info to clipboard
  Future<void> copyDeviceInfo() async {
    final deviceInfo = await getDeviceInfo();
    final text = '''
O7Lite Device Info
====================
Model: ${deviceInfo.model}
Brand: ${deviceInfo.brand}
Serial: ${deviceInfo.serialNumber}
OS: ${deviceInfo.osVersion}
App Version: ${deviceInfo.appVersion} (${deviceInfo.buildNumber})
''';
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Share full diagnostic report
  Future<void> shareDiagnostics() async {
    final report = await runFullDiagnostics();
    final text = report.toShareableText();
    await SharePlus.instance.share(ShareParams(
      text: text,
      subject: 'OxPay Lite Diagnostic Report',
      // Required for iPad - provide a share origin rect
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
    ));
  }

  /// Measure network latency
  Future<int> measureLatency(String serverUrl) {
    return _networkManager.measureLatency(serverUrl);
  }

  /// Print test receipt
  Future<bool> printTestReceipt() {
    return _printerManager.printTestReceipt();
  }

  /// Play test sound
  Future<bool> playTestSound() {
    return _audioManager.playTestSound();
  }

  /// Dispose all resources
  void dispose() {
    _batteryManager.dispose();
    _networkManager.dispose();
    _bluetoothManager.dispose();
    _audioManager.dispose();
    _progressController.close();
  }
}
