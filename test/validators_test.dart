import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/features/auth/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('   '), isNotNull);
    });
    test('rejects invalid', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('a@ b.com'), isNotNull);
    });
    test('accepts valid', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('reza@gmail.com'), isNull);
      expect(Validators.email('  reza@gmail.com  '), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects short', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('1234567'), isNotNull);
    });
    test('accepts 8+', () {
      expect(Validators.password('12345678'), isNull);
      expect(Validators.password('super-secret'), isNull);
    });
  });

  group('Validators.fullName', () {
    test('rejects empty/short', () {
      expect(Validators.fullName(''), isNotNull);
      expect(Validators.fullName('a'), isNotNull);
    });
    test('accepts real name', () {
      expect(Validators.fullName('Rezza'), isNull);
      expect(Validators.fullName('Rezza Nur'), isNull);
    });
  });
}
