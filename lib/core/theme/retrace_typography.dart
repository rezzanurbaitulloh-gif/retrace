import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// RETRACE typography — Inter, highly readable, 320dp-safe (§53).
///
/// Scale: Display / H1 / H2 / Title / Body / Label / Caption.
/// Never overflow: callers must use ellipsis + maxLines on dynamic text.
@immutable
final class RetraceTypography {
  const RetraceTypography._();

  static TextTheme textTheme(Brightness brightness) {
    final Color displayColor = brightness == Brightness.dark
        ? const Color(0xFFF2F7F4)
        : const Color(0xFF0E1B16);
    final Color bodyColor = brightness == Brightness.dark
        ? const Color(0xFFC6D6CE)
        : const Color(0xFF33463E);
    final Color captionColor = brightness == Brightness.dark
        ? const Color(0xFF9DB3AA)
        : const Color(0xFF4E655C);

    TextStyle base({
      required double size,
      required FontWeight weight,
      required Color color,
      double height = 1.35,
      double spacing = 0,
    }) =>
        GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: spacing,
        );

    return TextTheme(
      displayLarge: base(
          size: 28, weight: FontWeight.w700, color: displayColor, height: 1.2),
      headlineMedium: base(
          size: 22, weight: FontWeight.w700, color: displayColor, height: 1.25),
      headlineSmall: base(
          size: 18, weight: FontWeight.w600, color: displayColor, height: 1.3),
      titleMedium: base(
          size: 16, weight: FontWeight.w600, color: displayColor, height: 1.35),
      bodyLarge: base(size: 16, weight: FontWeight.w400, color: bodyColor),
      bodyMedium: base(size: 14, weight: FontWeight.w400, color: bodyColor),
      labelLarge: base(size: 14, weight: FontWeight.w600, color: displayColor),
      labelMedium: base(size: 12, weight: FontWeight.w600, color: bodyColor),
      bodySmall: base(size: 12, weight: FontWeight.w400, color: captionColor),
    );
  }
}
