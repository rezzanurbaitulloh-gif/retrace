import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/data/security/recovery_codes_repository.dart';
import 'package:retrace/data/session/preferences_store.dart';

void main() {
  group('RecoveryCodesRepository', () {
    late InMemoryPreferencesStore prefs;
    late RecoveryCodesRepository repo;

    setUp(() {
      prefs = InMemoryPreferencesStore();
      repo = RecoveryCodesRepository(prefs);
    });

    test('no codes initially', () async {
      expect(await repo.hasCodes(), isFalse);
      expect(await repo.remainingCount(), equals(0));
    });

    test('generates 8 unique display codes in XXXX-XXXX form', () async {
      final List<String> codes =
          await repo.generateCodes(random: Random(7));
      expect(codes, hasLength(RecoveryCodesRepository.codeCount));
      expect(codes.toSet(), hasLength(RecoveryCodesRepository.codeCount));
      for (final String c in codes) {
        expect(
          RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(c),
          isTrue,
          reason: c,
        );
        // Unambiguous alphabet only — no 0/O, 1/I/L.
        for (final String ch
            in RecoveryCodesRepository.normalizeCode(c).split('')) {
          expect(RecoveryCodesRepository.alphabet, contains(ch));
        }
      }
      expect(await repo.hasCodes(), isTrue);
      expect(await repo.remainingCount(), equals(8));
    });

    test('verify burns single-use; second use fails', () async {
      final List<String> codes =
          await repo.generateCodes(random: Random(11));
      expect(await repo.verifyAndBurn(codes.first), isTrue);
      expect(await repo.remainingCount(), equals(7));
      expect(await repo.verifyAndBurn(codes.first), isFalse);
    });

    test('wrong code fails without burning', () async {
      await repo.generateCodes(random: Random(13));
      expect(await repo.verifyAndBurn('ZZZZ-ZZZZ'), isFalse);
      expect(await repo.remainingCount(), equals(8));
    });

    test('input normalization: lowercase, spaces, no dash', () async {
      final List<String> codes =
          await repo.generateCodes(random: Random(17));
      final String core =
          RecoveryCodesRepository.normalizeCode(codes.first);
      expect(await repo.verifyAndBurn(core.toLowerCase()), isTrue);
    });

    test('regenerate invalidates the old batch', () async {
      final List<String> oldCodes =
          await repo.generateCodes(random: Random(19));
      await repo.generateCodes(random: Random(23));
      expect(await repo.verifyAndBurn(oldCodes.first), isFalse);
      expect(await repo.remainingCount(), equals(8));
    });

    test('locks after 5 failures, rejects even valid codes', () async {
      final List<String> codes =
          await repo.generateCodes(random: Random(29));
      for (int i = 0; i < 5; i++) {
        expect(await repo.verifyAndBurn('ZZZZ-ZZZZ'), isFalse);
      }
      expect(await repo.isLocked(), isTrue);
      expect(await repo.verifyAndBurn(codes.first), isFalse);
      // Burn did not happen — code still valid after lock clears.
      await prefs.write(
        'retrace_rc_lock_until',
        DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
      );
      expect(await repo.isLocked(), isFalse);
      expect(await repo.verifyAndBurn(codes.first), isTrue);
    });

    test('no plaintext codes in storage', () async {
      final List<String> codes =
          await repo.generateCodes(random: Random(31));
      final String? raw = await prefs.read('retrace_rc_hashes');
      expect(raw, isNotNull);
      for (final String c in codes) {
        final String core = RecoveryCodesRepository.normalizeCode(c);
        expect(raw, isNot(contains(core)));
        expect(raw, isNot(contains(c)));
      }
    });

    test('format/normalize helpers', () {
      expect(
        RecoveryCodesRepository.formatCode('AB12CD34'),
        equals('AB12-CD34'),
      );
      expect(
        RecoveryCodesRepository.normalizeCode('ab12-cd34 '),
        equals('AB12CD34'),
      );
    });
  });
}
