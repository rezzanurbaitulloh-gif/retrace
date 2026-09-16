import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/core/db/app_db.dart';
import 'package:retrace/core/theme/retrace_theme.dart';
import 'package:retrace/data/session/onboarding_store.dart';
import 'package:retrace/data/session/preferences_store.dart';
import 'package:retrace/features/device_registration/device_registration_page.dart'
    show deviceInfoServiceProvider, DeviceRegistrationPage;
import 'package:retrace/features/devices/devices_repository.dart';
import 'package:retrace/services/device_info_service.dart';

// Local test providers - same as feature files
final deviceInfoServiceProviderTest =
    Provider<DeviceInfoService>((Ref ref) => RealDeviceInfoService());

class FakeDeviceInfo implements DeviceInfoService {
  @override
  Future<DeviceIdentity> getIdentity() async => const DeviceIdentity(
        brand: 'FakeBrand',
        model: 'FakeModel',
        osName: 'Android',
        osVersion: '14',
        manufacturer: 'FakeMfg',
        isPhysical: true,
        androidId: 'fake-id',
      );
  @override
  Future<String> getAppVersion() async => '1.0.0+1';
}

void main() {
  testWidgets('Device registration shows auto-detected and saves', (WidgetTester tester) async {
    final AppDb db = AppDb.forTesting();
    addTearDown(() async => db.close());
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDbProvider.overrideWithValue(db),
          deviceInfoServiceProvider.overrideWithValue(FakeDeviceInfo()),
          preferencesStoreProvider.overrideWithValue(InMemoryPreferencesStore()),
        ],
        child: MaterialApp(
          theme: RetraceTheme.dark(),
          home: const DeviceRegistrationPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Wait for device identity to load
    for (int i = 0; i < 10 && find.text('FakeBrand').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('FakeBrand'), findsOneWidget);
    expect(find.text('Unavailable'), findsNothing);
    await tester.enterText(find.byType(TextFormField).first, 'My Phone');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save_device_button')));
    await tester.pumpAndSettle();
    // after pop, stack would close — in test we stay on page but db should have entry
    final List<LocalDevice> all = await db.allDevices();
    expect(all.length, equals(1));
    expect(all.first.name, equals('My Phone'));
    expect(all.first.brand, equals('FakeBrand'));
  });

  testWidgets('IMEI empty is allowed (Unavailable never fake)', (WidgetTester tester) async {
    final AppDb db = AppDb.forTesting();
    addTearDown(() async => db.close());
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDbProvider.overrideWithValue(db),
          deviceInfoServiceProvider.overrideWithValue(FakeDeviceInfo()),
          preferencesStoreProvider.overrideWithValue(InMemoryPreferencesStore()),
        ],
        child: MaterialApp(theme: RetraceTheme.dark(), home: const DeviceRegistrationPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Tablet');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save_device_button')));
    await tester.pumpAndSettle();
    expect((await db.allDevices()).length, equals(1));
  });
}
