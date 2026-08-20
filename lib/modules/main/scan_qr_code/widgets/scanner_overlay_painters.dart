// ignore_for_file: deprecated_member_use

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:app/shared/constants/colors.dart';
import 'package:app/shared/utils/responsive_util.dart';

import '../scanner_overlay_geometry.dart';

/// The vertical sweep direction of the animated scan beam.
///
/// Supplied to [ScanLinePainter] so its translucent glow can trail *behind* the
/// beam relative to travel: when sweeping [down] the glow extends upward, and
/// when sweeping [up] it extends downward (Req 4.6). The overlay derives this
/// from the `AnimationController` status (`forward` -> [down], `reverse` ->
/// [up]).
enum SweepDirection {
  /// The beam is moving from the top edge toward the bottom edge; the glow
  /// trails upward.
  down,

  /// The beam is moving from the bottom edge toward the top edge; the glow
  /// trails downward.
  up,
}

/// Decorative painters for the QR scanner overlay.
///
/// This file hosts the three [CustomPainter]s that draw the purely visual
/// scanner overlay on top of the live camera preview:
///
/// * [ScanMaskPainter] dims everything outside the square scan window.
/// * [ScanFramePainter] draws the square border and the four corner brackets.
/// * [ScanLinePainter] draws the animated glowing beam (a solid core plus a
///   translucent gradient glow that trails behind the sweep), clipped to the
///   rounded scan window.
///
/// None of the painters affect barcode detection or navigation; they consume
/// the single [Rect] produced by [ScannerOverlayGeometry.computeWindowRect] so
/// the visuals stay aligned with `MobileScanner.scanWindow`.

/// The default accent color used by the frame and the scan line.
///
/// The requested `0xFF7E01D7` purple does not exist in the codebase, so the
/// nearest approved value ([ColorConstants.backgroundColorButtonPrint],
/// `0xFF635BFF`) is used for visual consistency.
Color get _defaultAccentColor => ColorConstants.backgroundColorButtonPrint;

/// Paints a translucent dark mask over the whole canvas while leaving the
/// square scan window fully transparent.
///
/// The mask is drawn as a single path: a rectangle covering the entire canvas
/// with the rounded window rectangle punched out via
/// `Path.combine(PathOperation.difference, ...)`. Using one difference path
/// (instead of four separate rectangles) guarantees there is no seam or overlap
/// at the window border (Req 2.2) and that the mask covers the whole screen,
/// including the area behind the top bar and any safe-area insets (Req 2.3).
/// The cutout is rounded with [cornerRadius] so the cleared mask edge coincides
/// exactly with the [ScanFramePainter] rounded border (Req 2.2 / 3.4).
class ScanMaskPainter extends CustomPainter {
  /// Creates a mask painter for the given window [rect].
  const ScanMaskPainter({
    required this.rect,
    this.maskOpacity = 0.5,
    this.cornerRadius = 10.0,
  });

  /// The scan window, in the same coordinate space as the canvas. The interior
  /// of this rectangle stays fully transparent.
  final Rect rect;

  /// Opacity of the dark mask outside the window, within `[0.4, 0.6]` (Req 2.1).
  final double maskOpacity;

  /// Radius of the rounded corners of the cleared cutout, in logical pixels.
  /// Mirrors the geometry default (`ScannerOverlayGeometry.cornerRadius`, 10px)
  /// so the cutout matches the frame's rounded border with no seam (Req 2.2).
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    // Full-canvas rectangle with the rounded window punched out, as one path so
    // there is no dimmed gap or overlap exactly at the window border (Req 2.2).
    final Path fullCanvas = Path()..addRect(Offset.zero & size);
    final Path window = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)));
    final Path mask =
        Path.combine(PathOperation.difference, fullCanvas, window);

    final Paint maskPaint = Paint()
      ..color = ColorConstants.black.withOpacity(maskOpacity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(mask, maskPaint);
  }

  @override
  bool shouldRepaint(covariant ScanMaskPainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.maskOpacity != maskOpacity ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}

