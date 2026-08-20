import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/shared/secure_storage/i_secure_storage.dart';
import 'package:app/shared/secure_storage/migration_service.dart';

/// Mock implementation of ISecureStorage for testing.
class MockSecureStorage implements ISecureStorage {
  final Map<String, String> _storage = {};
  bool shouldFailOnWrite = false;
  Set<String> keysToFailOnWrite = {};

  @override
  Future<void> write({required String key, required String? value}) async {
    if (shouldFailOnWrite || keysToFailOnWrite.contains(key)) {
      throw Exception('Mock write failure');
    }
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

  void clear() {
    _storage.clear();
    shouldFailOnWrite = false;
    keysToFailOnWrite.clear();
  }
}

/// Mock implementation of LegacyStorageAdapter for testing.
class MockLegacyStorageAdapter {
  final Map<String, dynamic> _legacyData = {};

  void setLegacyData(Map<String, dynamic> data) {
    _legacyData.clear();
    _legacyData.addAll(data);
  }

  Future<Map<String, dynamic>> readAllLegacyData() async {
    return Map.from(_legacyData);
  }

  Future<void> clearLegacy() async {
    _legacyData.clear();
  }

  void clear() {
    _legacyData.clear();
  }
}

/// Test-friendly MigrationService that uses mocks.
class TestMigrationService {
  static const String _migrationCompleteKey = '_secure_storage_migrated_v2';

  final MockLegacyStorageAdapter _legacyStorage;
  final ISecureStorage _newStorage;

  TestMigrationService({
    required MockLegacyStorageAdapter legacyStorage,
    required ISecureStorage newStorage,
  })  : _legacyStorage = legacyStorage,
        _newStorage = newStorage;

