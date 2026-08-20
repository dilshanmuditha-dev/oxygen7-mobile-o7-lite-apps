// ignore_for_file: deprecated_member_use, must_be_immutable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_controller.dart';
import '../../shared/constants/colors.dart';
import '../../shared/constants/common.dart';
import '../../shared/utils/responsive_util.dart';
import '../../shared/services/storage_service.dart';
import '../../shared/utils/device_performance_detector.dart';
import 'home_controller.dart';
import 'tabs/dashboard/dashboard_screen.dart';
import 'transaction_history/transaction_history_screen.dart';

class HomeScreen extends GetView<HomeController> {
  HomeScreen({Key? key}) : super(key: key);
  final AppController appController = Get.find();

  @override
  Widget build(BuildContext context) {
    ResponsiveUtil().init(context);

    return WillPopScope(
      onWillPop: () async {
        if (controller.bottomNavIndex.value != 0) {
          controller.setValueBottomIndex(0);
          return false;
        }
        return await controller.onWillPop(context);
      },
      child: Obx(
        () => Scaffold(
          extendBody: true,
          resizeToAvoidBottomInset: false,
          backgroundColor: appController.isDarkModeOn.value
              ? Color(0xFF0f0f23)
              : Color(0xFFf8fafc),
          body: _buildAdaptiveBody(),
          bottomNavigationBar: _buildAdaptiveBottomNav(),
        ),
      ),
    );
  }

