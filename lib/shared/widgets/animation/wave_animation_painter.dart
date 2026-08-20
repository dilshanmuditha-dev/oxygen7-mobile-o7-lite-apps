import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide AnimationStyle;

import '../../../shared/utils/animation/animation_color_scheme.dart';
import '../../../shared/utils/animation/animation_style.dart';
import '../../../shared/utils/animation/wave_animation_config.dart';
import '../../../shared/utils/device_performance_detector.dart';

/// Helper function to get alpha value from a Color.
/// Uses the new API pattern to avoid deprecation warnings.
int _getAlpha(Color color) => (color.a * 255.0).round().clamp(0, 255);

/// CustomPainter for rendering wave animations with minimal overhead.
///
/// Uses pre-calculated paths and adaptive complexity based on device tier.
/// Supports multiple animation styles: wave, gradient, pulse, and particles.
///
/// **Requirements:** 1.5, 6.1, 6.3
/// - Requirement 1.5: Use CustomPainter for rendering wave effects to minimize widget rebuilds
/// - Requirement 6.1: Render waves with smooth sine curve interpolation
/// - Requirement 6.3: Position waves at the bottom portion of the screen
class WaveAnimationPainter extends CustomPainter {
  /// Current animation progress value (0.0 to 1.0).
  final double animationValue;

  /// The animation style to render.
  final AnimationStyle style;

  /// Whether dark mode is enabled.
  final bool isDarkMode;

  /// Device performance tier for adaptive rendering.
  final DevicePerformanceTier performanceTier;

  /// Colors to use for wave rendering.
  final List<Color> waveColors;

  /// Animation configuration based on performance tier.
  final WaveAnimationConfig config;

  /// Color scheme for the current theme.
  final AnimationColorScheme colorScheme;

  /// Pre-calculated particle positions for particle animation.
  /// Stored to maintain particle positions across frames.
  final List<_Particle>? particles;

