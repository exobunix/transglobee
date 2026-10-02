import 'sound_service_stub.dart' if (dart.library.js_interop) 'sound_service_web.dart' as sound_impl;

class SoundService {
  static void playNotificationBeep() {
    sound_impl.playNotificationBeep();
  }

  static void playAcceptBeep() {
    sound_impl.playNotificationBeep();
  }
}
