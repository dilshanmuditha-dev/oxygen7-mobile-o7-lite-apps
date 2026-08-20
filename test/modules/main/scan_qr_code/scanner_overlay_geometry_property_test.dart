// ignore_for_file: avoid_print

/// Property-based tests for `ScannerOverlayGeometry`.
///
/// Feature: 30-qr-scanner-animated-overlay
///
/// `ScannerOverlayGeometry` is the pure, dependency-free single source of truth
/// for the square scan window shared by both the `MobileScanner.scanWindow`
/// detection region and the decorative painters. Because it has clear
/// input/output behavior over screen sizes and animation values, it is the
/// target of the feature's correctness properties (see design.md).
///
/// This file hosts ALL four geometry properties (P1–P4). Each property lives in
/// its own `group`, named with the exact spec tag string, and every group drives
/// a seeded, dependency-free `Random` generator for at least 100 iterations
/// (matching the PBT convention established by spec 29). The generators are
/// collected in the clearly delimited "Generators" section below so additional
/// properties can be appended without duplicating input-space logic.
///
/// `flutter_test` is used (rather than plain `package:test`) because the type
/// consumes `dart:ui` `Size` / `Rect` / `Offset`.

import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:app/modules/main/scan_qr_code/scanner_overlay_geometry.dart';
import 'package:app/modules/main/scan_qr_code/widgets/scanner_overlay_painters.dart';

// ===========================================================================
// Generators (shared across property groups)
//
// Add new `Random`-based generators here (e.g. a window-`Rect` generator for
// the line-position properties) so every property draws from a single,
// well-understood input space.
// ===========================================================================

/// Lower bound of the generated shorter screen dimension, in logical pixels.
///
/// The window side is `shorter * sizeFactor` clamped into the `[50%, 80%]` band,
/// then into `[minSide, maxSide] = [160, 320]`, then to `shorter - 2*minMargin`.
/// For the "square / centered / banded / margin-safe" property to hold for
/// EVERY generated input, the shorter side must sit in the regime where those
/// clamps do not push the side out of the `[50%, 80%]` band:
///   * `shorter >= 200` keeps the `minSide` (160) clamp inside `[50%, 80%]`
///     (`160 <= 0.8 * shorter`), and
///   * `shorter <= 640` keeps the `maxSide` (320) clamp inside `[50%, 80%]`
///     (`320 >= 0.5 * shorter`).
/// We generate a small distance inside `[200, 640]` so the property is
/// well-defined without relying on floating-point behavior at the exact band
/// boundaries. This range also spans all three sizing regimes (clamped up to
/// 160, the raw `0.7 * shorter` band, and clamped down to 320) and comfortably
/// keeps every edge margin `>= 16` (Req 8.3).
const double _minShorter = 204.0;

/// Upper bound of the generated shorter screen dimension, in logical pixels.
const double _maxShorter = 636.0;

/// Maximum extra length added to the longer dimension, so aspect ratios range
/// from square (extra == 0) up to tall/wide phones and tablets. The longer side
/// never affects the window side (it depends only on `shortestSide`); it only
/// exercises centering across aspect ratios and orientations.
const double _maxExtraLong = 1000.0;

/// Generates a random screen [Size] whose shorter side lies in the supported
/// range, in both portrait and landscape orientations (and occasionally
/// square). The shorter side is always the true `shortestSide`.
Size randomScreenSize(Random rng) {
  final double shorter =
      _minShorter + rng.nextDouble() * (_maxShorter - _minShorter);
  final double longer = shorter + rng.nextDouble() * _maxExtraLong;
  final bool portrait = rng.nextBool();
  return portrait ? Size(shorter, longer) : Size(longer, shorter);
}

/// Minimum coordinate for a generated window's top-left origin, in logical
/// pixels. Deliberately negative so the line-position property is exercised
/// regardless of the window's absolute placement in the coordinate space.
const double _minRectOrigin = -200.0;

/// Maximum coordinate for a generated window's top-left origin, in logical
/// pixels.
const double _maxRectOrigin = 800.0;

/// Bounds for a generated window's width, in logical pixels. Width does not
/// influence the vertical line position but is varied so the generated rects
/// are not degenerate on the horizontal axis.
const double _minRectWidth = 1.0;
const double _maxRectWidth = 600.0;

/// Upper bound for a generated window's height, in logical pixels.
const double _maxRectHeight = 600.0;

