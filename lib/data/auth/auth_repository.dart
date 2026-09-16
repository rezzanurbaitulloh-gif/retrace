import 'package:retrace/data/auth/auth_user.dart';

/// Auth contract. Implementations: Supabase (production) + fakes (tests).
/// No social login until a real provider is wired — never a fake button (§10).
abstract class AuthRepository {
  Stream<AuthUser?> watchAuth();
  Future<AuthUser?> currentUser();
  Future<AuthUser> signIn({required String email, required String password});
  Future<AuthUser> signUp({
    required String fullName,
    required String email,
    required String password,
  });
  Future<void> sendPasswordReset({required String email});
  Future<void> signOut();
}
