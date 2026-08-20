import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/shared/widgets/currency_selector.dart';

void main() {
  group('CurrencySelectorWidget', () {
    testWidgets('should display selected currency', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencySelectorWidget(
              selectedCurrency: 'SGD',
              supportedCurrencies: ['SGD', 'MYR', 'USD'],
              onCurrencyChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('SGD'), findsOneWidget);
    });

    testWidgets('should show dropdown indicator when multiple currencies',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencySelectorWidget(
              selectedCurrency: 'SGD',
              supportedCurrencies: ['SGD', 'MYR', 'USD'],
              onCurrencyChanged: (_) {},
            ),
          ),
        ),
      );

      // Should find dropdown arrow icon
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('should hide dropdown indicator when single currency',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencySelectorWidget(
              selectedCurrency: 'SGD',
              supportedCurrencies: ['SGD'],
              onCurrencyChanged: (_) {},
            ),
          ),
        ),
      );

      // Should not find dropdown arrow icon
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
    });

    testWidgets('should open dropdown on tap when multiple currencies',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencySelectorWidget(
              selectedCurrency: 'SGD',
              supportedCurrencies: ['SGD', 'MYR', 'USD'],
              onCurrencyChanged: (_) {},
            ),
          ),
        ),
      );

      // Tap on the selector
      await tester.tap(find.text('SGD'));
      await tester.pumpAndSettle();

      // Should show all currencies in dropdown
      expect(
          find.text('SGD'), findsWidgets); // One in selector, one in dropdown
      expect(find.text('MYR'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
    });

    testWidgets('should call onCurrencyChanged when currency selected',
        (tester) async {
      String? selectedCurrency;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencySelectorWidget(
              selectedCurrency: 'SGD',
              supportedCurrencies: ['SGD', 'MYR', 'USD'],
              onCurrencyChanged: (currency) {
                selectedCurrency = currency;
              },
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.text('SGD'));
      await tester.pumpAndSettle();

      // Select MYR
      await tester.tap(find.text('MYR'));
      await tester.pumpAndSettle();

      expect(selectedCurrency, equals('MYR'));
    });

    testWidgets('should not open dropdown when single currency',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencySelectorWidget(
              selectedCurrency: 'SGD',
              supportedCurrencies: ['SGD'],
              onCurrencyChanged: (_) {},
            ),
          ),
        ),
      );

      // Tap on the selector
      await tester.tap(find.text('SGD'));
      await tester.pumpAndSettle();

      // Should only find one SGD (no dropdown opened)
      expect(find.text('SGD'), findsOneWidget);
    });

    testWidgets('should close dropdown when tapping outside', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CurrencySelectorWidget(
                  selectedCurrency: 'SGD',
                  supportedCurrencies: ['SGD', 'MYR', 'USD'],
                  onCurrencyChanged: (_) {},
                ),
                const SizedBox(height: 200),
                const Text('Outside area'),
              ],
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.text('SGD'));
      await tester.pumpAndSettle();

      // Verify dropdown is open
      expect(find.text('MYR'), findsOneWidget);

      // Tap outside (on the transparent overlay)
      await tester.tapAt(const Offset(100, 300));
      await tester.pumpAndSettle();

      // Dropdown should be closed
      expect(find.text('MYR'), findsNothing);
    });

    testWidgets('should highlight selected currency in dropdown',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencySelectorWidget(
              selectedCurrency: 'MYR',
              supportedCurrencies: ['SGD', 'MYR', 'USD'],
              onCurrencyChanged: (_) {},
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.text('MYR'));
      await tester.pumpAndSettle();

      // Should show check icon for selected currency
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('should work in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencySelectorWidget(
              selectedCurrency: 'SGD',
              supportedCurrencies: ['SGD', 'MYR'],
              onCurrencyChanged: (_) {},
              isDarkMode: true,
            ),
          ),
        ),
      );

      expect(find.text('SGD'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });
  });
}
