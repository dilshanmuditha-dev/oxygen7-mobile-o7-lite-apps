import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/modules/splash/widgets/adaptive_splash_background.dart';
import 'package:app/modules/splash/models/splash_color_scheme.dart';

/// **Feature: splash-screen-enhancement, Property 1: Low-spec device simplified rendering**
/// **Validates: Requirements 2.1, 2.2, 2.3**
///
/// For any device configuration where shouldUseSimplifiedUI() returns true,
/// the splash screen should render without animated decorations, particle effects,
/// or gradient backgrounds - using only solid colors and static elements.
void main() {
  group(
      'AdaptiveSplashBackground - Property 1: Low-spec device simplified rendering',
      () {
    testWidgets('low-spec mode (useGradient=false) renders solid background',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveSplashBackground(
            useGradient: false,
            isDarkMode: false,
          ),
        ),
      );

      // Find the Container widget
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      // Get the Container widget
      final container = tester.widget<Container>(containerFinder);

      // Verify it uses solid color (no gradient decoration)
      expect(container.decoration, isNull,
          reason: 'Low-spec mode should not use BoxDecoration with gradient');
      expect(container.color, isNotNull,
          reason: 'Low-spec mode should use solid color');
    });

    testWidgets('high-spec mode (useGradient=true) renders gradient background',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveSplashBackground(
            useGradient: true,
            isDarkMode: false,
          ),
        ),
      );

      // Find the Container widget
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      // Get the Container widget
      final container = tester.widget<Container>(containerFinder);

      // Verify it uses gradient decoration
      expect(container.decoration, isNotNull,
          reason: 'High-spec mode should use BoxDecoration');
      expect(container.decoration, isA<BoxDecoration>());

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull,
          reason: 'High-spec mode should have gradient');
      expect(decoration.gradient, isA<LinearGradient>());
    });

    // Property-based test: For any low-spec configuration, no gradient is used
    testWidgets(
        'property: for any low-spec config (useGradient=false), solid color is used',
        (WidgetTester tester) async {
      // Test both dark and light modes with low-spec setting
      for (final isDarkMode in [true, false]) {
        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveSplashBackground(
              useGradient: false, // Low-spec
              isDarkMode: isDarkMode,
            ),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final modeName = isDarkMode ? 'dark' : 'light';

        // Low-spec should always use solid color, never gradient
        expect(container.decoration, isNull,
            reason:
                'Low-spec $modeName mode should not use BoxDecoration with gradient');
        expect(container.color, isNotNull,
            reason: 'Low-spec $modeName mode should use solid color');
      }
    });

    // Property-based test: For any high-spec configuration, gradient is used
    testWidgets(
        'property: for any high-spec config (useGradient=true), gradient is used',
        (WidgetTester tester) async {
      // Test both dark and light modes with high-spec setting
      for (final isDarkMode in [true, false]) {
        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveSplashBackground(
              useGradient: true, // High-spec
              isDarkMode: isDarkMode,
            ),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final modeName = isDarkMode ? 'dark' : 'light';

        // High-spec should always use gradient
        expect(container.decoration, isNotNull,
            reason: 'High-spec $modeName mode should use BoxDecoration');

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.gradient, isNotNull,
            reason: 'High-spec $modeName mode should have gradient');
      }
    });

    testWidgets('child widget is rendered correctly',
        (WidgetTester tester) async {
      const testKey = Key('test_child');

      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveSplashBackground(
            useGradient: false,
            isDarkMode: false,
            child: Text('Test Child', key: testKey),
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('uses correct colors from SplashColorScheme',
        (WidgetTester tester) async {
      // Test light mode solid background
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveSplashBackground(
            useGradient: false,
            isDarkMode: false,
          ),
        ),
      );

      final lightContainer = tester.widget<Container>(find.byType(Container));
      final lightScheme = SplashColorScheme.light();
      expect(lightContainer.color, equals(lightScheme.backgroundColor));

      // Test dark mode solid background
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveSplashBackground(
            useGradient: false,
            isDarkMode: true,
          ),
        ),
      );

      final darkContainer = tester.widget<Container>(find.byType(Container));
      final darkScheme = SplashColorScheme.dark();
      expect(darkContainer.color, equals(darkScheme.backgroundColor));
    });
  });
}