/// Paints the rounded square frame around the scan window plus four accented
/// corner brackets.
///
/// The border stroke is 3px with rounded corners of radius [cornerRadius] and
/// each corner bracket is an L shape made of two perpendicular 28px arms, both
/// rendered in [accentColor] and aligned to the window [rect] (Req 3.1–3.4).
/// Each bracket is offset inward along its edges by [cornerRadius] so its arms
/// start where the straight edge meets the corner arc and visually hug the
/// rounded corner instead of overhanging the square vertex (Req 3.5). Stroke and
/// arm sizes are scaled through [ResponsiveUtil] so they stay proportional
/// across devices.
class ScanFramePainter extends CustomPainter {
  /// Creates a frame painter for the given window [rect].
  ///
  /// [accentColor] defaults to [ColorConstants.backgroundColorButtonPrint] when
  /// null.
  const ScanFramePainter({
    required this.rect,
    this.accentColor,
    this.cornerRadius = 10.0,
  });

  /// The scan window whose boundary the frame is aligned to.
  final Rect rect;

  /// The color of the border and corner brackets. Falls back to the default
  /// accent color when null.
  final Color? accentColor;

  /// Radius of the rounded border corners, in logical pixels. Mirrors the
  /// geometry default (`ScannerOverlayGeometry.cornerRadius`, 10px) so the
  /// border matches the [ScanMaskPainter] cutout exactly (Req 3.4).
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Color color = accentColor ?? _defaultAccentColor;
    final double stroke = ResponsiveUtil().getSize(3);
    final double armLength = ResponsiveUtil().getSize(28);

    // Rounded square border aligned to the window boundary (Req 3.1 / 3.3 /
    // 3.4).
    final Paint borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..isAntiAlias = true;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)),
      borderPaint,
    );

    // Four L-shaped corner brackets, each offset inward by [cornerRadius] so
    // its arms begin where the straight edge meets the rounded corner arc and
    // hug the arc rather than overhanging the square vertex (Req 3.2 / 3.5).
    final Paint bracketPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final Path brackets = Path()
      // Top-left corner.
      ..moveTo(rect.left, rect.top + cornerRadius + armLength)
      ..lineTo(rect.left, rect.top + cornerRadius)
      ..moveTo(rect.left + cornerRadius, rect.top)
      ..lineTo(rect.left + cornerRadius + armLength, rect.top)
      // Top-right corner.
      ..moveTo(rect.right - cornerRadius - armLength, rect.top)
      ..lineTo(rect.right - cornerRadius, rect.top)
      ..moveTo(rect.right, rect.top + cornerRadius)
      ..lineTo(rect.right, rect.top + cornerRadius + armLength)
      // Bottom-right corner.
      ..moveTo(rect.right, rect.bottom - cornerRadius - armLength)
      ..lineTo(rect.right, rect.bottom - cornerRadius)
      ..moveTo(rect.right - cornerRadius, rect.bottom)
      ..lineTo(rect.right - cornerRadius - armLength, rect.bottom)
      // Bottom-left corner.
      ..moveTo(rect.left + cornerRadius + armLength, rect.bottom)
      ..lineTo(rect.left + cornerRadius, rect.bottom)
      ..moveTo(rect.left, rect.bottom - cornerRadius)
      ..lineTo(rect.left, rect.bottom - cornerRadius - armLength);

    canvas.drawPath(brackets, bracketPaint);
  }

  @override
  bool shouldRepaint(covariant ScanFramePainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}