/// Extra height (above the line thickness) used for the "short window" branch,
/// so the usable travel range `height - lineThickness` ranges from 0 up to a
/// few pixels and exercises the `max(0, travel)` clamp boundary of
/// `lineOffsetFor` (Req 4.2).
const double _shortWindowExtra = 6.0;

/// Draws roughly one window in five as a "short" window (height within a few
/// pixels of the line thickness) to exercise the near-zero travel / clamp
/// boundary.
const int _shortWindowOneIn = 5;

/// Generates a random window [Rect].
///
/// The height is always at least [lineThickness] (the thinnest window that can
/// still fully contain the line), so the "line stays within the window"
/// invariant is well-defined for every generated rect. Roughly one rect in five
/// is intentionally short — its height sits within [_shortWindowExtra] pixels of
/// the thickness — to exercise the near-zero travel / clamp boundary; the rest
/// have comfortably larger heights so `height - lineThickness` is a meaningful
/// travel range.
Rect randomWindowRect(Random rng, double lineThickness) {
  final double left =
      _minRectOrigin + rng.nextDouble() * (_maxRectOrigin - _minRectOrigin);
  final double top =
      _minRectOrigin + rng.nextDouble() * (_maxRectOrigin - _minRectOrigin);
  final double width =
      _minRectWidth + rng.nextDouble() * (_maxRectWidth - _minRectWidth);
  final bool shortWindow = rng.nextInt(_shortWindowOneIn) == 0;
  final double height = shortWindow
      ? lineThickness + rng.nextDouble() * _shortWindowExtra
      : lineThickness + rng.nextDouble() * (_maxRectHeight - lineThickness);
  return Rect.fromLTWH(left, top, width, height);
}

