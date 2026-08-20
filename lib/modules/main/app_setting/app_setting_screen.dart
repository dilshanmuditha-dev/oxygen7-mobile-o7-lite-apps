// ignore_for_file: deprecated_member_use

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app_controller.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/common.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/utils/animation/animation_style.dart' as app_animation;
import '../../../shared/utils/responsive_util.dart';
import '../../../shared/widgets/animation/animation_style_selector.dart';
import '../../../shared/widgets/button.dart';
import '../../../shared/widgets/custom_text_style.dart';
import '../../../shared/widgets/input_field.dart';
import '../../../shared/widgets/normal_button.dart';
import 'app_setting_controller.dart';

class AppSettingScreen extends GetView<AppSettingController> {
  AppSettingScreen({Key? key}) : super(key: key);
  final AppController appController = Get.find();

  @override
  Widget build(BuildContext context) {
    return NormalButton(
      onPressed: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: appController.isDarkModeOn.value
            ? ColorConstants.darkScaffoldBackgroundColor
            : Color(0xFFFBFBFB),
        appBar: _buildAppBar(),
        body: Form(
          key: controller.carplateNumberFormKey,
          child: Obx(
            () => StorageService.isGw3
                ? _buildGw3Layout(context)
                : _buildLegacyLayout(context),
          ),
        ),
      ),
    );
  }

  // Build app bar with consistent GW3 styling
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      title: Text(
        CommonConstants.appSetting.tr,
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
        icon: Icon(
          Icons.arrow_back,
          color: appController.isDarkModeOn.value
              ? ColorConstants.white
              : Color(0xFF382F41),
          size: 24,
        ),
        onPressed: () => Get.back(),
      ),
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
    );
  }

  // New GW3 layout following Figma design
  Widget _buildGw3Layout(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),

          // Settings Container - All items in one container
          Container(
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
            child: Column(
              children: [
                // Enable Refund Password
                _buildGw3SettingItem(
                  title: 'settingsEnableRefundPassword'.tr,
                  value: controller.isEnableRefundPassword.value,
                  onChanged: () => controller.enableRefundPassword(),
                  isFirst: true,
                ),

                _buildDivider(),

                // Enable App Animations
                _buildGw3SettingItem(
                  title: 'settingsEnableAppAnimations'.tr,
                  value: controller.isEnableAppAnimation.value,
                  onChanged: () => controller.enableAppAnimation(),
                ),

                // Animation Style Selector - only show when animations are enabled
                if (controller.isEnableAppAnimation.value) ...[
                  _buildDivider(),
                  AnimationStyleSelector(
                    selectedStyle:
                        app_animation.AnimationStyle.values.firstWhere(
                      (s) => s.name == controller.selectedAnimationStyle.value,
                      orElse: () => app_animation.AnimationStyle.wave,
                    ),
                    onStyleChanged: (style) =>
                        controller.setAnimationStyle(style),
                    enabled: controller.isEnableAppAnimation.value,
                    isDarkMode: appController.isDarkModeOn.value,
                  ),
                ],

                _buildDivider(),

                // Sound Enable
                _buildGw3SettingItem(
                  title: CommonConstants.soundEnable.tr,
                  value: controller.isEnableSound.value,
                  onChanged: () => controller.toggleEnableSound(),
                ),

                // Sound Dropdown
                if (controller.isEnableSound.value) ...[
                  _buildDivider(),
                  _buildGw3SoundDropdown(),
                ],

                // Email Receipt Settings
                if (!appController.isLandiDevice.value &&
                    !appController.isSunmiDevice.value) ...[
                  _buildDivider(),
                  _buildGw3SettingItem(
                    title: 'settingsEmailReceipt'.tr,
                    value: controller.isEnableEmailReceipt.value,
                    onChanged: () => controller.toggleEnableEmailReceipt(),
                  ),
                ],

                // Email CC Settings
                if (controller.isEnableEmailReceipt.value) ...[
                  _buildDivider(),
                  _buildGw3SettingItem(
                    title: 'settingsCcEmailTo'.tr,
                    value: controller.isEnableEmailCC.value,
                    onChanged: () => controller.toggleEnableEmailCC(),
                  ),
                ],

                // Email CC Input
                if (controller.isEnableEmailReceipt.value &&
                    controller.isEnableEmailCC.value) ...[
                  _buildDivider(),
                  _buildGw3InputItem(
                    title: 'settingsInputEmailAddress'.tr,
                    child: InputField(
                      counterText: '',
                      controller: controller.emailCCController,
                      hintText: 'settingsEnterEmailAddress'.tr,
                      focusNode: controller.emailCCFocusNode,
                      validator: (value) {
                        if (value!.isNotEmpty && !GetUtils.isEmail(value)) {
                          return 'dialogInvalidEmailAddress'.tr;
                        }
                        return null;
                      },
                    ),
                  ),
                ],

                _buildDivider(),

                // Refresh Interval - Check if this is last item
                _buildGw3SettingItem(
                  title: 'settingsRefreshInterval'.tr,
                  value: controller.isEnableRefreshInterval.value,
                  onChanged: () => controller.toggleEnableRefreshInterval(),
                  isLast: !appController.isLandiDevice.value &&
                      !controller.isMobileUser.value,
                ),

                // MineSec Setting
                if (appController.isLandiDevice.value) ...[
                  _buildDivider(),
                  _buildGw3SettingItem(
                    title: 'settingsEnableMineSec'.tr,
                    value: appController.isEnableMineSec.value,
                    onChanged: () => controller.toggleEnableMinsec(),
                    isLast: !controller.isMobileUser.value,
                  ),
                ],

                // Limo App Settings
                if (controller.isMobileUser.value) ...[
                  _buildDivider(),
                  _buildGw3InputItem(
                    title: CommonConstants.description.tr,
                    child: InputField(
                      inputFormatters: [AlphaNumericTextInputFormatter()],
                      counterText: '',
                      controller: controller.carplateNumberController,
                      hintText: 'settingsEnterDescription'.tr,
                      focusNode: controller.carplateNumberFocus,
                    ),
                  ),
                  _buildDivider(),
                  _buildGw3InputItem(
                    title: 'settingsServiceChargeRate'.tr,
                    isLast: true,
                    child: InputField(
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      counterText: '',
                      controller: controller.serviceChargeRateController,
                      hintText: 'settingsEnterRate'.tr,
                      maxLength: 2,
                      focusNode: controller.serviceChargeRateFocus,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'settingsServiceChargeRequired'.tr;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 32),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => controller.applySettings(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7E01D7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(80),
                ),
                elevation: 0,
              ),
              child: Text(
                'settingsApply'.tr,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(height: 32),
        ],
      ),
    );
  }

  // Build individual setting item for GW3
  Widget _buildGw3SettingItem({
    required String title,
    required bool value,
    required VoidCallback onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? Radius.circular(12) : Radius.zero,
          bottom: isLast ? Radius.circular(12) : Radius.zero,
        ),
        onTap: onChanged,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
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
              SizedBox(width: 8),
              Switch(
                value: value,
                activeColor: Color(0xFF7E01D7),
                activeTrackColor: Color(0xFF7E01D7).withOpacity(0.5),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
                onChanged: (_) => onChanged(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build divider between items
  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: 20),
      color: appController.isDarkModeOn.value
          ? Color(0xFF374151)
          : Color(0xFFF3F4F6),
    );
  }

  // Build input field item for GW3
  Widget _buildGw3InputItem({
    required String title,
    required Widget child,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: appController.isDarkModeOn.value
                    ? Colors.white.withOpacity(0.8)
                    : Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  // Build sound dropdown item
  Widget _buildGw3SoundDropdown() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              CommonConstants.sound.tr,
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
          SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: _buildGw3Dropdown(),
          ),
        ],
      ),
    );
  }

  // Build GW3 styled dropdown
  Widget _buildGw3Dropdown() {
    return Obx(
      () => DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          items: controller.appWithSound
              .map((item) => DropdownMenuItem<String>(
                    value: item['name'],
                    child: Center(
                      child: Text(
                        item['name']!.tr,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: appController.isDarkModeOn.value
                              ? Colors.white
                              : Color(0xFF382F41),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ))
              .toList(),
          value: controller.selectedApp.value,
          onChanged: (newValue) => controller.onChanged(newValue),
          buttonStyleData: ButtonStyleData(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                width: 1,
                color: appController.isDarkModeOn.value
                    ? Color(0xFF4A5568)
                    : Color(0xFFD1D5DB),
              ),
              color: appController.isDarkModeOn.value
                  ? ColorConstants.grey800
                  : Colors.white,
            ),
            padding: EdgeInsets.symmetric(horizontal: 12),
            elevation: 0,
          ),
          iconStyleData: IconStyleData(
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: appController.isDarkModeOn.value
                  ? Colors.white
                  : Color(0xFF6B7280),
            ),
            iconSize: 20,
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: appController.isDarkModeOn.value
                  ? ColorConstants.grey800
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            offset: const Offset(0, -5),
          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }

  // Legacy layout for non-GW3 users
  Widget _buildLegacyLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: ResponsiveUtil().getSize(40)),
          ListTile(
            title: Text(
              'settingsEnableRefundPassword'.tr,
              style: CustomTextStyles.labelBlack500Size16Fw500,
            ),
            onTap: () {
              controller.enableRefundPassword();
            },
            trailing: Obx(
              () => Switch(
                value: controller.isEnableRefundPassword.value,
                activeTrackColor: controller.isEnableRefundPassword.value
                    ? ColorConstants.backgroundColorButtonPrint
                    : Colors.blueGrey,
                activeColor: ColorConstants.white,
                onChanged: (value) {
                  controller.enableRefundPassword();
                },
              ),
            ),
          ),
          ListTile(
            title: Text(
              'settingsEnableAppAnimations'.tr,
              style: CustomTextStyles.labelBlack500Size16Fw500,
            ),
            onTap: () {
              controller.enableAppAnimation();
            },
            trailing: Obx(
              () => Switch(
                value: controller.isEnableAppAnimation.value,
                activeTrackColor: controller.isEnableAppAnimation.value
                    ? ColorConstants.backgroundColorButtonPrint
                    : Colors.blueGrey,
                activeColor: ColorConstants.white,
                onChanged: (value) {
                  controller.enableAppAnimation();
                },
              ),
            ),
          ),
          // Animation Style Selector for legacy layout
          Obx(
            () => controller.isEnableAppAnimation.value
                ? ListTile(
                    title: Text(
                      CommonConstants.animationStyle.tr,
                      style: CustomTextStyles.labelBlack500Size16Fw500,
                    ),
                    trailing: SizedBox(
                      width: ResponsiveUtil().getSize(140),
                      child: AnimationStyleSelector(
                        selectedStyle:
                            app_animation.AnimationStyle.values.firstWhere(
                          (s) =>
                              s.name == controller.selectedAnimationStyle.value,
                          orElse: () => app_animation.AnimationStyle.wave,
                        ),
                        onStyleChanged: (style) =>
                            controller.setAnimationStyle(style),
                        enabled: true,
                        isDarkMode: appController.isDarkModeOn.value,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          ListTile(
            title: Text(
              CommonConstants.soundEnable.tr,
              style: CustomTextStyles.labelBlack500Size16Fw500,
            ),
            onTap: () {
              controller.toggleEnableSound();
            },
            trailing: Obx(
              () => Switch(
                value: controller.isEnableSound.value,
                activeTrackColor: controller.isEnableSound.value
                    ? ColorConstants.backgroundColorButtonPrint
                    : Colors.blueGrey,
                activeColor: ColorConstants.white,
                onChanged: (value) {
                  controller.toggleEnableSound();
                },
              ),
            ),
          ),
          SizedBox(
              height: controller.isEnableSound.value
                  ? ResponsiveUtil().getSize(10)
                  : 0),
          Obx(
            () => controller.isEnableSound.value
                ? ListTile(
                    title: Text(
                      CommonConstants.sound.tr,
                      style: CustomTextStyles.labelBlack500Size16Fw500,
                    ),
                    onTap: () {},
                    trailing: SizedBox(
                      width: ResponsiveUtil().getSize(140),
                      child: _buildLegacyDropdown(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          appController.isLandiDevice.value || appController.isSunmiDevice.value
              ? const SizedBox.shrink()
              : ListTile(
                  title: Text(
                    'settingsEmailReceipt'.tr,
                    style: CustomTextStyles.labelBlack500Size16Fw500,
                  ),
                  onTap: () {
                    controller.toggleEnableEmailReceipt();
                  },
                  trailing: Obx(
                    () => Switch(
                      value: controller.isEnableEmailReceipt.value,
                      activeTrackColor: controller.isEnableEmailReceipt.value
                          ? ColorConstants.backgroundColorButtonPrint
                          : Colors.blueGrey,
                      activeColor: ColorConstants.white,
                      onChanged: (value) {
                        controller.toggleEnableEmailReceipt();
                      },
                    ),
                  ),
                ),
          controller.isEnableEmailReceipt.value
              ? ListTile(
                  title: Text(
                    'settingsCcEmailTo'.tr,
                    style: CustomTextStyles.labelBlack500Size16Fw500,
                  ),
                  onTap: () {
                    controller.toggleEnableEmailCC();
                  },
                  trailing: Obx(
                    () => Switch(
                      value: controller.isEnableEmailCC.value,
                      activeTrackColor: controller.isEnableEmailCC.value
                          ? ColorConstants.backgroundColorButtonPrint
                          : Colors.blueGrey,
                      activeColor: ColorConstants.white,
                      onChanged: (value) {
                        controller.toggleEnableEmailCC();
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          controller.isEnableEmailReceipt.value &&
                  controller.isEnableEmailCC.value
              ? ListTile(
                  title: Text(
                    "",
                    style: CustomTextStyles.labelBlack500Size16Fw500,
                  ),
                  trailing: SizedBox(
                    width: ResponsiveUtil().getSize(200),
                    child: InputField(
                      counterText: '',
                      controller: controller.emailCCController,
                      hintText: '',
                      focusNode: controller.emailCCFocusNode,
                      validator: (value) {
                        if (value!.isNotEmpty && !GetUtils.isEmail(value)) {
                          return 'dialogInvalidEmailAddress'.tr;
                        }
                        return null;
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          ListTile(
            title: Text(
              'settingsRefreshInterval'.tr,
              style: CustomTextStyles.labelBlack500Size16Fw500,
            ),
            onTap: () {
              controller.toggleEnableRefreshInterval();
            },
            trailing: Obx(
              () => Switch(
                value: controller.isEnableRefreshInterval.value,
                activeTrackColor: controller.isEnableRefreshInterval.value
                    ? ColorConstants.backgroundColorButtonPrint
                    : Colors.blueGrey,
                activeColor: ColorConstants.white,
                onChanged: (value) {
                  controller.toggleEnableRefreshInterval();
                },
              ),
            ),
          ),
          appController.isLandiDevice.value
              ? ListTile(
                  title: Text(
                    'settingsEnableMineSec'.tr,
                    style: CustomTextStyles.labelBlack500Size16Fw500,
                  ),
                  onTap: () {
                    controller.toggleEnableMinsec();
                  },
                  trailing: Obx(
                    () => Switch(
                      value: appController.isEnableMineSec.value,
                      activeTrackColor: appController.isEnableMineSec.value
                          ? ColorConstants.backgroundColorButtonPrint
                          : Colors.blueGrey,
                      activeColor: ColorConstants.white,
                      onChanged: (value) {
                        controller.toggleEnableMinsec();
                      },
                    ),
                  ),
                )
              : SizedBox.shrink(),
          SizedBox(
            height: ResponsiveUtil().getSize(10),
          ),
          controller.isMobileUser.value
              ? ListTile(
                  title: Text(
                    CommonConstants.description.tr,
                    style: CustomTextStyles.labelBlack500Size16Fw500,
                  ),
                  trailing: SizedBox(
                    width: ResponsiveUtil().getSize(200),
                    child: InputField(
                      inputFormatters: [
                        AlphaNumericTextInputFormatter(),
                      ],
                      counterText: '',
                      controller: controller.carplateNumberController,
                      hintText: '',
                      focusNode: controller.carplateNumberFocus,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          SizedBox(
            height: ResponsiveUtil().getSize(10),
          ),
          controller.isMobileUser.value
              ? ListTile(
                  title: Text(
                    'settingsServiceChargeRate'.tr,
                    style: CustomTextStyles.labelBlack500Size16Fw500,
                  ),
                  trailing: SizedBox(
                    width: ResponsiveUtil().getSize(200),
                    child: InputField(
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      counterText: '',
                      controller: controller.serviceChargeRateController,
                      hintText: '',
                      maxLength: 2,
                      focusNode: controller.serviceChargeRateFocus,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'settingsServiceChargeRequired'.tr;
                        }
                        return null;
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          Padding(
            padding: ResponsiveUtil().getPadding(left: 24, right: 24, top: 100),
            child: CommonWidgets.primaryButton(
              width: double.infinity,
              onPressed: () {
                controller.applySettings();
              },
              text: 'settingsApply'.tr,
            ),
          ),
        ],
      ),
    );
  }

  // Legacy dropdown
  Widget _buildLegacyDropdown() {
    return Obx(
      () => DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          items: controller.appWithSound
              .map((item) => DropdownMenuItem<String>(
                    value: item['name'],
                    child: Center(
                      child: Text(
                        item['name']!.tr,
                        style: CustomTextStyles.labelBlack500Size14Fw400,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ))
              .toList(),
          value: controller.selectedApp.value,
          onChanged: (newValue) {
            controller.onChanged(newValue);
          },
          buttonStyleData: ButtonStyleData(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(width: 1, color: ColorConstants.white),
              color: appController.isDarkModeOn.value
                  ? ColorConstants.grey800
                  : ColorConstants.white,
            ),
            padding: ResponsiveUtil().getPadding(left: 10),
            elevation: 2,
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(
              Icons.arrow_drop_down,
            ),
            iconSize: 24,
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            offset: const Offset(0, 0),
            scrollbarTheme: ScrollbarThemeData(
              radius: const Radius.circular(40),
              thickness: MaterialStateProperty.all<double>(6),
              thumbVisibility: MaterialStateProperty.all<bool>(true),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 40,
            padding: EdgeInsets.only(left: 14, right: 14),
          ),
        ),
      ),
    );
  }
}
