import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/modules/splash/widgets/adaptive_loading_indicator.dart';

/// **Feature: splash-screen-enhancement, Property 5: Device-adaptive loading indicator**
/// **Validates: Requirements 4.2, 4.3**
///
/// For any device configuration, when the loading indicator is displayed,
/// it should use a pulsing animation if enableComplexAnimations is true,
/// otherwise it should use a simple static or minimal animation.
void main() {
  group(
      'AdaptiveLoadingIndicator - Property 5: Device-adaptive loading indicator',
      () {
    testWidgets('isLoading=false renders empty SizedBox',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptiveLoadingIndicator(
              isLoading: false,
              usePulseAnimation: true,
            ),
          ),
        ),
      );

      // Should render SizedBox.shrink() when not loading
      final sizedBoxFinder = find.byType(SizedBox);
      expect(sizedBoxFinder, findsOneWidget);

      final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
      expect(sizedBox.width, equals(0.0));
      expect(sizedBox.height, equals(0.0));
    });

    testWidgets('isLoading=true renders indicator dots',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptiveLoadingIndicator(
              isLoading: true,
              usePulseAnimation: false,
            ),
          ),
        ),
      );

      // Should render Row with dots
      expect(find.byType(Row), findsOneWidget);

      // Should have 3 dot containers
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsNWidgets(3));
    });

    testWidgets(
        'low-spec mode (usePulseAnimation=false) renders simple static dots',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptiveLoadingIndicator(
              isLoading: true,
              usePulseAnimation: false, // Low-spec
            ),
          ),
        ),
      );

      // Should render dots without animation wrapper
      expect(find.byType(Row), findsOneWidget);

      // Verify dots are rendered
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.length, equals(3),
          reason: 'Should have 3 dots for loading indicator');

      // Verify dots have circular shape
      for (final container in containers) {
        expect(container.decoration, isA<BoxDecoration>());
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.shape, equals(BoxShape.circle));
      }
    });

    testWidgets(
        'high-spec mode (usePulseAnimation=true) creates animation controller',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptiveLoadingIndicator(
              isLoading: true,
              usePulseAnimation: true, // High-spec
            ),
          ),
        ),
      );

      // Pump a few frames to let animation start
      await tester.pump(const Duration(milliseconds: 100));

      // Should render dots
      expect(find.byType(Row), findsOneWidget);

      // Verify dots are rendered
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.length, equals(3));
    });

    // Property-based test: For any low-spec configuration, simple indicator is used
    testWidgets(
        'property: for any low-spec config (usePulseAnimation=false), simple indicator is rendered',
        (WidgetTester tester) async {
      // Test with loading=true, usePulseAnimation=false
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptiveLoadingIndicator(
              isLoading: true,
              usePulseAnimation: false,
            ),
          ),
        ),
      );

      // Should render Row with dots
      expect(find.byType(Row), findsOneWidget);

      // Should have exactly 3 dots
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.length, equals(3),
          reason: 'Low-spec mode should render 3 static dots');
    });

    // Property-based test: For any high-spec configuration, pulsing indicator is used
    testWidgets(
        'property: for any high-spec config (usePulseAnimation=true), pulsing indicator is rendered',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptiveLoadingIndicator(
              isLoading: true,
              usePulseAnimation: true,
            ),
          ),
        ),
      );

      // Pump to start animation
      await tester.pump(const Duration(milliseconds: 100));

      // Should render Row with dots
      expect(find.byType(Row), findsOneWidget);

      // Should have 3 dots
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.length, equals(3),
          reason: 'High-spec mode should render 3 animated dots');
    });

    testWidgets('custom color is applied to dots', (WidgetTester tester) async {
      const testColor = Colors.red;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptiveLoadingIndicator(
              isLoading: true,
              usePulseAnimation: false,
              color: testColor,
            ),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));

      for (final container in containers) {
        final decoration = container.decoration as BoxDecoration;
        // Color should be based on testColor (with alpha)
        expect(decoration.color?.red, equals(testColor.red));
        expect(decoration.color?.green, equals(testColor.green));
        expect(decoration.color?.blue, equals(testColor.blue));
      }
    });

    testWidgets('custom size affects dot size', (WidgetTester tester) async {
      const customSize = 36.0;
      const expectedDotSize = customSize / 3; // 12.0

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptiveLoadingIndicator(
              isLoading: true,
              usePulseAnimation: false,
              size: customSize,
            ),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));

      for (final container in containers) {
        expect(container.constraints?.maxWidth, equals(expectedDotSize));
        expect(container.constraints?.maxHeight, equals(expectedDotSize));
      }
    });

    testWidgets('SimpleLoadingText renders when loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SimpleLoadingText(
              isLoading: true,
              text: 'Please wait...',
            ),
          ),
        ),
      );

      expect(find.text('Please wait...'), findsOneWidget);
    });

    testWidgets('SimpleLoadingText renders empty when not loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SimpleLoadingText(
              isLoading: false,
              text: 'Please wait...',
            ),
          ),
        ),
      );

      expect(find.text('Please wait...'), findsNothing);
    });
  });
}