  /// Build adaptive body based on device performance
  Widget _buildAdaptiveBody() {
    final detector = DevicePerformanceDetector.instance;

    if (detector.isInitialized && detector.shouldUseSimplifiedUI()) {
      // Simple body for low-spec devices - no gradient
      return _getCurrentWidget();
    } else {
      // Rich body for high-spec devices - with gradient background
      return Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: appController.isDarkModeOn.value
                    ? [
                        Color(0xFF0f0f23),
                        Color(0xFF1a1a2e),
                        Color(0xFF16213e),
                        Color(0xFF0f0f23),
                      ]
                    : [
                        Color(0xFFf8fafc),
                        Color(0xFFe2e8f0),
                        Color(0xFFf1f5f9),
                      ],
              ),
            ),
          ),
          // Main content
          _getCurrentWidget(),
        ],
      );
    }
  }

  /// Build adaptive bottom navigation based on device performance
  Widget _buildAdaptiveBottomNav() {
    final detector = DevicePerformanceDetector.instance;

    return Obx(
      () => !controller.isDonationPressed.value
          ? (detector.isInitialized && detector.shouldUseSimplifiedUI())
              ? _buildSimpleBottomNav()
              : _buildLiquidGlassBottomNav()
          : const SizedBox(),
    );
  }

  /// Simple bottom navigation for low-spec devices
  Widget _buildSimpleBottomNav() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 80,
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: appController.isDarkModeOn.value
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: _buildSimpleNavItem(
                index: 0,
                icon: controller.imagePaths[0],
                selectedIcon: controller.bottomNavSelectedIconPaths[0],
                label: CommonConstants.home.tr,
              ),
            ),
            Expanded(
              child: _buildSimpleNavItem(
                index: 1,
                icon: controller.imagePaths[1],
                selectedIcon: controller.bottomNavSelectedIconPaths[1],
                label: StorageService.isGw3
                    ? CommonConstants.histories.tr
                    : CommonConstants.transactionHistory.tr,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Simple navigation item for low-spec devices
  Widget _buildSimpleNavItem({
    required int index,
    required String icon,
    required String selectedIcon,
    required String label,
  }) {
    return Obx(
      () {
        bool isSelected = controller.bottomNavIndex.value == index;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            controller.setValueBottomIndex(index);
          },
          child: Container(
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                SvgPicture.asset(
                  isSelected ? selectedIcon : icon,
                  height: 28,
                  width: 28,
                  color: isSelected
                      ? ColorConstants.backgroundColorButtonPrint
                      : (appController.isDarkModeOn.value
                          ? Colors.white.withOpacity(0.6)
                          : Color(0xFF6B7280)),
                ),

                SizedBox(height: 6),

                // Label
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? ColorConstants.backgroundColorButtonPrint
                        : (appController.isDarkModeOn.value
                            ? Colors.white.withOpacity(0.6)
                            : Color(0xFF6B7280)),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiquidGlassBottomNav() {
    return Obx(
      () => !controller.isDonationPressed.value
          ? StorageService.isGw3
              ? _buildGw3BottomNav()
              : _buildLegacyBottomNav()
          : const SizedBox(),
    );
  }

  // New GW3 Bottom Navigation following Figma design
  Widget _buildGw3BottomNav() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 11.5, vertical: 16),
      height: 88,
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : Colors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: appController.isDarkModeOn.value
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: _buildGw3NavItem(
                index: 0,
                icon: controller.imagePaths[0],
                selectedIcon: controller.bottomNavSelectedIconPaths[0],
                label: CommonConstants.home.tr,
              ),
            ),
            Expanded(
              child: _buildGw3NavItem(
                index: 1,
                icon: controller.imagePaths[1],
                selectedIcon: controller.bottomNavSelectedIconPaths[1],
                label: CommonConstants.history.tr,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Legacy Bottom Navigation (existing glass effect)
  Widget _buildLegacyBottomNav() {
    return Container(
      margin: EdgeInsets.all(16),
      height: 82,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: appController.isDarkModeOn.value
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: appController.isDarkModeOn.value
                    ? [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                        Colors.blue.withOpacity(0.1),
                      ]
                    : [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
              ),
              border: Border.all(
                color: appController.isDarkModeOn.value
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.8),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    index: 0,
                    icon: controller.imagePaths[0],
                    selectedIcon: controller.bottomNavSelectedIconPaths[0],
                    label: CommonConstants.home.tr,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 1,
                    icon: controller.imagePaths[1],
                    selectedIcon: controller.bottomNavSelectedIconPaths[1],
                    label: CommonConstants.histories.tr,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // GW3 Navigation Item following Figma design
  Widget _buildGw3NavItem({
    required int index,
    required String icon,
    required String selectedIcon,
    required String label,
  }) {
    return Obx(
      () {
        bool isSelected = controller.bottomNavIndex.value == index;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            controller.setValueBottomIndex(index);
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF7E01D7) : Colors.transparent,
              borderRadius: BorderRadius.circular(isSelected ? 80 : 37),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                SvgPicture.asset(
                  isSelected ? selectedIcon : icon,
                  height: 26,
                  width: 26,
                  color: isSelected
                      ? Colors.white
                      : (appController.isDarkModeOn.value
                          ? Colors.white.withOpacity(0.7)
                          : Color(0xFF382F41)),
                ),

                // Label - only show for selected item
                if (isSelected) ...[
                  SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required String icon,
    required String selectedIcon,
    required String label,
  }) {
    return Obx(
      () {
        bool isSelected = controller.bottomNavIndex.value == index;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            controller.setValueBottomIndex(index);
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 12 : 8,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isSelected
                    ? (appController.isDarkModeOn.value
                        ? Colors.blue.withOpacity(0.2)
                        : ColorConstants.backgroundColorButtonPrint
                            .withOpacity(0.2))
                    : Colors.transparent,
                border: isSelected
                    ? Border.all(
                        color: appController.isDarkModeOn.value
                            ? Colors.white.withOpacity(0.3)
                            : ColorConstants.backgroundColorButtonPrint
                                .withOpacity(0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with animation
                  AnimatedContainer(
                    duration: Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.all(isSelected ? 8 : 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? (appController.isDarkModeOn.value
                              ? Colors.white.withOpacity(0.15)
                              : ColorConstants.backgroundColorButtonPrint
                                  .withOpacity(0.15))
                          : Colors.transparent,
                    ),
                    child: AnimatedScale(
                      scale: isSelected ? 1.05 : 1.0,
                      duration: Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      child: SvgPicture.asset(
                        isSelected ? selectedIcon : icon,
                        height: 24,
                        width: 24,
                        color: isSelected
                            ? (appController.isDarkModeOn.value
                                ? Colors.white.withOpacity(0.95)
                                : ColorConstants.backgroundColorButtonPrint)
                            : (appController.isDarkModeOn.value
                                ? Colors.white.withOpacity(0.7)
                                : ColorConstants.grey800?.withOpacity(0.8)),
                      ),
                    ),
                  ),
                  // Label with animation - only show if there's enough space
                  if (isSelected) ...[
                    SizedBox(width: 6),
                    AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 200),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: appController.isDarkModeOn.value
                              ? Colors.white.withOpacity(0.95)
                              : ColorConstants.backgroundColorButtonPrint,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _getCurrentWidget() {
    final detector = DevicePerformanceDetector.instance;

    if (detector.isInitialized && detector.shouldUseSimplifiedUI()) {
      // No animation for low-spec devices - instant switching
      return _getScreenForIndex(controller.bottomNavIndex.value);
    } else {
      // Smooth animation for high-spec devices
      return AnimatedSwitcher(
        duration: detector.isInitialized
            ? detector.getOptimalAnimationDuration()
            : Duration(milliseconds: 250),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _getScreenForIndex(controller.bottomNavIndex.value),
      );
    }
  }

  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return DashBoardScreen(key: ValueKey('dashboard'));
      case 1:
        return TransactionHistory(key: ValueKey('history'));
      default:
        return DashBoardScreen(key: ValueKey('dashboard'));
    }
  }
}
