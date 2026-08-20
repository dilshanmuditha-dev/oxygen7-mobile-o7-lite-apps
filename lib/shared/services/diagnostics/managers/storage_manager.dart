// Storage Manager - Handles device storage diagnostics
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/diagnostic_models.dart';
import '../utils/formatters.dart';
import 'package:app/shared/utils/log_utils.dart';

class StorageManager {
  /// Get total internal storage in bytes
  Future<int> getTotalStorage() async {
    try {
      if (Platform.isAndroid) {
        final directory = await getApplicationDocumentsDirectory();
        final result = await Process.run('df', [directory.path]);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          if (lines.length > 1) {
            final parts = lines[1].split(RegExp(r'\s+'));
            if (parts.length >= 2) {
              return int.tryParse(parts[1]) ?? 0 * 1024;
            }
          }
        }
        return await _getDirectorySize(directory);
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        return await _getDirectorySize(directory);
      }
      return 0;
    } catch (e) {
      LogUtils.debugLog('Error getting total storage: $e');
      return 0;
    }
  }

  /// Get free storage space in bytes
  Future<int> getFreeStorage() async {
    try {
      if (Platform.isAndroid) {
        final directory = await getApplicationDocumentsDirectory();

        final result = await Process.run('df', [directory.path]);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          if (lines.length > 1) {
            final parts = lines[1].split(RegExp(r'\s+'));
            if (parts.length >= 4) {
              // df returns available space in 1K blocks (index 3)
              final availableKB = int.tryParse(parts[3]) ?? 0;
              return availableKB * 1024;
            }
          }
        }
      }

      return 1024 * 1024 * 1024; // 1GB fallback
    } catch (e) {
      LogUtils.debugLog('Error getting free storage: $e');
      return 0;
    }
  }

  /// Get used storage space in bytes
  Future<int> getUsedStorage() async {
    final total = await getTotalStorage();
    final free = await getFreeStorage();
    return total - free;
  }

  /// Get complete storage info
  Future<StorageInfo> getStorageInfo() async {
    try {
      final total = await getTotalStorage();
      final free = await getFreeStorage();
      final used = total > 0 ? total - free : 0;
      final percentage = calculatePercentage(used, total);
      final status = getStorageStatus(free);

      return StorageInfo(
        totalBytes: total,
        freeBytes: free,
        usedBytes: used,
        usagePercentage: percentage,
        status: status,
      );
    } catch (e) {
      LogUtils.debugLog('Error getting storage info: $e');
      return StorageInfo(
        totalBytes: 0,
        freeBytes: 0,
        usedBytes: 0,
        usagePercentage: 0,
        status: DiagnosticStatus.error,
      );
    }
  }

  Future<int> _getDirectorySize(Directory directory) async {
    int size = 0;
    try {
      if (await directory.exists()) {
        await for (final entity
            in directory.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (e) {
      LogUtils.debugLog('Error calculating directory size: $e');
    }
    return size;
  }
}
