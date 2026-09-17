import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/main.dart' as app;

/// Optional sign-back-in credentials, passed only on local runs:
/// --dart-define=E2E_TEST_EMAIL=... --dart-define=E2E_TEST_PASSWORD=...
/// Never committed — the test skips the round-trip when absent.
const String _e2eEmail = String.fromEnvironment('E2E_TEST_EMAIL');
const String _e2ePassword = String.fromEnvironment('E2E_TEST_PASSWORD');

/// Guest journey E2E (runs on-device, here: Linux desktop).
/// Secure storage may already hold a session from manual QA, so the test
/// normalizes to signed-out first (via the real UI), asserts the guest
/// shell, then signs back in when credentials are supplied — leaving the
/// machine exactly as it found it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guest explores shell; optional sign-in round-trip',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Fresh installs land on onboarding; returning ones go to the shell.
    if (find.text('Welcome to RETRACE').evaluate().isNotEmpty) {
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await tester.tap(find.text('Explore first'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }

    // Shell tabs are reachable with or without a session.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Devices'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Normalize to guest through the real sign-out flow when needed.
    if (find.textContaining('Exploring as guest').evaluate().isEmpty) {
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Sign Out').last);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }
    expect(find.textContaining('Exploring as guest'), findsOneWidget);

    // Guest exploration: tabs render content, never a login wall.
    await tester.tap(find.text('Devices'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Search devices'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('RETRACE PIN'), findsOneWidget);

    // Optional: sign back in to restore the machine's session.
    if (_e2eEmail.isNotEmpty && _e2ePassword.isNotEmpty) {
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await tester.enterText(
        find.widgetWithText(TextField, 'Email or phone number'),
        _e2eEmail,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        _e2ePassword,
      );
      await tester.tap(find.widgetWithText(RetraceButton, 'Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 10));
      expect(find.textContaining('Exploring as guest'), findsNothing);
      expect(find.textContaining(_e2eEmail), findsOneWidget);
    }

    expect(tester.takeException(), isNull);
  });
}
