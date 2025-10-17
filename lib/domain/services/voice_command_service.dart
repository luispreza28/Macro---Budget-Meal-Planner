import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

final voiceCommandServiceProvider = Provider<VoiceCommandService>((_) => VoiceCommandService());

class VoiceCommandService {
  final _stt = stt.SpeechToText();
  bool _ready = false;

  Future<bool> init() async {
    _ready = await _stt.initialize(onError: (e) {
      if (kDebugMode) debugPrint('[Voice] $e');
    });
    return _ready;
  }

  Future<void> listen(void Function(String) onPhrase) async {
    if (!_ready) await init();
    await _stt.listen(
      onResult: (r) {
        final phrase = (r.recognizedWords).toLowerCase().trim();
        if (phrase.isNotEmpty) onPhrase(phrase);
      },
      listenMode: stt.ListenMode.confirmation,
      partialResults: true,
    );
  }

  Future<void> stop() => _stt.stop();
}

