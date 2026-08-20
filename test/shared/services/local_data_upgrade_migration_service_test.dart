import 'package:app/shared/services/local_data_upgrade_migration_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalDataUpgradeMigrationService decision', () {
    const sunmiRule = LocalDataWipeRule(
      deviceType: PosDeviceType.sunmi,
      encryptedBaselineVersionCode: 78,
      markerKey: 'sunmi_done',
    );

    test('fresh install at or above baseline is marked without wiping', () {
      final decision = LocalDataUpgradeMigrationService.decide(
        rule: sunmiRule,
        currentVersionCode: 80,
        lastSeenVersionCode: null,
        migrationDone: false,
        legacyLocalDataExists: false,
        secureStorageMigrationComplete: false,
      );

      expect(decision, LocalDataUpgradeDecision.markHandledOnly);
    });

    test('Sunmi upgrade from stable 77 to encrypted baseline wipes once', () {
      final decision = LocalDataUpgradeMigrationService.decide(
        rule: sunmiRule,
        currentVersionCode: 80,
        lastSeenVersionCode: null,
        migrationDone: false,
        legacyLocalDataExists: true,
        secureStorageMigrationComplete: false,
      );

      expect(decision, LocalDataUpgradeDecision.wipeAndMarkHandled);
    });

    test('already handled Sunmi migration does not wipe again', () {
      final decision = LocalDataUpgradeMigrationService.decide(
        rule: sunmiRule,
        currentVersionCode: 80,
        lastSeenVersionCode: 80,
        migrationDone: true,
        legacyLocalDataExists: true,
        secureStorageMigrationComplete: false,
      );

      expect(decision, LocalDataUpgradeDecision.skip);
    });

    test(
        'future Sunmi release after encrypted storage is marked without wiping',
        () {
      final decision = LocalDataUpgradeMigrationService.decide(
        rule: sunmiRule,
        currentVersionCode: 81,
        lastSeenVersionCode: null,
        migrationDone: false,
        legacyLocalDataExists: true,
        secureStorageMigrationComplete: true,
      );

      expect(decision, LocalDataUpgradeDecision.markHandledOnly);
    });

    test('explicit last seen version crossing baseline wipes', () {
      final decision = LocalDataUpgradeMigrationService.decide(
        rule: sunmiRule,
        currentVersionCode: 80,
        lastSeenVersionCode: 77,
        migrationDone: false,
        legacyLocalDataExists: false,
        secureStorageMigrationComplete: false,
      );

      expect(decision, LocalDataUpgradeDecision.wipeAndMarkHandled);
    });

    test('device with disabled rule is skipped', () {
      final decision = LocalDataUpgradeMigrationService.decide(
        rule: null,
        currentVersionCode: 80,
        lastSeenVersionCode: null,
        migrationDone: false,
        legacyLocalDataExists: true,
        secureStorageMigrationComplete: false,
      );

      expect(decision, LocalDataUpgradeDecision.skip);
    });

    test('confirmed POS rules use their first encrypted baseline versions', () {
      expect(
        LocalDataUpgradeMigrationService
            .rules[PosDeviceType.sunmi]?.encryptedBaselineVersionCode,
        78,
      );
      expect(
        LocalDataUpgradeMigrationService
            .rules[PosDeviceType.landi]?.encryptedBaselineVersionCode,
        78,
      );
      expect(
        LocalDataUpgradeMigrationService
            .rules[PosDeviceType.castle]?.encryptedBaselineVersionCode,
        60,
      );
      expect(
        LocalDataUpgradeMigrationService
            .rules[PosDeviceType.wizarpos]?.encryptedBaselineVersionCode,
        59,
      );
    });
  });

  group('PosDeviceTypeDetector', () {
    test('detects known POS families from brand and model', () {
      expect(
        PosDeviceTypeDetector.fromBrandModel(brand: 'SUNMI', model: 'V2s'),
        PosDeviceType.sunmi,
      );
      expect(
        PosDeviceTypeDetector.fromBrandModel(brand: 'LANDI', model: 'M20'),
        PosDeviceType.landi,
      );
      expect(
        PosDeviceTypeDetector.fromBrandModel(brand: 'Castles', model: 'S1F2'),
        PosDeviceType.castle,
      );
      expect(
        PosDeviceTypeDetector.fromBrandModel(
          brand: 'Generic',
          model: 'WizarPOS Q2',
        ),
        PosDeviceType.wizarpos,
      );
      expect(
        PosDeviceTypeDetector.fromBrandModel(brand: 'Centerm', model: 'K9'),
        PosDeviceType.coherent,
      );
    });

    test('falls back to mobile for unknown phones', () {
      expect(
        PosDeviceTypeDetector.fromBrandModel(brand: 'Samsung', model: 'SM-G99'),
        PosDeviceType.mobile,
      );
    });
  });
}
