import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/features/devices/devices_repository.dart';

final List<DeviceSummary> _fixtures = <DeviceSummary>[
  const DeviceSummary(
    id: '1',
    name: "Rezza's Phone",
    meta: 'OPPO A18',
    status: DeviceStatus.protected,
    lastSeen: '12 sec ago',
  ),
  const DeviceSummary(
    id: '2',
    name: 'iPad',
    meta: 'Tablet',
    status: DeviceStatus.offline,
    lastSeen: '3h ago',
  ),
  const DeviceSummary(
    id: '3',
    name: 'Galaxy Watch',
    meta: 'Wear OS',
    status: DeviceStatus.lost,
    lastSeen: 'Lost Mode',
  ),
];

void main() {
  group('filterDevices', () {
    test('all returns everything when query empty', () {
      expect(filterDevices(_fixtures, DeviceFilter.all, ''), hasLength(3));
    });
    test('online filter', () {
      final List<DeviceSummary> out =
          filterDevices(_fixtures, DeviceFilter.online, '');
      expect(out, hasLength(1));
      expect(out.first.name, "Rezza's Phone");
    });
    test('offline filter', () {
      final List<DeviceSummary> out =
          filterDevices(_fixtures, DeviceFilter.offline, '');
      expect(out, hasLength(1));
      expect(out.first.name, 'iPad');
    });
    test('lost filter', () {
      expect(filterDevices(_fixtures, DeviceFilter.lost, ''), hasLength(1));
    });
    test('search by name case-insensitive', () {
      expect(filterDevices(_fixtures, DeviceFilter.all, 'rezza'), hasLength(1));
      expect(filterDevices(_fixtures, DeviceFilter.all, 'GALAXY'), hasLength(1));
      expect(filterDevices(_fixtures, DeviceFilter.all, 'watch'), hasLength(1));
    });
    test('search by meta', () {
      expect(filterDevices(_fixtures, DeviceFilter.all, 'oppo'), hasLength(1));
    });
    test('filter + search combined', () {
      expect(filterDevices(_fixtures, DeviceFilter.lost, 'watch'), hasLength(1));
      expect(filterDevices(_fixtures, DeviceFilter.lost, 'ipad'), isEmpty);
    });
    test('no match returns empty', () {
      expect(filterDevices(_fixtures, DeviceFilter.all, 'zzz'), isEmpty);
    });
  });
}
