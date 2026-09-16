import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:retrace/core/db/app_db.dart';
import 'package:retrace/features/evidence/evidence.dart';
import 'package:retrace/providers.dart';
import 'package:retrace/services/evidence_service.dart';

/// Local evidence persistence + upload queue (§33-34).
class EvidenceLocalRepository {
  EvidenceLocalRepository(this._db);

  final AppDb _db;

  final List<EvidenceItem> _items = <EvidenceItem>[];

  Future<void> upsertItem(EvidenceItem item) async {
    final int idx = _items.indexWhere((EvidenceItem e) => e.id == item.id);
    if (idx >= 0) {
      _items[idx] = item;
    } else {
      _items.add(item);
    }
    await _db.enqueueCommand(
      PendingCommand(
        id: 'evidence_${item.id}',
        deviceId: item.metadata.deviceId,
        type: 'EVIDENCE_UPLOAD',
        status: item.uploaded ? 'SYNCED' : 'PENDING',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<EvidenceItem>> listByDevice(String deviceId) async {
    final List<EvidenceItem> out = _items
        .where((EvidenceItem e) => e.metadata.deviceId == deviceId)
        .toList()
      ..sort((EvidenceItem a, EvidenceItem b) =>
          b.metadata.capturedAt.compareTo(a.metadata.capturedAt));
    return List<EvidenceItem>.unmodifiable(out);
  }

  Future<EvidenceItem?> getById(String id) async {
    for (final EvidenceItem e in _items) {
      if (e.id == id) return e;
    }
    return null;
  }
}

/// Remote evidence API.
abstract class EvidenceRemoteRepository {
  Future<String> uploadBytes({
    required String storagePath,
    required Uint8List bytes,
    required String mimeType,
  });
  Future<List<EvidenceItem>> listByDevice(String deviceId);
}

/// Production implementation — Supabase Storage bucket `evidence`.
class SupabaseEvidenceRemoteRepository implements EvidenceRemoteRepository {
  SupabaseEvidenceRemoteRepository(this._appDb);

  final AppDb _appDb;

  @override
  Future<String> uploadBytes({
    required String storagePath,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final SupabaseClient client = Supabase.instance.client;
    await client.storage.from('evidence').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );
    return client.storage.from('evidence').getPublicUrl(storagePath);
  }

  @override
  Future<List<EvidenceItem>> listByDevice(String deviceId) {
    // Server-side listing arrives with the evidence table (Phase 7+);
    // local queue is the source of truth until then — never fake rows.
    return Future<List<EvidenceItem>>.value(<EvidenceItem>[]);
  }
}

/// Offline fallback — queues locally, reports not-uploaded honestly.
class LocalEvidenceRepository implements EvidenceRemoteRepository {
  LocalEvidenceRepository(this._db);

  final AppDb _db;

  @override
  Future<String> uploadBytes({
    required String storagePath,
    required Uint8List bytes,
    required String mimeType,
  }) {
    throw Exception('Offline — evidence queued locally and retries on sync.');
  }

  @override
  Future<List<EvidenceItem>> listByDevice(String deviceId) {
    return Future<List<EvidenceItem>>.value(<EvidenceItem>[]);
  }
}

/// High-level controller: capture record → queue → upload attempt.
class EvidenceController {
  EvidenceController(this._local, this._remote, this._capture);

  final EvidenceLocalRepository _local;
  final EvidenceRemoteRepository _remote;
  final EvidenceCaptureService _capture;

  Future<List<EvidenceItem>> listByDevice(String deviceId) async {
    try {
      final List<EvidenceItem> remote = await _remote.listByDevice(deviceId);
      if (remote.isNotEmpty) return remote;
    } on Object catch (_) {
      // Fall through to local queue — offline is normal, not an error.
    }
    return _local.listByDevice(deviceId);
  }

  /// Pick a photo, validate against §34 limits, queue locally, then attempt
  /// upload. Returns the item as stored — [EvidenceItem.uploaded] tells the
  /// UI whether the bytes reached Supabase or are queued for retry.
  Future<EvidenceItem> capturePhoto({
    required String deviceId,
    required ImageSource source,
    String? recoveryId,
    String? caption,
    double? latitude,
    double? longitude,
  }) async {
    final XFile? picked = await _capture.pickImage(source);
    if (picked == null) {
      throw const EvidenceCancelled();
    }
    final Uint8List bytes = await picked.readAsBytes();
    final String fileName = picked.name.isEmpty
        ? 'evidence_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : picked.name;
    final EvidenceValidation validation = validateEvidenceFile(
      fileName: fileName,
      sizeBytes: bytes.length,
    );
    if (!validation.ok) {
      throw EvidenceRejected(validation.reason ?? 'File rejected.');
    }

    final String evidenceId = 'ev_${DateTime.now().millisecondsSinceEpoch}';
    final EvidenceItem queued = EvidenceItem(
      metadata: EvidenceMetadata(
        id: evidenceId,
        deviceId: deviceId,
        recoveryId: recoveryId,
        capturedAt: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
        caption: caption?.trim().isEmpty ?? true ? null : caption!.trim(),
      ),
      localPath: picked.path,
      fileName: fileName,
      mimeType: mimeOf(fileName),
      sizeBytes: bytes.length,
    );
    await _local.upsertItem(queued);

    try {
      final String storagePath = buildStoragePath(
        deviceId: deviceId,
        evidenceId: evidenceId,
        fileName: fileName,
      );
      await _remote.uploadBytes(
        storagePath: storagePath,
        bytes: bytes,
        mimeType: queued.mimeType,
      );
      final EvidenceItem uploaded =
          queued.copyWith(remotePath: storagePath, uploaded: true);
      await _local.upsertItem(uploaded);
      return uploaded;
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('[Evidence] upload deferred, queued locally: $e');
      }
      return queued;
    }
  }

  /// Retry a queued upload with fresh bytes supplied by the caller.
  Future<EvidenceItem> retryUpload(EvidenceItem item, Uint8List bytes) async {
    final String storagePath = item.remotePath ??
        buildStoragePath(
          deviceId: item.metadata.deviceId,
          evidenceId: item.id,
          fileName: item.fileName,
        );
    await _remote.uploadBytes(
      storagePath: storagePath,
      bytes: bytes,
      mimeType: item.mimeType,
    );
    final EvidenceItem uploaded =
        item.copyWith(remotePath: storagePath, uploaded: true);
    await _local.upsertItem(uploaded);
    return uploaded;
  }
}

/// User backed out of the picker — not an error, UI just dismisses.
final class EvidenceCancelled implements Exception {
  const EvidenceCancelled();
  @override
  String toString() => 'Evidence capture cancelled.';
}

/// File failed §34 limits — [message] is user-facing.
final class EvidenceRejected implements Exception {
  const EvidenceRejected(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Providers.
final evidenceLocalRepositoryProvider = Provider<EvidenceLocalRepository>(
  (Ref ref) => EvidenceLocalRepository(ref.watch(appDbProvider)),
);

final evidenceRemoteRepositoryProvider = Provider<EvidenceRemoteRepository>(
  (Ref ref) => SupabaseEvidenceRemoteRepository(ref.watch(appDbProvider)),
);

final evidenceControllerProvider = Provider<EvidenceController>(
  (Ref ref) => EvidenceController(
    ref.watch(evidenceLocalRepositoryProvider),
    ref.watch(evidenceRemoteRepositoryProvider),
    ref.watch(evidenceCaptureServiceProvider),
  ),
);
