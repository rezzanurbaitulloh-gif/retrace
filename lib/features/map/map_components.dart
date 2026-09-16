import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/retrace_colors.dart';
import '../../core/theme/retrace_spacing.dart';
import '../../core/theme/retrace_typography.dart';

/// Main map widget (§19). Uses OSM tiles (no API key), supports:
/// current location, accuracy circle, path history, offline marker, finder location.
class RetraceMap extends StatefulWidget {
  const RetraceMap({
    super.key,
    required this.controller,
    this.showAccuracy = true,
    this.showPath = true,
    this.showFinder = true,
  });

  final RetraceMapController controller;
  final bool showAccuracy;
  final bool showPath;
  final bool showFinder;

  @override
  State<RetraceMap> createState() => _RetraceMapState();
}

class _RetraceMapState extends State<RetraceMap> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    widget.controller._attach(_mapController);
  }

  @override
  void dispose() {
    widget.controller._detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.controller.currentCenter ?? const LatLng(-7.9, 112.5),
        initialZoom: 15,
        minZoom: 3,
        maxZoom: 19,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.retrace.retrace',
        ),
        if (widget.showAccuracy && widget.controller.currentAccuracy != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: widget.controller.currentLocation!,
                radius: widget.controller.currentAccuracy!,
                color: RetraceColors.primary.withValues(alpha: 0.15),
                borderColor: RetraceColors.primary,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        if (widget.showPath && widget.controller.pathHistory.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.controller.pathHistory,
                color: RetraceColors.primary,
                strokeWidth: 3,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (widget.controller.currentLocation != null)
              Marker(
                point: widget.controller.currentLocation!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: RetraceColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.navigation, color: Colors.white, size: 20),
                ),
              ),
            if (widget.showFinder && widget.controller.finderLocation != null)
              Marker(
                point: widget.controller.finderLocation!,
                width: 36,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: RetraceColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.person_search, color: Colors.white, size: 18),
                ),
              ),
            if (widget.controller.offlineMarker != null)
              Marker(
                point: widget.controller.offlineMarker!,
                width: 36,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: RetraceColors.warning,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.cloud_off, color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Controller for map state — owned by the feature, not the widget.
class RetraceMapController {
  LatLng? currentLocation;
  double? currentAccuracy;
  List<LatLng> pathHistory = <LatLng>[];
  LatLng? finderLocation;
  LatLng? offlineMarker;
  LatLng get currentCenter =>
      currentLocation ?? pathHistory.lastOrNull ?? const LatLng(-7.9, 112.5);

  MapController _mapController = MapController();

  void _attach(MapController mc) => _mapController = mc;
  void _detach() => _mapController = MapController();

  void updateLocation(LatLng location, {double? accuracy}) {
    currentLocation = location;
    if (accuracy != null) currentAccuracy = accuracy;
    pathHistory.add(location);
    if (pathHistory.length > 500) pathHistory.removeAt(0);
  }

  void setFinderLocation(LatLng location) => finderLocation = location;
  void setOfflineMarker(LatLng location) => offlineMarker = location;
  void clearPath() => pathHistory.clear();
  void animateTo(LatLng location, {double zoom = 15}) =>
      _mapController.move(location, zoom);
}