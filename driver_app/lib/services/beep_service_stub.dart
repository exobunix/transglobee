import 'dart:async';
import 'package:flutter/services.dart';

Timer? _beepTimer;

void startBeeping() {
  if (_beepTimer != null && _beepTimer!.isActive) return;
  _playChime();
  _beepTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
    _playChime();
  });
}

void _playChime() {
  try {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
  } catch (_) {}
}

void stopBeeping() {
  _beepTimer?.cancel();
  _beepTimer = null;
}

void playSingleBeep() {
  try {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
  } catch (_) {}
}
