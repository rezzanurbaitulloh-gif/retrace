import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/data/security/pin_repository.dart';
import 'package:retrace/data/session/preferences_store.dart';

void main() {
  group('PinRepository', () {
    late InMemoryPreferencesStore prefs;
    late PinRepository repo;

    setUp(() {
      prefs = InMemoryPreferencesStore();
      repo = PinRepository(prefs);
    });

    test('hasPin false initially', () async {
      expect(await repo.hasPin(), isFalse);
    });

    test('setPin and verify success', () async {
      await repo.setPin('1234');
      expect(await repo.hasPin(), isTrue);
      expect(await repo.verify('1234'), isTrue);
      expect(await repo.verify('0000'), isFalse);
    });

    test('verify locks after 5 failures', () async {
      await repo.setPin('1234');
      for (int i = 0; i < 5; i++) {
        expect(await repo.verify('0000'), isFalse);
      }
      expect(await repo.isLocked(), isTrue);
      final Duration? rem = await repo.lockRemaining();
      expect(rem, isNotNull);
      expect(rem!.inSeconds, greaterThan(0));
      // correct pin still locked
      expect(await repo.verify('1234'), isFalse);
    });

    test('lock clears after expiry (simulate past)', () async {
      await repo.setPin('1234');
      for (int i = 0; i < 5; i++) {
        await repo.verify('0000');
      }
      // manually set lockUntil in past
      await prefs.write('retrace_pin_lock_until',
          DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String());
      expect(await repo.isLocked(), isFalse);
      expect(await repo.verify('1234'), isTrue);
    });

    test('setPin rejects non-digit', () async {
      expect(() => repo.setPin('ab12'), throwsArgumentError);
      expect(() => repo.setPin('123'), throwsArgumentError);
    });

    test('hash is not plaintext in storage', () async {
      await repo.setPin('5678');
      final Map<String, String?> snap = await repo.debugSnapshot();
      expect(snap['hash'], isNotNull);
      expect(snap['hash'], isNot(equals('5678')));
      expect(snap['salt'], isNotNull);
    });
  });
}
