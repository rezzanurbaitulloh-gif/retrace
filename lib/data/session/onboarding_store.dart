import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/data/session/preferences_store.dart';

/// Onboarding + device-type persistence (secure storage, Phase 2 shell).
/// Complex offline data moves to Drift in Phase 3 — these are single keys.
final preferencesStoreProvider = Provider<PreferencesStore>(
  (Ref ref) => SecurePreferencesStore(),
);

final onboardingSeenProvider = StateProvider<bool>((Ref ref) => false);

final class OnboardingStore {
  OnboardingStore(this._prefs);

  final PreferencesStore _prefs;

  static const String seenKey = 'retrace_onboarding_seen';
  static const String deviceTypeKey = 'retrace_onboarding_device_type';

  Future<bool> isSeen() async => await _prefs.read(seenKey) == '1';

  Future<void> markSeen() => _prefs.write(seenKey, '1');

  Future<String?> deviceType() => _prefs.read(deviceTypeKey);

  Future<void> setDeviceType(String value) =>
      _prefs.write(deviceTypeKey, value);
}

final onboardingStoreProvider = Provider<OnboardingStore>(
  (Ref ref) => OnboardingStore(ref.watch(preferencesStoreProvider)),
);
