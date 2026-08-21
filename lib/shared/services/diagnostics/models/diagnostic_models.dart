// Diagnostic Models and Enums for POS Device Diagnostics
// This file contains all data models used by the diagnostic system

/// Status indicator for diagnostic results
enum DiagnosticStatus { good, warning, critical, error, unknown }

/// Network connection type
enum ConnectionType { wifi, mobile, ethernet, none }

/// WiFi signal strength categories
enum SignalStrength { excellent, good, fair, poor, none }

/// Printer connection status
enum PrinterStatus { connected, disconnected, error, busy }

/// Printer paper status
enum PaperStatus { ok, low, empty, unknown }

/// Battery charging state
enum BatteryState { charging, discharging, full, notCharging, unknown }

/// Bluetooth adapter state
enum BluetoothState { on, off, unavailable, unknown }

/// Storage information data class
class StorageInfo {
  final int totalBytes;
  final int freeBytes;
  final int usedBytes;
  final double usagePercentage;
  final DiagnosticStatus status;

  StorageInfo({
    required this.totalBytes,
    required this.freeBytes,
    required this.usedBytes,
    required this.usagePercentage,
    required this.status,
  });

  factory StorageInfo.empty() => StorageInfo(
        totalBytes: 0,
        freeBytes: 0,
        usedBytes: 0,
        usagePercentage: 0,
        status: DiagnosticStatus.unknown,
      );
}

/// Memory (RAM) information data class
class MemoryInfo {
  final int totalBytes;
  final int freeBytes;
  final int usedBytes;
  final double usagePercentage;
  final DiagnosticStatus status;

  MemoryInfo({
    required this.totalBytes,
    required this.freeBytes,
    required this.usedBytes,
    required this.usagePercentage,
    required this.status,
  });

  factory MemoryInfo.empty() => MemoryInfo(
        totalBytes: 0,
        freeBytes: 0,
        usedBytes: 0,
        usagePercentage: 0,
        status: DiagnosticStatus.unknown,
      );
}

/// Battery information data class
class BatteryInfo {
  final int level;
  final BatteryState state;
  final DiagnosticStatus status;
  final bool isCharging;

  BatteryInfo({
    required this.level,
    required this.state,
    required this.status,
    required this.isCharging,
  });

  factory BatteryInfo.empty() => BatteryInfo(
        level: 0,
        state: BatteryState.unknown,
        status: DiagnosticStatus.unknown,
        isCharging: false,
      );
}

/// Network information data class
class NetworkInfo {
  final ConnectionType connectionType;
  final String? ssid;
  final SignalStrength signalStrength;
  final String? networkType; // 4G, 3G, 2G, LTE
  final int? latencyMs;
  final DiagnosticStatus status;

  NetworkInfo({
    required this.connectionType,
    this.ssid,
    required this.signalStrength,
    this.networkType,
    this.latencyMs,
    required this.status,
  });

  factory NetworkInfo.empty() => NetworkInfo(
        connectionType: ConnectionType.none,
        signalStrength: SignalStrength.none,
        status: DiagnosticStatus.unknown,
      );

  factory NetworkInfo.disconnected() => NetworkInfo(
        connectionType: ConnectionType.none,
        signalStrength: SignalStrength.none,
        status: DiagnosticStatus.error,
      );
}

/// Printer information data class
class PrinterInfo {
  final PrinterStatus status;
  final String? model;
  final PaperStatus paperStatus;
  final String? errorMessage;

  PrinterInfo({
    required this.status,
    this.model,
    required this.paperStatus,
    this.errorMessage,
  });

  factory PrinterInfo.empty() => PrinterInfo(
        status: PrinterStatus.disconnected,
        paperStatus: PaperStatus.unknown,
      );
}

/// Bluetooth information data class
class BluetoothInfo {
  final BluetoothState state;
  final int pairedDeviceCount;
  final DiagnosticStatus status;

  BluetoothInfo({
    required this.state,
    required this.pairedDeviceCount,
    required this.status,
  });

  factory BluetoothInfo.empty() => BluetoothInfo(
        state: BluetoothState.unknown,
        pairedDeviceCount: 0,
        status: DiagnosticStatus.unknown,
      );
}

/// Device information data class
class DeviceInfo {
  final String appName;
  final String model;
  final String brand;
  final String serialNumber;
  final String osVersion;
  final String appVersion;
  final String buildNumber;

  DeviceInfo({
    required this.appName,
    required this.model,
    required this.brand,
    required this.serialNumber,
    required this.osVersion,
    required this.appVersion,
    required this.buildNumber,
  });

  factory DeviceInfo.empty() => DeviceInfo(
        appName: 'Unknown',
        model: 'Unknown',
        brand: 'Unknown',
        serialNumber: 'Unknown',
        osVersion: 'Unknown',
        appVersion: 'Unknown',
        buildNumber: 'Unknown',
      );
}

/// Audio/Sound information data class
class AudioInfo {
  final int volumeLevel;
  final bool isMuted;
  final DiagnosticStatus status;

  AudioInfo({
    required this.volumeLevel,
    required this.isMuted,
    required this.status,
  });

  factory AudioInfo.empty() => AudioInfo(
        volumeLevel: 0,
        isMuted: false,
        status: DiagnosticStatus.unknown,
      );
}

/// Scanner information data class
class ScannerInfo {
  final bool hasCameraPermission;
  final bool qrScannerAvailable;
  final bool barcodeScannerAvailable;
  final DiagnosticStatus status;

  ScannerInfo({
    required this.hasCameraPermission,
    required this.qrScannerAvailable,
    required this.barcodeScannerAvailable,
    required this.status,
  });

