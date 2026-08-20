/// Abstract interface defining secure storage operations.
///
/// This interface provides a contract for secure storage implementations,
/// allowing for different backends (e.g., flutter_secure_storage, legacy storage)
/// while maintaining a consistent API.
abstract class ISecureStorage {
  /// Writes a value to secure storage.
  ///
  /// [key] - The key to store the value under
  /// [value] - The value to store (null to delete)
  Future<void> write({required String key, required String? value});

  /// Reads a value from secure storage.
  ///
  /// [key] - The key to read
  /// Returns the stored value, or null if not found or on error
  Future<String?> read({required String key});

  /// Deletes a value from secure storage.
  ///
  /// [key] - The key to delete
  Future<void> delete({required String key});

  /// Deletes all values from secure storage.
  Future<void> deleteAll();

  /// Reads all key-value pairs from secure storage.
  ///
  /// Returns a map of all stored key-value pairs
  Future<Map<String, String>> readAll();

  /// Checks if a key exists in secure storage.
  ///
  /// [key] - The key to check
  /// Returns true if the key exists, false otherwise
  Future<bool> containsKey({required String key});
}
