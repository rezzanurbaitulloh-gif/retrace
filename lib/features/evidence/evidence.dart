import 'package:flutter/foundation.dart';

/// Evidence models (§33-34). Pure Dart — no platform imports, fully unit-testable.
/// Capture/upload lives in [EvidenceService]/[EvidenceRepository]; this file
/// owns the data contract + validation limits so UI, repo, and tests agree.
enum EvidenceType { photo, document }

extension EvidenceTypeLabel on EvidenceType {
  String get title => switch (this) {
        EvidenceType.photo => 'Photo',
        EvidenceType.document => 'Document',
      };

  /// Extensions accepted per type (lowercase, no dot).
  List<String> get extensions => switch (this) {
        EvidenceType.photo => const <String>['jpg', 'jpeg', 'png', 'heic'],
        EvidenceType.document => const <String>['pdf'],
      };
}

/// Hard limits (§34). Single source of truth — UI copy, repo validation,
/// and tests all read these constants.
const int kMaxEvidenceBytes = 10 * 1024 * 1024; // 10 MB
const String kMaxEvidenceLabel = '10 MB';

/// Metadata attached to every evidence item.
@immutable
final class EvidenceMetadata {
  const EvidenceMetadata({
    required this.id,
    required this.deviceId,
    this.recoveryId,
    required this.capturedAt,
    this.latitude,
    this.longitude,
    this.caption,
    this.type = EvidenceType.photo,
  });

  final String id;
  final String deviceId;
  final String? recoveryId;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
  final String? caption;
  final EvidenceType type;

  bool get hasLocation => latitude != null && longitude != null;

  /// Standard `??` semantics: passing null keeps the existing value.
  /// Use [clearLocation] to wipe both coordinates at once — clearing one
  /// without the other would leave a half-located item, which [hasLocation]
  /// treats as unlocated anyway.
  EvidenceMetadata copyWith({
    String? id,
    String? deviceId,
    String? recoveryId,
    DateTime? capturedAt,
    double? latitude,
    double? longitude,
    bool clearLocation = false,
    String? caption,
    EvidenceType? type,
  }) {
    return EvidenceMetadata(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      recoveryId: recoveryId ?? this.recoveryId,
      capturedAt: capturedAt ?? this.capturedAt,
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
      caption: caption ?? this.caption,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'deviceId': deviceId,
        'recoveryId': recoveryId,
        'capturedAt': capturedAt.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'caption': caption,
        'type': type.name,
      };

  factory EvidenceMetadata.fromJson(Map<String, dynamic> json) {
    final Object? rawType = json['type'];
    return EvidenceMetadata(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      recoveryId: json['recoveryId'] as String?,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      caption: json['caption'] as String?,
      type: rawType == EvidenceType.document.name
          ? EvidenceType.document
          : EvidenceType.photo,
    );
  }
}

/// Stored evidence item: metadata + local path + remote sync state.
@immutable
final class EvidenceItem {
  const EvidenceItem({
    required this.metadata,
    required this.localPath,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.remotePath,
    this.uploaded = false,
  });

  final EvidenceMetadata metadata;
  final String localPath;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String? remotePath;
  final bool uploaded;

  String get id => metadata.id;

  EvidenceItem copyWith({
    EvidenceMetadata? metadata,
    String? localPath,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    String? remotePath,
    bool? uploaded,
  }) {
    return EvidenceItem(
      metadata: metadata ?? this.metadata,
      localPath: localPath ?? this.localPath,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      remotePath: remotePath ?? this.remotePath,
      uploaded: uploaded ?? this.uploaded,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'metadata': metadata.toJson(),
        'localPath': localPath,
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'remotePath': remotePath,
        'uploaded': uploaded,
      };

  factory EvidenceItem.fromJson(Map<String, dynamic> json) => EvidenceItem(
        metadata: EvidenceMetadata.fromJson(
          Map<String, dynamic>.from(json['metadata'] as Map),
        ),
        localPath: json['localPath'] as String,
        fileName: json['fileName'] as String,
        mimeType: json['mimeType'] as String,
        sizeBytes: json['sizeBytes'] as int,
        remotePath: json['remotePath'] as String?,
        uploaded: json['uploaded'] as bool? ?? false,
      );
}

/// Validation outcome — [reason] is a user-facing string, never an exception.
@immutable
final class EvidenceValidation {
  const EvidenceValidation.ok() : ok = true, reason = null;
  const EvidenceValidation.fail(this.reason) : ok = false;

  final bool ok;
  final String? reason;
}

/// Pure file validation (§34 limits). No I/O — caller supplies name + size.
EvidenceValidation validateEvidenceFile({
  required String fileName,
  required int sizeBytes,
  EvidenceType type = EvidenceType.photo,
}) {
  if (fileName.trim().isEmpty) {
    return const EvidenceValidation.fail('File name is missing.');
  }
  final String ext = extensionOf(fileName);
  if (ext.isEmpty) {
    return const EvidenceValidation.fail(
      'File has no extension. Use JPG, PNG, or HEIC.',
    );
  }
  if (!type.extensions.contains(ext)) {
    return EvidenceValidation.fail(
      'Unsupported type .$ext. Allowed: ${type.extensions.map((String e) => '.$e').join(', ')}.',
    );
  }
  if (sizeBytes <= 0) {
    return const EvidenceValidation.fail('File is empty.');
  }
  if (sizeBytes > kMaxEvidenceBytes) {
    return const EvidenceValidation.fail(
      'File exceeds $kMaxEvidenceLabel. Pick a smaller photo.',
    );
  }
  return const EvidenceValidation.ok();
}

/// Lowercase extension without dot; '' when none.
String extensionOf(String fileName) {
  final String name = fileName.split('/').last.split('\\').last;
  final int dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

/// Best-effort MIME for supported extensions.
String mimeOf(String fileName) => switch (extensionOf(fileName)) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'heic' => 'image/heic',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };

/// Deterministic Supabase Storage object path:
/// `evidence/<device>/<id>.<ext>`.
String buildStoragePath({
  required String deviceId,
  required String evidenceId,
  required String fileName,
}) {
  final String safeDevice = deviceId.trim().isEmpty ? 'unknown' : deviceId.trim();
  final String ext = extensionOf(fileName);
  final String suffix = ext.isEmpty ? '' : '.$ext';
  return 'evidence/$safeDevice/$evidenceId$suffix';
}
