import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/app/bootstrap.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/design_system/components/retrace_states.dart';

/// Splash: logo + tagline + real loading state + subtle motion (§7).
/// Routing decisions live in the router; this page only renders states.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<void> boot = ref.watch(bootstrapProvider);
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(RetraceSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.96, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double scale, Widget? child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: RetraceColors.primary.withValues(alpha: 0.14),
                      borderRadius:
                          BorderRadius.circular(RetraceRadius.lg),
                    ),
                    child: const Center(
                      child: Text(
                        'R',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: RetraceColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: RetraceSpacing.md),
                Text('RETRACE',
                    style: theme.textTheme.headlineMedium?.copyWith(
                        letterSpacing: 4)),
                const SizedBox(height: 4),
                Text('Find. Protect. Recover.',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: RetraceSpacing.xl),
                switch (boot) {
                  AsyncError(:final Object error) => ErrorState(
                      message: 'Startup failed: ${_short(error)}',
                      onRetry: () =>
                          ref.invalidate(bootstrapProvider),
                    ),
                  _ => const LoadingState(message: 'Preparing RETRACE…'),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _short(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
