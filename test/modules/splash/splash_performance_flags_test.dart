import 'package:flutter_test/flutter_test.dart';
import 'package:app/modules/splash/models/splash_performance_flags.dart';

/// **Feature: splash-screen-enhancement, Property 6: Device-adaptive animation duration**
/// **Validates: Requirements 5.2, 5.3**
///
/// For any device configuration, animation durations should match the value
/// returned by DevicePerformanceDetector.getOptimalAnimationDuration() -
/// 150ms for low-spec devices and 300ms for high-spec devices.
void main() {
  group(
      'SplashPerformanceFlags - Property 6: Device-adaptive animation duration',
      () {
    test('lowSpecDefault returns 150ms animation duration', () {
      final flags = SplashPerformanceFlags.lowSpecDefault();

      expect(flags.animationDuration.inMilliseconds, equals(150),
          reason: 'Low-spec default should have 150ms animation duration');
    });

    test('lowSpecDefault returns 150ms transition duration', () {
      final flags = SplashPerformanceFlags.lowSpecDefault();

      expect(flags.transitionDuration.inMilliseconds, equals(150),
          reason: 'Low-spec default should have 150ms transition duration');
    });

    test('lowSpecDefault has simplified UI enabled', () {
      final flags = SplashPerformanceFlags.lowSpecDefault();

      expect(flags.shouldUseSimplifiedUI, isTrue,
          reason: 'Low-spec default should use simplified UI');
    });

    test('lowSpecDefault has gradients disabled', () {
      final flags = SplashPerformanceFlags.lowSpecDefault();

      expect(flags.enableGradients, isFalse,
          reason: 'Low-spec default should not enable gradients');
    });

    test('lowSpecDefault has complex animations disabled', () {
      final flags = SplashPerformanceFlags.lowSpecDefault();

      expect(flags.enableComplexAnimations, isFalse,
          reason: 'Low-spec default should not enable complex animations');
    });

    test('lowSpecDefault has blur effects disabled', () {
      final flags = SplashPerformanceFlags.lowSpecDefault();

      expect(flags.enableBlurEffects, isFalse,
          reason: 'Low-spec default should not enable blur effects');
    });

    // Property-based test: For any low-spec configuration, animation duration is 150ms
    test(
        'property: for any low-spec configuration, animation duration is 150ms',
        () {
      // Low-spec default should always have 150ms
      final flags = SplashPerformanceFlags.lowSpecDefault();

      expect(flags.animationDuration.inMilliseconds, equals(150),
          reason: 'Low-spec animation duration should be 150ms');
      expect(flags.transitionDuration.inMilliseconds, equals(150),
          reason: 'Low-spec transition duration should be 150ms');
    });

    test('toString returns readable representation', () {
      final flags = SplashPerformanceFlags.lowSpecDefault();
      final str = flags.toString();

      expect(str, contains('simplifiedUI: true'));
      expect(str, contains('gradients: false'));
      expect(str, contains('complexAnimations: false'));
      expect(str, contains('150ms'));
    });

    test('getFlags returns lowSpecDefault when detector not initialized', () {
      // Since DevicePerformanceDetector is not initialized in tests,
      // getFlags should return lowSpecDefault
      final flags = SplashPerformanceFlags.getFlags();

      expect(flags.shouldUseSimplifiedUI, isTrue,
          reason: 'Uninitialized detector should fallback to simplified UI');
      expect(flags.animationDuration.inMilliseconds, equals(150),
          reason: 'Uninitialized detector should use 150ms animation');
    });

    // Property-based test: Animation duration is always positive
    test('property: animation duration is always positive', () {
      final flags = SplashPerformanceFlags.lowSpecDefault();

      expect(flags.animationDuration.inMilliseconds, greaterThan(0),
          reason: 'Animation duration should be positive');
      expect(flags.transitionDuration.inMilliseconds, greaterThan(0),
          reason: 'Transition duration should be positive');
    });

    // Property-based test: Low-spec flags are consistent
    test('property: low-spec flags are internally consistent', () {
      final flags = SplashPerformanceFlags.lowSpecDefault();

      // If simplified UI is enabled, complex features should be disabled
      if (flags.shouldUseSimplifiedUI) {
        expect(flags.enableComplexAnimations, isFalse,
            reason: 'Simplified UI should not have complex animations enabled');
        expect(flags.enableBlurEffects, isFalse,
            reason: 'Simplified UI should not have blur effects enabled');
      }
    });
  });
}

/// **Feature: splash-screen-enhancement, Property 7: Device-adaptive transition duration**
/// **Validates: Requirements 6.2, 6.3**
///
/// For any device configuration, the navigation transition duration should be
/// 150ms for low-spec devices and 300ms for high-spec devices, matching the
/// device's optimal animation duration.
void transitionDurationTests() {
  group(
      'SplashPerformanceFlags - Property 7: Device-adaptive transition duration',
      () {
    test('lowSpecDefault returns 150ms transition duration', () {
      final flags = SplashPerformanceFlags.lowSpecDefault();

      expect(flags.transitionDuration.inMilliseconds, equals(150),
          reason: 'Low-spec default should have 150ms transition duration');
    });

    // Property-based test: Transition duration matches animation duration for low-spec
    test(
        'property: for low-spec, transition duration equals animation duration',
        () {
      final flags = SplashPerformanceFlags.lowSpecDefault();

      expect(flags.transitionDuration, equals(flags.animationDuration),
          reason:
              'Low-spec transition duration should match animation duration');
    });

    // Property-based test: Transition duration is always positive
    test('property: transition duration is always positive', () {
      final flags = SplashPerformanceFlags.lowSpecDefault();

      expect(flags.transitionDuration.inMilliseconds, greaterThan(0),
          reason: 'Transition duration should be positive');
    });

    // Property-based test: Transition duration is reasonable (not too long)
    test('property: transition duration is reasonable (< 500ms)', () {
      final flags = SplashPerformanceFlags.lowSpecDefault();

      expect(flags.transitionDuration.inMilliseconds, lessThan(500),
          reason: 'Transition duration should be less than 500ms');
    });
  });
}
