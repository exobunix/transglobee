import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:js_interop' as js;

@js.JS('startContinuousChime')
external void _startContinuousChime();

@js.JS('stopContinuousChime')
external void _stopContinuousChime();

@js.JS('playNotificationBeep')
external void _playNotificationBeep([js.JSNumber? durationMs, js.JSNumber? freq1, js.JSNumber? freq2]);

/// Plays a continuous alert chime sound and haptic vibration in the Driver App
/// whenever a new booking request popup is presented, stopping when accepted/rejected.
class BeepService {
  static Timer? _beepTimer;

  /// Start playing continuous alert beeps/chimes.
  static void startBeeping() {
    if (kIsWeb) {
      try {
        _startContinuousChime();
        return;
      } catch (e) {
        debugPrint('Web audio start error: $e');
      }
    }
    if (_beepTimer != null && _beepTimer!.isActive) return;
    _playChime();
    _beepTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      _playChime();
    });
  }

  static void _playChime() {
    try {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Stop beeping immediately.
  static void stopBeeping() {
    if (kIsWeb) {
      try {
        _stopContinuousChime();
      } catch (_) {}
    }
    _beepTimer?.cancel();
    _beepTimer = null;
  }

  /// Play a single beep (e.g., when booking is accepted/completed).
  static void playSingleBeep() {
    if (kIsWeb) {
      try {
        _playNotificationBeep(300.toJS, 880.toJS, 1200.toJS);
        return;
      } catch (_) {}
    }
    _playChime();
  }
}

