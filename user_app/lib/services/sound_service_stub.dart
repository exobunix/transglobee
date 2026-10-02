import 'package:flutter/services.dart';

void playNotificationBeep() {
  try {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
  } catch (_) {}
}
