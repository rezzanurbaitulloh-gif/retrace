import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/data/session/onboarding_store.dart';
import 'package:retrace/data/session/preferences_store.dart';
import 'package:retrace/features/onboarding/onboarding_page.dart';

void main() {
  testWidgets('Onboarding completes and persists seen flag',
      (WidgetTester tester) async {
    final InMemoryPreferencesStore prefs = InMemoryPreferencesStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          preferencesStoreProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: OnboardingPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Swipe through 3 pages via Continue
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
    expect(find.text('What are you protecting?'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    // allow async write
    await tester.pump(const Duration(milliseconds: 50));
    expect(await prefs.read(OnboardingStore.seenKey), '1');
    expect(await prefs.read(OnboardingStore.deviceTypeKey), isNotNull);
  });

  testWidgets('Onboarding respects 320dp without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          preferencesStoreProvider
              .overrideWithValue(InMemoryPreferencesStore()),
        ],
        child: const MaterialApp(home: OnboardingPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
