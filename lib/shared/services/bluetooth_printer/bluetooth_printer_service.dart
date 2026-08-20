import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

import '../../secure_shared_preferences/secure_shared_preferences.dart';
import '../../utils/log_utils.dart';
import 'models.dart';

/// Service responsible for managing Bluetooth printer connectivity and persistence.
///
/// Handles scanning, connecting, disconnecting, and sending data to
/// external Bluetooth thermal printers for mobile users.
/// Printer pairing data is persisted via [SecureSharedPreferences] for
/// automatic reconnection on app launch.
class BluetoothPrinterService {
  BluetoothPrinterService._();

  /// Singleton instance.
  static final BluetoothPrinterService instance = BluetoothPrinterService._();

  /// Current connection status (reactive for UI binding via GetX).
  final Rx<BluetoothPrinterStatus> status =
      BluetoothPrinterStatus.disconnected.obs;

  /// Currently connected Bluetooth device (null when disconnected).
  BluetoothDevice? connectedDevice;

  /// Subscription to the scan results stream.
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  /// Subscription to the connected device's connection state stream.
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  /// Start scanning for nearby Bluetooth printers.
  ///
  /// Uses [FlutterBluePlus.startScan] with a configurable [timeout]
  /// (defaults to 10 seconds). Filters discovered devices to only include
  /// those advertising the Serial Port Profile (SPP) service UUID.
  /// Updates [status] to [BluetoothPrinterStatus.scanning] while active.
  ///
  /// Returns a broadcast stream of discovered [ScanResult] lists.
  Stream<List<ScanResult>> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) {
    final controller = StreamController<List<ScanResult>>.broadcast();

    () async {
      try {
        status.value = BluetoothPrinterStatus.scanning;
        LogUtils.debugLog('BluetoothPrinterService: Starting scan...');

        await FlutterBluePlus.startScan(
          timeout: timeout,
          androidUsesFineLocation: true,
        );

        _scanSubscription = FlutterBluePlus.scanResults.listen(
          (results) {
            final filtered = results.where(_isSppCapable).toList();
            controller.add(filtered);
          },
          onError: (dynamic error) {
            LogUtils.debugLog(
              'BluetoothPrinterService: Scan stream error - $error',
            );
            controller.addError(error as Object);
          },
        );

        // When FlutterBluePlus finishes scanning (timeout reached),
        // update status and close the stream.
        FlutterBluePlus.isScanning
            .where((scanning) => !scanning)
            .first
            .then((_) {
          _onScanFinished();
          controller.close();
        });
      } catch (e) {
        LogUtils.debugLog('BluetoothPrinterService: Error starting scan - $e');
        status.value = BluetoothPrinterStatus.disconnected;
        controller.addError(e);
        controller.close();
      }
    }();

    return controller.stream;
  }

  /// Stop an ongoing Bluetooth scan.
  ///
  /// Cancels the scan results subscription and resets [status] to
  /// [BluetoothPrinterStatus.disconnected].
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _onScanFinished();
      LogUtils.debugLog('BluetoothPrinterService: Scan stopped manually');
    } catch (e) {
      LogUtils.debugLog('BluetoothPrinterService: Error stopping scan - $e');
    }
  }

  /// Clean up after a scan completes or is stopped.
  void _onScanFinished() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    if (status.value == BluetoothPrinterStatus.scanning) {
      status.value = BluetoothPrinterStatus.disconnected;
    }
  }

  /// Connect to a specific Bluetooth device.
  ///
  /// Sets [status] to [BluetoothPrinterStatus.connecting] during the attempt.
  /// On success, stores the device as [connectedDevice], updates [status] to
  /// [BluetoothPrinterStatus.connected], persists the printer info via
  /// [savePrinter], and subscribes to the device's connection state stream
  /// to detect unexpected disconnects.
  ///
  /// Returns `true` if the connection was established successfully.
  Future<bool> connect(BluetoothDevice device) async {
    try {
      status.value = BluetoothPrinterStatus.connecting;
      LogUtils.debugLog(
        'BluetoothPrinterService: Connecting to ${device.platformName} (${device.remoteId})...',
      );

      await device.connect(autoConnect: false);

      connectedDevice = device;
      status.value = BluetoothPrinterStatus.connected;

      await savePrinter(device.platformName, device.remoteId.str);

      _listenToConnectionState(device);

      LogUtils.debugLog(
        'BluetoothPrinterService: Connected to ${device.platformName}',
      );
      return true;
    } catch (e) {
      LogUtils.debugLog(
        'BluetoothPrinterService: Connection failed - $e',
      );
      connectedDevice = null;
      status.value = BluetoothPrinterStatus.disconnected;
      return false;
    }
  }

  /// Disconnect from the currently connected printer.
  ///
  /// Cancels the connection state subscription, disconnects the device,
  /// clears [connectedDevice], updates [status] to
  /// [BluetoothPrinterStatus.disconnected], and removes the saved printer
  /// data via [forgetPrinter].
  Future<void> disconnect() async {
    try {
      LogUtils.debugLog('BluetoothPrinterService: Disconnecting...');

      await _connectionSubscription?.cancel();
      _connectionSubscription = null;

      final device = connectedDevice;
      connectedDevice = null;
      status.value = BluetoothPrinterStatus.disconnected;

      if (device != null) {
        await device.disconnect();
      }

      await forgetPrinter();

      LogUtils.debugLog('BluetoothPrinterService: Disconnected');
    } catch (e) {
      LogUtils.debugLog(
        'BluetoothPrinterService: Error during disconnect - $e',
      );
      connectedDevice = null;
      status.value = BluetoothPrinterStatus.disconnected;
    }
  }

  /// Send raw ESC/POS byte data to the connected Bluetooth printer.
  ///
  /// Discovers services on [connectedDevice], locates a writable
  /// [BluetoothCharacteristic], and writes [data] in chunks of
  /// [_chunkSize] bytes to avoid BLE buffer overflow.
  ///
  /// Returns `true` if all data was sent successfully, `false` if
  /// no device is connected, no writable characteristic is found,
  /// or a write error occurs.
  Future<bool> sendData(List<int> data) async {
    if (connectedDevice == null ||
        status.value != BluetoothPrinterStatus.connected) {
      LogUtils.debugLog(
        'BluetoothPrinterService: Cannot send data - no printer connected',
      );
      return false;
    }

    try {
      LogUtils.debugLog(
        'BluetoothPrinterService: Sending ${data.length} bytes...',
      );

      final characteristic = await _findWritableCharacteristic();
      if (characteristic == null) {
        LogUtils.debugLog(
          'BluetoothPrinterService: No writable characteristic found',
        );
        return false;
      }

      // Write data in chunks to avoid BLE buffer overflow.
      for (var offset = 0; offset < data.length; offset += _chunkSize) {
        final end = (offset + _chunkSize > data.length)
            ? data.length
            : offset + _chunkSize;
        final chunk = data.sublist(offset, end);

        await characteristic.write(chunk, withoutResponse: false);
      }

      LogUtils.debugLog(
        'BluetoothPrinterService: Data sent successfully (${data.length} bytes)',
      );
      return true;
    } catch (e) {
      LogUtils.debugLog(
        'BluetoothPrinterService: Error sending data - $e',
      );
      return false;
    }
  }

  /// Maximum bytes per BLE write operation to avoid buffer overflow.
  static const int _chunkSize = 512;

  /// Discover services on the connected device and find a writable characteristic.
  ///
  /// Iterates through all discovered [BluetoothService]s and their
  /// [BluetoothCharacteristic]s, returning the first characteristic that
  /// supports write or writeWithoutResponse.
  Future<BluetoothCharacteristic?> _findWritableCharacteristic() async {
    final device = connectedDevice;
    if (device == null) return null;

    final services = await device.discoverServices();

    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse) {
          LogUtils.debugLog(
            'BluetoothPrinterService: Found writable characteristic '
            '${characteristic.uuid} on service ${service.uuid}',
          );
          return characteristic;
        }
      }
    }

    return null;
  }

  /// Subscribe to the connection state stream of [device] to detect
  /// unexpected disconnects.
  ///
  /// When the device reports a [BluetoothConnectionState.disconnected] state,
  /// the service cleans up the connection and calls [forgetPrinter].
  void _listenToConnectionState(BluetoothDevice device) {
    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen(
      (state) {
        if (state == BluetoothConnectionState.disconnected) {
          LogUtils.debugLog(
            'BluetoothPrinterService: Unexpected disconnect detected',
          );
          connectedDevice = null;
          status.value = BluetoothPrinterStatus.disconnected;
          _connectionSubscription?.cancel();
          _connectionSubscription = null;
          forgetPrinter();
        }
      },
      onError: (dynamic error) {
        LogUtils.debugLog(
          'BluetoothPrinterService: Connection state stream error - $error',
        );
      },
    );
  }

  /// Check if a discovered device likely supports the Serial Port Profile (SPP).
  ///
  /// Filters by the standard SPP UUID (0x1101) in advertised services,
  /// or falls back to accepting devices that have a non-empty local name
  /// (common for thermal printers that don't always advertise SPP explicitly).
  bool _isSppCapable(ScanResult result) {
    const sppUuid = '00001101-0000-1000-8000-00805f9b34fb';
    final advertisedServices = result.advertisementData.serviceUuids;

    if (advertisedServices.any(
      (uuid) => uuid.toString().toLowerCase() == sppUuid,
    )) {
      return true;
    }

    // Many thermal printers don't advertise SPP in BLE advertisements.
    // Accept devices with a non-empty name as potential printer candidates.
    return result.device.platformName.isNotEmpty;
  }

  /// Persist the paired printer name and MAC address to secure storage.
  ///
  /// Called after a successful Bluetooth connection is established.
  /// Validates that both [name] and [macAddress] are non-empty before saving.
  Future<void> savePrinter(String name, String macAddress) async {
    try {
      if (name.isEmpty || macAddress.isEmpty) {
        LogUtils.debugLog(
          'BluetoothPrinterService: Cannot save printer with empty name or MAC address',
        );
        return;
      }
      await SecureSharedPreferences.instance.setBtPrinterName(name);
      await SecureSharedPreferences.instance.setBtPrinterMac(macAddress);
      LogUtils.debugLog(
        'BluetoothPrinterService: Saved printer - $name ($macAddress)',
      );
    } catch (e) {
      LogUtils.debugLog('BluetoothPrinterService: Error saving printer - $e');
    }
  }

  /// Retrieve the saved paired printer info from secure storage.
  ///
  /// Returns a [PairedPrinterInfo] if both name and MAC address are found,
  /// or `null` if no printer has been saved.
  Future<PairedPrinterInfo?> getSavedPrinter() async {
    try {
      final name = await SecureSharedPreferences.instance.getBtPrinterName();
      final mac = await SecureSharedPreferences.instance.getBtPrinterMac();

      if (name != null && name.isNotEmpty && mac != null && mac.isNotEmpty) {
        return PairedPrinterInfo(name: name, macAddress: mac);
      }
      return null;
    } catch (e) {
      LogUtils.debugLog(
        'BluetoothPrinterService: Error reading saved printer - $e',
      );
      return null;
    }
  }

  /// Attempt to automatically reconnect to the saved paired printer.
  ///
  /// Loads the saved printer info from [SecureSharedPreferences]. If a
  /// paired printer exists, creates a [BluetoothDevice] from the stored
  /// MAC address and attempts to connect via [connect].
  ///
  /// On failure, silently marks [status] as [BluetoothPrinterStatus.disconnected]
  /// without showing any error dialogs — the user can manually reconnect later.
  ///
  /// Returns `true` if reconnection succeeded, `false` otherwise.
  Future<bool> autoReconnect() async {
    try {
      final savedPrinter = await getSavedPrinter();
      if (savedPrinter == null) {
        LogUtils.debugLog(
          'BluetoothPrinterService: No saved printer found, skipping auto-reconnect',
        );
        return false;
      }

      LogUtils.debugLog(
        'BluetoothPrinterService: Auto-reconnecting to ${savedPrinter.name} (${savedPrinter.macAddress})...',
      );

      final device = BluetoothDevice.fromId(savedPrinter.macAddress);
      final connected = await connect(device);

      if (!connected) {
        LogUtils.debugLog(
          'BluetoothPrinterService: Auto-reconnect failed, marking as disconnected',
        );
        status.value = BluetoothPrinterStatus.disconnected;
        return false;
      }

      LogUtils.debugLog(
        'BluetoothPrinterService: Auto-reconnect successful',
      );
      return true;
    } catch (e) {
      LogUtils.debugLog(
        'BluetoothPrinterService: Auto-reconnect error - $e',
      );
      status.value = BluetoothPrinterStatus.disconnected;
      return false;
    }
  }

  /// Remove the saved paired printer data from secure storage.
  ///
  /// Called when the user explicitly forgets a printer or disconnects.
  Future<void> forgetPrinter() async {
    try {
      await SecureSharedPreferences.instance.clearBtPrinter();
      LogUtils.debugLog('BluetoothPrinterService: Cleared saved printer');
    } catch (e) {
      LogUtils.debugLog(
        'BluetoothPrinterService: Error clearing saved printer - $e',
      );
    }
  }
}
