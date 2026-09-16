/// Compile-time environment. Secrets arrive via `--dart-define`, never
/// hardcoded, never committed (§42, security-review checklist).
///
/// Example:
/// ```sh
/// flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=<anon-key>
/// ```
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// False until the owner links a Supabase project (Phase 3).
  /// Repositories throw [BackendUnconfiguredException] instead of faking data.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
