import 'dart:js_interop' as js;

@js.JS('playNotificationBeep')
external void _playNotificationBeep([js.JSNumber? durationMs, js.JSNumber? freq1, js.JSNumber? freq2]);

void playNotificationBeep() {
  try {
    _playNotificationBeep(350.toJS, 600.toJS, 950.toJS);
  } catch (_) {}
}
