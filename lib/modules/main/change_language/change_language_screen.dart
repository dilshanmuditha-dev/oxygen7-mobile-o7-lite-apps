import 'package:app/shared/constants/colors.dart';
import 'package:app/shared/constants/common.dart';
import 'package:app/shared/utils/responsive_util.dart';

import 'package:app/shared/services/storage_service.dart';
import 'package:app/shared/secure_shared_preferences/sharepreference.dart';
import 'package:app/lang/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app_controller.dart';
import 'change_language_controller.dart';
import 'language_widget.dart';

class ChangeLanguage extends GetView<ChangeLanguageController> {
  const ChangeLanguage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AppController appController = Get.find();

    return Obx(
      () => Scaffold(
        backgroundColor: appController.isDarkModeOn.value
            ? ColorConstants.darkScaffoldBackgroundColor
            : Color(0xFFFBFBFB),
        appBar: _buildAppBar(appController),
        body: StorageService.isGw3
            ? _buildGw3Layout(appController)
            : _buildLegacyLayout(appController),
      ),
    );
  }

  // Build app bar with consistent GW3 styling
  PreferredSizeWidget _buildAppBar(AppController appController) {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      title: Text(
        CommonConstants.changeLanguage.tr,
        style: TextStyle(
          fontFamily: 'Open Sans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: appController.isDarkModeOn.value
              ? Colors.white
              : Color(0xFF382F41),
        ),
      ),
      leading: IconButton(
        onPressed: () {
          Get.back();
        },
        icon: Icon(
          Icons.arrow_back,
          color: appController.isDarkModeOn.value
              ? ColorConstants.white
              : Color(0xFF382F41),
          size: 24,
        ),
      ),
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
    );
  }

  // New GW3 layout following Figma design
  Widget _buildGw3Layout(AppController appController) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),

          // Language Options - All 15 languages in priority order
          Column(
            children: [
              _buildGw3LanguageItem(
                flag: '🇺🇸',
                label: 'English',
                locale: 'en',
                index: 0,
                appController: appController,
              ),
              SizedBox(height: 12),
              _buildGw3LanguageItem(
                flag: '🇨🇳',
                label: '简体中文',
                locale: 'cn',
                index: 1,
                appController: appController,
              ),
              SizedBox(height: 12),
              _buildGw3LanguageItem(
                flag: '🇮🇳',
                label: 'हिन्दी',
                locale: 'hi',
                index: 2,
                appController: appController,
              ),
              SizedBox(height: 12),
              _buildGw3LanguageItem(
                flag: '🇪🇸',
                label: 'Español',
                locale: 'es',
                index: 3,
                appController: appController,
              ),
              SizedBox(height: 12),
              _buildGw3LanguageItem(
                flag: '🇫🇷',
                label: 'Français',
                locale: 'fr',
                index: 4,
                appController: appController,
              ),
              SizedBox(height: 12),
              _buildGw3LanguageItem(
                flag: '🇸🇦',
                label: 'العربية',
                locale: 'ar',
                index: 5,
                appController: appController,
              ),
              SizedBox(height: 12),
              _buildGw3LanguageItem(
                flag: '🇧🇩',
                label: 'বাংলা',
                locale: 'bn',
                index: 6,
                appController: appController,
              ),
              SizedBox(height: 12),
              _buildGw3LanguageItem(
                flag: '🇷🇺',
                label: 'Русский',
                locale: 'ru',
                index: 7,
                appController: appController,
              ),
              SizedBox(height: 12),
              _buildGw3LanguageItem(
                flag: '🇵🇹',
                label: 'Português',
                locale: 'pt',
                index: 8,
                appController: appController,
              ),
              SizedBox(height: 12),
              _buildGw3LanguageItem(
                flag: '🇵🇰',
                label: 'اردو',
                locale: 'ur',
                index: 9,
                appController: appController,
              ),
              SizedBox(height: 12),
              _buildGw3LanguageItem(
                flag: '🇹🇭',
                label: 'ไทย',
                locale: 'th',
                index: 10,
                appController: appController,
              ),
              SizedBox(height: 12),
              _buildGw3LanguageItem(
                flag: '🇲🇾',
                label: 'Bahasa Melayu',
                locale: 'ms',
                index: 11,
                appController: appController,
              ),
              SizedBox(height: 12),
              _buildGw3LanguageItem(
                flag: '🇰🇷',
                label: '한국어',
                locale: 'ko',
                index: 12,
                appController: appController,
              ),
              SizedBox(height: 12),
              _buildGw3LanguageItem(
                flag: '🇻🇳',
                label: 'Tiếng Việt',
                locale: 'vi',
                index: 13,
                appController: appController,
              ),
              SizedBox(height: 12),
              _buildGw3LanguageItem(
                flag: '🇯🇵',
                label: '日本語',
                locale: 'ja',
                index: 14,
                appController: appController,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build individual language item for GW3 - Each in separate container
  Widget _buildGw3LanguageItem({
    required String flag,
    required String label,
    required String locale,
    required int index,
    required AppController appController,
  }) {
    return Obx(() {
      final isSelected = controller.indexChangeLanguage.value == index;

      return Container(
        decoration: BoxDecoration(
          color: appController.isDarkModeOn.value
              ? ColorConstants.grey800
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: appController.isDarkModeOn.value
                ? Color(0xFF4A5568)
                : Color(0xFFCFD3D0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: appController.isDarkModeOn.value
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _changeLanguage(index, locale, label);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Flag icon
                  Container(
                    width: 32,
                    height: 32,
                    // decoration: BoxDecoration(
                    //   borderRadius: BorderRadius.circular(6),
                    //   border: Border.all(
                    //     color: appController.isDarkModeOn.value
                    //         ? Color(0xFF4A5568)
                    //         : Color(0xFFE5E7EB),
                    //     width: 1,
                    //   ),
                    // ),
                    child: Center(
                      child: Text(
                        flag,
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // Language label
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: appController.isDarkModeOn.value
                            ? Colors.white
                            : Color(0xFF382F41),
                      ),
                    ),
                  ),

                  // Selection indicator
                  if (isSelected)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Color(0xFF7E01D7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    )
                  else
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: appController.isDarkModeOn.value
                              ? Color(0xFF4A5568)
                              : Color(0xFFD1D5DB),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // Legacy layout for non-GW3 users
  Widget _buildLegacyLayout(AppController appController) {
    return Padding(
      padding: ResponsiveUtil().getPadding(all: 10),
      child: SingleChildScrollView(
        child: Column(
          children: [
            ListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                LanguageWidget(
                  flag: '🇺🇸',
                  label: 'English',
                  locale: 'en',
                  index: 0,
                ),
                Divider(height: 1.6, color: Colors.grey.withOpacity(.2)),
                LanguageWidget(
                  flag: '🇨🇳',
                  label: '简体中文',
                  locale: 'cn',
                  index: 1,
                ),
                Divider(height: 1.6, color: Colors.grey.withOpacity(.2)),
                LanguageWidget(
                  flag: '🇮🇳',
                  label: 'हिन्दी',
                  locale: 'hi',
                  index: 2,
                ),
                Divider(height: 1.6, color: Colors.grey.withOpacity(.2)),
                LanguageWidget(
                  flag: '🇪🇸',
                  label: 'Español',
                  locale: 'es',
                  index: 3,
                ),
                Divider(height: 1.6, color: Colors.grey.withOpacity(.2)),
                LanguageWidget(
                  flag: '🇫🇷',
                  label: 'Français',
                  locale: 'fr',
                  index: 4,
                ),
                Divider(height: 1.6, color: Colors.grey.withOpacity(.2)),
                LanguageWidget(
                  flag: '🇸🇦',
                  label: 'العربية',
                  locale: 'ar',
                  index: 5,
                ),
                Divider(height: 1.6, color: Colors.grey.withOpacity(.2)),
                LanguageWidget(
                  flag: '🇧🇩',
                  label: 'বাংলা',
                  locale: 'bn',
                  index: 6,
                ),
                Divider(height: 1.6, color: Colors.grey.withOpacity(.2)),
                LanguageWidget(
                  flag: '🇷🇺',
                  label: 'Русский',
                  locale: 'ru',
                  index: 7,
                ),
                Divider(height: 1.6, color: Colors.grey.withOpacity(.2)),
                LanguageWidget(
                  flag: '🇵🇹',
                  label: 'Português',
                  locale: 'pt',
                  index: 8,
                ),
                Divider(height: 1.6, color: Colors.grey.withOpacity(.2)),
                LanguageWidget(
                  flag: '🇵🇰',
                  label: 'اردو',
                  locale: 'ur',
                  index: 9,
                ),
                Divider(height: 1.6, color: Colors.grey.withOpacity(.2)),
                LanguageWidget(
                  flag: '🇹🇭',
                  label: 'ไทย',
                  locale: 'th',
                  index: 10,
                ),
                Divider(height: 1.6, color: Colors.grey.withOpacity(.2)),
                LanguageWidget(
                  flag: '🇲🇾',
                  label: 'Bahasa Melayu',
                  locale: 'ms',
                  index: 11,
                ),
                Divider(height: 1.6, color: Colors.grey.withOpacity(.2)),
                LanguageWidget(
                  flag: '🇰🇷',
                  label: '한국어',
                  locale: 'ko',
                  index: 12,
                ),
                Divider(height: 1.6, color: Colors.grey.withOpacity(.2)),
                LanguageWidget(
                  flag: '🇻🇳',
                  label: 'Tiếng Việt',
                  locale: 'vi',
                  index: 13,
                ),
                Divider(height: 1.6, color: Colors.grey.withOpacity(.2)),
                LanguageWidget(
                  flag: '🇯🇵',
                  label: '日本語',
                  locale: 'ja',
                  index: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Handle language change
  void _changeLanguage(int index, String locale, String label) {
    TranslationService.changeLocale(locale);
    controller.locateChangeLanguage.value = locale;
    controller.languageTitle.value = label;
    controller.indexChangeLanguage.value = index;
    SharedPrefManager.instance.setIndexChangeLanguage(index);
    SharedPrefManager.instance.setLocalTitleChangeLanguage(label);
    SharedPrefManager.instance.setChangeLanguage(locale);
  }
}
