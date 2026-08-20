// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/device_performance_detector.dart';

/// Adaptive animation widgets that adjust complexity based on device performance
///
/// Features:
/// - Automatic animation simplification for low-spec devices
/// - Performance-optimized curves and durations
/// - Memory-efficient animation controllers
/// - Conditional animation disabling

/// Adaptive AnimatedContainer
class AdaptiveAnimatedContainer extends StatelessWidget {
  final Widget child;
  final Duration? duration;
  final Curve curve;
  final double? width;
  final double? height;
  final Color? color;
  final Decoration? decoration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;
  final Matrix4? transform;

  const AdaptiveAnimatedContainer({
    Key? key,
    required this.child,
    this.duration,
    this.curve = Curves.easeInOut,
    this.width,
    this.height,
    this.color,
    this.decoration,
    this.padding,
    this.margin,
    this.alignment,
    this.transform,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final detector = DevicePerformanceDetector.instance;

    // Skip animation for low-spec devices
    if (detector.isInitialized && detector.shouldUseSimplifiedUI()) {
      return Container(
        width: width,
        height: height,
        color: color,
        decoration: decoration,
        padding: padding,
        margin: margin,
        alignment: alignment,
        transform: transform,
        child: child,
      );
    }

    // Use adaptive duration and curve
    return AnimatedContainer(
      duration: duration ?? detector.getOptimalAnimationDuration(),
      curve: _getOptimalCurve(detector),
      width: width,
      height: height,
      color: color,
      decoration: decoration,
      padding: padding,
      margin: margin,
      alignment: alignment,
      transform: transform,
      child: child,
    );
  }

  Curve _getOptimalCurve(DevicePerformanceDetector detector) {
    if (!detector.isInitialized) return curve;

    return detector.shouldUseSimplifiedUI()
        ? Curves.linear // Faster, less CPU intensive
        : curve;
  }
}

/// Adaptive AnimatedOpacity
class AdaptiveAnimatedOpacity extends StatelessWidget {
  final Widget child;
  final double opacity;
  final Duration? duration;
  final Curve curve;

  const AdaptiveAnimatedOpacity({
    Key? key,
    required this.child,
    required this.opacity,
    this.duration,
    this.curve = Curves.easeInOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final detector = DevicePerformanceDetector.instance;

    // Skip animation for low-spec devices
    if (detector.isInitialized && detector.shouldUseSimplifiedUI()) {
      return Opacity(
        opacity: opacity,
        child: child,
      );
    }

    return AnimatedOpacity(
      opacity: opacity,
      duration: duration ?? detector.getOptimalAnimationDuration(),
      curve: _getOptimalCurve(detector),
      child: child,
    );
  }

  Curve _getOptimalCurve(DevicePerformanceDetector detector) {
    if (!detector.isInitialized) return curve;

    return detector.shouldUseSimplifiedUI() ? Curves.linear : curve;
  }
}

/// Adaptive AnimatedSwitcher
class AdaptiveAnimatedSwitcher extends StatelessWidget {
  final Widget child;
  final Duration? duration;
  final Duration? reverseDuration;
  final Curve switchInCurve;
  final Curve switchOutCurve;
  final AnimatedSwitcherTransitionBuilder? transitionBuilder;

  const AdaptiveAnimatedSwitcher({
    Key? key,
    required this.child,
    this.duration,
    this.reverseDuration,
    this.switchInCurve = Curves.linear,
    this.switchOutCurve = Curves.linear,
    this.transitionBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final detector = DevicePerformanceDetector.instance;

    // Skip animation for low-spec devices
    if (detector.isInitialized && detector.shouldUseSimplifiedUI()) {
      return child;
    }

    return AnimatedSwitcher(
      duration: duration ?? detector.getOptimalAnimationDuration(),
      reverseDuration: reverseDuration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      transitionBuilder: transitionBuilder ?? _defaultTransitionBuilder,
      child: child,
    );
  }

  Widget _defaultTransitionBuilder(Widget child, Animation<double> animation) {
    return FadeTransition(opacity: animation, child: child);
  }
}

/// Adaptive AnimatedSize
class AdaptiveAnimatedSize extends StatelessWidget {
  final Widget child;
  final Duration? duration;
  final Curve curve;
  final AlignmentGeometry alignment;

  const AdaptiveAnimatedSize({
    Key? key,
    required this.child,
    this.duration,
    this.curve = Curves.easeInOut,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final detector = DevicePerformanceDetector.instance;

    // Skip animation for low-spec devices
    if (detector.isInitialized && detector.shouldUseSimplifiedUI()) {
      return child;
    }

    return AnimatedSize(
      duration: duration ?? detector.getOptimalAnimationDuration(),
      curve: curve,
      alignment: alignment,
      child: child,
    );
  }
}

/// Performance-optimized fade transition
class OptimizedFadeTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> opacity;
  final bool alwaysIncludeSemantics;

  const OptimizedFadeTransition({
    Key? key,
    required this.child,
    required this.opacity,
    this.alwaysIncludeSemantics = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final detector = DevicePerformanceDetector.instance;

    // Use RepaintBoundary for complex animations on capable devices
    if (detector.isInitialized && !detector.shouldUseSimplifiedUI()) {
      return RepaintBoundary(
        child: FadeTransition(
          opacity: opacity,
          alwaysIncludeSemantics: alwaysIncludeSemantics,
          child: child,
        ),
      );
    }

    return FadeTransition(
      opacity: opacity,
      alwaysIncludeSemantics: alwaysIncludeSemantics,
      child: child,
    );
  }
}

/// Adaptive slide transition
class AdaptiveSlideTransition extends StatelessWidget {
  final Widget child;
  final Animation<Offset> position;
  final TextDirection? textDirection;

