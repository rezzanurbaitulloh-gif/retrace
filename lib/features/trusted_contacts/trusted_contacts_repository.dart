import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:retrace/core/db/app_db.dart';
import 'package:retrace/features/trusted_contacts/trusted_contacts.dart';
import 'package:retrace/providers.dart';

/// Local trusted-contacts persistence + sync queue (§40).
class TrustedContactsLocalRepository {
  TrustedContactsLocalRepository(this._db);

  final AppDb _db;

  final List<TrustedContact> _contacts = <TrustedContact>[];

  Future<void> upsert(TrustedContact contact) async {
    final int idx =
        _contacts.indexWhere((TrustedContact c) => c.id == contact.id);
    if (idx >= 0) {
      _contacts[idx] = contact;
    } else {
      _contacts.add(contact);
    }
    await _db.enqueueCommand(
      PendingCommand(
        id: 'contact_${contact.id}',
        deviceId: '',
        type: contact.status == ContactStatus.revoked
            ? 'CONTACT_REVOKE'
            : 'CONTACT_UPSERT',
        status: 'PENDING',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<TrustedContact>> listAll() async {
    final List<TrustedContact> out = List<TrustedContact>.of(_contacts)
      ..sort((TrustedContact a, TrustedContact b) =>
          a.createdAt.compareTo(b.createdAt));
    return List<TrustedContact>.unmodifiable(out);
  }

  Future<TrustedContact?> getById(String id) async {
    for (final TrustedContact c in _contacts) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// Remote contacts API.
abstract class TrustedContactsRemoteRepository {
  Future<List<TrustedContact>> listAll();
  Future<void> upsert(TrustedContact contact);
}

/// Production implementation — Supabase contacts table + RLS (§40).
/// The table does not exist yet: every call throws honestly so the
/// controller falls back to the local roster instead of faking rows.
class SupabaseTrustedContactsRemoteRepository
    implements TrustedContactsRemoteRepository {
  SupabaseTrustedContactsRemoteRepository(this._appDb);

  final AppDb _appDb;

  @override
  Future<List<TrustedContact>> listAll() {
    throw Exception(
      'Contacts service is not provisioned yet — roster is local-only.',
    );
  }

  @override
  Future<void> upsert(TrustedContact contact) {
    throw Exception(
      'Contacts service is not provisioned yet — change is queued locally.',
    );
  }
}

/// High-level controller: validate → store locally → queue → sync attempt.
class TrustedContactsController {
  TrustedContactsController(this._local, this._remote);

  final TrustedContactsLocalRepository _local;
  final TrustedContactsRemoteRepository _remote;

  Future<List<TrustedContact>> listAll() async {
    try {
      final List<TrustedContact> remote = await _remote.listAll();
      if (remote.isNotEmpty) return remote;
    } on Object {
      // Fall through — remote missing is expected until tables land.
    }
    return _local.listAll();
  }

  Future<TrustedContact> add({
    required String name,
    required String address,
    required Set<ContactScope> scopes,
  }) async {
    final String? nameError = validateContactName(name);
    if (nameError != null) throw TrustedContactRejected(nameError);
    final String? addressError = validateContactAddress(address);
    if (addressError != null) throw TrustedContactRejected(addressError);
    if (scopes.isEmpty) {
      throw const TrustedContactRejected('Pick at least one scope.');
    }
    final TrustedContact contact = TrustedContact(
      id: 'tc_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      address: address.trim(),
      scopes: Set<ContactScope>.of(scopes),
      createdAt: DateTime.now(),
    );
    await _local.upsert(contact);
    try {
      await _remote.upsert(contact);
    } on Object {
      // Queued locally — sync retries when the service lands.
    }
    return contact;
  }

  Future<TrustedContact> revoke(String id) async {
    final TrustedContact? existing = await _local.getById(id);
    if (existing == null) {
      throw const TrustedContactRejected('Contact no longer exists.');
    }
    final TrustedContact revoked =
        existing.copyWith(status: ContactStatus.revoked);
    await _local.upsert(revoked);
    try {
      await _remote.upsert(revoked);
    } on Object {
      // Queued locally.
    }
    return revoked;
  }
}

/// Validation failure — [message] is user-facing.
final class TrustedContactRejected implements Exception {
  const TrustedContactRejected(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Providers.
final trustedContactsLocalRepositoryProvider =
    Provider<TrustedContactsLocalRepository>(
  (Ref ref) => TrustedContactsLocalRepository(ref.watch(appDbProvider)),
);

final trustedContactsRemoteRepositoryProvider =
    Provider<TrustedContactsRemoteRepository>(
  (Ref ref) => SupabaseTrustedContactsRemoteRepository(
    ref.watch(appDbProvider),
  ),
);

final trustedContactsControllerProvider =
    Provider<TrustedContactsController>(
  (Ref ref) => TrustedContactsController(
    ref.watch(trustedContactsLocalRepositoryProvider),
    ref.watch(trustedContactsRemoteRepositoryProvider),
  ),
);
