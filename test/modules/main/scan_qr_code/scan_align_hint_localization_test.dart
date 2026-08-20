/// Locale coverage test for the `scanAlignHint` Align_Hint key.
///
/// **Validates: Requirements 9.4**
///
/// Feature: 30-qr-scanner-animated-overlay
///
/// The Align_Hint text (Requirement 9) is resolved through GetX localization
/// using the dedicated `scanAlignHint` key. Requirement 9.4 mandates that the
/// key be present in all 15 locale files, with the English value as the
/// canonical source (Req 9.5 relies on the English entry always existing so it
/// can serve as the fallback).
///
/// Rather than parsing the `.dart` files as text, each locale's exported
/// `const Map<String, String>` is imported statically (with a per-locale
/// prefix) and iterated. This keeps the check type-checked and robust: if a
/// locale file is renamed, removed, or its map variable changes, this test
/// fails to compile instead of silently passing.
///
/// `flutter_test` is used for consistency with the sibling geometry tests
/// (the locale maps themselves have no Flutter dependency).

import 'package:flutter_test/flutter_test.dart';

import 'package:app/lang/value/ar_SA.dart' as ar_sa;
import 'package:app/lang/value/bn_BD.dart' as bn_bd;
import 'package:app/lang/value/cn_CN.dart' as cn_cn;
import 'package:app/lang/value/en_US.dart' as en_us;
import 'package:app/lang/value/es_ES.dart' as es_es;
import 'package:app/lang/value/fr_FR.dart' as fr_fr;
import 'package:app/lang/value/hi_IN.dart' as hi_in;
import 'package:app/lang/value/ja_JA.dart' as ja_ja;
import 'package:app/lang/value/ko_KO.dart' as ko_ko;
import 'package:app/lang/value/ms_MS.dart' as ms_ms;
import 'package:app/lang/value/pt_PT.dart' as pt_pt;
import 'package:app/lang/value/ru_RU.dart' as ru_ru;
import 'package:app/lang/value/th_TH.dart' as th_th;
import 'package:app/lang/value/ur_PK.dart' as ur_pk;
import 'package:app/lang/value/vi_VN.dart' as vi_vn;

void main() {
  // The dedicated localization key under test (mirrors
  // `CommonConstants.scanAlignHint`).
  const String scanAlignHintKey = 'scanAlignHint';

  // The English canonical value (Req 9.4 / 9.5). This is the fallback used when
  // a locale cannot resolve the key, so it must remain stable.
  const String englishCanonicalValue = 'Align the QR code within the frame';

  // All 15 supported locale maps, keyed by their file/locale identifier for
  // readable failure messages. Referencing the exported map variables directly
  // (statically imported) keeps this list type-checked.
  const Map<String, Map<String, String>> localeMaps =
      <String, Map<String, String>>{
    'ar_SA': ar_sa.ar,
    'bn_BD': bn_bd.bn,
    'cn_CN': cn_cn.cn,
    'en_US': en_us.en,
    'es_ES': es_es.es,
    'fr_FR': fr_fr.fr,
    'hi_IN': hi_in.hi,
    'ja_JA': ja_ja.ja,
    'ko_KO': ko_ko.ko,
    'ms_MS': ms_ms.ms,
    'pt_PT': pt_pt.pt,
    'ru_RU': ru_ru.ru,
    'th_TH': th_th.th,
    'ur_PK': ur_pk.ur,
    'vi_VN': vi_vn.vi,
  };

  group('scanAlignHint locale coverage (Req 9.4)', () {
    test('exactly 15 locale maps are covered', () {
      expect(localeMaps.length, 15,
          reason:
              'all 15 supported locales must be included in the coverage set');
    });

    // Iterate every locale map and assert the key is present with a non-empty
    // (after trimming) value (Req 9.4).
    for (final MapEntry<String, Map<String, String>> entry
        in localeMaps.entries) {
      final String localeName = entry.key;
      final Map<String, String> map = entry.value;

      test('$localeName contains a non-empty "$scanAlignHintKey"', () {
        expect(map.containsKey(scanAlignHintKey), isTrue,
            reason: '$localeName is missing the "$scanAlignHintKey" key');
        expect(map[scanAlignHintKey]!.trim(), isNotEmpty,
            reason: '$localeName has an empty "$scanAlignHintKey" value');
      });
    }

    test('en_US holds the canonical English value (Req 9.4/9.5)', () {
      expect(en_us.en[scanAlignHintKey], englishCanonicalValue,
          reason: 'the English canonical Align_Hint value must be stable so it '
              'can serve as the fallback for unresolved locales');
    });
  });
}
