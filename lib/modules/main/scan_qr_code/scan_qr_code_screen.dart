// ignore_for_file: deprecated_member_use

import 'package:app/shared/utils/log_utils.dart';
import 'package:app/shared/utils/responsive_util.dart';
import 'package:app/shared/widgets/custom_text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/common.dart';
import 'scan_qr_code_controller.dart';
import 'scanner_overlay_geometry.dart';
import 'widgets/scanner_overlay.dart';

class ScanQRCodeScreen extends GetView<ScanQrCodeController> {
  ScanQRCodeScreen({Key? key}) : super(key: key);

  final ScanQrCodeController scanQrCodeController = Get.find();

  @override
  Widget build(BuildContext context) {
    // Single source of truth: the same responsive rect drives both the
    // MobileScanner detection window and the decorative overlay painters, so
    // detection and visuals cannot drift (Req 1.2, 6.2). Recomputed each build
    // from MediaQuery so it re-centers on orientation / size changes (Req 1.5).
    final Size size = MediaQuery.of(context).size;
    const ScannerOverlayGeometry geometry = ScannerOverlayGeometry();
    final Rect windowRect = geometry.computeWindowRect(size);

    return Scaffold(
      body: Stack(
        children: [
          // Live camera preview + detection. Built ONCE at the base of the
          // Stack and NEVER wrapped in an Obx, so overlay/state rebuilds never
          // reconstruct it (Req 6.6, 14.4). Bound to the controller-owned
          // Camera_Controller so the controller drives the camera lifecycle
          // explicitly (Req 14). The detection region is the responsive scan
          // window; the detection / navigation contract (handleBarcode) is
          // unchanged.
          MobileScanner(
            controller: controller.cameraController,
            onDetect: controller.handleBarcode,
            scanWindow: windowRect,
            // Log detection errors without crashing the screen (Req 13.4).
            onDetectError: (error, stackTrace) {
              LogUtils.debugLog(
                  'MobileScanner detect error: $error\n$stackTrace');
            },
            // Camera_Error_State: replaces the previously blank/black failure
            // preview for camera-start failures and permission denial
            // (Req 13.1, 13.2). errorBuilder is
            // Widget Function(BuildContext, MobileScannerException) in
            // mobile_scanner v7, and MobileScannerException exposes errorCode.
            errorBuilder: (context, error) => _CameraErrorState(
              permissionDenied:
                  error.errorCode == MobileScannerErrorCode.permissionDenied,
              onRetry: controller.retryScan,
            ),
          ),
          // Decorative overlay: dimmed mask + square frame + animated scan line.
          // Wrapped in Obx so toggling renderScanLine rebuilds only this layer,
          // in IgnorePointer so it never intercepts top bar taps (Req 6.5), and
          // in ExcludeSemantics so assistive technology ignores the purely
          // decorative layers (Req 10.1, 10.2). Layered below the top bar so the
          // top bar controls stay interactive and reachable (Req 6.5, 10.3).
          Obx(
            () => ExcludeSemantics(
              child: IgnorePointer(
                child: ScannerOverlay(
                  geometry: geometry,
                  screenSize: size,
                  hasScanned: controller.hasScanned,
                  renderScanLine: controller.renderScanLine.value,
                ),
              ),
            ),
          ),
          // Top bar (back / title / switch-camera) — unchanged behavior.
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 34,
              horizontal: 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => controller.navigateBack(),
                  icon: Icon(
                    Icons.arrow_back,
                    color: ColorConstants.white,
                    size: ResponsiveUtil().getSize(24),
                  ),
                ),
                Text(
                  CommonConstants.scanQR.tr,
                  style: CustomTextStyles.labelStepWhite700Size18Fw600,
                  textAlign: TextAlign.center,
                ),
                IconButton(
                  icon: Icon(
                    Icons.switch_camera,
                    color: ColorConstants.white,
                  ),
                  onPressed: () {
                    controller.toggleCamera();
                  },
                ),
              ],
            ),
          ),
          // Optional Align_Hint positioned just below the scan window, centered
          // horizontally, using the same title text style (Req 9.1, 9.6). Hidden
          // when showAlignHint is false (Req 9.2).
          Positioned(
            top: windowRect.bottom + ResponsiveUtil().getSize(24),
            left: 0,
            right: 0,
            child: Obx(
              () => controller.showAlignHint.value
                  ? Text(
                      CommonConstants.scanAlignHint.tr,
                      textAlign: TextAlign.center,
                      style: CustomTextStyles.labelStepWhite700Size18Fw600,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // Top-most overlay: the Timeout_Prompt (Req 12.2/12.4/12.5). Kept in
          // its own Obx so only this layer rebuilds on uiState changes; the
          // base MobileScanner is untouched (Req 6.6). Rendered as an
          // overlay-in-Stack rather than a Get.dialog so it composes with the
          // existing Stack.
          Obx(
            () => controller.uiState.value == ScanUiState.timedOut
                ? _TimeoutPrompt(
                    onRetry: controller.retryScan,
                    onCancel: controller.cancelFromTimeout,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Timeout_Prompt overlay shown when the Scan_Timeout elapses without a
/// detection (Req 12.2). A full-screen scrim plus a centered card offering
/// Retry (restart camera + countdown) and Cancel (stop camera, return null).
class _TimeoutPrompt extends StatelessWidget {
  const _TimeoutPrompt({
    required this.onRetry,
    required this.onCancel,
  });

  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: ColorConstants.black.withOpacity(0.6),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtil().getSize(32),
        ),
        child: Container(
          padding: EdgeInsets.all(ResponsiveUtil().getSize(24)),
          decoration: BoxDecoration(
            color: ColorConstants.blackText,
            borderRadius: BorderRadius.circular(ResponsiveUtil().getSize(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                CommonConstants.scanTimeoutTitle.tr,
                textAlign: TextAlign.center,
                style: CustomTextStyles.labelStepWhite700Size18Fw600,
              ),
              SizedBox(height: ResponsiveUtil().getSize(12)),
              Text(
                CommonConstants.scanTimeoutMessage.tr,
                textAlign: TextAlign.center,
                style: CustomTextStyles.bodySmallWhite,
              ),
              SizedBox(height: ResponsiveUtil().getSize(24)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorConstants.white,
                        side: BorderSide(color: ColorConstants.white),
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveUtil().getSize(12),
                        ),
                      ),
                      child: Text(CommonConstants.cancel.tr),
                    ),
                  ),
                  SizedBox(width: ResponsiveUtil().getSize(12)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            ColorConstants.backgroundColorButtonPrint,
                        foregroundColor: ColorConstants.white,
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveUtil().getSize(12),
                        ),
                      ),
                      child: Text(CommonConstants.scanRetry.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Camera_Error_State rendered by [MobileScanner.errorBuilder] when the camera
/// cannot start or permission is denied (Req 13.1, 13.2). It fully replaces the
/// blank/black preview with a solid background, an explanatory message, a Retry
/// action, and — only for permission denial — an "Open settings" action wired
/// to permission_handler's [openAppSettings].
class _CameraErrorState extends StatelessWidget {
  const _CameraErrorState({
    required this.permissionDenied,
    required this.onRetry,
  });

  final bool permissionDenied;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorConstants.black,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtil().getSize(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            permissionDenied ? Icons.no_photography : Icons.videocam_off,
            color: ColorConstants.white,
            size: ResponsiveUtil().getSize(56),
          ),
          SizedBox(height: ResponsiveUtil().getSize(16)),
          Text(
            permissionDenied
                ? CommonConstants.scanCameraPermission.tr
                : CommonConstants.scanCameraUnavailable.tr,
            textAlign: TextAlign.center,
            style: CustomTextStyles.labelStepWhite700Size18Fw600,
          ),
          SizedBox(height: ResponsiveUtil().getSize(24)),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.backgroundColorButtonPrint,
              foregroundColor: ColorConstants.white,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtil().getSize(32),
                vertical: ResponsiveUtil().getSize(12),
              ),
            ),
            child: Text(CommonConstants.scanRetry.tr),
          ),
          if (permissionDenied) ...[
            SizedBox(height: ResponsiveUtil().getSize(12)),
            TextButton(
              onPressed: openAppSettings,
              style: TextButton.styleFrom(
                foregroundColor: ColorConstants.white,
              ),
              child: Text(CommonConstants.scanOpenSettings.tr),
            ),
          ],
        ],
      ),
    );
  }
}
