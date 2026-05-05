import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  final ValueNotifier<String?> currentlyPlaying = ValueNotifier(null);
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    _initialized = true;
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() => currentlyPlaying.value = null);
    _tts.setCancelHandler(() => currentlyPlaying.value = null);
    _tts.setErrorHandler((msg) => currentlyPlaying.value = null);
  }

  Future<void> speak(String text, String articleId) async {
    await _ensureInit();
    if (currentlyPlaying.value == articleId) {
      await stop();
      return;
    }
    await stop();
    currentlyPlaying.value = articleId;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    currentlyPlaying.value = null;
    await _tts.stop();
  }

  Future<void> speakBriefing(List<String> headlines) async {
    await _ensureInit();
    await stop();
    currentlyPlaying.value = '__briefing__';
    final script = headlines.asMap().entries.map((e) =>
      'Story ${e.key + 1}. ${e.value}'
    ).join('. Next. ');
    await _tts.speak('Your NewsSense briefing. $script. End of briefing.');
  }
}
