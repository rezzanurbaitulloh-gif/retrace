import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:retrace/core/config/env.dart';
import 'package:retrace/data/auth/auth_repository.dart';
import 'package:retrace/data/auth/auth_user.dart';
import 'package:retrace/data/session/preferences_store.dart';

/// Production auth over Supabase Auth. Session persistence + expiry are
/// handled by the SDK; this layer maps SDK results to [AuthUser] and SDK
/// failures to human-readable [AuthException]s.
final class SupabaseAuthRepository implements AuthRepository {
  sb.SupabaseClient get _client {
    if (!Env.isSupabaseConfigured) {
      throw const BackendUnconfiguredException();
    }
    return sb.Supabase.instance.client;
  }

  static AuthUser _toUser(sb.User user) => AuthUser(
        id: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['full_name'] as String?,
      );

  static AuthException _toFailure(Object error) {
    if (error is BackendUnconfiguredException) return error;
    if (error is sb.AuthException) {
      return AuthException(_humanize(error.message));
    }
    return const AuthException(
      'Something went wrong. Check your connection and try again.',
    );
  }

  /// Never leak raw server text like "invalid JWT" or status codes (§48).
  static String _humanize(String message) {
    final String lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Wrong email or password. Try again or reset your password.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please verify your email first, then sign in.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already exists')) {
      return 'This email is already registered. Try signing in instead.';
    }
    if (lower.contains('password')) {
      return 'Password does not meet the requirements. Use at least 8 characters.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('timeout')) {
      return 'Unable to reach the server. Your data stays on this device — try again.';
    }
    return 'Unable to sign in. Please try again.';
  }

  @override
  Stream<AuthUser?> watchAuth() {
    if (!Env.isSupabaseConfigured) return Stream<AuthUser?>.value(null);
    return _client.auth.onAuthStateChange.map(
      (sb.AuthState state) =>
          state.session?.user == null ? null : _toUser(state.session!.user),
    );
  }

  @override
  Future<AuthUser?> currentUser() async {
    if (!Env.isSupabaseConfigured) return null;
    final sb.User? user = _client.auth.currentUser;
    return user == null ? null : _toUser(user);
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final sb.AuthResponse res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final sb.User? user = res.user;
      if (user == null) {
        throw const AuthException('Unable to sign in. Please try again.');
      }
      return _toUser(user);
    } on Object catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<AuthUser> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final sb.AuthResponse res = await _client.auth.signUp(
        email: email,
        password: password,
        data: <String, Object>{'full_name': fullName},
      );
      final sb.User? user = res.user;
      if (user == null) {
        throw const AuthException('Unable to create account. Please try again.');
      }
      return _toUser(user);
    } on Object catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on Object catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<void> signOut() async {
    if (!Env.isSupabaseConfigured) return;
    try {
      await _client.auth.signOut();
    } on Object catch (e) {
      throw _toFailure(e);
    }
  }
}
