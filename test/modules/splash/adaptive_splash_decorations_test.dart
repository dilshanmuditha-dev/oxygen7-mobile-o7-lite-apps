import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/modules/splash/widgets/adaptive_splash_decorations.dart';

/// **Feature: splash-screen-enhancement, Property 2: High-spec device decorative elements**
/// **Validates: Requirements 1.4**
///
/// For any device configuration where shouldUseSimplifiedUI() returns false
/// and enableComplexAnimations is true, the splash screen should include
/// animated decorative elements such as floating particles or pulse effects.
void main() {
  group(
      'AdaptiveSplashDecorations - Property 2: High-spec device decorative elements',
      () {
    testWidgets('low-spec mode (enableAnimations=false) renders empty SizedBox',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptiveSplashDecorations(
              enableAnimations: false,
              isDarkMode: false,
            ),
          ),
        ),
      );

      // Should render SizedBox.shrink() for low-spec
      final sizedBoxFinder = find.byType(SizedBox);
      expect(sizedBoxFinder, findsOneWidget);

      final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
      expect(sizedBox.width, equals(0.0));
      expect(sizedBox.height, equals(0.0));
    });

    testWidgets(
        'high-spec mode (enableAnimations=true) renders decorative elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveSplashDecorations(
            enableAnimations: true,
            isDarkMode: false,
          ),
        ),
      );

      // Should render Stack with decorative elements
      final stackFinder = find.byType(Stack);
      expect(stackFinder, findsOneWidget);

      // Should have positioned containers for overlays
      final positionedFinder = find.byType(Positioned);
      expect(positionedFinder, findsAtLeastNWidgets(2),
          reason: 'High-spec mode should have at least 2 positioned overlays');
    });

    // Property-based test: For any low-spec configuration, no decorations
    testWidgets(
        'property: for any low-spec config (enableAnimations=false), no decorations rendered',
        (WidgetTester tester) async {
      for (final isDarkMode in [true, false]) {
        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveSplashDecorations(
              enableAnimations: false, // Low-spec
              isDarkMode: isDarkMode,
            ),
          ),
        );

        final modeName = isDarkMode ? 'dark' : 'light';

        // Should always render empty SizedBox for low-spec
        final sizedBoxFinder = find.byType(SizedBox);
        expect(sizedBoxFinder, findsOneWidget,
            reason: 'Low-spec $modeName mode should render SizedBox');

        // Should NOT render Stack with decorations (AdaptiveSplashDecorations returns SizedBox.shrink)
        final stackFinder = find.byType(Stack);
        expect(stackFinder, findsNothing,
            reason:
                'Low-spec $modeName mode should not render Stack with decorations');
      }
    });

    // Property-based test: For any high-spec configuration, decorations are present
    testWidgets(
        'property: for any high-spec config (enableAnimations=true), decorations are rendered',
        (WidgetTester tester) async {
      for (final isDarkMode in [true, false]) {
        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveSplashDecorations(
              enableAnimations: true, // High-spec
              isDarkMode: isDarkMode,
            ),
          ),
        );

        final modeName = isDarkMode ? 'dark' : 'light';

        // Should render Stack with decorations
        final stackFinder = find.byType(Stack);
        expect(stackFinder, findsOneWidget,
            reason: 'High-spec $modeName mode should render Stack');

        // Should have positioned overlays
        final positionedFinder = find.byType(Positioned);
        expect(positionedFinder, findsAtLeastNWidgets(2),
            reason: 'High-spec $modeName mode should have positioned overlays');

        // Should have circular containers
        final containerFinder = find.byType(Container);
        expect(containerFinder, findsAtLeastNWidgets(2),
            reason: 'High-spec $modeName mode should have circular containers');
      }
    });

    testWidgets('decorations include circular gradient overlays',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveSplashDecorations(
            enableAnimations: true,
            isDarkMode: false,
          ),
        ),
      );

      // Find containers with BoxDecoration
      final containers = tester.widgetList<Container>(find.byType(Container));

      bool hasCircularDecoration = false;
      for (final container in containers) {
        if (container.decoration is BoxDecoration) {
          final decoration = container.decoration as BoxDecoration;
          if (decoration.shape == BoxShape.circle) {
            hasCircularDecoration = true;
            break;
          }
        }
      }

      expect(hasCircularDecoration, isTrue,
          reason: 'High-spec mode should have circular decorations');
    });

    testWidgets('StaticSplashDecorations renders simple overlay',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StaticSplashDecorations(
            isDarkMode: false,
          ),
        ),
      );

      // Should render Stack
      expect(find.byType(Stack), findsOneWidget);

      // Should have positioned element
      expect(find.byType(Positioned), findsOneWidget);
    });
  });
}
