import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WizarPOS min SDK bypasses Flutter literal migration', () {
    final source = File('android/app/build.gradle.kts').readAsStringSync();

    expect(source, contains('val wizarPosMinSdk = 23'));
    expect(source, contains('minSdk = wizarPosMinSdk'));
    expect(source, isNot(contains('minSdk = 23//flutter.minSdkVersion')));
  });
}
