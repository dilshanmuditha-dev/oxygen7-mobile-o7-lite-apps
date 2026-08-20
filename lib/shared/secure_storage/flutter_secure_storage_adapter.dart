import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'i_secure_storage.dart';

/// Implementation of [ISecureStorage] using flutter_secure_storage with AES-GCM.
///
/// This adapter provides secure storage with:
/// - AES-GCM authenticated encryption (confidentiality + integrity)
/// - RSA-OAEP key wrapping on Android
/// - iOS Keychain storage
///
/// Security features:
/// - Prevents padding oracle attacks (AES-GCM has no padding)
/// - Provides integrity protection (GCM authentication tag)
/// - Uses hardware-backed key storage where available
class FlutterSecureStorageAdapter implements ISecureStorage {
  late final FlutterSecureStorage _storage;

  FlutterSecureStorageAdapter() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        // RSA-OAEP for key wrapping + AES-GCM for data encryption
        // This is the recommended secure configuration
        keyCipherAlgorithm:
            KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
      iOptions: IOSOptions(
        // Accessible after first unlock, not synced to other devices
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      await delete(key: key);
      return;
    }

    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (e) {
      // Log error without exposing sensitive details
      throw SecureStorageException(
        'Failed to write to secure storage',
        code: e.code,
      );
    }
  }

  @override
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException {
      // Return null for all read failures to prevent information leakage
      // This ensures uniform error responses (Requirement 5.4)
      return null;
    }
  }

  @override
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException catch (e) {
      throw SecureStorageException(
        'Failed to delete from secure storage',
        code: e.code,
      );
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } on PlatformException catch (e) {
      throw SecureStorageException(
        'Failed to clear secure storage',
        code: e.code,
      );
    }
  }

  @override
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } on PlatformException {
      // Return empty map on failure to prevent information leakage
      return {};
    }
  }

  @override
  Future<bool> containsKey({required String key}) async {
    try {
      return await _storage.containsKey(key: key);
    } on PlatformException {
      return false;
    }
  }
}

/// Exception thrown when secure storage operations fail.
///
/// This exception intentionally does not expose detailed error information
/// to prevent aiding potential attackers (Requirement 5.3).
class SecureStorageException implements Exception {
  final String message;
  final String? code;

  SecureStorageException(this.message, {this.code});

  @override
  String toString() => 'SecureStorageException: $message';
}
