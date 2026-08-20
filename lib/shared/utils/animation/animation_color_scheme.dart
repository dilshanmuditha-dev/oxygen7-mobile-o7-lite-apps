import 'dart:ui';

/// Color scheme for animations based on theme.
///
/// Provides theme-aware color palettes for all animation styles,
/// ensuring visual consistency with the app's light and dark modes.
///
/// **Requirements:** 4.1, 4.2, 6.4
class AnimationColorScheme {
  /// Colors used for wave animation layers.
  ///
  /// All wave colors have alpha < 255 (semi-transparent) to allow
  /// content visibility beneath the waves. (Requirement 6.4)
  final List<Color> waveColors;

  /// Colors used for gradient animation transitions.
  final List<Color> gradientColors;

  /// Primary color used for pulse animation glow effect.
  final Color pulseColor;

  /// Color used for floating particles in particle animation.
  final Color particleColor;

  /// Creates a new [AnimationColorScheme] with the specified colors.
  const AnimationColorScheme({
    required this.waveColors,
    required this.gradientColors,
    required this.pulseColor,
    required this.particleColor,
  });

  /// Creates a light theme color scheme for animations.
  ///
  /// Uses lighter, softer colors that complement the light theme
  /// while maintaining sufficient contrast with screen content.
  ///
  /// **Validates: Requirement 4.2**
  factory AnimationColorScheme.light() {
    return const AnimationColorScheme(
      // Semi-transparent blue/cyan wave colors for light theme
      // All alpha values < 255 (Requirement 6.4 / Property 9)
      waveColors: [
        Color(0x4D2196F3), // Blue with ~30% opacity (alpha: 77)
        Color(0x3303A9F4), // Light Blue with ~20% opacity (alpha: 51)
        Color(0x2600BCD4), // Cyan with ~15% opacity (alpha: 38)
      ],
      // Gradient colors for smooth transitions
      gradientColors: [
        Color(0xFF2196F3), // Blue
        Color(0xFF03A9F4), // Light Blue
        Color(0xFF00BCD4), // Cyan
        Color(0xFF4CAF50), // Green
      ],
      // Soft blue pulse color
      pulseColor: Color(0x662196F3), // Blue with ~40% opacity (alpha: 102)
      // Light blue particle color
      particleColor: Color(0xB32196F3), // Blue with ~70% opacity (alpha: 179)
    );
  }

  /// Creates a dark theme color scheme for animations.
  ///
  /// Uses darker, more muted colors that complement the dark theme
  /// while maintaining sufficient contrast with screen content.
  ///
  /// **Validates: Requirement 4.1**
  factory AnimationColorScheme.dark() {
    return const AnimationColorScheme(
      // Semi-transparent purple/indigo wave colors for dark theme
      // All alpha values < 255 (Requirement 6.4 / Property 9)
      waveColors: [
        Color(0x4D7C4DFF), // Deep Purple with ~30% opacity (alpha: 77)
        Color(0x33536DFE), // Indigo Accent with ~20% opacity (alpha: 51)
        Color(0x26448AFF), // Blue Accent with ~15% opacity (alpha: 38)
      ],
      // Gradient colors for smooth transitions in dark mode
      gradientColors: [
        Color(0xFF7C4DFF), // Deep Purple Accent
        Color(0xFF536DFE), // Indigo Accent
        Color(0xFF448AFF), // Blue Accent
        Color(0xFF40C4FF), // Light Blue Accent
      ],
      // Soft purple pulse color
      pulseColor:
          Color(0x667C4DFF), // Deep Purple with ~40% opacity (alpha: 102)
      // Purple particle color
      particleColor:
          Color(0xB3536DFE), // Indigo Accent with ~70% opacity (alpha: 179)
    );
  }

  /// Creates an [AnimationColorScheme] based on the given [Brightness].
  ///
  /// This static method provides a convenient way to get the appropriate
  /// color scheme based on the current theme brightness.
  ///
  /// **Validates: Requirements 4.1, 4.2**
  static AnimationColorScheme fromBrightness(Brightness brightness) {
    switch (brightness) {
      case Brightness.dark:
        return AnimationColorScheme.dark();
      case Brightness.light:
        return AnimationColorScheme.light();
    }
  }

  @override
  String toString() {
    return 'AnimationColorScheme('
        'waveColors: $waveColors, '
        'gradientColors: $gradientColors, '
        'pulseColor: $pulseColor, '
        'particleColor: $particleColor)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnimationColorScheme) return false;

    // Compare lists element by element
    if (waveColors.length != other.waveColors.length) return false;
    for (int i = 0; i < waveColors.length; i++) {
      if (waveColors[i] != other.waveColors[i]) return false;
    }

    if (gradientColors.length != other.gradientColors.length) return false;
    for (int i = 0; i < gradientColors.length; i++) {
      if (gradientColors[i] != other.gradientColors[i]) return false;
    }

    return pulseColor == other.pulseColor &&
        particleColor == other.particleColor;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(waveColors),
      Object.hashAll(gradientColors),
      pulseColor,
      particleColor,
    );
  }

  /// Creates a copy of this color scheme with the given fields replaced.
  AnimationColorScheme copyWith({
    List<Color>? waveColors,
    List<Color>? gradientColors,
    Color? pulseColor,
    Color? particleColor,
  }) {
    return AnimationColorScheme(
      waveColors: waveColors ?? this.waveColors,
      gradientColors: gradientColors ?? this.gradientColors,
      pulseColor: pulseColor ?? this.pulseColor,
      particleColor: particleColor ?? this.particleColor,
    );
  }
}
