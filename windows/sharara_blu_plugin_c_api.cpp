#include "include/sharara_bluetooth/sharara_bluetooth_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "sharara_bluetooth_plugin.h"

void ShararaBluPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  sharara_bluetooth::ShararaBluPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
