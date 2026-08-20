import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app/app_controller.dart';
import 'package:app/shared/constants/country.dart';
import 'package:app/shared/utils/app_flavor_helper.dart';

/// Unit tests for AppController country integration
/// **Validates: Requirements 4.2, 4.3, 4.4, 4.5, 5.1-5.6**
///
/// Tests cover:
/// - currentCountry getter returns correct enum
/// - setCountryFromAlpha3 with valid codes
/// - Default to Singapore on invalid input
/// - All location helper methods
/// - Synchronization between Country enum and countryCodeAlpha string
///
/// Property-Based Tests:
/// - Property 5: Country-String Synchronization Invariant
void main() {
  late AppController appController;

  setUp(() {
    // Enable GetX test mode to avoid platform channel issues
    Get.testMode = true;

    // Create a fresh AppController instance for each test
    // Using development flavor for testing
    appController = AppController(AppFlavor.development);
  });

  tearDown(() {
    // Clean up GetX state
    Get.reset();
  });

  // ============================================================================
  // currentCountry Getter Tests
  // ============================================================================

  group('AppController - currentCountry Getter (Requirement 4.2)', () {
    test('currentCountry should default to Singapore', () {
      // Requirement 4.2: THE AppController SHALL provide a getter for the current Country_Enum value
      // Default should be Singapore as per design
      expect(appController.currentCountry, equals(Country.singapore));
    });

    test('currentCountry should return Country type', () {
      // Verify the getter returns the correct type
      expect(appController.currentCountry, isA<Country>());
    });
  });

  // ============================================================================
  // setCountryFromAlpha3 Tests - Valid Codes
  // ============================================================================

  group(
      'AppController - setCountryFromAlpha3 with valid codes (Requirement 4.4)',
      () {
    test('setCountryFromAlpha3("SGP") should set Singapore', () {
      // Requirement 4.4: WHEN the country is set from a string code, THE AppController SHALL convert it to the Country_Enum
      appController.setCountryFromAlpha3('SGP');
      expect(appController.currentCountry, equals(Country.singapore));
    });

    test('setCountryFromAlpha3("MYS") should set Malaysia', () {
      appController.setCountryFromAlpha3('MYS');
      expect(appController.currentCountry, equals(Country.malaysia));
    });

    test('setCountryFromAlpha3("THA") should set Thailand', () {
      appController.setCountryFromAlpha3('THA');
      expect(appController.currentCountry, equals(Country.thailand));
    });

    test('setCountryFromAlpha3("BTN") should set Bhutan', () {
      appController.setCountryFromAlpha3('BTN');
      expect(appController.currentCountry, equals(Country.bhutan));
    });

    test('setCountryFromAlpha3 should handle lowercase codes', () {
      appController.setCountryFromAlpha3('mys');
      expect(appController.currentCountry, equals(Country.malaysia));
    });

    test('setCountryFromAlpha3 should handle mixed case codes', () {
      appController.setCountryFromAlpha3('Tha');
      expect(appController.currentCountry, equals(Country.thailand));
    });
  });

  // ============================================================================
  // setCountryFromAlpha3 Tests - Invalid/Empty Inputs (Default to Singapore)
  // ============================================================================

  group(
      'AppController - setCountryFromAlpha3 default to Singapore (Requirement 4.5)',
      () {
    test('setCountryFromAlpha3(null) should default to Singapore', () {
      // Requirement 4.5: WHEN the country is set and no valid Country_Enum match is found, THE AppController SHALL default to SINGAPORE
      // First set to a different country to verify the default behavior
      appController.setCountryFromAlpha3('MYS');
      expect(appController.currentCountry, equals(Country.malaysia));

      // Now set with null - should default to Singapore
      appController.setCountryFromAlpha3(null);
      expect(appController.currentCountry, equals(Country.singapore));
    });

    test('setCountryFromAlpha3("") should default to Singapore', () {
      // First set to a different country
      appController.setCountryFromAlpha3('THA');
      expect(appController.currentCountry, equals(Country.thailand));

      // Now set with empty string - should default to Singapore
      appController.setCountryFromAlpha3('');
      expect(appController.currentCountry, equals(Country.singapore));
    });

    test('setCountryFromAlpha3("XXX") should default to Singapore', () {
      // First set to a different country
      appController.setCountryFromAlpha3('BTN');
      expect(appController.currentCountry, equals(Country.bhutan));

      // Now set with invalid code - should default to Singapore
      appController.setCountryFromAlpha3('XXX');
      expect(appController.currentCountry, equals(Country.singapore));
    });

    test(
        'setCountryFromAlpha3("USA") should default to Singapore (unsupported country)',
        () {
      appController.setCountryFromAlpha3('MYS');
      appController.setCountryFromAlpha3('USA');
      expect(appController.currentCountry, equals(Country.singapore));
    });

    test('setCountryFromAlpha3("   ") should default to Singapore (whitespace)',
        () {
      appController.setCountryFromAlpha3('THA');
      appController.setCountryFromAlpha3('   ');
      expect(appController.currentCountry, equals(Country.singapore));
    });
  });

  // ============================================================================
  // setCountryFromAlpha3 Tests - Synchronization with countryCodeAlpha
  // ============================================================================

  group('AppController - Country-String Synchronization (Requirement 4.6)', () {
    test('setCountryFromAlpha3 should synchronize countryCodeAlpha string', () {
      // Requirement 4.6: THE AppController SHALL synchronize the Country_Enum value with the countryCodeAlpha string value
      appController.setCountryFromAlpha3('SGP');
      expect(appController.countryCodeAlpha.value, equals('SGP'));
    });

    test('setCountryFromAlpha3("MYS") should set countryCodeAlpha to "MYS"',
        () {
      appController.setCountryFromAlpha3('MYS');
      expect(appController.countryCodeAlpha.value, equals('MYS'));
    });

    test('setCountryFromAlpha3("THA") should set countryCodeAlpha to "THA"',
        () {
      appController.setCountryFromAlpha3('THA');
      expect(appController.countryCodeAlpha.value, equals('THA'));
    });

    test('setCountryFromAlpha3("BTN") should set countryCodeAlpha to "BTN"',
        () {
      appController.setCountryFromAlpha3('BTN');
      expect(appController.countryCodeAlpha.value, equals('BTN'));
    });

    test(
        'setCountryFromAlpha3(null) should set countryCodeAlpha to "SGP" (default)',
        () {
      appController.setCountryFromAlpha3(null);
      expect(appController.countryCodeAlpha.value, equals('SGP'));
    });

    test(
        'setCountryFromAlpha3("") should set countryCodeAlpha to "SGP" (default)',
        () {
      appController.setCountryFromAlpha3('');
      expect(appController.countryCodeAlpha.value, equals('SGP'));
    });

    test(
        'setCountryFromAlpha3("XXX") should set countryCodeAlpha to "SGP" (default)',
        () {
      appController.setCountryFromAlpha3('XXX');
      expect(appController.countryCodeAlpha.value, equals('SGP'));
    });

    test('countryCodeAlpha should always match currentCountry.alpha3Code', () {
      // Test all valid countries
      for (final country in Country.values) {
        appController.setCountryFromAlpha3(country.alpha3Code);
        expect(
          appController.countryCodeAlpha.value,
          equals(appController.currentCountry.alpha3Code),
          reason:
              'countryCodeAlpha should match currentCountry.alpha3Code for ${country.name}',
        );
      }
    });
  });

  // ============================================================================
  // isSGPLocation Tests
  // ============================================================================

  group('AppController - isSGPLocation (Requirements 5.1, 5.5, 5.6)', () {
    test('isSGPLocation should return true for Singapore', () {
      // Requirement 5.1: THE AppController SHALL provide an isSGPLocation() method that returns true when current country is SINGAPORE
      appController.setCountryFromAlpha3('SGP');
      expect(appController.isSGPLocation(), isTrue);
    });

    test('isSGPLocation should return true when countryCodeAlpha is empty', () {
      // Requirement 5.5: WHEN the country is not set or empty, THE isSGPLocation() method SHALL return true (default behavior)
      // Create a new controller and don't set any country
      final newController = AppController(AppFlavor.development);
      // countryCodeAlpha defaults to empty string
      expect(newController.countryCodeAlpha.value, equals(''));
      expect(newController.isSGPLocation(), isTrue);
    });

    test('isSGPLocation should return false for Malaysia', () {
      appController.setCountryFromAlpha3('MYS');
      expect(appController.isSGPLocation(), isFalse);
    });

    test('isSGPLocation should return false for Thailand', () {
      appController.setCountryFromAlpha3('THA');
      expect(appController.isSGPLocation(), isFalse);
    });

    test('isSGPLocation should return false for Bhutan', () {
      appController.setCountryFromAlpha3('BTN');
      expect(appController.isSGPLocation(), isFalse);
    });
  });

  // ============================================================================
  // isMYSLocation Tests
  // ============================================================================

  group('AppController - isMYSLocation (Requirement 5.2)', () {
    test('isMYSLocation should return true for Malaysia', () {
      // Requirement 5.2: THE AppController SHALL provide an isMYSLocation() method that returns true when current country is MALAYSIA
      appController.setCountryFromAlpha3('MYS');
      expect(appController.isMYSLocation(), isTrue);
    });

    test('isMYSLocation should return false for Singapore', () {
      appController.setCountryFromAlpha3('SGP');
      expect(appController.isMYSLocation(), isFalse);
    });

    test('isMYSLocation should return false for Thailand', () {
      appController.setCountryFromAlpha3('THA');
      expect(appController.isMYSLocation(), isFalse);
    });

    test('isMYSLocation should return false for Bhutan', () {
      appController.setCountryFromAlpha3('BTN');
      expect(appController.isMYSLocation(), isFalse);
    });

    test('isMYSLocation should return false when country not set', () {
      // Default is Singapore, so Malaysia should be false
      expect(appController.isMYSLocation(), isFalse);
    });
  });

  // ============================================================================
  // isTHALocation Tests
  // ============================================================================

  group('AppController - isTHALocation (Requirement 5.3)', () {
    test('isTHALocation should return true for Thailand', () {
      // Requirement 5.3: THE AppController SHALL provide an isTHALocation() method that returns true when current country is THAILAND
      appController.setCountryFromAlpha3('THA');
      expect(appController.isTHALocation(), isTrue);
    });

    test('isTHALocation should return false for Singapore', () {
      appController.setCountryFromAlpha3('SGP');
      expect(appController.isTHALocation(), isFalse);
    });

    test('isTHALocation should return false for Malaysia', () {
      appController.setCountryFromAlpha3('MYS');
      expect(appController.isTHALocation(), isFalse);
    });

    test('isTHALocation should return false for Bhutan', () {
      appController.setCountryFromAlpha3('BTN');
      expect(appController.isTHALocation(), isFalse);
    });

    test('isTHALocation should return false when country not set', () {
      // Default is Singapore, so Thailand should be false
      expect(appController.isTHALocation(), isFalse);
    });
  });

  // ============================================================================
  // isBTNLocation Tests
  // ============================================================================

  group('AppController - isBTNLocation (Requirement 5.4)', () {
    test('isBTNLocation should return true for Bhutan', () {
      // Requirement 5.4: THE AppController SHALL provide an isBTNLocation() method that returns true when current country is BHUTAN
      appController.setCountryFromAlpha3('BTN');
      expect(appController.isBTNLocation(), isTrue);
    });

    test('isBTNLocation should return false for Singapore', () {
      appController.setCountryFromAlpha3('SGP');
      expect(appController.isBTNLocation(), isFalse);
    });

    test('isBTNLocation should return false for Malaysia', () {
      appController.setCountryFromAlpha3('MYS');
      expect(appController.isBTNLocation(), isFalse);
    });

    test('isBTNLocation should return false for Thailand', () {
      appController.setCountryFromAlpha3('THA');
      expect(appController.isBTNLocation(), isFalse);
    });

    test('isBTNLocation should return false when country not set', () {
      // Default is Singapore, so Bhutan should be false
      expect(appController.isBTNLocation(), isFalse);
    });
  });

  // ============================================================================
  // Exactly One Location Method Returns True
  // ============================================================================

  group('AppController - Exactly One Location Method Returns True', () {
    test('only isSGPLocation should return true for Singapore', () {
      appController.setCountryFromAlpha3('SGP');
      expect(appController.isSGPLocation(), isTrue);
      expect(appController.isMYSLocation(), isFalse);
      expect(appController.isTHALocation(), isFalse);
      expect(appController.isBTNLocation(), isFalse);

      // Count how many return true
      final trueCount = [
        appController.isSGPLocation(),
        appController.isMYSLocation(),
        appController.isTHALocation(),
        appController.isBTNLocation(),
      ].where((v) => v).length;
      expect(trueCount, equals(1));
    });

    test('only isMYSLocation should return true for Malaysia', () {
      appController.setCountryFromAlpha3('MYS');
      expect(appController.isSGPLocation(), isFalse);
      expect(appController.isMYSLocation(), isTrue);
      expect(appController.isTHALocation(), isFalse);
      expect(appController.isBTNLocation(), isFalse);

      final trueCount = [
        appController.isSGPLocation(),
        appController.isMYSLocation(),
        appController.isTHALocation(),
        appController.isBTNLocation(),
      ].where((v) => v).length;
      expect(trueCount, equals(1));
    });

    test('only isTHALocation should return true for Thailand', () {
      appController.setCountryFromAlpha3('THA');
      expect(appController.isSGPLocation(), isFalse);
      expect(appController.isMYSLocation(), isFalse);
      expect(appController.isTHALocation(), isTrue);
      expect(appController.isBTNLocation(), isFalse);

      final trueCount = [
        appController.isSGPLocation(),
        appController.isMYSLocation(),
        appController.isTHALocation(),
        appController.isBTNLocation(),
      ].where((v) => v).length;
      expect(trueCount, equals(1));
    });

    test('only isBTNLocation should return true for Bhutan', () {
      appController.setCountryFromAlpha3('BTN');
      expect(appController.isSGPLocation(), isFalse);
      expect(appController.isMYSLocation(), isFalse);
      expect(appController.isTHALocation(), isFalse);
      expect(appController.isBTNLocation(), isTrue);

      final trueCount = [
        appController.isSGPLocation(),
        appController.isMYSLocation(),
        appController.isTHALocation(),
        appController.isBTNLocation(),
      ].where((v) => v).length;
      expect(trueCount, equals(1));
    });

    test('exactly one location method returns true for all Country values', () {
      for (final country in Country.values) {
        appController.setCountryFromAlpha3(country.alpha3Code);

        final locationResults = [
          appController.isSGPLocation(),
          appController.isMYSLocation(),
          appController.isTHALocation(),
          appController.isBTNLocation(),
        ];

        final trueCount = locationResults.where((v) => v).length;
        expect(
          trueCount,
          equals(1),
          reason:
              'Exactly one location method should return true for ${country.name}, '
              'but got $trueCount. Results: SGP=${locationResults[0]}, MYS=${locationResults[1]}, '
              'THA=${locationResults[2]}, BTN=${locationResults[3]}',
        );
      }
    });
  });

  // ============================================================================
  // Backward Compatibility Tests
  // ============================================================================

  group('AppController - Backward Compatibility (Requirement 6.1, 6.2)', () {
    test('countryCodeAlpha should be accessible as RxString', () {
      // Requirement 6.1: WHEN existing code accesses countryCodeAlpha as a string, THE AppController SHALL return the correct alpha-3 code string
      expect(appController.countryCodeAlpha, isA<RxString>());
    });

    test('countryCodeAlpha.value should return correct alpha-3 code string',
        () {
      appController.setCountryFromAlpha3('MYS');
      expect(appController.countryCodeAlpha.value, equals('MYS'));
      expect(appController.countryCodeAlpha.value, isA<String>());
    });

    test('isSGPLocation should maintain backward compatibility for SGP', () {
      // Requirement 6.2: WHEN existing code calls isSGPLocation(), THE AppController SHALL return the same result as before the change
      appController.setCountryFromAlpha3('SGP');
      expect(appController.isSGPLocation(), isTrue);
    });

    test(
        'isSGPLocation should maintain backward compatibility for empty string',
        () {
      // When countryCodeAlpha is empty, isSGPLocation should return true (backward compatibility)
      final newController = AppController(AppFlavor.development);
      expect(newController.isSGPLocation(), isTrue);
    });
  });

  // ============================================================================
  // PROPERTY-BASED TESTS
  // ============================================================================
  // Feature: country-enum-support, Property 5: Country-String Synchronization Invariant
  //
  // Property-based testing approach: Since there are only 4 enum values,
  // we use exhaustive testing (testing all values) which is more thorough
  // than random sampling. Each property is verified across all Country values
  // with multiple iterations to ensure consistency.
  // ============================================================================

  group(
      'Property-Based Tests - Property 5: Country-String Synchronization Invariant',
      () {
    /// **Validates: Requirements 4.4, 4.6, 6.1**
    ///
    /// Property 5: Country-String Synchronization Invariant
    /// *For any* country set via setCountryFromAlpha3, the currentCountry enum
    /// value and countryCodeAlpha string value should always be consistent
    /// (countryCodeAlpha == currentCountry.alpha3Code).
    ///
    /// Test approach: Exhaustive testing over all 4 enum values, repeated 100+
    /// times to satisfy minimum iteration requirement.

    test(
        'Property 5.1: countryCodeAlpha always equals currentCountry.alpha3Code for all valid alpha-3 codes',
        () {
      // Exhaustive test: iterate over all Country values
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Set country using alpha-3 code
          appController.setCountryFromAlpha3(country.alpha3Code);

          // Property: countryCodeAlpha.value == currentCountry.alpha3Code
          expect(
            appController.countryCodeAlpha.value,
            equals(appController.currentCountry.alpha3Code),
            reason:
                'Iteration $iteration: After setCountryFromAlpha3("${country.alpha3Code}"), '
                'countryCodeAlpha.value (${appController.countryCodeAlpha.value}) '
                'should equal currentCountry.alpha3Code (${appController.currentCountry.alpha3Code})',
          );
        }
      }
    });

    test(
        'Property 5.2: countryCodeAlpha always equals currentCountry.alpha3Code for lowercase alpha-3 codes',
        () {
      // Exhaustive test: iterate over all Country values with lowercase codes
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Set country using lowercase alpha-3 code
          final lowercaseCode = country.alpha3Code.toLowerCase();
          appController.setCountryFromAlpha3(lowercaseCode);

          // Property: countryCodeAlpha.value == currentCountry.alpha3Code
          expect(
            appController.countryCodeAlpha.value,
            equals(appController.currentCountry.alpha3Code),
            reason:
                'Iteration $iteration: After setCountryFromAlpha3("$lowercaseCode"), '
                'countryCodeAlpha.value (${appController.countryCodeAlpha.value}) '
                'should equal currentCountry.alpha3Code (${appController.currentCountry.alpha3Code})',
          );
        }
      }
    });

    test(
        'Property 5.3: countryCodeAlpha always equals currentCountry.alpha3Code for mixed-case alpha-3 codes',
        () {
      // Exhaustive test: iterate over all Country values with mixed-case codes
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Create mixed-case code (e.g., "Sgp", "Mys", "Tha", "Btn")
          final mixedCaseCode = country.alpha3Code[0] +
              country.alpha3Code.substring(1).toLowerCase();
          appController.setCountryFromAlpha3(mixedCaseCode);

          // Property: countryCodeAlpha.value == currentCountry.alpha3Code
          expect(
            appController.countryCodeAlpha.value,
            equals(appController.currentCountry.alpha3Code),
            reason:
                'Iteration $iteration: After setCountryFromAlpha3("$mixedCaseCode"), '
                'countryCodeAlpha.value (${appController.countryCodeAlpha.value}) '
                'should equal currentCountry.alpha3Code (${appController.currentCountry.alpha3Code})',
          );
        }
      }
    });

    test(
        'Property 5.4: Synchronization invariant holds after multiple sequential country changes',
        () {
      // Test that the invariant holds after multiple sequential changes
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        // Cycle through all countries in sequence
        for (final country in Country.values) {
          appController.setCountryFromAlpha3(country.alpha3Code);

          // Property: countryCodeAlpha.value == currentCountry.alpha3Code
          // This must hold after EVERY change, not just the final state
          expect(
            appController.countryCodeAlpha.value,
            equals(appController.currentCountry.alpha3Code),
            reason:
                'Iteration $iteration: Synchronization invariant violated after setting ${country.name}. '
                'countryCodeAlpha.value (${appController.countryCodeAlpha.value}) '
                'should equal currentCountry.alpha3Code (${appController.currentCountry.alpha3Code})',
          );
        }
      }
    });

    test(
        'Property 5.5: Combined synchronization property - all valid alpha-3 codes maintain invariant (comprehensive)',
        () {
      /// Combined property test: verifies synchronization invariant in one comprehensive pass
      /// This is the comprehensive property that validates Requirements 4.4, 4.6, 6.1
      ///
      /// For ALL valid alpha-3 codes (SGP, MYS, THA, BTN):
      /// - After calling setCountryFromAlpha3(code), countryCodeAlpha.value == currentCountry.alpha3Code

      // All valid alpha-3 codes
      final validAlpha3Codes = ['SGP', 'MYS', 'THA', 'BTN'];

      // Exhaustive test: iterate over all valid codes
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final code in validAlpha3Codes) {
          appController.setCountryFromAlpha3(code);

          // Combined property assertion: synchronization must hold
          final isSynchronized = appController.countryCodeAlpha.value ==
              appController.currentCountry.alpha3Code;

          expect(
            isSynchronized,
            isTrue,
            reason:
                'Iteration $iteration: Synchronization invariant violated for code "$code". '
                'countryCodeAlpha.value="${appController.countryCodeAlpha.value}", '
                'currentCountry.alpha3Code="${appController.currentCountry.alpha3Code}"',
          );

          // Additional verification: the alpha3Code should match the input code (normalized to uppercase)
          expect(
            appController.countryCodeAlpha.value,
            equals(code.toUpperCase()),
            reason:
                'Iteration $iteration: countryCodeAlpha should be "$code" after setCountryFromAlpha3("$code")',
          );
        }
      }
    });
  });

  // ============================================================================
  // Edge Cases and Additional Tests
  // ============================================================================

  group('AppController - Edge Cases', () {
    test('multiple setCountryFromAlpha3 calls should update correctly', () {
      // Set to Malaysia
      appController.setCountryFromAlpha3('MYS');
      expect(appController.currentCountry, equals(Country.malaysia));
      expect(appController.countryCodeAlpha.value, equals('MYS'));

      // Change to Thailand
      appController.setCountryFromAlpha3('THA');
      expect(appController.currentCountry, equals(Country.thailand));
      expect(appController.countryCodeAlpha.value, equals('THA'));

      // Change to Bhutan
      appController.setCountryFromAlpha3('BTN');
      expect(appController.currentCountry, equals(Country.bhutan));
      expect(appController.countryCodeAlpha.value, equals('BTN'));

      // Change back to Singapore
      appController.setCountryFromAlpha3('SGP');
      expect(appController.currentCountry, equals(Country.singapore));
      expect(appController.countryCodeAlpha.value, equals('SGP'));
    });

    test(
        'setCountryFromAlpha3 with lowercase should normalize to uppercase in countryCodeAlpha',
        () {
      appController.setCountryFromAlpha3('mys');
      // countryCodeAlpha should be uppercase (from the enum's alpha3Code)
      expect(appController.countryCodeAlpha.value, equals('MYS'));
    });

    test('currentCountry and countryCodeAlpha should always be in sync', () {
      // Test with all valid codes
      final testCodes = [
        'SGP',
        'MYS',
        'THA',
        'BTN',
        'sgp',
        'mys',
        'tha',
        'btn',
        'Sgp',
        'Mys'
      ];

      for (final code in testCodes) {
        appController.setCountryFromAlpha3(code);
        expect(
          appController.countryCodeAlpha.value,
          equals(appController.currentCountry.alpha3Code),
          reason:
              'countryCodeAlpha should match currentCountry.alpha3Code after setting "$code"',
        );
      }
    });

    test('invalid codes should always result in Singapore', () {
      final invalidCodes = [
        null,
        '',
        'XXX',
        'USA',
        'ABC',
        '123',
        '   ',
        'SGPP',
        'S'
      ];

      for (final code in invalidCodes) {
        appController.setCountryFromAlpha3(code);
        expect(
          appController.currentCountry,
          equals(Country.singapore),
          reason: 'Invalid code "$code" should default to Singapore',
        );
        expect(
          appController.countryCodeAlpha.value,
          equals('SGP'),
          reason: 'Invalid code "$code" should set countryCodeAlpha to "SGP"',
        );
      }
    });
  });

  // ============================================================================
  // PROPERTY-BASED TESTS
  // ============================================================================
  // Feature: country-enum-support, Property 5: Country-String Synchronization Invariant
  //
  // Property-based testing approach: Since there are only 4 enum values,
  // we use exhaustive testing (testing all values) which is more thorough
  // than random sampling. Each property is verified across all Country values
  // with multiple iterations to ensure consistency.
  // ============================================================================

  group(
      'Feature: country-enum-support, Property 5: Country-String Synchronization Invariant',
      () {
    /// **Validates: Requirements 4.4, 4.6, 6.1**
    ///
    /// Property 5: Country-String Synchronization Invariant
    /// *For any* country set via setCountryFromAlpha3, the currentCountry enum
    /// value and countryCodeAlpha string value should always be consistent
    /// (countryCodeAlpha == currentCountry.alpha3Code).
    ///
    /// Test approach: Exhaustive testing over all 4 enum values, repeated 100+
    /// times to satisfy minimum iteration requirement.

    test(
        'Property 5.1: countryCodeAlpha always equals currentCountry.alpha3Code for all valid alpha-3 codes (100 iterations)',
        () {
      /// **Validates: Requirements 4.4, 4.6, 6.1**
      ///
      /// Exhaustive test: iterate over all Country values
      /// Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Set country using alpha-3 code
          appController.setCountryFromAlpha3(country.alpha3Code);

          // Property: countryCodeAlpha.value == currentCountry.alpha3Code
          expect(
            appController.countryCodeAlpha.value,
            equals(appController.currentCountry.alpha3Code),
            reason:
                'Iteration $iteration: After setCountryFromAlpha3("${country.alpha3Code}"), '
                'countryCodeAlpha.value (${appController.countryCodeAlpha.value}) '
                'should equal currentCountry.alpha3Code (${appController.currentCountry.alpha3Code})',
          );
        }
      }
    });

    test(
        'Property 5.2: countryCodeAlpha always equals currentCountry.alpha3Code for lowercase alpha-3 codes (100 iterations)',
        () {
      /// **Validates: Requirements 4.4, 4.6, 6.1**
      ///
      /// Exhaustive test: iterate over all Country values with lowercase codes
      /// Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Set country using lowercase alpha-3 code
          final lowercaseCode = country.alpha3Code.toLowerCase();
          appController.setCountryFromAlpha3(lowercaseCode);

          // Property: countryCodeAlpha.value == currentCountry.alpha3Code
          expect(
            appController.countryCodeAlpha.value,
            equals(appController.currentCountry.alpha3Code),
            reason:
                'Iteration $iteration: After setCountryFromAlpha3("$lowercaseCode"), '
                'countryCodeAlpha.value (${appController.countryCodeAlpha.value}) '
                'should equal currentCountry.alpha3Code (${appController.currentCountry.alpha3Code})',
          );
        }
      }
    });

    test(
        'Property 5.3: countryCodeAlpha always equals currentCountry.alpha3Code for mixed-case alpha-3 codes (100 iterations)',
        () {
      /// **Validates: Requirements 4.4, 4.6, 6.1**
      ///
      /// Exhaustive test: iterate over all Country values with mixed-case codes
      /// Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Create mixed-case code (e.g., "Sgp", "Mys", "Tha", "Btn")
          final mixedCaseCode = country.alpha3Code[0] +
              country.alpha3Code.substring(1).toLowerCase();
          appController.setCountryFromAlpha3(mixedCaseCode);

          // Property: countryCodeAlpha.value == currentCountry.alpha3Code
          expect(
            appController.countryCodeAlpha.value,
            equals(appController.currentCountry.alpha3Code),
            reason:
                'Iteration $iteration: After setCountryFromAlpha3("$mixedCaseCode"), '
                'countryCodeAlpha.value (${appController.countryCodeAlpha.value}) '
                'should equal currentCountry.alpha3Code (${appController.currentCountry.alpha3Code})',
          );
        }
      }
    });

    test(
        'Property 5.4: Synchronization invariant holds after multiple sequential country changes (100 iterations)',
        () {
      /// **Validates: Requirements 4.4, 4.6, 6.1**
      ///
      /// Test that the invariant holds after multiple sequential changes
      /// Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        // Cycle through all countries in sequence
        for (final country in Country.values) {
          appController.setCountryFromAlpha3(country.alpha3Code);

          // Property: countryCodeAlpha.value == currentCountry.alpha3Code
          // This must hold after EVERY change, not just the final state
          expect(
            appController.countryCodeAlpha.value,
            equals(appController.currentCountry.alpha3Code),
            reason:
                'Iteration $iteration: Synchronization invariant violated after setting ${country.name}. '
                'countryCodeAlpha.value (${appController.countryCodeAlpha.value}) '
                'should equal currentCountry.alpha3Code (${appController.currentCountry.alpha3Code})',
          );
        }
      }
    });

    test(
        'Property 5.5: Combined synchronization property - all valid alpha-3 codes maintain invariant (100 iterations)',
        () {
      /// **Validates: Requirements 4.4, 4.6, 6.1**
      ///
      /// Combined property test: verifies synchronization invariant in one comprehensive pass
      /// This is the comprehensive property that validates Requirements 4.4, 4.6, 6.1
      ///
      /// For ALL valid alpha-3 codes (SGP, MYS, THA, BTN):
      /// - After calling setCountryFromAlpha3(code), countryCodeAlpha.value == currentCountry.alpha3Code

      // All valid alpha-3 codes
      final validAlpha3Codes = ['SGP', 'MYS', 'THA', 'BTN'];

      // Exhaustive test: iterate over all valid codes
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final code in validAlpha3Codes) {
          appController.setCountryFromAlpha3(code);

          // Combined property assertion: synchronization must hold
          final isSynchronized = appController.countryCodeAlpha.value ==
              appController.currentCountry.alpha3Code;

          expect(
            isSynchronized,
            isTrue,
            reason:
                'Iteration $iteration: Synchronization invariant violated for code "$code". '
                'countryCodeAlpha.value="${appController.countryCodeAlpha.value}", '
                'currentCountry.alpha3Code="${appController.currentCountry.alpha3Code}"',
          );

          // Additional verification: the alpha3Code should match the input code (normalized to uppercase)
          expect(
            appController.countryCodeAlpha.value,
            equals(code.toUpperCase()),
            reason:
                'Iteration $iteration: countryCodeAlpha should be "$code" after setCountryFromAlpha3("$code")',
          );
        }
      }
    });
  });

  // ============================================================================
  // PROPERTY-BASED TESTS
  // ============================================================================
  // Feature: country-enum-support, Property 7: Exactly One Location Method Returns True
  //
  // Property-based testing approach: Since there are only 4 enum values,
  // we use exhaustive testing (testing all values) which is more thorough
  // than random sampling. Each property is verified across all Country values
  // with multiple iterations to ensure consistency.
  // ============================================================================

  group(
      'Feature: country-enum-support, Property 7: Exactly One Location Method Returns True',
      () {
    /// **Validates: Requirements 5.1, 5.2, 5.3, 5.4**
    ///
    /// Property 7: Exactly One Location Method Returns True
    /// *For any* valid Country enum value set in AppController, exactly one of
    /// the location check methods (isSGPLocation, isMYSLocation, isTHALocation,
    /// isBTNLocation) should return true, and it should correspond to the
    /// current country.
    ///
    /// Test approach: Exhaustive testing over all 4 enum values, repeated 100+
    /// times to satisfy minimum iteration requirement.

    /// Helper function to get the expected location method result for a country
    bool Function(AppController) _getExpectedLocationMethod(Country country) {
      switch (country) {
        case Country.singapore:
          return (controller) => controller.isSGPLocation();
        case Country.malaysia:
          return (controller) => controller.isMYSLocation();
        case Country.thailand:
          return (controller) => controller.isTHALocation();
        case Country.bhutan:
          return (controller) => controller.isBTNLocation();
      }
    }

    /// Helper function to get the name of the expected location method for a country
    String _getExpectedLocationMethodName(Country country) {
      switch (country) {
        case Country.singapore:
          return 'isSGPLocation';
        case Country.malaysia:
          return 'isMYSLocation';
        case Country.thailand:
          return 'isTHALocation';
        case Country.bhutan:
          return 'isBTNLocation';
      }
    }

    test(
        'Property 7.1: Exactly one location method returns true for all Country enum values (100 iterations)',
        () {
      /// **Validates: Requirements 5.1, 5.2, 5.3, 5.4**
      ///
      /// For ALL Country enum values:
      /// - Exactly one of isSGPLocation(), isMYSLocation(), isTHALocation(), isBTNLocation() returns true

      // Exhaustive test: iterate over all Country values
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Set country using alpha-3 code
          appController.setCountryFromAlpha3(country.alpha3Code);

          // Get all location method results
          final locationResults = [
            appController.isSGPLocation(),
            appController.isMYSLocation(),
            appController.isTHALocation(),
            appController.isBTNLocation(),
          ];

          // Property: Exactly one location method returns true
          final trueCount = locationResults.where((v) => v).length;
          expect(
            trueCount,
            equals(1),
            reason:
                'Iteration $iteration: Exactly one location method should return true for ${country.name}, '
                'but got $trueCount. Results: isSGPLocation=${locationResults[0]}, '
                'isMYSLocation=${locationResults[1]}, isTHALocation=${locationResults[2]}, '
                'isBTNLocation=${locationResults[3]}',
          );
        }
      }
    });

    test(
        'Property 7.2: The correct location method returns true for each Country enum value (100 iterations)',
        () {
      /// **Validates: Requirements 5.1, 5.2, 5.3, 5.4**
      ///
      /// For ALL Country enum values:
      /// - The method that returns true corresponds to the current country

      // Exhaustive test: iterate over all Country values
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Set country using alpha-3 code
          appController.setCountryFromAlpha3(country.alpha3Code);

          // Get the expected location method for this country
          final expectedMethod = _getExpectedLocationMethod(country);
          final expectedMethodName = _getExpectedLocationMethodName(country);

          // Property: The correct location method returns true
          expect(
            expectedMethod(appController),
            isTrue,
            reason:
                'Iteration $iteration: $expectedMethodName() should return true for ${country.name}',
          );
        }
      }
    });

    test(
        'Property 7.3: All other location methods return false for each Country enum value (100 iterations)',
        () {
      /// **Validates: Requirements 5.1, 5.2, 5.3, 5.4**
      ///
      /// For ALL Country enum values:
      /// - All location methods except the one for the current country return false

      // Map of country to its location method
      final countryToMethod = {
        Country.singapore: (AppController c) => c.isSGPLocation(),
        Country.malaysia: (AppController c) => c.isMYSLocation(),
        Country.thailand: (AppController c) => c.isTHALocation(),
        Country.bhutan: (AppController c) => c.isBTNLocation(),
      };

      final countryToMethodName = {
        Country.singapore: 'isSGPLocation',
        Country.malaysia: 'isMYSLocation',
        Country.thailand: 'isTHALocation',
        Country.bhutan: 'isBTNLocation',
      };

      // Exhaustive test: iterate over all Country values
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final currentCountry in Country.values) {
          // Set country using alpha-3 code
          appController.setCountryFromAlpha3(currentCountry.alpha3Code);

          // Check all other location methods return false
          for (final otherCountry in Country.values) {
            if (otherCountry != currentCountry) {
              final method = countryToMethod[otherCountry]!;
              final methodName = countryToMethodName[otherCountry]!;

              expect(
                method(appController),
                isFalse,
                reason:
                    'Iteration $iteration: $methodName() should return false when country is ${currentCountry.name}',
              );
            }
          }
        }
      }
    });

    test(
        'Property 7.4: Combined property - exactly one true and corresponds to current country (100 iterations)',
        () {
      /// **Validates: Requirements 5.1, 5.2, 5.3, 5.4**
      ///
      /// Combined property test: verifies both conditions in one comprehensive pass
      /// This is the comprehensive property that validates Requirements 5.1, 5.2, 5.3, 5.4
      ///
      /// For ALL Country enum values:
      /// 1. Exactly one of isSGPLocation(), isMYSLocation(), isTHALocation(), isBTNLocation() returns true
      /// 2. The method that returns true corresponds to the current country

      // Map of country to its expected location method index
      // Index: 0=isSGPLocation, 1=isMYSLocation, 2=isTHALocation, 3=isBTNLocation
      final countryToExpectedIndex = {
        Country.singapore: 0,
        Country.malaysia: 1,
        Country.thailand: 2,
        Country.bhutan: 3,
      };

      final methodNames = [
        'isSGPLocation',
        'isMYSLocation',
        'isTHALocation',
        'isBTNLocation',
      ];

      // Exhaustive test: iterate over all Country values
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Set country using alpha-3 code
          appController.setCountryFromAlpha3(country.alpha3Code);

          // Get all location method results
          final locationResults = [
            appController.isSGPLocation(),
            appController.isMYSLocation(),
            appController.isTHALocation(),
            appController.isBTNLocation(),
          ];

          // Property 1: Exactly one location method returns true
          final trueCount = locationResults.where((v) => v).length;
          expect(
            trueCount,
            equals(1),
            reason:
                'Iteration $iteration: Exactly one location method should return true for ${country.name}, '
                'but got $trueCount. Results: ${methodNames[0]}=${locationResults[0]}, '
                '${methodNames[1]}=${locationResults[1]}, ${methodNames[2]}=${locationResults[2]}, '
                '${methodNames[3]}=${locationResults[3]}',
          );

          // Property 2: The correct method returns true
          final expectedIndex = countryToExpectedIndex[country]!;
          final trueIndex = locationResults.indexOf(true);
          expect(
            trueIndex,
            equals(expectedIndex),
            reason:
                'Iteration $iteration: ${methodNames[expectedIndex]}() should return true for ${country.name}, '
                'but ${methodNames[trueIndex]}() returned true instead',
          );
        }
      }
    });

    test(
        'Property 7.5: Location method correspondence with case-insensitive alpha-3 codes (100 iterations)',
        () {
      /// **Validates: Requirements 5.1, 5.2, 5.3, 5.4**
      ///
      /// Verifies that the property holds regardless of case variation in input codes

      // Map of country to its expected location method
      final countryToMethod = {
        Country.singapore: (AppController c) => c.isSGPLocation(),
        Country.malaysia: (AppController c) => c.isMYSLocation(),
        Country.thailand: (AppController c) => c.isTHALocation(),
        Country.bhutan: (AppController c) => c.isBTNLocation(),
      };

      // Exhaustive test: iterate over all Country values with different case variations
      // Repeated 100 times to meet minimum iteration requirement
      for (var iteration = 0; iteration < 100; iteration++) {
        for (final country in Country.values) {
          // Test with uppercase, lowercase, and mixed-case codes
          final codeVariations = [
            country.alpha3Code.toUpperCase(),
            country.alpha3Code.toLowerCase(),
            country.alpha3Code[0] +
                country.alpha3Code.substring(1).toLowerCase(),
          ];

          for (final code in codeVariations) {
            // Set country using the code variation
            appController.setCountryFromAlpha3(code);

            // Get all location method results
            final locationResults = [
              appController.isSGPLocation(),
              appController.isMYSLocation(),
              appController.isTHALocation(),
              appController.isBTNLocation(),
            ];

            // Property: Exactly one location method returns true
            final trueCount = locationResults.where((v) => v).length;
            expect(
              trueCount,
              equals(1),
              reason:
                  'Iteration $iteration: Exactly one location method should return true for code "$code" (${country.name}), '
                  'but got $trueCount',
            );

            // Property: The correct method returns true
            expect(
              countryToMethod[country]!(appController),
              isTrue,
              reason:
                  'Iteration $iteration: Expected location method should return true for code "$code" (${country.name})',
            );
          }
        }
      }
    });
  });
}
