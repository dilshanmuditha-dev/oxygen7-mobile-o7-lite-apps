/// Unit tests for `ScannerOverlayGeometry`.
///
/// **Validates: Requirements 1.1, 1.3, 4.2, 8.1, 8.3**
///
/// Feature: 30-qr-scanner-animated-overlay
///
/// `ScannerOverlayGeometry` is the pure, dependency-free single source of truth
/// for the square scan window shared by both the `MobileScanner.scanWindow`
/// detection region and the decorative painters. These example-based tests
/// exercise the two public methods (`computeWindowRect`, `lineOffsetFor`) on
/// representative device sizes / animation values and assert the exposed layout
/// constants sit within their required ranges.
///
/// `flutter_test` is used (rather than plain `package:test`) because the type
/// consumes `dart:ui` `Size` / `Rect` / `Offset`.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:app/modules/main/scan_qr_code/scanner_overlay_geometry.dart';

void main() {
  const ScannerOverlayGeometry geometry = ScannerOverlayGeometry();

  // Tolerance for floating-point comparisons. The requirements allow up to
  // 1 logical pixel of drift; we assert far tighter to catch regressions.
  const double eps = 1e-9;

  /// Asserts the window returned for [screen] is square, centered on the screen
  /// center, side-length within the [50%, 80%] band of the shorter dimension,
  /// and leaves a margin of at least `minMargin` on every edge (Req 1.1, 1.3,
  /// 8.1, 8.3).
  void expectValidWindow(Size screen) {
    final Rect rect = geometry.computeWindowRect(screen);
    final double shorter = screen.shortestSide;

    // (a) Square: equal side lengths (Req 1.1 / 3.1).
    expect(rect.width, closeTo(rect.height, eps),
        reason: 'window must be square for $screen');

    // (b) Centered on the screen center within tolerance (Req 1.3 / 8.2).
    expect(rect.center.dx, closeTo(screen.width / 2, eps),
        reason: 'window must be horizontally centered for $screen');
    expect(rect.center.dy, closeTo(screen.height / 2, eps),
        reason: 'window must be vertically centered for $screen');

    // (c) Side within [50%, 80%] of the shorter dimension (Req 8.1).
    expect(rect.width, greaterThanOrEqualTo(shorter * 0.5 - eps),
        reason: 'side must be >= 50% of shorter side for $screen');
    expect(rect.width, lessThanOrEqualTo(shorter * 0.8 + eps),
        reason: 'side must be <= 80% of shorter side for $screen');

    // (d) At least `minMargin` (16px) gap on every edge (Req 8.3).
    final double left = rect.left;
    final double top = rect.top;
    final double right = screen.width - rect.right;
    final double bottom = screen.height - rect.bottom;
    expect(left, greaterThanOrEqualTo(geometry.minMargin - eps),
        reason: 'left margin must be >= ${geometry.minMargin} for $screen');
    expect(top, greaterThanOrEqualTo(geometry.minMargin - eps),
        reason: 'top margin must be >= ${geometry.minMargin} for $screen');
    expect(right, greaterThanOrEqualTo(geometry.minMargin - eps),
        reason: 'right margin must be >= ${geometry.minMargin} for $screen');
    expect(bottom, greaterThanOrEqualTo(geometry.minMargin - eps),
        reason: 'bottom margin must be >= ${geometry.minMargin} for $screen');
  }

  group('computeWindowRect', () {
    test('small POS 320x480 -> square, centered, banded, margin-safe', () {
      const Size screen = Size(320, 480);
      expectValidWindow(screen);

      // shorter = 320, side = 320 * 0.7 = 224 (inside the [160, 256] band).
      final Rect rect = geometry.computeWindowRect(screen);
      expect(rect.width, closeTo(224.0, eps));
      expect(rect.center.dx, closeTo(160.0, eps));
      expect(rect.center.dy, closeTo(240.0, eps));
    });

    test('phone 428x926 -> square, centered, banded, margin-safe', () {
      const Size screen = Size(428, 926);
      expectValidWindow(screen);

      // shorter = 428, side = 428 * 0.7 ~= 299.6 (inside [214, 342.4], < 320).
      final Rect rect = geometry.computeWindowRect(screen);
      expect(rect.width, closeTo(428 * 0.7, eps));
      expect(rect.center.dx, closeTo(214.0, eps));
      expect(rect.center.dy, closeTo(463.0, eps));
    });

    test('landscape 926x428 -> square, centered, banded, margin-safe', () {
      const Size screen = Size(926, 428);
      expectValidWindow(screen);

      // shortestSide is still 428, so the side matches the portrait phone case.
      final Rect rect = geometry.computeWindowRect(screen);
      expect(rect.width, closeTo(428 * 0.7, eps));
      expect(rect.center.dx, closeTo(463.0, eps));
      expect(rect.center.dy, closeTo(214.0, eps));
    });
  });

  group('lineOffsetFor', () {
    // A simple 300x300 square window; thickness defaults to 2 (half = 1).
    const Rect rect = Rect.fromLTWH(100, 200, 300, 300);
    final double half = geometry.lineThickness / 2.0;

    test('t = 0 places the line at the top edge', () {
      final double y = geometry.lineOffsetFor(0.0, rect);
      // The line's top edge (y - half) sits exactly on rect.top (Req 4.2).
      expect(y - half, closeTo(rect.top, eps));
    });

    test('t = 0.5 places the line at the vertical mid-point', () {
      final double y = geometry.lineOffsetFor(0.5, rect);
      expect(y, closeTo(rect.top + rect.height / 2, eps));
    });

    test('t = 1 places the line at the bottom edge', () {
      final double y = geometry.lineOffsetFor(1.0, rect);
      // The line's bottom edge (y + half) sits exactly on rect.bottom (Req 4.2).
      expect(y + half, closeTo(rect.bottom, eps));
    });

    test('t below 0 clamps to the top edge', () {
      final double clamped = geometry.lineOffsetFor(-0.5, rect);
      final double atZero = geometry.lineOffsetFor(0.0, rect);
      expect(clamped, closeTo(atZero, eps));
    });

    test('t above 1 clamps to the bottom edge', () {
      final double clamped = geometry.lineOffsetFor(1.5, rect);
      final double atOne = geometry.lineOffsetFor(1.0, rect);
      expect(clamped, closeTo(atOne, eps));
    });

    test('line stays fully within the window for all t in [0, 1]', () {
      for (final double t in <double>[0, 0.1, 0.25, 0.5, 0.75, 0.9, 1]) {
        final double y = geometry.lineOffsetFor(t, rect);
        expect(y - half, greaterThanOrEqualTo(rect.top - eps),
            reason: 'line above top edge at t=$t');
        expect(y + half, lessThanOrEqualTo(rect.bottom + eps),
            reason: 'line below bottom edge at t=$t');
      }
    });
  });

  group('layout constants within required ranges', () {
    test('maskOpacity is within [0.4, 0.6] (Req 2.1)', () {
      expect(geometry.maskOpacity, greaterThanOrEqualTo(0.4));
      expect(geometry.maskOpacity, lessThanOrEqualTo(0.6));
    });

    test('lineThickness is within [1, 4] (Req 4.3)', () {
      expect(geometry.lineThickness, greaterThanOrEqualTo(1.0));
      expect(geometry.lineThickness, lessThanOrEqualTo(4.0));
    });

    test('sizeFactor is within the [0.5, 0.8] band (Req 8.1)', () {
      expect(geometry.sizeFactor, greaterThanOrEqualTo(0.5));
      expect(geometry.sizeFactor, lessThanOrEqualTo(0.8));
    });

    test('minMargin is at least 16 logical pixels (Req 8.3)', () {
      expect(geometry.minMargin, greaterThanOrEqualTo(16.0));
    });

    test('minSide is positive and below maxSide', () {
      expect(geometry.minSide, greaterThan(0.0));
      expect(geometry.minSide, lessThan(geometry.maxSide));
    });
  });

  group('rounded-corner and glow constants (Req 2.2, 3.4, 4.3, 4.6)', () {
    test('cornerRadius is 10 and within [0, minSide / 2]', () {
      expect(geometry.cornerRadius, closeTo(10.0, eps));
      // Corner_Radius must stay within a valid rounded-rect range so it can
      // never exceed half the smallest possible window side.
      expect(geometry.cornerRadius, greaterThanOrEqualTo(0.0));
      expect(geometry.cornerRadius, lessThanOrEqualTo(geometry.minSide / 2));
    });

    test('beamGlowExtent is positive (Req 4.6)', () {
      expect(geometry.beamGlowExtent, greaterThan(0.0));
    });

    test(
        'windowRRect uses cornerRadius on every corner and keeps the '
        'outer bounds equal to rect (Req 2.2, 3.4, 4.2)', () {
      const Rect rect = Rect.fromLTWH(40, 60, 300, 300);
      final RRect rrect = geometry.windowRRect(rect);

      // The outer bounds match the source rect exactly (no drift).
      expect(rrect.outerRect, rect);
      expect(rrect.left, closeTo(rect.left, eps));
      expect(rrect.top, closeTo(rect.top, eps));
      expect(rrect.right, closeTo(rect.right, eps));
      expect(rrect.bottom, closeTo(rect.bottom, eps));

      // All four corners use the shared cornerRadius (circular, x == y).
      expect(rrect.tlRadiusX, closeTo(geometry.cornerRadius, eps));
      expect(rrect.trRadiusX, closeTo(geometry.cornerRadius, eps));
      expect(rrect.blRadiusX, closeTo(geometry.cornerRadius, eps));
      expect(rrect.brRadiusX, closeTo(geometry.cornerRadius, eps));
      expect(rrect.tlRadiusY, closeTo(geometry.cornerRadius, eps));
      expect(rrect.trRadiusY, closeTo(geometry.cornerRadius, eps));
      expect(rrect.blRadiusY, closeTo(geometry.cornerRadius, eps));
      expect(rrect.brRadiusY, closeTo(geometry.cornerRadius, eps));
    });
  });
}
