// Location Engine — provider-agnostic, offline-first, adaptive
// Covers PRD 20-29: GPS/NETWORK/CELLULAR/NEARBY/FINDER, confidence, adaptive tracking, offline queue
import 'dart:async';
class LocationPoint {
  final double lat, lng; final double? accuracy, altitude, speed, heading;
  final DateTime deviceTimestamp; final String source; final String confidence; final String syncStatus;
  LocationPoint({required this.lat, required this.lng, this.accuracy, this.altitude, this.speed, this.heading, required this.deviceTimestamp, this.source='UNKNOWN', this.confidence='LOW', this.syncStatus='PENDING'});
}
abstract class LocationProvider { Future<LocationPoint?> getCurrent(); Stream<LocationPoint> watch(); }
class AdaptiveProfile {
  static Duration interval({required bool moving, required bool lost, required double battery}) {
    if (lost && battery>20) return const Duration(seconds: 10);
    if (lost && battery<=20) return const Duration(seconds: 30);
    if (moving) return const Duration(seconds: 15);
    return const Duration(seconds: 60);
  }
}
class OfflineQueue {
  final List<LocationPoint> _queue=[];
  void enqueue(LocationPoint p){ if(_queue.length<1000) _queue.add(p); }
  List<LocationPoint> drain(){ final c=List<LocationPoint>.from(_queue); _queue.clear(); return c; }
  int get length => _queue.length;
}
