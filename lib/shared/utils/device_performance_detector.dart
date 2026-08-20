// ignore_for_file: avoid_print

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/shared/utils/log_utils.dart';

/// Comprehensive device performance detection for adaptive UI optimization
///
/// This class analyzes device capabilities to provide appropriate UI optimizations
/// for both low-spec POS devices (like Sunmi P2) and high-spec smartphones
class DevicePerformanceDetector {
  static DevicePerformanceDetector? _instance;
  static DevicePerformanceDetector get instance =>
      _instance ??= DevicePerformanceDetector._();

  DevicePerformanceDetector._();

  // Device capability flags
  bool _isInitialized = false;
  bool _isLowSpecDevice = false;
  bool _shouldUseLightweightAnimations = false;
  bool _shouldReduceShimmerEffects = false;
  bool _shouldOptimizeScrolling = false;
  bool _shouldSimplifyUI = false;

  // Device information
  String _deviceModel = '';
  String _deviceManufacturer = '';
  int _androidApiLevel = 0;
  int _estimatedRAM = 0;

  // Performance thresholds
  static const int LOW_SPEC_RAM_THRESHOLD = 2048; // 2GB in MB
  static const int LOW_SPEC_API_THRESHOLD = 28; // Android 9.0
  static const List<String> LOW_SPEC_DEVICES = [
    'sunmi p2',
    'sunmi p1',
    'pax a920',
    'pax a80',
    'ingenico move/5000',
    'castle mp200',
    'landi a8',
    'landi a9',
  ];

  // Getters for device capabilities
  bool get isInitialized => _isInitialized;
  bool get isLowSpecDevice => _isLowSpecDevice;
  bool get shouldUseLightweightAnimations => _shouldUseLightweightAnimations;
  bool get shouldReduceShimmerEffects => _shouldReduceShimmerEffects;
  bool get shouldOptimizeScrolling => _shouldOptimizeScrolling;
  bool get shouldSimplifyUI => _shouldSimplifyUI;

  String get deviceModel => _deviceModel;
  String get deviceManufacturer => _deviceManufacturer;
  int get androidApiLevel => _androidApiLevel;
  int get estimatedRAM => _estimatedRAM;

