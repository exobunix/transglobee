import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class VoiceRecognitionService {
  dynamic _recognition;
  bool _isListening = false;
  bool get isListening => _isListening;

  void startListening({
    required Function(String text) onResult,
    VoidCallback? onDone,
    Function(String error)? onError,
  }) {
    try {
      final hasRecognition = js.context.hasProperty('webkitSpeechRecognition') || js.context.hasProperty('SpeechRecognition');
      if (!hasRecognition) {
        onError?.call("Web Speech API not supported in this browser");
        return;
      }

      final speechClass = js.context.hasProperty('SpeechRecognition')
          ? js.context['SpeechRecognition']
          : js.context['webkitSpeechRecognition'];

      _recognition = js.JsObject(speechClass);
      _recognition['continuous'] = false;
      _recognition['interimResults'] = true;
      _recognition['lang'] = 'en-IN';

      _recognition['onstart'] = js.allowInterop((_) {
        _isListening = true;
      });

      _recognition['onresult'] = js.allowInterop((event) {
        try {
          final results = event['results'];
          if (results != null && results['length'] > 0) {
            final first = results[0];
            if (first != null && first['length'] > 0) {
              final transcript = first[0]['transcript'];
              if (transcript != null) {
                onResult(transcript.toString());
              }
            }
          }
        } catch (e) {
          debugPrint("Error reading transcript: $e");
        }
      });

      _recognition['onerror'] = js.allowInterop((event) {
        _isListening = false;
        final error = event['error']?.toString() ?? 'Recognition error';
        onError?.call(error);
      });

      _recognition['onend'] = js.allowInterop((_) {
        _isListening = false;
        onDone?.call();
      });

      _recognition.callMethod('start');
    } catch (e) {
      _isListening = false;
      onError?.call("Speech error: $e");
    }
  }

  void stopListening() {
    try {
      if (_recognition != null && _isListening) {
        _recognition.callMethod('stop');
      }
    } catch (_) {}
    _isListening = false;
  }
}
