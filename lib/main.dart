import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/app/theme_controller.dart';
import 'package:retrace/core/config/env.dart';
import 'package:retrace/core/theme/retrace_theme.dart';
import 'package:retrace/providers.dart';
import 'package:retrace/routing/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Workmanager for background location (§64)
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  // Backend initializes only when the owner links Supabase via --dart-define.
  if (Env.isSupabaseConfigured) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: Env.supabaseAnonKey,
    );
  }
  runApp(const ProviderScope(child: RetraceApp()));
}

/// RETRACE root: router-driven from Phase 2. Design gallery stays reachable
/// at /design-system for Design QA compares (§70).
class RetraceApp extends ConsumerWidget {
  const RetraceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
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
      routerConfig: ref.watch(routerProvider),
    );
  }
}
