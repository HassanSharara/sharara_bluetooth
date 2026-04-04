import 'package:flutter_test/flutter_test.dart';
import 'package:sharara_bluetooth/sharara_bluetooth.dart';
import 'package:sharara_bluetooth/sharara_bluetooth_platform_interface.dart';
import 'package:sharara_bluetooth/sharara_bluetooth_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockShararaBluetoothPlatform
    with MockPlatformInterfaceMixin
    implements ShararaBluetoothPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ShararaBluetoothPlatform initialPlatform = ShararaBluetoothPlatform.instance;

  test('$MethodChannelShararaBluetooth is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelShararaBluetooth>());
  });

  test('getPlatformVersion', () async {
    ShararaBluetooth shararaBluetoothPlugin = ShararaBluetooth();
    MockShararaBluetoothPlatform fakePlatform = MockShararaBluetoothPlatform();
    ShararaBluetoothPlatform.instance = fakePlatform;

    expect(await shararaBluetoothPlugin.getPlatformVersion(), '42');
  });
}
