import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/constants/colors.dart';

/// Adaptive loading indicator for splash screen.
///
/// Shows a pulsing animation for high-spec devices or a simple
/// static/minimal indicator for low-spec devices.
class AdaptiveLoadingIndicator extends StatefulWidget {
  /// Whether the loading indicator is visible.
  final bool isLoading;

  /// Whether to use pulsing animation (high-spec) or simple indicator (low-spec).
  final bool usePulseAnimation;

  /// Color of the loading indicator.
  final Color? color;

  /// Size of the loading indicator.
  final double size;

  const AdaptiveLoadingIndicator({
    Key? key,
    required this.isLoading,
    required this.usePulseAnimation,
    this.color,
    this.size = 24.0,
  }) : super(key: key);

  @override
  State<AdaptiveLoadingIndicator> createState() =>
      _AdaptiveLoadingIndicatorState();
}

class _AdaptiveLoadingIndicatorState extends State<AdaptiveLoadingIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    if (widget.usePulseAnimation && widget.isLoading) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      );

      _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: _pulseController!,
          curve: Curves.easeInOut,
        ),
      );

      _pulseController!.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AdaptiveLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle animation state changes
    if (widget.isLoading != oldWidget.isLoading ||
        widget.usePulseAnimation != oldWidget.usePulseAnimation) {
      _disposeAnimation();
      _initializeAnimation();
    }
  }

  void _disposeAnimation() {
    _pulseController?.dispose();
    _pulseController = null;
    _pulseAnimation = null;
  }

  @override
  void dispose() {
    _disposeAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return const SizedBox.shrink();
    }

    final indicatorColor =
        widget.color ?? ColorConstants.backgroundColorButtonPrint;

    if (widget.usePulseAnimation && _pulseAnimation != null) {
      return _buildPulsingIndicator(indicatorColor);
    }

    return _buildSimpleIndicator(indicatorColor);
  }

  /// Builds pulsing loading indicator for high-spec devices.
  Widget _buildPulsingIndicator(Color color) {
    return AnimatedBuilder(
      animation: _pulseAnimation!,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation!.value,
          child: _buildIndicatorContent(color),
        );
      },
    );
  }

  /// Builds simple static loading indicator for low-spec devices.
  Widget _buildSimpleIndicator(Color color) {
    return _buildIndicatorContent(color);
  }

  /// Builds the actual indicator content (dots).
  Widget _buildIndicatorContent(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDot(color, 0),
        const SizedBox(width: 8),
        _buildDot(color, 1),
        const SizedBox(width: 8),
        _buildDot(color, 2),
      ],
    );
  }

  /// Builds a single dot with optional animation offset.
  Widget _buildDot(Color color, int index) {
    final dotSize = widget.size / 3;

    if (widget.usePulseAnimation && _pulseAnimation != null) {
      // Staggered animation for each dot
      final delay = index * 0.2;
      final adjustedValue =
          ((_pulseAnimation!.value - 0.8) / 0.2 + delay) % 1.0;
      final opacity = 0.4 + (adjustedValue * 0.6);

      return Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withAlpha((opacity * 255).toInt()),
        ),
      );
    }

    // Simple static dot for low-spec
    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha(179), // 0.7 opacity
      ),
    );
  }
}

/// Simple loading text indicator as an alternative.
class SimpleLoadingText extends StatelessWidget {
  final bool isLoading;
  final String? text;
  final Color? color;

  const SimpleLoadingText({
    Key? key,
    required this.isLoading,
    this.text,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return Text(
      text ?? 'splashLoading'.tr,
      style: TextStyle(
        fontSize: 12,
        color:
            color ?? ColorConstants.backgroundColorButtonPrint.withAlpha(179),
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
