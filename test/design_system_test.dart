import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/app/design_gallery.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/design_system/components/retrace_cards.dart';
import 'package:retrace/design_system/components/retrace_states.dart';

import 'helpers.dart';

void main() {
  group('Design system tokens', () {
    test('status colors are distinct and danger reserved for lost', () {
      expect(RetraceColors.statusColor(DeviceStatus.lost),
          RetraceColors.danger);
      expect(RetraceColors.statusColor(DeviceStatus.protected),
          RetraceColors.success);
      expect(
        RetraceColors.statusColor(DeviceStatus.lost) !=
            RetraceColors.statusColor(DeviceStatus.protected),
        isTrue,
      );
    });
  });

  group('States', () {
    testWidgets('EmptyState renders action', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        const EmptyState(
          title: 'No devices yet',
          message: 'Protect your first device with RETRACE.',
          actionLabel: 'Add Device',
          onAction: noop,
        ),
      ));
      expect(find.text('No devices yet'), findsOneWidget);
      expect(find.text('Add Device'), findsOneWidget);
    });

    testWidgets('ErrorState renders retry', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        const ErrorState(message: 'No connection.', onRetry: noop),
      ));
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('OfflineBanner announces pending count',
        (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        const OfflineBanner(pendingCount: 12, lastSynced: '10:28'),
      ));
      expect(find.textContaining('12'), findsWidgets);
    });

    testWidgets('StatusBadge is never color-only (icon + text)',
        (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        const StatusBadge(status: DeviceStatus.lost),
      ));
      expect(find.textContaining('Lost Mode'), findsOneWidget);
      expect(find.byType(Icon), findsWidgets);
    });
  });

  group('Gallery', () {
    testWidgets('renders all sections without overflow at 320dp',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: DesignGalleryPage())),
      );
      // NOTE: pump(), not pumpAndSettle(): SyncIndicator + theme toggle hold
      // indefinite animations (progress spinners), which never "settle".
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('RETRACE · Design System'), findsOneWidget);
      expect(find.text('Find. Protect. Recover.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
