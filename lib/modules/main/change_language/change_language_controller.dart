import 'package:get/get.dart';

import '../../../shared/secure_shared_preferences/sharepreference.dart';

class ChangeLanguageController extends GetxController {
  Rx<int> indexChangeLanguage = 0.obs;
  Rx<String> locateChangeLanguage = 'en'.obs;
  Rx<String> languageTitle = 'English'.obs;

  void getIndexChangeLanguage() async {
    indexChangeLanguage.value =
        await SharedPrefManager.instance.getIndexChangeLanguage();
    languageTitle.value =
        await SharedPrefManager.instance.getLocalTitleChangeLanguage();
  }

  @override
  void onInit() {
    getIndexChangeLanguage();

    super.onInit();
  }
}
