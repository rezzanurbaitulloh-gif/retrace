import 'package:permission_handler/permission_handler.dart';
class PermissionService {
  static String explain(Permission p) {
    if (p == Permission.location) return 'Location for tracking (PRD 9)';
    if (p == Permission.locationAlways) return 'Background location for Lost Mode';
    if (p == Permission.camera) return 'Camera for recovery evidence (front/rear)';
    if (p == Permission.notification) return 'Notifications for recovery events';
    if (p == Permission.bluetooth) return 'Bluetooth/Nearby for nearby recovery';
    return p.toString();
  }
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
