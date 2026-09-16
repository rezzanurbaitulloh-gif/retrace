import 'package:flutter/material.dart';

/// 4/8dp spacing rhythm + radius + elevation tokens (§51).
@immutable
final class RetraceSpacing {
  const RetraceSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Horizontal gutter adapts by width (phone vs tablet/landscape, §58).
  static double gutter(double width) => width >= 600 ? 24 : 16;
}

@immutable
final class RetraceRadius {
  const RetraceRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheet =
      BorderRadius.vertical(top: Radius.circular(lg));
}

@immutable
final class RetraceElevation {
  const RetraceElevation._();

  static const double card = 0; // hairline borders, not shadows (§3)
  static const double sheet = 8;
  static const double dialog = 16;
}

/// Purposeful motion only (§56). One shared token set, smooth on low-end.
@immutable
final class RetraceMotion {
  const RetraceMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 350);
  static const Curve curve = Curves.easeOutCubic;
}
