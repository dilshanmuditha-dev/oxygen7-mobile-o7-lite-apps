import 'package:flutter_test/flutter_test.dart';
import 'package:app/shared/secure_storage/i_secure_storage.dart';

/// In-memory implementation of ISecureStorage for testing.
///
/// This mock simulates the behavior of the real secure storage
/// without requiring platform-specific implementations.
class MockSecureStorage implements ISecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      _storage.remove(key);
    } else {
      _storage[key] = value;
    }
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map.from(_storage);
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey(key);
  }

  /// Clears the mock storage for test isolation.
  void clear() {
    _storage.clear();
  }
}

void main() {
  group('SecureStorage', () {
    late MockSecureStorage storage;

    setUp(() {
      storage = MockSecureStorage();
    });

    tearDown(() {
      storage.clear();
    });

    group('Property 1: Storage round-trip consistency', () {
      // Feature: secure-storage-remediation, Property 1: Storage round-trip consistency
      // For any valid value and valid storage key, writing the value to storage
      // and then reading it back SHALL return an equivalent value.
      // Validates: Requirements 4.2

      test('string values round-trip correctly', () async {
        final testCases = [
          'simple string',
          '',
          'string with spaces',
          'string\nwith\nnewlines',
          'unicode: 你好世界 🎉',
          'special chars: !@#\$%^&*()',
          'a' * 10000, // Long string
        ];

        for (final value in testCases) {
          const key = 'test_key';
          await storage.write(key: key, value: value);
          final result = await storage.read(key: key);
          expect(result, equals(value), reason: 'Failed for value: $value');
        }
      });

      test('integer values round-trip correctly when serialized', () async {
        final testCases = [0, 1, -1, 999999, -999999, 2147483647, -2147483648];

        for (final value in testCases) {
          const key = 'test_int';
          final stringValue = value.toString();
          await storage.write(key: key, value: stringValue);
          final result = await storage.read(key: key);
          expect(int.parse(result!), equals(value));
        }
      });

      test('boolean values round-trip correctly when serialized', () async {
        for (final value in [true, false]) {
          const key = 'test_bool';
          final stringValue = value.toString();
          await storage.write(key: key, value: stringValue);
          final result = await storage.read(key: key);
          expect(result == 'true', equals(value));
        }
      });

      test('multiple keys maintain isolation', () async {
        const key1 = 'key1';
        const key2 = 'key2';
        const value1 = 'value1';
        const value2 = 'value2';

        await storage.write(key: key1, value: value1);
        await storage.write(key: key2, value: value2);

        expect(await storage.read(key: key1), equals(value1));
        expect(await storage.read(key: key2), equals(value2));
      });

      test('overwriting a key updates the value', () async {
        const key = 'test_key';
        const value1 = 'first value';
        const value2 = 'second value';

        await storage.write(key: key, value: value1);
        expect(await storage.read(key: key), equals(value1));

        await storage.write(key: key, value: value2);
        expect(await storage.read(key: key), equals(value2));
      });
    });

    group('Property 6: Deletion completeness', () {
      // Feature: secure-storage-remediation, Property 6: Deletion completeness
      // For any key that has been written and then deleted, subsequent reads
      // SHALL return null.
      // Validates: Requirements 4.2

      test('deleted keys return null', () async {
        const key = 'test_key';
        const value = 'test_value';

        await storage.write(key: key, value: value);
        expect(await storage.read(key: key), equals(value));

        await storage.delete(key: key);
        expect(await storage.read(key: key), isNull);
      });

      test('deleteAll removes all keys', () async {
        await storage.write(key: 'key1', value: 'value1');
        await storage.write(key: 'key2', value: 'value2');
        await storage.write(key: 'key3', value: 'value3');

        await storage.deleteAll();

        expect(await storage.read(key: 'key1'), isNull);
        expect(await storage.read(key: 'key2'), isNull);
        expect(await storage.read(key: 'key3'), isNull);
        expect(await storage.readAll(), isEmpty);
      });

      test('writing null deletes the key', () async {
        const key = 'test_key';
        const value = 'test_value';

        await storage.write(key: key, value: value);
        expect(await storage.read(key: key), equals(value));

        await storage.write(key: key, value: null);
        expect(await storage.read(key: key), isNull);
      });
    });

    group('containsKey', () {
      test('returns true for existing keys', () async {
        const key = 'test_key';
        await storage.write(key: key, value: 'value');
        expect(await storage.containsKey(key: key), isTrue);
      });

      test('returns false for non-existing keys', () async {
        expect(await storage.containsKey(key: 'non_existing'), isFalse);
      });

      test('returns false after deletion', () async {
        const key = 'test_key';
        await storage.write(key: key, value: 'value');
        await storage.delete(key: key);
        expect(await storage.containsKey(key: key), isFalse);
      });
    });

    group('readAll', () {
      test('returns all stored key-value pairs', () async {
        await storage.write(key: 'key1', value: 'value1');
        await storage.write(key: 'key2', value: 'value2');

        final all = await storage.readAll();
        expect(all, equals({'key1': 'value1', 'key2': 'value2'}));
      });

      test('returns empty map when storage is empty', () async {
        final all = await storage.readAll();
        expect(all, isEmpty);
      });
    });
  });
}
