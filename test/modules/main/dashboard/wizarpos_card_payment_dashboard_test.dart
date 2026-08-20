import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard exposes reactive WizarPOS Card Payment action', () {
    final source = File(
      'lib/modules/main/tabs/dashboard/dashboard_screen.dart',
    ).readAsStringSync();

    expect(source, contains("ValueKey('wizarpos_card_payment_figma')"));
    expect(source, contains('controller.hasEnabledCardPayment.value'));
    expect(source, contains('SystemInfo.openWizarPosCardPaymentApp()'));
    expect(source, contains('if (didOpen) return;'));
    expect(source, isNot(contains('LaunchApp.isAppInstalled')));
    expect(source, contains('CustomAlertDialog'));
    expect(
      source,
      contains('Card Payment app is not installed. Please contact support.'),
    );
  });
}
