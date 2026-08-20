// ignore_for_file: deprecated_member_use, unused_element, unnecessary_statements, use_key_in_widget_constructors

import 'package:app/shared/utils/enum/app_dialog_type.dart';
import 'package:app/shared/services/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/api_provider.dart';
import '../../app_controller.dart';
import '../../modules/auth/auth_controller.dart';
import '../../modules/main/home_controller.dart';
import '../../routes/app_pages.dart';
import '../constants/colors.dart';
import '../constants/common.dart';
import '../constants/app_secrets.dart';
import '../constants/image_constant.dart';
import '../secure_shared_preferences/secure_shared_preferences.dart';
import '../secure_shared_preferences/sharepreference.dart';
import '../utils/responsive_util.dart';
import '../utils/device_performance_detector.dart';
import 'custom_dialog/custom_dialog.dart';
import 'custom_text_style.dart';
import 'package:app/shared/utils/log_utils.dart';

class DrawerBarScreen extends StatelessWidget {
  // Use existing controller instance to avoid re-creation (faster open)
  final HomeController homeController = Get.find<HomeController>();
  final AppController appController = Get.find();
  final ScrollController scrollController = ScrollController();
  final String logoAsset;

  DrawerBarScreen({Key? key, required this.logoAsset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return homeController.onWillPop(context);
      },
      child: Drawer(
        width: MediaQuery.of(context).size.width * .75,
        backgroundColor: appController.isDarkModeOn.value
            ? ColorConstants.darkScaffoldBackgroundColor
            : Color(0xFFFBFBFB),
        child: _buildAdaptiveDrawer(context),
      ),
    );
  }

  /// Build adaptive drawer based on device performance and GW3 status
  Widget _buildAdaptiveDrawer(BuildContext context) {
    final detector = DevicePerformanceDetector.instance;

    // For low-spec devices, use simplified drawer regardless of GW3 status
    if (detector.isInitialized && detector.shouldUseSimplifiedUI()) {
      return _buildSimplifiedDrawer(context);
    }

    // For high-spec devices, use GW3 or legacy based on service
    return StorageService.isGw3
        ? _buildGw3Layout(context)
        : _buildLegacyLayout(context);
  }

  /// Simplified drawer for low-spec devices
  Widget _buildSimplifiedDrawer(BuildContext context) {
    final detector = DevicePerformanceDetector.instance;
    final cacheExtent =
        detector.isInitialized ? detector.getOptimalCacheExtent() : 200.0;

    // Build items lazily for smoother scroll on low-spec
    final List<Widget> items = [
      _buildSimpleMenuItem(
          0, CommonConstants.home.tr, ImageConstant.iconBottomHome, () {
        homeController.isCheckDrawer.value = 0;
        Get.back();
      }),
      _buildSimpleMenuItem(1, CommonConstants.changeLanguage.tr,
          ImageConstant.iconDrawerChangeLanguage, () {
        homeController.isCheckDrawer.value = 1;
        Get.toNamed(Routes.CHANGE_LANGUAGE);
      }),
      _buildSimpleSwitchItem(
          2, CommonConstants.darkMode.tr, ImageConstant.iconDrawerChangeTheme),
      _buildSimpleMenuItem(5, CommonConstants.troubleshootingHelp.tr,
          ImageConstant.iconDrawerSupport, () {
        homeController.isCheckDrawer.value = 5;
        Get.toNamed(Routes.TROUBLE_SHOOTING_PAGE);
      }),
      _buildSimpleMenuItem(
          6, CommonConstants.appSetting.tr, ImageConstant.iconDrawerAppSettings,
          () {
        homeController.isCheckDrawer.value = 6;
        Get.toNamed(Routes.APP_SETTING);
      }),
      _buildSimpleMenuItem(3, CommonConstants.privacyPolicy.tr,
          ImageConstant.iconDrawerPrivacyPolicy, () {
        homeController.isCheckDrawer.value = 3;
        _launchUrl(AppSecrets.privacyPolicyUrlFallback);
      }),
      _buildSimpleMenuItem(
          4, CommonConstants.support.tr, ImageConstant.iconDrawerSupport, () {
        homeController.isCheckDrawer.value = 4;
        sendEmail(email: AppSecrets.supportEmailFallback);
      }),
      _buildSimpleMenuItem(
          7, CommonConstants.dashboard.tr, ImageConstant.iconDrawerDashboard,
          () {
        homeController.isCheckDrawer.value = 7;
        _launchUrl(AppSecrets.merchantDashboardUrlFallback);
      }),
      _buildSimpleMenuItem(
          8, CommonConstants.userGuide.tr, ImageConstant.iconDrawerUserGuide,
          () {
        homeController.isCheckDrawer.value = 8;
        _launchUrl(AppSecrets.userGuideUrlFallback);
      }),
      _buildSimpleSignOutItem(),
      Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'v${homeController.versionName.value} (#${homeController.versionCode.value})',
            style: TextStyle(
              fontSize: 12,
              color: appController.isDarkModeOn.value
                  ? Colors.white.withOpacity(0.5)
                  : Colors.grey,
            ),
          ),
        ),
      ),
      SizedBox(height: 80),
    ];

    return Column(
      children: [
        _buildSimplifiedHeader(),
        Expanded(
          child: ListView.builder(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            cacheExtent: cacheExtent,
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ],
    );
  }

  /// Simplified header for low-spec devices
  Widget _buildSimplifiedHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 40, 16, 20),
      color: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
      child: Column(
        children: [
          // Simple logo
          SvgPicture.asset(
            logoAsset,
            width: 120,
            height: 54,
            color: appController.isDarkModeOn.value ? Colors.white : null,
          ),

          SizedBox(height: 12),

          // Device info in simple text
          Text(
            homeController.deviceModel.value,
            style: TextStyle(
              fontSize: 12,
              color: appController.isDarkModeOn.value
                  ? Colors.white.withOpacity(0.7)
                  : Colors.grey,
            ),
          ),

          SizedBox(height: 8),

          Text(
            homeController.userID.value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: appController.isDarkModeOn.value
                  ? Colors.white
                  : Colors.black87,
            ),
          ),

          SizedBox(height: 4),

          Text(
            homeController.terminalID.value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: appController.isDarkModeOn.value
                  ? Colors.white
                  : Colors.black87,
            ),
          ),

          SizedBox(height: 16),

          Container(
            height: 1,
            color: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  /// Simple menu item for low-spec devices
  Widget _buildSimpleMenuItem(
      int index, String title, String icon, VoidCallback onTap) {
    final detector = DevicePerformanceDetector.instance;
    final isLowSpec =
        detector.isInitialized && detector.shouldUseSimplifiedUI();
    final isSelected = homeController.isCheckDrawer.value == index;

    return Container(
      height: 56,
      color: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SvgPicture.asset(
                  icon,
                  width: 24,
                  height: 24,
                  // Avoid SVG recolor on low-spec to reduce paint cost
                  color: isSelected
                      ? ColorConstants.backgroundColorButtonPrint
                      : (appController.isDarkModeOn.value
                          ? Colors.white
                          : Colors.black87),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? ColorConstants.backgroundColorButtonPrint
                          : (appController.isDarkModeOn.value
                              ? Colors.white
                              : Colors.black87),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Simple switch item for dark mode
  Widget _buildSimpleSwitchItem(int index, String title, String icon) {
    return Container(
      height: 56,
      color: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              width: 24,
              height: 24,
              color: appController.isDarkModeOn.value
                  ? Colors.white.withOpacity(0.8)
                  : Colors.grey[700],
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: appController.isDarkModeOn.value
                      ? Colors.white
                      : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Obx(() => Switch(
                  value: appController.isDarkModeOn.value,
                  activeColor: ColorConstants.backgroundColorButtonPrint,
                  onChanged: (value) => appController.toggleDarkMode(),
                )),
          ],
        ),
      ),
    );
  }

  /// Simple sign out item
  Widget _buildSimpleSignOutItem() {
    return Container(
      height: 56,
      color: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            homeController.isCheckDrawer.value = 9;
            CustomDialog.showCustomDialog(
              titleButton: CommonConstants.ok.tr,
              content: CommonConstants.tittleExitApp.tr,
              context: Get.context!,
              onpressCancel: () => Get.back(),
              onPressedCheck: () async {
                await _performLogout();
              },
              dialogType: AppDialogType.confirm,
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SvgPicture.asset(
                  ImageConstant.iconDrawerLogout,
                  width: 24,
                  height: 24,
                  color: Colors.red,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    CommonConstants.signOut.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.red,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New GW3 layout following Figma design
  Widget _buildGw3Layout(BuildContext context) {
    return Obx(() => Column(
          children: [
            // Header with logo and device info
            _buildGw3Header(),

            // Menu items
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(height: 8),

                    // Main menu items in container
                    _buildGw3MenuContainer(),

                    SizedBox(height: 16),

                    // Secondary menu items
                    _buildGw3SecondaryMenu(),

                    SizedBox(height: 16),

                    // Sign out
                    _buildGw3SignOutButton(),

                    SizedBox(height: 16),

                    // Version info at bottom
                    _buildGw3VersionInfo(),

                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  // Build GW3 header with logo and device info
  Widget _buildGw3Header() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 24),
            // Logo
            SvgPicture.asset(
              logoAsset,
              fit: BoxFit.contain,
              width: 120,
              height: 54,
              color: appController.isDarkModeOn.value ? Colors.white : null,
            ),

            SizedBox(height: 12),

            // Copyright
            Text(
              CommonConstants.copyrightText.tr,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: appController.isDarkModeOn.value
                    ? Colors.white.withOpacity(0.7)
                    : Color(0xFF6B7280),
              ),
            ),

            SizedBox(height: 16),

            // Device information card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: appController.isDarkModeOn.value
                    ? ColorConstants.grey800
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: appController.isDarkModeOn.value
                      ? Color(0xFF4A5568)
                      : Color(0xFFCFD3D0),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  // Device Model
                  _buildGw3InfoItem(
                    icon: Icons.phone_android,
                    label: CommonConstants.device.tr,
                    value: homeController.deviceModel.value,
                  ),

                  SizedBox(height: 8),

                  // User ID
                  _buildGw3InfoItem(
                    icon: Icons.person_outline,
                    label: 'drawerBusinessEntity'.tr,
                    value: homeController.userID.value,
                  ),

                  SizedBox(height: 8),

                  // Terminal ID
                  _buildGw3InfoItem(
                    icon: Icons.point_of_sale_outlined,
                    label: CommonConstants.terminal.tr,
                    value: homeController.terminalID.value,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build device info item
  Widget _buildGw3InfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: appController.isDarkModeOn.value
                ? null
                : Color(0xFF7E01D7).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 12,
            color: appController.isDarkModeOn.value
                ? ColorConstants.white
                : Color(0xFF7E01D7),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Text(
                '$label: ',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: appController.isDarkModeOn.value
                      ? Colors.white.withOpacity(0.8)
                      : Color(0xFF6B7280),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: appController.isDarkModeOn.value
                        ? Colors.white
                        : Color(0xFF382F41),
                  ),
                  // maxLines: 1,
                  // overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build main menu container
  Widget _buildGw3MenuContainer() {
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
      child: Column(
        children: [
          _buildGw3MenuItem(
            index: 0,
            title: CommonConstants.home.tr,
            icon: ImageConstant.iconDrawerHome,
            onTap: () {
              homeController.isCheckDrawer.value = 0;
              Get.back();
            },
            isFirst: true,
          ),
          _buildGw3Divider(),
          _buildGw3MenuItem(
            index: 1,
            title: CommonConstants.changeLanguage.tr,
            icon: ImageConstant.iconDrawerChangeLanguage,
            onTap: () {
              homeController.isCheckDrawer.value = 1;
              Get.toNamed(Routes.CHANGE_LANGUAGE);
            },
          ),
          _buildGw3Divider(),
          _buildGw3SwitchItem(
            index: 2,
            title: CommonConstants.darkMode.tr,
            icon: ImageConstant.iconDrawerChangeTheme,
            onTap: () {
              homeController.isCheckDrawer.value = 2;
            },
          ),
          _buildGw3Divider(),
          _buildGw3MenuItem(
            index: 5,
            title: CommonConstants.troubleshootingHelp.tr,
            icon: ImageConstant.iconDrawerSupport,
            onTap: () {
              homeController.isCheckDrawer.value = 5;
              Get.toNamed(Routes.TROUBLE_SHOOTING_PAGE);
            },
          ),
          _buildGw3Divider(),
          _buildGw3MenuItem(
            index: 6,
            title: CommonConstants.appSetting.tr,
            icon: ImageConstant.iconDrawerAppSettings,
            onTap: () {
              homeController.isCheckDrawer.value = 6;
              Get.toNamed(Routes.APP_SETTING);
            },
            isLast: true,
          ),
        ],
      ),
    );
  }

  // Build secondary menu items
  Widget _buildGw3SecondaryMenu() {
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
      child: Column(
        children: [
          _buildGw3MenuItem(
            index: 3,
            title: CommonConstants.privacyPolicy.tr,
            icon: ImageConstant.iconDrawerPrivacyPolicy,
            onTap: () {
              homeController.isCheckDrawer.value = 3;
              _launchUrl(AppSecrets.privacyPolicyUrlFallback);
            },
            isFirst: true,
          ),
          _buildGw3Divider(),
          _buildGw3MenuItem(
            index: 4,
            title: CommonConstants.support.tr,
            icon: ImageConstant.iconDrawerSupport,
            onTap: () {
              homeController.isCheckDrawer.value = 4;
              sendEmail(email: AppSecrets.supportEmailFallback);
            },
          ),
          _buildGw3Divider(),
          _buildGw3MenuItem(
            index: 7,
            title: CommonConstants.dashboard.tr,
            icon: ImageConstant.iconDrawerDashboard,
            onTap: () {
              homeController.isCheckDrawer.value = 7;
              _launchUrl(AppSecrets.merchantDashboardUrlFallback);
            },
          ),
          _buildGw3Divider(),
          _buildGw3MenuItem(
            index: 8,
            title: CommonConstants.userGuide.tr,
            icon: ImageConstant.iconDrawerUserGuide,
            onTap: () {
              homeController.isCheckDrawer.value = 8;
              _launchUrl(AppSecrets.userGuideUrlFallback);
            },
            isLast: true,
          ),
        ],
      ),
    );
  }

  // Build sign out button
  Widget _buildGw3SignOutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFF75145).withOpacity(0.3),
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
            homeController.isCheckDrawer.value = 9;
            CustomDialog.showCustomDialog(
              titleButton: CommonConstants.ok.tr,
              content: CommonConstants.tittleExitApp.tr,
              context: Get.context!,
              onpressCancel: () {
                Get.back();
              },
              onPressedCheck: () async {
                await _performLogout();
              },
              dialogType: AppDialogType.confirm,
            );
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                SvgPicture.asset(
                  ImageConstant.iconDrawerLogout,
                  width: 24,
                  height: 24,
                  color: Color(0xFFF75145),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    CommonConstants.signOut.tr,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF75145),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build version info
  Widget _buildGw3VersionInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? Color(0xFF374151)
            : Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: appController.isDarkModeOn.value
                ? Colors.white.withOpacity(0.5)
                : Color(0xFF6B7280),
          ),
          SizedBox(width: 8),
          Obx(() => Text(
                'v${homeController.versionName.value} (#${homeController.versionCode.value})',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: appController.isDarkModeOn.value
                      ? Colors.white.withOpacity(0.5)
                      : Color(0xFF6B7280),
                ),
              )),
        ],
      ),
    );
  }

  // Build menu item for GW3
  Widget _buildGw3MenuItem({
    required int index,
    required String title,
    required String icon,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = homeController.isCheckDrawer.value == index;
    final detector = DevicePerformanceDetector.instance;
    final bool simplify =
        detector.isInitialized && detector.shouldUseSimplifiedUI();

    // Choose accent based on theme
    final Color accent = ColorConstants.backgroundColorButtonPrint;
    final Color baseText = appController.isDarkModeOn.value
        ? Colors.white
        : const Color(0xFF382F41);
    final Color baseIcon = appController.isDarkModeOn.value
        ? Colors.white.withOpacity(0.8)
        : const Color(0xFF6B7280);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirst ? 12 : 0),
          topRight: Radius.circular(isFirst ? 12 : 0),
          bottomLeft: Radius.circular(isLast ? 12 : 0),
          bottomRight: Radius.circular(isLast ? 12 : 0),
        ),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: simplify
              ? null
              : BoxDecoration(
                  // subtle hover background for high-spec only
                  color: Colors.transparent,
                ),
          child: Row(
            children: [
              // Icon with theme-aware color; avoid recolor on low-spec for perf
              simplify
                  ? SvgPicture.asset(
                      icon,
                      width: 24,
                      height: 24,
                    )
                  : SvgPicture.asset(
                      icon,
                      width: 24,
                      height: 24,
                      color: isSelected ? accent : baseIcon,
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? accent : baseText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build switch item for dark mode
  Widget _buildGw3SwitchItem({
    required int index,
    required String title,
    required String icon,
    required VoidCallback onTap,
  }) {
    final isSelected = homeController.isCheckDrawer.value == index;

    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          SvgPicture.asset(
            icon,
            width: 24,
            height: 24,
            color: isSelected
                ? Color(0xFF7E01D7)
                : (appController.isDarkModeOn.value
                    ? Colors.white.withOpacity(0.8)
                    : Color(0xFF6B7280)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Color(0xFF7E01D7)
                    : (appController.isDarkModeOn.value
                        ? Colors.white
                        : Color(0xFF382F41)),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          Obx(() => Switch(
                value: appController.isDarkModeOn.value,
                activeColor: Color.fromARGB(255, 168, 51, 252),
                activeTrackColor:
                    Color.fromARGB(255, 168, 51, 252).withOpacity(0.3),
                inactiveThumbColor: appController.isDarkModeOn.value
                    ? ColorConstants.white
                    : Color(0xFF6B7280),
                inactiveTrackColor: appController.isDarkModeOn.value
                    ? Color(0xFF374151)
                    : Color(0xFFF3F4F6),
                onChanged: (value) {
                  appController.toggleDarkMode();
                },
              )),
        ],
      ),
    );
  }

  // Build divider
  Widget _buildGw3Divider() {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: 16),
      color: appController.isDarkModeOn.value
          ? Color(0xFF374151)
          : Color(0xFFF3F4F6),
    );
  }

  // Legacy layout for non-GW3 users
  Widget _buildLegacyLayout(BuildContext context) {
    return Obx(() => Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Column(
              children: [
                SizedBox(height: ResponsiveUtil().getSize(62)),
                SvgPicture.asset(
                  logoAsset,
                  fit: BoxFit.contain,
                  width: ResponsiveUtil().getSize(160),
                  height: ResponsiveUtil().getSize(72),
                ),
                SizedBox(height: ResponsiveUtil().getSize(8)),
                Text(
                  CommonConstants.copyrightText.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: appController.isDarkModeOn.value
                        ? ColorConstants.nearlyWhite
                        : ColorConstants.grey800,
                    fontSize: ResponsiveUtil().getFontSize(12),
                  ),
                ),
                SizedBox(height: ResponsiveUtil().getSize(6)),
                Text(
                  homeController.deviceModel.value,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: appController.isDarkModeOn.value
                        ? ColorConstants.nearlyWhite
                        : ColorConstants.grey800?.withOpacity(.4),
                    fontSize: ResponsiveUtil().getFontSize(12),
                  ),
                ),
                SizedBox(height: ResponsiveUtil().getSize(16)),
                Text(
                  homeController.userID.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: appController.isDarkModeOn.value
                        ? ColorConstants.nearlyWhite
                        : ColorConstants.grey800,
                    fontSize: ResponsiveUtil().getFontSize(16),
                  ),
                ),
                SizedBox(height: ResponsiveUtil().getSize(4)),
                Text(
                  homeController.terminalID.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: appController.isDarkModeOn.value
                        ? ColorConstants.nearlyWhite
                        : ColorConstants.grey800,
                    fontSize: ResponsiveUtil().getFontSize(16),
                  ),
                ),
                SizedBox(height: ResponsiveUtil().getSize(16)),
                Divider(height: 1, color: Colors.grey.withOpacity(.3)),
                SizedBox(height: ResponsiveUtil().getSize(24)),

                // Legacy menu items
                RepaintBoundary(
                  key: ValueKey('drawer_home'),
                  child: _buildListTile(
                    false,
                    0,
                    CommonConstants.home.tr,
                    ImageConstant.iconBottomHome,
                    () {
                      homeController.isCheckDrawer.value = 0;
                      Get.back();
                    },
                    false,
                  ),
                ),
                SizedBox(height: ResponsiveUtil().getSize(8)),
                RepaintBoundary(
                  key: ValueKey('drawer_language'),
                  child: _buildListTile(
                    false,
                    1,
                    CommonConstants.changeLanguage.tr,
                    "assets/o7lite/icons/ic_change_language.svg",
                    () {
                      homeController.isCheckDrawer.value = 1;
                      Get.toNamed(Routes.CHANGE_LANGUAGE);
                    },
                    false,
                  ),
                ),
                SizedBox(height: ResponsiveUtil().getSize(8)),
                RepaintBoundary(
                  key: ValueKey('drawer_dark_mode'),
                  child: _buildListTile(
                    true,
                    2,
                    CommonConstants.darkMode.tr,
                    "assets/o7lite/icons/ic_dark_mode.svg",
                    () {
                      homeController.isCheckDrawer.value = 2;
                    },
                    false,
                  ),
                ),
                SizedBox(height: ResponsiveUtil().getSize(8)),
                RepaintBoundary(
                  key: ValueKey('drawer_privacy'),
                  child: _buildListTile(
                    false,
                    3,
                    CommonConstants.privacyPolicy.tr,
                    "assets/o7lite/icons/ic_policy.svg",
                    () {
                      homeController.isCheckDrawer.value = 3;
                      _launchUrl(AppSecrets.privacyPolicyUrlFallback);
                    },
                    false,
                  ),
                ),
                SizedBox(height: ResponsiveUtil().getSize(8)),
                RepaintBoundary(
                  key: ValueKey('drawer_support'),
                  child: _buildListTile(
                    false,
                    4,
                    CommonConstants.support.tr,
                    "assets/o7lite/icons/ic_support.svg",
                    () {
                      homeController.isCheckDrawer.value = 4;
                      sendEmail(email: AppSecrets.supportEmailFallback);
                    },
                    false,
                  ),
                ),
                SizedBox(height: ResponsiveUtil().getSize(8)),
                RepaintBoundary(
                  key: ValueKey('drawer_troubleshooting'),
                  child: _buildListTile(
                    false,
                    5,
                    CommonConstants.troubleshootingHelp.tr,
                    ImageConstant.iconTroubleShooting,
                    () {
                      homeController.isCheckDrawer.value = 5;
                      Get.toNamed(Routes.TROUBLE_SHOOTING_PAGE);
                    },
                    false,
                  ),
                ),
                RepaintBoundary(
                  key: ValueKey('drawer_app_setting'),
                  child: _buildListTile(
                    false,
                    6,
                    CommonConstants.appSetting.tr,
                    ImageConstant.iconSetting,
                    () {
                      homeController.isCheckDrawer.value = 6;
                      Get.toNamed(Routes.APP_SETTING);
                    },
                    false,
                  ),
                ),
                RepaintBoundary(
                  key: ValueKey('drawer_dashboard'),
                  child: _buildListTile(
                    false,
                    7,
                    CommonConstants.dashboard.tr,
                    ImageConstant.iconDashboard,
                    () {
                      homeController.isCheckDrawer.value = 7;
                      _launchUrl(AppSecrets.merchantDashboardUrlFallback);
                    },
                    false,
                  ),
                ),
                RepaintBoundary(
                  key: ValueKey('drawer_user_guide'),
                  child: _buildListTile(
                    false,
                    8,
                    CommonConstants.userGuide.tr,
                    ImageConstant.iconUserGuide,
                    () {
                      homeController.isCheckDrawer.value = 8;
                      _launchUrl(AppSecrets.userGuideUrlFallback);
                    },
                    false,
                  ),
                ),
                RepaintBoundary(
                  key: ValueKey('drawer_sign_out'),
                  child: _buildListTile(
                    false,
                    9,
                    CommonConstants.signOut.tr,
                    "assets/o7lite/icons/ic_logout.svg",
                    () {
                      homeController.isCheckDrawer.value = 9;
                      CustomDialog.showCustomDialog(
                        titleButton: CommonConstants.ok.tr,
                        content: CommonConstants.tittleExitApp.tr,
                        context: Get.context!,
                        onpressCancel: () {
                          Get.back();
                        },
                        onPressedCheck: () async {
                          await _performLogout();
                        },
                        dialogType: AppDialogType.confirm,
                      );
                    },
                    true,
                  ),
                ),
                SizedBox(height: ResponsiveUtil().getSize(32)),

                // Version information at bottom
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: Obx(() => Text(
                          'v${homeController.versionName.value} (#${homeController.versionCode.value})',
                          style: TextStyle(
                            fontSize: 11,
                            color: appController.isDarkModeOn.value
                                ? Colors.white.withOpacity(0.5)
                                : Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        )),
                  ),
                ),
                SizedBox(height: ResponsiveUtil().getSize(100)),
              ],
            ),
          ),
        ));
  }

  /// Performs the full logout flow:
  /// 1. Calls GW3 logout API to invalidate the token server-side (GW3 only)
  /// 2. Clears local session data
  /// 3. Navigates to login screen
  ///
  /// The local clear always runs even if the API call fails, so the user
  /// is never stuck in a logged-in state.
  Future<void> _performLogout() async {
    await EasyLoading.show(status: '${CommonConstants.loading.tr}...');

    try {
      // Debug: Check state BEFORE clearing
      if (kDebugMode) {
        final preRememberTid =
            await SecureSharedPreferences.instance.getRememberTid();
        final preTid = await SecureSharedPreferences.instance.getTID();
        LogUtils.debugLog(
            '[RememberTID] LOGOUT BEFORE clear → rememberTid=$preRememberTid, TID=$preTid');
      }

      // Call server-side logout for GW3 to invalidate the token
      if (StorageService.isGw3) {
        try {
          final apiProvider = Get.find<ApiProvider>();
          final response = await apiProvider.logOutGw3();
          if (kDebugMode) {
            print('[Logout] GW3 logout API response: ${response.statusCode}');
          }
        } catch (e) {
          // Don't block logout if API call fails
          if (kDebugMode) {
            print('[Logout] GW3 logout API error: $e');
          }
        }
      }

      // Clear local session data
      await SecureSharedPreferences.instance.clearSessionOnly();
      await SharedPrefManager.instance.clearSessionOnly();

      // Debug: Check state AFTER clearing
      if (kDebugMode) {
        final postRememberTid =
            await SecureSharedPreferences.instance.getRememberTid();
        final postTid = await SecureSharedPreferences.instance.getTID();
        LogUtils.debugLog(
            '[RememberTID] LOGOUT AFTER clear → rememberTid=$postRememberTid, TID=$postTid');
      }
    } finally {
      await EasyLoading.dismiss();
    }

    Get.delete<AuthController>(force: true);
    Get.offAllNamed(Routes.LOG_IN, arguments: {'isLogout': true});
  }

  Future<void> _launchUrl(String url) async {
    if (url.isNotEmpty) {
      try {
        final Uri urlSupport = Uri.parse(url);
        bool canLaunch = await canLaunchUrl(urlSupport);
        if (canLaunch) {
          await launchUrl(urlSupport, mode: LaunchMode.externalApplication);
        } else {
          // Copy URL to clipboard if can't launch
          await Clipboard.setData(ClipboardData(text: url));
          Get.snackbar(
            CommonConstants.info.tr,
            CommonConstants.cannotOpenBrowser.tr,
            backgroundColor: ColorConstants.orangeColor,
            colorText: ColorConstants.white,
          );
        }
      } catch (e) {
        // Fallback: copy to clipboard
        await Clipboard.setData(ClipboardData(text: url));
        Get.snackbar(
          CommonConstants.error.tr,
          CommonConstants.cannotOpenURL.tr,
          backgroundColor: ColorConstants.orangeColor,
          colorText: ColorConstants.white,
        );
      }
    }
  }

  Future<void> sendEmail({String? email}) async {
    String? encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map((MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: encodeQueryParameters(<String, String>{
        'subject': CommonConstants.emailSubject.tr,
        'body': CommonConstants.emailBody.tr
      }),
    );

    try {
      launchUrl(emailLaunchUri);
    } catch (e) {
      Get.snackbar(
        CommonConstants.error.tr,
        CommonConstants.couldNotLaunchEmail.tr,
        backgroundColor: ColorConstants.red,
        colorText: ColorConstants.white,
      );
    }
  }

  /// Legacy ListTile for non-GW3 users
  ListTile _buildListTile(
    bool isCheckDarkMode,
    int index,
    String title,
    String iconPath,
    Function() function,
    bool isCheckColor,
  ) {
    // Pre-calculate values to avoid repeated calculations during scrolling
    final isDarkMode = appController.isDarkModeOn.value;
    final isSelected = homeController.isCheckDrawer.value == index;
    final iconSize = ResponsiveUtil().getSize(24);
    final fontSize = ResponsiveUtil().getFontSize(16);

    // Pre-calculate colors based on state
    final Color selectedAccent = ColorConstants.backgroundColorButtonPrint;
    final iconColor = isCheckColor
        ? ColorConstants.red
        : (isSelected
            ? selectedAccent
            : (isDarkMode ? ColorConstants.lightGray : ColorConstants.black));

    final textColor = isSelected
        ? selectedAccent
        : (isDarkMode ? ColorConstants.lightGray : ColorConstants.black);

    return ListTile(
      leading: SvgPicture.asset(
        iconPath,
        height: iconSize,
        color: iconColor,
      ),
      title: Text(
        title.tr,
        style: isCheckColor
            ? CustomTextStyles.labelRedBlureSize18Fw600
            : TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w400,
              ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        if (isCheckDarkMode) {
          appController.toggleDarkMode();
          return;
        }
        // Ensure selection updates consistently
        homeController.isCheckDrawer.value = index;
        function();
      },
      trailing: isCheckDarkMode
          ? Obx(
              () => Switch(
                value: appController.isDarkModeOn.value,
                activeTrackColor: appController.isDarkModeOn.value
                    ? ColorConstants.grey800
                    : Colors.blueGrey,
                activeColor: ColorConstants.colorBorderTextFieldBold,
                onChanged: (value) {
                  appController.toggleDarkMode();
                },
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
