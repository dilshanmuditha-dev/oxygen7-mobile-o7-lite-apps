import 'dart:math' as math;
import 'dart:ui';

/// Pure, dependency-free layout helper for the QR scanner overlay.
///
/// This value type is the single source of truth for the square scan window
/// shared by both the `MobileScanner.scanWindow` detection region and the
/// decorative painters (mask, frame, and animated scan line). Keeping the
/// geometry in one place guarantees detection and visuals cannot drift apart.
///
/// It imports only `dart:ui` / `dart:math` (`Size`, `Rect`, `Offset`) so it can
/// be unit- and property-tested without a camera, a `BuildContext`, or any
/// Flutter widget.
class ScannerOverlayGeometry {
  /// Creates an immutable geometry configuration.
  ///
  /// All parameters default to the approved design constants and can be
  /// overridden in tests. The type is `const`, so `const ScannerOverlayGeometry()`
  /// produces the canonical layout used by the screen.
  const ScannerOverlayGeometry({
    this.sizeFactor = 0.7,
    this.minSide = 160.0,
    this.maxSide = 320.0,
    this.minMargin = 16.0,
    this.lineThickness = 2.0,
    this.maskOpacity = 0.5,
    this.cornerRadius = 10.0,
    this.beamGlowExtent = 48.0,
  });

  /// Fraction of the shorter screen dimension used for the window side,
  /// before clamping. Kept within the `[0.5, 0.8]` band (Req 8.1).
  final double sizeFactor;

  /// Absolute lower clamp for the window side, in logical pixels.
  final double minSide;

  /// Absolute upper clamp for the window side, in logical pixels.
  final double maxSide;

  /// Minimum gap preserved between each window edge and the screen edge on the
  /// smallest supported screens, in logical pixels (Req 8.3).
  final double minMargin;

  /// Scan line thickness, in logical pixels. Kept within `[1, 4]` (Req 4.3).
  final double lineThickness;

  /// Opacity of the dark mask painted outside the window, within `[0.4, 0.6]`
  /// (Req 2.1). Exposed here so the mask painter reads it from the single
  /// geometry source.
  final double maskOpacity;

  /// The single source of truth for the rounded-corner radius (Corner_Radius,
  /// 10 logical px; valid range `[0, minSide / 2]`). It is shared by the mask
  /// cutout, the frame border, and the scan-line clip so the cleared mask edge
  /// and the visible frame border coincide exactly at the rounded corners with
  /// no gap or overlap (Req 2.2 / 3.4).
  final double cornerRadius;

  /// The length the translucent glow trail extends from the scan-line core,
  /// in logical pixels. Consumed by the scan-line painter to build the vertical
  /// gradient glow that fades to fully transparent behind the beam
  /// (Req 4.3 / 4.6).
  final double beamGlowExtent;

  /// Computes the square scan window for the given [screen] size.
  ///
  /// The rectangle is expressed in the same coordinate space used by
  /// `MobileScanner.scanWindow` (the full screen size). The side length is the
  /// shorter dimension scaled by [sizeFactor], clamped into the `[50%, 80%]`
  /// band of the shorter dimension, then clamped to `[minSide, maxSide]`, and
  /// finally clamped so a margin of at least [minMargin] is preserved on every
  /// edge (and never negative). The window is centered on the screen center so
  /// it re-centers automatically on orientation or size changes.
  Rect computeWindowRect(Size screen) {
    final double shorter = screen.shortestSide;
    // Never let the window touch the edges on the smallest screens (Req 8.3).
    final double marginCap = shorter - 2 * minMargin;
    // 50%..80% band (Req 8.1) then absolute clamps then margin cap.
    final double banded =
        (shorter * sizeFactor).clamp(shorter * 0.5, shorter * 0.8).toDouble();
    final double side = banded
        .clamp(minSide, maxSide)
        .clamp(0.0, marginCap < 0 ? 0.0 : marginCap)
        .toDouble();
    return Rect.fromCenter(
      center: Offset(screen.width / 2, screen.height / 2), // Req 1.3 / 8.2
      width: side,
      height: side, // square (Req 1.1 / 3.1)
    );
  }

  /// Returns the given window [rect] as a rounded rectangle using the shared
  /// [cornerRadius].
  ///
  /// This is the single [RRect] source shared by the mask cutout, the frame
  /// border, and the scan-line clip, so all three build the exact same rounded
  /// window and cannot drift at the corners (Req 2.2 / 3.4 / 4.2). Pure and
  /// side-effect free.
  RRect windowRRect(Rect rect) =>
      RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

  /// Returns the vertical center `y` of the scan line for animation value [t].
  ///
  /// [t] is clamped to `[0, 1]`. The result keeps the whole line (accounting for
  /// [lineThickness]) inside `[rect.top, rect.bottom]`, so at `t == 0` the line
  /// sits at the top edge and at `t == 1` at the bottom edge (Req 4.2).
  double lineOffsetFor(double t, Rect rect) {
    final double clampedT = t.clamp(0.0, 1.0).toDouble();
    final double half = lineThickness / 2.0;
    final double travel = rect.height - lineThickness; // usable vertical range
    return rect.top + half + clampedT * math.max(0.0, travel);
  }
}
