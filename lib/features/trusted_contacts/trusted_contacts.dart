import 'package:flutter/foundation.dart';
import 'package:retrace/features/auth/validators.dart';

/// Trusted contacts (§40). Pure Dart — no platform imports, fully testable.
///
/// Honesty contract: contacts are an owner-managed roster with *intended*
/// permission scopes. Statuses are only [ContactStatus.invited] and
/// [ContactStatus.revoked] — there is deliberately no "verified/active"
/// state, because granting access requires the server-side contacts table +
/// RLS policies, which do not exist yet. The UI must never imply a contact
/// can currently access anything.
enum ContactScope { emergency, recovery, location }

extension ContactScopeLabel on ContactScope {
  String get title => switch (this) {
        ContactScope.emergency => 'Emergency',
        ContactScope.recovery => 'Recovery',
        ContactScope.location => 'Location',
      };

  String get description => switch (this) {
        ContactScope.emergency =>
          'Can be notified in an emergency once the contacts service lands.',
        ContactScope.recovery =>
          'Can help return a lost device once the contacts service lands.',
        ContactScope.location =>
          'May see live location once the contacts service lands.',
      };
}

enum ContactStatus { invited, revoked }

extension ContactStatusLabel on ContactStatus {
  String get title => switch (this) {
        ContactStatus.invited => 'Invited',
        ContactStatus.revoked => 'Revoked',
      };
}

/// A person the owner trusts with future recovery/help scopes.
@immutable
final class TrustedContact {
  const TrustedContact({
    required this.id,
    required this.name,
    required this.address,
    this.scopes = const <ContactScope>{ContactScope.emergency},
    this.status = ContactStatus.invited,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String address; // email or phone, as typed
  final Set<ContactScope> scopes;
  final ContactStatus status;
  final DateTime createdAt;

  bool get isEmail => Validators.email(address) == null;

  TrustedContact copyWith({
    String? id,
    String? name,
    String? address,
    Set<ContactScope>? scopes,
    ContactStatus? status,
    DateTime? createdAt,
  }) {
    return TrustedContact(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      scopes: scopes ?? this.scopes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'address': address,
        'scopes': scopes.map((ContactScope s) => s.name).toList(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TrustedContact.fromJson(Map<String, dynamic> json) {
    final List<Object?> rawScopes =
        (json['scopes'] as List?)?.cast<Object?>() ?? <Object?>[];
    final Set<ContactScope> scopes = <ContactScope>{
      for (final Object? s in rawScopes)
        if (s == ContactScope.emergency.name)
          ContactScope.emergency
        else if (s == ContactScope.recovery.name)
          ContactScope.recovery
        else if (s == ContactScope.location.name)
          ContactScope.location,
    };
    return TrustedContact(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      scopes: scopes.isEmpty ? <ContactScope>{ContactScope.emergency} : scopes,
      status: json['status'] == ContactStatus.revoked.name
          ? ContactStatus.revoked
          : ContactStatus.invited,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Human summary of a scope set, e.g. "Emergency · Recovery".
String scopeLabel(Set<ContactScope> scopes) {
  if (scopes.isEmpty) return ContactScope.emergency.title;
  final List<ContactScope> ordered = ContactScope.values
      .where(scopes.contains)
      .toList();
  return ordered.map((ContactScope s) => s.title).join(' · ');
}

/// Name rules mirror [Validators.fullName] so messages stay consistent.
String? validateContactName(String value) => Validators.fullName(value);

/// Address must be an email or a phone number (7+ digits, optional +, spaces,
/// dashes, parentheses). Returns a user-facing reason or null when valid.
String? validateContactAddress(String value) {
  final String v = value.trim();
  if (v.isEmpty) return 'Email or phone is required.';
  if (Validators.email(v) == null) return null;
  final String digits = v.replaceAll(RegExp(r'\D'), '');
  final bool shapeOk =
      RegExp(r'^\+?[(0-9][0-9\s\-().]{5,}$').hasMatch(v) &&
          digits.length >= 7;
  if (shapeOk) return null;
  return 'Enter a valid email or phone number.';
}
