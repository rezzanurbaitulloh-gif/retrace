import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/design_system/components/retrace_cards.dart';
import 'package:retrace/design_system/components/retrace_states.dart';
import 'package:retrace/features/devices/devices_repository.dart';

final deviceByIdProvider =
    FutureProvider.family<DeviceSummary?, String>((Ref ref, String id) {
  return ref.watch(devicesRepositoryProvider).getById(id);
});

/// Device detail route. Full header/map/status/actions land in Phase 3–6;
/// an unknown id renders an honest not-found error, never a fake device.
class DeviceDetailPage extends ConsumerWidget {
  const DeviceDetailPage({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DeviceSummary?> device =
        ref.watch(deviceByIdProvider(deviceId));
    return Scaffold(
      appBar: AppBar(title: const Text('Device')),
      body: switch (device) {
        AsyncLoading() =>
          const LoadingState(message: 'Loading device…'),
        AsyncError(:final Object error) => ErrorState(
            message:
                'Unable to load device: ${error.toString().replaceFirst('Exception: ', '')}',
            onRetry: () =>
                ref.invalidate(deviceByIdProvider(deviceId)),
          ),
        AsyncData(:final DeviceSummary? value) => value == null
            ? ErrorState(
                message:
                    'Device not found. It may have been removed.',
                onRetry: () =>
                    ref.invalidate(deviceByIdProvider(deviceId)),
              )
            : ListView(
                padding: const EdgeInsets.all(RetraceSpacing.md),
                children: [
                  DeviceCard(
                    name: value.name,
                    meta: value.meta,
                    status: value.status,
                    lastSeen: value.lastSeen,
                  ),
                  const SizedBox(height: RetraceSpacing.sm),
                  const MapCard(
                    statusLine:
                        'Map engine arrives in Phase 4 — no location is shown until real tracking exists.',
                  ),
                  const SizedBox(height: RetraceSpacing.sm),
                  RetraceButton(
                    label: 'View evidence',
                    icon: Icons.photo_library_outlined,
                    isSecondary: true,
                    onPressed: () => context
                        .push('/devices/${value.id}/evidence'),
                  ),
                ],
              ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
