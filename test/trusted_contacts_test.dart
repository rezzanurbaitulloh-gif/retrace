import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/features/trusted_contacts/trusted_contacts.dart';

TrustedContact _contact() => TrustedContact(
      id: 'tc_1',
      name: 'Ayu Lestari',
      address: 'ayu@example.com',
      scopes: const <ContactScope>{
        ContactScope.emergency,
        ContactScope.recovery,
      },
      createdAt: DateTime.utc(2026, 9, 18),
    );

void main() {
  group('validateContactName', () {
    test('accepts real names', () {
      expect(validateContactName('Ayu Lestari'), isNull);
    });

    test('rejects blank and single char', () {
      expect(validateContactName(''), isNotNull);
      expect(validateContactName('  '), isNotNull);
      expect(validateContactName('A'), isNotNull);
    });
  });

  group('validateContactAddress', () {
    test('accepts emails', () {
      expect(validateContactAddress('ayu@example.com'), isNull);
    });

    test('accepts local and international phones', () {
      expect(validateContactAddress('+628123456789'), isNull);
      expect(validateContactAddress('0812 3456 789'), isNull);
      expect(validateContactAddress('(021) 555-1234'), isNull);
    });

    test('rejects blank, short, and garbage', () {
      expect(validateContactAddress(''), isNotNull);
      expect(validateContactAddress('12345'), isNotNull);
      expect(validateContactAddress('not-an-address'), isNotNull);
      expect(validateContactAddress('abc-def'), isNotNull);
    });
  });

  group('scopeLabel', () {
    test('orders canonically and joins', () {
      expect(
        scopeLabel(const <ContactScope>{
          ContactScope.location,
          ContactScope.emergency,
        }),
        equals('Emergency · Location'),
      );
      expect(
        scopeLabel(const <ContactScope>{ContactScope.recovery}),
        equals('Recovery'),
      );
    });

    test('empty set falls back to Emergency', () {
      expect(scopeLabel(<ContactScope>{}), equals('Emergency'));
    });
  });

  group('TrustedContact JSON', () {
    test('round-trips scopes, status, timestamps', () {
      final TrustedContact back =
          TrustedContact.fromJson(_contact().toJson());
      expect(back.id, equals('tc_1'));
      expect(back.name, equals('Ayu Lestari'));
      expect(back.scopes,
          equals(<ContactScope>{ContactScope.emergency, ContactScope.recovery}));
      expect(back.status, equals(ContactStatus.invited));
      expect(back.isEmail, isTrue);
    });

    test('phone address is not email', () {
      final TrustedContact c =
          _contact().copyWith(address: '+628123456789');
      expect(c.isEmail, isFalse);
    });

    test('unknown scopes default to Emergency, unknown status to invited', () {
      final Map<String, dynamic> raw = _contact().toJson()
        ..['scopes'] = <String>['telepathy']
        ..['status'] = 'verified';
      final TrustedContact back = TrustedContact.fromJson(raw);
      expect(back.scopes, equals(<ContactScope>{ContactScope.emergency}));
      // No verified state exists until the server lands — never parsed in.
      expect(back.status, equals(ContactStatus.invited));
    });

    test('revoked survives round-trip', () {
      final TrustedContact back = TrustedContact.fromJson(
        _contact().copyWith(status: ContactStatus.revoked).toJson(),
      );
      expect(back.status, equals(ContactStatus.revoked));
    });
  });
}
