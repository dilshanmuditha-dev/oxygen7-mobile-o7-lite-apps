// ignore_for_file: depend_on_referenced_packages

import 'package:app/models/response/report_model/report_model.dart';
import 'package:app/modules/main/app_setting/app_setting_controller.dart';
import 'package:app/modules/main/home_controller.dart';
import 'package:app/shared/utils/utils.dart';
import 'package:app/shared/widgets/custom_text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../../app_controller.dart';
import '../../../models/route_payment_model.dart';
import '../../../routes/app_pages.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/common.dart';
import 'package:animate_gradient/animate_gradient.dart';

import '../../../shared/constants/constants_o7lite.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/utils/responsive_util.dart';
import '../../../shared/widgets/animation/wave_animation_widget.dart';
import '../../../shared/utils/animation/animation_style.dart' as app_animation;
import '../../../shared/widgets/custom_dialog/custom_dialog.dart';

class PaymentList extends GetView<HomeController> {
  PaymentList({
    Key? key,
    this.indexPageBack,
  }) : super(key: key);
  final AppController appController = Get.find();
  final int indexPage = Get.arguments ?? 0;
  final bool? indexPageBack;
  final ScrollController scrollController = ScrollController();
  final AppSettingController appSettingController = Get.find();

  // Note: selectedPaymentIndex removed as we navigate directly on tap

