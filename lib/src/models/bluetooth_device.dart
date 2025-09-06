
import '../../sharara_bluetooth_platform_interface.dart';
import 'errors.dart';

final class BluetoothDevice {
    String? name,address;
    int? type;

    BluetoothDevice.fromParsed(final dynamic data){
      if( data is! Map || !data.containsKey("address")) throw DeviceBuildingException("10","invalid data ${data.runtimeType}","could not format BluetoothDevice Model cause data: ${data.runtimeType} $data");
      name = data['name'];
      address = data['address'];
      type = int.tryParse(data['type'].toString());
    }
    Future<bool> get isConnected async => await ShararaBluetoothPlatform.instance.isDeviceConnected(this);
    Future<bool>  disconnect() async => ShararaBluetoothPlatform.instance.disconnect(this);
    Future<bool>  connect() async => ShararaBluetoothPlatform.instance.connect(this);
    Future<bool> writeData(final dynamic data)async{
      if( !await isConnected )return false;
      return ShararaBluetoothPlatform.instance.writeToDevice(this, data: data);
    }
 }