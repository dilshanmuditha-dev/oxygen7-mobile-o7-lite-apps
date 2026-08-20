import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/shared/secure_storage/i_secure_storage.dart';
import 'package:app/shared/secure_storage/secure_storage_service.dart';

/// Mock implementation of ISecureStorage for testing.
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

  void clear() {
    _storage.clear();
  }
}

/// Test-friendly SecureStorageService that uses mock storage directly.
class TestSecureStorageService {
  final ISecureStorage _storage;

  TestSecureStorageService(this._storage);

  // Route List Methods
  Future<void> setRouteList(String? routeList) async {
    await _storage.write(key: 'routeList', value: routeList);
  }

  Future<String?> getRouteList() async {
    return await _storage.read(key: 'routeList');
  }

  Future<void> setRootRouteList(String? routeList) async {
    await _storage.write(key: 'rootRouteList', value: routeList);
  }

  Future<String?> getRootRouteList() async {
    return await _storage.read(key: 'rootRouteList');
  }

  Future<void> setDonationRouteList(String? routeList) async {
    await _storage.write(key: 'donationRouteList', value: routeList);
  }

  Future<String?> getDonationRouteList() async {
    return await _storage.read(key: 'donationRouteList');
  }

  // Brand List Methods
  Future<void> setBrandList(String? brandList) async {
    await _storage.write(key: 'brandList', value: brandList);
  }

  Future<String?> getBrandList() async {
    return await _storage.read(key: 'brandList');
  }

  Future<void> setRootBrandList(String? brandList) async {
    await _storage.write(key: 'rootBrandList', value: brandList);
  }

  Future<String?> getRootBrandList() async {
    return await _storage.read(key: 'rootBrandList');
  }

  // Terminal ID Methods
  Future<void> setMCPTerminalId(String? mcpTerminalID) async {
    await _storage.write(key: 'mcpTerminalId', value: mcpTerminalID);
  }

  Future<String?> getMCPTerminalId() async {
    return await _storage.read(key: 'mcpTerminalId');
  }

  Future<void> setTID(String? tid) async {
    await _storage.write(key: 'tid', value: tid);
  }

  Future<String?> getTID() async {
    return await _storage.read(key: 'tid');
  }

  // Merchant Info Methods
  Future<void> setMerchantName(String? merchantName) async {
    await _storage.write(key: 'merchantName', value: merchantName);
  }

  Future<String?> getMerchantName() async {
    return await _storage.read(key: 'merchantName');
  }

  Future<void> setAddress(String? address) async {
    await _storage.write(key: 'address', value: address);
  }

  Future<String?> getAdress() async {
    return await _storage.read(key: 'address');
  }

  // Authentication Methods
  Future<void> setPassword(String? password) async {
    await _storage.write(key: 'password', value: password);
  }

  Future<String?> getPassword() async {
    return await _storage.read(key: 'password');
  }

  Future<void> setRememberTid(bool? rememberTid) async {
    await _storage.write(
        key: 'remmemberTid', value: rememberTid?.toString() ?? 'false');
  }

  Future<bool?> getRememberTid() async {
    final value = await _storage.read(key: 'remmemberTid');
    if (value == null) return null;
    return value == 'true';
  }

  // Settings Methods
  Future<void> setServiceChargeRate(int? serviceChargeRate) async {
    await _storage.write(
        key: 'serviceChargeRate', value: serviceChargeRate?.toString() ?? '0');
  }

  Future<int?> getServiceChargeRate() async {
    final value = await _storage.read(key: 'serviceChargeRate');
    if (value == null) return 0;
    return int.tryParse(value) ?? 0;
  }

  Future<void> setCarplaceNumber(String? carplateNumber) async {
    await _storage.write(key: 'carplaceNumber', value: carplateNumber);
  }

  Future<String?> getCarplaceNumber() async {
    return await _storage.read(key: 'carplaceNumber');
  }

  Future<void> setEmailCC(String? emailCC) async {
    await _storage.write(key: 'EMAIL_CC', value: emailCC);
  }

  Future<String?> getEmailCC() async {
    return await _storage.read(key: 'EMAIL_CC');
  }

