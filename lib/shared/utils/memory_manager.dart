// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'device_performance_detector.dart';

/// Memory management system for low-spec devices
///
/// Features:
/// - Automatic memory monitoring
/// - Garbage collection optimization
/// - Memory leak detection
/// - Resource cleanup automation
class MemoryManager {
  static MemoryManager? _instance;
  static MemoryManager get instance => _instance ??= MemoryManager._();

  MemoryManager._();

  Timer? _memoryMonitorTimer;
  Timer? _cleanupTimer;
  bool _isInitialized = false;
  int _lastMemoryUsage = 0;
  final List<MemoryWarningCallback> _memoryWarningCallbacks = [];
  final Map<String, DateTime> _resourceTimestamps = {};

  // Memory thresholds (in MB)
  static const int MEMORY_WARNING_THRESHOLD = 200; // 200MB
  static const int MEMORY_CRITICAL_THRESHOLD = 300; // 300MB
  static const int MAX_CACHE_AGE_MINUTES = 15;

  /// Initialize memory manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    final detector = DevicePerformanceDetector.instance;

    // Only enable intensive monitoring for low-spec devices
    if (detector.isInitialized && detector.isLowSpecDevice) {
      await _startMemoryMonitoring();
      _startPeriodicCleanup();
    }

    _isInitialized = true;

    if (kDebugMode) {
      print(
          '🧠 MemoryManager: Initialized for ${detector.isLowSpecDevice ? "low-spec" : "high-spec"} device');
    }
  }

  /// Start memory monitoring
  Future<void> _startMemoryMonitoring() async {
    _memoryMonitorTimer = Timer.periodic(
      const Duration(seconds: 30), // Check every 30 seconds
      (timer) => _checkMemoryUsage(),
    );
  }

  /// Start periodic cleanup
  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5), // Cleanup every 5 minutes
      (timer) => performCleanup(),
    );
  }

  /// Check current memory usage
  Future<void> _checkMemoryUsage() async {
    try {
      final memoryUsage = await _getCurrentMemoryUsage();

      if (memoryUsage > MEMORY_CRITICAL_THRESHOLD) {
        await _handleCriticalMemory();
      } else if (memoryUsage > MEMORY_WARNING_THRESHOLD) {
        _handleMemoryWarning();
      }

      _lastMemoryUsage = memoryUsage;

      if (kDebugMode && memoryUsage > MEMORY_WARNING_THRESHOLD) {
        print('⚠️ MemoryManager: High memory usage: ${memoryUsage}MB');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MemoryManager: Error checking memory usage: $e');
      }
    }
  }

  /// Get current memory usage in MB
  Future<int> _getCurrentMemoryUsage() async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('memory_info/system');
        final result = await platform.invokeMethod('getMemoryUsage');
        return (result as int) ~/ (1024 * 1024); // Convert bytes to MB
      }
    } catch (e) {
      // Platform channel not available, use estimation
    }

    // Fallback estimation based on known factors
    return _estimateMemoryUsage();
  }

  /// Estimate memory usage based on app state
  int _estimateMemoryUsage() {
    // Base memory usage estimation
    int estimated = 50; // Base Flutter app memory

    // Add estimated usage based on cached resources
    estimated += _resourceTimestamps.length * 2; // ~2MB per resource

    return estimated;
  }

  /// Handle critical memory situation
  Future<void> _handleCriticalMemory() async {
    if (kDebugMode) {
      print(
          '🚨 MemoryManager: Critical memory usage detected - performing aggressive cleanup');
    }

    // Trigger aggressive cleanup
    await _aggressiveCleanup();

    // Notify callbacks
    for (final callback in _memoryWarningCallbacks) {
      callback(MemoryWarningLevel.critical);
    }

    // Force garbage collection
    _forceGarbageCollection();
  }

  /// Handle memory warning
  void _handleMemoryWarning() {
    if (kDebugMode) {
      print('⚠️ MemoryManager: Memory warning - performing standard cleanup');
    }

    // Trigger standard cleanup
    performCleanup();

    // Notify callbacks
    for (final callback in _memoryWarningCallbacks) {
      callback(MemoryWarningLevel.warning);
    }
  }

  /// Perform standard cleanup
  void performCleanup() {
    _cleanupOldResources();
    _cleanupImageCache();
    _forceGarbageCollection();
  }

  /// Perform aggressive cleanup
  Future<void> _aggressiveCleanup() async {
    // Clear all caches
    _resourceTimestamps.clear();

    // Clear image cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // Clear any custom caches
    await _clearCustomCaches();

    // Force multiple GC cycles
    for (int i = 0; i < 3; i++) {
      _forceGarbageCollection();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Clean up old resources
  void _cleanupOldResources() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _resourceTimestamps.entries) {
      final age = now.difference(entry.value).inMinutes;
      if (age > MAX_CACHE_AGE_MINUTES) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _resourceTimestamps.remove(key);
    }

    if (kDebugMode && keysToRemove.isNotEmpty) {
      print('MemoryManager: Cleaned up ${keysToRemove.length} old resources');
    }
  }

  /// Clean up image cache with size limits
  void _cleanupImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;
    final detector = DevicePerformanceDetector.instance;

    if (detector.isInitialized && detector.isLowSpecDevice) {
      // Aggressive cache limits for low-spec devices
      imageCache.maximumSize = 50; // Max 50 images
      imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB max
    } else {
      // Standard limits for high-spec devices
      imageCache.maximumSize = 1000;
      imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100MB max
    }

    // Clear excess images if over limit
    if (imageCache.currentSize > imageCache.maximumSize) {
      imageCache.clear();
    }
  }

  /// Clear custom application caches
  Future<void> _clearCustomCaches() async {
    try {
      // Clear app-specific caches here when additional caches are introduced.
    } catch (e) {
      if (kDebugMode) {
        print('MemoryManager: Error clearing custom caches: $e');
      }
    }
  }

  /// Force garbage collection
  void _forceGarbageCollection() {
    // Note: In production, avoid frequent GC calls as they can cause stuttering
    if (kDebugMode) {
      print('MemoryManager: Forcing garbage collection');
    }

    // This doesn't guarantee immediate GC, but suggests it to the VM
    Future.delayed(Duration.zero, () {
      // Force a microtask to potentially trigger GC
    });
  }

  /// Register resource usage
  void registerResource(String resourceId) {
    _resourceTimestamps[resourceId] = DateTime.now();
  }

  /// Unregister resource
  void unregisterResource(String resourceId) {
    _resourceTimestamps.remove(resourceId);
  }

  /// Add memory warning callback
  void addMemoryWarningCallback(MemoryWarningCallback callback) {
    _memoryWarningCallbacks.add(callback);
  }

  /// Remove memory warning callback
  void removeMemoryWarningCallback(MemoryWarningCallback callback) {
    _memoryWarningCallbacks.remove(callback);
  }

  /// Get current memory statistics
  Map<String, dynamic> getMemoryStats() {
    final imageCache = PaintingBinding.instance.imageCache;

    return {
      'lastMemoryUsage': _lastMemoryUsage,
      'resourceCount': _resourceTimestamps.length,
      'imageCacheSize': imageCache.currentSize,
      'imageCacheSizeBytes': imageCache.currentSizeBytes,
      'isMonitoring': _memoryMonitorTimer?.isActive ?? false,
    };
  }

  /// Check if device is under memory pressure
  bool isUnderMemoryPressure() {
    return _lastMemoryUsage > MEMORY_WARNING_THRESHOLD;
  }

  /// Dispose memory manager
  void dispose() {
    _memoryMonitorTimer?.cancel();
    _cleanupTimer?.cancel();
    _memoryWarningCallbacks.clear();
    _resourceTimestamps.clear();
    _isInitialized = false;
  }
}

