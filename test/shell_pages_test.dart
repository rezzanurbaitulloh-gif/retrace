import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/core/theme/retrace_theme.dart';
import 'package:retrace/features/activity/activity_page.dart';
import 'package:retrace/features/devices/devices_page.dart';
import 'package:retrace/features/home/home_page.dart';
import 'package:retrace/features/profile/profile_page.dart';

Widget _shell(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: RetraceTheme.light(),
        darkTheme: RetraceTheme.dark(),
        themeMode: ThemeMode.dark,
        home: child,
      ),
    );

void main() {
  testWidgets('Home renders empty state without devices',
      (WidgetTester tester) async {
    await tester.pumpWidget(_shell(const HomePage()));
    await tester.pump();
    expect(find.text('No devices yet'), findsOneWidget);
  });

  testWidgets('Devices renders filter chips + search',
      (WidgetTester tester) async {
    await tester.pumpWidget(_shell(const DevicesPage()));
    await tester.pump();
    expect(find.text('Search devices'), findsOneWidget);
    expect(find.text('All'), findsWidgets);
    expect(find.text('Lost'), findsOneWidget);
  });

  testWidgets('Activity renders tabs + empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(_shell(const ActivityPage()));
    await tester.pump();
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('No activity yet'), findsOneWidget);
  });

  testWidgets('Profile renders sign out (no dead entries)',
      (WidgetTester tester) async {
    await tester.pumpWidget(_shell(const ProfilePage()));
    await tester.pump();
    expect(find.text('RETRACE PIN'), findsOneWidget);
    // Preferences + Support are below fold — scroll to reveal.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Trusted Contacts'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Soon'), findsWidgets);
    expect(find.text('Sign Out'), findsOneWidget);
  });

  testWidgets('Shell pages survive 320dp',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    for (final Widget page in <Widget>[
      const HomePage(),
      const DevicesPage(),
      const ActivityPage(),
      const ProfilePage(),
    ]) {
      await tester.pumpWidget(_shell(page));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });
}
