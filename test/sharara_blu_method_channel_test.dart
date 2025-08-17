import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharara_bluetooth/sharara_bluetooth_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelShararaBlu platform = MethodChannelShararaBlu();
  const MethodChannel channel = MethodChannel('sharara_bluetooth');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {

  });
}
