import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// RETRACE PIN security (§13). Never plaintext, hashed with salt,
/// rate-limited, brute-force protected. Recovery via email fallback (§41).
///
/// Hash: SHA-256(salt + pin) with constant-time compare. Salt stored
/// alongside hash in secure storage (not in plain SharedPrefs).
abstract final class PinCrypto {
  static const int _saltLen = 16;

  static String generateSalt() {
    final Random r = Random.secure();
    final List<int> bytes =
        List<int>.generate(_saltLen, (_) => r.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hash(String pin, String salt) {
    final List<int> bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  /// Constant-time equality to avoid timing leak.
  static bool constantEquals(String a, String b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static bool isValidPin(String pin) => RegExp(r'^\d{4,8}$').hasMatch(pin);
}
