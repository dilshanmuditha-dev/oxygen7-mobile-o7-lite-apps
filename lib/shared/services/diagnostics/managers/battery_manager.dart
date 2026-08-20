// Battery Manager - Handles device battery diagnostics
import 'dart:async';
import 'package:battery_plus/battery_plus.dart' as bp;
import '../models/diagnostic_models.dart';
import '../utils/formatters.dart';
import 'package:app/shared/utils/log_utils.dart';

class BatteryManager {
  final bp.Battery _battery = bp.Battery();
  StreamSubscription<bp.BatteryState>? _batteryStateSubscription;

  /// Get current battery level (0-100)
  Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      LogUtils.debugLog('Error getting battery level: $e');
      return 0;
    }
  }

  /// Get current battery state
  Future<BatteryState> getBatteryState() async {
    try {
      final state = await _battery.batteryState;
      return _mapBatteryState(state);
    } catch (e) {
      LogUtils.debugLog('Error getting battery state: $e');
      return BatteryState.unknown;
    }
  }

  /// Stream of battery level changes
  Stream<int> onBatteryLevelChanged() {
    // Battery plus doesn't have a direct level stream,
    // so we create one that polls periodically
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await getBatteryLevel();
    }).asyncMap((future) => future);
  }

  /// Stream of battery state changes
  Stream<BatteryState> onBatteryStateChanged() {
    return _battery.onBatteryStateChanged.map(_mapBatteryState);
  }

  /// Get complete battery info
  Future<BatteryInfo> getBatteryInfo() async {
    try {
      final level = await getBatteryLevel();
      final state = await getBatteryState();
      final status = getBatteryStatus(level);
      final isCharging = state == BatteryState.charging;

      return BatteryInfo(
        level: level,
        state: state,
        status: status,
        isCharging: isCharging,
      );
    } catch (e) {
      LogUtils.debugLog('Error getting battery info: $e');
      return BatteryInfo(
        level: 0,
        state: BatteryState.unknown,
        status: DiagnosticStatus.error,
        isCharging: false,
      );
    }
  }

  /// Map battery_plus BatteryState to our BatteryState enum
  BatteryState _mapBatteryState(bp.BatteryState state) {
    switch (state) {
      case bp.BatteryState.charging:
        return BatteryState.charging;
      case bp.BatteryState.discharging:
        return BatteryState.discharging;
      case bp.BatteryState.full:
        return BatteryState.full;
      case bp.BatteryState.connectedNotCharging:
        return BatteryState.notCharging;
      case bp.BatteryState.unknown:
        return BatteryState.unknown;
    }
  }

  /// Dispose resources
  void dispose() {
    _batteryStateSubscription?.cancel();
  }
}
