import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/route_payment_model.dart';

/// **Feature: multi-currency-selector, Property 1: Supported currencies preservation**
/// **Validates: Requirements 1.1**
///
/// For any Route with a non-empty currencies list, when converted to RoutePaymentModel,
/// the supportedCurrencies field SHALL contain all currencies from the original Route.
void main() {
  group('RoutePaymentModel - Supported Currencies Preservation', () {
    test(
        'should preserve all supported currencies when created with currency list',
        () {
      // Arrange
      final currencies = ['SGD', 'MYR', 'USD'];

      // Act
      final model = RoutePaymentModel(
        image: 'test_image.png',
        acquireReport: 'test_host',
        isActivated: true,
        currency: 'SGD',
        supportedCurrencies: currencies,
      );

      // Assert
      expect(model.supportedCurrencies, isNotNull);
      expect(model.supportedCurrencies!.length, equals(3));
      expect(model.supportedCurrencies, containsAll(['SGD', 'MYR', 'USD']));
    });

    test('should preserve currency order in supportedCurrencies list', () {
      // Arrange
      final currencies = ['MYR', 'SGD', 'THB', 'USD'];

      // Act
      final model = RoutePaymentModel(
        image: 'test_image.png',
        acquireReport: 'test_host',
        isActivated: true,
        currency: 'MYR',
        supportedCurrencies: currencies,
      );

      // Assert
      expect(model.supportedCurrencies![0], equals('MYR'));
      expect(model.supportedCurrencies![1], equals('SGD'));
      expect(model.supportedCurrencies![2], equals('THB'));
      expect(model.supportedCurrencies![3], equals('USD'));
    });

    test('should handle single currency in supportedCurrencies', () {
      // Arrange
      final currencies = ['SGD'];

      // Act
      final model = RoutePaymentModel(
        image: 'test_image.png',
        acquireReport: 'test_host',
        isActivated: true,
        currency: 'SGD',
        supportedCurrencies: currencies,
      );

      // Assert
      expect(model.supportedCurrencies!.length, equals(1));
      expect(model.supportedCurrencies!.first, equals('SGD'));
    });

    test('should handle null supportedCurrencies for backward compatibility',
        () {
      // Act
      final model = RoutePaymentModel(
        image: 'test_image.png',
        acquireReport: 'test_host',
        isActivated: true,
        currency: 'SGD',
      );

      // Assert
      expect(model.supportedCurrencies, isNull);
      expect(model.currency, equals('SGD'));
    });

    test('should handle empty supportedCurrencies list', () {
      // Arrange
      final currencies = <String>[];

      // Act
      final model = RoutePaymentModel(
        image: 'test_image.png',
        acquireReport: 'test_host',
        isActivated: true,
        currency: 'SGD',
        supportedCurrencies: currencies,
      );

      // Assert
      expect(model.supportedCurrencies, isNotNull);
      expect(model.supportedCurrencies!.isEmpty, isTrue);
    });

    test('should preserve both currency and supportedCurrencies independently',
        () {
      // Arrange - currency might differ from first in supportedCurrencies
      final currencies = ['MYR', 'SGD', 'USD'];

      // Act
      final model = RoutePaymentModel(
        image: 'test_image.png',
        acquireReport: 'test_host',
        isActivated: true,
        currency: 'SGD', // Different from first in list
        supportedCurrencies: currencies,
      );

      // Assert
      expect(model.currency, equals('SGD'));
      expect(model.supportedCurrencies!.first, equals('MYR'));
      expect(model.supportedCurrencies!.contains(model.currency), isTrue);
    });
  });
}