  // View mode tracking (true = grid view, false = list view)
  final RxBool isGridView = true.obs;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
          extendBodyBehindAppBar: isAnimationEnabled,
          appBar: AppBar(
            centerTitle: true,
            elevation: 0,
            backgroundColor: isAnimationEnabled
                ? Colors.transparent
                : (appController.isDarkModeOn.value
                    ? ColorConstants.grey800
                    : Colors.white),
            title: Text(
              indexPage == 0
                  ? CommonConstants.digitalPayment.tr
                  : indexPage == 1
                      ? CommonConstants.reports.tr
                      : CommonConstants.voidText.tr,
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
                indexPageBack == true
                    ? controller.setValueBottomIndex(0)
                    : Get.back();
              },
              icon: Icon(
                Icons.arrow_back,
                color: appController.isDarkModeOn.value
                    ? ColorConstants.white
                    : Color(0xFF382F41),
                size: 24,
              ),
            ),
          ),
          body: _buildNewDesign(),
        ),
      );
    });
  }

  Widget _buildNewDesign() {
    final bool isAnimationEnabled =
        appSettingController.isEnableAppAnimation.value;
    final double topPadding = isAnimationEnabled
        ? kToolbarHeight + MediaQuery.of(Get.context!).padding.top
        : 0;

    return Column(
      children: [
        // Content area
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16 + topPadding, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and View Mode Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        indexPage == 2
                            ? CommonConstants.selectPaymentToRefund.tr
                            : CommonConstants.selectPaymentMethod.tr,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: appController.isDarkModeOn.value
                              ? Colors.white
                              : Color(0xFF382F41),
                        ),
                      ),
                    ),

                    SizedBox(width: 16),

                    // View Mode Toggle Button
                    Obx(() => _buildViewModeToggle()),
                  ],
                ),

                SizedBox(height: 24),

                // Payment Methods Grid
                Obx(() {
                  if (controller.listWalletType.isEmpty) {
                    return Container(
                      height: 300,
                      child: Center(
                        child: Lottie.asset(
                          'assets/o7lite/images/lt_payment.json',
                          height: 160,
                        ),
                      ),
                    );
                  }

                  return Obx(() => GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isGridView.value ? 2 : 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isGridView.value
                              ? 171 / 76 // Grid view ratio from Figma
                              : 343 / 76, // List view ratio (full width)
                        ),
                        itemCount: controller.listWalletType.length,
                        itemBuilder: (context, index) {
                          return Obx(() => _buildPaymentMethodCard(
                                controller.listWalletType[index],
                                index,
                              ));
                        },
                      ));
                }),

                SizedBox(height: 32), // Space at bottom
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(RoutePaymentModel paymentMethod, int index) {
    final isActivated = paymentMethod.isActivated;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isActivated
            ? () => _onPaymentMethodTap(paymentMethod, index)
            : null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive sizing based on available width
            final isSmallScreen = constraints.maxWidth < 180;
            final iconSize = isSmallScreen ? 36.0 : 40.0;
            final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
            final iconSpacing = isSmallScreen ? 12.0 : 16.0;

            return Container(
              height: 76,
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
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Icon container - Responsive sizing
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: isActivated
                            ? Colors.white
                            : (appController.isDarkModeOn.value
                                ? ColorConstants.grey800
                                : Colors.grey.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: isActivated
                            ? (StorageService.isGw3
                                ? getBrandImageWidgetV2(
                                    paymentMethod,
                                    height: iconSize,
                                  )
                                : Image.asset(
                                    paymentMethod.image,
                                    width: iconSize,
                                    height: iconSize,
                                    fit: BoxFit.cover,
                                  ))
                            : ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  Colors.grey,
                                  BlendMode.saturation,
                                ),
                                child: StorageService.isGw3
                                    ? getBrandImageWidgetV2(
                                        paymentMethod,
                                        height: iconSize,
                                      )
                                    : Image.asset(
                                        paymentMethod.image,
                                        width: iconSize,
                                        height: iconSize,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                      ),
                    ),

                    SizedBox(width: iconSpacing),

                    // Payment method name - Responsive text
                    Expanded(
                      child: _buildResponsivePaymentTitle(
                        paymentMethod.title?.toUpperCase() ?? '',
                        isActivated,
                        constraints.maxWidth,
                      ),
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

  Widget _buildViewModeToggle() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => isGridView.value = !isGridView.value,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isGridView.value
                ? Icons.grid_view_rounded
                : Icons.view_list_rounded,
            size: 20,
            color: appController.isDarkModeOn.value
                ? Colors.white.withOpacity(0.8)
                : Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsivePaymentTitle(
      String title, bool isActivated, double availableWidth) {
    // Calculate optimal font size based on available width and text length
    double baseFontSize = 14.0;

    // Adjust font size based on screen width and text length
    if (availableWidth < 180) {
      // Very small screens
      baseFontSize = title.length > 12 ? 11.0 : 12.0;
    } else if (availableWidth < 200) {
      // Small screens
      baseFontSize = title.length > 15 ? 12.0 : 13.0;
    } else {
      // Normal and large screens
      baseFontSize = title.length > 20 ? 12.0 : 14.0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle = TextStyle(
          fontFamily: 'Open Sans',
          fontSize: baseFontSize,
          fontWeight: FontWeight.w600,
          color: isActivated
              ? (appController.isDarkModeOn.value
                  ? Colors.white
                  : Color(0xFF382F41))
              : (appController.isDarkModeOn.value
                  ? Colors.white.withOpacity(0.5)
                  : Colors.grey),
          height: 1.2, // Tighter line height
        );

        // Check if text fits in one line
        final textPainter = TextPainter(
          text: TextSpan(text: title, style: textStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);

        // If text fits in one line or is very short, use single line
        if (!textPainter.didExceedMaxLines || title.length < 8) {
          return Text(
            title,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
          );
        }

        // For longer text that needs 2 lines, use FittedBox with careful handling
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth *
                  1.2, // Allow slight overflow for better fitting
            ),
            child: Text(
              title,
              style: textStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ),
        );
      },
    );
  }

  // Removed _buildSelectButton as we navigate directly on tap

  void _onPaymentMethodTap(RoutePaymentModel paymentMethod, int index) {
    if (!paymentMethod.isActivated) {
      Get.snackbar(
        CommonConstants.oops.tr,
        CommonConstants.paymentMethodDisabled.tr,
        backgroundColor: ColorConstants.backgroundColorButtonPrint,
        colorText: ColorConstants.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
      );
      return;
    }

    // Navigate directly to the next screen
    _navigateToNextScreen(paymentMethod);
  }

  void _navigateToNextScreen(RoutePaymentModel selectedPayment) {
    if (indexPage == 0) {
      // Digital Payment
      if (selectedPayment.acquirerDigital == ConstantsO7Lite.CARD_TYPE) {
        Get.toNamed(Routes.PAYMENT_PAGE_QR_O7LITE);
      } else {
        Get.toNamed(
          Routes.DIGITAL_PAYMENT,
          arguments: selectedPayment,
        );
      }
    } else if (indexPage == 1) {
      // Reports
      var reportModel = ReportModel(
        acquirer: selectedPayment.acquireReport,
        currency: selectedPayment.currency,
        creditCardActivated:
            selectedPayment.creditCardActivated ?? CommonConstants.textEmpty,
        isBoost: selectedPayment.isBoost,
        brand: selectedPayment.brand,
      );

      Get.toNamed(
        Routes.REPORT_SCREEN,
        arguments: reportModel,
      );
    } else if (indexPage == 2) {
      // Refund
      if (selectedPayment.isActivated && selectedPayment.acquirerVoid != null) {
        if (selectedPayment.acquirerVoid == ConstantsO7Lite.DASH_TYPE) {
          CustomDialog.showToast(CommonConstants.textNotSupportVoidDashPAY);
          return;
        } else if (selectedPayment.acquirerVoid ==
            ConstantsO7Lite.IOUPAY_TYPE) {
          CustomDialog.showToast(CommonConstants.textNotSupportVoidIOUPAY);
          return;
        }

        Get.toNamed(
          Routes.REFUND_SCREEN,
          arguments: ReportModel(
            acquirer: selectedPayment.acquirerVoid,
            currency: selectedPayment.currency,
            creditCardActivated: selectedPayment.creditCardActivated ??
                CommonConstants.textEmpty,
            isBoost: selectedPayment.isBoost,
          ),
        );
      }
    }
  }

  // Removed _onSelectPressed as we navigate directly on tap

  // Legacy widgets - keeping for backward compatibility but not used in new design
  Widget widgetAnimation() {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: AnimateGradient(
        primaryBegin: Alignment.topLeft,
        primaryEnd: Alignment.bottomLeft,
        secondaryBegin: Alignment.bottomLeft,
        secondaryEnd: Alignment.topRight,
        primaryColors: [
          appSettingController.isEnableAppAnimation.value
              ? Colors.purple
              : appController.isDarkModeOn.value
                  ? ColorConstants.black
                  : Colors.grey.withOpacity(.1),
          appSettingController.isEnableAppAnimation.value
              ? Colors.purpleAccent
              : appController.isDarkModeOn.value
                  ? ColorConstants.black
                  : Colors.grey.withOpacity(.1),
          appController.isDarkModeOn.value
              ? ColorConstants.black
              : Colors.grey.withOpacity(.1),
        ],
        secondaryColors: [
          appSettingController.isEnableAppAnimation.value
              ? Colors.blue
              : appController.isDarkModeOn.value
                  ? ColorConstants.black
                  : Colors.grey.withOpacity(.1),
          appSettingController.isEnableAppAnimation.value
              ? Colors.blueAccent
              : appController.isDarkModeOn.value
                  ? ColorConstants.black
                  : Colors.grey.withOpacity(.1),
          appController.isDarkModeOn.value
              ? ColorConstants.black
              : Colors.grey.withOpacity(.1),
        ],
        child: Padding(
          padding: ResponsiveUtil().getPadding(
            right: 16,
            left: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: ResponsiveUtil().getSize(34),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: appController.isDarkModeOn.value
                          ? ColorConstants.grey800
                          : ColorConstants.white,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: ResponsiveUtil().getPadding(
                            all: 20,
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Text(
                              indexPage == 2
                                  ? CommonConstants.paymentVoidMethods.tr
                                  : CommonConstants.paymentMethods.tr,
                              style: CustomTextStyles.labelBlack500Size20Fw600,
                            ),
                          ),
                        ),
                        Obx(
                          () {
                            return controller.listWalletType.isEmpty
                                ? Lottie.asset(
                                    'assets/o7lite/images/lt_payment.json',
                                    height: ResponsiveUtil().getSize(160),
                                  )
                                : GridView.builder(
                                    padding: EdgeInsets.all(0),
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8.0,
                                      mainAxisSpacing: 8.0,
                                    ),
                                    itemCount: controller.listWalletType.length,
                                    itemBuilder: (context, index) {
                                      return Material(
                                        color: appController.isDarkModeOn.value
                                            ? ColorConstants.grey800
                                            : ColorConstants.white,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            splashColor: ColorConstants
                                                .backgroundColorButtonPrint
                                                .withOpacity(.26),
                                            onTap: () {
                                              if (!controller
                                                  .listWalletType[index]
                                                  .isActivated) {
                                                Get.snackbar(
                                                  CommonConstants.oops.tr,
                                                  CommonConstants
                                                      .paymentMethodDisabled.tr,
                                                  backgroundColor: ColorConstants
                                                      .backgroundColorButtonPrint,
                                                  colorText:
                                                      ColorConstants.white,
                                                  snackPosition:
                                                      SnackPosition.BOTTOM,
                                                  duration:
                                                      Duration(seconds: 2),
                                                );
                                                return;
                                              }

                                              if (indexPage == 0) {
                                                if (controller
                                                        .listWalletType[index]
                                                        .acquirerDigital ==
                                                    ConstantsO7Lite.CARD_TYPE) {
                                                  Get.toNamed(Routes
                                                      .PAYMENT_PAGE_QR_O7LITE);
                                                } else {
                                                  Get.toNamed(
                                                    Routes.DIGITAL_PAYMENT,
                                                    arguments: controller
                                                        .listWalletType[index],
                                                  );
                                                }
                                              } else if (indexPage == 1) {
                                                RoutePaymentModel
                                                    routePaymentModel =
                                                    controller
                                                        .listWalletType[index];

                                                var reportModel = ReportModel(
                                                  acquirer: routePaymentModel
                                                      .acquireReport,
                                                  currency: routePaymentModel
                                                      .currency,
                                                  creditCardActivated:
                                                      routePaymentModel
                                                              .creditCardActivated ??
                                                          CommonConstants
                                                              .textEmpty,
                                                  isBoost:
                                                      routePaymentModel.isBoost,
                                                  brand:
                                                      routePaymentModel.brand,
                                                );

                                                Get.toNamed(
                                                  Routes.REPORT_SCREEN,
                                                  arguments: reportModel,
                                                );
                                              } else if (indexPage == 2) {
                                                if (controller
                                                        .listWalletType[index]
                                                        .isActivated &&
                                                    controller
                                                            .listWalletType[
                                                                index]
                                                            .acquirerVoid !=
                                                        null) {
                                                  if (controller
                                                          .listWalletType[index]
                                                          .acquirerVoid ==
                                                      ConstantsO7Lite
                                                          .DASH_TYPE) {
                                                    CustomDialog.showToast(
                                                        CommonConstants
                                                            .textNotSupportVoidDashPAY);
                                                    return;
                                                  } else if (controller
                                                          .listWalletType[index]
                                                          .acquirerVoid ==
                                                      ConstantsO7Lite
                                                          .IOUPAY_TYPE) {
                                                    CustomDialog.showToast(
                                                        CommonConstants
                                                            .textNotSupportVoidIOUPAY);
                                                    return;
                                                  }

                                                  Get.toNamed(
                                                    Routes.REFUND_SCREEN,
                                                    arguments: ReportModel(
                                                      acquirer: controller
                                                          .listWalletType[index]
                                                          .acquirerVoid,
                                                      currency: controller
                                                          .listWalletType[index]
                                                          .currency,
                                                      creditCardActivated: controller
                                                              .listWalletType[
                                                                  index]
                                                              .creditCardActivated ??
                                                          CommonConstants
                                                              .textEmpty,
                                                      isBoost: controller
                                                          .listWalletType[index]
                                                          .isBoost,
                                                    ),
                                                  );
                                                } else {
                                                  Container();
                                                }
                                              }
                                            },
                                            child: Padding(
                                              padding: ResponsiveUtil()
                                                  .getPadding(all: 8),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(6),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: appController
                                                                    .isDarkModeOn
                                                                    .value
                                                                ? ColorConstants
                                                                    .grey800
                                                                : ColorConstants
                                                                    .darkGray
                                                                    .withAlpha(
                                                                        50),
                                                          ),
                                                          padding:
                                                              EdgeInsets.all(1),
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            child: controller
                                                                    .listWalletType[
                                                                        index]
                                                                    .isActivated
                                                                ? StorageService
                                                                        .isGw3
                                                                    ? getBrandImageWidgetV2(
                                                                        controller
                                                                            .listWalletType[index],
                                                                        height:
                                                                            ResponsiveUtil().getSize(120),
                                                                        // fit: BoxFit
                                                                        //     .fitHeight,
                                                                      )
                                                                    : Image
                                                                        .asset(
                                                                        controller
                                                                            .listWalletType[index]
                                                                            .image,
                                                                        width: ResponsiveUtil()
                                                                            .getSize(120),
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      )
                                                                : ColorFiltered(
                                                                    colorFilter:
                                                                        ColorFilter
                                                                            .mode(
                                                                      Colors
                                                                          .grey,
                                                                      BlendMode
                                                                          .saturation,
                                                                    ),
                                                                    child: Image
                                                                        .asset(
                                                                      controller
                                                                          .listWalletType[
                                                                              index]
                                                                          .image,
                                                                      // height: ResponsiveUtil()
                                                                      //     .getSize(
                                                                      //         120),
                                                                      // width: ResponsiveUtil()
                                                                      //     .getSize(
                                                                      //         120),
                                                                      // fit: BoxFit
                                                                      //     .fitHeight,
                                                                    ),
                                                                  ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: ResponsiveUtil()
                                                        .getSize(8),
                                                  ),
                                                  Text(
                                                    controller
                                                            .listWalletType[
                                                                index]
                                                            .title
                                                            ?.toUpperCase() ??
                                                        '',
                                                    textAlign: TextAlign.center,
                                                    style: CustomTextStyles
                                                        .labelBlack500Size14Fw400,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                          },
                        ),
                        SizedBox(
                          height: ResponsiveUtil().getSize(24),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: ResponsiveUtil().getSize(24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget widgetNotAnimation() {
    return Scaffold(
      backgroundColor:
          appController.isDarkModeOn.value ? null : Colors.grey.withOpacity(.1),
      body: Padding(
        padding: EdgeInsets.only(
          top: 34,
          right: 16,
          left: 16,
          bottom: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: appController.isDarkModeOn.value
                      ? ColorConstants.grey800
                      : ColorConstants.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: ResponsiveUtil().getPadding(
                        all: 20,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          indexPage == 2
                              ? CommonConstants.paymentVoidMethods.tr
                              : CommonConstants.paymentMethods.tr,
                          style: CustomTextStyles.labelBlack500Size20Fw600,
                        ),
                      ),
                    ),
                    Obx(
                      () {
                        return controller.listWalletType.isEmpty
                            ? Lottie.asset(
                                'assets/o7lite/images/lt_payment.json',
                                height: ResponsiveUtil().getSize(160),
                              )
                            : GridView.builder(
                                padding: EdgeInsets.all(0),
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8.0,
                                  mainAxisSpacing: 8.0,
                                ),
                                itemCount: controller.listWalletType.length,
                                itemBuilder: (context, index) {
                                  return Material(
                                    color: appController.isDarkModeOn.value
                                        ? ColorConstants.grey800
                                        : ColorConstants.white,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        splashColor: ColorConstants
                                            .backgroundColorButtonPrint
                                            .withOpacity(.26),
                                        onTap: () {
                                          if (!controller.listWalletType[index]
                                              .isActivated) return;

                                          if (indexPage == 0) {
                                            if (controller.listWalletType[index]
                                                    .acquirerDigital ==
                                                ConstantsO7Lite.CARD_TYPE) {
                                              Get.toNamed(Routes
                                                  .PAYMENT_PAGE_QR_O7LITE);
                                            } else {
                                              Get.toNamed(
                                                Routes.DIGITAL_PAYMENT,
                                                arguments: controller
                                                    .listWalletType[index],
                                              );
                                            }
                                          } else if (indexPage == 1) {
                                            RoutePaymentModel
                                                routePaymentModel = controller
                                                    .listWalletType[index];

                                            var reportModel = ReportModel(
                                              acquirer: routePaymentModel
                                                  .acquireReport,
                                              currency:
                                                  routePaymentModel.currency,
                                              creditCardActivated:
                                                  routePaymentModel
                                                          .creditCardActivated ??
                                                      CommonConstants.textEmpty,
                                              isBoost:
                                                  routePaymentModel.isBoost,
                                              brand: routePaymentModel.brand,
                                            );

                                            Get.toNamed(
                                              Routes.REPORT_SCREEN,
                                              arguments: reportModel,
                                            );
                                          } else if (indexPage == 2) {
                                            if (controller.listWalletType[index]
                                                    .isActivated &&
                                                controller.listWalletType[index]
                                                        .acquirerVoid !=
                                                    null) {
                                              if (controller
                                                      .listWalletType[index]
                                                      .acquirerVoid ==
                                                  ConstantsO7Lite.DASH_TYPE) {
                                                CustomDialog.showToast(
                                                    CommonConstants
                                                        .textNotSupportVoidDashPAY);
                                                return;
                                              } else if (controller
                                                      .listWalletType[index]
                                                      .acquirerVoid ==
                                                  ConstantsO7Lite.IOUPAY_TYPE) {
                                                CustomDialog.showToast(
                                                    CommonConstants
                                                        .textNotSupportVoidIOUPAY);
                                                return;
                                              }

                                              Get.toNamed(
                                                Routes.REFUND_SCREEN,
                                                arguments: ReportModel(
                                                  acquirer: controller
                                                      .listWalletType[index]
                                                      .acquirerVoid,
                                                  currency: controller
                                                      .listWalletType[index]
                                                      .currency,
                                                  creditCardActivated: controller
                                                          .listWalletType[index]
                                                          .creditCardActivated ??
                                                      CommonConstants.textEmpty,
                                                  isBoost: controller
                                                      .listWalletType[index]
                                                      .isBoost,
                                                ),
                                              );
                                            } else {
                                              Container();
                                            }
                                          }
                                        },
                                        child: Padding(
                                          padding: ResponsiveUtil()
                                              .getPadding(all: 8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Padding(
                                                  padding: EdgeInsets.all(6),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: appController
                                                                .isDarkModeOn
                                                                .value
                                                            ? ColorConstants
                                                                .grey800
                                                            : ColorConstants
                                                                .darkGray
                                                                .withAlpha(50),
                                                      ),
                                                      padding:
                                                          EdgeInsets.all(1),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        child: controller
                                                                .listWalletType[
                                                                    index]
                                                                .isActivated
                                                            ? StorageService
                                                                    .isGw3
                                                                ? getBrandImageWidgetV2(
                                                                    controller
                                                                            .listWalletType[
                                                                        index],
                                                                    height: ResponsiveUtil()
                                                                        .getSize(
                                                                            120),
                                                                    // fit: BoxFit
                                                                    //     .fitHeight,
                                                                  )
                                                                : Image.asset(
                                                                    controller
                                                                        .listWalletType[
                                                                            index]
                                                                        .image,
                                                                    width: ResponsiveUtil()
                                                                        .getSize(
                                                                            120),
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  )
                                                            : ColorFiltered(
                                                                colorFilter:
                                                                    ColorFilter
                                                                        .mode(
                                                                  Colors.grey,
                                                                  BlendMode
                                                                      .saturation,
                                                                ),
                                                                child: StorageService
                                                                        .isGw3
                                                                    ? getBrandImageWidgetV2(
                                                                        controller
                                                                            .listWalletType[index],
                                                                        height:
                                                                            ResponsiveUtil().getSize(120),
                                                                        // fit: BoxFit
                                                                        //     .fitHeight,
                                                                      )
                                                                    : Image
                                                                        .asset(
                                                                        controller
                                                                            .listWalletType[index]
                                                                            .image,
                                                                        width: ResponsiveUtil()
                                                                            .getSize(120),
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height:
                                                    ResponsiveUtil().getSize(8),
                                              ),
                                              Text(
                                                controller.listWalletType[index]
                                                        .title
                                                        ?.toUpperCase() ??
                                                    '',
                                                textAlign: TextAlign.center,
                                                style: CustomTextStyles
                                                    .labelBlack500Size14Fw400,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                      },
                    ),
                    SizedBox(
                      height: ResponsiveUtil().getSize(24),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
