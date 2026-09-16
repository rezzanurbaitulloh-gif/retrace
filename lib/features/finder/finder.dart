import 'package:flutter/foundation.dart';
import 'package:retrace/features/lost_mode/lost_mode.dart';

export 'package:retrace/features/lost_mode/lost_mode.dart' show LostScreenData;

/// Finder session data (§31).
@immutable
final class FinderSession {
  const FinderSession({
    required this.id,
    required this.recoveryId,
    required this.deviceId,
    required this.createdAt,
    this.finderLocation,
    this.contactSent = false,
  });

  final String id;
  final String recoveryId;
  final String deviceId;
  final DateTime createdAt;
  final FinderLocation? finderLocation;
  final bool contactSent;
}

/// Finder sighting (§32).
@immutable
final class FinderSighting {
  const FinderSighting({
    required this.id,
    required this.sessionId,
    required this.location,
    required this.reportedAt,
  });

  final String id;
  final String sessionId;
  final FinderLocation location;
  final DateTime reportedAt;
}

/// Finder location data (§32).
@immutable
final class FinderLocation {
  const FinderLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.address,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String? address;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
        'address': address,
      };

  factory FinderLocation.fromJson(Map<String, dynamic> json) => FinderLocation(
        latitude: json['latitude'] as double,
        longitude: json['longitude'] as double,
        accuracy: json['accuracy'] as double,
        timestamp: DateTime.parse(json['timestamp'] as String),
        address: json['address'] as String?,
      );
}

/// Finder contact form data (§31).
@immutable
final class ContactOwnerForm {
  const ContactOwnerForm({
    required this.name,
    required this.contact,
    this.message,
  });

  final String name;
  final String contact;
  final String? message;

  bool get isValid =>
      name.trim().isNotEmpty &&
      contact.trim().isNotEmpty &&
      (message == null || message!.trim().isNotEmpty);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name.trim(),
        'contact': contact.trim(),
        'message': message?.trim() ?? '',
      };
}