//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <dotup_flutter_active_window/dotup_flutter_active_window_plugin.h>
#include <sqlite3_flutter_libs/sqlite3_flutter_libs_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) dotup_flutter_active_window_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "DotupFlutterActiveWindowPlugin");
  dotup_flutter_active_window_plugin_register_with_registrar(dotup_flutter_active_window_registrar);
  g_autoptr(FlPluginRegistrar) sqlite3_flutter_libs_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "Sqlite3FlutterLibsPlugin");
  sqlite3_flutter_libs_plugin_register_with_registrar(sqlite3_flutter_libs_registrar);
}