  /// Initialize device detection - MUST be called during app startup
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        print('🔍 DevicePerformanceDetector: Starting initialization...');
      }

      await _detectDeviceInfo();
      _analyzePerformanceCapabilities();
      _isInitialized = true;

      if (kDebugMode) {
        _logDeviceInfo();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ DevicePerformanceDetector: Initialization failed: $e');
      }
      // Fallback to safe low-spec mode
      _setFallbackLowSpecMode();
      _isInitialized = true;
    }
  }

  /// Detect detailed device information
  Future<void> _detectDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      _deviceModel = androidInfo.model.toLowerCase();
      _deviceManufacturer = androidInfo.manufacturer.toLowerCase();
      _androidApiLevel = androidInfo.version.sdkInt;

      // Try to get RAM information through different methods
      _estimatedRAM = await _estimateDeviceRAM();
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      _deviceModel = iosInfo.model.toLowerCase();
      _deviceManufacturer = 'apple';
      _androidApiLevel = 30; // iOS devices are generally high-spec
      _estimatedRAM = await _estimateDeviceRAM();
    }
  }

  /// Estimate device RAM using various methods
  Future<int> _estimateDeviceRAM() async {
    try {
      // Method 1: Try to get actual RAM from system info
      if (Platform.isAndroid) {
        final int? actualRAM = await _getAndroidRAM();
        if (actualRAM != null && actualRAM > 0) {
          return actualRAM;
        }
      }

      // Method 2: Estimate based on known device models
      final int estimatedRAM = _estimateRAMFromDeviceModel();
      if (estimatedRAM > 0) {
        return estimatedRAM;
      }

      // Method 3: Conservative fallback based on API level
      return _estimateRAMFromAPILevel();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ DevicePerformanceDetector: RAM estimation failed: $e');
      }
      return 1024; // 1GB fallback for safety
    }
  }

  /// Get actual Android RAM using platform channels
  Future<int?> _getAndroidRAM() async {
    try {
      const platform = MethodChannel('device_info/system');
      final result = await platform.invokeMethod('getTotalMemory');
      if (result != null) {
        return (result as int) ~/ (1024 * 1024); // Convert bytes to MB
      }
    } catch (e) {
      // Platform channel not available, continue with estimation
    }
    return null;
  }

  /// Estimate RAM based on known device models
  int _estimateRAMFromDeviceModel() {
    final String modelKey = '$_deviceManufacturer $_deviceModel';

    // Known low-spec POS devices
    if (modelKey.contains('sunmi p2')) return 1024; // 1GB
    if (modelKey.contains('sunmi p1')) return 1024; // 1GB
    if (modelKey.contains('pax a920')) return 1024; // 1GB
    if (modelKey.contains('pax a80')) return 512; // 512MB
    if (modelKey.contains('ingenico')) return 1024; // 1GB
    if (modelKey.contains('castle mp200')) return 1024; // 1GB
    if (modelKey.contains('landi a8')) return 1024; // 1GB
    if (modelKey.contains('landi a9')) return 2048; // 2GB

    // High-spec smartphone patterns
    if (_deviceManufacturer.contains('samsung')) {
      if (_deviceModel.contains('galaxy s') || _deviceModel.contains('note')) {
        return 6144; // 6GB+ for flagship Samsung
      }
      return 4096; // 4GB for mid-range Samsung
    }

    if (_deviceManufacturer.contains('apple')) {
      return 4096; // iOS devices typically have good performance
    }

    if (_deviceManufacturer.contains('google') &&
        _deviceModel.contains('pixel')) {
      return 6144; // 6GB+ for Pixel devices
    }

    if (_deviceManufacturer.contains('oneplus')) {
      return 8192; // 8GB+ for OnePlus
    }

    if (_deviceManufacturer.contains('xiaomi') ||
        _deviceManufacturer.contains('redmi')) {
      return 4096; // 4GB average for Xiaomi/Redmi
    }

    return 0; // Unknown, will fallback to API level estimation
  }

  /// Estimate RAM based on Android API level
  int _estimateRAMFromAPILevel() {
    if (_androidApiLevel >= 30) return 4096; // Android 11+ typically 4GB+
    if (_androidApiLevel >= 28) return 3072; // Android 9+ typically 3GB+
    if (_androidApiLevel >= 26) return 2048; // Android 8+ typically 2GB+
    if (_androidApiLevel >= 23) return 1536; // Android 6+ typically 1.5GB+
    return 1024; // Older Android, assume 1GB
  }

  /// Analyze device capabilities and set optimization flags
  void _analyzePerformanceCapabilities() {
    // Primary check: Known low-spec device models
    _isLowSpecDevice = _isKnownLowSpecDevice();

    // Secondary checks: RAM and API level
    if (!_isLowSpecDevice) {
      _isLowSpecDevice = _estimatedRAM <= LOW_SPEC_RAM_THRESHOLD ||
          _androidApiLevel < LOW_SPEC_API_THRESHOLD;
    }

    // Set specific optimization flags based on analysis
    if (_isLowSpecDevice) {
      _shouldUseLightweightAnimations = true;
      _shouldReduceShimmerEffects = true;
      _shouldOptimizeScrolling = true;
      _shouldSimplifyUI = true;
    } else {
      // High-spec device - enable all features
      _shouldUseLightweightAnimations = false;
      _shouldReduceShimmerEffects = false;
      _shouldOptimizeScrolling = false;
      _shouldSimplifyUI = false;
    }

    // Special cases for mid-range devices
    if (_estimatedRAM > LOW_SPEC_RAM_THRESHOLD && _estimatedRAM < 4096) {
      // Mid-range: Some optimizations but not all
      _shouldReduceShimmerEffects = true;
      _shouldOptimizeScrolling = true;
    }
  }

  /// Check if device is in known low-spec list
  bool _isKnownLowSpecDevice() {
    final String deviceIdentifier =
        '$_deviceManufacturer $_deviceModel'.toLowerCase();

    return LOW_SPEC_DEVICES.any((lowSpecDevice) =>
        deviceIdentifier.contains(lowSpecDevice.toLowerCase()));
  }

  /// Set fallback mode for initialization failures
  void _setFallbackLowSpecMode() {
    _isLowSpecDevice = true;
    _shouldUseLightweightAnimations = true;
    _shouldReduceShimmerEffects = true;
    _shouldOptimizeScrolling = true;
    _shouldSimplifyUI = true;
    _deviceModel = 'unknown';
    _deviceManufacturer = 'unknown';
    _androidApiLevel = 0;
    _estimatedRAM = 1024;
  }

  /// Log device information for debugging
  void _logDeviceInfo() {
    LogUtils.debugLog('📱 Device Performance Analysis:');
    LogUtils.debugLog('   Model: $_deviceManufacturer $_deviceModel');
    LogUtils.debugLog('   Android API: $_androidApiLevel');
    LogUtils.debugLog('   Estimated RAM: ${_estimatedRAM}MB');
    LogUtils.debugLog('   Low-spec device: $_isLowSpecDevice');
    LogUtils.debugLog(
        '   Lightweight animations: $_shouldUseLightweightAnimations');
    LogUtils.debugLog(
        '   Reduce shimmer effects: $_shouldReduceShimmerEffects');
    LogUtils.debugLog('   Optimize scrolling: $_shouldOptimizeScrolling');
    LogUtils.debugLog('   Simplify UI: $_shouldSimplifyUI');
  }

  /// Get recommended scroll physics based on device capability
  ScrollPhysics getOptimalScrollPhysics() {
    if (_shouldOptimizeScrolling) {
      return const ClampingScrollPhysics(); // Faster, less CPU intensive
    }
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  /// Get recommended cache extent for lists
  double getOptimalCacheExtent() {
    if (_shouldOptimizeScrolling) {
      return 200.0; // Smaller cache for low-spec devices
    }
    return 500.0; // Larger cache for high-spec devices
  }

  /// Get recommended animation duration
  Duration getOptimalAnimationDuration() {
    if (_shouldUseLightweightAnimations) {
      return const Duration(milliseconds: 150); // Faster animations
    }
    return const Duration(milliseconds: 300); // Smooth animations
  }

  /// Check if shimmer effects should be used
  bool shouldUseShimmerLoading() {
    // On iOS, prefer simpler loading to avoid render tree complexity
    if (Platform.isIOS) {
      return false;
    }
    return !_shouldReduceShimmerEffects;
  }

  /// Get appropriate number of shimmer items
  int getOptimalShimmerItemCount() {
    if (_shouldReduceShimmerEffects) {
      return 3; // Fewer items for low-spec
    }
    return 6; // More items for high-spec
  }

  /// Check if complex UI elements should be simplified
  bool shouldUseSimplifiedUI() {
    return _shouldSimplifyUI;
  }

  /// Get device performance tier for conditional rendering
  DevicePerformanceTier getPerformanceTier() {
    if (_isLowSpecDevice) {
      return DevicePerformanceTier.low;
    } else if (_estimatedRAM >= 4096) {
      return DevicePerformanceTier.high;
    } else {
      return DevicePerformanceTier.medium;
    }
  }
}

