import 'package:app/shared/utils/pref_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemInfo.platform, null);
  });

  test('requests the fixed WizarPOS Card Payment launch operation', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemInfo.platform, (call) async {
      receivedCall = call;
      return true;
    });

    final didOpen = await SystemInfo.openWizarPosCardPaymentApp();

    expect(didOpen, isTrue);
    expect(receivedCall?.method, 'openWizarPosCardPaymentApp');
    expect(receivedCall?.arguments, isNull);
  });

  test('returns false when native launcher reports failure', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemInfo.platform, (_) async => false);

    expect(await SystemInfo.openWizarPosCardPaymentApp(), isFalse);
  });

  test('returns false when the platform channel throws', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemInfo.platform, (_) async {
      throw PlatformException(code: 'APP_LAUNCH_FAILED');
    });

    expect(await SystemInfo.openWizarPosCardPaymentApp(), isFalse);
  });
}
