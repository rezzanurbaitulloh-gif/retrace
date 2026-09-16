import 'package:flutter/material.dart';

/// RETRACE color tokens — extracted from `retracemobile.png` (source of truth).
///
/// Dark-first security app. Primary = teal/mint. Emergency red is reserved
/// for Lost Mode / critical / destructive only (§52) — never app-wide.
@immutable
final class RetraceColors {
  const RetraceColors._();

  // Brand
  static const Color primary = Color(0xFF00E5A0);
  static const Color primaryDim = Color(0xFF00B87E);
  static const Color onPrimary = Color(0xFF06231A);

  // Dark theme surfaces (default)
  static const Color darkBackground = Color(0xFF0B1512);
  static const Color darkSurface = Color(0xFF122019);
  static const Color darkElevated = Color(0xFF182A21);
  static const Color darkHairline = Color(0xFF24403A);

  // Light theme surfaces ("same experience, different feel")
  static const Color lightBackground = Color(0xFFF4F7F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFEAF1ED);
  static const Color lightHairline = Color(0xFFD8E2DD);

  // Text
  static const Color darkTextPrimary = Color(0xFFF2F7F4);
  static const Color darkTextSecondary = Color(0xFF9DB3AA);
  static const Color lightTextPrimary = Color(0xFF0E1B16);
  static const Color lightTextSecondary = Color(0xFF4E655C);

  // Status (§52 + reference badges)
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);
  static const Color offline = Color(0xFF8A9A93);

  /// Map status color to its semantic color. Never color-only in UI —
  /// always pair with icon + label (§57).
  static Color statusColor(DeviceStatus status) => switch (status) {
        DeviceStatus.protected => success,
        DeviceStatus.online => success,
        DeviceStatus.offline => offline,
        DeviceStatus.limited => warning,
        DeviceStatus.lost => danger,
      };
}

/// Device status language — matches reference badges exactly.
enum DeviceStatus {
  protected,
  online,
  offline,
  limited,
  lost,
}

extension DeviceStatusLabel on DeviceStatus {
  String get label => switch (this) {
        DeviceStatus.protected => 'Protected',
        DeviceStatus.online => 'Online',
        DeviceStatus.offline => 'Offline',
        DeviceStatus.limited => 'Limited',
        DeviceStatus.lost => 'Lost Mode',
      };
}
