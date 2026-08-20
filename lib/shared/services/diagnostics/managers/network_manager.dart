// Network Manager - Handles network connectivity diagnostics
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart' as nip;
import '../models/diagnostic_models.dart';
import 'package:app/shared/utils/log_utils.dart';

class NetworkManager {
  final Connectivity _connectivity = Connectivity();
  final nip.NetworkInfo _networkInfo = nip.NetworkInfo();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Get current connection type
  Future<ConnectionType> getConnectionType() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty) return ConnectionType.none;

      final result = results.first;
      return _mapConnectivityResult(result);
    } catch (e) {
      LogUtils.debugLog('Error getting connection type: $e');
      return ConnectionType.none;
    }
  }

  /// Get WiFi SSID (requires location permission on Android)
  Future<String?> getWifiSSID() async {
    try {
      final connectionType = await getConnectionType();
      if (connectionType != ConnectionType.wifi) return null;

      final ssid = await _networkInfo.getWifiName();
      // Remove quotes if present
      return ssid?.replaceAll('"', '');
    } catch (e) {
      LogUtils.debugLog('Error getting WiFi SSID: $e');
      return null;
    }
  }

  /// Get WiFi signal strength
  Future<SignalStrength> getSignalStrength() async {
    try {
      final connectionType = await getConnectionType();
      if (connectionType != ConnectionType.wifi) return SignalStrength.none;

      // network_info_plus doesn't provide signal strength directly
      // We would need platform channels for accurate RSSI
      // For now, return good if connected
      return SignalStrength.good;
    } catch (e) {
      LogUtils.debugLog('Error getting signal strength: $e');
      return SignalStrength.none;
    }
  }

  /// Get mobile network type (4G, 3G, etc.)
  Future<String?> getMobileNetworkType() async {
    try {
      final connectionType = await getConnectionType();
      if (connectionType != ConnectionType.mobile) return null;

      // This would require platform-specific implementation
      // For now, return a default
      return 'LTE';
    } catch (e) {
      LogUtils.debugLog('Error getting mobile network type: $e');
      return null;
    }
  }

  /// Measure latency to a server (in milliseconds)
  Future<int> measureLatency(String serverUrl) async {
    try {
      final stopwatch = Stopwatch()..start();

      final socket = await Socket.connect(
        serverUrl.replaceAll(RegExp(r'https?://'), ''),
        443,
        timeout: const Duration(seconds: 5),
      );

      stopwatch.stop();
      await socket.close();

      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      LogUtils.debugLog('Error measuring latency: $e');
      return -1; // Indicates failure
    }
  }

  /// Check if internet is actually reachable
  Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Stream of connectivity changes
  Stream<ConnectionType> onConnectionChanged() {
    return _connectivity.onConnectivityChanged.map((results) {
      if (results.isEmpty) return ConnectionType.none;
      return _mapConnectivityResult(results.first);
    });
  }

  /// Get complete network info
  Future<NetworkInfo> getNetworkInfo() async {
    try {
      final connectionType = await getConnectionType();
      final ssid = await getWifiSSID();
      final signalStrength = await getSignalStrength();
      final networkType = await getMobileNetworkType();
      final isConnected = await checkInternetConnection();

      DiagnosticStatus status;
      if (!isConnected) {
        status = DiagnosticStatus.error;
      } else if (signalStrength == SignalStrength.poor) {
        status = DiagnosticStatus.warning;
      } else {
        status = DiagnosticStatus.good;
      }

      return NetworkInfo(
        connectionType: connectionType,
        ssid: ssid,
        signalStrength: signalStrength,
        networkType: networkType,
        status: status,
      );
    } catch (e) {
      LogUtils.debugLog('Error getting network info: $e');
      return NetworkInfo.disconnected();
    }
  }

  /// Map ConnectivityResult to ConnectionType
  ConnectionType _mapConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return ConnectionType.wifi;
      case ConnectivityResult.mobile:
        return ConnectionType.mobile;
      case ConnectivityResult.ethernet:
        return ConnectionType.ethernet;
      case ConnectivityResult.none:
        return ConnectionType.none;
      default:
        return ConnectionType.none;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
