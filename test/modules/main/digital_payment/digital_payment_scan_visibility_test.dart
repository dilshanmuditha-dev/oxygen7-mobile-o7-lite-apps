/// Unit tests for [isScanQrSupportedBrand] — the pure helper that decides
/// whether the Scan QR (Consumer-Presented Mode) button is shown in the GW3
/// digital payment layout.
///
/// Only Alipay, WeChat, and ShopeePay support scanning the customer's wallet
/// code, matched case-insensitively against the payment method brand OR title.
/// These tests mirror the legacy layout behavior and guard against the
/// 'shopee' keyword producing a false-positive for unrelated brands.

import 'package:flutter_test/flutter_test.dart';
import 'package:app/modules/main/digital_payment/digital_payment.dart';

void main() {
  group('isScanQrSupportedBrand', () {
    test('returns true for supported brands (case-insensitive)', () {
      expect(isScanQrSupportedBrand('Alipay', null), isTrue);
      expect(isScanQrSupportedBrand('ALIPAY', null), isTrue);
      expect(isScanQrSupportedBrand('WeChat Pay', null), isTrue);
      expect(isScanQrSupportedBrand('ShopeePay', null), isTrue);
    });

    test('returns true when only the title matches (brand null/empty)', () {
      expect(isScanQrSupportedBrand(null, 'WeChat Pay'), isTrue);
      expect(isScanQrSupportedBrand('', 'ShopeePay'), isTrue);
      expect(isScanQrSupportedBrand(null, 'Alipay'), isTrue);
    });

    test('returns false for unsupported brands', () {
      expect(isScanQrSupportedBrand('GrabPay', null), isFalse);
      expect(isScanQrSupportedBrand('Atome', 'Atome'), isFalse);
      expect(isScanQrSupportedBrand('PayNow', null), isFalse);
      expect(isScanQrSupportedBrand(null, null), isFalse);
    });

    test('does not false-positive "ShopBack" via the "shopee" keyword', () {
      expect(isScanQrSupportedBrand('ShopBack', null), isFalse);
      expect(isScanQrSupportedBrand(null, 'ShopBack'), isFalse);
    });
  });
}
