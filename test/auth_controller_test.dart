import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/data/auth/auth_repository.dart';
import 'package:retrace/data/auth/auth_user.dart';
import 'package:retrace/data/session/preferences_store.dart';
import 'package:retrace/features/auth/auth_controller.dart';

final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.initialUser});

  AuthUser? initialUser;
  bool shouldFailSignIn = false;
  bool shouldFailSignUp = false;
  final StreamController<AuthUser?> _ctrl =
      StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> watchAuth() async* {
    yield initialUser;
    yield* _ctrl.stream;
  }

  @override
  Future<AuthUser?> currentUser() async => initialUser;

  @override
  Future<AuthUser> signIn(
      {required String email, required String password}) async {
    if (shouldFailSignIn) throw const AuthException('Wrong email or password.');
    const AuthUser user =
        AuthUser(id: 'u1', email: 'a@b.co', displayName: 'Rezza');
    initialUser = user;
    _ctrl.add(user);
    return user;
  }

  @override
  Future<AuthUser> signUp(
      {required String fullName,
      required String email,
      required String password}) async {
    if (shouldFailSignUp) throw const AuthException('Already registered.');
    const AuthUser user =
        AuthUser(id: 'u2', email: 'new@b.co', displayName: 'New User');
    initialUser = user;
    _ctrl.add(user);
    return user;
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {}

  @override
  Future<void> signOut() async {
    initialUser = null;
    _ctrl.add(null);
  }
}

void main() {
  group('AuthController', () {
    test('starts with null when not signed in', () async {
      final FakeAuthRepository repo = FakeAuthRepository(initialUser: null);
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      final AsyncValue<AuthUser?> v = await c.read(authControllerProvider.future).then(
            (AuthUser? u) => AsyncData<AuthUser?>(u),
            onError: (Object e, StackTrace st) => AsyncError<AuthUser?>(e, st),
          );
      // StreamNotifier initial value is AsyncLoading then AsyncData(null)
      expect(c.read(authControllerProvider).valueOrNull, isNull);
      expect(v.valueOrNull, isNull);
    });

    test('signIn failure surfaces as AsyncError', () async {
      final FakeAuthRepository repo = FakeAuthRepository()..shouldFailSignIn = true;
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      // prime
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await c.read(authControllerProvider.notifier).signIn(
            email: 'a@b.co',
            password: 'wrong',
          );
      expect(c.read(authControllerProvider) is AsyncError<AuthUser?>, isTrue);
    });

    test('signIn success yields user', () async {
      final FakeAuthRepository repo = FakeAuthRepository();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await c.read(authControllerProvider.notifier).signIn(
            email: 'a@b.co',
            password: 'ok123456',
          );
      expect(c.read(authControllerProvider).valueOrNull?.email, 'a@b.co');
    });

    test('authController exposes current user after signUp', () async {
      final FakeAuthRepository repo = FakeAuthRepository();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await c.read(authControllerProvider.notifier).signUp(
            fullName: 'Rezza',
            email: 'new@b.co',
            password: 'ok123456',
          );
      expect(c.read(authControllerProvider).valueOrNull?.id, 'u2');
    });
  });
}
