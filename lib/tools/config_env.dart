// Test-environment detection for the config getters in `functions.dart`.
//
// `dart:io` is unavailable on the web, so the implementation is picked by a
// conditional import: web builds (JS and WASM) always link the stub, while
// the VM — including every `flutter test` isolate — reads the real process
// environment.
export 'config_env_io.dart' if (dart.library.js_interop) 'config_env_web.dart';
