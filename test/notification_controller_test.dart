import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:retrace/features/lost_mode/lost_mode.dart';
import 'package:retrace/features/notifications/notifications.dart';
import 'package:retrace/features/notifications/notifications_controller.dart';
import 'package:retrace/services/notification_platform.dart';
import 'package:retrace/services/permission_service.dart';

final class FakeNotificationPlatform implements NotificationPlatform {
  FakeNotificationPlatform({this.delivered = true});

  bool delivered;
  final List<Map<String, Object?>> calls = <Map<String, Object?>>[];
  Future<void> Function(String? route)? tapHandler;

  @override
  Future<bool> init(Future<void> Function(String? route) onTap) async {
    tapHandler = onTap;
    return true;
  }

  @override
  Future<bool> show({
    required int id,
    required RetraceChannel channel,
    required String title,
    required String body,
    String? route,
  }) async {
    calls.add(<String, Object?>{
      'channel': channel,
      'title': title,
      'body': body,
      'route': route,
    });
    return delivered;
  }

  @override
  Future<String?> launchRoute() async => null;
}

final class FakePermissionService implements PermissionService {
  FakePermissionService({this.granted = true});

  bool granted;

  PermissionState _state() => PermissionState(
        permission: AppPermission.notifications,
        status: granted
            ? PermissionStatus.granted
            : PermissionStatus.denied,
        isGranted: granted,
        isLimited: false,
      );

  @override
  Future<PermissionState> check(AppPermission p) async => _state();

  @override
  Future<List<PermissionState>> checkAll() async => <PermissionState>[_state()];

  @override
  Future<void> openSettings() async {}
}

final class FakeDeepLinkSource implements DeepLinkSource {
  FakeDeepLinkSource({this.initialUri});

  final Uri? initialUri;
  final StreamController<Uri> controller =
      StreamController<Uri>.broadcast();

  @override
  Future<Uri?> initial() async => initialUri;

  @override
  Stream<Uri> links() => controller.stream;
}

RemoteCommand _command() => RemoteCommand(
      id: 'cmd_1',
      deviceId: 'dev_1',
      type: CommandType.ring,
      status: CommandStatus.pending,
      createdAt: DateTime.utc(2026, 9, 18),
    );

void main() {
  group('NotificationController', () {
    test('command status shows + logs with device route', () async {
      final FakeNotificationPlatform platform = FakeNotificationPlatform();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          notificationPlatformProvider.overrideWithValue(platform),
          permissionServiceProvider.overrideWithValue(
            FakePermissionService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(notificationControllerProvider)
          .commandStatus(command: _command(), delivered: false);

      expect(platform.calls, hasLength(1));
      expect(platform.calls.first['channel'],
          equals(RetraceChannel.commands));
      expect(platform.calls.first['title'], equals('Ring queued'));
      final List<RetraceNotification> log =
          container.read(notificationLogProvider);
      expect(log, hasLength(1));
      expect(log.first.route, equals('/devices/dev_1'));
      expect(log.first.title, equals('Ring queued'));
    });

    test('denied permission shows nothing and logs nothing', () async {
      final FakeNotificationPlatform platform = FakeNotificationPlatform();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          notificationPlatformProvider.overrideWithValue(platform),
          permissionServiceProvider.overrideWithValue(
            FakePermissionService(granted: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(notificationControllerProvider)
          .commandStatus(command: _command(), delivered: true);

      expect(platform.calls, isEmpty);
      expect(container.read(notificationLogProvider), isEmpty);
    });

    test('undelivered platform call is not logged', () async {
      final FakeNotificationPlatform platform =
          FakeNotificationPlatform(delivered: false);
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          notificationPlatformProvider.overrideWithValue(platform),
          permissionServiceProvider.overrideWithValue(
            FakePermissionService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(notificationControllerProvider)
          .evidenceStored(
            deviceId: 'dev_1',
            fileName: 'a.jpg',
            uploaded: false,
          );

      expect(platform.calls, hasLength(1));
      expect(container.read(notificationLogProvider), isEmpty);
    });

    test('contact wording promises queue, not owner delivery', () async {
      final FakeNotificationPlatform platform = FakeNotificationPlatform();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          notificationPlatformProvider.overrideWithValue(platform),
          permissionServiceProvider.overrideWithValue(
            FakePermissionService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(notificationControllerProvider)
          .contactSent(recoveryId: 'RT-1');

      expect(platform.calls.first['channel'],
          equals(RetraceChannel.recovery));
      expect(platform.calls.first['body'].toString(), contains('queued'));
      expect(platform.calls.first['body'].toString(),
          isNot(contains('owner has been notified')));
    });

    test('last-code warning fires only at exactly one remaining', () async {
      final FakeNotificationPlatform platform = FakeNotificationPlatform();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          notificationPlatformProvider.overrideWithValue(platform),
          permissionServiceProvider.overrideWithValue(
            FakePermissionService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final NotificationController controller =
          container.read(notificationControllerProvider);

      await controller.lastCodeWarning(remaining: 3);
      await controller.lastCodeWarning(remaining: 0);
      expect(platform.calls, isEmpty);

      await controller.lastCodeWarning(remaining: 1);
      expect(platform.calls, hasLength(1));
      expect(platform.calls.first['route'], equals('/pin/codes'));
    });
  });

  group('DeepLinkNotifier', () {
    test('cold-start link becomes pending route', () async {
      final FakeDeepLinkSource source = FakeDeepLinkSource(
        initialUri: Uri.parse('retrace://recover/RT-9'),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          deepLinkSourceProvider.overrideWithValue(source),
        ],
      );
      addTearDown(() {
        container.dispose();
        source.controller.close();
      });

      expect(container.read(deepLinkProvider), isNull);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(container.read(deepLinkProvider), equals('/lost/RT-9'));

      container.read(deepLinkProvider.notifier).consume();
      expect(container.read(deepLinkProvider), isNull);
    });

    test('stream link updates, unknown links ignored', () async {
      final FakeDeepLinkSource source = FakeDeepLinkSource();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          deepLinkSourceProvider.overrideWithValue(source),
        ],
      );
      addTearDown(() {
        container.dispose();
        source.controller.close();
      });
      container.read(deepLinkProvider);

      source.controller.add(Uri.parse('https://evil.com/x'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(container.read(deepLinkProvider), isNull);

      source.controller.add(Uri.parse('retrace://notifications'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        container.read(deepLinkProvider),
        equals('/notifications'),
      );
    });
  });
}
