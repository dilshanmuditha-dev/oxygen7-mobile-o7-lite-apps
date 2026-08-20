import 'package:flutter/material.dart';
import '../models/splash_color_scheme.dart';

/// Adaptive background widget for splash screen.
///
/// Renders either a gradient background for high-spec devices or
/// a solid color background for low-spec devices based on the
/// [useGradient] flag.
class AdaptiveSplashBackground extends StatelessWidget {
  /// Whether to use gradient background (high-spec) or solid color (low-spec).
  final bool useGradient;

  /// Whether dark mode is enabled.
  final bool isDarkMode;

  /// Optional child widget to render on top of the background.
  final Widget? child;

  const AdaptiveSplashBackground({
    Key? key,
    required this.useGradient,
    required this.isDarkMode,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = SplashColorScheme.fromDarkMode(isDarkMode);

    if (useGradient) {
      return _buildGradientBackground(colorScheme);
    }
    return _buildSolidBackground(colorScheme);
  }

  /// Builds gradient background for high-spec devices.
  ///
  /// Uses a linear gradient from top-left to bottom-right with
  /// brand colors for a modern, professional appearance.
  Widget _buildGradientBackground(SplashColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.gradientStart,
            colorScheme.gradientEnd,
          ],
        ),
      ),
      child: child,
    );
  }

  /// Builds solid color background for low-spec devices.
  ///
  /// Uses a simple solid color to minimize rendering overhead
  /// and ensure smooth performance on resource-constrained devices.
  Widget _buildSolidBackground(SplashColorScheme colorScheme) {
    return Container(
      color: colorScheme.backgroundColor,
      child: child,
    );
  }
}
