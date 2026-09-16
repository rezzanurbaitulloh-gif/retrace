import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Real permission states (§15, §64). Tap → explains why, status, risk, fix.
/// Open Settings is the only honest path — we never pretend to toggle ourselves.
enum AppPermission {
  location,
  backgroundLocation,
  notifications,
  camera,
  bluetooth,
  batteryOptimization,
}

extension AppPermissionLabel on AppPermission {
  String get title => switch (this) {
        AppPermission.location => 'Location',
        AppPermission.backgroundLocation => 'Background Location',
        AppPermission.notifications => 'Notifications',
        AppPermission.camera => 'Camera',
        AppPermission.bluetooth => 'Bluetooth',
        AppPermission.batteryOptimization => 'Battery Optimization',
      };

  String get why => switch (this) {
        AppPermission.location => 'Live tracking needs precise location.',
        AppPermission.backgroundLocation =>
          'Continued tracking when the app is in background.',
        AppPermission.notifications =>
          'Commands and recovery alerts need notification permission.',
        AppPermission.camera => 'Evidence capture uses the camera when you trigger it.',
        AppPermission.bluetooth =>
          'Optional nearby-device scans (finder relay).',
        AppPermission.batteryOptimization =>
          'Aggressive optimization can pause background tracking.',
      };
}

@immutable
final class PermissionState {
  const PermissionState({
    required this.permission,
    required this.status,
    required this.isGranted,
    required this.isLimited,
  });

  final AppPermission permission;
  final PermissionStatus status;
  final bool isGranted;
  final bool isLimited;
}

abstract class PermissionService {
  Future<List<PermissionState>> checkAll();
  Future<PermissionState> check(AppPermission p);
  Future<void> openSettings();
}

final permissionServiceProvider =
    Provider<PermissionService>((Ref ref) => RealPermissionService());

/// Production implementation over permission_handler + battery optimization heuristics.
/// Battery optimization has no direct handler API — we report Limited as the honest default
/// until a platform channel can detect DOZE/ignore-battery whitelisting (documented PLATFORM-LIMITED).
final class RealPermissionService implements PermissionService {
  @override
  Future<PermissionState> check(AppPermission p) async {
    final PermissionStatus s = await _nativeStatus(p);
    final bool granted = s.isGranted;
    final bool limited = s.isLimited || s.isRestricted;
    return PermissionState(
      permission: p,
      status: s,
      isGranted: granted,
      isLimited: limited,
    );
  }

  @override
  Future<List<PermissionState>> checkAll() async {
    final List<PermissionState> out = <PermissionState>[];
    for (final AppPermission p in AppPermission.values) {
      out.add(await check(p));
    }
    return out;
  }

  @override
  Future<void> openSettings() => openAppSettings();

  Future<PermissionStatus> _nativeStatus(AppPermission p) async {
    try {
      return switch (p) {
        AppPermission.location => await Permission.location.status,
        AppPermission.backgroundLocation =>
          await Permission.locationAlways.status,
        AppPermission.notifications => await Permission.notification.status,
        AppPermission.camera => await Permission.camera.status,
        AppPermission.bluetooth => await Permission.bluetooth.status,
        AppPermission.batteryOptimization => PermissionStatus.denied,
      };
    } on Object catch (_) {
      return PermissionStatus.denied;
    }
  }
}

/// Protection score is pure function of real states — never fake (§14).
int protectionScore(List<PermissionState> states) {
  if (states.isEmpty) return 0;
  // weight: location 25, background 25, notifications 15, camera 10, bluetooth 10, battery 15 = 100
  const Map<AppPermission, int> w = <AppPermission, int>{
    AppPermission.location: 25,
    AppPermission.backgroundLocation: 25,
    AppPermission.notifications: 15,
    AppPermission.camera: 10,
    AppPermission.bluetooth: 10,
    AppPermission.batteryOptimization: 15,
  };
  int score = 0;
  for (final PermissionState s in states) {
    if (s.isGranted) {
      score += w[s.permission] ?? 0;
    } else if (s.isLimited) {
      score += ((w[s.permission] ?? 0) ~/ 2);
    }
  }
  return score.clamp(0, 100);
}
