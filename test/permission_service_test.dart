import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrace/services/permission_service.dart';

const MethodChannel _channel =
    MethodChannel('flutter.baseflow.com/permissions/methods');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('RealPermissionService.openSettings', () {
    test('missing plugin becomes friendly error, never a crash', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        throw MissingPluginException('No implementation found');
      });
      await expectLater(
        RealPermissionService().openSettings(),
        throwsA(isA<PermissionSettingsUnavailable>()),
      );
    });

    test('success path completes silently', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        expect(call.method, equals('openAppSettings'));
        return true;
      });
      await RealPermissionService().openSettings();
    });
  });
}
