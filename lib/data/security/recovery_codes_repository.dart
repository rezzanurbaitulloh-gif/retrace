import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/core/security/pin_crypto.dart';
import 'package:retrace/data/session/onboarding_store.dart';
import 'package:retrace/data/session/preferences_store.dart';

/// Offline PIN recovery codes (§41 codes leg).
///
/// Fully local by design: 8 single-use codes, only salted SHA-256 hashes in
/// secure storage, verified with constant-time compare, burned on use, and
/// rate-limited exactly like the PIN (5 attempts → 60s lockout). Plaintext
/// exists only in the return value of [generateCodes] — shown once, then it
/// lives on the paper the owner wrote it on. There is deliberately no
/// "list my codes" API: unburned codes cannot be re-displayed.
final class RecoveryCodesRepository {
  RecoveryCodesRepository(this._prefs);

  final PreferencesStore _prefs;

  static const int codeCount = 8;
  static const int codeCoreLength = 8;

  /// Unambiguous alphabet — no 0/O, 1/I/L.
  static const String alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static const String _hashesKey = 'retrace_rc_hashes';
  static const String _failKey = 'retrace_rc_fail_count';
  static const String _lockUntilKey = 'retrace_rc_lock_until';

  static const int maxAttempts = 5;
  static const Duration lockout = Duration(seconds: 60);

  Future<bool> hasCodes() async {
    final List<_CodeHash> hashes = await _readHashes();
    return hashes.isNotEmpty;
  }

  Future<int> remainingCount() async {
    final List<_CodeHash> hashes = await _readHashes();
    return hashes.length;
  }

  /// Generates a fresh batch, replacing any previous one, and returns the
  /// display codes (`XXXX-XXXX`) exactly once. Old codes stop working.
  Future<List<String>> generateCodes({Random? random}) async {
    final Random r = random ?? Random.secure();
    final Set<String> cores = <String>{};
    while (cores.length < codeCount) {
      final StringBuffer sb = StringBuffer();
      for (int i = 0; i < codeCoreLength; i++) {
        sb.write(alphabet[r.nextInt(alphabet.length)]);
      }
      cores.add(sb.toString());
    }
    // Each code gets its own salt; the stored salt is exactly the one
    // the hash was computed with.
    final List<_CodeHash> hashes = <_CodeHash>[];
    for (final String core in cores) {
      final String salt = PinCrypto.generateSalt();
      hashes.add(_CodeHash(salt: salt, hash: PinCrypto.hash(core, salt)));
    }
    await _prefs.write(
      _hashesKey,
      jsonEncode(hashes.map((e) => e.toJson()).toList()),
    );
    await _prefs.delete(_failKey);
    await _prefs.delete(_lockUntilKey);
    return cores.map(formatCode).toList();
  }

  /// Verifies [input] against unburned hashes; burns the match (single-use).
  /// Returns false for wrong codes and while locked — never reveals which.
  Future<bool> verifyAndBurn(String input) async {
    if (await isLocked()) return false;
    final String core = normalizeCode(input);
    if (core.length != codeCoreLength) {
      await _recordFailure();
      return false;
    }
    final List<_CodeHash> hashes = await _readHashes();
    for (int i = 0; i < hashes.length; i++) {
      final String candidate = PinCrypto.hash(core, hashes[i].salt);
      if (PinCrypto.constantEquals(candidate, hashes[i].hash)) {
        final List<_CodeHash> rest = List<_CodeHash>.of(hashes)..removeAt(i);
        await _persist(rest);
        await _prefs.delete(_failKey);
        await _prefs.delete(_lockUntilKey);
        return true;
      }
    }
    await _recordFailure();
    return false;
  }

  Future<bool> isLocked() async {
    final String? iso = await _prefs.read(_lockUntilKey);
    if (iso == null) return false;
    final DateTime until =
        DateTime.tryParse(iso) ?? DateTime.fromMillisecondsSinceEpoch(0);
    if (DateTime.now().isAfter(until)) {
      await _prefs.delete(_failKey);
      await _prefs.delete(_lockUntilKey);
      return false;
    }
    return true;
  }

  Future<Duration?> lockRemaining() async {
    final String? iso = await _prefs.read(_lockUntilKey);
    if (iso == null) return null;
    final DateTime until =
        DateTime.tryParse(iso) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final Duration d = until.difference(DateTime.now());
    return d.isNegative ? null : d;
  }

  Future<void> _recordFailure() async {
    final int fails =
        int.tryParse(await _prefs.read(_failKey) ?? '0') ?? 0;
    final int next = fails + 1;
    await _prefs.write(_failKey, '$next');
    if (next >= maxAttempts) {
      await _prefs.write(
        _lockUntilKey,
        DateTime.now().add(lockout).toIso8601String(),
      );
    }
  }

  Future<List<_CodeHash>> _readHashes() async {
    final String? raw = await _prefs.read(_hashesKey);
    if (raw == null || raw.isEmpty) return <_CodeHash>[];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return <_CodeHash>[
        for (final dynamic e in list)
          _CodeHash.fromJson(Map<String, dynamic>.from(e as Map)),
      ];
    } on Object {
      return <_CodeHash>[];
    }
  }

  Future<void> _persist(List<_CodeHash> hashes) async {
    await _prefs.write(
      _hashesKey,
      jsonEncode(hashes.map((e) => e.toJson()).toList()),
    );
  }

  /// Display form `XXXX-XXXX` for an 8-char core.
  static String formatCode(String core) {
    final String c = core.toUpperCase();
    if (c.length != codeCoreLength) return c;
    return '${c.substring(0, 4)}-${c.substring(4)}';
  }

  /// Normalizes user input: uppercase, strip everything outside A-Z0-9.
  static String normalizeCode(String input) {
    return input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }
}

final class _CodeHash {
  const _CodeHash({required this.salt, required this.hash});

  final String salt;
  final String hash;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'salt': salt,
        'hash': hash,
      };

  factory _CodeHash.fromJson(Map<String, dynamic> json) => _CodeHash(
        salt: json['salt'] as String,
        hash: json['hash'] as String,
      );
}

final recoveryCodesRepositoryProvider =
    Provider<RecoveryCodesRepository>(
  (Ref ref) => RecoveryCodesRepository(ref.watch(preferencesStoreProvider)),
);
