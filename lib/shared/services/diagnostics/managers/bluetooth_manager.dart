// Bluetooth Manager - Handles Bluetooth diagnostics
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../models/diagnostic_models.dart';
import 'package:app/shared/utils/log_utils.dart';

class BluetoothDiagnosticManager {
  StreamSubscription<fbp.BluetoothAdapterState>? _adapterStateSubscription;

  /// Get Bluetooth adapter state
  Future<BluetoothState> getAdapterState() async {
    try {
      final state = await fbp.FlutterBluePlus.adapterState.first;
      return _mapAdapterState(state);
    } catch (e) {
      LogUtils.debugLog('Error getting Bluetooth state: $e');
      return BluetoothState.unknown;
    }
  }

  /// Get count of paired/bonded devices
  Future<int> getPairedDeviceCount() async {
    try {
      final state = await getAdapterState();
      if (state != BluetoothState.on) return 0;

      final bondedDevices = await fbp.FlutterBluePlus.bondedDevices;
      return bondedDevices.length;
    } catch (e) {
      LogUtils.debugLog('Error getting paired devices: $e');
      return 0;
    }
  }

  /// Test Bluetooth functionality
  Future<bool> testBluetooth() async {
    try {
      final state = await getAdapterState();
      if (state != BluetoothState.on) {
        return false;
      }

      // Try to get bonded devices as a simple test
      final bondedDevices = await fbp.FlutterBluePlus.bondedDevices;
      return true; // If we get here, Bluetooth is working
    } catch (e) {
      LogUtils.debugLog('Error testing Bluetooth: $e');
      return false;
    }
  }

  /// Stream of Bluetooth state changes
  Stream<BluetoothState> onStateChanged() {
    return fbp.FlutterBluePlus.adapterState.map(_mapAdapterState);
  }

  /// Get complete Bluetooth info
  Future<BluetoothInfo> getBluetoothInfo() async {
    try {
      final state = await getAdapterState();
      final pairedCount = await getPairedDeviceCount();

      DiagnosticStatus status;
      switch (state) {
        case BluetoothState.on:
          status = DiagnosticStatus.good;
          break;
        case BluetoothState.off:
          status = DiagnosticStatus.warning;
          break;
        case BluetoothState.unavailable:
          status = DiagnosticStatus.error;
          break;
        default:
          status = DiagnosticStatus.unknown;
      }

      return BluetoothInfo(
        state: state,
        pairedDeviceCount: pairedCount,
        status: status,
      );
    } catch (e) {
      LogUtils.debugLog('Error getting Bluetooth info: $e');
      return BluetoothInfo(
        state: BluetoothState.unknown,
        pairedDeviceCount: 0,
        status: DiagnosticStatus.error,
      );
    }
  }

  /// Map flutter_blue_plus state to our BluetoothState enum
  BluetoothState _mapAdapterState(fbp.BluetoothAdapterState state) {
    switch (state) {
      case fbp.BluetoothAdapterState.on:
        return BluetoothState.on;
      case fbp.BluetoothAdapterState.off:
        return BluetoothState.off;
      case fbp.BluetoothAdapterState.unavailable:
        return BluetoothState.unavailable;
      default:
        return BluetoothState.unknown;
    }
  }

  /// Dispose resources
  void dispose() {
    _adapterStateSubscription?.cancel();
  }
}
