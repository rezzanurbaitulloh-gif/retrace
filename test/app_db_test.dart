import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/core/db/app_db.dart';

void main() {
  group('AppDb', () {
    late AppDb db;
    setUp(() {
      db = AppDb.forTesting();
    });
    tearDown(() async => db.close());

    test('upsert and watch devices', () async {
      await db.upsertDevice(
        LocalDevice(id: '1', name: 'Phone', deviceType: 'Phone', brand: 'OPPO', model: 'A18'),
      );
      expect((await db.allDevices()).length, equals(1));
      await db.upsertDevice(
        LocalDevice(id: '1', name: 'Phone Renamed', deviceType: 'Phone', brand: 'OPPO', model: 'A18'),
      );
      expect((await db.allDevices()).first.name, equals('Phone Renamed'));
      expect((await db.allDevices()).length, equals(1));
    });

    test('location queue dedupes by clientId', () async {
      final LocalLocation loc = LocalLocation(
        deviceId: '1',
        latitude: -7.9,
        longitude: 112.5,
        timestamp: DateTime.now(),
        clientId: 'c1',
      );
      expect(await db.enqueueLocation(loc), greaterThan(0));
      expect(await db.enqueueLocation(loc), equals(-1)); // deduped
      expect((await db.unsyncedLocations()).length, equals(1));
    });

    test('markSynced and clearSynced', () async {
      await db.enqueueLocation(
        LocalLocation(deviceId: '1', latitude: 0, longitude: 0, timestamp: DateTime.now(), clientId: 'c2'),
      );
      await db.enqueueLocation(
        LocalLocation(deviceId: '1', latitude: 1, longitude: 1, timestamp: DateTime.now(), clientId: 'c3'),
      );
      final List<LocalLocation> unsynced = await db.unsyncedLocations();
      expect(unsynced.length, equals(2));
      await db.markSynced(unsynced.map((LocalLocation e) => e.id!).toList());
      expect((await db.unsyncedLocations()).length, equals(0));
      await db.clearSynced();
      // no error, remains 0 unsynced
      expect((await db.unsyncedLocations()).length, equals(0));
    });

    test('deleteDevice', () async {
      await db.upsertDevice(LocalDevice(id: 'x', name: 'X', deviceType: 'Other'));
      await db.deleteDevice('x');
      expect(await db.allDevices(), isEmpty);
    });
  });
}
