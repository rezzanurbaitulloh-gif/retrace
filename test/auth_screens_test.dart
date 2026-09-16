import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/core/theme/retrace_theme.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/features/auth/login_page.dart';
import 'package:retrace/features/auth/recovery_page.dart';
import 'package:retrace/features/auth/register_page.dart';

Widget _harness(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: RetraceTheme.light(),
        darkTheme: RetraceTheme.dark(),
        themeMode: ThemeMode.dark,
        home: child,
      ),
    );

void main() {
  group('Auth screens render', () {
    testWidgets('Login shows fields + actions', (WidgetTester tester) async {
      await tester.pumpWidget(_harness(const LoginPage()));
      await tester.pump();
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Email or phone number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('Register shows full name + email + password',
        (WidgetTester tester) async {
      await tester.pumpWidget(_harness(const RegisterPage()));
      await tester.pump();
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('Recovery shows email field', (WidgetTester tester) async {
      await tester.pumpWidget(_harness(const RecoveryPage()));
      await tester.pump();
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
    });

    testWidgets('Login validates without network call',
        (WidgetTester tester) async {
      await tester.pumpWidget(_harness(const LoginPage()));
      await tester.pump();
      await tester.tap(find.byType(RetraceButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Email is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
    });
  });
}
