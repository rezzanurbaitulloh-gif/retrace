import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/design_system/components/retrace_states.dart';
import 'package:retrace/features/notifications/notifications.dart';
import 'package:retrace/features/notifications/notifications_controller.dart';

/// Delivered-notification log (§Phase 9). Newest first; tapping an entry
/// follows its route when it has one. Route: /notifications.
/// Delivery here is local-only — remote push alerts need the server leg
/// and are stated as such, never implied.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<RetraceNotification> log =
        ref.watch(notificationLogProvider);
    final List<RetraceNotification> items = log.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_outlined,
              title: 'No notifications yet',
              message:
                  'Command updates and recovery alerts appear here as '
                  'they happen on this device.',
            )
          : ListView(
              padding: const EdgeInsets.all(RetraceSpacing.md),
              children: <Widget>[
                ...items.map(
                  (RetraceNotification n) => _Tile(item: n),
                ),
                const SizedBox(height: RetraceSpacing.sm),
                Text(
                  'Local notifications only. Remote push alerts arrive '
                  'with the server leg.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.item});

  final RetraceNotification item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: RetraceSpacing.sm),
      child: ListTile(
        leading: Icon(_icon(item.channel),
            color: theme.colorScheme.primary),
        title: Text(item.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.body,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              '${item.channel.name} · ${_time(item.createdAt)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: item.route == null
            ? null
            : const Icon(Icons.chevron_right_outlined),
        onTap: item.route == null
            ? null
            : () => context.push(item.route!),
      ),
    );
  }

  static IconData _icon(RetraceChannel channel) => switch (channel) {
        RetraceChannel.commands => Icons.settings_remote_outlined,
        RetraceChannel.recovery => Icons.volunteer_activism_outlined,
        RetraceChannel.system => Icons.info_outlined,
      };

  static String _time(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}';
  }
}
