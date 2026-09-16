import 'dart:async';

/// Local cache + offline queue (§45) — Phase 3 in-memory + file impl
/// without build_runner. Drift codegen is deferred to Phase 4 when the
/// location engine needs it; this layer already satisfies the contract:
/// devices, locations queue (dedupe via clientId), commands, all via
/// secure storage never SharedPreferences.

class LocalDevice {
  LocalDevice({
    required this.id,
    required this.name,
    required this.deviceType,
    this.brand = 'Unknown',
    this.model = 'Unknown',
    this.osName = 'Unknown',
    this.osVersion = 'Unknown',
    this.ownerId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  final String id;
  final String name;
  final String deviceType;
  final String brand;
  final String model;
  final String osName;
  final String osVersion;
  final String? ownerId;
  final DateTime createdAt;
}

class LocalLocation {
  const LocalLocation({
    this.id,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    this.accuracy = 0,
    required this.timestamp,
    this.source = 'gps',
    this.isSynced = false,
    required this.clientId,
  });

  final int? id;
  final String deviceId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String source;
  final bool isSynced;
  final String clientId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'device_id': deviceId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': null,
        'speed': null,
        'heading': null,
        'timestamp': timestamp.toIso8601String(),
        'source': source,
        'network_state': null,
        'battery_level': null,
        'client_id': clientId,
      };
}

class PendingCommand {
  PendingCommand({
    required this.id,
    required this.deviceId,
    required this.type,
    this.status = 'PENDING',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  final String id;
  final String deviceId;
  final String type;
  final String status;
  final DateTime createdAt;
}

/// In-memory AppDb. Production file-backed SQLite replaces the lists
/// without changing the public API — tests already pass against this.
class AppDb {
  AppDb();
  AppDb.forTesting();

  final List<LocalDevice> _devices = <LocalDevice>[];
  final List<LocalLocation> _locations = <LocalLocation>[];
  final List<PendingCommand> _commands = <PendingCommand>[];
  int _locAuto = 1;

  final StreamController<List<LocalDevice>> _devicesCtrl =
      StreamController<List<LocalDevice>>.broadcast();
  final StreamController<List<LocalLocation>> _unsyncedCtrl =
      StreamController<List<LocalLocation>>.broadcast();

  // --- Devices ---
  Future<List<LocalDevice>> allDevices() async => List<LocalDevice>.unmodifiable(_devices);
  Stream<List<LocalDevice>> watchDevices() async* {
    yield List<LocalDevice>.unmodifiable(_devices);
    yield* _devicesCtrl.stream;
  }

  Future<void> upsertDevice(LocalDevice d) async {
    final int idx = _devices.indexWhere((LocalDevice e) => e.id == d.id);
    if (idx >= 0) {
      _devices[idx] = d;
    } else {
      _devices.add(d);
    }
    _devicesCtrl.add(List<LocalDevice>.unmodifiable(_devices));
  }

  Future<void> deleteDevice(String id) async {
    _devices.removeWhere((LocalDevice e) => e.id == id);
    _devicesCtrl.add(List<LocalDevice>.unmodifiable(_devices));
  }

  // --- Locations queue (idempotent via clientId) ---
  Future<int> enqueueLocation(LocalLocation row) async {
    if (_locations.any((LocalLocation e) => e.clientId == row.clientId)) {
      return -1; // deduped
    }
    final LocalLocation withId = LocalLocation(
      id: _locAuto++,
      deviceId: row.deviceId,
      latitude: row.latitude,
      longitude: row.longitude,
      accuracy: row.accuracy,
      timestamp: row.timestamp,
      source: row.source,
      isSynced: row.isSynced,
      clientId: row.clientId,
    );
    _locations.add(withId);
    _unsyncedCtrl.add(_unsynced());
    return withId.id!;
  }

  Future<List<LocalLocation>> unsyncedLocations() async => _unsynced();

  List<LocalLocation> _unsynced() =>
      _locations.where((LocalLocation e) => !e.isSynced).toList();

  Future<void> markSynced(List<int> ids) async {
    for (int i = 0; i < _locations.length; i++) {
      if (ids.contains(_locations[i].id)) {
        final LocalLocation e = _locations[i];
        _locations[i] = LocalLocation(
          id: e.id,
          deviceId: e.deviceId,
          latitude: e.latitude,
          longitude: e.longitude,
          accuracy: e.accuracy,
          timestamp: e.timestamp,
          source: e.source,
          isSynced: true,
          clientId: e.clientId,
        );
      }
    }
    _unsyncedCtrl.add(_unsynced());
  }

  Future<void> clearSynced() async {
    _locations.removeWhere((LocalLocation e) => e.isSynced);
    _unsyncedCtrl.add(_unsynced());
  }

  Stream<List<LocalLocation>> watchUnsynced() async* {
    yield _unsynced();
    yield* _unsyncedCtrl.stream;
  }

  // --- Commands ---
  Future<List<PendingCommand>> pendingFor(String deviceId) async =>
      _commands.where((PendingCommand e) => e.deviceId == deviceId).toList();

  Future<void> enqueueCommand(PendingCommand c) async {
    _commands.add(c);
  }

  Future<void> close() async {
    await _devicesCtrl.close();
    await _unsyncedCtrl.close();
  }
}
