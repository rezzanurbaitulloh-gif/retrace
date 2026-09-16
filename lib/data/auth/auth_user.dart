import 'package:flutter/foundation.dart';

/// Minimal session user. Profile enrichment (display name, avatar, timezone…)
/// arrives with account setup (§11) — never invented here.
@immutable
final class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
  });

  final String id;
  final String email;
  final String? displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          other.id == id &&
          other.email == email &&
          other.displayName == displayName;

  @override
  int get hashCode => Object.hash(id, email, displayName);
}
