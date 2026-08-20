import 'package:flutter/material.dart' hide AnimationStyle;

import '../../utils/animation/animation_color_scheme.dart';
import '../../utils/animation/animation_lifecycle_controller.dart';
import '../../utils/animation/animation_style.dart';
import '../../utils/animation/wave_animation_config.dart';
import '../../utils/device_performance_detector.dart';
import 'wave_animation_painter.dart';
import 'package:app/shared/utils/log_utils.dart';

/// Adaptive wave animation widget that renders background animations
/// based on device performance and user settings.
///
/// This widget wraps child content and renders animated backgrounds
/// using [CustomPainter] for efficient rendering. The animation adapts
/// to device capabilities using [DevicePerformanceDetector].
///
/// **Requirements:** 1.5, 1.6, 2.1, 2.2
/// - Requirement 1.5: Use CustomPainter for rendering wave effects to minimize widget rebuilds
/// - Requirement 1.6: Wrap animated content in RepaintBoundary to isolate repaint operations
/// - Requirement 2.1: Low-spec devices use 30 FPS
/// - Requirement 2.2: High-spec devices use 60 FPS
///
/// Usage:
/// ```dart
/// WaveAnimationWidget(
///   enabled: true,
///   style: AnimationStyle.wave,
///   isDarkMode: false,
///   child: YourScreenContent(),
/// )
/// ```
class WaveAnimationWidget extends StatefulWidget {
  /// The child widget to display on top of the animation.
  final Widget child;

  /// The animation style to render.
  ///
  /// Defaults to [AnimationStyle.wave].
  final AnimationStyle style;

  /// Whether the animation is enabled.
  ///
  /// When `false`, only the child widget is rendered without animation.
  /// Defaults to `true`.
  final bool enabled;

  /// Whether dark mode is enabled.
  ///
  /// Used to select the appropriate color scheme for the animation.
  /// Defaults to `false`.
  final bool isDarkMode;

  /// Creates a new [WaveAnimationWidget].
  ///
  /// The [child] parameter is required and represents the content
  /// to display on top of the animation.
  const WaveAnimationWidget({
    Key? key,
    required this.child,
    this.style = AnimationStyle.wave,
    this.enabled = true,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<WaveAnimationWidget> createState() => _WaveAnimationWidgetState();
}

class _WaveAnimationWidgetState extends State<WaveAnimationWidget>
    with SingleTickerProviderStateMixin {
  /// Animation controller for driving the wave animation.
  AnimationController? _animationController;

  /// Lifecycle controller for managing animation pause/resume.
  AnimationLifecycleController? _lifecycleController;

  /// Animation configuration based on device performance tier.
  late WaveAnimationConfig _config;

  /// Device performance tier for adaptive rendering.
  late DevicePerformanceTier _performanceTier;

  /// Color scheme based on current theme.
  late AnimationColorScheme _colorScheme;

  /// Whether animation initialization was successful.
  bool _animationInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePerformanceConfig();
    _initializeColorScheme();
    _initializeAnimation();
  }

  /// Initializes performance configuration based on device capabilities.
  ///
  /// Queries [DevicePerformanceDetector] for the device performance tier
  /// and creates the appropriate [WaveAnimationConfig].
  void _initializePerformanceConfig() {
    final detector = DevicePerformanceDetector.instance;

    // Use low-spec defaults if detector is not initialized
    if (!detector.isInitialized) {
      _performanceTier = DevicePerformanceTier.low;
      _config = WaveAnimationConfig.lowSpec;
      LogUtils.debugLog(
        'WaveAnimationWidget: DevicePerformanceDetector not initialized, '
        'using low-spec defaults',
      );
      return;
    }

    _performanceTier = detector.getPerformanceTier();
    _config = WaveAnimationConfig.fromPerformanceTier(_performanceTier);
  }

  /// Initializes the color scheme based on the current theme.
  void _initializeColorScheme() {
    _colorScheme = widget.isDarkMode
        ? AnimationColorScheme.dark()
        : AnimationColorScheme.light();
  }

  /// Initializes the animation controller with error handling.
  ///
  /// **Requirement 5.5:** If animation controller fails to initialize,
  /// gracefully degrade to no animation without crashing.
  void _initializeAnimation() {
    if (!widget.enabled) {
      return;
    }

    try {
      // Create animation controller with duration from config
      // Frame rate is controlled by the config (30 FPS for low-spec, 60 FPS for high-spec)
      _animationController = AnimationController(
        duration: _config.animationDuration,
        vsync: this,
      );

      // Create lifecycle controller for pause/resume management
      _lifecycleController = AnimationLifecycleController(
        animationController: _animationController!,
      );
      _lifecycleController!.initialize();

      // Start the animation loop
      _animationController!.repeat();
      _animationInitialized = true;
    } catch (e) {
      // Log error but don't crash - graceful degradation
      LogUtils.debugLog(
          'WaveAnimationWidget: Failed to initialize animation: $e');
      _animationInitialized = false;
      _disposeAnimation();
    }
  }

  /// Disposes animation resources safely.
  void _disposeAnimation() {
    _lifecycleController?.dispose();
    _lifecycleController = null;

    _animationController?.dispose();
    _animationController = null;
  }

  @override
  void didUpdateWidget(WaveAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle enabled state changes
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled && !_animationInitialized) {
        _initializeAnimation();
      } else if (!widget.enabled && _animationInitialized) {
        _disposeAnimation();
        _animationInitialized = false;
      }
    }

    // Handle theme changes
    if (widget.isDarkMode != oldWidget.isDarkMode) {
      setState(() {
        _initializeColorScheme();
      });
    }

    // Handle style changes - no need to reinitialize, just rebuild
    if (widget.style != oldWidget.style) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _disposeAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If animation is disabled or failed to initialize, just show child
    if (!widget.enabled ||
        !_animationInitialized ||
        _animationController == null) {
      return widget.child;
    }

    // Get screen size for full screen animation
    final screenSize = MediaQuery.of(context).size;

    // Wrap in RepaintBoundary to isolate repaint operations (Requirement 1.6)
    return RepaintBoundary(
      child: SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Animation layer at the bottom - full screen
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animationController!,
                builder: (context, child) {
                  return CustomPaint(
                    size: screenSize,
                    painter: WaveAnimationPainter(
                      animationValue: _animationController!.value,
                      style: widget.style,
                      isDarkMode: widget.isDarkMode,
                      performanceTier: _performanceTier,
                      waveColors: _colorScheme.waveColors,
                      config: _config,
                      colorScheme: _colorScheme,
                    ),
                    // Use willChange hint for better performance
                    willChange: true,
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
            // Child content on top
            Positioned.fill(
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
