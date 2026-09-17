import 'package:flutter/foundation.dart';

/// Notification contract (§Phase 9). Pure Dart — channels, payload model,
/// and deep-link parsing. Platform display lives in the notification
/// service; this file owns what a notification *means* so UI, service,
/// and tests agree.
///
/// Push (FCM) is deliberately out of scope: delivery here is local-only,
/// triggered by on-device events (command status, finder activity).
/// Anything requiring a server round-trip says so in its copy.
enum RetraceChannel { commands, recovery, system }

extension RetraceChannelInfo on RetraceChannel {
  /// Stable Android channel id — never rename once shipped.
  String get id => switch (this) {
        RetraceChannel.commands => 'retrace_commands',
        RetraceChannel.recovery => 'retrace_recovery',
        RetraceChannel.system => 'retrace_system',
      };

  String get name => switch (this) {
        RetraceChannel.commands => 'Device commands',
        RetraceChannel.recovery => 'Recovery alerts',
        RetraceChannel.system => 'System',
      };

  String get description => switch (this) {
        RetraceChannel.commands =>
          'Status of remote commands: ring, lock, locate, and evidence capture.',
        RetraceChannel.recovery =>
          'Finder sightings and contact attempts on lost devices.',
        RetraceChannel.system =>
          'Sync, protection score, and app health notices.',
      };
}

/// A shown (or logged) notification. [route] is an in-app deep link —
/// tapping opens it; null means informational with nowhere to go.
@immutable
final class RetraceNotification {
  const RetraceNotification({
    required this.id,
    required this.channel,
    required this.title,
    required this.body,
    this.route,
    required this.createdAt,
  });

  final int id;
  final RetraceChannel channel;
  final String title;
  final String body;
  final String? route;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'channel': channel.name,
        'title': title,
        'body': body,
        'route': route,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RetraceNotification.fromJson(Map<String, dynamic> json) {
    final Object? raw = json['channel'];
    return RetraceNotification(
      id: json['id'] as int,
      channel: RetraceChannel.values.firstWhere(
        (RetraceChannel c) => c.name == raw,
        orElse: () => RetraceChannel.system,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      route: json['route'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Stable positive int for a notification key — same key replaces the
/// previous notification instead of stacking (e.g. command progress).
int notificationIdFor(String key) => key.hashCode & 0x7fffffff;

/// Maps an incoming link to an in-app route, or null when unknown.
///
/// Accepted:
/// - `retrace://device/<id>` → `/devices/<id>`
/// - `retrace://recover/<recoveryId>` → `/lost/<recoveryId>`
/// - `retrace://finder/<recoveryId>` → `/finder/<recoveryId>`
/// - `retrace://evidence/<deviceId>` → `/devices/<deviceId>/evidence`
/// - `retrace://contacts` → `/trusted-contacts`
/// - `retrace://notifications` → `/notifications`
/// - `https://retrace.app/recover/<recoveryId>` → `/lost/<recoveryId>`
/// - `https://retrace.app/device/<id>` → `/devices/<id>`
String? parseDeepLink(Uri uri) {
  if (uri.scheme == 'retrace') {
    final List<String> seg = uri.pathSegments;
    switch (uri.host) {
      case 'device':
        if (seg.length == 1 && seg.first.isNotEmpty) {
          return '/devices/${seg.first}';
        }
      case 'recover':
        if (seg.length == 1 && seg.first.isNotEmpty) {
          return '/lost/${seg.first}';
        }
      case 'finder':
        if (seg.length == 1 && seg.first.isNotEmpty) {
          return '/finder/${seg.first}';
        }
      case 'evidence':
        if (seg.length == 1 && seg.first.isNotEmpty) {
          return '/devices/${seg.first}/evidence';
        }
      case 'contacts':
        if (seg.isEmpty) return '/trusted-contacts';
      case 'notifications':
        if (seg.isEmpty) return '/notifications';
    }
    return null;
  }
  if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host == 'retrace.app') {
    final List<String> seg = uri.pathSegments;
    if (seg.length == 2 && seg[0] == 'recover' && seg[1].isNotEmpty) {
      return '/lost/${seg[1]}';
    }
    if (seg.length == 2 && seg[0] == 'device' && seg[1].isNotEmpty) {
      return '/devices/${seg[1]}';
    }
  }
  return null;
}
