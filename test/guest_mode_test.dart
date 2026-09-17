import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/core/theme/retrace_theme.dart';
import 'package:retrace/routing/app_router.dart';

void main() {
  group('requiresAuth', () {
    test('account-bound routes require auth', () {
      for (final String loc in <String>[
        '/devices/new',
        '/pin',
        '/pin/codes',
        '/pin/recovery',
        '/trusted-contacts',
        '/devices/abc123/lost/activate',
        '/devices/abc123/evidence',
      ]) {
        expect(requiresAuth(loc), isTrue, reason: loc);
      }
    });

    test('browseable routes stay open for guests', () {
      for (final String loc in <String>[
        '/splash',
        '/onboarding',
        '/login',
        '/register',
        '/recovery',
        '/design-system',
        '/home',
        '/devices',
        '/devices/abc123',
        '/devices/abc123/map',
        '/devices/abc123/lost',
        '/lost/RT-ABC123',
        '/finder/scan',
        '/finder/RT-ABC123',
        '/map/live',
        '/map/history',
        '/activity',
        '/profile',
        '/permissions',
        '/protection-setup',
      ]) {
        expect(requiresAuth(loc), isFalse, reason: loc);
      }
    });

    test('lookalike paths do not over-match', () {
      // No such routes today — guards against sloppy prefix matching.
      expect(requiresAuth('/pincode'), isFalse);
      expect(requiresAuth('/devices/newcomer'), isFalse);
      expect(requiresAuth('/devices/abc123/lost'), isFalse);
    });
  });

  group('GuestModeBanner', () {
    testWidgets('renders message and fires sign-in', (
      WidgetTester tester,
    ) async {
      bool signedIn = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: RetraceTheme.dark(),
          home: Scaffold(
            body: GuestModeBanner(onSignIn: () => signedIn = true),
          ),
        ),
      );
      expect(find.textContaining('Exploring as guest'), findsOneWidget);
      await tester.tap(find.text('Sign in'));
      expect(signedIn, isTrue);
    });
  });
}
