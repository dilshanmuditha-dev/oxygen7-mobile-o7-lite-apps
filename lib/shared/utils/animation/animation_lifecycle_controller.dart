import 'package:flutter/widgets.dart';

/// Controller for managing animation lifecycle.
///
/// Handles pause/resume on app background/foreground transitions to conserve
/// resources when the app is not visible. Implements [WidgetsBindingObserver]
/// to listen for app lifecycle state changes.
///
/// **Requirements:** 2.7, 5.1, 5.2, 5.3
///
/// Usage:
/// ```dart
/// class MyAnimatedWidget extends StatefulWidget {
///   @override
///   State<MyAnimatedWidget> createState() => _MyAnimatedWidgetState();
/// }
///
/// class _MyAnimatedWidgetState extends State<MyAnimatedWidget>
///     with SingleTickerProviderStateMixin {
///   late AnimationController _animationController;
///   late AnimationLifecycleController _lifecycleController;
///
///   @override
///   void initState() {
///     super.initState();
///     _animationController = AnimationController(
///       duration: const Duration(seconds: 3),
///       vsync: this,
///     );
///     _lifecycleController = AnimationLifecycleController(
///       animationController: _animationController,
///     );
///     _lifecycleController.initialize();
///     _animationController.repeat();
///   }
///
///   @override
///   void dispose() {
///     _lifecycleController.dispose();
///     _animationController.dispose();
///     super.dispose();
///   }
/// }
/// ```
class AnimationLifecycleController with WidgetsBindingObserver {
  /// The animation controller to manage.
  final AnimationController animationController;

  /// Whether the animation is currently paused due to lifecycle events.
  bool _isPaused = false;

  /// Whether the animation was running before being paused.
  ///
  /// Used to determine if animation should resume when app returns to foreground.
  bool _wasAnimatingBeforePause = false;

  /// Whether this controller has been initialized.
  bool _isInitialized = false;

  /// Whether this controller has been disposed.
  bool _isDisposed = false;

  /// Creates a new [AnimationLifecycleController].
  ///
  /// The [animationController] parameter is required and represents the
  /// animation controller that will be managed by this lifecycle controller.
  AnimationLifecycleController({
    required this.animationController,
  });

  /// Whether the animation is currently paused.
  ///
  /// Returns `true` if the animation was paused due to app lifecycle events
  /// (e.g., app went to background).
  bool get isPaused => _isPaused;

  /// Whether this controller has been initialized.
  bool get isInitialized => _isInitialized;

  /// Whether this controller has been disposed.
  bool get isDisposed => _isDisposed;

  /// Initializes the lifecycle controller.
  ///
  /// Registers this controller as a [WidgetsBindingObserver] to receive
  /// app lifecycle state change notifications.
  ///
  /// Must be called before the controller can respond to lifecycle events.
  /// Typically called in [State.initState].
  ///
  /// **Requirement 5.1:** Proper initialization for lifecycle management.
  void initialize() {
    if (_isInitialized || _isDisposed) {
      return;
    }

    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
  }

  /// Disposes the lifecycle controller.
  ///
  /// Removes this controller from the [WidgetsBindingObserver] list and
  /// cleans up resources. After disposal, this controller cannot be used.
  ///
  /// Must be called when the animation is no longer needed.
  /// Typically called in [State.dispose].
  ///
  /// **Requirement 5.1:** When screen with wave animation is disposed,
  /// properly dispose all animation controllers.
  void dispose() {
    if (_isDisposed) {
      return;
    }

    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
    _isDisposed = true;
  }

  /// Pauses the animation.
  ///
  /// Stops the animation controller and marks the animation as paused.
  /// Records whether the animation was running before pause to enable
  /// proper resume behavior.
  ///
  /// **Requirement 2.7:** When app is in background, pause all animations
  /// to conserve resources.
  ///
  /// **Requirement 5.2:** When app enters background state, pause all
  /// running animations.
  void pause() {
    if (_isPaused || _isDisposed) {
      return;
    }

    _wasAnimatingBeforePause = animationController.isAnimating;
    if (_wasAnimatingBeforePause) {
      animationController.stop();
    }
    _isPaused = true;
  }

  /// Resumes the animation.
  ///
  /// Restarts the animation controller if it was running before being paused.
  /// Only resumes if the animation was previously paused by this controller.
  ///
  /// **Requirement 5.3:** When app returns to foreground, resume paused
  /// animations.
  void resume() {
    if (!_isPaused || _isDisposed) {
      return;
    }

    if (_wasAnimatingBeforePause) {
      animationController.repeat();
    }
    _isPaused = false;
  }

  /// Handles app lifecycle state changes.
  ///
  /// Called by the Flutter framework when the app lifecycle state changes.
  /// Pauses animations when the app goes to background (paused or inactive)
  /// and resumes them when the app returns to foreground (resumed).
  ///
  /// **Requirement 2.7:** When app is in background, pause all animations
  /// to conserve resources.
  ///
  /// **Requirement 5.2:** When app enters background state, pause all
  /// running animations.
  ///
  /// **Requirement 5.3:** When app returns to foreground, resume paused
  /// animations.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) {
      return;
    }

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is going to background or being hidden
        pause();
        break;
      case AppLifecycleState.resumed:
        // App is returning to foreground
        resume();
        break;
    }
  }
}