  const AdaptiveSlideTransition({
    Key? key,
    required this.child,
    required this.position,
    this.textDirection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final detector = DevicePerformanceDetector.instance;

    // Skip animation for low-spec devices - just show final position
    if (detector.isInitialized && detector.shouldUseSimplifiedUI()) {
      return child;
    }

    return SlideTransition(
      position: position,
      textDirection: textDirection,
      child: child,
    );
  }
}

/// Optimized scale transition
class OptimizedScaleTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> scale;
  final Alignment alignment;

  const OptimizedScaleTransition({
    Key? key,
    required this.child,
    required this.scale,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final detector = DevicePerformanceDetector.instance;

    // Use RepaintBoundary for smooth scaling on capable devices
    if (detector.isInitialized && !detector.shouldUseLightweightAnimations) {
      return RepaintBoundary(
        child: ScaleTransition(
          scale: scale,
          alignment: alignment,
          child: child,
        ),
      );
    }

    return ScaleTransition(
      scale: scale,
      alignment: alignment,
      child: child,
    );
  }
}

/// Memory-efficient animation controller manager
class AnimationControllerManager {
  static final Map<String, AnimationController> _controllers = {};
  static const int MAX_CONTROLLERS = 10; // Limit for low-spec devices

  /// Get or create animation controller
  static AnimationController getController({
    required String id,
    required TickerProvider vsync,
    Duration? duration,
  }) {
    final detector = DevicePerformanceDetector.instance;

    // Check if we have too many controllers on low-spec devices
    if (detector.isInitialized &&
        detector.shouldUseSimplifiedUI() &&
        _controllers.length >= MAX_CONTROLLERS) {
      _disposeOldestController();
    }

    if (_controllers.containsKey(id)) {
      return _controllers[id]!;
    }

    final controller = AnimationController(
      duration: duration ?? detector.getOptimalAnimationDuration(),
      vsync: vsync,
    );

    _controllers[id] = controller;
    return controller;
  }

  /// Dispose specific controller
  static void disposeController(String id) {
    final controller = _controllers.remove(id);
    controller?.dispose();
  }

  /// Dispose oldest controller to free memory
  static void _disposeOldestController() {
    if (_controllers.isEmpty) return;

    final oldestKey = _controllers.keys.first;
    disposeController(oldestKey);
  }

  /// Dispose all controllers
  static void disposeAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  /// Get current controller count
  static int getControllerCount() {
    return _controllers.length;
  }
}

/// Adaptive loading animation
class AdaptiveLoadingAnimation extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration? duration;

  const AdaptiveLoadingAnimation({
    Key? key,
    this.size = 40.0,
    this.color,
    this.duration,
  }) : super(key: key);

  @override
  State<AdaptiveLoadingAnimation> createState() =>
      _AdaptiveLoadingAnimationState();
}

class _AdaptiveLoadingAnimationState extends State<AdaptiveLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    final detector = DevicePerformanceDetector.instance;

    // Skip complex animation for low-spec devices
    if (detector.isInitialized && detector.shouldUseSimplifiedUI()) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
      _controller.repeat();
    } else {
      _controller = AnimationController(
        duration: widget.duration ?? const Duration(milliseconds: 1200),
        vsync: this,
      );
      _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detector = DevicePerformanceDetector.instance;

    if (detector.isInitialized && detector.shouldUseSimplifiedUI()) {
      // Simple rotating container for low-spec
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _animation.value * 2.0 * 3.14159,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color ?? Colors.blue,
                  width: 3.0,
                ),
              ),
              child: Container(
                margin: EdgeInsets.all(widget.size * 0.2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color ?? Colors.blue,
                ),
              ),
            ),
          );
        },
      );
    }

    // Rich animation for high-spec devices
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            value: null, // Indeterminate
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.color ?? Colors.blue,
            ),
          ),
        );
      },
    );
  }
}

/// Performance monitoring for animations
class AnimationPerformanceMonitor {
  static final Map<String, DateTime> _animationStartTimes = {};
  static final Map<String, int> _frameSkipCounts = {};

  /// Start monitoring animation performance
  static void startAnimationMonitoring(String animationId) {
    _animationStartTimes[animationId] = DateTime.now();
    _frameSkipCounts[animationId] = 0;
  }

  /// Record frame skip
  static void recordFrameSkip(String animationId) {
    _frameSkipCounts[animationId] = (_frameSkipCounts[animationId] ?? 0) + 1;
  }

  /// End monitoring and get performance metrics
  static Map<String, dynamic> endAnimationMonitoring(String animationId) {
    final startTime = _animationStartTimes[animationId];
    final frameSkips = _frameSkipCounts[animationId] ?? 0;

    if (startTime == null) {
      return {'error': 'Monitoring not started for $animationId'};
    }

    final duration = DateTime.now().difference(startTime);

    // Clean up
    _animationStartTimes.remove(animationId);
    _frameSkipCounts.remove(animationId);

    return {
      'animationId': animationId,
      'duration': duration.inMilliseconds,
      'frameSkips': frameSkips,
      'averageFps': frameSkips > 0 ? 60 - frameSkips : 60,
    };
  }
}
