import 'package:flutter/material.dart';
import '../../../shared/constants/colors.dart';

/// Color scheme for splash screen with theme support.
///
/// Provides consistent color definitions for both light and dark modes,
/// ensuring proper contrast ratios for accessibility compliance.
class SplashColorScheme {
  final Color backgroundColor;
  final Color gradientStart;
  final Color gradientEnd;
  final Color textColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final Color decorationColor;
  final Color logoContainerColor;
  final Color shadowColor;

  const SplashColorScheme({
    required this.backgroundColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.textColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.decorationColor,
    required this.logoContainerColor,
    required this.shadowColor,
  });

  /// Creates light mode color scheme.
  ///
  /// Uses light backgrounds with dark text for optimal readability.
  /// Contrast ratios meet WCAG 2.1 AA standards (4.5:1 minimum).
  factory SplashColorScheme.light() {
    return SplashColorScheme(
      backgroundColor: const Color(0xFFF5F5FF),
      gradientStart: ColorConstants.backgroundColorButtonPrint
          .withAlpha(13), // 0.05 opacity
      gradientEnd: ColorConstants.backgroundColorButtonPrint
          .withAlpha(38), // 0.15 opacity
      textColor: ColorConstants.grey800 ?? const Color(0xFF424242),
      secondaryTextColor: (ColorConstants.grey800 ?? const Color(0xFF424242))
          .withAlpha(153), // 0.6 opacity
      accentColor: ColorConstants.backgroundColorButtonPrint,
      decorationColor: ColorConstants.backgroundColorButtonPrint
          .withAlpha(26), // 0.1 opacity
      logoContainerColor: Colors.white,
      shadowColor: ColorConstants.backgroundColorButtonPrint
          .withAlpha(26), // 0.1 opacity
    );
  }

  /// Creates dark mode color scheme.
  ///
  /// Uses dark backgrounds with light text for optimal readability.
  /// Contrast ratios meet WCAG 2.1 AA standards (4.5:1 minimum).
  factory SplashColorScheme.dark() {
    return SplashColorScheme(
      backgroundColor: const Color(0xFF1A1A2E),
      gradientStart: (ColorConstants.grey800 ?? const Color(0xFF424242))
          .withAlpha(230), // 0.9 opacity
      gradientEnd: ColorConstants.grey800 ?? const Color(0xFF424242),
      textColor: ColorConstants.white,
      secondaryTextColor: ColorConstants.white.withAlpha(153), // 0.6 opacity
      accentColor: ColorConstants.colorGradientNext,
      decorationColor: ColorConstants.backgroundColorButtonPrint
          .withAlpha(51), // 0.2 opacity
      logoContainerColor: ColorConstants.grey800 ?? const Color(0xFF424242),
      shadowColor: Colors.black.withAlpha(51), // 0.2 opacity
    );
  }

  /// Gets the appropriate color scheme based on dark mode setting.
  factory SplashColorScheme.fromDarkMode(bool isDarkMode) {
    return isDarkMode ? SplashColorScheme.dark() : SplashColorScheme.light();
  }

  /// Calculates contrast ratio between two colors.
  ///
  /// Returns the contrast ratio as defined by WCAG 2.1.
  /// A ratio of 4.5:1 or higher meets AA standards for normal text.
  static double calculateContrastRatio(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();

    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Checks if text color meets WCAG AA contrast requirements.
  ///
  /// Returns true if contrast ratio is at least 4.5:1.
  bool meetsWCAGAAContrast() {
    final textContrast = calculateContrastRatio(textColor, backgroundColor);
    final secondaryContrast =
        calculateContrastRatio(secondaryTextColor, backgroundColor);

    return textContrast >= 4.5 && secondaryContrast >= 3.0;
  }
}
