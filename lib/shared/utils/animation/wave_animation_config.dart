import '../device_performance_detector.dart';

/// Configuration for wave animation parameters.
///
/// Adapts animation settings based on device performance tier to ensure
/// smooth animations on both low-spec POS devices and high-spec smartphones.
///
/// **Requirements:** 2.1, 2.2, 2.3, 2.4, 6.5, 6.6, 7.5, 7.6
class WaveAnimationConfig {
  /// Target frame rate for the animation.
  ///
  /// - Low-spec: 30 FPS (Requirement 2.1)
  /// - High-spec: 60 FPS (Requirement 2.2)
  final int frameRate;

  /// Number of points used to calculate the wave path.
  ///
  /// Fewer points = simplified wave calculations for low-spec devices.
  /// (Requirement 2.3)
  final int wavePointCount;

  /// Number of overlapping wave layers for depth effect.
  ///
  /// - Low-spec: 1 layer (Requirement 6.6)
  /// - High-spec: Multiple layers (Requirement 6.5)
  final int waveLayers;

  /// Duration of one complete animation cycle.
  ///
  /// Should be between 2-4 seconds for comfortable viewing.
  /// (Requirement 6.2 / Property 8)
  final Duration animationDuration;

  /// Whether to use gradient fills for waves.
  ///
  /// - Low-spec: false (solid colors) (Requirement 2.4)
  /// - High-spec: true (gradients allowed)
  final bool useGradients;

  /// Maximum number of particles for particle animation style.
  ///
  /// - Low-spec: 10 particles (Requirement 7.5)
  /// - High-spec: 30 particles (Requirement 7.6)
  final int maxParticles;

  /// Creates a new [WaveAnimationConfig] with the specified parameters.
  const WaveAnimationConfig({
    required this.frameRate,
    required this.wavePointCount,
    required this.waveLayers,
    required this.animationDuration,
    required this.useGradients,
    required this.maxParticles,
  });

  /// Creates a [WaveAnimationConfig] based on the device performance tier.
  ///
  /// This factory method returns the appropriate configuration for the
  /// given [DevicePerformanceTier], ensuring optimal performance on all devices.
  ///
  /// **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 6.5, 6.6, 7.5, 7.6**
  factory WaveAnimationConfig.fromPerformanceTier(DevicePerformanceTier tier) {
    switch (tier) {
      case DevicePerformanceTier.low:
        return lowSpec;
      case DevicePerformanceTier.medium:
        return mediumSpec;
      case DevicePerformanceTier.high:
        return highSpec;
    }
  }

  /// Configuration for low-spec devices (POS terminals, old smartphones).
  ///
  /// Optimized for minimal resource usage:
  /// - 30 FPS frame rate (Requirement 2.1)
  /// - Simplified wave calculations with fewer points (Requirement 2.3)
  /// - Solid colors instead of gradients (Requirement 2.4)
  /// - Single wave layer (Requirement 6.6)
  /// - Maximum 10 particles (Requirement 7.5)
  static const WaveAnimationConfig lowSpec = WaveAnimationConfig(
    frameRate: 30,
    wavePointCount: 20,
    waveLayers: 1,
    animationDuration: Duration(milliseconds: 3000),
    useGradients: false,
    maxParticles: 10,
  );

  /// Configuration for medium-spec devices (mid-range smartphones).
  ///
  /// Balanced settings for good visuals with reasonable performance:
  /// - 45 FPS frame rate
  /// - Moderate wave point count
  /// - Gradients enabled
  /// - 2 wave layers
  /// - Maximum 20 particles
  static const WaveAnimationConfig mediumSpec = WaveAnimationConfig(
    frameRate: 45,
    wavePointCount: 35,
    waveLayers: 2,
    animationDuration: Duration(milliseconds: 3000),
    useGradients: true,
    maxParticles: 20,
  );

  /// Configuration for high-spec devices (flagship smartphones, tablets).
  ///
  /// Full visual quality with all effects enabled:
  /// - 60 FPS frame rate (Requirement 2.2)
  /// - High wave point count for smooth curves
  /// - Gradients enabled
  /// - Multiple wave layers for depth effect (Requirement 6.5)
  /// - Maximum 30 particles (Requirement 7.6)
  static const WaveAnimationConfig highSpec = WaveAnimationConfig(
    frameRate: 60,
    wavePointCount: 50,
    waveLayers: 3,
    animationDuration: Duration(milliseconds: 3000),
    useGradients: true,
    maxParticles: 30,
  );

  /// Returns the frame duration based on the target frame rate.
  ///
  /// Useful for throttling animation updates to the target FPS.
  Duration get frameDuration => Duration(
        milliseconds: (1000 / frameRate).round(),
      );

  @override
  String toString() {
    return 'WaveAnimationConfig('
        'frameRate: $frameRate, '
        'wavePointCount: $wavePointCount, '
        'waveLayers: $waveLayers, '
        'animationDuration: ${animationDuration.inMilliseconds}ms, '
        'useGradients: $useGradients, '
        'maxParticles: $maxParticles)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WaveAnimationConfig &&
        other.frameRate == frameRate &&
        other.wavePointCount == wavePointCount &&
        other.waveLayers == waveLayers &&
        other.animationDuration == animationDuration &&
        other.useGradients == useGradients &&
        other.maxParticles == maxParticles;
  }

  @override
  int get hashCode {
    return Object.hash(
      frameRate,
      wavePointCount,
      waveLayers,
      animationDuration,
      useGradients,
      maxParticles,
    );
  }

  /// Creates a copy of this config with the given fields replaced.
  WaveAnimationConfig copyWith({
    int? frameRate,
    int? wavePointCount,
    int? waveLayers,
    Duration? animationDuration,
    bool? useGradients,
    int? maxParticles,
  }) {
    return WaveAnimationConfig(
      frameRate: frameRate ?? this.frameRate,
      wavePointCount: wavePointCount ?? this.wavePointCount,
      waveLayers: waveLayers ?? this.waveLayers,
      animationDuration: animationDuration ?? this.animationDuration,
      useGradients: useGradients ?? this.useGradients,
      maxParticles: maxParticles ?? this.maxParticles,
    );
  }
}
