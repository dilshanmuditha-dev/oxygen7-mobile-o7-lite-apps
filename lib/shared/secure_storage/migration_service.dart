import 'package:shared_preferences/shared_preferences.dart';

import 'i_secure_storage.dart';
import 'legacy_storage_adapter.dart';

/// Result of a migration operation.
class MigrationResult {
  final bool success;
  final int migratedCount;
  final int failedCount;
  final List<String> failedKeys;
  final String? errorMessage;

  MigrationResult({
    required this.success,
    required this.migratedCount,
    required this.failedCount,
    required this.failedKeys,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'MigrationResult(success: $success, migrated: $migratedCount, '
        'failed: $failedCount, failedKeys: $failedKeys)';
  }
}

/// Service responsible for migrating data from legacy storage to new secure storage.
///
/// This service handles the one-time migration from secure_shared_preferences
/// (AES-CBC) to flutter_secure_storage (AES-GCM).
///
/// Migration behavior:
/// - Runs automatically on first access after update
/// - Migrates all existing encrypted data to new format
/// - Continues on individual key failures (Requirement 3.3)
/// - Marks migration complete to prevent re-migration (Requirement 3.4)
/// - Preserves all data keys and values (Requirement 3.5)
class MigrationService {
  static const String _migrationCompleteKey = '_secure_storage_migrated_v2';

  final LegacyStorageAdapter _legacyStorage;
  final ISecureStorage _newStorage;

  MigrationService({
    required LegacyStorageAdapter legacyStorage,
    required ISecureStorage newStorage,
  })  : _legacyStorage = legacyStorage,
        _newStorage = newStorage;

  /// Checks if migration has already been completed.
  Future<bool> isMigrationComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_migrationCompleteKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Marks migration as complete to prevent re-migration.
  Future<void> markMigrationComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migrationCompleteKey, true);
    } catch (e) {
      // Log but don't fail - worst case is migration runs again
    }
  }

  /// Performs migration if needed.
  ///
  /// Returns a [MigrationResult] with details about the migration.
  /// If migration was already complete, returns a result with migratedCount = 0.
  Future<MigrationResult> migrateIfNeeded() async {
    // Check if migration already completed
    if (await isMigrationComplete()) {
      return MigrationResult(
        success: true,
        migratedCount: 0,
        failedCount: 0,
        failedKeys: [],
      );
    }

    return await _performMigration();
  }

  /// Performs the actual migration.
  Future<MigrationResult> _performMigration() async {
    final failedKeys = <String>[];
    var migratedCount = 0;

    try {
      // Read all legacy data
      final legacyData = await _legacyStorage.readAllLegacyData();

      // Migrate each key-value pair
      for (final entry in legacyData.entries) {
        try {
          await _newStorage.write(key: entry.key, value: entry.value);
          migratedCount++;
        } catch (e) {
          // Log error and continue with remaining keys (Requirement 3.3)
          failedKeys.add(entry.key);
        }
      }

      // Mark migration complete if at least partially successful
      if (failedKeys.isEmpty || migratedCount > 0) {
        await markMigrationComplete();
      }

      return MigrationResult(
        success: failedKeys.isEmpty,
        migratedCount: migratedCount,
        failedCount: failedKeys.length,
        failedKeys: failedKeys,
      );
    } catch (e) {
      return MigrationResult(
        success: false,
        migratedCount: migratedCount,
        failedCount: failedKeys.length,
        failedKeys: failedKeys,
        errorMessage: 'Migration failed: ${e.toString()}',
      );
    }
  }

  /// Forces migration to run again (for testing purposes).
  ///
  /// This clears the migration complete flag and runs migration.
  Future<MigrationResult> forceMigration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_migrationCompleteKey);
    } catch (e) {
      // Continue anyway
    }
    return await _performMigration();
  }
}