/// Device performance tier enumeration
enum DevicePerformanceTier {
  low, // Low-spec POS devices, old smartphones
  medium, // Mid-range smartphones
  high, // High-spec smartphones, tablets
}

/// Performance optimization configuration for different tiers
class PerformanceConfig {
  static Map<DevicePerformanceTier, PerformanceSettings> get settings => {
        DevicePerformanceTier.low: PerformanceSettings(
          useShimmerLoading: false,
          shimmerItemCount: 3,
          cacheExtent: 200.0,
          animationDuration: Duration(milliseconds: 150),
          scrollPhysics: ClampingScrollPhysics(),
          enableComplexAnimations: false,
          enableBlurEffects: false,
          enableGradients: false,
          maxConcurrentImages: 5,
        ),
        DevicePerformanceTier.medium: PerformanceSettings(
          useShimmerLoading: true,
          shimmerItemCount: 4,
          cacheExtent: 350.0,
          animationDuration: Duration(milliseconds: 200),
          scrollPhysics: BouncingScrollPhysics(),
          enableComplexAnimations: true,
          enableBlurEffects: false,
          enableGradients: true,
          maxConcurrentImages: 10,
        ),
        DevicePerformanceTier.high: PerformanceSettings(
          useShimmerLoading: true,
          shimmerItemCount: 6,
          cacheExtent: 500.0,
          animationDuration: Duration(milliseconds: 300),
          scrollPhysics:
              BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          enableComplexAnimations: true,
          enableBlurEffects: true,
          enableGradients: true,
          maxConcurrentImages: 20,
        ),
      };
}

/// Performance settings configuration
class PerformanceSettings {
  final bool useShimmerLoading;
  final int shimmerItemCount;
  final double cacheExtent;
  final Duration animationDuration;
  final ScrollPhysics scrollPhysics;
  final bool enableComplexAnimations;
  final bool enableBlurEffects;
  final bool enableGradients;
  final int maxConcurrentImages;

  const PerformanceSettings({
    required this.useShimmerLoading,
    required this.shimmerItemCount,
    required this.cacheExtent,
    required this.animationDuration,
    required this.scrollPhysics,
    required this.enableComplexAnimations,
    required this.enableBlurEffects,
    required this.enableGradients,
    required this.maxConcurrentImages,
  });
}
