import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/modules/splash/models/splash_color_scheme.dart';

/// **Feature: splash-screen-enhancement, Property 4: WCAG contrast compliance**
/// **Validates: Requirements 3.3**
///
/// For any color combination used in the splash screen (text on background),
/// the contrast ratio should be at least 4.5:1 to meet WCAG 2.1 AA standards.
void main() {
  group('SplashColorScheme - Property 4: WCAG contrast compliance', () {
    // WCAG 2.1 AA requires:
    // - 4.5:1 for normal text
    // - 3:1 for large text (18pt+ or 14pt+ bold)
    const double wcagAANormalText = 4.5;
    const double wcagAALargeText = 3.0;

    test('calculateContrastRatio returns correct values', () {
      // Black on white should be ~21:1
      final blackOnWhite = SplashColorScheme.calculateContrastRatio(
        Colors.black,
        Colors.white,
      );
      expect(blackOnWhite, closeTo(21.0, 0.1));

      // White on black should also be ~21:1
      final whiteOnBlack = SplashColorScheme.calculateContrastRatio(
        Colors.white,
        Colors.black,
      );
      expect(whiteOnBlack, closeTo(21.0, 0.1));

      // Same color should be 1:1
      final sameColor = SplashColorScheme.calculateContrastRatio(
        Colors.grey,
        Colors.grey,
      );
      expect(sameColor, closeTo(1.0, 0.01));
    });

    test('light mode primary text meets WCAG AA contrast (4.5:1)', () {
      final scheme = SplashColorScheme.light();
      final contrast = SplashColorScheme.calculateContrastRatio(
        scheme.textColor,
        scheme.backgroundColor,
      );

      expect(contrast, greaterThanOrEqualTo(wcagAANormalText),
          reason:
              'Light mode primary text contrast ($contrast) should be >= $wcagAANormalText');
    });

    test('light mode secondary text meets WCAG AA large text contrast (3:1)',
        () {
      final scheme = SplashColorScheme.light();
      final contrast = SplashColorScheme.calculateContrastRatio(
        scheme.secondaryTextColor,
        scheme.backgroundColor,
      );

      expect(contrast, greaterThanOrEqualTo(wcagAALargeText),
          reason:
              'Light mode secondary text contrast ($contrast) should be >= $wcagAALargeText');
    });

    test('dark mode primary text meets WCAG AA contrast (4.5:1)', () {
      final scheme = SplashColorScheme.dark();
      final contrast = SplashColorScheme.calculateContrastRatio(
        scheme.textColor,
        scheme.backgroundColor,
      );

      expect(contrast, greaterThanOrEqualTo(wcagAANormalText),
          reason:
              'Dark mode primary text contrast ($contrast) should be >= $wcagAANormalText');
    });

    test('dark mode secondary text meets WCAG AA large text contrast (3:1)',
        () {
      final scheme = SplashColorScheme.dark();
      final contrast = SplashColorScheme.calculateContrastRatio(
        scheme.secondaryTextColor,
        scheme.backgroundColor,
      );

      expect(contrast, greaterThanOrEqualTo(wcagAALargeText),
          reason:
              'Dark mode secondary text contrast ($contrast) should be >= $wcagAALargeText');
    });

    test('meetsWCAGAAContrast returns true for light mode', () {
      final scheme = SplashColorScheme.light();
      expect(scheme.meetsWCAGAAContrast(), isTrue,
          reason: 'Light mode should meet WCAG AA contrast requirements');
    });

    test('meetsWCAGAAContrast returns true for dark mode', () {
      final scheme = SplashColorScheme.dark();
      expect(scheme.meetsWCAGAAContrast(), isTrue,
          reason: 'Dark mode should meet WCAG AA contrast requirements');
    });

    // Property-based test: For any theme mode, WCAG AA contrast is met
    test('property: for any theme mode, WCAG AA contrast requirements are met',
        () {
      for (final isDarkMode in [true, false]) {
        final scheme = SplashColorScheme.fromDarkMode(isDarkMode);
        final modeName = isDarkMode ? 'dark' : 'light';

        // Primary text must meet 4.5:1
        final primaryContrast = SplashColorScheme.calculateContrastRatio(
          scheme.textColor,
          scheme.backgroundColor,
        );
        expect(primaryContrast, greaterThanOrEqualTo(wcagAANormalText),
            reason:
                '$modeName mode primary text contrast ($primaryContrast) should be >= $wcagAANormalText');

        // Secondary text must meet 3:1 (large text standard)
        final secondaryContrast = SplashColorScheme.calculateContrastRatio(
          scheme.secondaryTextColor,
          scheme.backgroundColor,
        );
        expect(secondaryContrast, greaterThanOrEqualTo(wcagAALargeText),
            reason:
                '$modeName mode secondary text contrast ($secondaryContrast) should be >= $wcagAALargeText');

        // meetsWCAGAAContrast should return true
        expect(scheme.meetsWCAGAAContrast(), isTrue,
            reason: '$modeName mode should pass meetsWCAGAAContrast check');
      }
    });

    test('accent color has sufficient contrast on background', () {
      for (final isDarkMode in [true, false]) {
        final scheme = SplashColorScheme.fromDarkMode(isDarkMode);
        final modeName = isDarkMode ? 'dark' : 'light';

        final accentContrast = SplashColorScheme.calculateContrastRatio(
          scheme.accentColor,
          scheme.backgroundColor,
        );

        // Accent color should have at least 3:1 contrast for UI components
        expect(accentContrast, greaterThanOrEqualTo(3.0),
            reason:
                '$modeName mode accent color contrast ($accentContrast) should be >= 3.0');
      }
    });
  });
}
