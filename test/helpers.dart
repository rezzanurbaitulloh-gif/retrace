import 'package:flutter/material.dart';
import 'package:retrace/core/theme/retrace_theme.dart';

void noop() {}

/// Minimal harness: dark RETRACE theme + infinite-size-safe surface.
Widget harness(Widget child) {
  return MaterialApp(
    theme: RetraceTheme.light(),
    darkTheme: RetraceTheme.dark(),
    themeMode: ThemeMode.dark,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}
