#ifndef FLUTTER_PLUGIN_SHARARA_BLUETOOTH_PLUGIN_H_
#define FLUTTER_PLUGIN_SHARARA_BLUETOOTH_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include "src/sharara_bluetooth_handler.h"
#include <memory>

namespace sharara_bluetooth {

class ShararaBluetoothPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  sharara_bluetooth::ShararaBluetoothHandler handler;
  ShararaBluetoothPlugin(flutter::PluginRegistrarWindows *registrar);

  virtual ~ShararaBluetoothPlugin();

  // Disallow copy and assign.
  ShararaBluetoothPlugin(const ShararaBluetoothPlugin&) = delete;
  ShararaBluetoothPlugin& operator=(const ShararaBluetoothPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace sharara_bluetooth

#endif  // FLUTTER_PLUGIN_SHARARA_BLUETOOTH_PLUGIN_H_
