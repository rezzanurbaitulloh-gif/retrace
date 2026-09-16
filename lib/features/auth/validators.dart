/// Real input validation — shared by login, register, recovery.
/// Tested in `test/validators_test.dart`.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String value) {
    final String v = value.trim();
    if (v.isEmpty) return 'Email is required.';
    if (!_email.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  static String? fullName(String value) {
    if (value.trim().isEmpty) return 'Full name is required.';
    if (value.trim().length < 2) return 'Enter your real name.';
    return null;
  }
}
