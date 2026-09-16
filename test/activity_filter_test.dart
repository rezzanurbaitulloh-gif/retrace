import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/features/activity/activity_repository.dart';

void main() {
  group('filterActivity', () {
    final List<ActivityEvent> fixtures = <ActivityEvent>[
      const ActivityEvent(
        id: '1',
        category: ActivityCategory.security,
        title: 'Lost Mode activated',
        timestamp: '10:27',
      ),
      const ActivityEvent(
        id: '2',
        category: ActivityCategory.location,
        title: 'Location updated',
        timestamp: '10:32',
      ),
      const ActivityEvent(
        id: '3',
        category: ActivityCategory.finder,
        title: 'QR scanned',
        timestamp: '10:21',
      ),
    ];

    test('all returns everything', () {
      expect(filterActivity(fixtures, ActivityFilter.all), hasLength(3));
    });
    test('security filter', () {
      expect(filterActivity(fixtures, ActivityFilter.security), hasLength(1));
    });
    test('finder filter', () {
      expect(filterActivity(fixtures, ActivityFilter.finder), hasLength(1));
    });
    test('location filter', () {
      expect(filterActivity(fixtures, ActivityFilter.location), hasLength(1));
    });
    test('device filter with no device events', () {
      expect(filterActivity(fixtures, ActivityFilter.device), isEmpty);
    });
  });
}
