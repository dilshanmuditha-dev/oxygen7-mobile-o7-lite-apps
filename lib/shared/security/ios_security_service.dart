import 'dart:io';
import 'package:flutter/services.dart';

/// iOS Security Assessment result from native layer
class IOSSecurityAssessment {
  final String overallStatus;
  final bool isJailbroken;
  final bool isDebugging;
  final bool integrityValid;
  final bool runtimeSafe;
  final DateTime timestamp;
  final String assessmentId;
  final Map<String, dynamic>? jailbreakResult;
  final Map<String, dynamic>? debuggerResult;
  final Map<String, dynamic>? integrityResult;
  final Map<String, dynamic>? runtimeResult;

  IOSSecurityAssessment({
    required this.overallStatus,
    required this.isJailbroken,
    required this.isDebugging,
    required this.integrityValid,
    required this.runtimeSafe,
    required this.timestamp,
    required this.assessmentId,
    this.jailbreakResult,
    this.debuggerResult,
    this.integrityResult,
    this.runtimeResult,
  });

  factory IOSSecurityAssessment.fromMap(Map<String, dynamic> map) {
    return IOSSecurityAssessment(
      overallStatus: map['overallStatus'] as String? ?? 'unknown',
      isJailbroken: map['isJailbroken'] as bool? ?? false,
      isDebugging: map['isDebugging'] as bool? ?? false,
      integrityValid: map['integrityValid'] as bool? ?? true,
      runtimeSafe: map['runtimeSafe'] as bool? ?? true,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        ((map['timestamp'] as num?) ?? 0 * 1000).toInt(),
      ),
      assessmentId: map['assessmentId'] as String? ?? '',
      jailbreakResult: map['jailbreakResult'] as Map<String, dynamic>?,
      debuggerResult: map['debuggerResult'] as Map<String, dynamic>?,
      integrityResult: map['integrityResult'] as Map<String, dynamic>?,
      runtimeResult: map['runtimeResult'] as Map<String, dynamic>?,
    );
  }

  /// Creates a compromised assessment for error cases
  factory IOSSecurityAssessment.compromised({String reason = 'Unknown error'}) {
    return IOSSecurityAssessment(
      overallStatus: 'compromised',
      isJailbroken: false,
      isDebugging: false,
      integrityValid: false,
      runtimeSafe: false,
      timestamp: DateTime.now(),
      assessmentId: 'error-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  bool get isSecure => overallStatus == 'secure';
  bool get isWarning => overallStatus == 'warning';
  bool get isCompromised => overallStatus == 'compromised';

  @override
  String toString() {
    return 'IOSSecurityAssessment(status: $overallStatus, jailbroken: $isJailbroken, '
        'debugging: $isDebugging, integrity: $integrityValid, runtime: $runtimeSafe)';
  }
}

/// iOS Security Event from native layer
class IOSSecurityEvent {
  final String id;
  final String type;
  final String severity;
  final String message;
  final Map<String, String> details;
  final DateTime timestamp;

  IOSSecurityEvent({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.details,
    required this.timestamp,
  });

  factory IOSSecurityEvent.fromMap(Map<String, dynamic> map) {
    return IOSSecurityEvent(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'unknown',
      severity: map['severity'] as String? ?? 'info',
      message: map['message'] as String? ?? '',
      details: Map<String, String>.from(map['details'] ?? {}),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        ((map['timestamp'] as num?) ?? 0 * 1000).toInt(),
      ),
    );
  }

  bool get isCritical => severity == 'critical';
  bool get isHigh => severity == 'high';

  @override
  String toString() {
    return 'IOSSecurityEvent(type: $type, severity: $severity, message: $message)';
  }
}

/// iOS Security Configuration
class IOSSecurityConfiguration {
  final bool jailbreakDetectionEnabled;
  final bool debuggerDetectionEnabled;
  final bool integrityCheckEnabled;
  final bool runtimeProtectionEnabled;
  final double monitoringInterval;
  final bool allowJailbrokenDevices;
  final String? expectedBundleIdentifier;
  final String? expectedTeamIdentifier;

  const IOSSecurityConfiguration({
    this.jailbreakDetectionEnabled = true,
    this.debuggerDetectionEnabled = true,
    this.integrityCheckEnabled = true,
    this.runtimeProtectionEnabled = true,
    this.monitoringInterval = 30.0,
    this.allowJailbrokenDevices = false,
    this.expectedBundleIdentifier,
    this.expectedTeamIdentifier,
  });

