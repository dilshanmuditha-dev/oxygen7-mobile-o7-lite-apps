// Memory Manager - Handles device RAM diagnostics
import 'dart:io';
import '../models/diagnostic_models.dart';
import '../utils/formatters.dart';
import 'package:app/shared/utils/log_utils.dart';

class MemoryManager {
  /// Get total RAM in bytes
  Future<int> getTotalMemory() async {
    try {
      if (Platform.isAndroid) {
        // Read from /proc/meminfo on Android
        final file = File('/proc/meminfo');
        if (await file.exists()) {
          final contents = await file.readAsString();
          final lines = contents.split('\n');
          for (final line in lines) {
            if (line.startsWith('MemTotal:')) {
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length >= 2) {
                // Value is in kB
                final kb = int.tryParse(parts[1]) ?? 0;
                return kb * 1024;
              }
            }
          }
        }
      }
      // Fallback value for iOS or if reading fails
      return 4 * 1024 * 1024 * 1024; // 4GB default
    } catch (e) {
      LogUtils.debugLog('Error getting total memory: $e');
      return 0;
    }
  }

  /// Get free/available RAM in bytes
  Future<int> getFreeMemory() async {
    try {
      if (Platform.isAndroid) {
        final file = File('/proc/meminfo');
        if (await file.exists()) {
          final contents = await file.readAsString();
          final lines = contents.split('\n');
          int memFree = 0;
          int buffers = 0;
          int cached = 0;

          for (final line in lines) {
            if (line.startsWith('MemFree:')) {
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length >= 2) {
                memFree = (int.tryParse(parts[1]) ?? 0) * 1024;
              }
            } else if (line.startsWith('Buffers:')) {
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length >= 2) {
                buffers = (int.tryParse(parts[1]) ?? 0) * 1024;
              }
            } else if (line.startsWith('Cached:')) {
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length >= 2) {
                cached = (int.tryParse(parts[1]) ?? 0) * 1024;
              }
            }
          }
          // Available memory = MemFree + Buffers + Cached
          return memFree + buffers + cached;
        }
      }
      // Fallback
      return 1024 * 1024 * 1024; // 1GB default
    } catch (e) {
      LogUtils.debugLog('Error getting free memory: $e');
      return 0;
    }
  }

  /// Get used RAM in bytes
  Future<int> getUsedMemory() async {
    final total = await getTotalMemory();
    final free = await getFreeMemory();
    return total - free;
  }

  /// Get complete memory info
  Future<MemoryInfo> getMemoryInfo() async {
    try {
      final total = await getTotalMemory();
      final free = await getFreeMemory();
      final used = total > 0 ? total - free : 0;
      final percentage = calculatePercentage(used, total);
      final status = getMemoryStatus(free);

      return MemoryInfo(
        totalBytes: total,
        freeBytes: free,
        usedBytes: used,
        usagePercentage: percentage,
        status: status,
      );
    } catch (e) {
      LogUtils.debugLog('Error getting memory info: $e');
      return MemoryInfo(
        totalBytes: 0,
        freeBytes: 0,
        usedBytes: 0,
        usagePercentage: 0,
        status: DiagnosticStatus.error,
      );
    }
  }
}