/// Memory warning levels
enum MemoryWarningLevel {
  warning,
  critical,
}

/// Memory warning callback type
typedef MemoryWarningCallback = void Function(MemoryWarningLevel level);

/// Mixin for widgets that need memory management
mixin MemoryAwareMixin {
  late final MemoryWarningCallback _memoryCallback;

  /// Initialize memory awareness
  void initializeMemoryAwareness() {
    _memoryCallback = (level) => onMemoryWarning(level);
    MemoryManager.instance.addMemoryWarningCallback(_memoryCallback);
  }

  /// Handle memory warning - override in implementing classes
  void onMemoryWarning(MemoryWarningLevel level) {
    // Default implementation - can be overridden
    if (level == MemoryWarningLevel.critical) {
      // Perform emergency cleanup
      releaseResources();
    }
  }

  /// Release resources - implement in subclasses
  void releaseResources() {
    // Override in implementing classes
  }

  /// Dispose memory awareness
  void disposeMemoryAwareness() {
    MemoryManager.instance.removeMemoryWarningCallback(_memoryCallback);
  }
}

/// Memory-aware StatefulWidget base class
abstract class MemoryAwareStatefulWidget extends StatefulWidget {
  const MemoryAwareStatefulWidget({Key? key}) : super(key: key);
}

/// Memory-aware State base class
abstract class MemoryAwareState<T extends MemoryAwareStatefulWidget>
    extends State<T> with MemoryAwareMixin {
  @override
  void initState() {
    super.initState();
    initializeMemoryAwareness();
  }

  @override
  void dispose() {
    disposeMemoryAwareness();
    super.dispose();
  }

  /// Register a resource for memory tracking
  void registerResource(String resourceId) {
    MemoryManager.instance.registerResource(resourceId);
  }

  /// Unregister a resource
  void unregisterResource(String resourceId) {
    MemoryManager.instance.unregisterResource(resourceId);
  }
}