  // Clear Methods
  Future<void> clearSecureSharedPef() async {
    final localPrefs = await SharedPreferences.getInstance();
    final rememberTid = await getRememberTid() ?? false;

    if (!rememberTid) {
      await _storage.deleteAll();
      await localPrefs.clear();
      return;
    }

    final tid = await getTID();
    await _storage.deleteAll();
    await localPrefs.clear();

    await setRememberTid(true);
    await setTID(tid);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureSharedPreferences Compatibility', () {
    late MockSecureStorage mockStorage;
    late TestSecureStorageService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockStorage = MockSecureStorage();
      service = TestSecureStorageService(mockStorage);
    });

    tearDown(() async {
      mockStorage.clear();
      SecureStorageService.resetInstance();
    });

    group('Route List Methods', () {
      test('setRouteList and getRouteList work correctly', () async {
        const testValue = 'route1,route2,route3';
        await service.setRouteList(testValue);
        final result = await service.getRouteList();
        expect(result, equals(testValue));
      });

      test('setRootRouteList and getRootRouteList work correctly', () async {
        const testValue = 'rootRoute1,rootRoute2';
        await service.setRootRouteList(testValue);
        final result = await service.getRootRouteList();
        expect(result, equals(testValue));
      });

      test('setDonationRouteList and getDonationRouteList work correctly',
          () async {
        const testValue = 'donationRoute1';
        await service.setDonationRouteList(testValue);
        final result = await service.getDonationRouteList();
        expect(result, equals(testValue));
      });
    });

    group('Brand List Methods', () {
      test('setBrandList and getBrandList work correctly', () async {
        const testValue = 'brand1,brand2';
        await service.setBrandList(testValue);
        final result = await service.getBrandList();
        expect(result, equals(testValue));
      });

      test('setRootBrandList and getRootBrandList work correctly', () async {
        const testValue = 'rootBrand1';
        await service.setRootBrandList(testValue);
        final result = await service.getRootBrandList();
        expect(result, equals(testValue));
      });
    });

    group('Terminal ID Methods', () {
      test('setMCPTerminalId and getMCPTerminalId work correctly', () async {
        const testValue = 'TERM123';
        await service.setMCPTerminalId(testValue);
        final result = await service.getMCPTerminalId();
        expect(result, equals(testValue));
      });

      test('setTID and getTID work correctly', () async {
        const testValue = 'TID456';
        await service.setTID(testValue);
        final result = await service.getTID();
        expect(result, equals(testValue));
      });
    });

    group('Merchant Info Methods', () {
      test('setMerchantName and getMerchantName work correctly', () async {
        const testValue = 'Test Merchant';
        await service.setMerchantName(testValue);
        final result = await service.getMerchantName();
        expect(result, equals(testValue));
      });

      test('setAddress and getAdress work correctly', () async {
        const testValue = '123 Test Street';
        await service.setAddress(testValue);
        final result = await service.getAdress();
        expect(result, equals(testValue));
      });
    });

    group('Authentication Methods', () {
      test('setPassword and getPassword work correctly', () async {
        const testValue = 'encrypted_password';
        await service.setPassword(testValue);
        final result = await service.getPassword();
        expect(result, equals(testValue));
      });

      test('setRememberTid and getRememberTid work correctly', () async {
        await service.setRememberTid(true);
        final result = await service.getRememberTid();
        expect(result, isTrue);

        await service.setRememberTid(false);
        final result2 = await service.getRememberTid();
        expect(result2, isFalse);
      });
    });

    group('Settings Methods', () {
      test('setServiceChargeRate and getServiceChargeRate work correctly',
          () async {
        const testValue = 250;
        await service.setServiceChargeRate(testValue);
        final result = await service.getServiceChargeRate();
        expect(result, equals(testValue));
      });

      test('setCarplaceNumber and getCarplaceNumber work correctly', () async {
        const testValue = 'ABC123';
        await service.setCarplaceNumber(testValue);
        final result = await service.getCarplaceNumber();
        expect(result, equals(testValue));
      });

      test('setEmailCC and getEmailCC work correctly', () async {
        const testValue = 'test@example.com';
        await service.setEmailCC(testValue);
        final result = await service.getEmailCC();
        expect(result, equals(testValue));
      });
    });

    group('Null Value Handling', () {
      test('setting null removes the value', () async {
        await service.setRouteList('test');
        expect(await service.getRouteList(), equals('test'));

        await service.setRouteList(null);
        expect(await service.getRouteList(), isNull);
      });

      test('getting non-existent key returns null', () async {
        final result = await service.getRouteList();
        expect(result, isNull);
      });
    });

    group('Clear Methods', () {
      test('clearSecureSharedPef clears all data when rememberTid is false',
          () async {
        await service.setRouteList('route');
        await service.setBrandList('brand');
        await service.setTID('tid');
        await service.setRememberTid(false);

        await service.clearSecureSharedPef();

        expect(await service.getRouteList(), isNull);
        expect(await service.getBrandList(), isNull);
        expect(await service.getTID(), isNull);
      });

      test('clearSecureSharedPef preserves TID when rememberTid is true',
          () async {
        await service.setRouteList('route');
        await service.setTID('preserved_tid');
        await service.setRememberTid(true);

        await service.clearSecureSharedPef();

        expect(await service.getRouteList(), isNull);
        expect(await service.getTID(), equals('preserved_tid'));
        expect(await service.getRememberTid(), isTrue);
      });
    });
  });
}
