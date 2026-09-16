import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrace/core/config/env.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/data/auth/auth_user.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/design_system/components/retrace_cards.dart';
import 'package:retrace/design_system/components/retrace_states.dart';
import 'package:retrace/features/auth/auth_controller.dart';
import 'package:retrace/features/devices/devices_repository.dart';

/// Home answers: is the device safe? when last seen? anything to do? (§16).
/// With zero registered devices it renders the honest empty state —
/// never demo devices. Quick actions appear only when devices exist.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<AuthUser?> auth = ref.watch(authControllerProvider);
    final AsyncValue<List<DeviceSummary>> devices =
        ref.watch(devicesStreamProvider);
    final String email = auth.valueOrNull?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('RETRACE'),
        actions: [
          SyncIndicator(
            label: Env.isSupabaseConfigured ? 'Synced' : 'Local only',
            isSyncing: devices.isLoading,
          ),
          const SizedBox(width: RetraceSpacing.sm),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(devicesStreamProvider);
        },
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: RetraceSpacing.gutter(
                MediaQuery.sizeOf(context).width),
            vertical: RetraceSpacing.md,
          ),
          children: [
            Text('${_greeting()},',
                style: theme.textTheme.headlineMedium),
            Text(email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              'Your devices are safe.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: RetraceSpacing.md),
            switch (devices) {
              AsyncLoading() => const SizedBox(
                  height: 200,
                  child: LoadingState(message: 'Loading devices…'),
                ),
              AsyncError(:final Object error) => ErrorState(
                  message:
                      'Unable to load devices: ${_short(error)}',
                  onRetry: () =>
                      ref.invalidate(devicesStreamProvider),
                ),
              AsyncData(:final List<DeviceSummary> value) =>
                value.isEmpty
                    ? EmptyState(
                        title: 'No devices yet',
                        message:
                            'Protect your first device with RETRACE.',
                        actionLabel: 'View Devices',
                        onAction: () => context.go('/devices'),
                      )
                    : Column(
                        children: [
                          DeviceCard(
                            name: value.first.name,
                            meta: value.first.meta,
                            status: value.first.status,
                            lastSeen: value.first.lastSeen,
                            onTap: () => context.push(
                                '/devices/${value.first.id}'),
                          ),
                          const SizedBox(height: RetraceSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: CommandButton(
                                  icon: Icons.location_on_outlined,
                                  label: 'Locate',
                                  onPressed: () => context.push(
                                      '/devices/${value.first.id}'),
                                ),
                              ),
                              const SizedBox(width: RetraceSpacing.sm),
                              Expanded(
                                child: CommandButton(
                                  icon: Icons.volume_up_outlined,
                                  label: 'Ring',
                                  onPressed: () => context.push(
                                      '/devices/${value.first.id}'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              _ => const SizedBox.shrink(),
            },
            const SizedBox(height: RetraceSpacing.md),
            Text('Recent activity',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: RetraceSpacing.sm),
            Text(
              'Your device events will appear here.',
              style: theme.textTheme.bodySmall,
            ),
            TextButton(
              onPressed: () => context.go('/activity'),
              child: const Text('View all activity'),
            ),
          ],
        ),
      ),
    );
  }

  static String _greeting() {
    final int h = DateTime.now().hour;
    if (h < 11) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  static String _short(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
