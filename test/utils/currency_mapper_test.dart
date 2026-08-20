import 'package:flutter_test/flutter_test.dart';
import 'package:app/shared/utils/currency_mapper.dart';

/// **Feature: multi-currency-selector, Property 2: Default currency mapping consistency**
/// **Validates: Requirements 1.2, 1.3, 5.1, 5.2**
///
/// For any country code and supported currencies list, the getDefaultCurrency function
/// SHALL return a currency that is either:
/// - The mapped currency for that country code (if present in supportedCurrencies), OR
/// - The first currency in supportedCurrencies (if mapped currency is not available)
void main() {
  /// **Feature: country-enum-support, Task 2.2: CurrencyMapper Bhutan mapping tests**
  /// **Validates: Requirements 3.1, 3.2, 3.3**
  group('CurrencyMapper - Bhutan (BT → BTN) Mapping', () {
    test('BT should map to BTN - Requirement 3.1, 3.2', () {
      // Requirement 3.1: THE CurrencyMapper SHALL include the mapping BT → BTN
      // Requirement 3.2: WHEN a Bhutan country code (BT) is provided, THE CurrencyMapper SHALL return BTN
      final result = CurrencyMapper.getDefaultCurrency(
        'BT',
        ['BTN', 'INR', 'USD'],
      );
      expect(result, equals('BTN'));
    });

    test('BT mapping should work with lowercase country code', () {
      final result = CurrencyMapper.getDefaultCurrency(
        'bt', // lowercase
        ['BTN', 'INR', 'USD'],
      );
      expect(result, equals('BTN'));
    });

    test('BT mapping should work with mixed case country code', () {
      final result = CurrencyMapper.getDefaultCurrency(
        'Bt', // mixed case
        ['BTN', 'INR', 'USD'],
      );
      expect(result, equals('BTN'));
    });

    test('BT should fallback to first currency when BTN not in supported list',
        () {
      final result = CurrencyMapper.getDefaultCurrency(
        'BT',
        ['INR', 'USD', 'SGD'], // BTN not in list
      );
      expect(result, equals('INR'));
    });
  });

  /// **Validates: Requirement 3.3**
  /// THE CurrencyMapper SHALL maintain all existing country-to-currency mappings
  group('CurrencyMapper - Existing Mappings Preserved (Requirement 3.3)', () {
    test('SG should still map to SGD - existing mapping preserved', () {
      final result = CurrencyMapper.getDefaultCurrency(
        'SG',
        ['SGD', 'MYR', 'USD'],
      );
      expect(result, equals('SGD'));
    });

    test('MY should still map to MYR - existing mapping preserved', () {
      final result = CurrencyMapper.getDefaultCurrency(
        'MY',
        ['SGD', 'MYR', 'USD'],
      );
      expect(result, equals('MYR'));
    });

    test('TH should still map to THB - existing mapping preserved', () {
      final result = CurrencyMapper.getDefaultCurrency(
        'TH',
        ['SGD', 'THB', 'USD'],
      );
      expect(result, equals('THB'));
    });

    test('countryToCurrency map should contain BT → BTN entry', () {
      // Direct verification that the mapping exists in the static map
      expect(CurrencyMapper.countryToCurrency['BT'], equals('BTN'));
    });

    test('countryToCurrency map should preserve SG → SGD entry', () {
      expect(CurrencyMapper.countryToCurrency['SG'], equals('SGD'));
    });

    test('countryToCurrency map should preserve MY → MYR entry', () {
      expect(CurrencyMapper.countryToCurrency['MY'], equals('MYR'));
    });

    test('countryToCurrency map should preserve TH → THB entry', () {
      expect(CurrencyMapper.countryToCurrency['TH'], equals('THB'));
    });
  });

  group('CurrencyMapper - Default Currency Mapping Consistency', () {
    group('Known country code mappings', () {
      test('SG should map to SGD when SGD is in supported list', () {
        final result = CurrencyMapper.getDefaultCurrency(
          'SG',
          ['SGD', 'MYR', 'USD'],
        );
        expect(result, equals('SGD'));
      });

      test('MY should map to MYR when MYR is in supported list', () {
        final result = CurrencyMapper.getDefaultCurrency(
          'MY',
          ['SGD', 'MYR', 'USD'],
        );
        expect(result, equals('MYR'));
      });

      test('TH should map to THB when THB is in supported list', () {
        final result = CurrencyMapper.getDefaultCurrency(
          'TH',
          ['SGD', 'THB', 'USD'],
        );
        expect(result, equals('THB'));
      });

      test('ID should map to IDR when IDR is in supported list', () {
        final result = CurrencyMapper.getDefaultCurrency(
          'ID',
          ['IDR', 'SGD', 'USD'],
        );
        expect(result, equals('IDR'));
      });

      test('HK should map to HKD when HKD is in supported list', () {
        final result = CurrencyMapper.getDefaultCurrency(
          'HK',
          ['HKD', 'CNY', 'USD'],
        );
        expect(result, equals('HKD'));
      });

      test('CN should map to CNY when CNY is in supported list', () {
        final result = CurrencyMapper.getDefaultCurrency(
          'CN',
          ['CNY', 'HKD', 'USD'],
        );
        expect(result, equals('CNY'));
      });
    });

    group('Fallback behavior', () {
      test('should return first currency when mapped currency not in list', () {
        // SG maps to SGD, but SGD is not in the list
        final result = CurrencyMapper.getDefaultCurrency(
          'SG',
          ['MYR', 'THB', 'USD'],
        );
        expect(result, equals('MYR'));
      });

      test('should return first currency for unknown country code', () {
        final result = CurrencyMapper.getDefaultCurrency(
          'XX', // Unknown country code
          ['SGD', 'MYR', 'USD'],
        );
        expect(result, equals('SGD'));
      });

      test('should return first currency when country code is null', () {
        final result = CurrencyMapper.getDefaultCurrency(
          null,
          ['MYR', 'SGD', 'USD'],
        );
        expect(result, equals('MYR'));
      });

      test('should return first currency when country code is empty', () {
        final result = CurrencyMapper.getDefaultCurrency(
          '',
          ['THB', 'SGD', 'USD'],
        );
        expect(result, equals('THB'));
      });
    });

    group('Edge cases', () {
      test('should return empty string for empty supported currencies list',
          () {
        final result = CurrencyMapper.getDefaultCurrency(
          'SG',
          [],
        );
        expect(result, equals(''));
      });

      test('should handle single currency in list', () {
        final result = CurrencyMapper.getDefaultCurrency(
          'SG',
          ['USD'],
        );
        expect(result, equals('USD'));
      });

      test('should handle lowercase country code', () {
        final result = CurrencyMapper.getDefaultCurrency(
          'sg', // lowercase
          ['SGD', 'MYR', 'USD'],
        );
        expect(result, equals('SGD'));
      });

      test('should handle mixed case country code', () {
        final result = CurrencyMapper.getDefaultCurrency(
          'Sg', // mixed case
          ['SGD', 'MYR', 'USD'],
        );
        expect(result, equals('SGD'));
      });
    });

    group('Property: Result always in supported list or empty', () {
      test('result should always be in supported list when list is non-empty',
          () {
        final testCases = [
          {
            'country': 'SG',
            'currencies': ['SGD', 'MYR']
          },
          {
            'country': 'MY',
            'currencies': ['USD', 'EUR']
          },
          {
            'country': 'XX',
            'currencies': ['THB']
          },
          {
            'country': null,
            'currencies': ['IDR', 'PHP']
          },
        ];

        for (final testCase in testCases) {
          final currencies = testCase['currencies'] as List<String>;
          final result = CurrencyMapper.getDefaultCurrency(
            testCase['country'] as String?,
            currencies,
          );
          expect(
            currencies.contains(result),
            isTrue,
            reason: 'Result "$result" should be in $currencies',
          );
        }
      });
    });
  });
}
