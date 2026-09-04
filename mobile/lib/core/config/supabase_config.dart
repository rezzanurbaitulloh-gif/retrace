import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';
class SupabaseConfig {
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static Future<void> initialize() async {
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  }
}