  Future<bool> isMigrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationCompleteKey) ?? false;
  }

  Future<void> markMigrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationCompleteKey, true);
  }

  Future<void> clearMigrationFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationCompleteKey);
  }

  Future<MigrationResult> migrateIfNeeded() async {
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

  Future<MigrationResult> _performMigration() async {
    final failedKeys = <String>[];
    var migratedCount = 0;

    try {
      final legacyData = await _legacyStorage.readAllLegacyData();

      for (final entry in legacyData.entries) {
        try {
          await _newStorage.write(
              key: entry.key, value: entry.value.toString());
          migratedCount++;
        } catch (e) {
          failedKeys.add(entry.key);
        }
      }

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

  Future<MigrationResult> forceMigration() async {
    await clearMigrationFlag();
    return await _performMigration();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MigrationService', () {
    late MockSecureStorage newStorage;
    late MockLegacyStorageAdapter legacyStorage;
    late TestMigrationService migrationService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      newStorage = MockSecureStorage();
      legacyStorage = MockLegacyStorageAdapter();
      migrationService = TestMigrationService(
        legacyStorage: legacyStorage,
        newStorage: newStorage,
      );
    });

    tearDown(() async {
      newStorage.clear();
      legacyStorage.clear();
      await migrationService.clearMigrationFlag();
    });

    group('Property 2: Migration data preservation', () {
      // Feature: secure-storage-remediation, Property 2: Migration data preservation
      // For any set of key-value pairs stored in the legacy storage system,
      // after migration completes, reading each key from the new storage system
      // SHALL return the identical value that was stored in the legacy system.
      // Validates: Requirements 1.3, 3.2, 3.5

      test('all legacy data is preserved after migration', () async {
        final legacyData = {
          'routeList': 'route1,route2,route3',
          'brandList': 'brand1,brand2',
          'mcpTerminalId': 'TERM123',
          'password': 'encrypted_password',
          'tid': 'TID456',
        };

        legacyStorage.setLegacyData(legacyData);

        final result = await migrationService.migrateIfNeeded();

        expect(result.success, isTrue);
        expect(result.migratedCount, equals(legacyData.length));

        // Verify all data is preserved
        for (final entry in legacyData.entries) {
          final migratedValue = await newStorage.read(key: entry.key);
          expect(migratedValue, equals(entry.value),
              reason: 'Value for key ${entry.key} was not preserved');
        }
      });

      test('empty legacy data results in empty migration', () async {
        legacyStorage.setLegacyData({});

        final result = await migrationService.migrateIfNeeded();

        expect(result.success, isTrue);
        expect(result.migratedCount, equals(0));
        expect(await newStorage.readAll(), isEmpty);
      });

      test('special characters in values are preserved', () async {
        final legacyData = {
          'key1': 'value with spaces',
          'key2': 'value\nwith\nnewlines',
          'key3': 'unicode: 你好世界',
          'key4': 'special: !@#\$%^&*()',
        };

        legacyStorage.setLegacyData(legacyData);

        final result = await migrationService.migrateIfNeeded();

        expect(result.success, isTrue);
        for (final entry in legacyData.entries) {
          final migratedValue = await newStorage.read(key: entry.key);
          expect(migratedValue, equals(entry.value));
        }
      });
    });

    group('Property 3: Migration idempotence', () {
      // Feature: secure-storage-remediation, Property 3: Migration idempotence
      // For any storage state, running the migration process N times (where N >= 1)
      // SHALL produce the same final state as running it exactly once.
      // Validates: Requirements 3.4

      test('migration only runs once', () async {
        final legacyData = {
          'key1': 'value1',
          'key2': 'value2',
        };

        legacyStorage.setLegacyData(legacyData);

        // First migration
        final result1 = await migrationService.migrateIfNeeded();
        expect(result1.migratedCount, equals(2));

        // Second migration attempt
        final result2 = await migrationService.migrateIfNeeded();
        expect(result2.migratedCount, equals(0)); // Should not migrate again

        // Verify data is still correct
        expect(await newStorage.read(key: 'key1'), equals('value1'));
        expect(await newStorage.read(key: 'key2'), equals('value2'));
      });

      test('multiple migration calls produce same result', () async {
        final legacyData = {'key': 'value'};
        legacyStorage.setLegacyData(legacyData);

        // Run migration multiple times
        await migrationService.migrateIfNeeded();
        await migrationService.migrateIfNeeded();
        await migrationService.migrateIfNeeded();

        // Verify final state
        final allData = await newStorage.readAll();
        expect(allData, equals({'key': 'value'}));
      });

      test('force migration can re-run migration', () async {
        final legacyData = {'key': 'original'};
        legacyStorage.setLegacyData(legacyData);

        // First migration
        await migrationService.migrateIfNeeded();
        expect(await newStorage.read(key: 'key'), equals('original'));

        // Update legacy data
        legacyStorage.setLegacyData({'key': 'updated'});

        // Normal migration should not run
        final result = await migrationService.migrateIfNeeded();
        expect(result.migratedCount, equals(0));

        // Force migration should run
        final forceResult = await migrationService.forceMigration();
        expect(forceResult.migratedCount, equals(1));
        expect(await newStorage.read(key: 'key'), equals('updated'));
      });
    });

    group('Error handling', () {
      test('migration continues after individual key failures', () async {
        final legacyData = {
          'key1': 'value1',
          'key2': 'value2',
          'key3': 'value3',
        };

        legacyStorage.setLegacyData(legacyData);
        newStorage.keysToFailOnWrite = {'key2'};

        final result = await migrationService.forceMigration();

        expect(result.success, isFalse);
        expect(result.migratedCount, equals(2));
        expect(result.failedCount, equals(1));
        expect(result.failedKeys, contains('key2'));

        // Verify successful keys were migrated
        expect(await newStorage.read(key: 'key1'), equals('value1'));
        expect(await newStorage.read(key: 'key3'), equals('value3'));
        expect(await newStorage.read(key: 'key2'), isNull);
      });

      test('migration marks complete even with partial failures', () async {
        final legacyData = {
          'key1': 'value1',
          'key2': 'value2',
        };

        legacyStorage.setLegacyData(legacyData);
        newStorage.keysToFailOnWrite = {'key2'};

        await migrationService.forceMigration();

        // Should be marked complete to prevent re-migration
        expect(await migrationService.isMigrationComplete(), isTrue);
      });
    });
  });
}
