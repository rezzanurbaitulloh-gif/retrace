import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/core/db/app_db.dart';
import 'package:retrace/features/lost_mode/lost_mode.dart';
import 'package:retrace/providers.dart';

/// Local Lost Mode persistence + queue.
class LostModeLocalRepository {
  LostModeLocalRepository(this._db);

  final AppDb _db;

  Future<void> upsert(LostModeInfo info) async {
    // For now store in memory - Phase 6+ will add Drift table
    // This is a placeholder that satisfies the interface
  }

  Future<LostModeInfo?> getByDeviceId(String deviceId) async {
    return null; // Phase 6+ implementation
  }
}

/// Remote Lost Mode API.
abstract class LostModeRemoteRepository {
  Future<LostModeInfo> activateLostMode(String deviceId, String requestedBy);
  Future<LostModeInfo> deactivateLostMode(String deviceId, String requestedBy);
  Future<LostScreenData> getLostScreenData(String recoveryId);
  Future<RemoteCommand> sendCommand(RemoteCommand command);
  Future<List<RemoteCommand>> getCommandHistory(String deviceId);
}

/// Production implementation - calls Supabase Edge Functions / REST.
class SupabaseLostModeRemoteRepository implements LostModeRemoteRepository {
  SupabaseLostModeRemoteRepository(this._appDb);

  final AppDb _appDb;

  @override
  Future<LostModeInfo> activateLostMode(String deviceId, String requestedBy) async {
    // TODO: Call Supabase RPC / edge function
    // For now return local-only info
    return LostModeInfo(
      deviceId: deviceId,
      state: LostModeState.active,
      activatedAt: DateTime.now(),
      recoveryId: 'RT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
    );
  }

  @override
  Future<LostModeInfo> deactivateLostMode(String deviceId, String requestedBy) async {
    return LostModeInfo(
      deviceId: deviceId,
      state: LostModeState.inactive,
      activatedAt: DateTime.now(),
      deactivatedAt: DateTime.now(),
    );
  }

  @override
  Future<LostScreenData> getLostScreenData(String recoveryId) async {
    return LostScreenData(
      recoveryId: recoveryId,
      message: 'If you\'ve found this device, please help return it.',
      contactUrl: 'https://retrace.app/recover/$recoveryId',
      qrData: 'https://retrace.app/recover/$recoveryId',
    );
  }

  @override
  Future<RemoteCommand> sendCommand(RemoteCommand command) async {
    // TODO: Insert into Supabase lost_commands table
    // For now return with PENDING status
    return command.copyWith(status: CommandStatus.pending);
  }

  @override
  Future<List<RemoteCommand>> getCommandHistory(String deviceId) async {
    // TODO: Query Supabase lost_commands table
    return [];
  }
}

/// Phase 5 local stub (offline-first).
class LocalLostModeRepository implements LostModeRemoteRepository {
  LocalLostModeRepository(this._db);

  final AppDb _db;

  @override
  Future<LostModeInfo> activateLostMode(String deviceId, String requestedBy) async {
    final info = LostModeInfo(
      deviceId: deviceId,
      state: LostModeState.active,
      activatedAt: DateTime.now(),
      recoveryId: 'RT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
    );
    await _db.enqueueCommand(
      PendingCommand(
        id: 'lost_activate_${DateTime.now().millisecondsSinceEpoch}',
        deviceId: deviceId,
        type: 'LOST_ACTIVATE',
        status: 'PENDING',
        createdAt: DateTime.now(),
      ),
    );
    return info;
  }

  @override
  Future<LostModeInfo> deactivateLostMode(String deviceId, String requestedBy) async {
    return LostModeInfo(
      deviceId: deviceId,
      state: LostModeState.inactive,
      activatedAt: DateTime.now(),
      deactivatedAt: DateTime.now(),
    );
  }

  @override
  Future<LostScreenData> getLostScreenData(String recoveryId) async {
    return LostScreenData(
      recoveryId: recoveryId,
      message: 'If you\'ve found this device, please help return it.',
      contactUrl: 'https://retrace.app/recover/$recoveryId',
      qrData: 'https://retrace.app/recover/$recoveryId',
    );
  }

  @override
  Future<RemoteCommand> sendCommand(RemoteCommand command) async {
    await _db.enqueueCommand(
      PendingCommand(
        id: command.id,
        deviceId: command.deviceId,
        type: command.type.apiValue,
        status: command.status.name.toUpperCase(),
        createdAt: command.createdAt,
      ),
    );
    return command.copyWith(status: CommandStatus.pending);
  }

  @override
  Future<List<RemoteCommand>> getCommandHistory(String deviceId) async {
    final cmds = await _db.pendingFor(deviceId);
    return cmds
        .map((c) => RemoteCommand(
              id: c.id,
              deviceId: c.deviceId,
              type: CommandType.values.firstWhere(
                (t) => t.apiValue == c.type,
                orElse: () => CommandType.requestLocation,
              ),
              status: CommandStatus.values.firstWhere(
                (s) => s.name.toUpperCase() == c.status,
                orElse: () => CommandStatus.pending,
              ),
              createdAt: c.createdAt,
            ))
        .toList();
  }
}

/// High-level controller for Lost Mode.
class LostModeController {
  LostModeController(this._local, this._remote);

  final LostModeLocalRepository _local;
  final LostModeRemoteRepository _remote;

  Future<LostModeInfo> activate(String deviceId, String requestedBy) async {
    // Try remote first, fallback to local
    try {
      final info = await _remote.activateLostMode(deviceId, requestedBy);
      await _local.upsert(info);
      return info;
    } catch (_) {
      return _remote.activateLostMode(deviceId, requestedBy);
    }
  }

  Future<LostModeInfo> deactivate(String deviceId, String requestedBy) async {
    try {
      final info = await _remote.deactivateLostMode(deviceId, requestedBy);
      await _local.upsert(info);
      return info;
    } catch (_) {
      return _remote.deactivateLostMode(deviceId, requestedBy);
    }
  }

  Future<RemoteCommand> sendCommand(RemoteCommand command) async {
    return _remote.sendCommand(command);
  }

  Future<LostScreenData> getLostScreenData(String recoveryId) async {
    return _remote.getLostScreenData(recoveryId);
  }

  Future<List<RemoteCommand>> getHistory(String deviceId) async {
    return _remote.getCommandHistory(deviceId);
  }
}

/// Providers
final lostModeLocalRepositoryProvider = Provider<LostModeLocalRepository>(
  (Ref ref) => LostModeLocalRepository(ref.watch(appDbProvider)),
);

final lostModeRemoteRepositoryProvider = Provider<LostModeRemoteRepository>(
  (Ref ref) => SupabaseLostModeRemoteRepository(ref.watch(appDbProvider)),
);

final lostModeControllerProvider = Provider<LostModeController>(
  (Ref ref) => LostModeController(
    ref.watch(lostModeLocalRepositoryProvider),
    ref.watch(lostModeRemoteRepositoryProvider),
  ),
);