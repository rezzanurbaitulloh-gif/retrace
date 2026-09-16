import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/features/devices/devices_repository.dart';
import 'package:retrace/features/map/map_components.dart';
import 'package:retrace/providers.dart';
import 'package:retrace/services/location_engine.dart';

/// Live map page (§18, §19). Real OSM tiles, accuracy circle, path, finder marker.
/// No fake GPS — shows "Unavailable" if location not available.
class LiveMapPage extends ConsumerStatefulWidget {
  const LiveMapPage({super.key});

  @override
  ConsumerState<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends ConsumerState<LiveMapPage> {
  late final LocationEngine _engine;
  late final RetraceMapController _mapController;
  StreamSubscription<LocationPoint>? _locSub;
  StreamSubscription<LocationEngineState>? _stateSub;
  LocationEngineState _engineState = LocationEngineState.initial;
  LocationPoint? _lastPoint;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _engine = ref.read(locationEngineProvider);
    _mapController = ref.read(mapControllerProvider);
    _stateSub = _engine.stateStream.listen((LocationEngineState s) {
      if (mounted) setState(() => _engineState = s);
    });
  }

  @override
  void dispose() {
    _locSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      await _engine.stop();
      _locSub?.cancel();
      setState(() => _isTracking = false);
    } else {
      final String? deviceId = ref.read(devicesStreamProvider).valueOrNull?.firstOrNull?.id;
      if (deviceId == null) return;
      await _engine.start(deviceId: deviceId, foreground: true);
      _locSub?.cancel();
      _locSub = _engine.locationStream.listen((LocationPoint pt) {
        if (!mounted) return;
        _lastPoint = pt;
        ref.read(mapControllerProvider).updateLocation(
          LatLng(pt.latitude, pt.longitude),
          accuracy: pt.accuracy,
        );
        setState(() {});
      });
      setState(() => _isTracking = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final LocationPoint? pt = _lastPoint;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location'),
        actions: [
          IconButton(
            tooltip: _isTracking ? 'Stop tracking' : 'Start tracking',
            onPressed: _toggleTracking,
            icon: Icon(_isTracking ? Icons.stop_circle : Icons.play_circle),
          ),
          const SizedBox(width: RetraceSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          _StatusBar(
            engineState: _engineState,
            point: pt,
            isTracking: _isTracking,
          ),
          Expanded(
            child: RetraceMap(
              controller: ref.read(mapControllerProvider),
              showAccuracy: true,
              showPath: true,
              showFinder: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.engineState,
    required this.point,
    required this.isTracking,
  });

  final LocationEngineState engineState;
  final LocationPoint? point;
  final bool isTracking;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    Color statusColor;
    String statusText;
    switch (engineState) {
      case LocationEngineState.running:
        statusColor = RetraceColors.success;
        statusText = isTracking ? 'TRACKING' : 'READY';
      case LocationEngineState.permissionDenied:
        statusColor = RetraceColors.danger;
        statusText = 'PERMISSION DENIED';
      case LocationEngineState.permissionLimited:
        statusColor = RetraceColors.warning;
        statusText = 'LIMITED (foreground only)';
      case LocationEngineState.error:
        statusColor = RetraceColors.danger;
        statusText = 'GPS ERROR';
      default:
        statusColor = RetraceColors.warning;
        statusText = engineState.name.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.all(RetraceSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: RetraceSpacing.sm),
          Text(statusText, style: theme.textTheme.labelLarge?.copyWith(color: statusColor)),
          const Spacer(),
          if (point != null) ...[
            Text('±${point!.accuracy.toStringAsFixed(0)}m',
                style: theme.textTheme.bodySmall),
            const SizedBox(width: RetraceSpacing.sm),
            Text('${point!.latitude.toStringAsFixed(5)}, ${point!.longitude.toStringAsFixed(5)}',
                style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}