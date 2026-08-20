import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/modules/splash/models/splash_color_scheme.dart';

/// **Feature: splash-screen-enhancement, Property 3: Theme-based color application**
/// **Validates: Requirements 3.1, 3.2**
///
/// For any theme mode (dark or light), the splash screen should apply the
/// corresponding color scheme from SplashColorScheme - dark backgrounds with
/// light text for dark mode, and light backgrounds with dark text for light mode.
void main() {
  group('SplashColorScheme - Property 3: Theme-based color application', () {
    test('light mode creates scheme with light background and dark text', () {
      final scheme = SplashColorScheme.light();

      // Light mode should have light background
      final bgLuminance = scheme.backgroundColor.computeLuminance();
      expect(bgLuminance, greaterThan(0.5),
          reason: 'Light mode background should be light (luminance > 0.5)');

      // Light mode should have dark text
      final textLuminance = scheme.textColor.computeLuminance();
      expect(textLuminance, lessThan(0.5),
          reason: 'Light mode text should be dark (luminance < 0.5)');
    });

    test('dark mode creates scheme with dark background and light text', () {
      final scheme = SplashColorScheme.dark();

      // Dark mode should have dark background
      final bgLuminance = scheme.backgroundColor.computeLuminance();
      expect(bgLuminance, lessThan(0.3),
          reason: 'Dark mode background should be dark (luminance < 0.3)');

      // Dark mode should have light text
      final textLuminance = scheme.textColor.computeLuminance();
      expect(textLuminance, greaterThan(0.7),
          reason: 'Dark mode text should be light (luminance > 0.7)');
    });

    test('fromDarkMode factory returns correct scheme for each mode', () {
      // Test with isDarkMode = false
      final lightScheme = SplashColorScheme.fromDarkMode(false);
      final expectedLight = SplashColorScheme.light();
      expect(
          lightScheme.backgroundColor, equals(expectedLight.backgroundColor));
      expect(lightScheme.textColor, equals(expectedLight.textColor));

      // Test with isDarkMode = true
      final darkScheme = SplashColorScheme.fromDarkMode(true);
      final expectedDark = SplashColorScheme.dark();
      expect(darkScheme.backgroundColor, equals(expectedDark.backgroundColor));
      expect(darkScheme.textColor, equals(expectedDark.textColor));
    });

    // Property-based test: For any boolean value, the correct scheme is returned
    test('property: for any theme mode, correct color scheme is applied', () {
      for (final isDarkMode in [true, false]) {
        final scheme = SplashColorScheme.fromDarkMode(isDarkMode);
        final bgLuminance = scheme.backgroundColor.computeLuminance();
        final textLuminance = scheme.textColor.computeLuminance();

        if (isDarkMode) {
          // Dark mode: dark background, light text
          expect(bgLuminance, lessThan(0.3),
              reason: 'Dark mode should have dark background');
          expect(textLuminance, greaterThan(0.7),
              reason: 'Dark mode should have light text');
        } else {
          // Light mode: light background, dark text
          expect(bgLuminance, greaterThan(0.5),
              reason: 'Light mode should have light background');
          expect(textLuminance, lessThan(0.5),
              reason: 'Light mode should have dark text');
        }
      }
    });

    test('all color properties are defined for light mode', () {
      final scheme = SplashColorScheme.light();

      expect(scheme.backgroundColor, isNotNull);
      expect(scheme.gradientStart, isNotNull);
      expect(scheme.gradientEnd, isNotNull);
      expect(scheme.textColor, isNotNull);
      expect(scheme.secondaryTextColor, isNotNull);
      expect(scheme.accentColor, isNotNull);
      expect(scheme.decorationColor, isNotNull);
      expect(scheme.logoContainerColor, isNotNull);
      expect(scheme.shadowColor, isNotNull);
    });

    test('all color properties are defined for dark mode', () {
      final scheme = SplashColorScheme.dark();

      expect(scheme.backgroundColor, isNotNull);
      expect(scheme.gradientStart, isNotNull);
      expect(scheme.gradientEnd, isNotNull);
      expect(scheme.textColor, isNotNull);
      expect(scheme.secondaryTextColor, isNotNull);
      expect(scheme.accentColor, isNotNull);
      expect(scheme.decorationColor, isNotNull);
      expect(scheme.logoContainerColor, isNotNull);
      expect(scheme.shadowColor, isNotNull);
    });
  });
}
