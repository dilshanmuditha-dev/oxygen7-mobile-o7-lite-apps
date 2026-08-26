import 'dart:io';

import 'package:app/models/response/route.dart';
import 'package:app/modules/main/home_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WizarPOS card payment route classification', () {
    test('matches Visa and Mastercard brands without case sensitivity', () {
      expect(isCardPaymentBrand('VISA'), isTrue);
      expect(isCardPaymentBrand('Visa Credit'), isTrue);
      expect(isCardPaymentBrand('masterCARD Debit'), isTrue);
      expect(isCardPaymentBrand('Visa/Mastercard'), isTrue);
      expect(isCardPaymentBrand('Alipay'), isFalse);
    });

    test('excludes card routes from wallet display', () {
      final route = Route(
        brand: 'Visa/Mastercard',
        host: 'card-host',
        currencies: ['SGD'],
        isActive: true,
      );

      expect(isValidGw3WalletRoute(route), isFalse);
    });

    test('preserves existing active route and host filters', () {
      Route route({
        required String brand,
        required String host,
        required bool isActive,
      }) {
        return Route(
          brand: brand,
          host: host,
          currencies: ['SGD'],
          isActive: isActive,
        );
      }

      expect(
        isValidGw3WalletRoute(
          route(brand: 'Alipay', host: 'alipay-host', isActive: true),
        ),
        isTrue,
      );
      expect(
        isValidGw3WalletRoute(
          route(brand: 'Alipay', host: 'alipay-host', isActive: false),
        ),
        isFalse,
      );
      expect(
        isValidGw3WalletRoute(
          route(brand: 'GrabPay', host: 'grabpay-online', isActive: true),
        ),
        isFalse,
      );
    });

    test('enables card payment only for WizarPOS with a qualifying route', () {
      final cardRoute = Route(
        brand: 'VISA Credit',
        host: 'card-host',
        currencies: ['SGD'],
        isActive: true,
      );
      final inactiveCardRoute = Route(
        brand: 'Mastercard',
        host: 'card-host',
        currencies: ['SGD'],
        isActive: false,
      );

      expect(
        shouldEnableWizarPosCardPayment([cardRoute], isWizarPos: true),
        isTrue,
      );
      expect(
        shouldEnableWizarPosCardPayment([cardRoute], isWizarPos: false),
        isFalse,
      );
      expect(
        shouldEnableWizarPosCardPayment(
          [inactiveCardRoute],
          isWizarPos: true,
        ),
        isFalse,
      );
      expect(
        shouldEnableWizarPosCardPayment(const [], isWizarPos: true),
        isFalse,
      );
    });

    test('HomeController force-disables card payment in the demo build', () {
      final source =
          File('lib/modules/main/home_controller.dart').readAsStringSync();

      expect(
        source,
        contains('final RxBool hasEnabledCardPayment = false.obs;'),
      );
      // Demo build: acquirer routes are ignored and Ripple is the only
      // wallet on offer, so card payment is pinned off rather than derived
      // from the terminal's routes.
      expect(source, contains('hasEnabledCardPayment.value = false;'));
      expect(source, contains('_setDemoWalletList()'));
      expect(source, isNot(contains('.where(isValidGw3WalletRoute)')));
    });
  });
}
