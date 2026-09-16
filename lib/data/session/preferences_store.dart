import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Human-readable auth/backend failures. Raw SDK messages never reach the UI
/// directly (§48) — controllers map them through here.
final class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// Thrown when Supabase is not linked yet. UI renders an honest
/// "backend not configured" error — never a fake success (§80-fake rule).
final class BackendUnconfiguredException extends AuthException {
  const BackendUnconfiguredException()
      : super(
          'Backend is not connected yet. '
          'Link a Supabase project to enable sign in.',
        );
}

/// Key-value persistence behind an interface so tests use memory
/// while production uses platform-secure storage (Keychain / EncryptedSharedPreferences).
abstract class PreferencesStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

final class SecurePreferencesStore implements PreferencesStore {
  SecurePreferencesStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

final class InMemoryPreferencesStore implements PreferencesStore {
  final Map<String, String> _map = <String, String>{};

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async => _map[key] = value;

  @override
  Future<void> delete(String key) async => _map.remove(key);
}
