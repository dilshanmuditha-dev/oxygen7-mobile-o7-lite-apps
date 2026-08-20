import 'dart:math';
import 'package:flutter/material.dart';

/// Animated scanning indicator with corner brackets and a comet-trail light
/// traveling along the border. Professional payment-scanning aesthetic.
///
/// [lightweight] mode disables blur effects for better performance on
/// low-end POS devices (e.g., Sunmi).
class QrScanningIndicator extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final Color color;
  final bool lightweight;

  const QrScanningIndicator({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.color = const Color(0xFF7E01D7),
    this.lightweight = false,
  });

  @override
  State<QrScanningIndicator> createState() => _QrScanningIndicatorState();
}

class _QrScanningIndicatorState extends State<QrScanningIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            foregroundPainter: _CornerScanPainter(
              progress: _controller.value,
              borderRadius: widget.borderRadius,
              color: widget.color,
              lightweight: widget.lightweight,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Paints corner brackets, a subtle border track, and a comet-trail glow
/// that orbits the QR container border.
class _CornerScanPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final Color color;
  final bool lightweight;

  static const double _cornerFraction = 0.22;
  static const double _cornerStroke = 3.5;
  static const double _trackStroke = 1.0;
  static const int _trailCount = 8;
  static const double _trailSpan = 0.06;

  _CornerScanPainter({
    required this.progress,
    required this.borderRadius,
    required this.color,
    required this.lightweight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = borderRadius.clamp(0.0, min(w, h) / 2);
    final cornerLen = min(w, h) * _cornerFraction;
    final pInfo = _PerimeterInfo(w, h, r);

    _drawBorderTrack(canvas, w, h, r);
    _drawCornerBrackets(canvas, w, h, r, cornerLen, pInfo);
    _drawCometTrail(canvas, pInfo);
  }

  void _drawBorderTrack(Canvas canvas, double w, double h, double r) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & Size(w, h),
      Radius.circular(r),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _trackStroke
      ..color = color.withValues(alpha: 0.10);
    canvas.drawRRect(rrect, paint);
  }

  void _drawCornerBrackets(
    Canvas canvas,
    double w,
    double h,
    double r,
    double cornerLen,
    _PerimeterInfo pInfo,
  ) {
    final cometDist = progress * pInfo.perimeter;
    final nearCorner = _getNearestCorner(cometDist, pInfo);

    for (int i = 0; i < 4; i++) {
      final isNear = (nearCorner == i);
      final alpha = isNear ? 1.0 : 0.7;
      final stroke = isNear ? _cornerStroke + 0.8 : _cornerStroke;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: alpha);

      final path = _buildCornerPath(i, w, h, r, cornerLen);
      canvas.drawPath(path, paint);

      // Corner glow when comet passes (skip on lightweight mode)
      if (isNear && !lightweight) {
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke + 3
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(path, glowPaint);
      }
    }
  }

  Path _buildCornerPath(int corner, double w, double h, double r, double len) {
    final path = Path();
    switch (corner) {
      case 0: // Top-left
        path.moveTo(0, len);
        path.lineTo(0, r);
        path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
        path.lineTo(len, 0);
      case 1: // Top-right
        path.moveTo(w - len, 0);
        path.lineTo(w - r, 0);
        path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
        path.lineTo(w, len);
      case 2: // Bottom-right
        path.moveTo(w, h - len);
        path.lineTo(w, h - r);
        path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
        path.lineTo(w - len, h);
      case 3: // Bottom-left
        path.moveTo(len, h);
        path.lineTo(r, h);
        path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
        path.lineTo(0, h - len);
    }
    return path;
  }

  int _getNearestCorner(double dist, _PerimeterInfo p) {
    final corners = [
      p.straightH / 2 + p.arcLen,
      p.straightH / 2 + p.arcLen + p.straightV + p.arcLen,
      p.straightH / 2 + 2 * p.arcLen + p.straightV + p.straightH + p.arcLen,
      p.straightH / 2 + 3 * p.arcLen + 2 * p.straightV + p.straightH,
    ];
    final ordered = [corners[3], corners[0], corners[1], corners[2]];

    int nearest = 0;
    double minDist = double.infinity;
    for (int i = 0; i < 4; i++) {
      final d = (dist - ordered[i]).abs();
      final dWrap = (p.perimeter - d).abs();
      final effective = min(d, dWrap);
      if (effective < minDist) {
        minDist = effective;
        nearest = i;
      }
    }
    final threshold = min(p.straightH, p.straightV) * 0.3;
    return minDist < threshold ? nearest : -1;
  }

  void _drawCometTrail(Canvas canvas, _PerimeterInfo pInfo) {
    final totalDist = progress * pInfo.perimeter;

    for (int i = _trailCount; i >= 0; i--) {
      final t = i / _trailCount; // 0 = head, 1 = tail
      final trailDist =
          (totalDist - t * _trailSpan * pInfo.perimeter) % pInfo.perimeter;
      final point = pInfo.getPoint(trailDist);

      if (i == 0) {
        // Comet head
        if (!lightweight) {
          canvas.drawCircle(
              point,
              12,
              Paint()
                ..style = PaintingStyle.fill
                ..color = color.withValues(alpha: 0.25)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
          canvas.drawCircle(
              point,
              6,
              Paint()
                ..style = PaintingStyle.fill
                ..color = color.withValues(alpha: 0.5)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        } else {
          // Lightweight: simple circles without blur
          canvas.drawCircle(
              point,
              8,
              Paint()
                ..style = PaintingStyle.fill
                ..color = color.withValues(alpha: 0.2));
          canvas.drawCircle(
              point,
              5,
              Paint()
                ..style = PaintingStyle.fill
                ..color = color.withValues(alpha: 0.4));
        }
        // Core dot (both modes)
        canvas.drawCircle(
            point,
            3.5,
            Paint()
              ..style = PaintingStyle.fill
              ..color = color);
        // White-hot center
        canvas.drawCircle(
            point,
            1.5,
            Paint()
              ..style = PaintingStyle.fill
              ..color = Colors.white.withValues(alpha: 0.8));
      } else {
        // Trail particles
        final alpha = (1.0 - t) * 0.4;
        final radius = (1.0 - t) * 2.5;
        final trailPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: alpha);
        if (!lightweight) {
          trailPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        }
        canvas.drawCircle(point, radius, trailPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_CornerScanPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Pre-calculated perimeter geometry for a rounded rectangle.
class _PerimeterInfo {
  final double w, h, r;
  final double straightH, straightV, arcLen, perimeter;

  _PerimeterInfo(this.w, this.h, this.r)
      : straightH = w - 2 * r,
        straightV = h - 2 * r,
        arcLen = pi * r / 2,
        perimeter = 2 * (w - 2 * r) + 2 * (h - 2 * r) + 4 * (pi * r / 2);

  Offset getPoint(double dist) {
    double rem = dist % perimeter;

    final topHalf = straightH / 2;
    if (rem < topHalf) return Offset(w / 2 + rem, 0);
    rem -= topHalf;

    if (rem < arcLen) {
      final angle = -pi / 2 + (rem / arcLen) * (pi / 2);
      return Offset(w - r + r * cos(angle), r + r * sin(angle));
    }
    rem -= arcLen;

    if (rem < straightV) return Offset(w, r + rem);
    rem -= straightV;

    if (rem < arcLen) {
      final angle = (rem / arcLen) * (pi / 2);
      return Offset(w - r + r * cos(angle), h - r + r * sin(angle));
    }
    rem -= arcLen;

    if (rem < straightH) return Offset(w - r - rem, h);
    rem -= straightH;

    if (rem < arcLen) {
      final angle = pi / 2 + (rem / arcLen) * (pi / 2);
      return Offset(r + r * cos(angle), h - r + r * sin(angle));
    }
    rem -= arcLen;

    if (rem < straightV) return Offset(0, h - r - rem);
    rem -= straightV;

    if (rem < arcLen) {
      final angle = pi + (rem / arcLen) * (pi / 2);
      return Offset(r + r * cos(angle), r + r * sin(angle));
    }
    rem -= arcLen;

    return Offset(r + rem, 0);
  }
}
