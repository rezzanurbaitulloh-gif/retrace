import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:workmanager/workmanager.dart';

import 'package:retrace/core/db/app_db.dart';
import 'package:retrace/features/map/map_components.dart';
import 'package:retrace/services/location_engine.dart';
import 'package:retrace/services/sync_engine.dart';

/// Core infrastructure providers (Phase 3+)
final appDbProvider = Provider<AppDb>((Ref ref) {
  final AppDb db = AppDb();
  ref.onDispose(() => db.close());
  return db;
});

final locationEngineConfigProvider = Provider<LocationEngineConfig>(
  (Ref ref) => const LocationEngineConfig(),
);

final locationEngineProvider = Provider<LocationEngine>(
  (Ref ref) => RealLocationEngine(
    config: ref.watch(locationEngineConfigProvider),
    appDb: ref.watch(appDbProvider),
    connectivity: Connectivity(),
    battery: BatteryPlus(),
  ),
);

final mapControllerProvider = Provider<RetraceMapController>(
  (Ref ref) => RetraceMapController(),
);

final syncEngineProvider = Provider<SyncEngine>(
  (Ref ref) => SyncEngine(
    appDb: ref.watch(appDbProvider),
    connectivity: Connectivity(),
  ),
);

/// Workmanager callback — must be top-level or static.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) async {
    // Background location task would run here
    // In production: initialize location engine, get position, enqueue to local DB
    return Future.value(true);
  });
}