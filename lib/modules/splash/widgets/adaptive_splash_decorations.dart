import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/splash_color_scheme.dart';

/// Adaptive decorations widget for splash screen.
///
/// Renders animated decorative elements (floating particles, pulse effects)
/// for high-spec devices, or returns an empty widget for low-spec devices.
class AdaptiveSplashDecorations extends StatelessWidget {
  /// Whether to enable animated decorations.
  final bool enableAnimations;

  /// Whether dark mode is enabled.
  final bool isDarkMode;

  /// Animation controller for pulse effect (optional, high-spec only).
  final Animation<double>? pulseAnimation;

  /// Animation controller for particle effect (optional, high-spec only).
  final Animation<double>? particleAnimation;

  const AdaptiveSplashDecorations({
    Key? key,
    required this.enableAnimations,
    required this.isDarkMode,
    this.pulseAnimation,
    this.particleAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Return empty widget for low-spec devices
    if (!enableAnimations) {
      return const SizedBox.shrink();
    }

    final colorScheme = SplashColorScheme.fromDarkMode(isDarkMode);

    return Stack(
      children: [
        // Circular gradient overlay at top-right
        _buildCircularOverlay(colorScheme),
        // Circular gradient overlay at bottom-left
        _buildBottomLeftOverlay(colorScheme),
        // Floating particles (if animation provided)
        if (particleAnimation != null) _buildFloatingParticles(colorScheme),
        // Pulse effect (if animation provided)
        if (pulseAnimation != null) _buildPulseEffect(colorScheme),
      ],
    );
  }

  /// Builds circular gradient overlay at top-right corner.
  Widget _buildCircularOverlay(SplashColorScheme colorScheme) {
    return Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              colorScheme.decorationColor,
              colorScheme.decorationColor.withAlpha(0),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds circular gradient overlay at bottom-left corner.
  Widget _buildBottomLeftOverlay(SplashColorScheme colorScheme) {
    return Positioned(
      bottom: -80,
      left: -80,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              colorScheme.accentColor.withAlpha(20),
              colorScheme.accentColor.withAlpha(0),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds floating particles animation.
  Widget _buildFloatingParticles(SplashColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: particleAnimation!,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            progress: particleAnimation!.value,
            color: colorScheme.decorationColor,
          ),
        );
      },
    );
  }

  /// Builds pulse effect animation.
  Widget _buildPulseEffect(SplashColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: pulseAnimation!,
      builder: (context, child) {
        final scale = 1.0 + (pulseAnimation!.value * 0.1);
        final opacity = 1.0 - (pulseAnimation!.value * 0.5);

        return Center(
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    colorScheme.accentColor.withAlpha((opacity * 30).toInt()),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for floating particles effect.
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Generate deterministic particle positions based on progress
    final random = math.Random(42); // Fixed seed for consistent positions

    for (int i = 0; i < 8; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      // Animate particles floating upward
      final animatedY = baseY - (progress * 50) + (i * 20);
      final wrappedY = animatedY % size.height;

      final radius = 2.0 + (random.nextDouble() * 3);
      final opacity = 0.3 + (random.nextDouble() * 0.4);

      paint.color = color.withAlpha((opacity * 255).toInt());
      canvas.drawCircle(Offset(baseX, wrappedY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Static decorations for simplified display (no animations).
///
/// Used as a lightweight alternative when animations are disabled
/// but some visual interest is still desired.
class StaticSplashDecorations extends StatelessWidget {
  final bool isDarkMode;

  const StaticSplashDecorations({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = SplashColorScheme.fromDarkMode(isDarkMode);

    return Stack(
      children: [
        // Simple static circular overlay
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.decorationColor,
            ),
          ),
        ),
      ],
    );
  }
}
