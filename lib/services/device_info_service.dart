import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Real device identity (§12). IMEI is UNavailable on stock Android Flutter
/// (needs privileged API) — report "Unavailable", never fake. Brand/model/OS
/// come from platform; serial may be "unknown" on some devices — also honest.
@immutable
final class DeviceIdentity {
  const DeviceIdentity({
    required this.brand,
    required this.model,
    required this.osName,
    required this.osVersion,
    required this.manufacturer,
    required this.isPhysical,
    this.androidId,
  });

  final String brand;
  final String model;
  final String osName;
  final String osVersion;
  final String manufacturer;
  final bool isPhysical;
  final String? androidId;

  String get displayLabel => '$brand $model • $osName $osVersion';

  static const DeviceIdentity fallback = DeviceIdentity(
    brand: 'Unknown',
    model: 'Unknown',
    osName: 'Unknown',
    osVersion: 'Unknown',
    manufacturer: 'Unknown',
    isPhysical: false,
  );
}

abstract class DeviceInfoService {
  Future<DeviceIdentity> getIdentity();
  Future<String> getAppVersion();
}

final class RealDeviceInfoService implements DeviceInfoService {
  final DeviceInfoPlugin _plugin = DeviceInfoPlugin();

  @override
  Future<DeviceIdentity> getIdentity() async {
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo a = await _plugin.androidInfo;
        return DeviceIdentity(
          brand: a.brand,
          model: a.model,
          osName: 'Android',
          osVersion: a.version.release,
          manufacturer: a.manufacturer,
          isPhysical: a.isPhysicalDevice,
          androidId: a.id,
        );
      }
      if (Platform.isIOS) {
        final IosDeviceInfo i = await _plugin.iosInfo;
        return DeviceIdentity(
          brand: 'Apple',
          model: i.model,
          osName: i.systemName,
          osVersion: i.systemVersion,
          manufacturer: 'Apple',
          isPhysical: i.isPhysicalDevice,
        );
      }
    } on Object catch (_) {
      // fall through to fallback — never throw to UI (§48)
    }
    return DeviceIdentity.fallback;
  }

  @override
  Future<String> getAppVersion() async {
    try {
      final PackageInfo pi = await PackageInfo.fromPlatform();
      return '${pi.version}+${pi.buildNumber}';
    } on Object catch (_) {
      return 'unknown';
    }
  }
}
