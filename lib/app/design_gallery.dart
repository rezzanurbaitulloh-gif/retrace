import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/app/theme_controller.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/design_system/components/retrace_cards.dart';
import 'package:retrace/design_system/components/retrace_lists.dart';
import 'package:retrace/design_system/components/retrace_states.dart';

/// Phase 1 render target: every token + component on one scrollable page
/// so Design QA (§70) can compare against `retracemobile.png` directly.
class DesignGalleryPage extends ConsumerWidget {
  const DesignGalleryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ThemeMode mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('RETRACE · Design System'),
        actions: [
          Semantics(
            label: 'Toggle light and dark mode',
            child: IconButton(
              tooltip: 'Toggle theme',
              onPressed: () =>
                  ref.read(themeModeProvider.notifier).toggle(),
              icon: Icon(mode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: RetraceSpacing.gutter(
              MediaQuery.sizeOf(context).width),
          vertical: RetraceSpacing.md,
        ),
        children: [
          Text('Find. Protect. Recover.',
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Advanced device tracking and recovery, built for your peace of mind.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: RetraceSpacing.lg),
          _Section(
              title: 'Buttons',
              child: Wrap(
                spacing: RetraceSpacing.sm,
                runSpacing: RetraceSpacing.sm,
                children: [
                  RetraceButton(
                      label: 'Get Started',
                      onPressed: () {},
                      icon: Icons.arrow_forward_outlined),
                  const RetraceButton(
                      label: 'Secondary', onPressed: null),
                  RetraceButton(
                      label: 'Activate Lost Mode',
                      isDestructive: true,
                      onPressed: () {}),
                  const RetraceButton(
                      label: 'Loading…', onPressed: null, isLoading: true),
                ],
              )),
          const _Section(
            title: 'Status badges (icon + text, never color-only)',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge(status: DeviceStatus.protected),
                StatusBadge(status: DeviceStatus.online),
                StatusBadge(status: DeviceStatus.offline),
                StatusBadge(status: DeviceStatus.limited),
                StatusBadge(status: DeviceStatus.lost),
              ],
            ),
          ),
          _Section(
            title: 'Device cards',
            child: Column(
              children: [
                DeviceCard(
                    name: "Rezza's Phone",
                    meta: 'OPPO A18 · Android 14',
                    status: DeviceStatus.protected,
                    lastSeen: 'Last seen 12 sec ago',
                    onTap: () {}),
                const SizedBox(height: RetraceSpacing.sm),
                const DeviceCard(
                    name: 'Galaxy Watch',
                    meta: 'Wear OS',
                    status: DeviceStatus.lost,
                    lastSeen: 'Lost Mode · active'),
              ],
            ),
          ),
          const _Section(
            title: 'Map card (placeholder until Phase 4 engine)',
            child: MapCard(
              statusLine: 'LAST SEEN · accuracy 12m',
              accuracyLine: 'Malang, East Java · 10:32',
            ),
          ),
          const _Section(
            title: 'Activity',
            child: Column(
              children: [
                ActivityItem(
                    icon: Icons.location_on_outlined,
                    title: 'Location updated',
                    subtitle: 'Malang, East Java',
                    timestamp: '10:32'),
                SizedBox(height: 8),
                ActivityItem(
                    icon: Icons.warning_amber_outlined,
                    title: 'Lost Mode activated',
                    timestamp: '10:27',
                    tone: RetraceColors.danger),
              ],
            ),
          ),
          _Section(
            title: 'Permissions',
            child: Column(
              children: [
                PermissionItem(
                    icon: Icons.location_on_outlined,
                    title: 'Location',
                    granted: true,
                    onTap: () {}),
                PermissionItem(
                    icon: Icons.camera_alt_outlined,
                    title: 'Camera',
                    granted: false,
                    onTap: () {}),
              ],
            ),
          ),
          const _Section(
            title: 'Trusted contacts',
            child: TrustedContactCard(
                name: 'Dimas', scope: 'Emergency only'),
          ),
          const _Section(
            title: 'Commands',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                CommandButton(
                    icon: Icons.volume_up_outlined,
                    label: 'Ring',
                    sublabel: 'Play sound',
                    onPressed: null),
                CommandButton(
                    icon: Icons.lock_outlined,
                    label: 'Lock',
                    sublabel: 'RETRACE PIN',
                    onPressed: null),
              ],
            ),
          ),
          const _Section(
            title: 'Offline + sync',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OfflineBanner(
                    pendingCount: 12, lastSynced: '10:28'),
                SizedBox(height: 8),
                SyncIndicator(label: 'Syncing…', isSyncing: true),
              ],
            ),
          ),
          _Section(
            title: 'States',
            child: Column(
              children: [
                SizedBox(
                  height: 120,
                  child: EmptyState(
                    title: 'No devices yet',
                    message:
                        'Protect your first device with RETRACE.',
                    actionLabel: 'Add Device',
                    onAction: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (_) {},
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.devices_outlined), label: 'Devices'),
          BottomNavigationBarItem(
              icon: Icon(Icons.timeline_outlined), label: 'Activity'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined), label: 'Profile'),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: RetraceSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: RetraceSpacing.sm),
          child,
        ],
      ),
    );
  }
}
