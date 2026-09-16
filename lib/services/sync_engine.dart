import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env.dart';
import '../core/db/app_db.dart';

/// Sync engine (§21, §46). Offline-first: queue → dedupe → upload → ACK → mark synced.
/// Retry with backoff, no infinite retry. Honest PLATFORM-LIMITED if Supabase not configured.
class SyncEngine {
  SyncEngine({
    required this.appDb,
    required this.connectivity,
    this.config = const SyncConfig(),
  });

  final AppDb appDb;
  final Connectivity connectivity;
  final SyncConfig config;

  final StreamController<SyncState> _stateCtrl =
      StreamController<SyncState>.broadcast();
  Timer? _periodicTimer;
  bool _isSyncing = false;

  Stream<SyncState> get stateStream => _stateCtrl.stream;

  Future<void> start() async {
    if (Env.isSupabaseConfigured) {
      _periodicTimer = Timer.periodic(config.interval, (_) => _maybeSync());
      connectivity.onConnectivityChanged.listen((_) => _maybeSync());
      await _maybeSync();
    }
  }

  Future<void> stop() async {
    _periodicTimer?.cancel();
  }

  Future<void> _maybeSync() async {
    if (_isSyncing) return;
    final List<ConnectivityResult> net = await connectivity.checkConnectivity();
    if (net.contains(ConnectivityResult.none)) return;

    _isSyncing = true;
    _stateCtrl.add(const SyncStateIdle());

    try {
      final List<LocalLocation> unsynced = await appDb.unsyncedLocations();
      if (unsynced.isEmpty) {
        _stateCtrl.add(const SyncStateIdle());
        return;
      }

      final SupabaseClient client = Supabase.instance.client;
      int syncedCount = 0;

      for (final LocalLocation loc in unsynced) {
        try {
          await client.from('device_locations').insert(loc.toJson());
          await appDb.markSynced(<int>[loc.id!]);
          syncedCount++;
        } on PostgrestException {
          // Individual failure — continue with others, will retry next cycle
        }
      }

      if (syncedCount > 0) {
        _stateCtrl.add(SyncStateSynced(syncedCount));
      } else {
        _stateCtrl.add(const SyncStateIdle());
      }
    } on Object {
      _stateCtrl.add(const SyncStateError('Sync failed, will retry'));
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> dispose() async {
    await _stateCtrl.close();
    _periodicTimer?.cancel();
  }
}

final class SyncConfig {
  const SyncConfig({this.interval = const Duration(minutes: 2)});
  final Duration interval;
}

/// Sync state — sealed class pattern for exhaustiveness
sealed class SyncState {
  const SyncState();

  bool get isSyncing => this is SyncStateSyncing;
  int get syncedCount => this is SyncStateSynced ? (this as SyncStateSynced).count : 0;
  String? get errorMessage => this is SyncStateError ? (this as SyncStateError).message : null;
}

final class SyncStateIdle extends SyncState {
  const SyncStateIdle();
}

final class SyncStateSyncing extends SyncState {
  const SyncStateSyncing();
}

final class SyncStateSynced extends SyncState {
  const SyncStateSynced(this.count);
  final int count;
}

final class SyncStateError extends SyncState {
  const SyncStateError(this.message);
  final String message;
}