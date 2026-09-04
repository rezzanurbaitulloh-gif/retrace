import 'package:flutter_test/flutter_test.dart';
import 'package:retrace_mobile/features/location/location_engine.dart';
import 'package:retrace_mobile/features/sync/sync_engine.dart';
import 'package:retrace_mobile/features/permissions/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('LocationEngine', () {
    test('AdaptiveProfile stationary vs moving', () {
      final stationary = AdaptiveProfile.interval(moving: false, lost: false, battery: 80);
      final moving = AdaptiveProfile.interval(moving: true, lost: false, battery: 80);
      final lostHigh = AdaptiveProfile.interval(moving: false, lost: true, battery: 80);
      final lostLow = AdaptiveProfile.interval(moving: false, lost: true, battery: 15);
      expect(stationary.inSeconds, greaterThan(moving.inSeconds));
      expect(lostHigh.inSeconds, lessThan(stationary.inSeconds));
      expect(lostLow.inSeconds, greaterThan(lostHigh.inSeconds));
    });

    test('OfflineQueue enqueue and drain', () {
      final q = OfflineQueue();
      final p = LocationPoint(lat: -6.2, lng: 106.8, deviceTimestamp: DateTime.now(), source: 'GPS', confidence: 'HIGH');
      q.enqueue(p);
      expect(q.length, 1);
      final batch = q.drain();
      expect(batch.length, 1);
      expect(q.length, 0);
    });

    test('OfflineQueue respects max 1000', () {
      final q = OfflineQueue();
      for (int i = 0; i < 1050; i++) {
        q.enqueue(LocationPoint(lat: 0, lng: 0, deviceTimestamp: DateTime.now()));
      }
      expect(q.length, 1000);
    });
  });

  group('SyncEngine', () {
    test('dedup prevents duplicate', () {
      final engine = SyncEngine();
      final e1 = SyncEvent(id: 'a1', type: 'location', payload: {}, createdAt: DateTime.now());
      final e2 = SyncEvent(id: 'a1', type: 'location', payload: {}, createdAt: DateTime.now());
      engine.enqueue(e1);
      engine.enqueue(e2);
      expect(engine.length, 1);
    });

    test('ordered by createdAt', () {
      final engine = SyncEngine();
      final e2 = SyncEvent(id: '2', type: 'location', payload: {}, createdAt: DateTime.now().add(const Duration(seconds: 10)));
      final e1 = SyncEvent(id: '1', type: 'location', payload: {}, createdAt: DateTime.now());
      engine.enqueue(e2);
      engine.enqueue(e1);
      final batch = engine.drainBatch(batchSize: 10);
      expect(batch.first.id, '1');
    });

    test('ack success removes', () {
      final engine = SyncEngine();
      final e = SyncEvent(id: 'x', type: 'activity', payload: {}, createdAt: DateTime.now());
      engine.enqueue(e);
      engine.drainBatch();
      engine.ack('x', success: true);
      expect(engine.length, 0);
    });
  });

  group('PermissionService', () {
    test('explain returns string', () {
      expect(PermissionService.explain(Permission.location), contains('Location'));
      expect(PermissionService.explain(Permission.camera), contains('Camera'));
    });

    test('fallback for location', () {
      final s = PermissionService();
      expect(s.fallback(Permission.location), contains('Last known'));
      expect(s.fallback(Permission.camera), contains('UNSUPPORTED'));
    });
  });
}
