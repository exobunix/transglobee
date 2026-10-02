import 'dart:js_interop' as js;

@js.JS('startContinuousChime')
external void _startContinuousChime();

@js.JS('stopContinuousChime')
external void _stopContinuousChime();

@js.JS('playNotificationBeep')
external void _playNotificationBeep([js.JSNumber? durationMs, js.JSNumber? freq1, js.JSNumber? freq2]);

void startBeeping() {
  try {
    _startContinuousChime();
  } catch (_) {}
}

void stopBeeping() {
  try {
    _stopContinuousChime();
  } catch (_) {}
}

void playSingleBeep() {
  try {
    _playNotificationBeep(300.toJS, 880.toJS, 1200.toJS);
  } catch (_) {}
}