  /// Creates a new [WaveAnimationPainter].
  ///
  /// All parameters are required to ensure proper rendering based on
  /// device capabilities and user preferences.
  WaveAnimationPainter({
    required this.animationValue,
    required this.style,
    required this.isDarkMode,
    required this.performanceTier,
    required this.waveColors,
    required this.config,
    required this.colorScheme,
    this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Delegate to style-specific painting methods
    switch (style) {
      case AnimationStyle.wave:
        _paintWaveStyle(canvas, size);
        break;
      case AnimationStyle.gradient:
        _paintGradientStyle(canvas, size);
        break;
      case AnimationStyle.pulse:
        _paintPulseStyle(canvas, size);
        break;
      case AnimationStyle.particles:
        _paintParticlesStyle(canvas, size);
        break;
    }
  }

  /// Paints horizontal sine wave animation.
  ///
  /// **Requirements:** 6.1, 6.3, 7.1
  /// - Renders waves with smooth sine curve interpolation
  /// - Positions waves across the full screen height
  /// - Supports multiple wave layers for high-spec devices
  void _paintWaveStyle(Canvas canvas, Size size) {
    final int layerCount = config.waveLayers;
    final int pointCount = config.wavePointCount;

    // Wave covers full screen height
    final double waveAreaHeight = size.height;

    for (int layer = 0; layer < layerCount; layer++) {
      // Get color for this layer (with fallback)
      final Color waveColor = layer < waveColors.length
          ? waveColors[layer]
          : waveColors.isNotEmpty
              ? waveColors.last
              : Colors.blue.withAlpha(77);

      // Calculate layer-specific parameters for depth effect
      final double layerOffset = layer * 0.15;
      final double amplitudeMultiplier = 1.0 - (layer * 0.15);
      final double phaseOffset = layer * (math.pi / 3);

      // Calculate wave base Y position - distribute waves across full screen
      final double waveBaseY = size.height * (0.3 + layer * 0.2);

      // Pre-calculate wave points for this layer (Requirement 2.6)
      final List<Offset> wavePoints = _calculateWavePoints(
        size: size,
        pointCount: pointCount,
        waveBaseY: waveBaseY,
        amplitude: waveAreaHeight * 0.15 * amplitudeMultiplier,
        phaseOffset: phaseOffset,
        layerOffset: layerOffset,
      );

      // Create wave path
      final Path wavePath = _createWavePath(wavePoints, size);

      // Create paint with appropriate fill
      final Paint wavePaint = Paint()..style = PaintingStyle.fill;

      if (config.useGradients) {
        // Use gradient fill for high-spec devices
        wavePaint.shader = ui.Gradient.linear(
          Offset(0, waveBaseY - waveAreaHeight * 0.2),
          Offset(0, size.height),
          [
            waveColor,
            waveColor.withAlpha((_getAlpha(waveColor) * 0.3).round()),
          ],
        );
      } else {
        // Use solid color for low-spec devices (Requirement 2.4)
        wavePaint.color = waveColor;
      }

      canvas.drawPath(wavePath, wavePaint);
    }
  }

  /// Calculates wave points using sine curve interpolation.
  ///
  /// **Requirement 6.1:** Render waves with smooth sine curve interpolation
  List<Offset> _calculateWavePoints({
    required Size size,
    required int pointCount,
    required double waveBaseY,
    required double amplitude,
    required double phaseOffset,
    required double layerOffset,
  }) {
    final List<Offset> points = [];
    final double stepX = size.width / (pointCount - 1);

    // Animation phase based on current animation value
    final double animationPhase = animationValue * 2 * math.pi;

    for (int i = 0; i < pointCount; i++) {
      final double x = i * stepX;

      // Calculate normalized x position (0 to 1)
      final double normalizedX = x / size.width;

      // Sine wave calculation with smooth interpolation
      // Using multiple sine waves for more natural appearance
      final double primaryWave =
          math.sin((normalizedX * 2 * math.pi) + animationPhase + phaseOffset);
      final double secondaryWave = math.sin((normalizedX * 4 * math.pi) +
              animationPhase * 1.5 +
              phaseOffset) *
          0.3;

      // Combine waves for smooth curve
      final double combinedWave = primaryWave + secondaryWave;

      // Calculate y position
      final double y = waveBaseY + (combinedWave * amplitude);

      points.add(Offset(x, y));
    }

    return points;
  }

  /// Creates a closed path from wave points.
  Path _createWavePath(List<Offset> points, Size size) {
    final Path path = Path();

    if (points.isEmpty) return path;

    // Start from bottom-left corner
    path.moveTo(0, size.height);

    // Move to first wave point
    path.lineTo(points.first.dx, points.first.dy);

    // Draw smooth curve through all points using quadratic bezier
    for (int i = 0; i < points.length - 1; i++) {
      final Offset current = points[i];
      final Offset next = points[i + 1];

      // Calculate control point for smooth curve
      final double controlX = (current.dx + next.dx) / 2;
      final double controlY = (current.dy + next.dy) / 2;

      path.quadraticBezierTo(current.dx, current.dy, controlX, controlY);
    }

    // Connect to last point
    if (points.isNotEmpty) {
      path.lineTo(points.last.dx, points.last.dy);
    }

    // Close path to bottom-right and back to start
    path.lineTo(size.width, size.height);
    path.close();

    return path;
  }

  /// Paints animated gradient color transitions.
  ///
  /// **Requirement 7.2:** Render animated gradient color transitions
  void _paintGradientStyle(Canvas canvas, Size size) {
    final List<Color> gradientColors = colorScheme.gradientColors;

    if (gradientColors.isEmpty) return;

    // Calculate gradient rotation based on animation value
    final double angle = animationValue * 2 * math.pi;

    // Create rotating gradient effect
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.max(size.width, size.height);

    // Calculate gradient start and end points based on animation
    final Offset start = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
    final Offset end = Offset(
      center.dx + math.cos(angle + math.pi) * radius,
      center.dy + math.sin(angle + math.pi) * radius,
    );

    // Create gradient with animated colors
    final List<Color> animatedColors = _getAnimatedGradientColors(
      gradientColors,
      animationValue,
    );

    final Paint gradientPaint = Paint()
      ..shader = ui.Gradient.linear(
        start,
        end,
        animatedColors,
        _getGradientStops(animatedColors.length),
      );

    // Draw gradient covering full screen
    final Rect gradientRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );

    canvas.drawRect(gradientRect, gradientPaint);
  }

  /// Gets animated gradient colors based on animation progress.
  List<Color> _getAnimatedGradientColors(
      List<Color> baseColors, double progress) {
    if (baseColors.length < 2) {
      return baseColors.isNotEmpty
          ? [baseColors.first, baseColors.first]
          : [Colors.blue.withAlpha(128), Colors.cyan.withAlpha(128)];
    }

    // Shift colors based on animation progress for smooth transition
    final int shift =
        (progress * baseColors.length).floor() % baseColors.length;
    final List<Color> shiftedColors = [];

    for (int i = 0; i < baseColors.length; i++) {
      final int index = (i + shift) % baseColors.length;
      // Apply semi-transparency for visibility
      shiftedColors.add(baseColors[index].withAlpha(
        math.min(_getAlpha(baseColors[index]), 180),
      ));
    }

    return shiftedColors;
  }

  /// Gets evenly distributed gradient stops.
  List<double> _getGradientStops(int colorCount) {
    if (colorCount <= 1) return [0.0];
    return List.generate(
      colorCount,
      (index) => index / (colorCount - 1),
    );
  }

