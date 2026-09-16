import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/design_system/components/retrace_cards.dart';
import 'package:retrace/design_system/components/retrace_states.dart';
import 'package:retrace/features/devices/devices_repository.dart';

final devicesFilterProvider =
    StateProvider<DeviceFilter>((Ref ref) => DeviceFilter.all);
final devicesQueryProvider = StateProvider<String>((Ref ref) => '');

/// All devices with real filter + search (§17). Empty until registration
/// lands in Phase 3 — the filter/search logic itself is unit-tested now.
class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<DeviceSummary>> devices =
        ref.watch(devicesStreamProvider);
    final DeviceFilter filter = ref.watch(devicesFilterProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Devices'),
        actions: [
          IconButton(
            tooltip: 'Add device',
            onPressed: () => context.push('/devices/new'),
            icon: const Icon(Icons.add_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/devices/new'),
        icon: const Icon(Icons.add_outlined),
        label: const Text('Add Device'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              RetraceSpacing.md,
              RetraceSpacing.sm,
              RetraceSpacing.md,
              0,
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search devices',
                prefixIcon: Icon(Icons.search_outlined),
              ),
              onChanged: (String v) =>
                  ref.read(devicesQueryProvider.notifier).state = v,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: RetraceSpacing.md,
              vertical: RetraceSpacing.sm,
            ),
            child: Row(
              children: DeviceFilter.values.map((DeviceFilter f) {
                final bool selected = f == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_label(f)),
                    selected: selected,
                    onSelected: (_) => ref
                        .read(devicesFilterProvider.notifier)
                        .state = f,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: switch (devices) {
              AsyncLoading() => const LoadingState(
                  message: 'Loading devices…',
                ),
              AsyncError(:final Object error) => ErrorState(
                  message:
                      'Unable to load devices: ${_short(error)}',
                  onRetry: () =>
                      ref.invalidate(devicesStreamProvider),
                ),
              AsyncData(:final List<DeviceSummary> value) =>
                _List(
                  devices: filterDevices(
                    value,
                    filter,
                    ref.watch(devicesQueryProvider),
                  ),
                  hasAny: value.isNotEmpty,
                ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
      bottomNavigationBar: devices.valueOrNull?.isEmpty == true
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(RetraceSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/protection-setup'),
                        icon: const Icon(Icons.shield_outlined, size: 18),
                        label: const Text('Protection setup'),
                      ),
                    ),
                    const SizedBox(width: RetraceSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/permissions'),
                        icon: const Icon(Icons.verified_outlined, size: 18),
                        label: const Text('Permissions'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  static String _label(DeviceFilter f) => switch (f) {
        DeviceFilter.all => 'All',
        DeviceFilter.online => 'Online',
        DeviceFilter.offline => 'Offline',
        DeviceFilter.lost => 'Lost',
      };

  static String _short(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}

class _List extends ConsumerWidget {
  const _List({required this.devices, required this.hasAny});

  final List<DeviceSummary> devices;
  final bool hasAny;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (devices.isEmpty) {
      return EmptyState(
        title: hasAny ? 'No matches' : 'No devices yet',
        message: hasAny
            ? 'Try a different search or filter.'
            : 'Protect your first device with RETRACE. Tap + to register this device.',
        actionLabel: hasAny ? 'Clear search' : null,
        onAction: hasAny
            ? () {
                ref.read(devicesQueryProvider.notifier).state = '';
                ref.read(devicesFilterProvider.notifier).state =
                    DeviceFilter.all;
              }
            : null,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(RetraceSpacing.md),
      itemCount: devices.length,
      // ignore: unnecessary_underscores
      separatorBuilder: (_, __) =>
          const SizedBox(height: RetraceSpacing.sm),
      itemBuilder: (BuildContext context, int i) {
        final DeviceSummary d = devices[i];
        return DeviceCard(
          name: d.name,
          meta: d.meta,
          status: d.status,
          lastSeen: d.lastSeen,
          onTap: () => context.push('/devices/${d.id}'),
        );
      },
    );
  }
}
