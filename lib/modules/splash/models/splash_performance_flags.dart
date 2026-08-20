import '../../../shared/utils/device_performance_detector.dart';

/// Performance flags for splash screen adaptive rendering.
///
/// This class caches device capability flags from DevicePerformanceDetector
/// to enable efficient conditional rendering in the splash screen.
class SplashPerformanceFlags {
  final bool shouldUseSimplifiedUI;
  final bool enableGradients;
  final bool enableComplexAnimations;
  final bool enableBlurEffects;
  final Duration animationDuration;
  final Duration transitionDuration;

  const SplashPerformanceFlags({
    required this.shouldUseSimplifiedUI,
    required this.enableGradients,
    required this.enableComplexAnimations,
    required this.enableBlurEffects,
    required this.animationDuration,
    required this.transitionDuration,
  });

  /// Creates performance flags from DevicePerformanceDetector.
  ///
  /// Queries the detector for device capability flags and maps them
  /// to splash screen specific settings.
  factory SplashPerformanceFlags.fromDetector(
      DevicePerformanceDetector detector) {
    final tier = detector.getPerformanceTier();
    final config = PerformanceConfig.settings[tier]!;

    return SplashPerformanceFlags(
      shouldUseSimplifiedUI: detector.shouldUseSimplifiedUI(),
      enableGradients: config.enableGradients,
      enableComplexAnimations: config.enableComplexAnimations,
      enableBlurEffects: config.enableBlurEffects,
      animationDuration: config.animationDuration,
      transitionDuration: detector.getOptimalAnimationDuration(),
    );
  }

  /// Creates default low-spec flags for fallback mode.
  ///
  /// Used when DevicePerformanceDetector is not initialized or
  /// when initialization fails. Defaults to safe low-spec mode
  /// to ensure smooth performance on all devices.
  factory SplashPerformanceFlags.lowSpecDefault() {
    return const SplashPerformanceFlags(
      shouldUseSimplifiedUI: true,
      enableGradients: false,
      enableComplexAnimations: false,
      enableBlurEffects: false,
      animationDuration: Duration(milliseconds: 150),
      transitionDuration: Duration(milliseconds: 150),
    );
  }

  /// Gets performance flags with automatic fallback handling.
  ///
  /// Returns flags from detector if initialized, otherwise returns
  /// low-spec defaults for safe fallback behavior.
  static SplashPerformanceFlags getFlags() {
    final detector = DevicePerformanceDetector.instance;

    if (!detector.isInitialized) {
      return SplashPerformanceFlags.lowSpecDefault();
    }

    return SplashPerformanceFlags.fromDetector(detector);
  }

  @override
  String toString() {
    return 'SplashPerformanceFlags('
        'simplifiedUI: $shouldUseSimplifiedUI, '
        'gradients: $enableGradients, '
        'complexAnimations: $enableComplexAnimations, '
        'blur: $enableBlurEffects, '
        'animDuration: ${animationDuration.inMilliseconds}ms, '
        'transDuration: ${transitionDuration.inMilliseconds}ms)';
  }
}
