import 'package:flutter/widgets.dart';

/// Decides whether the decorative scanner animation (the Scan_Line) should run.
///
/// No dedicated device-performance helper exists in the codebase, so this
/// policy provides a tiny, self-contained gate. It defaults the animation ON
/// (the device is treated as capable) and only classifies a device as a
/// Low_Performance_Device when the heuristic returns `false`.
///
/// The gate is a single boolean, so it can later delegate to a real
/// device-performance detector without changing any call site.
class ScannerPerformancePolicy {
  const ScannerPerformancePolicy._();

  /// Whether the animated Scan_Line should be rendered.
  ///
  /// Uses a lightweight, dependency-free heuristic (no new packages): the
  /// device pixel ratio of the primary view. Very low-density displays
  /// (typical of low-end POS terminals) are treated as low performance and
  /// only render the static frame, while all other devices animate.
  ///
  /// Returns `true` when `devicePixelRatio >= 1.5` (animate); otherwise
  /// `false` (render the frame only).
  static bool get animationsEnabled {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final double dpr = view.devicePixelRatio;
    return dpr >= 1.5;
  }
}
