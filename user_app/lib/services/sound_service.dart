import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:js_interop' as js;

@js.JS('playNotificationBeep')
external void _playNotificationBeep([js.JSNumber? durationMs, js.JSNumber? freq1, js.JSNumber? freq2]);

class SoundService {
  /// Play a crisp, pleasant notification beep (e.g. when driver accepts a ride).
  static void playAcceptBeep() {
    if (kIsWeb) {
      try {
        _playNotificationBeep(350.toJS, 600.toJS, 950.toJS);
        return;
      } catch (e) {
        debugPrint('Web audio beep error: $e');
      }
    }
    try {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
