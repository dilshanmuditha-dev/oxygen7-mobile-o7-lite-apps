// ignore_for_file: deprecated_member_use, avoid_print

import 'package:app/app_controller.dart';
import 'package:app/modules/main/home_controller.dart';
import 'package:app/routes/app_pages.dart';
import 'package:app/shared/constants/colors.dart';
import 'package:app/shared/constants/image_constant.dart';
import 'package:app/shared/utils/creditcard_follow_type.dart';
import 'package:app/shared/utils/responsive_util.dart';
import 'package:app/shared/widgets/custom_dialog/custom_dialog.dart';
import 'package:app/shared/widgets/dialog_common.dart';
import 'package:app/shared/widgets/adaptive_loading_widget.dart';
import 'package:app/shared/utils/device_performance_detector.dart';
import 'package:app/shared/utils/pref_utils.dart';
// import 'package:carousel_slider/carousel_slider.dart'; // Unused - carousel disabled
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../../../shared/constants/common.dart';
import '../../../../shared/services/storage_service.dart';
import '../../../../shared/widgets/custom_text_style.dart';
import '../../../../shared/widgets/drawer_widget.dart';
import '../../../../shared/widgets/animation/wave_animation_widget.dart';
import '../../../../shared/utils/animation/animation_style.dart'
    as app_animation;
import '../../../main/app_setting/app_setting_controller.dart';

class DashBoardScreen extends GetView<HomeController> {
  DashBoardScreen({Key? key}) : super(key: key);
  final AppController appController = Get.find();
  AppSettingController get appSettingController =>
      Get.find<AppSettingController>();

  // Create unique scaffold key for this screen instance
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final bool isAnimationEnabled =
            appSettingController.isEnableAppAnimation.value;

