import 'package:flutter_test/flutter_test.dart';
import 'package:app/shared/constants/country.dart';

/// Unit tests for Country enum
/// **Validates: Requirements 1.1-1.6, 2.1-2.5**
///
/// Tests cover:
/// - All enum values exist with correct metadata
/// - Conversion methods with valid inputs
/// - Case-insensitivity for alpha code conversions
/// - Null/empty/invalid inputs return null
///
/// Property-Based Tests:
/// - Property 1: Country Enum Metadata Completeness
void main() {
  group('Country Enum - Enum Values Existence', () {
    test('should have exactly 4 country values', () {
      expect(Country.values.length, equals(4));
    });

    test('should have singapore enum value', () {
      expect(Country.values.contains(Country.singapore), isTrue);
    });

    test('should have malaysia enum value', () {
      expect(Country.values.contains(Country.malaysia), isTrue);
    });

    test('should have thailand enum value', () {
      expect(Country.values.contains(Country.thailand), isTrue);
    });

    test('should have bhutan enum value', () {
      expect(Country.values.contains(Country.bhutan), isTrue);
    });
  });

  group('Country Enum - Singapore Metadata', () {
    test('singapore should have alpha2Code SG', () {
      expect(Country.singapore.alpha2Code, equals('SG'));
    });

    test('singapore should have alpha3Code SGP', () {
      expect(Country.singapore.alpha3Code, equals('SGP'));
    });

    test('singapore should have currencyCode SGD', () {
      expect(Country.singapore.currencyCode, equals('SGD'));
    });

    test('singapore should have numericCode 702', () {
      expect(Country.singapore.numericCode, equals('702'));
    });

    test('singapore should have displayName Singapore', () {
      expect(Country.singapore.displayName, equals('Singapore'));
    });
  });

  group('Country Enum - Malaysia Metadata', () {
    test('malaysia should have alpha2Code MY', () {
      expect(Country.malaysia.alpha2Code, equals('MY'));
    });

    test('malaysia should have alpha3Code MYS', () {
      expect(Country.malaysia.alpha3Code, equals('MYS'));
    });

    test('malaysia should have currencyCode MYR', () {
      expect(Country.malaysia.currencyCode, equals('MYR'));
    });

    test('malaysia should have numericCode 458', () {
      expect(Country.malaysia.numericCode, equals('458'));
    });

    test('malaysia should have displayName Malaysia', () {
      expect(Country.malaysia.displayName, equals('Malaysia'));
    });
  });

  group('Country Enum - Thailand Metadata', () {
    test('thailand should have alpha2Code TH', () {
      expect(Country.thailand.alpha2Code, equals('TH'));
    });

    test('thailand should have alpha3Code THA', () {
      expect(Country.thailand.alpha3Code, equals('THA'));
    });

    test('thailand should have currencyCode THB', () {
      expect(Country.thailand.currencyCode, equals('THB'));
    });

    test('thailand should have numericCode 764', () {
      expect(Country.thailand.numericCode, equals('764'));
    });

    test('thailand should have displayName Thailand', () {
      expect(Country.thailand.displayName, equals('Thailand'));
    });
  });

  group('Country Enum - Bhutan Metadata', () {
    test('bhutan should have alpha2Code BT', () {
      expect(Country.bhutan.alpha2Code, equals('BT'));
    });

    test('bhutan should have alpha3Code BTN', () {
      expect(Country.bhutan.alpha3Code, equals('BTN'));
    });

    test('bhutan should have currencyCode BTN', () {
      expect(Country.bhutan.currencyCode, equals('BTN'));
    });

    test('bhutan should have numericCode 064', () {
      expect(Country.bhutan.numericCode, equals('064'));
    });

    test('bhutan should have displayName Bhutan', () {
      expect(Country.bhutan.displayName, equals('Bhutan'));
    });
  });

  group('Country Enum - fromAlpha3 with valid inputs', () {
    test('SGP should return singapore', () {
      expect(Country.fromAlpha3('SGP'), equals(Country.singapore));
    });

    test('MYS should return malaysia', () {
      expect(Country.fromAlpha3('MYS'), equals(Country.malaysia));
    });

    test('THA should return thailand', () {
      expect(Country.fromAlpha3('THA'), equals(Country.thailand));
    });

    test('BTN should return bhutan', () {
      expect(Country.fromAlpha3('BTN'), equals(Country.bhutan));
    });
  });

  group('Country Enum - fromAlpha2 with valid inputs', () {
    test('SG should return singapore', () {
      expect(Country.fromAlpha2('SG'), equals(Country.singapore));
    });

    test('MY should return malaysia', () {
      expect(Country.fromAlpha2('MY'), equals(Country.malaysia));
    });

    test('TH should return thailand', () {
      expect(Country.fromAlpha2('TH'), equals(Country.thailand));
    });

    test('BT should return bhutan', () {
      expect(Country.fromAlpha2('BT'), equals(Country.bhutan));
    });
  });

  group('Country Enum - fromNumeric with valid inputs', () {
    test('702 should return singapore', () {
      expect(Country.fromNumeric('702'), equals(Country.singapore));
    });

    test('458 should return malaysia', () {
      expect(Country.fromNumeric('458'), equals(Country.malaysia));
    });

    test('764 should return thailand', () {
      expect(Country.fromNumeric('764'), equals(Country.thailand));
    });

    test('064 should return bhutan', () {
      expect(Country.fromNumeric('064'), equals(Country.bhutan));
    });
  });

  group('Country Enum - fromAlpha3 case-insensitivity', () {
    test('lowercase sgp should return singapore', () {
      expect(Country.fromAlpha3('sgp'), equals(Country.singapore));
    });

    test('mixed case Sgp should return singapore', () {
      expect(Country.fromAlpha3('Sgp'), equals(Country.singapore));
    });

    test('mixed case sGp should return singapore', () {
      expect(Country.fromAlpha3('sGp'), equals(Country.singapore));
    });

    test('mixed case SGp should return singapore', () {
      expect(Country.fromAlpha3('SGp'), equals(Country.singapore));
    });

    test('lowercase mys should return malaysia', () {
      expect(Country.fromAlpha3('mys'), equals(Country.malaysia));
    });

    test('mixed case Mys should return malaysia', () {
      expect(Country.fromAlpha3('Mys'), equals(Country.malaysia));
    });

    test('lowercase tha should return thailand', () {
      expect(Country.fromAlpha3('tha'), equals(Country.thailand));
    });

    test('mixed case ThA should return thailand', () {
      expect(Country.fromAlpha3('ThA'), equals(Country.thailand));
    });

    test('lowercase btn should return bhutan', () {
      expect(Country.fromAlpha3('btn'), equals(Country.bhutan));
    });

    test('mixed case Btn should return bhutan', () {
      expect(Country.fromAlpha3('Btn'), equals(Country.bhutan));
    });
  });

  group('Country Enum - fromAlpha2 case-insensitivity', () {
    test('lowercase sg should return singapore', () {
      expect(Country.fromAlpha2('sg'), equals(Country.singapore));
    });

    test('mixed case Sg should return singapore', () {
      expect(Country.fromAlpha2('Sg'), equals(Country.singapore));
    });

    test('mixed case sG should return singapore', () {
      expect(Country.fromAlpha2('sG'), equals(Country.singapore));
    });

    test('lowercase my should return malaysia', () {
      expect(Country.fromAlpha2('my'), equals(Country.malaysia));
    });

    test('mixed case My should return malaysia', () {
      expect(Country.fromAlpha2('My'), equals(Country.malaysia));
    });

    test('lowercase th should return thailand', () {
      expect(Country.fromAlpha2('th'), equals(Country.thailand));
    });

    test('mixed case Th should return thailand', () {
      expect(Country.fromAlpha2('Th'), equals(Country.thailand));
    });

    test('lowercase bt should return bhutan', () {
      expect(Country.fromAlpha2('bt'), equals(Country.bhutan));
    });

    test('mixed case Bt should return bhutan', () {
      expect(Country.fromAlpha2('Bt'), equals(Country.bhutan));
    });
  });

  group('Country Enum - fromAlpha3 null/empty/invalid inputs', () {
    test('null input should return null', () {
      expect(Country.fromAlpha3(null), isNull);
    });

    test('empty string should return null', () {
      expect(Country.fromAlpha3(''), isNull);
    });

    test('invalid code XXX should return null', () {
      expect(Country.fromAlpha3('XXX'), isNull);
    });

    test('invalid code USA should return null', () {
      expect(Country.fromAlpha3('USA'), isNull);
    });

    test('invalid code ABC should return null', () {
      expect(Country.fromAlpha3('ABC'), isNull);
    });

    test('whitespace only should return null', () {
      expect(Country.fromAlpha3('   '), isNull);
    });

    test('partial code SG should return null (not alpha3)', () {
      expect(Country.fromAlpha3('SG'), isNull);
    });
  });

  group('Country Enum - fromAlpha2 null/empty/invalid inputs', () {
    test('null input should return null', () {
      expect(Country.fromAlpha2(null), isNull);
    });

    test('empty string should return null', () {
      expect(Country.fromAlpha2(''), isNull);
    });

    test('invalid code ZZ should return null', () {
      expect(Country.fromAlpha2('ZZ'), isNull);
    });

    test('invalid code US should return null', () {
      expect(Country.fromAlpha2('US'), isNull);
    });

    test('invalid code XX should return null', () {
      expect(Country.fromAlpha2('XX'), isNull);
    });

    test('whitespace only should return null', () {
      expect(Country.fromAlpha2('   '), isNull);
    });

    test('alpha3 code SGP should return null (not alpha2)', () {
      expect(Country.fromAlpha2('SGP'), isNull);
    });
  });

  group('Country Enum - fromNumeric null/empty/invalid inputs', () {
    test('null input should return null', () {
      expect(Country.fromNumeric(null), isNull);
    });

    test('empty string should return null', () {
      expect(Country.fromNumeric(''), isNull);
    });

    test('invalid code 999 should return null', () {
      expect(Country.fromNumeric('999'), isNull);
    });

    test('invalid code 000 should return null', () {
      expect(Country.fromNumeric('000'), isNull);
    });

    test('invalid code 123 should return null', () {
      expect(Country.fromNumeric('123'), isNull);
    });

    test('whitespace only should return null', () {
      expect(Country.fromNumeric('   '), isNull);
    });

    test('alpha code SGP should return null (not numeric)', () {
      expect(Country.fromNumeric('SGP'), isNull);
    });

    test('numeric without leading zero 64 should return null (bhutan is 064)',
        () {
      expect(Country.fromNumeric('64'), isNull);
    });
  });

  group('Country Enum - Metadata format validation', () {
    test('all alpha2Codes should be exactly 2 characters', () {
      for (final country in Country.values) {
        expect(
          country.alpha2Code.length,
          equals(2),
          reason: '${country.name} alpha2Code should be 2 characters',
        );
      }
    });

    test('all alpha3Codes should be exactly 3 characters', () {
      for (final country in Country.values) {
        expect(
          country.alpha3Code.length,
          equals(3),
          reason: '${country.name} alpha3Code should be 3 characters',
        );
      }
    });

    test('all currencyCodes should be exactly 3 characters', () {
      for (final country in Country.values) {
        expect(
          country.currencyCode.length,
          equals(3),
          reason: '${country.name} currencyCode should be 3 characters',
        );
      }
    });

    test('all numericCodes should be exactly 3 characters', () {
      for (final country in Country.values) {
        expect(
          country.numericCode.length,
          equals(3),
          reason: '${country.name} numericCode should be 3 characters',
        );
      }
    });

    test('all displayNames should be non-empty', () {
      for (final country in Country.values) {
        expect(
          country.displayName.isNotEmpty,
          isTrue,
          reason: '${country.name} displayName should not be empty',
        );
      }
    });

    test('all alpha2Codes should be uppercase', () {
      for (final country in Country.values) {
        expect(
          country.alpha2Code,
          equals(country.alpha2Code.toUpperCase()),
          reason: '${country.name} alpha2Code should be uppercase',
        );
      }
    });

    test('all alpha3Codes should be uppercase', () {
      for (final country in Country.values) {
        expect(
          country.alpha3Code,
          equals(country.alpha3Code.toUpperCase()),
          reason: '${country.name} alpha3Code should be uppercase',
        );
      }
    });

    test('all currencyCodes should be uppercase', () {
      for (final country in Country.values) {
        expect(
          country.currencyCode,
          equals(country.currencyCode.toUpperCase()),
          reason: '${country.name} currencyCode should be uppercase',
        );
      }
    });
  });

  group('Country Enum - Uniqueness validation', () {
    test('all alpha2Codes should be unique', () {
      final codes = Country.values.map((c) => c.alpha2Code).toList();
      expect(codes.toSet().length, equals(codes.length));
    });

    test('all alpha3Codes should be unique', () {
      final codes = Country.values.map((c) => c.alpha3Code).toList();
      expect(codes.toSet().length, equals(codes.length));
    });

    test('all numericCodes should be unique', () {
      final codes = Country.values.map((c) => c.numericCode).toList();
      expect(codes.toSet().length, equals(codes.length));
    });
  });

  // ============================================================================
  // PROPERTY-BASED TESTS
  // ============================================================================
  // Feature: country-enum-support, Property 1: Country Enum Metadata Completeness
  //
  // Property-based testing approach: Since there are only 4 enum values,
  // we use exhaustive testing (testing all values) which is more thorough
  // than random sampling. Each property is verified across all Country values
  // with multiple iterations to ensure consistency.
  // ============================================================================

  group('Property-Based Tests - Property 1: Country Enum Metadata Completeness',
      () {
    /// **Validates: Requirements 1.2, 1.3, 1.4, 1.5, 1.6**
    ///
    /// Property 1: Country Enum Metadata Completeness
    /// *For any* Country enum value, all metadata fields (alpha2Code, alpha3Code,
    /// currencyCode, numericCode, displayName) should be non-empty strings with
    /// correct format lengths (alpha2Code: 2 chars, alpha3Code: 3 chars,
    /// currencyCode: 3 chars, numericCode: 3 digits).
    ///
    /// Test approach: Exhaustive testing over all 4 enum values, repeated 100+
    /// times to satisfy minimum iteration requirement.

    test(
        'Property 1.1: alpha2Code is non-empty and exactly 2 characters for all Country values',
        () {
      // Exhaustive test: iterate over all Country values
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Property: alpha2Code must be non-empty
          expect(
            country.alpha2Code.isNotEmpty,
            isTrue,
            reason:
                'Iteration $iteration: ${country.name}.alpha2Code should not be empty',
          );

          // Property: alpha2Code must be exactly 2 characters
          expect(
            country.alpha2Code.length,
            equals(2),
            reason:
                'Iteration $iteration: ${country.name}.alpha2Code should be exactly 2 characters, got "${country.alpha2Code}"',
          );
        }
      }
    });

    test(
        'Property 1.2: alpha3Code is non-empty and exactly 3 characters for all Country values',
        () {
      // Exhaustive test: iterate over all Country values
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Property: alpha3Code must be non-empty
          expect(
            country.alpha3Code.isNotEmpty,
            isTrue,
            reason:
                'Iteration $iteration: ${country.name}.alpha3Code should not be empty',
          );

          // Property: alpha3Code must be exactly 3 characters
          expect(
            country.alpha3Code.length,
            equals(3),
            reason:
                'Iteration $iteration: ${country.name}.alpha3Code should be exactly 3 characters, got "${country.alpha3Code}"',
          );
        }
      }
    });

    test(
        'Property 1.3: currencyCode is non-empty and exactly 3 characters for all Country values',
        () {
      // Exhaustive test: iterate over all Country values
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Property: currencyCode must be non-empty
          expect(
            country.currencyCode.isNotEmpty,
            isTrue,
            reason:
                'Iteration $iteration: ${country.name}.currencyCode should not be empty',
          );

          // Property: currencyCode must be exactly 3 characters
          expect(
            country.currencyCode.length,
            equals(3),
            reason:
                'Iteration $iteration: ${country.name}.currencyCode should be exactly 3 characters, got "${country.currencyCode}"',
          );
        }
      }
    });

    test(
        'Property 1.4: numericCode is non-empty and exactly 3 digit characters for all Country values',
        () {
      // Regular expression for exactly 3 digits
      final numericPattern = RegExp(r'^\d{3}$');

      // Exhaustive test: iterate over all Country values
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Property: numericCode must be non-empty
          expect(
            country.numericCode.isNotEmpty,
            isTrue,
            reason:
                'Iteration $iteration: ${country.name}.numericCode should not be empty',
          );

          // Property: numericCode must be exactly 3 characters
          expect(
            country.numericCode.length,
            equals(3),
            reason:
                'Iteration $iteration: ${country.name}.numericCode should be exactly 3 characters, got "${country.numericCode}"',
          );

          // Property: numericCode must contain only digits
          expect(
            numericPattern.hasMatch(country.numericCode),
            isTrue,
            reason:
                'Iteration $iteration: ${country.name}.numericCode should be exactly 3 digits, got "${country.numericCode}"',
          );
        }
      }
    });

    test('Property 1.5: displayName is non-empty for all Country values', () {
      // Exhaustive test: iterate over all Country values
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Property: displayName must be non-empty
          expect(
            country.displayName.isNotEmpty,
            isTrue,
            reason:
                'Iteration $iteration: ${country.name}.displayName should not be empty',
          );

          // Property: displayName should not be just whitespace
          expect(
            country.displayName.trim().isNotEmpty,
            isTrue,
            reason:
                'Iteration $iteration: ${country.name}.displayName should not be only whitespace',
          );
        }
      }
    });

    test(
        'Property 1.6: All metadata fields are complete and valid for every Country value (combined property)',
        () {
      // Combined property test: verifies all metadata completeness in one pass
      // This is the comprehensive property that validates Requirements 1.2-1.6
      final numericPattern = RegExp(r'^\d{3}$');

      // Exhaustive test: iterate over all Country values
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Combined property assertion: all fields must be valid
          final isAlpha2Valid =
              country.alpha2Code.isNotEmpty && country.alpha2Code.length == 2;
          final isAlpha3Valid =
              country.alpha3Code.isNotEmpty && country.alpha3Code.length == 3;
          final isCurrencyValid = country.currencyCode.isNotEmpty &&
              country.currencyCode.length == 3;
          final isNumericValid = country.numericCode.isNotEmpty &&
              country.numericCode.length == 3 &&
              numericPattern.hasMatch(country.numericCode);
          final isDisplayNameValid = country.displayName.isNotEmpty &&
              country.displayName.trim().isNotEmpty;

          final allFieldsValid = isAlpha2Valid &&
              isAlpha3Valid &&
              isCurrencyValid &&
              isNumericValid &&
              isDisplayNameValid;

          expect(
            allFieldsValid,
            isTrue,
            reason: '''
Iteration $iteration: ${country.name} metadata completeness check failed:
  - alpha2Code "${country.alpha2Code}": ${isAlpha2Valid ? 'VALID' : 'INVALID (must be non-empty, 2 chars)'}
  - alpha3Code "${country.alpha3Code}": ${isAlpha3Valid ? 'VALID' : 'INVALID (must be non-empty, 3 chars)'}
  - currencyCode "${country.currencyCode}": ${isCurrencyValid ? 'VALID' : 'INVALID (must be non-empty, 3 chars)'}
  - numericCode "${country.numericCode}": ${isNumericValid ? 'VALID' : 'INVALID (must be non-empty, 3 digits)'}
  - displayName "${country.displayName}": ${isDisplayNameValid ? 'VALID' : 'INVALID (must be non-empty)'}
''',
          );
        }
      }
    });
  });

  // ============================================================================
  // PROPERTY-BASED TESTS - Property 2
  // ============================================================================
  // Feature: country-enum-support, Property 2: Round-Trip Conversion Consistency
  //
  // Property-based testing approach: Since there are only 4 enum values,
  // we use exhaustive testing (testing all values) which is more thorough
  // than random sampling. Each property is verified across all Country values
  // with multiple iterations to ensure consistency.
  // ============================================================================

  group('Property-Based Tests - Property 2: Round-Trip Conversion Consistency',
      () {
    /// **Validates: Requirements 2.1, 2.2, 2.3**
    ///
    /// Property 2: Round-Trip Conversion Consistency
    /// *For any* Country enum value, converting to any code format (alpha2,
    /// alpha3, numeric) and back using the corresponding fromX method should
    /// return the same Country enum value.
    ///
    /// Test approach: Exhaustive testing over all 4 enum values, repeated 100+
    /// times to satisfy minimum iteration requirement.

    test(
        'Property 2.1: Round-trip via alpha2Code returns same Country for all values',
        () {
      // Exhaustive test: iterate over all Country values
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Property: Country.fromAlpha2(country.alpha2Code) == country
          final alpha2Code = country.alpha2Code;
          final roundTrippedCountry = Country.fromAlpha2(alpha2Code);

          expect(
            roundTrippedCountry,
            equals(country),
            reason:
                'Iteration $iteration: Round-trip via alpha2Code failed for ${country.name}. '
                'Expected ${country.name}, got ${roundTrippedCountry?.name ?? 'null'}. '
                'alpha2Code: "$alpha2Code"',
          );
        }
      }
    });

    test(
        'Property 2.2: Round-trip via alpha3Code returns same Country for all values',
        () {
      // Exhaustive test: iterate over all Country values
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Property: Country.fromAlpha3(country.alpha3Code) == country
          final alpha3Code = country.alpha3Code;
          final roundTrippedCountry = Country.fromAlpha3(alpha3Code);

          expect(
            roundTrippedCountry,
            equals(country),
            reason:
                'Iteration $iteration: Round-trip via alpha3Code failed for ${country.name}. '
                'Expected ${country.name}, got ${roundTrippedCountry?.name ?? 'null'}. '
                'alpha3Code: "$alpha3Code"',
          );
        }
      }
    });

    test(
        'Property 2.3: Round-trip via numericCode returns same Country for all values',
        () {
      // Exhaustive test: iterate over all Country values
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Property: Country.fromNumeric(country.numericCode) == country
          final numericCode = country.numericCode;
          final roundTrippedCountry = Country.fromNumeric(numericCode);

          expect(
            roundTrippedCountry,
            equals(country),
            reason:
                'Iteration $iteration: Round-trip via numericCode failed for ${country.name}. '
                'Expected ${country.name}, got ${roundTrippedCountry?.name ?? 'null'}. '
                'numericCode: "$numericCode"',
          );
        }
      }
    });

    test(
        'Property 2.4: All round-trip conversions are consistent for every Country value (combined property)',
        () {
      // Combined property test: verifies all round-trip conversions in one pass
      // This is the comprehensive property that validates Requirements 2.1, 2.2, 2.3

      // Exhaustive test: iterate over all Country values
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Test all three round-trip conversions
          final fromAlpha2 = Country.fromAlpha2(country.alpha2Code);
          final fromAlpha3 = Country.fromAlpha3(country.alpha3Code);
          final fromNumeric = Country.fromNumeric(country.numericCode);

          // Combined property assertion: all round-trips must return the original country
          final alpha2RoundTripValid = fromAlpha2 == country;
          final alpha3RoundTripValid = fromAlpha3 == country;
          final numericRoundTripValid = fromNumeric == country;

          final allRoundTripsValid = alpha2RoundTripValid &&
              alpha3RoundTripValid &&
              numericRoundTripValid;

          expect(
            allRoundTripsValid,
            isTrue,
            reason: '''
Iteration $iteration: ${country.name} round-trip conversion check failed:
  - alpha2Code "${country.alpha2Code}" → fromAlpha2 → ${fromAlpha2?.name ?? 'null'}: ${alpha2RoundTripValid ? 'VALID' : 'INVALID'}
  - alpha3Code "${country.alpha3Code}" → fromAlpha3 → ${fromAlpha3?.name ?? 'null'}: ${alpha3RoundTripValid ? 'VALID' : 'INVALID'}
  - numericCode "${country.numericCode}" → fromNumeric → ${fromNumeric?.name ?? 'null'}: ${numericRoundTripValid ? 'VALID' : 'INVALID'}
''',
          );
        }
      }
    });
  });
}
