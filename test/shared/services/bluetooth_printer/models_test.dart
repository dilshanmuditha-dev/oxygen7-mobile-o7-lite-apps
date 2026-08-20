import 'package:flutter_test/flutter_test.dart';
import 'package:app/shared/services/bluetooth_printer/models.dart';

void main() {
  group('BluetoothPrinterStatus', () {
    test('has all expected values', () {
      expect(BluetoothPrinterStatus.values, hasLength(5));
      expect(BluetoothPrinterStatus.values,
          contains(BluetoothPrinterStatus.connected));
      expect(BluetoothPrinterStatus.values,
          contains(BluetoothPrinterStatus.disconnected));
      expect(BluetoothPrinterStatus.values,
          contains(BluetoothPrinterStatus.connecting));
      expect(BluetoothPrinterStatus.values,
          contains(BluetoothPrinterStatus.scanning));
      expect(BluetoothPrinterStatus.values,
          contains(BluetoothPrinterStatus.error));
    });
  });

  group('PairedPrinterInfo', () {
    test('creates instance with required fields', () {
      final printer = PairedPrinterInfo(
        name: 'Test Printer',
        macAddress: 'AA:BB:CC:DD:EE:FF',
      );

      expect(printer.name, 'Test Printer');
      expect(printer.macAddress, 'AA:BB:CC:DD:EE:FF');
    });

    test('toJson returns correct map', () {
      final printer = PairedPrinterInfo(
        name: 'My Printer',
        macAddress: '11:22:33:44:55:66',
      );

      final json = printer.toJson();

      expect(json, {
        'name': 'My Printer',
        'macAddress': '11:22:33:44:55:66',
      });
    });

    test('fromJson creates correct instance', () {
      final json = {
        'name': 'Office Printer',
        'macAddress': 'FF:EE:DD:CC:BB:AA',
      };

      final printer = PairedPrinterInfo.fromJson(json);

      expect(printer.name, 'Office Printer');
      expect(printer.macAddress, 'FF:EE:DD:CC:BB:AA');
    });

    test('toJson/fromJson round-trip preserves data', () {
      final original = PairedPrinterInfo(
        name: 'Round Trip Printer',
        macAddress: 'AB:CD:EF:01:23:45',
      );

      final restored = PairedPrinterInfo.fromJson(original.toJson());

      expect(restored, equals(original));
    });

    test('equality works for same values', () {
      final a = PairedPrinterInfo(name: 'P1', macAddress: 'AA:BB:CC:DD:EE:FF');
      final b = PairedPrinterInfo(name: 'P1', macAddress: 'AA:BB:CC:DD:EE:FF');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality for different values', () {
      final a = PairedPrinterInfo(name: 'P1', macAddress: 'AA:BB:CC:DD:EE:FF');
      final b = PairedPrinterInfo(name: 'P2', macAddress: 'AA:BB:CC:DD:EE:FF');

      expect(a, isNot(equals(b)));
    });

    test('toString returns readable representation', () {
      final printer = PairedPrinterInfo(
        name: 'Test',
        macAddress: '00:11:22:33:44:55',
      );

      expect(
        printer.toString(),
        'PairedPrinterInfo(name: Test, macAddress: 00:11:22:33:44:55)',
      );
    });
  });
}
