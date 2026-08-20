/// Animation style enum for the wave animation system.
///
/// Defines the available animation styles that users can select
/// in the app settings to personalize the visual appearance.
///
/// **Requirements:** 3.2, 7.1, 7.2, 7.3, 7.4
enum AnimationStyle {
  /// Horizontal sine wave animation
  wave,

  /// Animated gradient color transitions
  gradient,

  /// Subtle pulsing glow effects
  pulse,

  /// Floating particle animations
  particles,
}

/// Extension providing display properties for [AnimationStyle].
///
/// Provides localized display names, icon assets, and descriptions
/// for each animation style to be used in the UI.
extension AnimationStyleExtension on AnimationStyle {
  /// Returns the display name for the animation style.
  ///
  /// Used in the settings UI to show a human-readable name.
  String get displayName {
    switch (this) {
      case AnimationStyle.wave:
        return 'Wave';
      case AnimationStyle.gradient:
        return 'Gradient';
      case AnimationStyle.pulse:
        return 'Pulse';
      case AnimationStyle.particles:
        return 'Particles';
    }
  }

  /// Returns the icon asset path for the animation style.
  ///
  /// Used in the settings UI to show a visual preview icon.
  String get iconAsset {
    switch (this) {
      case AnimationStyle.wave:
        return 'assets/o7lite/icons/ic_animation_wave.svg';
      case AnimationStyle.gradient:
        return 'assets/o7lite/icons/ic_animation_gradient.svg';
      case AnimationStyle.pulse:
        return 'assets/o7lite/icons/ic_animation_pulse.svg';
      case AnimationStyle.particles:
        return 'assets/o7lite/icons/ic_animation_particles.svg';
    }
  }

  /// Returns a description of the animation style.
  ///
  /// Used in the settings UI to provide additional context
  /// about what each animation style looks like.
  String get description {
    switch (this) {
      case AnimationStyle.wave:
        return 'Smooth horizontal sine wave animation';
      case AnimationStyle.gradient:
        return 'Animated gradient color transitions';
      case AnimationStyle.pulse:
        return 'Subtle pulsing glow effects';
      case AnimationStyle.particles:
        return 'Floating particle animations';
    }
  }
}
