import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:retrace/features/lost_mode/lost_mode.dart';
import 'package:retrace/features/notifications/notifications.dart';
import 'package:retrace/services/notification_platform.dart';
import 'package:retrace/services/permission_service.dart';

/// Incoming-link source. Abstracted so tests can feed links without the
/// platform plugin; production reads real OS links (cold start + stream).
abstract class DeepLinkSource {
  Future<Uri?> initial();
  Stream<Uri> links();
}

final class RealDeepLinkSource implements DeepLinkSource {
  RealDeepLinkSource([AppLinks? links]) : _links = links ?? AppLinks();

  final AppLinks _links;

  @override
  Future<Uri?> initial() async {
    try {
      return await _links.getInitialLink();
    } on Object {
      return null;
    }
  }

  @override
  Stream<Uri> links() {
    try {
      return _links.uriLinkStream;
    } on Object {
      return const Stream<Uri>.empty();
    }
  }
}

/// Pending in-app route from a tapped notification or incoming link.
/// The router consumes it exactly once (then it resets to null).
final class DeepLinkNotifier extends Notifier<String?> {
  @override
  String? build() {
    final DeepLinkSource source = ref.watch(deepLinkSourceProvider);
    source.initial().then((Uri? uri) {
      if (uri != null) _offer(uri);
    });
    final StreamSubscription<Uri> sub = source.links().listen(
      _offer,
      onError: (Object _) {},
    );
    ref.onDispose(() => unawaited(sub.cancel()));
    return null;
  }

  void _offer(Uri uri) {
    final String? route = parseDeepLink(uri);
    if (route != null) state = route;
  }

  /// Called by the notification tap path (payload is already a route).
  void offerRoute(String route) {
    state = route;
  }

  void consume() {
    state = null;
  }
}

/// Delivered-notification log (newest last; UI reverses). In-memory for the
/// session — a persisted history table is a later phase; the tray itself is
/// the durable surface until then.
final notificationLogProvider =
    StateProvider<List<RetraceNotification>>((Ref ref) => <RetraceNotification>[]);

/// High-level controller: permission gate → platform display → log.
/// Every method is fire-and-forget safe: failures degrade to log-only or
/// silent skip, never a crash, never a fake "sent".
class NotificationController {
  NotificationController(this._ref);

  final Ref _ref;

  NotificationPlatform get _platform =>
      _ref.read(notificationPlatformProvider);

  /// True when notifications may be shown. Desktop platforms have no
  /// permission model for local notifications, so an uncheckable state
  /// (missing plugin) counts as allowed — documented, not faked.
  Future<bool> ensurePermission() async {
    try {
      final PermissionState state = await _ref
          .read(permissionServiceProvider)
          .check(AppPermission.notifications);
      return state.isGranted;
    } on MissingPluginException {
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> _emit({
    required String key,
    required RetraceChannel channel,
    required String title,
    required String body,
    String? route,
  }) async {
    if (!await ensurePermission()) return;
    final int id = notificationIdFor(key);
    final bool delivered = await _platform.show(
      id: id,
      channel: channel,
      title: title,
      body: body,
      route: route,
    );
    if (!delivered) return;
    final List<RetraceNotification> log =
        _ref.read(notificationLogProvider);
    _ref.read(notificationLogProvider.notifier).state = <RetraceNotification>[
      ...log,
      RetraceNotification(
        id: id,
        channel: channel,
        title: title,
        body: body,
        route: route,
        createdAt: DateTime.now(),
      ),
    ];
  }

  /// Remote-command outcome (owner side). [delivered] = bytes reached the
  /// device/queue; false = still queued locally for sync.
  Future<void> commandStatus({
    required RemoteCommand command,
    required bool delivered,
  }) {
    final String label = command.type.label;
    return _emit(
      key: 'cmd_${command.id}',
      channel: RetraceChannel.commands,
      title: delivered ? '$label sent' : '$label queued',
      body: delivered
          ? 'The $label command was sent to the device.'
          : 'No connection — the $label command will send on sync.',
      route: '/devices/${command.deviceId}',
    );
  }

  /// Finder-side confirmation after contacting an owner. Honest wording:
  /// queued for the owner, not "owner notified" (no server round-trip).
  Future<void> contactSent({required String recoveryId}) {
    return _emit(
      key: 'contact_$recoveryId',
      channel: RetraceChannel.recovery,
      title: 'Message saved',
      body:
          'Your message for the owner is queued and syncs when possible.',
      route: '/finder/$recoveryId',
    );
  }

  /// Finder-side confirmation after sharing a sighting location.
  /// Same honesty contract as [contactSent]: queued, not delivered.
  Future<void> sightingReported({required String recoveryId}) {
    return _emit(
      key: 'sighting_$recoveryId',
      channel: RetraceChannel.recovery,
      title: 'Sighting shared',
      body:
          'Your location is queued for the owner and syncs when possible.',
      route: '/finder/$recoveryId',
    );
  }

  /// Evidence capture outcome (owner side).
  Future<void> evidenceStored({
    required String deviceId,
    required String fileName,
    required bool uploaded,
  }) {
    return _emit(
      key: 'ev_${deviceId}_$fileName',
      channel: RetraceChannel.commands,
      title: uploaded ? 'Evidence uploaded' : 'Evidence queued',
      body: uploaded
          ? '$fileName reached secure storage.'
          : '$fileName is on-device and retries on sync.',
      route: '/devices/$deviceId/evidence',
    );
  }

  /// Safety warning when the last PIN recovery code is all that remains.
  Future<void> lastCodeWarning({required int remaining}) {
    if (remaining != 1) return Future<void>.value();
    return _emit(
      key: 'recovery_codes_low',
      channel: RetraceChannel.system,
      title: 'Last recovery code',
      body:
          'Only one PIN recovery code remains. Generate a fresh batch in PIN settings.',
      route: '/pin/codes',
    );
  }
}

/// Providers.
final deepLinkSourceProvider = Provider<DeepLinkSource>(
  (Ref ref) => RealDeepLinkSource(),
);

final deepLinkProvider =
    NotifierProvider<DeepLinkNotifier, String?>(DeepLinkNotifier.new);

final notificationControllerProvider = Provider<NotificationController>(
  (Ref ref) => NotificationController(ref),
);

/// Startup wiring: init platform, route taps + cold-launch links into
/// [deepLinkProvider]. Watched by the router for refresh.
final notificationInitProvider = FutureProvider<void>((Ref ref) async {
  final NotificationPlatform platform =
      ref.watch(notificationPlatformProvider);
  final DeepLinkNotifier links = ref.watch(deepLinkProvider.notifier);
  final bool ok = await platform.init((String? route) async {
    if (route != null && route.isNotEmpty) links.offerRoute(route);
  });
  if (!ok) {
    debugPrint('[Notifications] platform unavailable — log-only mode.');
    return;
  }
  final String? launch = await platform.launchRoute();
  if (launch != null && launch.isNotEmpty) links.offerRoute(launch);
});
