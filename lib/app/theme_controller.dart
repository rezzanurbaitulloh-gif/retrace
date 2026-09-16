import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Theme mode state — `initial / loaded` today; `syncing` hooks in later
/// phases when appearance is persisted per account (§ state management).
final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(
        ThemeModeController.new);

final class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  void setMode(ThemeMode mode) => state = mode;
  void toggle() => state =
      state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}
