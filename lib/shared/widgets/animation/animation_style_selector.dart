import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart' hide AnimationStyle;
import 'package:get/get.dart';

import '../../constants/colors.dart';
import '../../utils/animation/animation_style.dart';

/// Widget for selecting animation style in app settings.
///
/// Follows GW3 design pattern with dropdown selection.
/// Displays all available [AnimationStyle] options with preview indicators.
///
/// **Requirements:** 3.1, 8.1, 8.2, 8.4
class AnimationStyleSelector extends StatelessWidget {
  /// The currently selected animation style.
  final AnimationStyle selectedStyle;

  /// Callback when the user selects a different style.
  final ValueChanged<AnimationStyle> onStyleChanged;

  /// Whether the selector is enabled.
  /// When disabled, the dropdown is grayed out and non-interactive.
  final bool enabled;

  /// Whether dark mode is currently active.
  final bool isDarkMode;

  const AnimationStyleSelector({
    Key? key,
    required this.selectedStyle,
    required this.onStyleChanged,
    this.enabled = true,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'animationStyle'.tr,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _getLabelColor(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: _buildDropdown(),
          ),
        ],
      ),
    );
  }

  /// Returns the label text color based on enabled state and theme.
  Color _getLabelColor() {
    if (!enabled) {
      return isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;
    }
    return isDarkMode ? Colors.white : const Color(0xFF382F41);
  }

  /// Builds the GW3-styled dropdown for animation style selection.
  Widget _buildDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<AnimationStyle>(
        isExpanded: true,
        items: AnimationStyle.values
            .map((style) => DropdownMenuItem<AnimationStyle>(
                  value: style,
                  child: Row(
                    children: [
                      _buildStylePreviewIcon(style),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          style.displayName,
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF382F41),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
        value: selectedStyle,
        onChanged: enabled
            ? (newValue) {
                if (newValue != null) {
                  onStyleChanged(newValue);
                }
              }
            : null,
        buttonStyleData: ButtonStyleData(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              width: 1,
              color: _getBorderColor(),
            ),
            color: _getBackgroundColor(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          elevation: 0,
        ),
        iconStyleData: IconStyleData(
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: _getIconColor(),
          ),
          iconSize: 20,
        ),
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isDarkMode
                ? (ColorConstants.grey800 ?? Colors.grey.shade800)
                : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          offset: const Offset(0, -5),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  /// Returns the border color based on enabled state and theme.
  Color _getBorderColor() {
    if (!enabled) {
      return isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    }
    return isDarkMode ? const Color(0xFF4A5568) : const Color(0xFFD1D5DB);
  }

  /// Returns the background color based on enabled state and theme.
  Color _getBackgroundColor() {
    if (!enabled) {
      return isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100;
    }
    return isDarkMode
        ? (ColorConstants.grey800 ?? Colors.grey.shade800)
        : Colors.white;
  }

  /// Returns the icon color based on enabled state and theme.
  Color _getIconColor() {
    if (!enabled) {
      return isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;
    }
    return isDarkMode ? Colors.white : const Color(0xFF6B7280);
  }

  /// Builds a preview icon for the given animation style.
  ///
  /// Uses simple geometric shapes to represent each style visually.
  /// **Requirement 8.4:** Display a preview indicator for each style option.
  Widget _buildStylePreviewIcon(AnimationStyle style) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: _getPreviewIconBackgroundColor(),
      ),
      child: CustomPaint(
        painter: _StylePreviewPainter(
          style: style,
          color: _getPreviewIconColor(),
        ),
      ),
    );
  }

  /// Returns the preview icon background color based on theme.
  Color _getPreviewIconBackgroundColor() {
    return isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05);
  }

  /// Returns the preview icon foreground color based on theme.
  Color _getPreviewIconColor() {
    return isDarkMode ? Colors.white70 : const Color(0xFF6B7280);
  }
}

/// Custom painter for rendering style preview icons.
///
/// Draws simple geometric representations of each animation style.
class _StylePreviewPainter extends CustomPainter {
  final AnimationStyle style;
  final Color color;

  _StylePreviewPainter({
    required this.style,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    switch (style) {
      case AnimationStyle.wave:
        _drawWaveIcon(canvas, size, paint);
        break;
      case AnimationStyle.gradient:
        _drawGradientIcon(canvas, size, paint);
        break;
      case AnimationStyle.pulse:
        _drawPulseIcon(canvas, size, paint);
        break;
      case AnimationStyle.particles:
        _drawParticlesIcon(canvas, size, paint);
        break;
    }
  }

  /// Draws a wave icon (sine wave pattern).
  void _drawWaveIcon(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final centerY = size.height / 2;
    final amplitude = size.height * 0.25;

    path.moveTo(2, centerY);

    for (double x = 2; x <= size.width - 2; x += 1) {
      final normalizedX = (x - 2) / (size.width - 4);
      final y = centerY + amplitude * _sin(normalizedX * 2 * 3.14159);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  /// Draws a gradient icon (horizontal bars).
  void _drawGradientIcon(Canvas canvas, Size size, Paint paint) {
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.3);

    // Draw three horizontal bars with varying opacity
    for (int i = 0; i < 3; i++) {
      final y = 4.0 + i * 5.0;
      final opacity = 0.3 + (i * 0.25);
      fillPaint.color = color.withOpacity(opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(3, y, size.width - 6, 3),
          const Radius.circular(1.5),
        ),
        fillPaint,
      );
    }
  }

  /// Draws a pulse icon (concentric circles).
  void _drawPulseIcon(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw concentric circles
    for (int i = 0; i < 3; i++) {
      final radius = 3.0 + i * 3.0;
      paint.color = color.withOpacity(0.8 - (i * 0.2));
      canvas.drawCircle(center, radius, paint);
    }
  }

  /// Draws a particles icon (scattered dots).
  void _drawParticlesIcon(Canvas canvas, Size size, Paint paint) {
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    // Draw scattered particles
    final particles = [
      Offset(size.width * 0.25, size.height * 0.3),
      Offset(size.width * 0.6, size.height * 0.2),
      Offset(size.width * 0.4, size.height * 0.6),
      Offset(size.width * 0.75, size.height * 0.5),
      Offset(size.width * 0.2, size.height * 0.75),
      Offset(size.width * 0.65, size.height * 0.8),
    ];

    for (final particle in particles) {
      canvas.drawCircle(particle, 1.5, fillPaint);
    }
  }

  /// Simple sine function approximation.
  double _sin(double x) {
    // Normalize x to [0, 2π]
    x = x % (2 * 3.14159);
    // Taylor series approximation for sine
    return x -
        (x * x * x) / 6 +
        (x * x * x * x * x) / 120 -
        (x * x * x * x * x * x * x) / 5040;
  }

  @override
  bool shouldRepaint(_StylePreviewPainter oldDelegate) {
    return oldDelegate.style != style || oldDelegate.color != color;
  }
}
