import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Activity categories (§37). COMMAND + SYSTEM exist in the model from day
/// one so later phases never reshape stored events.
enum ActivityCategory { security, location, device, finder, command, system }

enum ActivityFilter { all, security, location, device, finder, command, system }

@immutable
final class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.category,
    required this.title,
    required this.timestamp,
    this.subtitle,
  });

  final String id;
  final ActivityCategory category;
  final String title;
  final String timestamp;
  final String? subtitle;
}

List<ActivityEvent> filterActivity(
  List<ActivityEvent> events,
  ActivityFilter filter,
) {
  if (filter == ActivityFilter.all) return events;
  return events
      .where(
        (ActivityEvent e) =>
            e.category.name == filter.name,
      )
      .toList();
}

abstract class ActivityRepository {
  Stream<List<ActivityEvent>> watchActivity();
}

/// Phase 2 local stub: honest empty timeline. Real event ledger (location,
/// commands, finder, system) streams from Supabase `activities` in Phase 4+.
final class LocalActivityRepository implements ActivityRepository {
  @override
  Stream<List<ActivityEvent>> watchActivity() =>
      Stream<List<ActivityEvent>>.value(const <ActivityEvent>[]);
}

final activityRepositoryProvider = Provider<ActivityRepository>(
  (Ref ref) => LocalActivityRepository(),
);

final activityStreamProvider = StreamProvider<List<ActivityEvent>>(
  (Ref ref) => ref.watch(activityRepositoryProvider).watchActivity(),
);
