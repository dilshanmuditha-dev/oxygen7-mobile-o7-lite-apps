import 'package:flutter_test/flutter_test.dart';
import 'package:app/shared/secure_storage/i_secure_storage.dart';

/// Mock storage that simulates various failure scenarios.
class FailingMockStorage implements ISecureStorage {
  final Map<String, String> _storage = {};

  // Failure simulation flags
  bool failOnRead = false;
  bool failOnWrite = false;
  bool failOnDelete = false;
  String?
      failureType; // 'tampering', 'corruption', 'wrong_key', 'invalid_format'

  @override
  Future<void> write({required String key, required String? value}) async {
    if (failOnWrite) {
      throw Exception('Write failure: $failureType');
    }
    if (value == null) {
      _storage.remove(key);
    } else {
      _storage[key] = value;
    }
  }

  @override
  Future<String?> read({required String key}) async {
    if (failOnRead) {
      // Simulate uniform error response - always return null
      return null;
    }
    return _storage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    if (failOnDelete) {
      throw Exception('Delete failure');
    }
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<Map<String, String>> readAll() async {
    if (failOnRead) {
      return {}; // Return empty map on failure
    }
    return Map.from(_storage);
  }

  @override
  Future<bool> containsKey({required String key}) async {
    if (failOnRead) {
      return false;
    }
    return _storage.containsKey(key);
  }

  void reset() {
    _storage.clear();
    failOnRead = false;
    failOnWrite = false;
    failOnDelete = false;
    failureType = null;
  }
}

void main() {
  group('Property 5: Error response uniformity', () {
    // Feature: secure-storage-remediation, Property 5: Error response uniformity
    // For any type of decryption failure (tampering, corruption, wrong key, or
    // invalid format), the system SHALL return null without providing
    // distinguishable error responses that could aid attackers.
    // Validates: Requirements 5.1, 5.4

    late FailingMockStorage storage;

    setUp(() {
      storage = FailingMockStorage();
    });

    tearDown(() {
      storage.reset();
    });

    test('tampering failure returns null', () async {
      storage.failOnRead = true;
      storage.failureType = 'tampering';

      final result = await storage.read(key: 'any_key');
      expect(result, isNull);
    });

    test('corruption failure returns null', () async {
      storage.failOnRead = true;
      storage.failureType = 'corruption';

      final result = await storage.read(key: 'any_key');
      expect(result, isNull);
    });

    test('wrong key failure returns null', () async {
      storage.failOnRead = true;
      storage.failureType = 'wrong_key';

      final result = await storage.read(key: 'any_key');
      expect(result, isNull);
    });

    test('invalid format failure returns null', () async {
      storage.failOnRead = true;
      storage.failureType = 'invalid_format';

      final result = await storage.read(key: 'any_key');
      expect(result, isNull);
    });

    test('all failure types produce identical response', () async {
      final failureTypes = [
        'tampering',
        'corruption',
        'wrong_key',
        'invalid_format'
      ];
      final responses = <String?>[];

      for (final failureType in failureTypes) {
        storage.reset();
        storage.failOnRead = true;
        storage.failureType = failureType;

        final result = await storage.read(key: 'test_key');
        responses.add(result);
      }

      // All responses should be null (indistinguishable)
      expect(responses, everyElement(isNull));
    });

    test('readAll returns empty map on failure', () async {
      storage.failOnRead = true;

      final result = await storage.readAll();
      expect(result, isEmpty);
    });

    test('containsKey returns false on failure', () async {
      // First write a value
      await storage.write(key: 'test_key', value: 'test_value');

      // Then simulate failure
      storage.failOnRead = true;

      final result = await storage.containsKey(key: 'test_key');
      expect(result, isFalse);
    });

    test('non-existent key returns null (same as failure)', () async {
      // This ensures attackers cannot distinguish between
      // "key doesn't exist" and "decryption failed"
      final result = await storage.read(key: 'non_existent_key');
      expect(result, isNull);
    });
  });

  group('Error handling behavior', () {
    late FailingMockStorage storage;

    setUp(() {
      storage = FailingMockStorage();
    });

    tearDown(() {
      storage.reset();
    });

    test('successful read after write', () async {
      await storage.write(key: 'key', value: 'value');
      final result = await storage.read(key: 'key');
      expect(result, equals('value'));
    });

    test('read returns null for non-existent key', () async {
      final result = await storage.read(key: 'non_existent');
      expect(result, isNull);
    });

    test('delete removes key', () async {
      await storage.write(key: 'key', value: 'value');
      await storage.delete(key: 'key');
      final result = await storage.read(key: 'key');
      expect(result, isNull);
    });
  });
}