  Map<String, dynamic> toMap() {
    return {
      'jailbreakDetectionEnabled': jailbreakDetectionEnabled,
      'debuggerDetectionEnabled': debuggerDetectionEnabled,
      'integrityCheckEnabled': integrityCheckEnabled,
      'runtimeProtectionEnabled': runtimeProtectionEnabled,
      'monitoringInterval': monitoringInterval,
      'allowJailbrokenDevices': allowJailbrokenDevices,
      if (expectedBundleIdentifier != null)
        'expectedBundleIdentifier': expectedBundleIdentifier,
      if (expectedTeamIdentifier != null)
        'expectedTeamIdentifier': expectedTeamIdentifier,
    };
  }
}

/// Service for iOS binary protection and security checks
class IOSSecurityService {
  static const _channel = MethodChannel('CHANNEL_IOS_SECURITY');

  /// Singleton instance
  static final IOSSecurityService _instance = IOSSecurityService._internal();
  factory IOSSecurityService() => _instance;
  IOSSecurityService._internal() {
    _setupEventListener();
  }

  /// Event callbacks
  final List<void Function(IOSSecurityEvent)> _eventCallbacks = [];

  /// Sets up the event listener for native events
  void _setupEventListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSecurityEvent') {
        final event = IOSSecurityEvent.fromMap(
          Map<String, dynamic>.from(call.arguments),
        );
        for (final callback in _eventCallbacks) {
          callback(event);
        }
      } else if (call.method == 'onSecurityStatusChanged') {
        // Handle status change if needed
      }
    });
  }

  /// Checks if running on iOS
  bool get isIOS => Platform.isIOS;

  /// Gets the current security status
  Future<String> getSecurityStatus() async {
    if (!isIOS) return 'secure';

    try {
      final result = await _channel.invokeMethod<String>('getSecurityStatus');
      return result ?? 'unknown';
    } on PlatformException catch (e) {
      // Treat platform errors as compromised
      return 'compromised';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Performs a comprehensive security check
  Future<IOSSecurityAssessment> performSecurityCheck() async {
    if (!isIOS) {
      return IOSSecurityAssessment(
        overallStatus: 'secure',
        isJailbroken: false,
        isDebugging: false,
        integrityValid: true,
        runtimeSafe: true,
        timestamp: DateTime.now(),
        assessmentId: 'non-ios',
      );
    }

    try {
      final result = await _channel.invokeMethod<Map>('performSecurityCheck');
      if (result == null) {
        return IOSSecurityAssessment.compromised(
          reason: 'Null result from security check',
        );
      }
      return IOSSecurityAssessment.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      return IOSSecurityAssessment.compromised(
        reason: 'Platform error: ${e.message}',
      );
    } catch (e) {
      return IOSSecurityAssessment.compromised(
        reason: 'Unexpected error during security check',
      );
    }
  }

  /// Starts runtime security monitoring
  Future<bool> startMonitoring() async {
    if (!isIOS) return true;

    try {
      final result = await _channel.invokeMethod<bool>('startMonitoring');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Stops runtime security monitoring
  Future<bool> stopMonitoring() async {
    if (!isIOS) return true;

    try {
      final result = await _channel.invokeMethod<bool>('stopMonitoring');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Checks if monitoring is active
  Future<bool> isMonitoring() async {
    if (!isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isMonitoring');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Gets recent security events
  Future<List<IOSSecurityEvent>> getSecurityEvents({int limit = 50}) async {
    if (!isIOS) return [];

    try {
      final result = await _channel.invokeMethod<List>(
        'getSecurityEvents',
        {'limit': limit},
      );
      if (result == null) return [];

      return result
          .map((e) => IOSSecurityEvent.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Updates security configuration
  Future<bool> setConfiguration(IOSSecurityConfiguration config) async {
    if (!isIOS) return true;

    try {
      final result = await _channel.invokeMethod<bool>(
        'setConfiguration',
        config.toMap(),
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Registers a callback for security events
  void onSecurityEvent(void Function(IOSSecurityEvent) callback) {
    _eventCallbacks.add(callback);
  }

  /// Removes a security event callback
  void removeSecurityEventCallback(void Function(IOSSecurityEvent) callback) {
    _eventCallbacks.remove(callback);
  }

  /// Clears all security event callbacks
  void clearSecurityEventCallbacks() {
    _eventCallbacks.clear();
  }
}