  factory ScannerInfo.empty() => ScannerInfo(
        hasCameraPermission: false,
        qrScannerAvailable: false,
        barcodeScannerAvailable: false,
        status: DiagnosticStatus.unknown,
      );
}

/// Individual test result
class TestResult {
  final String testName;
  final bool passed;
  final String? errorMessage;
  final List<String> recommendations;
  final Duration duration;

  TestResult({
    required this.testName,
    required this.passed,
    this.errorMessage,
    this.recommendations = const [],
    this.duration = Duration.zero,
  });
}

/// Complete diagnostic report
class DiagnosticReport {
  final DateTime timestamp;
  final DeviceInfo deviceInfo;
  final StorageInfo storageInfo;
  final MemoryInfo memoryInfo;
  final BatteryInfo batteryInfo;
  final NetworkInfo networkInfo;
  final PrinterInfo printerInfo;
  final BluetoothInfo bluetoothInfo;
  final AudioInfo audioInfo;
  final ScannerInfo scannerInfo;
  final Map<String, TestResult> testResults;

  DiagnosticReport({
    required this.timestamp,
    required this.deviceInfo,
    required this.storageInfo,
    required this.memoryInfo,
    required this.batteryInfo,
    required this.networkInfo,
    required this.printerInfo,
    required this.bluetoothInfo,
    required this.audioInfo,
    required this.scannerInfo,
    this.testResults = const {},
  });

  factory DiagnosticReport.empty() => DiagnosticReport(
        timestamp: DateTime.now(),
        deviceInfo: DeviceInfo.empty(),
        storageInfo: StorageInfo.empty(),
        memoryInfo: MemoryInfo.empty(),
        batteryInfo: BatteryInfo.empty(),
        networkInfo: NetworkInfo.empty(),
        printerInfo: PrinterInfo.empty(),
        bluetoothInfo: BluetoothInfo.empty(),
        audioInfo: AudioInfo.empty(),
        scannerInfo: ScannerInfo.empty(),
      );

  /// Generate formatted string for display
  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.writeln('=== Oxygen7 Lite Diagnostic Report ===');
    buffer.writeln('Generated: ${timestamp.toIso8601String()}');
    buffer.writeln('');
    buffer.writeln('--- Device Information ---');
    buffer.writeln('Model: ${deviceInfo.model}');
    buffer.writeln('Brand: ${deviceInfo.brand}');
    buffer.writeln('Serial: ${deviceInfo.serialNumber}');
    buffer.writeln('OS Version: ${deviceInfo.osVersion}');
    buffer.writeln(
        'App Version: ${deviceInfo.appVersion} (${deviceInfo.buildNumber})');
    buffer.writeln('');
    buffer.writeln('--- Storage ---');
    buffer.writeln('Total: ${_formatBytes(storageInfo.totalBytes)}');
    buffer.writeln('Free: ${_formatBytes(storageInfo.freeBytes)}');
    buffer.writeln('Used: ${storageInfo.usagePercentage.toStringAsFixed(1)}%');
    buffer.writeln('Status: ${storageInfo.status.name}');
    buffer.writeln('');
    buffer.writeln('--- Memory ---');
    buffer.writeln('Total: ${_formatBytes(memoryInfo.totalBytes)}');
    buffer.writeln('Free: ${_formatBytes(memoryInfo.freeBytes)}');
    buffer.writeln('Used: ${memoryInfo.usagePercentage.toStringAsFixed(1)}%');
    buffer.writeln('Status: ${memoryInfo.status.name}');
    buffer.writeln('');
    buffer.writeln('--- Battery ---');
    buffer.writeln('Level: ${batteryInfo.level}%');
    buffer.writeln('State: ${batteryInfo.state.name}');
    buffer.writeln('Status: ${batteryInfo.status.name}');
    buffer.writeln('');
    buffer.writeln('--- Network ---');
    buffer.writeln('Type: ${networkInfo.connectionType.name}');
    if (networkInfo.ssid != null) buffer.writeln('SSID: ${networkInfo.ssid}');
    buffer.writeln('Signal: ${networkInfo.signalStrength.name}');
    if (networkInfo.latencyMs != null)
      buffer.writeln('Latency: ${networkInfo.latencyMs}ms');
    buffer.writeln('Status: ${networkInfo.status.name}');
    buffer.writeln('');
    buffer.writeln('--- Printer ---');
    buffer.writeln('Status: ${printerInfo.status.name}');
    if (printerInfo.model != null)
      buffer.writeln('Model: ${printerInfo.model}');
    buffer.writeln('Paper: ${printerInfo.paperStatus.name}');
    buffer.writeln('');
    buffer.writeln('--- Bluetooth ---');
    buffer.writeln('State: ${bluetoothInfo.state.name}');
    buffer.writeln('Paired Devices: ${bluetoothInfo.pairedDeviceCount}');
    buffer.writeln('');
    buffer.writeln('--- Audio ---');
    buffer.writeln('Volume: ${audioInfo.volumeLevel}%');
    buffer.writeln('Muted: ${audioInfo.isMuted}');
    buffer.writeln('');

    if (testResults.isNotEmpty) {
      buffer.writeln('--- Test Results ---');
      for (final entry in testResults.entries) {
        final result = entry.value;
        buffer
            .writeln('${result.testName}: ${result.passed ? "PASS" : "FAIL"}');
        if (!result.passed && result.errorMessage != null) {
          buffer.writeln('  Error: ${result.errorMessage}');
        }
      }
    }

    return buffer.toString();
  }

  /// Generate shareable text for support
  String toShareableText() {
    return toFormattedString();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }
}
