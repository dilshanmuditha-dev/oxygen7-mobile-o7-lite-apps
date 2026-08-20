import 'package:flutter/services.dart';
import 'package:get/get.dart';

enum CastleReportPrintMonitorLevel { info, success, warning, error }

class CastleReportPrintMonitorEntry {
  CastleReportPrintMonitorEntry({
    required this.stage,
    required this.message,
    required this.level,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String stage;
  final String message;
  final CastleReportPrintMonitorLevel level;
  final DateTime timestamp;
}

class CastleReportPrintMonitor {
  CastleReportPrintMonitor() {
    _channel.setMethodCallHandler(_handleNativeMethodCall);
  }

  static const MethodChannel _channel =
      MethodChannel('CASTLE_REPORT_PRINT_MONITOR');

  static final CastleReportPrintMonitor instance = CastleReportPrintMonitor();

  /// Temporary diagnostic flag. Disable this after the Castle report print
  /// issue is fixed to hide the monitoring popup without changing print flow.
  bool isEnabled = false;

  final RxList<CastleReportPrintMonitorEntry> entries =
      <CastleReportPrintMonitorEntry>[].obs;
  final RxBool isRunning = false.obs;

  void startAttempt(String message) {
    if (!isEnabled) return;
    entries.clear();
    isRunning.value = true;
    addStep('Start', message);
  }

  void addStep(String stage, String message) {
    _addEntry(stage, message, CastleReportPrintMonitorLevel.info);
  }

  void addSuccess(String stage, String message) {
    _addEntry(stage, message, CastleReportPrintMonitorLevel.success);
  }

  void addWarning(String stage, String message) {
    _addEntry(stage, message, CastleReportPrintMonitorLevel.warning);
  }

  void addError(String stage, String message) {
    _addEntry(stage, message, CastleReportPrintMonitorLevel.error);
  }

  void finish({required bool success, String? message}) {
    if (!isEnabled) return;
    isRunning.value = false;
    if (message == null || message.isEmpty) return;
    if (success) {
      addSuccess('Done', message);
    } else {
      addError('Stopped', message);
    }
  }

  void clear() {
    entries.clear();
    isRunning.value = false;
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    if (call.method != 'onCastleReportPrintMonitorEvent') {
      return null;
    }

    final args = Map<String, dynamic>.from(call.arguments as Map);
    final stage = args['stage']?.toString() ?? 'Native';
    final message = args['message']?.toString() ?? '';
    final level = _levelFromNative(args['level']?.toString());
    final done = args['done'] == true;

    _addEntry(stage, message, level);
    if (done) {
      isRunning.value = false;
    }
  }

  CastleReportPrintMonitorLevel _levelFromNative(String? level) {
    switch (level) {
      case 'success':
        return CastleReportPrintMonitorLevel.success;
      case 'warning':
        return CastleReportPrintMonitorLevel.warning;
      case 'error':
        return CastleReportPrintMonitorLevel.error;
      case 'info':
      default:
        return CastleReportPrintMonitorLevel.info;
    }
  }

  void _addEntry(
    String stage,
    String message,
    CastleReportPrintMonitorLevel level,
  ) {
    if (!isEnabled) return;
    entries.add(CastleReportPrintMonitorEntry(
      stage: stage,
      message: message,
      level: level,
    ));
  }
}