        return WaveAnimationWidget(
          enabled: isAnimationEnabled,
          style: app_animation.AnimationStyle.values.firstWhere(
            (s) => s.name == appSettingController.selectedAnimationStyle.value,
            orElse: () => app_animation.AnimationStyle.wave,
          ),
          isDarkMode: appController.isDarkModeOn.value,
          child: Scaffold(
            backgroundColor: isAnimationEnabled
                ? Colors.transparent
                : (appController.isDarkModeOn.value
                    ? ColorConstants.darkScaffoldBackgroundColor
                    : Color(0xFFFBFBFB)),
            key: _scaffoldKey,
            drawer: DrawerBarScreen(
              logoAsset: ImageConstant.oxpayIconTransparentBackgroundSvg,
            ),
            appBar: _buildAppBar(),
            extendBody: true,
            extendBodyBehindAppBar: isAnimationEnabled,
            body: RepaintBoundary(
              child: Container(
                height: MediaQuery.of(context).size.height,
                child: controller.isDonationPressed.value
                    ? _buildDonationLayout()
                    : controller.isLoading.value
                        ? const AdaptiveDashboardLoader()
                        : StorageService.isGw3
                            ? _buildGw3Layout()
                            : _buildLegacyLayout(),
              ),
            ),
          ),
        );
      },
    );
  }

  // New GW3 layout matching Figma design with adaptive performance
  Widget _buildGw3Layout() {
    final detector = DevicePerformanceDetector.instance;
    final bool isAnimationEnabled =
        appSettingController.isEnableAppAnimation.value;
    final double topPadding = isAnimationEnabled
        ? kToolbarHeight + MediaQuery.of(Get.context!).padding.top + 16
        : 16;

    // Calculate bottom padding to ensure last item is fully visible
    final bottomSafeArea = MediaQuery.of(Get.context!).padding.bottom;
    final bottomPadding =
        120 + bottomSafeArea + 24; // Extra 24 for breathing room

    return RefreshIndicator(
      onRefresh: () => controller.refreshTerminalData(),
      color: ColorConstants.backgroundColorButtonPrint,
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
      child: ListView(
        physics: detector.isInitialized
            ? detector.getOptimalScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        padding:
            ResponsiveUtil().getPadding(bottom: bottomPadding, top: topPadding),
        cacheExtent:
            detector.isInitialized ? detector.getOptimalCacheExtent() : 500,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Additional legacy items for non-donation users
                if (!controller.isDonationActive.value) ...[
                  SizedBox(height: 16),
                  _buildAdditionalMenuItems(),
                ],

                // Main Menu Items - Matching Figma Design
                _buildFigmaMenuItems(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build main menu items matching Figma design
  Widget _buildFigmaMenuItems() {
    return Column(
      children: [
        // Digital Payment
        RepaintBoundary(
          key: ValueKey('digital_payment_figma'),
          child: _buildFigmaMenuItem(
            title: CommonConstants.digitalPayment.tr,
            subtitle: 'dashboardDigitalPaymentSubtitle'.tr,
            icon: ImageConstant.iconDashboardDigitalPayment,
            gradientColors: [Color(0xFF7062F3), Color(0xFF1F0CC9)],
            onTap: () {
              Get.toNamed(Routes.PAYMENT_LIST, arguments: 0);
            },
          ),
        ),

        SizedBox(height: 16),

        // Refund
        RepaintBoundary(
          key: ValueKey('refund_figma'),
          child: _buildFigmaMenuItem(
            title: CommonConstants.refund.tr,
            subtitle: 'dashboardRefundSubtitle'.tr,
            icon: ImageConstant.iconDashboardRefund,
            gradientColors: [Color(0xFFF75145), Color(0xFFDD1F11)],
            onTap: () {
              Get.toNamed(Routes.PAYMENT_LIST_VOID, arguments: true);
            },
          ),
        ),

        SizedBox(height: 16),

        // Reports
        RepaintBoundary(
          key: ValueKey('reports_figma'),
          child: _buildFigmaMenuItem(
            title: CommonConstants.reports.tr,
            subtitle: 'dashboardReportsSubtitle'.tr,
            icon: ImageConstant.iconDashboardReport,
            gradientColors: [Color(0xFF0CB991), Color(0xFF087F63)],
            onTap: () {
              Get.toNamed(Routes.PAYMENT_LIST, arguments: 1);
            },
          ),
        ),

        // SizedBox(height: 16),

        // // Create Payment
        // RepaintBoundary(
        //   key: ValueKey('create_payment_figma'),
        //   child: _buildFigmaMenuItem(
        //     title: CommonConstants.createPayment.tr,
        //     subtitle: 'Generate a secure payment URL to share',
        //     icon: ImageConstant.iconDashboardCreditCard,
        //     gradientColors: [Color(0xFFE5850A), Color(0xFFC57209)],
        //     onTap: () {
        //       Get.toNamed(
        //         Routes.PAYMENT_PAGE_QR_O7LITE,
        //         arguments: CreditCardFollowType.DASHBOARD,
        //       );
        //     },
        //   ),
        // ),

        // Hide Scan2Pay and Click2Pay for WizarPOS and Castle devices
        if (!appController.isWizarPosDevice.value &&
            !appController.isCastleDevice.value) ...[
          SizedBox(height: 16),
          RepaintBoundary(
            key: ValueKey('scan2pay_figma'),
            child: _buildFigmaMenuItem(
              title: 'dashboardScan2Pay'.tr,
              subtitle: 'dashboardScan2PaySubtitle'.tr,
              icon: ImageConstant.iconDashboardScan2Pay,
              gradientColors: [Color(0xFFE5850A), Color(0xFFC57209)],
              onTap: () {
                Get.toNamed(
                  Routes.PAYMENT_PAGE_QR_O7LITE,
                  arguments: {'mode': 'scan2pay'},
                );
              },
            ),
          ),
        ],

        if (appController.isMobileUser.value) ...[
          SizedBox(height: 16),
          RepaintBoundary(
            key: ValueKey('click2pay_figma'),
            child: _buildFigmaMenuItem(
              title: 'dashboardClick2Pay'.tr,
              subtitle: 'dashboardClick2PaySubtitle'.tr,
              icon: ImageConstant.iconDashboardClick2Pay,
              gradientColors: [Color(0xFFE5850A), Color(0xFFC57209)],
              onTap: () {
                Get.toNamed(
                  Routes.PAYMENT_PAGE_QR_O7LITE,
                  arguments: {'mode': 'click2pay'},
                );
              },
            ),
          ),
        ],

        if (controller.hasEnabledCardPayment.value) ...[
          const SizedBox(height: 16),
          RepaintBoundary(
            key: const ValueKey('wizarpos_card_payment_figma'),
            child: _buildFigmaMenuItem(
              title: 'dashboardCardPayment'.tr,
              subtitle: 'dashboardCardPaymentSubtitle'.tr,
              icon: ImageConstant.iconDashboardCreditCard,
              gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
              onTap: _openWizarPosCardPayment,
            ),
          ),
        ],

        // Castle Device - Razer Credit (at the end)
        if (appController.isCastleDevice.value) ...[
          SizedBox(height: 16),
          RepaintBoundary(
            key: ValueKey('razer_credit_figma'),
            child: _buildFigmaMenuItem(
              title: 'dashboardCardPayment'.tr,
              subtitle: 'dashboardCardPaymentSubtitle'.tr,
              icon: ImageConstant.iconDashboardCreditCard,
              gradientColors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              onTap: () async {
                await LaunchApp.openApp(
                  androidPackageName: 'com.cardbiz.razercredits1',
                );
              },
            ),
          ),
        ],

        // Landi Device with MineSec (at the end)
        if (appController.isLandiDevice.value &&
            appController.isEnableMineSec.value) ...[
          SizedBox(height: 16),
          RepaintBoundary(
            key: ValueKey('landi_card_payment_figma'),
            child: _buildFigmaMenuItem(
              title: 'dashboardCardPayment'.tr,
              subtitle: 'dashboardCardPaymentSubtitle'.tr,
              icon: ImageConstant.iconDashboardCreditCard,
              gradientColors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              onTap: () async {
                controller.openLandiApp();
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openWizarPosCardPayment() async {
    final didOpen = await SystemInfo.openWizarPosCardPaymentApp();
    if (didOpen) return;

    Get.dialog(
      CustomAlertDialog(
        title: 'Card Payment app is not installed. Please contact support.',
        onPressed: () => Get.back(),
      ),
    );
  }

  // Build Figma-style menu item with adaptive performance
  Widget _buildFigmaMenuItem({
    required String title,
    required String subtitle,
    required String icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final detector = DevicePerformanceDetector.instance;
    final shouldSimplify =
        detector.isInitialized && detector.shouldUseSimplifiedUI();

    return Container(
      // Increased height to accommodate 2-line subtitle
      constraints: BoxConstraints(
        minHeight: 84,
        maxHeight: 100,
      ),
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
        // Simplify shadows for low-spec devices
        boxShadow: shouldSimplify
            ? []
            : [
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
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon container with adaptive decoration
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    // Use solid color for low-spec, gradient for high-spec
                    gradient: shouldSimplify
                        ? null
                        : LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: gradientColors,
                          ),
                    color: shouldSimplify ? gradientColors.first : null,
                  ),
                  child: shouldSimplify
                      ? SvgPicture.asset(icon, fit: BoxFit.contain)
                      : RepaintBoundary(
                          child: SvgPicture.asset(icon, fit: BoxFit.contain)),
                ),

                SizedBox(width: 14),

                // Text content - Optimized for small devices
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 16, // Reduced from 18
                          fontWeight: FontWeight.w600,
                          color: appController.isDarkModeOn.value
                              ? Colors.white
                              : Color(0xFF382F41),
                          letterSpacing: 0,
                          height: 1.1, // Tighter line height
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 4), // Minimal spacing

                      // Subtitle - Optimized for 2 lines
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontSize: 12, // Reduced from 14
                              fontWeight: FontWeight.w400,
                              color: appController.isDarkModeOn.value
                                  ? Colors.white.withOpacity(0.8)
                                  : Color(0xFF6B7280), // Slightly lighter gray
                              letterSpacing: 0,
                              height: 1.2, // Optimized line height
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build additional menu items for specific conditions
  Widget _buildAdditionalMenuItems() {
    return Column(
      children: [
        // Credit Card (if activated)
        if (controller.isCreditCardActivated.value) ...[
          RepaintBoundary(
            child: _buildFigmaMenuItem(
              title: CommonConstants.creditCard.tr,
              subtitle: 'dashboardCreditCardSubtitle'.tr,
              icon: ImageConstant.iconCreditCard,
              gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
              onTap: () {
                Get.toNamed(
                  Routes.CREDIT_CARD,
                  arguments: controller.mCreditCardCurrency,
                );
              },
            ),
          ),
          SizedBox(height: 16),
        ],

        // Donation (if active)
        if (controller.isDonationActive.value) ...[
          RepaintBoundary(
            child: _buildFigmaMenuItem(
              title: CommonConstants.donate.tr,
              subtitle: 'dashboardDonateSubtitle'.tr,
              icon: ImageConstant.iconDonate,
              gradientColors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              onTap: () {
                controller.donationAction();
              },
            ),
          ),
          SizedBox(height: 16),
        ],

        // Sunmi Card Payment
        if (appController.isSunmiDevice.value &&
            !appController.isSGPLocation()) ...[
          RepaintBoundary(
            child: _buildFigmaMenuItem(
              title: 'dashboardCardPayment'.tr,
              subtitle: 'dashboardCardPaymentSunmiSubtitle'.tr,
              icon: ImageConstant.iconCreditCard,
              gradientColors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              onTap: () async {
                try {
                  await LaunchApp.openApp(
                    androidPackageName: 'com.pos.router.pay_dee',
                  );
                } catch (e) {
                  try {
                    await LaunchApp.openApp(
                      androidPackageName: 'com.sc.mf919',
                    );
                  } catch (e) {
                    Get.dialog(
                      CustomAlertDialog(
                        title: CommonConstants.creditCardModeActivated.tr,
                        onPressed: () => Get.back(),
                      ),
                    );
                  }
                }
              },
            ),
          ),
          SizedBox(height: 16),
        ],

        // Landi Device with MineSec
        if (appController.isLandiDevice.value &&
            appController.isEnableMineSec.value) ...[
          RepaintBoundary(
            child: _buildFigmaMenuItem(
              title: 'dashboardCardPayment'.tr,
              subtitle: 'dashboardCardPaymentLandiSubtitle'.tr,
              icon: ImageConstant.iconCreditCard,
              gradientColors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              onTap: () async {
                controller.openLandiApp();
              },
            ),
          ),
          SizedBox(height: 16),
        ],
      ],
    );
  }

  // Check if any payment method is activated
  bool _isAnyPaymentMethodActivated() {
    return controller.isAlipayActivated ||
        controller.isGrabPayActivated ||
        controller.isWechatPayActivated ||
        controller.isDashActivated ||
        controller.isPayNowActivated ||
        controller.isAtomeActivated ||
        controller.isThaiQRActivated ||
        controller.isBootTouchNGoActivated ||
        controller.isTouchNGoActivated ||
        controller.isCreditCardActivated.value ||
        controller.isShopeeActivated ||
        controller.isIouPayActivated;
  }

  // Build app bar matching Figma design
  PreferredSizeWidget _buildAppBar() {
    // Use transparent AppBar when animation is enabled
    final bool isAnimationEnabled =
        appSettingController.isEnableAppAnimation.value;

    return AppBar(
      centerTitle: true,
      elevation: 0,
      backgroundColor: isAnimationEnabled
          ? Colors.transparent
          : (appController.isDarkModeOn.value
              ? ColorConstants.grey800
              : Colors.white),
      title: SvgPicture.asset(
        ImageConstant.oxpayIconTransparentBackgroundSvg,
        fit: BoxFit.contain,
        width: 58,
        height: 26,
        color: appController.isDarkModeOn.value ? Colors.white : null,
      ),
      automaticallyImplyLeading: false,
      leading: controller.isDonationPressed.value
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: appController.isDarkModeOn.value
                    ? ColorConstants.white
                    : ColorConstants.grey800,
              ),
              onPressed: () => controller.donationAction(),
            )
          : null,
      actions: [
        if (!controller.isDonationPressed.value)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              splashRadius: 24,
              icon: SvgPicture.asset(
                ImageConstant.iconDashboardSettings,
                height: 24,
                width: 24,
                color: appController.isDarkModeOn.value ? Colors.white : null,
              ),
              onPressed: () {
                // Open drawer immediately without expensive logic
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ),
      ],
    );
  }

  // Legacy layout for non-GW3 users
  Widget _buildLegacyLayout() {
    final bool isAnimationEnabled =
        appSettingController.isEnableAppAnimation.value;
    final double topPadding = isAnimationEnabled
        ? kToolbarHeight + MediaQuery.of(Get.context!).padding.top + 8
        : 8;

    // Calculate bottom padding to ensure last item is fully visible
    final bottomSafeArea = MediaQuery.of(Get.context!).padding.bottom;
    final bottomPadding =
        120 + bottomSafeArea + 24; // Extra 24 for breathing room

    return RefreshIndicator(
      onRefresh: () => controller.refreshTerminalData(),
      color: ColorConstants.backgroundColorButtonPrint,
      backgroundColor: appController.isDarkModeOn.value
          ? ColorConstants.grey800
          : Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: ResponsiveUtil()
              .getPadding(bottom: bottomPadding, top: topPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Carousel slider section (disabled)
              // TODO: To enable carousel slider, uncomment the code below
              /*
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CarouselSlider(...),
                // ... rest of carousel code
              ],
            ),
            */
              SizedBox(height: ResponsiveUtil().getSize(150)),

              // Legacy menu items
              Padding(
                padding: ResponsiveUtil().getPadding(right: 24, left: 24),
                child: Row(
                  children: [
                    controller.isCreditCardActivated.value
                        ? buildCategoryRow(
                            () {
                              Get.toNamed(
                                Routes.CREDIT_CARD,
                                arguments: controller.mCreditCardCurrency,
                              );
                            },
                            CommonConstants.creditCard.tr,
                            ImageConstant.iconCreditCard,
                            Color(0XFFffeeef),
                            false,
                          )
                        : const SizedBox.shrink(),
                    SizedBox(
                      width: controller.isCreditCardActivated.value
                          ? ResponsiveUtil().getSize(24)
                          : 0,
                    ),
                    buildCategoryRow(
                      () {
                        if (_isAnyPaymentMethodActivated()) {
                          Get.toNamed(Routes.PAYMENT_LIST, arguments: 0);
                        } else {
                          CustomDialog.showToast(
                            CommonConstants.noDigitalWalletMode.tr,
                          );
                        }
                      },
                      CommonConstants.digitalPayment.tr,
                      ImageConstant.iconPaymentBold,
                      Color(0XFFeeedff),
                      false,
                    ),
                  ],
                ),
              ),

              SizedBox(height: ResponsiveUtil().getSize(30)),

              // More legacy menu items...
              Padding(
                padding: ResponsiveUtil().getPadding(right: 24, left: 24),
                child: Row(
                  children: [
                    buildCategoryRow(
                      () {
                        if (_isAnyPaymentMethodActivated()) {
                          Get.toNamed(Routes.PAYMENT_LIST, arguments: 1);
                        } else {
                          CustomDialog.showToast(
                            CommonConstants.noDigitalWalletMode.tr,
                          );
                        }
                      },
                      CommonConstants.reports.tr,
                      ImageConstant.iconDocument,
                      Color(0XFFeff8ec),
                      false,
                    ),
                    SizedBox(
                      width: !controller.isDonationActive.value
                          ? ResponsiveUtil().getSize(24)
                          : 0,
                    ),
                    !controller.isDonationActive.value
                        ? buildCategoryRow(
                            () {
                              if (_isAnyPaymentMethodActivated()) {
                                Get.toNamed(
                                  Routes.PAYMENT_LIST_VOID,
                                  arguments: true,
                                );
                              } else {
                                CustomDialog.showToast(
                                    CommonConstants.noDigitalWalletMode.tr);
                              }
                            },
                            CommonConstants.refund.tr,
                            ImageConstant.iconVoid,
                            Color(0XFFf5f5ff),
                            false,
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),

              // Additional legacy items...
              // Hide Create Payment for Sunmi and WizarPOS devices
              !appController.isSunmiDevice.value &&
                      !appController.isWizarPosDevice.value
                  ? Padding(
                      padding: ResponsiveUtil().getPadding(
                        top: 30,
                        right: 24,
                        left: 24,
                      ),
                      child: Row(
                        children: [
                          buildCategoryRow(
                            () {
                              Get.toNamed(Routes.PAYMENT_PAGE_QR_O7LITE,
                                  arguments: CreditCardFollowType.DASHBOARD);
                            },
                            CommonConstants.createPayment.tr,
                            ImageConstant.iconPaymentBold,
                            Color(0XFFDCF4F5),
                            true,
                          )
                        ],
                      ),
                    )
                  : SizedBox.shrink(),

              // Continue with other legacy items...
              appController.isSunmiDevice.value &&
                      !appController.isSGPLocation()
                  ? Padding(
                      padding: ResponsiveUtil().getPadding(
                        right: 24,
                        left: 24,
                        top: 30,
                      ),
                      child: buildCategoryRowNonFlex(
                        () async {
                          try {
                            await LaunchApp.openApp(
                              androidPackageName: 'com.pos.router.pay_dee',
                            );
                          } catch (e) {
                            try {
                              await LaunchApp.openApp(
                                androidPackageName: 'com.sc.mf919',
                              );
                            } catch (e) {
                              Get.dialog(
                                CustomAlertDialog(
                                  title: CommonConstants
                                      .creditCardModeActivated.tr,
                                  onPressed: () => Get.back(),
                                ),
                              );
                            }
                          }
                        },
                        'dashboardCardPayment'.tr,
                        ImageConstant.iconCreditCard,
                        Color(0XFFDCF4F5),
                        true,
                      ),
                    )
                  : const SizedBox.shrink(),

              // Donation
              Padding(
                padding: ResponsiveUtil().getPadding(
                  top: 30,
                  right: 24,
                  left: 24,
                ),
                child: Row(
                  children: [
                    controller.isDonationActive.value
                        ? buildCategoryRow(
                            () {
                              controller.donationAction();
                            },
                            CommonConstants.donate.tr,
                            ImageConstant.iconDonate,
                            Color(0XFFDCF4F5),
                            true,
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),

              SizedBox(height: ResponsiveUtil().getSize(30)),

              // Device-specific items
              appController.isCastleDevice.value
                  ? InkWell(
                      onTap: () async {
                        await LaunchApp.openApp(
                          androidPackageName: 'com.cardbiz.razercredits1',
                        );
                      },
                      child: Container(
                        padding: ResponsiveUtil().getPadding(all: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(300),
                          border: Border.all(
                            width: ResponsiveUtil().getSize(4),
                            color: ColorConstants.white,
                          ),
                        ),
                        child: SvgPicture.asset(
                          ImageConstant.iconCreditCard,
                          color: ColorConstants.backgroundColorButtonPrint,
                          height: ResponsiveUtil().getSize(40),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),

              appController.isLandiDevice.value &&
                      appController.isEnableMineSec.value
                  ? InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: () async {
                        controller.openLandiApp();
                      },
                      child: Container(
                        padding: ResponsiveUtil().getPadding(all: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(300),
                          border: Border.all(
                            width: ResponsiveUtil().getSize(4),
                            color: ColorConstants.white,
                          ),
                        ),
                        child: SvgPicture.asset(
                          ImageConstant.iconCreditCard,
                          color: ColorConstants.backgroundColorButtonPrint,
                          height: ResponsiveUtil().getSize(40),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),

              SizedBox(height: ResponsiveUtil().getSize(100)),
            ],
          ),
        ),
      ),
    );
  }

  // Donation layout
  Widget _buildDonationLayout() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        alignment: Alignment.center,
        width: ResponsiveUtil().getSize(200),
        child: controller.listWalletTypePayNow.isEmpty
            ? Lottie.asset(
                'assets/o7lite/images/lt_payment.json',
                height: ResponsiveUtil().getSize(160),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: controller.listWalletTypePayNow.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    splashColor: ColorConstants.backgroundColorButtonPrint
                        .withOpacity(.26),
                    onTap: () {
                      Get.toNamed(
                        Routes.DIGITAL_PAYMENT,
                        arguments: controller.listWalletTypePayNow[index],
                      );
                    },
                    child: Padding(
                      padding: ResponsiveUtil().getPadding(all: 16),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              controller.listWalletTypePayNow[index].image,
                              height: ResponsiveUtil().getSize(160),
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtil().getSize(10)),
                          Text(
                            controller.listWalletTypePayNow[index].title ?? '',
                            textAlign: TextAlign.center,
                            style: CustomTextStyles.labelBlack500Size14Fw400,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  // Legacy category row widgets (keeping for non-GW3 users)
  Widget buildCategoryRow(
    Function() onTap,
    String label,
    String iconPath,
    Color color,
    bool ischeckSizeIcon,
  ) {
    final AppController appController = Get.find();
    return Expanded(
      flex: 1,
      child: Container(
        height: ResponsiveUtil().getSize(78),
        decoration: BoxDecoration(
          color: appController.isDarkModeOn.value
              ? ColorConstants.grey800
              : ColorConstants.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          shadowColor: appController.isDarkModeOn.value
              ? ColorConstants.grey800
              : ColorConstants.white,
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: appController.isDarkModeOn.value
              ? ColorConstants.grey800
              : ColorConstants.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            splashColor: appController.isDarkModeOn.value
                ? ColorConstants.grey800
                : ColorConstants.white,
            onTap: onTap,
            child: Padding(
              padding: ResponsiveUtil().getPadding(left: 16, right: 16),
              child: Row(
                children: [
                  SvgPicture.asset(
                    iconPath,
                    color: ColorConstants.backgroundColorButtonPrint,
                    height: ischeckSizeIcon
                        ? ResponsiveUtil().getSize(38)
                        : ResponsiveUtil().getSize(32),
                  ),
                  SizedBox(width: ResponsiveUtil().getSize(16)),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CustomTextStyles.labelPurple500Size14Fw600,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCategoryRowNonFlex(
    Function() onTap,
    String label,
    String iconPath,
    Color color,
    bool ischeckSizeIcon,
  ) {
    final AppController appController = Get.find();
    return Container(
      height: ResponsiveUtil().getSize(78),
      decoration: BoxDecoration(
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : ColorConstants.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        shadowColor: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : ColorConstants.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        color: appController.isDarkModeOn.value
            ? ColorConstants.grey800
            : ColorConstants.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          splashColor: appController.isDarkModeOn.value
              ? ColorConstants.grey800
              : ColorConstants.white,
          onTap: onTap,
          child: Padding(
            padding: ResponsiveUtil().getPadding(left: 16, right: 16),
            child: Row(
              children: [
                SvgPicture.asset(
                  iconPath,
                  color: ColorConstants.backgroundColorButtonPrint,
                  height: ischeckSizeIcon
                      ? ResponsiveUtil().getSize(38)
                      : ResponsiveUtil().getSize(32),
                ),
                SizedBox(width: ResponsiveUtil().getSize(16)),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CustomTextStyles.labelPurple500Size14Fw600,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Legacy methods removed - functionality now handled by Figma design
}
