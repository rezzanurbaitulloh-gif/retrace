import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/data/session/onboarding_store.dart';

/// Startup gate: loads onboarding state from secure storage. The auth stream
/// primes itself via [AuthController], so no fake splash delay exists —
/// splash shows exactly as long as real I/O takes.
final bootstrapProvider = FutureProvider<void>((Ref ref) async {
  final OnboardingStore store = ref.watch(onboardingStoreProvider);
  ref.read(onboardingSeenProvider.notifier).state = await store.isSeen();
});
