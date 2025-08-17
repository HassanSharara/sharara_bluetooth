import 'package:flutter_test/flutter_test.dart';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sharara_bluetooth/sharara_bluetooth.dart';
import 'package:sharara_bluetooth/sharara_bluetooth_method_channel.dart';
import 'package:sharara_bluetooth/sharara_bluetooth_platform_interface.dart';


class MockShararaBluetoothPlatform
    with MockPlatformInterfaceMixin
    implements ShararaBluetoothPlatform {

  @override
  Future<void> cancelDiscovery() {
    // TODO: implement cancelDiscovery
    throw UnimplementedError();
  }

  @override
  Future<bool> connect(BluetoothDevice device, {String uuid = "00001101-0000-1000-8000-00805F9B34FB"}) {
    // TODO: implement connect
    throw UnimplementedError();
  }

  @override
  Future<bool> disconnect(BluetoothDevice device) {
    // TODO: implement disconnect
    throw UnimplementedError();
  }

  @override
  Future<bool> isAllServicesDisposed() {
    // TODO: implement isAllServicesDisposed
    throw UnimplementedError();
  }

  @override
  Future<bool> isDeviceConnected(BluetoothDevice device) {
    // TODO: implement isDeviceConnected
    throw UnimplementedError();
  }

  @override
  Future<bool> isDiscovering() {
    // TODO: implement isDiscovering
    throw UnimplementedError();
  }

  @override
  Future<Stream<List<BluetoothDevice>>?> startDiscovery({Duration? duration}) {
    // TODO: implement startDiscovery
    throw UnimplementedError();
  }

  @override
  Future<void> stopAndDisposeAllServices() {
    // TODO: implement stopAndDisposeAllServices
    throw UnimplementedError();
  }

  @override
  // TODO: implement stream
  Stream<List<BluetoothDevice>>? get stream => throw UnimplementedError();

  @override
  Future<bool> writeToDevice(BluetoothDevice device, {required List<int> data}) {
    // TODO: implement writeToDevice
    throw UnimplementedError();
  }

  @override
  Future<bool> forceConnecting(BluetoothDevice device, {String uuid = "00001101-0000-1000-8000-00805F9B34FB"}) {
    // TODO: implement forceConnecting
    throw UnimplementedError();
  }
}

void main() {
  final ShararaBluetoothPlatform initialPlatform = ShararaBluetoothPlatform.instance;

  test('$MethodChannelShararaBlu is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelShararaBlu>());
  });

  test('stopAndDisposeAllServices', () async {
    MockShararaBluetoothPlatform fakePlatform = MockShararaBluetoothPlatform();
    ShararaBluetoothPlatform.instance = fakePlatform;
  });
}
