import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('POS activity launches OxPay with round-trip task flags', () {
    final activity = File(
      'android/app/src/pos/kotlin/com/oxpay/o7lite/MainActivityRefactored.kt',
    ).readAsStringSync();
    final methodTypes = File(
      'android/app/src/main/kotlin/com/oxpay/o7lite/enums/MethodChannelType.kt',
    ).readAsStringSync();

    expect(
      methodTypes,
      contains(
        'OPEN_WIZARPOS_CARD_PAYMENT_APP("openWizarPosCardPaymentApp")',
      ),
    );
    expect(activity, contains('"com.wizarpos.oxpay"'));
    expect(activity, contains('getLaunchIntentForPackage'));
    expect(activity, contains('Intent.FLAG_ACTIVITY_NEW_TASK'));
    expect(activity, contains('Intent.FLAG_ACTIVITY_CLEAR_TOP'));
    expect(activity, contains('Intent.FLAG_ACTIVITY_SINGLE_TOP'));
    expect(activity, contains('startActivity(launchIntent)'));
    expect(
      activity,
      contains('result.success(openWizarPosCardPaymentApp())'),
    );
  });
}
