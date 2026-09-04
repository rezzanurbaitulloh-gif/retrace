class AppConfig {
  static const String appName = 'RETRACE';
  static const String appVersion = '1.0.0';
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://umxiqgauhfsbzlqiyelm.supabase.co');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const int defaultTrackingIntervalSeconds = 30;
  static const int batteryLowThreshold = 20;
  static const int maxOfflineLocations = 1000;
  static const int syncBatchSize = 50;
  static const int rescueBandwidthLimitBytes = 10485760;
  static const int qrTokenExpiryHours = 24;
}
