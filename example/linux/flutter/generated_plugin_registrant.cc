//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <sharara_bluetooth/sharara_blu_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) sharara_bluetooth_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ShararaBluPlugin");
  sharara_blu_plugin_register_with_registrar(sharara_bluetooth_registrar);
}
