import 'package:permission_handler/permission_handler.dart';
class PermissionService {
  static const _explain = {
    Permission.location: 'Location for tracking (PRD 9)',
    Permission.locationAlways: 'Background location for Lost Mode',
    Permission.camera: 'Camera for recovery evidence (front/rear)',
    Permission.notification: 'Notifications for recovery events',
    Permission.bluetooth: 'Bluetooth/Nearby for nearby recovery',
  };
  static String explain(Permission p) => _explain[p] ?? p.toString();
  Future<bool> requestWithRationale(Permission p) async {
    final status = await p.status;
    if (status.isGranted) return true;
    final result = await p.request();
    return result.isGranted;
  }
  String fallback(Permission p) {
    if (p == Permission.location) return 'Show Last known ±m + offline queue';
    if (p == Permission.camera) return 'UNSUPPORTED — respects OS indicator';
    return 'Offline queue + finder mechanisms';
  }
}
