import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/core/theme/retrace_colors.dart';

/// Minimal device summary for the shell. Full device identity, status
/// pipeline and Supabase wiring arrive in Phase 3 — this layer only owns
/// list/filter/search behavior, tested against an explicit stub.
@immutable
final class DeviceSummary {
  const DeviceSummary({
    required this.id,
    required this.name,
    required this.meta,
    required this.status,
    required this.lastSeen,
  });

  final String id;
  final String name;
  final String meta;
  final DeviceStatus status;
  final String lastSeen;
}

enum DeviceFilter { all, online, offline, lost }

/// Pure filter+search. Online = protected/online; offline = offline/limited.
List<DeviceSummary> filterDevices(
  List<DeviceSummary> devices,
  DeviceFilter filter,
  String query,
) {
  final String q = query.trim().toLowerCase();
  return devices.where((DeviceSummary d) {
    final bool matchesFilter = switch (filter) {
      DeviceFilter.all => true,
      DeviceFilter.online =>
        d.status == DeviceStatus.protected ||
            d.status == DeviceStatus.online,
      DeviceFilter.offline =>
        d.status == DeviceStatus.offline ||
            d.status == DeviceStatus.limited,
      DeviceFilter.lost => d.status == DeviceStatus.lost,
    };
    if (!matchesFilter) return false;
    if (q.isEmpty) return true;
    return d.name.toLowerCase().contains(q) ||
        d.meta.toLowerCase().contains(q);
  }).toList();
}

abstract class DevicesRepository {
  Stream<List<DeviceSummary>> watchDevices();
  Future<DeviceSummary?> getById(String id);
}

/// Phase 2 local stub: returns the real empty state (no devices registered
/// yet) instead of hardcoded demo devices — hardcoding is forbidden (§69).
/// Phase 3 replaces this with Supabase (`devices` table + RLS).
final class LocalDevicesRepository implements DevicesRepository {
  @override
  Stream<List<DeviceSummary>> watchDevices() =>
      Stream<List<DeviceSummary>>.value(const <DeviceSummary>[]);

  @override
  Future<DeviceSummary?> getById(String id) async => null;
}

final devicesRepositoryProvider = Provider<DevicesRepository>(
  (Ref ref) => LocalDevicesRepository(),
);

final devicesStreamProvider = StreamProvider<List<DeviceSummary>>(
  (Ref ref) => ref.watch(devicesRepositoryProvider).watchDevices(),
);
