// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/device_performance_detector.dart';
import '../utils/responsive_util.dart';
import '../constants/colors.dart';
import '../../app_controller.dart';

/// Adaptive loading widget that chooses appropriate loading UI based on device capability
///
/// For low-end devices: Uses simple animated containers instead of shimmer
/// For high-end devices: Uses full shimmer effects for better UX
class AdaptiveLoadingWidget extends StatelessWidget {
  final Widget? child;
  final double? height;
  final double? width;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool isListItem;

  const AdaptiveLoadingWidget({
    Key? key,
    this.child,
    this.height,
    this.width,
    this.margin,
    this.padding,
    this.borderRadius,
    this.isListItem = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AppController appController = Get.find();
    final detector = DevicePerformanceDetector.instance;

    // Early return for uninitialized detector - use simple fallback
    if (!detector.isInitialized) {
      return _buildFallbackLoading(appController);
    }

    // For iOS or complex render trees, prefer lightweight loading
    if (detector.shouldUseShimmerLoading() &&
        !detector.shouldUseSimplifiedUI()) {
      return _buildOptimizedShimmerLoading(appController);
    } else {
      return _buildLightweightLoading(appController);
    }
  }

  /// Ultra-lightweight fallback loading
  Widget _buildFallbackLoading(AppController appController) {
    return SizedBox(
      height: height ?? 60,
      width: width,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              ColorConstants.backgroundColorButtonPrint,
            ),
          ),
        ),
      ),
    );
  }

  /// Lightweight loading for low-end devices - minimized render tree
  Widget _buildLightweightLoading(AppController appController) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        color: appController.isDarkModeOn.value
            ? Colors.grey[800]!.withOpacity(0.3)
            : Colors.grey[200]!.withOpacity(0.5),
      ),
      child: child ?? _buildSimpleLoadingContent(),
    );
  }

  /// Optimized shimmer loading for high-end devices - reduced complexity
  Widget _buildOptimizedShimmerLoading(AppController appController) {
    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: appController.isDarkModeOn.value
            ? Colors.grey[800]!
            : ColorConstants.backgroundColorButtonPrint.withAlpha(30),
        highlightColor: appController.isDarkModeOn.value
            ? Colors.grey[500]!
            : ColorConstants.backgroundColorButtonPrint.withAlpha(10),
        child: Container(
          height: height,
          width: width,
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: child,
        ),
      ),
    );
  }

  /// Simple loading content for lightweight mode
  Widget _buildSimpleLoadingContent() {
    if (isListItem) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Mock image placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(width: 16),
            // Mock text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Default simple loading content
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[300],
      ),
    );
  }
}

/// Optimized dashboard-specific loading widget
class AdaptiveDashboardLoader extends StatelessWidget {
  const AdaptiveDashboardLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AppController appController = Get.find();
    final detector = DevicePerformanceDetector.instance;

    // Always use lightweight loading for better performance
    if (!detector.isInitialized || detector.shouldUseSimplifiedUI()) {
      return _buildLightweightDashboardLoading();
    } else {
      // Even for high-spec, use optimized version to avoid render tree issues
      return _buildOptimizedDashboardLoading(appController);
    }
  }

  Widget _buildLightweightDashboardLoading() {
    return Padding(
      padding: ResponsiveUtil().getPadding(bottom: 120, top: 8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ColorConstants.backgroundColorButtonPrint,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'splashLoading'.tr,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Optimized dashboard loading for high-spec devices
  Widget _buildOptimizedDashboardLoading(AppController appController) {
    return Padding(
      padding: ResponsiveUtil().getPadding(bottom: 120, top: 8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Optimized loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ColorConstants.backgroundColorButtonPrint,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'loadingDashboard'.tr,
              style: TextStyle(
                fontSize: 14,
                color: appController.isDarkModeOn.value
                    ? Colors.white.withOpacity(0.8)
                    : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Optimized transaction history specific loading widget
class AdaptiveTransactionHistoryLoader extends StatelessWidget {
  const AdaptiveTransactionHistoryLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Always use lightweight for better performance on all devices
    return _buildLightweightTransactionLoading();
  }

  Widget _buildLightweightTransactionLoading() {
    return SizedBox(
      height: 400, // Provide fixed height to avoid unbounded constraints
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Simple loading indicator at the top
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorConstants.backgroundColorButtonPrint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'loadingTransactions'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Simple placeholder items with fixed height container
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return AdaptiveLoadingWidget(
                    height: 90,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    borderRadius: BorderRadius.circular(12),
                    isListItem: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Adaptive list view widget with optimized scrolling
class AdaptiveListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final Widget? header;
  final bool shrinkWrap;

  const AdaptiveListView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.header,
    this.shrinkWrap = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final detector = DevicePerformanceDetector.instance;

    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: detector.isInitialized
          ? detector.getOptimalScrollPhysics()
          : const ClampingScrollPhysics(),
      cacheExtent:
          detector.isInitialized ? detector.getOptimalCacheExtent() : 200.0,
      itemCount: header != null ? itemCount + 1 : itemCount,
      itemBuilder: (context, index) {
        if (header != null && index == 0) {
          return header!;
        }

        final actualIndex = header != null ? index - 1 : index;

        // Wrap items in RepaintBoundary for better performance
        return RepaintBoundary(
          key: ValueKey('adaptive_list_item_$actualIndex'),
          child: itemBuilder(context, actualIndex),
        );
      },
    );
  }
}
