import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/core/db/app_db.dart';
import 'package:retrace/features/finder/finder.dart';
import 'package:retrace/providers.dart';

/// Local Finder persistence + queue.
class FinderLocalRepository {
  FinderLocalRepository(this._db);

  final AppDb _db;

  Future<void> upsertSession(FinderSession session) async {
    // Phase 6: in-memory placeholder, Phase 7+ will add Drift table
  }

  Future<FinderSession?> getSessionByRecoveryId(String recoveryId) async {
    return null; // Phase 7+ implementation
  }

  Future<void> upsertSighting(FinderSighting sighting) async {
    // Phase 6: in-memory placeholder
  }
}

/// Remote Finder API.
abstract class FinderRemoteRepository {
  Future<FinderSession> startSession(String recoveryId, String deviceId);
  Future<LostScreenData> getRecoveryData(String recoveryId);
  Future<FinderSession> updateLocation(String sessionId, FinderLocation location);
  Future<FinderSighting> reportSighting(String sessionId, FinderLocation location);
  Future<void> sendContact(String sessionId, ContactOwnerForm form);
}

/// Production implementation - calls Supabase.
class SupabaseFinderRemoteRepository implements FinderRemoteRepository {
  SupabaseFinderRemoteRepository(this._appDb);

  final AppDb _appDb;

  @override
  Future<FinderSession> startSession(String recoveryId, String deviceId) async {
    // TODO: Call Supabase RPC / edge function
    return FinderSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      recoveryId: recoveryId,
      deviceId: deviceId,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<LostScreenData> getRecoveryData(String recoveryId) async {
    // This is used by the Lost Screen page (Phase 5)
    return LostScreenData(
      recoveryId: recoveryId,
      message: 'If you\'ve found this device, please help return it.',
      contactUrl: 'https://retrace.app/recover/$recoveryId',
      qrData: 'https://retrace.app/recover/$recoveryId',
    );
  }

  @override
  Future<FinderSession> updateLocation(String sessionId, FinderLocation location) async {
    // TODO: Call Supabase to update location
    return FinderSession(
      id: sessionId,
      recoveryId: '',
      deviceId: '',
      createdAt: DateTime.now(),
      finderLocation: location,
    );
  }

  @override
  Future<FinderSighting> reportSighting(String sessionId, FinderLocation location) async {
    // TODO: Call Supabase to insert sighting
    return FinderSighting(
      id: 'sighting_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      location: location,
      reportedAt: DateTime.now(),
    );
  }

  @override
  Future<void> sendContact(String sessionId, ContactOwnerForm form) async {
    // TODO: Call Supabase to send contact notification to owner
    // For now, just log
  }
}

/// Phase 6 local stub (offline-first).
class LocalFinderRepository implements FinderRemoteRepository {
  LocalFinderRepository(this._db);

  final AppDb _db;

  @override
  Future<FinderSession> startSession(String recoveryId, String deviceId) async {
    final session = FinderSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      recoveryId: recoveryId,
      deviceId: deviceId,
      createdAt: DateTime.now(),
    );
    await _db.enqueueCommand(
      PendingCommand(
        id: 'finder_session_${DateTime.now().millisecondsSinceEpoch}',
        deviceId: deviceId,
        type: 'FINDER_SESSION',
        status: 'PENDING',
        createdAt: DateTime.now(),
      ),
    );
    return session;
  }

  @override
  Future<LostScreenData> getRecoveryData(String recoveryId) async {
    return LostScreenData(
      recoveryId: recoveryId,
      message: 'If you\'ve found this device, please help return it.',
      contactUrl: 'https://retrace.app/recover/$recoveryId',
      qrData: 'https://retrace.app/recover/$recoveryId',
    );
  }

  @override
  Future<FinderSession> updateLocation(String sessionId, FinderLocation location) async {
    return FinderSession(
      id: sessionId,
      recoveryId: '',
      deviceId: '',
      createdAt: DateTime.now(),
      finderLocation: location,
    );
  }

  @override
  Future<FinderSighting> reportSighting(String sessionId, FinderLocation location) async {
    return FinderSighting(
      id: 'sighting_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      location: location,
      reportedAt: DateTime.now(),
    );
  }

  @override
  Future<void> sendContact(String sessionId, ContactOwnerForm form) async {
    // Local queue only
    await _db.enqueueCommand(
      PendingCommand(
        id: 'contact_${DateTime.now().millisecondsSinceEpoch}',
        deviceId: '',
        type: 'CONTACT_OWNER',
        status: 'PENDING',
        createdAt: DateTime.now(),
      ),
    );
  }
}

/// High-level controller for Finder.
class FinderController {
  FinderController(this._local, this._remote);

  final FinderLocalRepository _local;
  final FinderRemoteRepository _remote;

  Future<FinderSession> startSession(String recoveryId, String deviceId) async {
    try {
      final session = await _remote.startSession(recoveryId, deviceId);
      await _local.upsertSession(session);
      return session;
    } catch (_) {
      return _remote.startSession(recoveryId, deviceId);
    }
  }

  Future<LostScreenData> getRecoveryData(String recoveryId) async {
    return _remote.getRecoveryData(recoveryId);
  }

  Future<FinderSession> updateLocation(String sessionId, FinderLocation location) async {
    return _remote.updateLocation(sessionId, location);
  }

  Future<FinderSighting> reportSighting(String sessionId, FinderLocation location) async {
    return _remote.reportSighting(sessionId, location);
  }

  Future<void> sendContact(String sessionId, ContactOwnerForm form) async {
    await _remote.sendContact('sessionId', form);
  }
}

/// Providers
final finderLocalRepositoryProvider = Provider<FinderLocalRepository>(
  (Ref ref) => FinderLocalRepository(ref.watch(appDbProvider)),
);

final finderRemoteRepositoryProvider = Provider<FinderRemoteRepository>(
  (Ref ref) => SupabaseFinderRemoteRepository(ref.watch(appDbProvider)),
);

final finderControllerProvider = Provider<FinderController>(
  (Ref ref) => FinderController(
    ref.watch(finderLocalRepositoryProvider),
    ref.watch(finderRemoteRepositoryProvider),
  ),
);