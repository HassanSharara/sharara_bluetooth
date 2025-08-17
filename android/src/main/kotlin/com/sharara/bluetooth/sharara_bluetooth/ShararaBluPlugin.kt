package com.sharara.bluetooth.sharara_bluetooth

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** ShararaBluPlugin */
class ShararaBluPlugin: FlutterPlugin, MethodCallHandler {

  private lateinit var channel : MethodChannel

  private lateinit  var flutterPlugin: FlutterPlugin.FlutterPluginBinding
  private var _bh:BluetoothHandler? = null

  private val  bluetoothHandler:BluetoothHandler
    get() {
      if( _bh == null){
        _bh = BluetoothHandler(flutterPlugin)
      }
      return _bh as BluetoothHandler
    }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    flutterPlugin = flutterPluginBinding
    bluetoothHandler
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "sharara_bluetooth")
    channel.setMethodCallHandler(this)
  }


  override fun onMethodCall(call: MethodCall, result: Result) {
     when (call.method) {
       "stopAndDisposeAllServices" -> {
         _bh?.cleanup()
         _bh = null
       }
       "isAllServicesDisposed" ->{
         result.success(_bh == null)
       }
       else -> {
         bluetoothHandler.onMethodInvoked(call,result)
       }
     }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
