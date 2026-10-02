import 'beep_service_stub.dart' if (dart.library.js_interop) 'beep_service_web.dart' as beep_impl;

class BeepService {
  static void startBeeping() => beep_impl.startBeeping();
  static void stopBeeping() => beep_impl.stopBeeping();
  static void playSingleBeep() => beep_impl.playSingleBeep();
}
