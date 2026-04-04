import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sharara_bluetooth/sharara_bluetooth.dart';
import 'package:sharara_bluetooth/sharara_bluetooth_platform_interface.dart';



/// An implementation of [ShararaBluetoothPlatform] that uses method channels.
class  MethodChannelShararaBlu extends ShararaBluetoothPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sharara_bluetooth');

  final EventChannel devicesEventChannel = EventChannel("sharara_bluetooth/devices");


  StreamController<List<BluetoothDevice>>? _stream;
  @override
  Stream<List<BluetoothDevice>>? get stream => _stream?.stream;

  @override
  Future<Stream<List<BluetoothDevice>>?> startDiscovery({final Duration? duration})async{
    if(!await requestBluetoothPermissions())return null;
    methodChannel.invokeMethod("startDiscovery");
    if( duration != null && ! await isAllServicesDisposed() ) {
      Future.delayed(duration).then((_)async{
        if( await isAllServicesDisposed())return;
        cancelDiscovery();
      });
    }
    if(_stream != null ) {
      return _stream!.stream;
    }
    _stream = StreamController();

    try {
  devicesEventChannel.receiveBroadcastStream().listen((data){
      if(data is! List)return;
      lastSeenDevices.clear();
      for(final dynamic data in data){
        try {
          final BluetoothDevice device = BluetoothDevice.fromParsed(data);
          lastSeenDevices.add(device);
        }catch(_){}

        continue;
      }
      _stream!.sink.add(lastSeenDevices);

    });
    return _stream!.stream;
    }
    catch(e){
      return null;
    }

  }

  @override
  Future<void> cancelDiscovery()async{
    methodChannel.invokeMethod("cancelDiscovery");
  }


  @override
  Future<bool> disconnect(BluetoothDevice device) async{
    final dynamic res =  await methodChannel.invokeMethod("disconnect",{
      "address":device.address,
    });
    cancelDiscovery();
    startDiscovery();
    return  res == true;
  }

  @override
  Future<bool> isDeviceConnected(BluetoothDevice device)async {
    final dynamic res =  await methodChannel.invokeMethod("isDeviceConnected",{
      "address":device.address,
    });
    return  res == true;
  }

  @override
  Future<void> stopAndDisposeAllServices() async {
    _stream?.close();
    _stream = null;
    await methodChannel.invokeMethod("stopAndDisposeAllServices");
  }

  @override
  Future<bool> writeToDevice(BluetoothDevice device,{required final List<int> data}) async {
    final dynamic res  = await methodChannel.invokeMethod("writeToDevice",
      {
        "address":device.address,
        "data":data
      }
    );
    return res == true;
  }

  @override
  Future<bool> connect(BluetoothDevice device, {final String uuid = "00001101-0000-1000-8000-00805F9B34FB"}) async{
   final dynamic res =  await methodChannel.invokeMethod("connect",{
      "address":device.address,
      "uuid":uuid,
    });
     await cancelDiscovery();
     await startDiscovery();
    final bool r = res is bool && res == true;
    return r;
  }


  @override
  Future<bool> forceConnecting(BluetoothDevice device, {final String uuid = "00001101-0000-1000-8000-00805F9B34FB"}) async{
   final dynamic res =  await methodChannel.invokeMethod("forceConnecting",{
      "address":device.address,
      "uuid":uuid,
    });
     await cancelDiscovery();
     await startDiscovery();
    final bool r = res is bool && res == true;
    return r;
  }

  @override
  Future<bool> isAllServicesDisposed() async {
    return await methodChannel.invokeMethod("isAllServicesDisposed") == true;
  }


  @override
  Future<bool> isDiscovering() async {
    return await methodChannel.invokeMethod("isDiscovering") == true;
  }

  Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      if (await _isAndroid12OrAbove()) {
        var scan = await Permission.bluetoothScan.request();
        var connect = await Permission.bluetoothConnect.request();
        var location = await Permission.locationWhenInUse.request(); // Some devices still need it
        return scan.isGranted && connect.isGranted && location.isGranted;
      } else {
        var location = await Permission.locationWhenInUse.request();
        return location.isGranted;
      }
    }
    return true; // Non-Android
  }

  Future<bool> _isAndroid12OrAbove() async {
    return (await Permission.bluetoothScan.status).isDenied || (await Permission.bluetoothScan.status).isGranted;
  }

}
