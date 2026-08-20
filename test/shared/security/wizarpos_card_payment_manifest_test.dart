import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  test('manifest queries the WizarPOS Card Payment companion app', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    final document = XmlDocument.parse(manifest.readAsStringSync());
    final packageNames = document
        .findAllElements('package')
        .map((element) => element.getAttribute('android:name'));

    expect(
      packageNames.where((name) => name == 'com.wizarpos.oxpay'),
      hasLength(1),
    );
  });
}
