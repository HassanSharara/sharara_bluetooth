#include "sharara_bluetooth_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include "src/sharara_bluetooth_handler.h"
//#include "src/sharara_bluetooth_handler.cpp"
#include <memory>
#include <sstream>

namespace sharara_bluetooth {

// static
void ShararaBluetoothPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "sharara_bluetooth",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<ShararaBluetoothPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
         auto handler = &plugin_pointer->handler;
         handler->call(call,std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

ShararaBluetoothPlugin::ShararaBluetoothPlugin(flutter::PluginRegistrarWindows *registrar):handler(ShararaBluetoothHandler(registrar)) {

}

ShararaBluetoothPlugin::~ShararaBluetoothPlugin() {}


}  // namespace sharara_bluetooth
