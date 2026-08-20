// ignore_for_file: unrelated_type_equality_checks

import 'package:app/shared/constants/colors.dart';
import 'package:app/shared/utils/responsive_util.dart';
import 'package:app/shared/widgets/custom_text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app_controller.dart';
import '../../../lang/translation_service.dart';
import '../../../shared/secure_shared_preferences/sharepreference.dart';
import 'change_language_controller.dart';

class LanguageWidget extends StatelessWidget {
  final String flag;
  final String label;
  final String locale;
  final int index;
  LanguageWidget({
    Key? key,
    required this.flag,
    required this.label,
    required this.locale,
    required this.index,
  }) : super(key: key);

  final AppController appController = Get.find();
  final ChangeLanguageController changeLanguageController = Get.find();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TranslationService.changeLocale(locale);
        TranslationService.changeLocale(
          locale,
        );
        changeLanguageController.locateChangeLanguage.value = locale;
        changeLanguageController.languageTitle.value = label;
        changeLanguageController.indexChangeLanguage.value = index;
        SharedPrefManager.instance.setIndexChangeLanguage(
            changeLanguageController.indexChangeLanguage.value);
        SharedPrefManager.instance.setLocalTitleChangeLanguage(
            changeLanguageController.languageTitle.value);
        SharedPrefManager.instance.setChangeLanguage(
            changeLanguageController.locateChangeLanguage.value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Stack(
          children: [
            Obx(
              () => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: ResponsiveUtil().getPadding(
                      left: 10,
                      right: 10,
                    ),
                    child: Row(
                      children: [
                        Text(
                          flag,
                          style: CustomTextStyles.labelBlack500Size16Fw500,
                        ),
                        SizedBox(
                          width: 16,
                        ),
                        Text(
                          label,
                          style: CustomTextStyles.labelBlack500Size16Fw500,
                        ),
                        Spacer(),
                        if (changeLanguageController.indexChangeLanguage ==
                            index)
                          SizedBox(
                            height: ResponsiveUtil().getSize(20),
                            child: Radio(
                              value: true,
                              groupValue: true,
                              activeColor: ColorConstants.purpleRewardColor,
                              onChanged: (value) {},
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
