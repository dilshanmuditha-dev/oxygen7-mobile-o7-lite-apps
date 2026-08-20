/// Stub adapter for legacy secure_shared_preferences.
///
/// This adapter was originally used during migration to read existing encrypted
/// data from the old storage system (AES-CBC). Now that migration is complete
/// and the secure_shared_preferences dependency has been removed, this class
/// serves as a no-op stub that returns empty data.
///
/// For existing users: Migration has already occurred on first app launch
/// after the update, so their data is already in the new secure storage.
///
/// For new users: There is no legacy data to migrate.
///
/// This class is kept for API compatibility with MigrationService.
class LegacyStorageAdapter {
  /// Reads a string value from legacy storage.
  ///
  /// Always returns null since legacy storage is no longer available.
  Future<String?> readLegacyString({
    required String key,
    bool isEncrypted = true,
  }) async {
    // Legacy storage removed - no data to read
    return null;
  }

  /// Reads an integer value from legacy storage.
  ///
  /// Always returns null since legacy storage is no longer available.
  Future<int?> readLegacyInt({required String key}) async {
    // Legacy storage removed - no data to read
    return null;
  }

  /// Reads a boolean value from legacy storage.
  ///
  /// Always returns null since legacy storage is no longer available.
  Future<bool?> readLegacyBool({required String key}) async {
    // Legacy storage removed - no data to read
    return null;
  }

  /// Reads all legacy data for migration.
  ///
  /// Always returns an empty map since legacy storage is no longer available.
  Future<Map<String, dynamic>> readAllLegacyData() async {
    // Legacy storage removed - no data to migrate
    return <String, dynamic>{};
  }

  /// Clears all data from legacy storage.
  ///
  /// No-op since legacy storage is no longer available.
  Future<void> clearLegacy() async {
    // Legacy storage removed - nothing to clear
  }
}
