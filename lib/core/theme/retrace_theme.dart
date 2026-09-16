import 'package:flutter/material.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/core/theme/retrace_typography.dart';

/// Light + dark ThemeData built ONLY from RETRACE tokens.
/// No per-screen hardcoded colors allowed (§51).
@immutable
final class RetraceTheme {
  const RetraceTheme._();

  static ThemeData dark() {
    final ColorScheme scheme = const ColorScheme.dark(
      primary: RetraceColors.primary,
      onPrimary: RetraceColors.onPrimary,
      surface: RetraceColors.darkSurface,
      onSurface: RetraceColors.darkTextPrimary,
      error: RetraceColors.danger,
      onError: Colors.white,
    );
    return _build(scheme, Brightness.dark);
  }

  static ThemeData light() {
    final ColorScheme scheme = const ColorScheme.light(
      primary: RetraceColors.primaryDim,
      onPrimary: Colors.white,
      surface: RetraceColors.lightSurface,
      onSurface: RetraceColors.lightTextPrimary,
      error: RetraceColors.danger,
      onError: Colors.white,
    );
    return _build(scheme, Brightness.light);
  }

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color hairline = isDark
        ? RetraceColors.darkHairline
        : RetraceColors.lightHairline;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? RetraceColors.darkBackground
          : RetraceColors.lightBackground,
      textTheme: RetraceTypography.textTheme(brightness),
      cardTheme: CardThemeData(
        elevation: RetraceElevation.card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: RetraceRadius.card,
          side: BorderSide(color: hairline),
        ),
        color: isDark
            ? RetraceColors.darkSurface
            : RetraceColors.lightSurface,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: isDark
            ? RetraceColors.darkBackground
            : RetraceColors.lightBackground,
        foregroundColor: scheme.onSurface,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark
            ? RetraceColors.darkSurface
            : RetraceColors.lightSurface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: isDark
            ? RetraceColors.darkTextSecondary
            : RetraceColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RetraceRadius.md),
          borderSide: BorderSide(color: hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RetraceRadius.md),
          borderSide: BorderSide(color: hairline),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RetraceSpacing.md,
          vertical: RetraceSpacing.sm + 2,
        ),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(RetraceRadius.lg),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: RetraceRadius.sheet),
      ),
    );
  }
}
