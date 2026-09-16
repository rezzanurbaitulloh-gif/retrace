import 'package:flutter/widgets.dart';

/// Localization-ready string table (§77). No hardcoded UI strings in widgets:
/// widgets take `label` params; screens resolve via [AppStrings.of].
///
/// Phase 1 ships `id` + `en`. ARB/codegen arrives with full screens (Phase 2).
@immutable
final class AppStrings {
  const AppStrings._(this.locale);

  final Locale locale;

  static AppStrings of(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    return AppStrings._(locale);
  }

  bool get isIndonesian => locale.languageCode == 'id';

  String get appTagline =>
      isIndonesian ? 'Find. Protect. Recover.' : 'Find. Protect. Recover.';
  String get addDevice =>
      isIndonesian ? 'Tambah Perangkat' : 'Add Device';
  String get retry => isIndonesian ? 'Coba Lagi' : 'Retry';
  String get noDevicesYet =>
      isIndonesian ? 'Belum ada perangkat' : 'No devices yet';
  String get protectFirst => isIndonesian
      ? 'Lindungi perangkat pertamamu dengan RETRACE.'
      : 'Protect your first device with RETRACE.';
}
