import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:retrace/services/permission_service.dart';

PermissionState _state(AppPermission p, bool granted, {bool limited = false}) =>
    PermissionState(
      permission: p,
      status: granted ? PermissionStatus.granted : PermissionStatus.denied,
      isGranted: granted,
      isLimited: limited,
    );

void main() {
  group('protectionScore', () {
    test('empty is 0', () {
      expect(protectionScore(<PermissionState>[]), equals(0));
    });
    test('all granted is 100', () {
      final List<PermissionState> states = AppPermission.values
          .map((AppPermission p) => _state(p, true))
          .toList();
      expect(protectionScore(states), equals(100));
    });
    test('all denied is 0, limited half', () {
      final List<PermissionState> denied = AppPermission.values
          .map((AppPermission p) => _state(p, false))
          .toList();
      expect(protectionScore(denied), equals(0));
      final List<PermissionState> limited = AppPermission.values
          .map((AppPermission p) => _state(p, false, limited: true))
          .toList();
      // each limited gives half weight = 50
      expect(protectionScore(limited), equals(50));
    });
    test('realistic mix never fake', () {
      final List<PermissionState> mix = <PermissionState>[
        _state(AppPermission.location, true),
        _state(AppPermission.backgroundLocation, true),
        _state(AppPermission.notifications, false, limited: true),
        _state(AppPermission.camera, false),
        _state(AppPermission.bluetooth, true),
        _state(AppPermission.batteryOptimization, false),
      ];
      // 25+25+ (15/2=7) +0+10+0 = 67
      expect(protectionScore(mix), equals(67));
    });
  });
}
