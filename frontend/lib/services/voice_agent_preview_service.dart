import 'speech_output_controller.dart';

class VoiceAgentPreviewService {
  static Future<void> preview(String voice) async {
    final speech = NativeSpeechOutputController(preferredVoice: voice);
    try {
      final capabilities = await speech.initialize();
      final englishSpoken = await speech.speak(
        'Hello, I am Saarthi. I can help you find the right government scheme.',
        languageTag: 'en-IN',
      );
      final tamilSpoken =
          capabilities.tamil &&
          await speech.speak(
            'வணக்கம், நான் சாரதி. உங்களுக்கு ஏற்ற அரசுத் திட்டத்தை கண்டுபிடிக்க உதவுகிறேன்.',
            languageTag: 'ta-IN',
          );
      if (!englishSpoken || !tamilSpoken) {
        throw StateError(
          'Install or enable both English and Tamil voices in Android Text-to-speech settings.',
        );
      }
    } finally {
      await speech.dispose();
    }
  }
}
