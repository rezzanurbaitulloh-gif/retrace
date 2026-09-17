import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/features/notifications/notifications.dart';

/// Thin wrapper around the platform notification plugin (§Phase 9).
/// Returns `delivered=false` instead of throwing when the platform cannot
/// display — the controller logs only what was actually delivered.
abstract class NotificationPlatform {
  /// Registers channels and the tap callback. [onTap] receives the
  /// notification's route payload (null when informational).
  Future<bool> init(Future<void> Function(String? route) onTap);

  Future<bool> show({
    required int id,
    required RetraceChannel channel,
    required String title,
    required String body,
    String? route,
  });

  /// Route that cold-launched the app via a notification tap, if any.
  Future<String?> launchRoute();
}

final class RealNotificationPlatform implements NotificationPlatform {
  RealNotificationPlatform([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<bool> init(Future<void> Function(String? route) onTap) async {
    try {
      final bool? ok = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
          macOS: DarwinInitializationSettings(),
          linux: LinuxInitializationSettings(
            defaultActionName: 'Open',
          ),
        ),
        onDidReceiveNotificationResponse:
            (NotificationResponse response) => onTap(response.payload),
      );
      if (ok != true) return false;
      final AndroidFlutterLocalNotificationsPlugin? android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      for (final RetraceChannel c in RetraceChannel.values) {
        await android?.createNotificationChannel(
          AndroidNotificationChannel(
            c.id,
            c.name,
            description: c.description,
            importance: Importance.high,
          ),
        );
      }
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> show({
    required int id,
    required RetraceChannel channel,
    required String title,
    required String body,
    String? route,
  }) async {
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
          linux: const LinuxNotificationDetails(),
        ),
        payload: route,
      );
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<String?> launchRoute() async {
    try {
      final NotificationAppLaunchDetails? details =
          await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        final String? payload = details?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) return payload;
      }
      return null;
    } on Object {
      return null;
    }
  }
}

final notificationPlatformProvider = Provider<NotificationPlatform>(
  (Ref ref) => RealNotificationPlatform(),
);