/// Paints the animated glowing beam scan line inside the scan window.
///
/// The beam is drawn in two layers, both hard-clipped to the rounded window:
///
/// 1. A translucent vertical **gradient glow** that trails *behind* the beam
///    relative to its travel [direction] and fades from `~0.35` opacity at the
///    core to fully transparent (0% opacity) at [ScannerOverlayGeometry.beamGlowExtent]
///    (48px) away, so it presents no hard edge (Req 4.6).
/// 2. A solid horizontal **core line** on top of the glow, spanning the full
///    width of [rect] at the vertical position returned by
///    [ScannerOverlayGeometry.lineOffsetFor] for the current animation value
///    [t], with thickness [ScannerOverlayGeometry.lineThickness] (2px) in
///    [accentColor] (Req 4.3).
///
/// Before drawing anything the painter calls
/// `canvas.clipRRect(geometry.windowRRect(rect))`, so neither the core nor its
/// glow can ever render outside the rounded `Scan_Window` (Req 4.2). The core
/// position is the unchanged pure [ScannerOverlayGeometry.lineOffsetFor] value,
/// so it still traverses edge to edge (Properties P2 / P4 stay valid).
class ScanLinePainter extends CustomPainter {
  /// Creates a scan line painter.
  ///
  /// [accentColor] defaults to [ColorConstants.backgroundColorButtonPrint] when
  /// null. [direction] defaults to [SweepDirection.down] so the glow trails
  /// upward on the initial downward sweep.
  const ScanLinePainter({
    required this.rect,
    required this.t,
    required this.geometry,
    this.accentColor,
    this.direction = SweepDirection.down,
  });

  /// The scan window the beam travels within and is clipped to.
  final Rect rect;

  /// The animation value in `[0, 1]`; `0` is the top edge and `1` the bottom.
  final double t;

  /// The shared geometry helper used to resolve the core position, thickness,
  /// glow extent, and the rounded clip.
  final ScannerOverlayGeometry geometry;

  /// The color of the beam core and its glow. Falls back to the default accent
  /// color when null.
  final Color? accentColor;

  /// The current sweep direction, used to orient the trailing glow (Req 4.6).
  final SweepDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    // Clip to the rounded window first so neither the beam nor its glow can
    // ever render outside the rounded Scan_Window (Req 4.2).
    canvas.clipRRect(geometry.windowRRect(rect));

    final Color accent = accentColor ?? _defaultAccentColor;
    final double y = geometry.lineOffsetFor(t, rect);
    final double glowExtent = geometry.beamGlowExtent;
    // X is irrelevant for a vertical gradient; use the same x for both points.
    final double x = rect.center.dx;

    // Glow fades from a translucent core (~0.35 opacity) to fully transparent
    // at [beamGlowExtent] away, with no hard edge (Req 4.6).
    final Color coreGlow = accent.withOpacity(0.35);
    final Color edgeGlow = accent.withOpacity(0.0);

    final double glowTop;
    final double glowBottom;
    final ui.Gradient glowShader;
    if (direction == SweepDirection.down) {
      // Sweeping down -> the glow trails upward: transparent at the top,
      // opaque at the core (bottom).
      glowTop = y - glowExtent;
      glowBottom = y;
      glowShader = ui.Gradient.linear(
        Offset(x, glowTop),
        Offset(x, glowBottom),
        <Color>[edgeGlow, coreGlow],
      );
    } else {
      // Sweeping up -> the glow trails downward: opaque at the core (top),
      // transparent at the bottom.
      glowTop = y;
      glowBottom = y + glowExtent;
      glowShader = ui.Gradient.linear(
        Offset(x, glowTop),
        Offset(x, glowBottom),
        <Color>[coreGlow, edgeGlow],
      );
    }

    // Paint the glow band; the clipRRect keeps it inside the rounded window.
    canvas.drawRect(
      Rect.fromLTRB(rect.left, glowTop, rect.right, glowBottom),
      Paint()..shader = glowShader,
    );

    // Solid core line on top of the glow (Req 4.3).
    final Paint linePaint = Paint()
      ..color = accent
      ..strokeWidth = geometry.lineThickness
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), linePaint);
  }

  @override
  bool shouldRepaint(covariant ScanLinePainter oldDelegate) {
    // The animation value and sweep direction drive per-frame repaints and the
    // trail re-orientation at each reversal (Req 7.1 / 4.6).
    return oldDelegate.t != t ||
        oldDelegate.direction != direction ||
        oldDelegate.rect != rect ||
        oldDelegate.geometry != geometry ||
        oldDelegate.accentColor != accentColor;
  }
}
