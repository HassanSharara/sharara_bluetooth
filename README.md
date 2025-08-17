# sharara_bluetooth

Sharara Bluetooth is a **Flutter plugin** that provides support for **classic Bluetooth (RFCOMM/SPP)** connections on Android.  
It allows apps to **scan for nearby devices, connect, exchange raw data, and manage Bluetooth connections** with ease.

> ⚠️ **Note:** Classic Bluetooth is **not available on iOS**, since Apple restricts direct access to generic SPP/RFCOMM profiles. This plugin currently works on **Android only**.

---

## ✨ Features
- Scan for nearby Bluetooth devices.
- Connect to devices using **classic Bluetooth (RFCOMM/SPP)**.
- Send and receive raw data over the connection.
- Manage connection states (connected/disconnected).
- Handle Bluetooth adapter status (enabled/disabled).

---

## 📦 Installation

Add the dependency in your `pubspec.yaml`:

```yaml
dependencies:
  sharara_bluetooth: ^1.0.0
```

## Example code
 connecting to bluetooth device and write data to it 
```dart

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sharara_bluetooth/sharara_bluetooth.dart';
void main(){
  WidgetsFlutterBinding.ensureInitialized();

  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:FirstScreen(),
    );
  }
}


class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});
  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  Stream<dynamic>? _stream;
  bool f =false;

  CapabilityProfile? capabilityProfile;
  Future<Stream<dynamic>?>launchFuture()async{
    if(f)return _stream;
    f = true;
    _stream = await ShararaBluetooth.instance.startDiscovery();
    return _stream;
  }

  Future<CapabilityProfile> get cp async => capabilityProfile??= await CapabilityProfile.load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:FutureBuilder(future: launchFuture(),
          builder: (context,s){
         if( _stream == null ){
           return Center(child: Text("stream is not initiated yet"),);
         }
          return StreamBuilder(stream: _stream,
              builder: (BuildContext context,final snapshot){

            final data  = snapshot.data;
            return ListView(
                 children: [
                   ElevatedButton(onPressed:()async{
                     await ShararaBluetooth.instance.startDiscovery();
                   }, child:
                    Text("start discovery")
                   ),
                   const SizedBox(height:10,),
                   ElevatedButton(onPressed:()async{
                     await ShararaBluetooth.instance.cancelDiscovery();
                   }, child:
                    Text("cancel discovery")
                   ),
                   const SizedBox(height:10,),

                   if(data is List)
                     for(final BluetoothDevice device in data)
                       Container(
                         margin:const EdgeInsets.symmetric(vertical:5,horizontal:3),
                         decoration:BoxDecoration(
                              color:Theme.of(context).canvasColor,
                             borderRadius:BorderRadius.circular(15),
                           boxShadow: [
                             BoxShadow(
                               color:Colors.black.withValues(alpha: 0.2),
                               spreadRadius: 1,
                               blurRadius:7
                             )
                           ]
                         ),
                         child:Column(
                           children: [

                             Text("name : ${device.name}"),
                             Text("address : ${device.address}"),
                             FutureBuilder(future: device.isConnected,
                                 builder: (c,s){
                                   return Text("isConnected : ${s.data}");
                                 }),

                             Row(
                               mainAxisAlignment:MainAxisAlignment.spaceAround,
                               children: [


                                 ElevatedButton(onPressed: ()async{
                                   await device.connect();
                                 }, child: Text("connect")),


                                 ElevatedButton(onPressed: device.disconnect, child: Text("disconnect")),


                                 ElevatedButton(onPressed: ()async{
                                   final generator = Generator(PaperSize.mm72,await cp);
                                   final List<int> bytes = [];
                                   bytes.addAll(generator.text("test\nhello"));
                                   bytes.addAll(generator.emptyLines(2));
                                   if(kDebugMode)print(await device.writeData(bytes));
                                 }, child: Text("write data")),
                               ],
                             )
                           ],
                         ),
                       )

                 ],
               );
            });
          }),
    );
  }
}


```