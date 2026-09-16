import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/core/db/app_db.dart';
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

/// Phase 3: local is source of truth, backed by AppDb (§45). Supabase sync
/// arrives Phase 4 — until then offline-first means local queue is truthful,
/// never a fake remote device.
final class LocalDevicesRepository implements DevicesRepository {
  LocalDevicesRepository(this._db);
  final AppDb _db;

  @override
  Stream<List<DeviceSummary>> watchDevices() =>
      _db.watchDevices().map(
            (List<LocalDevice> list) => list
                .map(
                  (LocalDevice e) => DeviceSummary(
                    id: e.id,
                    name: e.name,
                    meta: '${e.brand} ${e.model} • ${e.deviceType}',
                    status: DeviceStatus.protected,
                    lastSeen: 'Added ${_short(e.createdAt)}',
                  ),
                )
                .toList(),
          );

  @override
  Future<DeviceSummary?> getById(String id) async {
    final List<LocalDevice> all = await _db.allDevices();
    final LocalDevice? found = all.where((LocalDevice e) => e.id == id).firstOrNull;
    if (found == null) return null;
    return DeviceSummary(
      id: found.id,
      name: found.name,
      meta: '${found.brand} ${found.model} • ${found.deviceType}',
      status: DeviceStatus.protected,
      lastSeen: 'Added ${_short(found.createdAt)}',
    );
  }

  static String _short(DateTime dt) {
    if (dt.millisecondsSinceEpoch == 0) return 'just now';
    final Duration d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

final appDbProvider = Provider<AppDb>((Ref ref) {
  final AppDb db = AppDb();
  ref.onDispose(() => db.close());
  return db;
});

final devicesRepositoryProvider = Provider<DevicesRepository>(
  (Ref ref) => LocalDevicesRepository(ref.watch(appDbProvider)),
);

final devicesStreamProvider = StreamProvider<List<DeviceSummary>>(
  (Ref ref) => ref.watch(devicesRepositoryProvider).watchDevices(),
);