void main() {
  const ScannerOverlayGeometry geometry = ScannerOverlayGeometry();

  // Tolerance for floating-point comparisons on the band/margin bounds.
  const double eps = 1e-9;

  // Requirements 1.3 / 8.2 allow up to 1 logical pixel of centering drift.
  const double centerTolerancePx = 1.0;

  // Minimum iterations per property (spec convention: >= 100).
  const int iterations = 200;

  // ==========================================================================
  // Property 1: Scan window is square, centered, sized within bounds, and
  // margin-safe.
  // ==========================================================================
  group(
      'Feature: 30-qr-scanner-animated-overlay, Property 1: Scan window is '
      'square, centered, sized within bounds, and margin-safe', () {
    // Seeded for reproducibility across runs (seed == feature index).
    final Random rng = Random(30);

    /// Asserts the whole Property-1 invariant for a single [screen].
    void assertProperty1(Size screen) {
      final Rect rect = geometry.computeWindowRect(screen);
      final double shorter = screen.shortestSide;

      // (a) Square: equal side lengths (Req 1.1).
      expect(rect.width, closeTo(rect.height, eps),
          reason: 'window must be square for $screen');

      // (b) Centered on the screen center within 1px on both axes
      //     (Req 1.3 / 8.2). The value is exact; we assert within the allowed
      //     tolerance to reflect the requirement.
      expect(rect.center.dx, closeTo(screen.width / 2, centerTolerancePx),
          reason: 'window must be horizontally centered for $screen');
      expect(rect.center.dy, closeTo(screen.height / 2, centerTolerancePx),
          reason: 'window must be vertically centered for $screen');

      // (c) Side within [50%, 80%] of the shorter dimension after clamping
      //     (Req 8.1).
      expect(rect.width, greaterThanOrEqualTo(shorter * 0.5 - eps),
          reason: 'side must be >= 50% of shorter side for $screen');
      expect(rect.width, lessThanOrEqualTo(shorter * 0.8 + eps),
          reason: 'side must be <= 80% of shorter side for $screen');

      // (d) At least `minMargin` (16px) gap on every edge (Req 8.3). The
      //     tightest margin is on the shorter axis; we verify all four edges.
      final double left = rect.left;
      final double top = rect.top;
      final double right = screen.width - rect.right;
      final double bottom = screen.height - rect.bottom;
      expect(left, greaterThanOrEqualTo(geometry.minMargin - eps),
          reason: 'left margin >= ${geometry.minMargin} for $screen');
      expect(top, greaterThanOrEqualTo(geometry.minMargin - eps),
          reason: 'top margin >= ${geometry.minMargin} for $screen');
      expect(right, greaterThanOrEqualTo(geometry.minMargin - eps),
          reason: 'right margin >= ${geometry.minMargin} for $screen');
      expect(bottom, greaterThanOrEqualTo(geometry.minMargin - eps),
          reason: 'bottom margin >= ${geometry.minMargin} for $screen');
    }

    test(
        'holds for random screen sizes across both orientations '
        '(>= 100 iterations)', () {
      for (int i = 0; i < iterations; i++) {
        assertProperty1(randomScreenSize(rng));
      }

      // Explicit smallest-supported-screen checks (Req 8.3) in both
      // orientations, so the margin invariant is pinned at the low end.
      assertProperty1(const Size(320, 480));
      assertProperty1(const Size(480, 320));

      expect(iterations, greaterThanOrEqualTo(100));
      print('Property 1 iterations executed: ${iterations + 2}');
    });
  });

  // ==========================================================================
  // Property 2: Scan line stays fully within the window.
  //
  // For any animation value t in [0, 1] and any window Rect, the whole scan
  // line (its center +/- thickness/2) stays inside [rect.top, rect.bottom]:
  //   y - thickness/2 >= rect.top   and   y + thickness/2 <= rect.bottom
  // where y = geometry.lineOffsetFor(t, rect).
  // ==========================================================================
  group(
      'Feature: 30-qr-scanner-animated-overlay, Property 2: Scan line stays '
      'fully within the window', () {
    // Seeded for reproducibility across runs (seed == feature index).
    final Random rng = Random(30);

    /// Asserts that, for animation value [t] and window [rect], the whole scan
    /// line stays inside the window's vertical bounds (Req 4.2).
    void assertProperty2(double t, Rect rect) {
      final double y = geometry.lineOffsetFor(t, rect);
      final double half = geometry.lineThickness / 2.0;

      // Top edge of the line never rises above the window's top edge.
      expect(y - half, greaterThanOrEqualTo(rect.top - eps),
          reason: 'line top edge must stay >= rect.top for t=$t rect=$rect');

      // Bottom edge of the line never drops below the window's bottom edge.
      expect(y + half, lessThanOrEqualTo(rect.bottom + eps),
          reason:
              'line bottom edge must stay <= rect.bottom for t=$t rect=$rect');
    }

    test(
        'holds for random t in [0, 1] and random window rects '
        '(>= 100 iterations)', () {
      for (int i = 0; i < iterations; i++) {
        final Rect rect = randomWindowRect(rng, geometry.lineThickness);
        // Check each rect at a random interior value plus both edge values, so
        // the top edge (t == 0), an interior position, and the bottom edge
        // (t == 1) are all exercised.
        assertProperty2(rng.nextDouble(), rect);
        assertProperty2(0.0, rect);
        assertProperty2(1.0, rect);
      }

      expect(iterations, greaterThanOrEqualTo(100));
      print('Property 2 iterations executed: ${iterations * 3}');
    });
  });

  // ==========================================================================
  // Property 3: Single source of truth (detection Rect == visual Rect).
  //
  // The screen computes the scan window exactly once per build with
  // `const ScannerOverlayGeometry().computeWindowRect(size)` and hands that same
  // `Rect` both to `MobileScanner.scanWindow` (the detection path) and to the
  // decorative painters (the visual path). This property models both paths:
  // it calls `computeWindowRect(size)` twice — once standing in for detection,
  // once for the visuals — and asserts the two rects are deeply equal (0px
  // drift), then feeds the "visual" rect into `ScanMaskPainter`,
  // `ScanFramePainter`, and `ScanLinePainter` and asserts each painter's `rect`
  // field equals the "detection" rect. Because the helper is a pure function of
  // its input, detection and visual alignment cannot differ by even a fraction
  // of a logical pixel.
  // ==========================================================================
  group(
      'Feature: 30-qr-scanner-animated-overlay, Property 3: Single source of '
      'truth (detection Rect == visual Rect)', () {
    // Seeded for reproducibility across runs (seed == feature index).
    final Random rng = Random(30);

    /// Asserts that, for a given [screen], the detection rect and the visual
    /// rect are identical and that the painters consume that exact rect
    /// (Req 1.2, 2.2, 3.3, 6.2).
    void assertProperty3(Size screen) {
      // Detection path: the value handed to `MobileScanner.scanWindow`.
      final Rect detectionRect = geometry.computeWindowRect(screen);
      // Visual path: the value handed to the painters. Same helper, same input.
      final Rect visualRect = geometry.computeWindowRect(screen);

      // Deep `Rect` equality (Dart's `Rect ==` compares l/t/r/b): 0px drift.
      expect(detectionRect, equals(visualRect),
          reason: 'detection and visual rects must be equal for $screen');

      // Explicit component-wise equality so the "0px drift" guarantee is
      // unmistakable on every edge.
      expect(detectionRect.left, equals(visualRect.left),
          reason: 'left edges must match for $screen');
      expect(detectionRect.top, equals(visualRect.top),
          reason: 'top edges must match for $screen');
      expect(detectionRect.right, equals(visualRect.right),
          reason: 'right edges must match for $screen');
      expect(detectionRect.bottom, equals(visualRect.bottom),
          reason: 'bottom edges must match for $screen');

      // The painters are constructed from the visual rect (as the overlay does)
      // and must expose exactly the detection rect — proving the single source
      // of truth flows unchanged into every visual layer.
      final ScanMaskPainter mask = ScanMaskPainter(rect: visualRect);
      final ScanFramePainter frame = ScanFramePainter(rect: visualRect);
      final ScanLinePainter line = ScanLinePainter(
        rect: visualRect,
        t: rng.nextDouble(),
        geometry: geometry,
      );

      expect(mask.rect, equals(detectionRect),
          reason: 'mask painter rect must equal detection rect for $screen');
      expect(frame.rect, equals(detectionRect),
          reason: 'frame painter rect must equal detection rect for $screen');
      expect(line.rect, equals(detectionRect),
          reason: 'line painter rect must equal detection rect for $screen');
    }

    test(
        'holds for random screen sizes across both orientations '
        '(>= 100 iterations)', () {
      for (int i = 0; i < iterations; i++) {
        assertProperty3(randomScreenSize(rng));
      }

      // Explicit representative screens (small POS, phone, landscape) so the
      // invariant is pinned at concrete device sizes too.
      assertProperty3(const Size(320, 480));
      assertProperty3(const Size(428, 926));
      assertProperty3(const Size(926, 428));

      expect(iterations, greaterThanOrEqualTo(100));
      print('Property 3 iterations executed: ${iterations + 3}');
    });
  });

  // ==========================================================================
  // Property 4: Scan line traverses edge to edge.
  //
  // For any window Rect, the scan line reaches both extremes of its travel:
  //   * at t == 0 the line's top edge sits exactly on the window's top edge
  //     (`lineOffsetFor(0, rect) - thickness/2 == rect.top`), and
  //   * at t == 1 the line's bottom edge sits exactly on the window's bottom
  //     edge (`lineOffsetFor(1, rect) + thickness/2 == rect.bottom`).
  // Together these guarantee a full top-to-bottom sweep (Req 4.1). The bottom
  // equality relies on usable travel `height - thickness >= 0`; the shared
  // `randomWindowRect` generator always emits `height >= lineThickness`, so
  // travel is never clamped away. In the degenerate `height == thickness` case
  // both edges coincide and both equalities still hold.
  // ==========================================================================
  group(
      'Feature: 30-qr-scanner-animated-overlay, Property 4: Scan line '
      'traverses edge to edge', () {
    // Seeded for reproducibility across runs (seed == feature index).
    final Random rng = Random(30);

    /// Asserts that, for window [rect], the line reaches the top edge at t == 0
    /// and the bottom edge at t == 1 (Req 4.1).
    void assertProperty4(Rect rect) {
      final double half = geometry.lineThickness / 2.0;

      // t == 0: the line's top edge coincides with the window's top edge.
      final double yTop = geometry.lineOffsetFor(0.0, rect);
      expect(yTop - half, closeTo(rect.top, eps),
          reason: 'line must start at the top edge for rect=$rect');

      // t == 1: the line's bottom edge coincides with the window's bottom edge.
      final double yBottom = geometry.lineOffsetFor(1.0, rect);
      expect(yBottom + half, closeTo(rect.bottom, eps),
          reason: 'line must end at the bottom edge for rect=$rect');
    }

    test('holds for random window rects (>= 100 iterations)', () {
      for (int i = 0; i < iterations; i++) {
        assertProperty4(randomWindowRect(rng, geometry.lineThickness));
      }

      // Explicit representative windows so the edge-to-edge sweep is pinned at
      // concrete sizes: a comfortably tall window and a degenerate window whose
      // height equals the line thickness (top and bottom edges coincide).
      assertProperty4(const Rect.fromLTWH(10, 20, 200, 200));
      assertProperty4(Rect.fromLTWH(0, 0, 100, geometry.lineThickness));

      expect(iterations, greaterThanOrEqualTo(100));
      print('Property 4 iterations executed: ${iterations + 2}');
    });
  });
}
