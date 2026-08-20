/// Data models for the Bluetooth printer feature.
/// Used by BluetoothPrinterService for connection management and persistence.

/// Connection status of the Bluetooth printer.
enum BluetoothPrinterStatus {
  connected,
  disconnected,
  connecting,
  scanning,
  error,
}

/// Paired printer information stored in secure local storage.
/// Persisted as JSON for automatic reconnection on app launch.
class PairedPrinterInfo {
  final String name;
  final String macAddress;

  PairedPrinterInfo({
    required this.name,
    required this.macAddress,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'macAddress': macAddress,
      };

  factory PairedPrinterInfo.fromJson(Map<String, dynamic> json) =>
      PairedPrinterInfo(
        name: json['name'] as String,
        macAddress: json['macAddress'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PairedPrinterInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          macAddress == other.macAddress;

  @override
  int get hashCode => name.hashCode ^ macAddress.hashCode;

  @override
  String toString() =>
      'PairedPrinterInfo(name: $name, macAddress: $macAddress)';
}
