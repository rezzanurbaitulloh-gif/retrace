import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/data/auth/auth_repository.dart';
import 'package:retrace/data/auth/auth_user.dart';
import 'package:retrace/data/auth/supabase_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (Ref ref) => SupabaseAuthRepository(),
);

/// Session source of truth. `AsyncData(null)` = signed out,
/// `AsyncData(user)` = signed in, `AsyncError` = last failure surfaced once
/// (screens show it, then it is replaced by the live auth stream).
final class AuthController extends StreamNotifier<AuthUser?> {
  @override
  Stream<AuthUser?> build() =>
      ref.watch(authRepositoryProvider).watchAuth();

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading<AuthUser?>();
    state = await AsyncValue.guard<AuthUser?>(
      () => ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          ),
    );
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading<AuthUser?>();
    state = await AsyncValue.guard<AuthUser?>(
      () => ref.read(authRepositoryProvider).signUp(
            fullName: fullName,
            email: email,
            password: password,
          ),
    );
  }

  Future<void> sendPasswordReset({required String email}) async {
    await ref.read(authRepositoryProvider).sendPasswordReset(email: email);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}

final authControllerProvider =
    StreamNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);
