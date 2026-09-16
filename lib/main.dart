import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/app/design_gallery.dart';
import 'package:retrace/app/theme_controller.dart';
import 'package:retrace/core/theme/retrace_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RetraceApp()));
}

/// RETRACE root. Phase 1: design-system gallery is the home route so
/// Design QA (§70) can render + compare without fake feature screens.
class RetraceApp extends ConsumerWidget {
  const RetraceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'RETRACE',
      debugShowCheckedModeBanner: false,
      theme: RetraceTheme.light(),
      darkTheme: RetraceTheme.dark(),
      themeMode: mode,
      supportedLocales: const [Locale('en'), Locale('id')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const DesignGalleryPage(),
    );
  }
}
