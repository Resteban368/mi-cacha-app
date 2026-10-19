// Web Push solo existe en web: el resto de plataformas usa el stub.
// Ambas exportan createBrowserPush(). dart.library.html solo existe en web:
// en Android/iOS no se carga el código del navegador.
export 'browser_push_contract.dart';
export 'browser_push_stub.dart' if (dart.library.html) 'browser_push_web.dart';
