import 'package:retrace/core/security/pin_crypto.dart';
import 'package:retrace/data/session/preferences_store.dart';

/// Secure PIN store — hashed + salt in platform-secure storage (§13, §45).
/// Brute-force protection: 5 attempts → 60s lockout, stored with timestamp.
///
/// Keys live only in Keychain/EncryptedSharedPreferences, never SharedPrefs.
final class PinRepository {
  PinRepository(this._prefs);

  final PreferencesStore _prefs;

  static const String _hashKey = 'retrace_pin_hash';
  static const String _saltKey = 'retrace_pin_salt';
  static const String _failKey = 'retrace_pin_fail_count';
  static const String _lockUntilKey = 'retrace_pin_lock_until';

  static const int maxAttempts = 5;
  static const Duration lockout = Duration(seconds: 60);

  Future<bool> hasPin() async => await _prefs.read(_hashKey) != null;

  Future<void> setPin(String pin) async {
    if (!PinCrypto.isValidPin(pin)) {
      throw ArgumentError('PIN must be 4-8 digits.');
    }
    final String salt = PinCrypto.generateSalt();
    final String hash = PinCrypto.hash(pin, salt);
    await _prefs.write(_saltKey, salt);
    await _prefs.write(_hashKey, hash);
    await _prefs.delete(_failKey);
    await _prefs.delete(_lockUntilKey);
  }

  Future<bool> verify(String pin) async {
    if (await isLocked()) return false;
    final String? salt = await _prefs.read(_saltKey);
    final String? hash = await _prefs.read(_hashKey);
    if (salt == null || hash == null) return false;
    final String candidate = PinCrypto.hash(pin, salt);
    final bool ok = PinCrypto.constantEquals(candidate, hash);
    if (ok) {
      await _prefs.delete(_failKey);
      await _prefs.delete(_lockUntilKey);
    } else {
      await _recordFailure();
    }
    return ok;
  }

  Future<bool> isLocked() async {
    final String? iso = await _prefs.read(_lockUntilKey);
    if (iso == null) return false;
    final DateTime until = DateTime.tryParse(iso) ?? DateTime.fromMillisecondsSinceEpoch(0);
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
    final DateTime until = DateTime.tryParse(iso) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final Duration d = until.difference(DateTime.now());
    return d.isNegative ? null : d;
  }

  Future<void> _recordFailure() async {
    final int fails = int.tryParse(await _prefs.read(_failKey) ?? '0') ?? 0;
    final int next = fails + 1;
    await _prefs.write(_failKey, '$next');
    if (next >= maxAttempts) {
      await _prefs.write(
          _lockUntilKey, DateTime.now().add(lockout).toIso8601String());
    }
  }

  Future<void> clear() async {
    await _prefs.delete(_hashKey);
    await _prefs.delete(_saltKey);
    await _prefs.delete(_failKey);
    await _prefs.delete(_lockUntilKey);
  }

  /// Export for backup testing only — never log hash in production.
  Future<Map<String, String?>> debugSnapshot() async => <String, String?>{
        'hash': await _prefs.read(_hashKey),
        'salt': await _prefs.read(_saltKey),
      };
}
