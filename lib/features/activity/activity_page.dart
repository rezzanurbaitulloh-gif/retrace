import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/design_system/components/retrace_lists.dart';
import 'package:retrace/design_system/components/retrace_states.dart';
import 'package:retrace/features/activity/activity_repository.dart';

final activityFilterProvider =
    StateProvider<ActivityFilter>((Ref ref) => ActivityFilter.all);

/// Event ledger shell (§37): All / Security / Location / Device / Finder.
/// Real events stream from Supabase `activities` in Phase 4+; until then the
/// timeline honestly reports empty — never sample events.
class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ActivityFilter filter = ref.watch(activityFilterProvider);
    final AsyncValue<List<ActivityEvent>> events =
        ref.watch(activityStreamProvider);
    return DefaultTabController(
      length: ActivityFilter.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            onTap: (int i) => ref
                .read(activityFilterProvider.notifier)
                .state = ActivityFilter.values[i],
            tabs: ActivityFilter.values
                .map((ActivityFilter f) => Tab(text: _label(f)))
                .toList(),
          ),
        ),
        body: switch (events) {
          AsyncLoading() =>
            const LoadingState(message: 'Loading activity…'),
          AsyncError(:final Object error) => ErrorState(
              message:
                  'Unable to load activity: ${error.toString().replaceFirst('Exception: ', '')}',
              onRetry: () =>
                  ref.invalidate(activityStreamProvider),
            ),
          AsyncData(:final List<ActivityEvent> value) =>
            _Timeline(events: filterActivity(value, filter)),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  static String _label(ActivityFilter f) => switch (f) {
        ActivityFilter.all => 'All',
        ActivityFilter.security => 'Security',
        ActivityFilter.location => 'Location',
        ActivityFilter.device => 'Device',
        ActivityFilter.finder => 'Finder',
        ActivityFilter.command => 'Command',
        ActivityFilter.system => 'System',
      };
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events});

  final List<ActivityEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const EmptyState(
        title: 'No activity yet',
        message: 'Your device events will appear here.',
        icon: Icons.timeline_outlined,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(RetraceSpacing.md),
      itemCount: events.length,
      // ignore: unnecessary_underscores
      separatorBuilder: (_, __) =>
          const SizedBox(height: RetraceSpacing.sm),
      itemBuilder: (BuildContext context, int i) {
        final ActivityEvent e = events[i];
        return ActivityItem(
          icon: _icon(e.category),
          title: e.title,
          subtitle: e.subtitle,
          timestamp: e.timestamp,
        );
      },
    );
  }

  static IconData _icon(ActivityCategory c) => switch (c) {
        ActivityCategory.security => Icons.shield_outlined,
        ActivityCategory.location => Icons.location_on_outlined,
        ActivityCategory.device => Icons.smartphone_outlined,
        ActivityCategory.finder => Icons.qr_code_outlined,
        ActivityCategory.command => Icons.terminal_outlined,
        ActivityCategory.system => Icons.settings_outlined,
      };
}
