import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sharara_bluetooth/sharara_bluetooth.dart';
import 'package:sharara_bluetooth/sharara_bluetooth_method_channel.dart';

abstract class ShararaBluetoothPlatform extends PlatformInterface {
  /// Constructs a ShararaBluetoothPlatform.
  ShararaBluetoothPlatform() : super(token: _token);

  static final Object _token = Object();

  static ShararaBluetoothPlatform _instance = MethodChannelShararaBlu();

  /// The default instance of [ShararaBluetoothPlatform] to use.
  ///
  /// Defaults to [MethodChannelShararaBlu].
  static ShararaBluetoothPlatform get instance => _instance;

  Stream<List<BluetoothDevice>>? get stream ;

  static set instance(ShararaBluetoothPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }



  Future<Stream<List<BluetoothDevice>>?> startDiscovery({final Duration? duration})async{
    throw UnimplementedError("startDiscovery() has not been implemented");
  }

  Future<bool> isDeviceConnected(final BluetoothDevice device);
  Future<bool> isAllServicesDisposed();
  Future<bool> isDiscovering();
  Future<bool> connect(final BluetoothDevice device,{final String uuid ="00001101-0000-1000-8000-00805F9B34FB"});
  Future<bool> forceConnecting(final BluetoothDevice device,{final String uuid ="00001101-0000-1000-8000-00805F9B34FB"});
  Future<bool> disconnect(final BluetoothDevice device);
  Future<bool> writeToDevice(final BluetoothDevice device,{required final List<int> data});
  Future<void> stopAndDisposeAllServices();

  Future<void> cancelDiscovery()async{
    throw UnimplementedError("cancelDiscover() has not been implemented");
  }
}
