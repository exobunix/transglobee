import 'package:flutter/foundation.dart';

class VoiceRecognitionService {
  bool get isListening => false;
  void startListening({
    required Function(String text) onResult,
    VoidCallback? onDone,
    Function(String error)? onError,
  }) {
    onError?.call("Speech recognition not supported on this platform");
  }

  void stopListening() {}
}
