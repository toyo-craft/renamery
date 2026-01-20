import 'package:flutter/animation.dart';

/// Material Design 3 Motion Constants
/// Reference: https://m3.material.io/styles/motion/easing-and-duration/tokens-specs
class AppAnim {
  // Durations
  static const Duration durationShort1 = Duration(milliseconds: 50);
  static const Duration durationShort2 = Duration(milliseconds: 100);
  static const Duration durationShort3 = Duration(milliseconds: 150);
  static const Duration durationShort4 = Duration(milliseconds: 200);

  static const Duration durationMedium1 = Duration(milliseconds: 250);
  static const Duration durationMedium2 = Duration(milliseconds: 300);
  static const Duration durationMedium3 = Duration(milliseconds: 350);
  static const Duration durationMedium4 = Duration(milliseconds: 400);

  static const Duration durationLong1 = Duration(milliseconds: 450);
  static const Duration durationLong2 = Duration(milliseconds: 500);
  static const Duration durationLong3 = Duration(milliseconds: 550);
  static const Duration durationLong4 = Duration(milliseconds: 600);

  // Easing Curves
  // Standard easing: For use with elements that remain on screen (like list items changing size).
  static const Curve standard = Cubic(0.2, 0.0, 0.0, 1.0);

  // Standard decelerate: For elements entering the screen.
  static const Curve standardDecelerate = Cubic(0.0, 0.0, 0.0, 1.0);

  // Standard accelerate: For elements exiting the screen.
  static const Curve standardAccelerate = Cubic(0.3, 0.0, 1.0, 1.0);

  // Emphasized easing: For expressive motions (like FAB expansion).
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  // Emphasized decelerate: For expressive entry.
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  // Emphasized accelerate: For expressive exit.
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
}
