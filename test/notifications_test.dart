import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/features/notifications/notifications.dart';

void main() {
  group('parseDeepLink', () {
    test('custom scheme routes', () {
      expect(parseDeepLink(Uri.parse('retrace://device/abc')),
          equals('/devices/abc'));
      expect(parseDeepLink(Uri.parse('retrace://recover/RT-1')),
          equals('/lost/RT-1'));
      expect(parseDeepLink(Uri.parse('retrace://finder/RT-1')),
          equals('/finder/RT-1'));
      expect(parseDeepLink(Uri.parse('retrace://evidence/dev-9')),
          equals('/devices/dev-9/evidence'));
      expect(parseDeepLink(Uri.parse('retrace://contacts')),
          equals('/trusted-contacts'));
      expect(parseDeepLink(Uri.parse('retrace://notifications')),
          equals('/notifications'));
    });

    test('https retrace.app links (QR / contactUrl format)', () {
      expect(parseDeepLink(Uri.parse('https://retrace.app/recover/RT-1')),
          equals('/lost/RT-1'));
      expect(parseDeepLink(Uri.parse('https://retrace.app/device/abc')),
          equals('/devices/abc'));
    });

    test('unknown links yield null, never a guess', () {
      expect(parseDeepLink(Uri.parse('retrace://device/')), isNull);
      expect(parseDeepLink(Uri.parse('retrace://unknown/x')), isNull);
      expect(parseDeepLink(Uri.parse('retrace://contacts/extra')), isNull);
      expect(
          parseDeepLink(Uri.parse('https://retrace.app/recover/')), isNull);
      expect(parseDeepLink(Uri.parse('https://evil.com/recover/RT-1')),
          isNull);
      expect(parseDeepLink(Uri.parse('https://retrace.app/other/path')),
          isNull);
      expect(parseDeepLink(Uri.parse('mailto:a@b.com')), isNull);
    });
  });

  group('RetraceChannel', () {
    test('ids are stable and unique', () {
      final List<String> ids =
          RetraceChannel.values.map((RetraceChannel c) => c.id).toList();
      expect(ids.toSet(), hasLength(RetraceChannel.values.length));
      expect(ids, contains('retrace_commands'));
      expect(ids, contains('retrace_recovery'));
      expect(ids, contains('retrace_system'));
    });
  });

  group('notificationIdFor', () {
    test('stable, positive, 31-bit', () {
      final int a = notificationIdFor('cmd_x');
      expect(a, equals(notificationIdFor('cmd_x')));
      expect(a, greaterThanOrEqualTo(0));
      expect(a, lessThan(1 << 31));
    });
  });

  group('RetraceNotification JSON', () {
    test('round-trips incl. route', () {
      final RetraceNotification original = RetraceNotification(
        id: 7,
        channel: RetraceChannel.recovery,
        title: 'Sighted',
        body: 'Seen near the park.',
        route: '/finder/RT-1',
        createdAt: DateTime.utc(2026, 9, 18, 10),
      );
      final RetraceNotification back =
          RetraceNotification.fromJson(original.toJson());
      expect(back.id, equals(7));
      expect(back.channel, equals(RetraceChannel.recovery));
      expect(back.route, equals('/finder/RT-1'));
    });

    test('unknown channel degrades to system', () {
      final Map<String, dynamic> raw = <String, dynamic>{
        'id': 1,
        'channel': 'push',
        'title': 't',
        'body': 'b',
        'route': null,
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      };
      expect(RetraceNotification.fromJson(raw).channel,
          equals(RetraceChannel.system));
    });
  });
}
