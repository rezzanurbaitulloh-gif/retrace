import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/core/theme/retrace_typography.dart';
import 'package:retrace/features/map/map_components.dart';
import 'package:retrace/core/db/app_db.dart';
import 'package:retrace/providers.dart';

final historyFilterProvider = StateProvider<HistoryFilter>(
  (Ref ref) => HistoryFilter.all,
);

enum HistoryFilter { all, today, week, month }

/// Location history page (§19, §21). Honest empty state, real path from local DB.
class LocationHistoryPage extends ConsumerStatefulWidget {
  const LocationHistoryPage({super.key, this.deviceId});
  final String? deviceId;

  @override
  ConsumerState<LocationHistoryPage> createState() => _LocationHistoryPageState();
}

class _LocationHistoryPageState extends ConsumerState<LocationHistoryPage> {
  HistoryFilter _filter = HistoryFilter.all;
  DateTimeRange? _customRange;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<LocalLocation>> locations = widget.deviceId != null
        ? ref.watch(deviceLocationsProvider(widget.deviceId!))
        : ref.watch(allLocationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location History'),
        actions: [
          PopupMenuButton<HistoryFilter>(
            initialValue: _filter,
            onSelected: (HistoryFilter f) => setState(() => _filter = f),
            itemBuilder: (BuildContext context) => HistoryFilter.values
                .map((HistoryFilter f) => PopupMenuItem<HistoryFilter>(
                      value: f,
                      child: Text(_label(f)),
                    ))
                .toList(),
          ),
        ],
      ),
      body: switch (locations) {
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
        AsyncError(:final Object error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(RetraceSpacing.lg),
              child: Text('Unable to load history: ${error.toString().replaceFirst('Exception: ', '')}',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        AsyncData(:final List<LocalLocation> value) => _List(
            locations: _filterLocations(value, _filter, _customRange),
            deviceId: widget.deviceId,
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  static String _label(HistoryFilter f) => switch (f) {
        HistoryFilter.all => 'All time',
        HistoryFilter.today => 'Today',
        HistoryFilter.week => 'This week',
        HistoryFilter.month => 'This month',
      };

  static List<LocalLocation> _filterLocations(
    List<LocalLocation> locations,
    HistoryFilter filter,
    DateTimeRange? custom,
  ) {
    if (locations.isEmpty) return <LocalLocation>[];
    final DateTime now = DateTime.now();
    DateTime start;
    switch (filter) {
      case HistoryFilter.today:
        start = DateTime(now.year, now.month, now.day);
      case HistoryFilter.week:
        start = now.subtract(const Duration(days: 7));
      case HistoryFilter.month:
        start = DateTime(now.year, now.month - 1, now.day);
      case HistoryFilter.all:
      default:
        return locations;
    }
    if (custom != null) start = custom.start;
    return locations.where((LocalLocation l) => l.timestamp.isAfter(start)).toList();
  }
}

class _List extends ConsumerWidget {
  const _List({required this.locations, this.deviceId});
  final List<LocalLocation> locations;
  final String? deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    if (locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: RetraceSpacing.sm),
            Text('No location history', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Start tracking to see history here.', style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }
    final DateFormat fmt = DateFormat('MMM d, HH:mm');
    return ListView.separated(
      padding: const EdgeInsets.all(RetraceSpacing.md),
      itemCount: locations.length,
      separatorBuilder: (_, __) => const SizedBox(height: RetraceSpacing.sm),
      itemBuilder: (BuildContext context, int i) {
        final LocalLocation loc = locations[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: RetraceColors.primary.withValues(alpha: 0.15),
              child: Icon(loc.source == 'gps' ? Icons.gps_fixed : Icons.location_searching,
                  color: RetraceColors.primary, size: 20),
            ),
            title: Text('${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}'),
            subtitle: Text(
              '${fmt.format(loc.timestamp)}  •  ±${loc.accuracy.toStringAsFixed(0)}m  •  ${loc.source}',
            ),
            trailing: loc.isSynced
                ? const Icon(Icons.cloud_done, color: RetraceColors.success, size: 20)
                : const Icon(Icons.cloud_off, color: RetraceColors.warning, size: 20),
            onTap: () => _showMap(context, loc),
          ),
        );
      },
    );
  }

  void _showMap(BuildContext context, LocalLocation loc) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _MapSheet(location: loc),
    );
  }
}

class _MapSheet extends StatelessWidget {
  const _MapSheet({required this.location});
  final LocalLocation location;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final RetraceMapController mc = RetraceMapController();
    mc.currentLocation = LatLng(location.latitude, location.longitude);
    mc.currentAccuracy = location.accuracy;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            ListTile(
              title: Text('Location Detail', style: theme.textTheme.titleMedium),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: RetraceMap(
                controller: mc,
                showAccuracy: true,
                showPath: false,
                showFinder: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(RetraceSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Accuracy: ±${location.accuracy.toStringAsFixed(0)}m',
                      style: theme.textTheme.bodyMedium),
                  Text('Source: ${location.source}', style: theme.textTheme.bodySmall),
                  Text('Time: ${DateFormat('MMM d, yyyy HH:mm:ss').format(location.timestamp)}',
                      style: theme.textTheme.bodySmall),
                  Text('Synced: ${location.isSynced ? "Yes" : "Pending"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: location.isSynced ? RetraceColors.success : RetraceColors.warning)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final allLocationsProvider = StreamProvider<List<LocalLocation>>(
  (Ref ref) => ref.watch(appDbProvider).watchUnsynced().map((List<LocalLocation> l) => l),
);

final deviceLocationsProvider = StreamProvider.family<List<LocalLocation>, String>(
  (Ref ref, String deviceId) => ref.watch(appDbProvider).watchUnsynced().map(
        (List<LocalLocation> l) =>
            l.where((LocalLocation loc) => loc.deviceId == deviceId).toList(),
      ),
);