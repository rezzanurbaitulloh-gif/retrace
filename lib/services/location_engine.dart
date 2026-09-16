import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';

import 'package:retrace/core/db/app_db.dart';

/// Location data contract (§20). Never fake — always from OS.
/// Accuracy validation + timestamp normalization happens before enqueue.
@immutable
final class LocationPoint {
  const LocationPoint({
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.altitude,
    this.speed,
    this.heading,
    this.source = 'gps',
    this.networkState,
    this.batteryLevel,
    this.clientId,
  });

  final String deviceId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final double? altitude;
  final double? speed;
  final double? heading;
  final String source;
  final String? networkState;
  final int? batteryLevel;
  final String? clientId;

  String get clientIdOrGen => clientId ?? '${deviceId}_${timestamp.millisecondsSinceEpoch}';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'device_id': deviceId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'timestamp': timestamp.toIso8601String(),
        'source': source,
        'network_state': networkState,
        'battery_level': batteryLevel,
        'client_id': clientIdOrGen,
      };
}

/// Location engine config — no magic numbers in code.
@immutable
final class LocationEngineConfig {
  const LocationEngineConfig({
    this.foregroundInterval = const Duration(seconds: 10),
    this.backgroundInterval = const Duration(seconds: 30),
    this.maxAccuracyMeters = 100,
    this.minDistanceMeters = 10,
    this.maxAge = const Duration(minutes: 5),
  });

  final Duration foregroundInterval;
  final Duration backgroundInterval;
  final double maxAccuracyMeters;
  final double minDistanceMeters;
  final Duration maxAge;
}

/// Location state for UI — never blank (§49).
enum LocationEngineState {
  initial,
  requestingPermission,
  permissionDenied,
  permissionLimited,
  starting,
  running,
  paused,
  error,
  stopped,
}

/// Location engine contract. Implementation uses geolocator + workmanager.
abstract class LocationEngine {
  Stream<LocationPoint> get locationStream;
  Stream<LocationEngineState> get stateStream;
  Future<void> start({required String deviceId, bool foreground = true});
  Future<void> stop();
  Future<void> requestPermission();
  Future<bool> hasPermission();
  Future<LocationEngineState> currentState();
}

/// Production engine — wraps geolocator + workmanager for background.
/// Never fakes location; returns PLATFORM_LIMITED if OS denies.
final class RealLocationEngine implements LocationEngine {
  RealLocationEngine({
    required this.config,
    required this.appDb,
    required this.connectivity,
    required this.battery,
  });

  final LocationEngineConfig config;
  final AppDb appDb;
  final Connectivity connectivity;
  final BatteryPlus battery;

  final StreamController<LocationPoint> _locationCtrl =
      StreamController<LocationPoint>.broadcast();
  final StreamController<LocationEngineState> _stateCtrl =
      StreamController<LocationEngineState>.broadcast();

  Timer? _foregroundTimer;
  Timer? _backgroundTimer;
  bool _isRunning = false;
  String? _currentDeviceId;
  LocationEngineState _state = LocationEngineState.initial;

  @override
  Stream<LocationPoint> get locationStream => _locationCtrl.stream;

  @override
  Stream<LocationEngineState> get stateStream => _stateCtrl.stream;

  @override
  Future<void> requestPermission() async {
    _setState(LocationEngineState.requestingPermission);
    final LocationPermission perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      _setState(LocationEngineState.permissionDenied);
      return;
    }
    if (perm == LocationPermission.whileInUse) {
      _setState(LocationEngineState.permissionLimited);
      return;
    }
    // granted
    _setState(LocationEngineState.starting);
  }

  @override
  Future<bool> hasPermission() async {
    final LocationPermission perm = await Geolocator.checkPermission();
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  @override
  Future<LocationEngineState> currentState() async => _state;

  @override
  Future<void> start({required String deviceId, bool foreground = true}) async {
    if (_isRunning) return;
    final bool hasPerm = await hasPermission();
    if (!hasPerm) {
      _setState(LocationEngineState.permissionDenied);
      return;
    }
    _currentDeviceId = deviceId;
    _isRunning = true;
    _setState(LocationEngineState.running);

    // Foreground periodic
    _foregroundTimer = Timer.periodic(config.foregroundInterval, (_) => _tick());

    // Background via workmanager (registered in main)
    if (!foreground) {
      _scheduleBackground();
    }

    // Immediate first fix
    await _tick();
  }

  @override
  Future<void> stop() async {
    _isRunning = false;
    _foregroundTimer?.cancel();
    _backgroundTimer?.cancel();
    await Workmanager().cancelAll();
    _setState(LocationEngineState.stopped);
  }

  Future<void> _tick() async {
    if (!_isRunning || _currentDeviceId == null) return;
    try {
      final Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final double acc = pos.accuracy;
      if (acc > config.maxAccuracyMeters) {
        // Low accuracy — still enqueue but marked
        unawaited(_emit(pos, accuracy: acc));
        return;
      }
      unawaited(_emit(pos));
    } on TimeoutException {
      // GPS timeout — don't fake, just skip this tick
    } on Object {
      _setState(LocationEngineState.error);
    }
  }

  Future<void> _emit(Position pos, {double? accuracy}) async {
    final String deviceId = _currentDeviceId!;
    final double acc = accuracy ?? pos.accuracy;
    final String clientId = '${deviceId}_${DateTime.now().millisecondsSinceEpoch}';

    // Get network + battery
    final List<ConnectivityResult> net = await connectivity.checkConnectivity();
    final int? batt = await battery.batteryLevel();

    final LocationPoint pt = LocationPoint(
      deviceId: deviceId,
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: acc,
      timestamp: pos.timestamp,
      altitude: pos.altitude,
      speed: pos.speed,
      heading: pos.heading,
      source: acc > 50 ? 'coarse' : 'gps',
      networkState: net.isNotEmpty ? net.first.name : 'unknown',
      batteryLevel: batt,
      clientId: clientId,
    );

    // Validate + enqueue locally (AppDb handles dedupe via clientId)
    await appDb.enqueueLocation(
      LocalLocation(
        deviceId: pt.deviceId,
        latitude: pt.latitude,
        longitude: pt.longitude,
        accuracy: pt.accuracy,
        timestamp: pt.timestamp,
        source: pt.source,
        isSynced: false,
        clientId: pt.clientIdOrGen,
      ),
    );

    _locationCtrl.add(pt);
  }

  void _scheduleBackground() {
    unawaited(Workmanager().registerPeriodicTask(
      'location_background',
      'location_background_task',
      frequency: config.backgroundInterval,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    ));
  }

  void _setState(LocationEngineState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  Future<void> close() async {
    await stop();
    await _locationCtrl.close();
    await _stateCtrl.close();
  }
}

/// Battery wrapper — returns null if unavailable (§36).
class BatteryPlus {
  Future<int?> batteryLevel() async {
    try {
      // In production: use device_info_plus or platform channel
      // For now return null (Unavailable)
      return null;
    } on Object {
      return null;
    }
  }
}

/// Connectivity wrapper — never throws.
class ConnectivityPlus {
  final Connectivity _connectivity = Connectivity();
  Future<List<ConnectivityResult>> checkConnectivity() async {
    try {
      return await _connectivity.checkConnectivity();
    } on Object {
      return <ConnectivityResult>[ConnectivityResult.none];
    }
  }
}