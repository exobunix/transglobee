import 'dart:async';
import 'package:flutter/services.dart';

/// Plays a continuous alert beep sound and haptic vibration in the Driver App
/// whenever a new booking request popup is presented, stopping when accepted/rejected.
class BeepService {
  static Timer? _beepTimer;

  /// Start playing continuous alert beeps at 1.1s intervals.
  static void startBeeping() {
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
    _beepTimer?.cancel();
    _beepTimer = null;
  }
}
