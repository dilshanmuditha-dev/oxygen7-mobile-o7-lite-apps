import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/shared/constants/colors.dart';
import 'package:app/shared/utils/log_utils.dart';

import '../scanner_overlay_geometry.dart';
import 'scanner_overlay_painters.dart';

/// Decorative, interaction-free scanner overlay hosted above the live camera
/// preview and below the top bar.
///
/// This [StatefulWidget] owns the single [AnimationController] that drives the
/// animated scan line and paints the three decorative layers (mask, frame, and
/// line) from the single geometry source [ScannerOverlayGeometry]. It observes
/// the controller's [hasScanned] flag to stop and hide the line the moment a
/// barcode is detected, and it degrades gracefully when the ticker cannot start
/// or when the host device should not animate.
///
/// The widget never touches barcode detection or navigation; the caller wraps
/// it in `IgnorePointer` and `ExcludeSemantics` so it stays invisible to both
/// pointer events and assistive technology.
class ScannerOverlay extends StatefulWidget {
  /// Creates a scanner overlay.
  ///
  /// [geometry] is the shared source of truth for the scan window, [screenSize]
  /// is the full screen size used to compute that window, and [hasScanned] is
  /// the controller's reactive scan-state flag. Set [renderScanLine] to `false`
  /// on a Low_Performance_Device to render only the static frame (Req 7.2).
  /// [accentColor] falls back to [ColorConstants.backgroundColorButtonPrint]
  /// when null.
  const ScannerOverlay({
    super.key,
    required this.geometry,
    required this.screenSize,
    required this.hasScanned,
    this.renderScanLine = true,
    this.accentColor,
  });

  /// The pure geometry helper shared with `MobileScanner.scanWindow`.
  final ScannerOverlayGeometry geometry;

  /// The full screen size the scan window is centered within.
  final Size screenSize;

  /// The controller's reactive flag that becomes `true` on a successful scan.
  final RxBool hasScanned;

  /// Whether the animated scan line should render. Defaults to `true`; set to
  /// `false` on a Low_Performance_Device (Req 7.2).
  final bool renderScanLine;

  /// The accent color for the frame and line. Falls back to
  /// [ColorConstants.backgroundColorButtonPrint] when null.
  final Color? accentColor;

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  /// Drives the scan line sweep. Runs for two seconds per edge-to-edge pass
  /// (Req 4.4) and repeats in reverse for a continuous top -> bottom -> top
  /// motion.
  late final AnimationController _controller;

  /// The worker that stops the animation when [ScannerOverlay.hasScanned]
  /// becomes `true` (Req 5.3). Disposed alongside the widget.
  Worker? _scanWorker;

  /// Whether the scan line layer is currently rendered. Set to `false` when the
  /// ticker cannot start, when the device should not animate, or once a barcode
  /// has been detected.
  bool _scanLineActive = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Start the continuous sweep only when the device should animate (Req 7.2).
    if (widget.renderScanLine) {
      try {
        _controller.repeat(reverse: true); // Req 4.1 / 5.2
        _scanLineActive = true;
      } catch (error) {
        // Ticker could not start: render the frame without the line (Req 5.5)
        // while leaving barcode scanning fully functional.
        _scanLineActive = false;
        LogUtils.debugLog('ScannerOverlay animation failed to start: $error');
      }
    }

    // Stop and hide the line within 200ms of a successful detection
    // (Req 5.3 / 4.5). The worker is stored and disposed in [dispose].
    _scanWorker = ever<bool>(widget.hasScanned, (bool scanned) {
      if (scanned) {
        _stopScanLine();
      }
    });
  }

  /// Stops the ticker and hides the scan line layer.
  void _stopScanLine() {
    if (!mounted) return;
    _controller.stop();
    if (_scanLineActive) {
      setState(() {
        _scanLineActive = false;
      });
    }
  }

  @override
  void dispose() {
    // Cancel the reactive worker first, then release the ticker (Req 5.4).
    _scanWorker?.dispose();
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Rect windowRect =
        widget.geometry.computeWindowRect(widget.screenSize);
    final Color accent =
        widget.accentColor ?? ColorConstants.backgroundColorButtonPrint;

    return Stack(
      children: [
        // Dark mask with the window punched out (Req 2).
        Positioned.fill(
          child: CustomPaint(
            painter: ScanMaskPainter(
              rect: windowRect,
              maskOpacity: widget.geometry.maskOpacity,
            ),
          ),
        ),
        // Square border + accented corner brackets (Req 3).
        Positioned.fill(
          child: CustomPaint(
            painter: ScanFramePainter(
              rect: windowRect,
              accentColor: accent,
            ),
          ),
        ),
        // Animated scan line, isolated behind a RepaintBoundary so only the
        // line region repaints and the camera preview never rebuilds
        // (Req 6.6 / 7.1). Omitted entirely when the line is inactive.
        if (_scanLineActive)
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  // Derive the sweep direction from the live controller status
                  // each frame. With `repeat(reverse: true)`, `reverse` means
                  // the value is decreasing (t going 1 -> 0, beam moving up);
                  // any other status means the value is increasing (beam moving
                  // down). Reading the status here needs no extra status
                  // listener or setState because the builder already rebuilds
                  // every frame (Req 4.6).
                  final SweepDirection direction =
                      _controller.status == AnimationStatus.reverse
                          ? SweepDirection.up
                          : SweepDirection.down;
                  return CustomPaint(
                    painter: ScanLinePainter(
                      rect: windowRect,
                      t: _controller.value,
                      geometry: widget.geometry,
                      accentColor: accent,
                      direction: direction,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
