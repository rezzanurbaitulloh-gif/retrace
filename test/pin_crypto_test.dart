import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/core/security/pin_crypto.dart';

void main() {
  group('PinCrypto', () {
    test('isValidPin rejects short/long/non-digit', () {
      expect(PinCrypto.isValidPin('123'), isFalse);
      expect(PinCrypto.isValidPin('123456789'), isFalse);
      expect(PinCrypto.isValidPin('abcd'), isFalse);
      expect(PinCrypto.isValidPin('12a4'), isFalse);
      expect(PinCrypto.isValidPin(''), isFalse);
    });
    test('isValidPin accepts 4-8 digits', () {
      expect(PinCrypto.isValidPin('1234'), isTrue);
      expect(PinCrypto.isValidPin('123456'), isTrue);
      expect(PinCrypto.isValidPin('12345678'), isTrue);
    });
    test('hash deterministic with same salt, different with diff salt', () {
      const String pin = '1234';
      const String salt = 'fixed-salt-for-test';
      final String h1 = PinCrypto.hash(pin, salt);
      final String h2 = PinCrypto.hash(pin, salt);
      expect(h1, equals(h2));
      expect(PinCrypto.hash(pin, 'other'), isNot(equals(h1)));
    });
    test('constantEquals avoids timing leak', () {
      expect(PinCrypto.constantEquals('abc', 'abc'), isTrue);
      expect(PinCrypto.constantEquals('abc', 'abd'), isFalse);
      expect(PinCrypto.constantEquals('abc', 'ab'), isFalse);
    });
    test('generateSalt is 16 bytes base64url', () {
      final String s1 = PinCrypto.generateSalt();
      final String s2 = PinCrypto.generateSalt();
      expect(s1, isNot(equals(s2)));
      expect(s1.length, greaterThan(10));
    });
  });
}
