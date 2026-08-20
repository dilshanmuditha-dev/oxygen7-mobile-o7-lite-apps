// Feature: 18-hardcoded-string-localization, Property 4: Locale file key parity
// **Validates: Requirements 3.2, 3.4**

import 'package:flutter_test/flutter_test.dart';

import 'package:app/lang/value/en_US.dart';
import 'package:app/lang/value/ar_SA.dart';
import 'package:app/lang/value/bn_BD.dart';
import 'package:app/lang/value/cn_CN.dart';
import 'package:app/lang/value/es_ES.dart';
import 'package:app/lang/value/fr_FR.dart';
import 'package:app/lang/value/hi_IN.dart';
import 'package:app/lang/value/ja_JA.dart';
import 'package:app/lang/value/ko_KO.dart';
import 'package:app/lang/value/ms_MS.dart';
import 'package:app/lang/value/pt_PT.dart';
import 'package:app/lang/value/ru_RU.dart';
import 'package:app/lang/value/th_TH.dart';
import 'package:app/lang/value/ur_PK.dart';
import 'package:app/lang/value/vi_VN.dart';

void main() {
  /// All locale maps keyed by their locale identifier.
  final Map<String, Map<String, String>> locales = {
    'en_US': en,
    'ar_SA': ar,
    'bn_BD': bn,
    'cn_CN': cn,
    'es_ES': es,
    'fr_FR': fr,
    'hi_IN': hi,
    'ja_JA': ja,
    'ko_KO': ko,
    'ms_MS': ms,
    'pt_PT': pt,
    'ru_RU': ru,
    'th_TH': th,
    'ur_PK': ur,
    'vi_VN': vi,
  };

  final Set<String> primaryKeys = en.keys.toSet();

  group('Property 4: Locale file key parity', () {
    test('all 15 locale files are loaded', () {
      expect(locales.length, equals(15));
    });

    for (final entry in locales.entries) {
      final localeName = entry.key;
      final localeMap = entry.value;

      if (localeName == 'en_US') continue;

      test('$localeName contains every key from en_US (primary)', () {
        final localeKeys = localeMap.keys.toSet();
        final missingInLocale = primaryKeys.difference(localeKeys);

        expect(
          missingInLocale,
          isEmpty,
          reason:
              '$localeName is missing ${missingInLocale.length} key(s) from en_US: '
              '${missingInLocale.take(10).toList()}',
        );
      });

      test('$localeName has no extra keys beyond en_US (primary)', () {
        final localeKeys = localeMap.keys.toSet();
        final extraInLocale = localeKeys.difference(primaryKeys);

        expect(
          extraInLocale,
          isEmpty,
          reason:
              '$localeName has ${extraInLocale.length} extra key(s) not in en_US: '
              '${extraInLocale.take(10).toList()}',
        );
      });
    }

    test('all locale files have the same number of keys as en_US', () {
      for (final entry in locales.entries) {
        expect(
          entry.value.length,
          equals(en.length),
          reason:
              '${entry.key} has ${entry.value.length} keys but en_US has ${en.length}',
        );
      }
    });
  });
}