  /// Paints subtle pulsing glow effects.
  ///
  /// **Requirement 7.3:** Render subtle pulsing glow effects
  void _paintPulseStyle(Canvas canvas, Size size) {
    final Color pulseColor = colorScheme.pulseColor;

    // Calculate pulse intensity using sine wave for smooth pulsing
    final double pulseIntensity =
        (math.sin(animationValue * 2 * math.pi) + 1) / 2;

    // Pulse from center of screen for full screen effect
    final Offset pulseCenter = Offset(size.width / 2, size.height / 2);

    // Calculate pulse radius to cover full screen
    final double maxRadius = math.max(size.width, size.height) * 0.8;
    final double currentRadius = maxRadius * (0.6 + pulseIntensity * 0.4);

    // Create radial gradient for glow effect
    final Paint pulsePaint = Paint()
      ..shader = ui.Gradient.radial(
        pulseCenter,
        currentRadius,
        [
          pulseColor.withAlpha(
              (_getAlpha(pulseColor) * pulseIntensity * 0.6).round()),
          pulseColor.withAlpha(0),
        ],
        [0.0, 1.0],
      );

    // Draw pulse circle
    canvas.drawCircle(pulseCenter, currentRadius, pulsePaint);

    // Add secondary pulse for depth (only on high-spec devices)
    if (performanceTier != DevicePerformanceTier.low) {
      final double secondaryIntensity =
          (math.sin(animationValue * 2 * math.pi + math.pi / 2) + 1) / 2;
      final double secondaryRadius =
          maxRadius * 0.5 * (0.5 + secondaryIntensity * 0.5);

      final Paint secondaryPulsePaint = Paint()
        ..shader = ui.Gradient.radial(
          pulseCenter,
          secondaryRadius,
          [
            pulseColor.withAlpha(
                (_getAlpha(pulseColor) * 0.4 * secondaryIntensity).round()),
            pulseColor.withAlpha(0),
          ],
          [0.0, 1.0],
        );

      canvas.drawCircle(pulseCenter, secondaryRadius, secondaryPulsePaint);
    }
  }

  /// Paints floating particle animations.
  ///
  /// **Requirements:** 7.4, 7.5, 7.6
  /// - Render floating particle animations
  /// - Limit to 10 particles on low-spec devices
  /// - Allow up to 30 particles on high-spec devices
  void _paintParticlesStyle(Canvas canvas, Size size) {
    final Color particleColor = colorScheme.particleColor;
    final int maxParticles = config.maxParticles;

    // Use provided particles or generate based on animation value
    final List<_Particle> particlesToDraw =
        particles ?? _generateParticles(size, maxParticles);

    for (final particle in particlesToDraw) {
      // Calculate particle position based on animation
      final double animatedY = particle.y +
          (math.sin(animationValue * 2 * math.pi + particle.phase) *
              particle.amplitude);

      // Calculate particle opacity based on position (fade at edges)
      final double normalizedY = animatedY / size.height;
      final double opacity = math.sin(normalizedY * math.pi);

      // Draw particle
      final Paint particlePaint = Paint()
        ..color = particleColor.withAlpha(
          (_getAlpha(particleColor) * opacity * particle.opacity).round(),
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x, animatedY),
        particle.radius,
        particlePaint,
      );

      // Add glow effect for high-spec devices
      if (performanceTier == DevicePerformanceTier.high) {
        final Paint glowPaint = Paint()
          ..color = particleColor.withAlpha(
            (_getAlpha(particleColor) * 0.3 * opacity * particle.opacity)
                .round(),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawCircle(
          Offset(particle.x, animatedY),
          particle.radius * 2,
          glowPaint,
        );
      }
    }
  }

  /// Generates particle positions based on canvas size and max count.
  List<_Particle> _generateParticles(Size size, int count) {
    final math.Random random = math.Random(42); // Fixed seed for consistency
    final List<_Particle> particles = [];

    for (int i = 0; i < count; i++) {
      particles.add(_Particle(
        x: random.nextDouble() * size.width,
        y: random.nextDouble() * size.height, // Full screen distribution
        radius: 2 + random.nextDouble() * 4,
        phase: random.nextDouble() * 2 * math.pi,
        amplitude: 15 + random.nextDouble() * 30,
        opacity: 0.3 + random.nextDouble() * 0.7,
      ));
    }

    return particles;
  }

  @override
  bool shouldRepaint(WaveAnimationPainter oldDelegate) {
    // Repaint when animation value changes (primary trigger)
    if (animationValue != oldDelegate.animationValue) {
      return true;
    }

    // Repaint when style changes
    if (style != oldDelegate.style) {
      return true;
    }

    // Repaint when theme changes
    if (isDarkMode != oldDelegate.isDarkMode) {
      return true;
    }

    // Repaint when performance tier changes
    if (performanceTier != oldDelegate.performanceTier) {
      return true;
    }

    // Repaint when colors change
    if (!_areColorsEqual(waveColors, oldDelegate.waveColors)) {
      return true;
    }

    // No repaint needed if nothing changed
    return false;
  }

  /// Compares two color lists for equality.
  bool _areColorsEqual(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Internal class representing a particle for particle animation.
class _Particle {
  /// X position of the particle.
  final double x;

  /// Base Y position of the particle.
  final double y;

  /// Radius of the particle.
  final double radius;

  /// Phase offset for animation.
  final double phase;

  /// Amplitude of vertical movement.
  final double amplitude;

  /// Opacity multiplier (0.0 to 1.0).
  final double opacity;

  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.phase,
    required this.amplitude,
    required this.opacity,
  });
}
