import 'dart:collection';
import 'package:app/lang/value/ar_SA.dart';
import 'package:app/lang/value/bn_BD.dart';
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
import 'package:app/shared/secure_shared_preferences/sharepreference.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'value/cn_CN.dart';
import 'value/en_US.dart';

class TranslationService extends Translations {
  static Locale _savedLocale = const Locale('en', 'US');
  static Locale? get locale => _savedLocale;
  static const fallbackLocale = Locale('en', 'US');

  /// Loads the saved language preference from SharedPreferences.
  /// Must be called after SharedPrefManager.init() and before runApp().
  static Future<void> initFromSavedPreference() async {
    final savedLangCode = await SharedPrefManager.instance.getChangeLanguage();
    if (savedLangCode != null && savedLangCode != 'en_US') {
      _savedLocale = _getLocaleFromLanguage(langCode: savedLangCode);
    }
  }

  static final langCodes = [
    'en',
    'cn',
    'hi',
    'es',
    'fr',
    'ar',
    'bn',
    'ru',
    'pt',
    'ur',
    'th',
    'ms',
    'ko',
    'vi',
    'ja',
  ];

  static final locales = [
    const Locale('en', 'US'),
    const Locale('cn', 'CN'),
    const Locale('hi', 'IN'),
    const Locale('es', 'ES'),
    const Locale('fr', 'FR'),
    const Locale('ar', 'SA'),
    const Locale('bn', 'BD'),
    const Locale('ru', 'RU'),
    const Locale('pt', 'PT'),
    const Locale('ur', 'PK'),
    const Locale('th', 'TH'),
    const Locale('ms', 'MY'),
    const Locale('ko', 'KR'),
    const Locale('vi', 'VN'),
    const Locale('ja', 'JP'),
  ];

  static final langs = LinkedHashMap.from({
    'en': 'English',
    'cn': '简体中文',
    'hi': 'हिन्दी',
    'es': 'Español',
    'fr': 'Français',
    'ar': 'العربية',
    'bn': 'বাংলা',
    'ru': 'Русский',
    'pt': 'Português',
    'ur': 'اردو',
    'th': 'ไทย',
    'ms': 'Bahasa Melayu',
    'ko': '한국어',
    'vi': 'Tiếng Việt',
    'ja': '日本語',
  });

  static void changeLocale(String langCode) {
    final locale = _getLocaleFromLanguage(langCode: langCode);
    Get.updateLocale(locale);
  }

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': en,
        'cn_CN': cn,
        'hi_IN': hi,
        'es_ES': es,
        'fr_FR': fr,
        'ar_SA': ar,
        'bn_BD': bn,
        'ru_RU': ru,
        'pt_PT': pt,
        'ur_PK': ur,
        'th_TH': th,
        'ms_MY': ms,
        'ko_KR': ko,
        'vi_VN': vi,
        'ja_JP': ja,
      };

  static Locale _getLocaleFromLanguage({String? langCode}) {
    var lang = langCode ?? Get.deviceLocale?.languageCode;
    for (int i = 0; i < langCodes.length; i++) {
      if (lang == langCodes[i]) return locales[i];
    }
    return Get.locale!;
  }
}
