// Diagnostic Formatters and Utility Functions
// Contains formatting and calculation utilities for diagnostics

import '../models/diagnostic_models.dart';

/// Format bytes to human-readable string (B, KB, MB, GB, TB)
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';

  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  var i = 0;
  double size = bytes.toDouble();

  while (size >= 1024 && i < suffixes.length - 1) {
    size /= 1024;
    i++;
  }

  // Format with appropriate decimal places
  if (size == size.roundToDouble()) {
    return '${size.toInt()} ${suffixes[i]}';
  }
  return '${size.toStringAsFixed(2)} ${suffixes[i]}';
}

/// Calculate percentage from used and total values
/// Returns value between 0.0 and 100.0
double calculatePercentage(int used, int total) {
  if (total <= 0) return 0.0;
  if (used < 0) return 0.0;
  if (used > total) return 100.0;

  return (used / total) * 100.0;
}

/// Get diagnostic status based on threshold values
/// value: current value (e.g., free storage in bytes)
/// warningThreshold: value below which status is warning
/// criticalThreshold: value below which status is critical
DiagnosticStatus getThresholdStatus(
  int value,
  int warningThreshold,
  int criticalThreshold,
) {
  if (value < criticalThreshold) {
    return DiagnosticStatus.critical;
  } else if (value < warningThreshold) {
    return DiagnosticStatus.warning;
  }
  return DiagnosticStatus.good;
}

/// Get storage status based on free space
/// Warning at 500MB, Critical at 100MB
DiagnosticStatus getStorageStatus(int freeBytes) {
  const warningThreshold = 500 * 1024 * 1024; // 500 MB
  const criticalThreshold = 100 * 1024 * 1024; // 100 MB
  return getThresholdStatus(freeBytes, warningThreshold, criticalThreshold);
}

/// Get memory status based on free RAM
/// Warning at 200MB, Critical at 50MB
DiagnosticStatus getMemoryStatus(int freeBytes) {
  const warningThreshold = 200 * 1024 * 1024; // 200 MB
  const criticalThreshold = 50 * 1024 * 1024; // 50 MB
  return getThresholdStatus(freeBytes, warningThreshold, criticalThreshold);
}

/// Get battery status based on level percentage
DiagnosticStatus getBatteryStatus(int level) {
  if (level < 10) return DiagnosticStatus.critical;
  if (level < 20) return DiagnosticStatus.warning;
  return DiagnosticStatus.good;
}

/// Map WiFi signal strength (dBm) to SignalStrength enum
SignalStrength mapSignalStrength(int? rssi) {
  if (rssi == null) return SignalStrength.none;

  if (rssi >= -50) return SignalStrength.excellent;
  if (rssi >= -60) return SignalStrength.good;
  if (rssi >= -70) return SignalStrength.fair;
  return SignalStrength.poor;
}

/// Get display string for connection type
String getConnectionTypeDisplay(ConnectionType type) {
  switch (type) {
    case ConnectionType.wifi:
      return 'WiFi';
    case ConnectionType.mobile:
      return 'Mobile Data';
    case ConnectionType.ethernet:
      return 'Ethernet';
    case ConnectionType.none:
      return 'No Connection';
  }
}

/// Get display string for battery state
String getBatteryStateDisplay(BatteryState state) {
  switch (state) {
    case BatteryState.charging:
      return 'Charging';
    case BatteryState.discharging:
      return 'Discharging';
    case BatteryState.full:
      return 'Full';
    case BatteryState.notCharging:
      return 'Not Charging';
    case BatteryState.unknown:
      return 'Unknown';
  }
}

/// Get display string for printer status
String getPrinterStatusDisplay(PrinterStatus status) {
  switch (status) {
    case PrinterStatus.connected:
      return 'Connected';
    case PrinterStatus.disconnected:
      return 'Disconnected';
    case PrinterStatus.error:
      return 'Error';
    case PrinterStatus.busy:
      return 'Busy';
  }
}

/// Get display string for Bluetooth state
String getBluetoothStateDisplay(BluetoothState state) {
  switch (state) {
    case BluetoothState.on:
      return 'On';
    case BluetoothState.off:
      return 'Off';
    case BluetoothState.unavailable:
      return 'Unavailable';
    case BluetoothState.unknown:
      return 'Unknown';
  }
}

/// Get display string for signal strength
String getSignalStrengthDisplay(SignalStrength strength) {
  switch (strength) {
    case SignalStrength.excellent:
      return 'Excellent';
    case SignalStrength.good:
      return 'Good';
    case SignalStrength.fair:
      return 'Fair';
    case SignalStrength.poor:
      return 'Poor';
    case SignalStrength.none:
      return 'No Signal';
  }
}

/// Get printer error message and recommendations
(String message, List<String> recommendations) getPrinterErrorInfo(
    String? errorCode) {
  if (errorCode == null) {
    return (
      'Unknown error',
      ['Check printer connection', 'Restart the device']
    );
  }

  switch (errorCode.toLowerCase()) {
    case 'paper_empty':
    case 'no_paper':
      return (
        'Paper Empty',
        ['Load paper into the printer', 'Check paper roll alignment']
      );
    case 'paper_jam':
      return (
        'Paper Jam',
        ['Open printer cover', 'Remove jammed paper', 'Reload paper']
      );
    case 'overheated':
      return (
        'Printer Overheated',
        ['Wait for printer to cool down', 'Reduce print frequency']
      );
    case 'cover_open':
      return ('Cover Open', ['Close the printer cover']);
    case 'not_connected':
      return (
        'Printer Not Connected',
        ['Check USB/Bluetooth connection', 'Restart printer']
      );
    default:
      return (
        'Printer Error: $errorCode',
        ['Restart the printer', 'Contact support if issue persists']
      );
  }
}

/// Get troubleshooting recommendations for a test result
List<String> getRecommendations(TestResult result) {
  if (result.passed) return [];

  final testName = result.testName.toLowerCase();

  if (testName.contains('storage')) {
    return [
      'Clear app cache',
      'Delete unused files',
      'Uninstall unused apps',
    ];
  }

  if (testName.contains('memory') || testName.contains('ram')) {
    return [
      'Close background apps',
      'Restart the device',
      'Clear app cache',
    ];
  }

  if (testName.contains('battery')) {
    return [
      'Connect charger',
      'Reduce screen brightness',
      'Close unused apps',
    ];
  }

  if (testName.contains('network') || testName.contains('wifi')) {
    return [
      'Check WiFi connection',
      'Move closer to router',
      'Restart WiFi router',
      'Try mobile data',
    ];
  }

  if (testName.contains('printer')) {
    return [
      'Check printer connection',
      'Ensure paper is loaded',
      'Restart printer',
    ];
  }

  if (testName.contains('bluetooth')) {
    return [
      'Enable Bluetooth in settings',
      'Restart Bluetooth',
      'Pair device again',
    ];
  }

  if (testName.contains('scanner') || testName.contains('camera')) {
    return [
      'Grant camera permission',
      'Clean camera lens',
      'Restart app',
    ];
  }

  if (testName.contains('sound') || testName.contains('audio')) {
    return [
      'Increase volume',
      'Unmute device',
      'Check speaker',
    ];
  }

  return ['Contact support for assistance'];
}
