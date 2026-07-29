import 'speech_output_controller.dart';

class VoiceAgentPreviewService {
  static Future<void> preview(String voice) async {
    final speech = NativeSpeechOutputController();
    try {
      final spoken = await speech.speak(
        'Hello, I am Saarthi. I can help you find the right government scheme.',
        languageTag: 'en-IN',
      );
      if (!spoken) {
        throw StateError(
          'Install or enable an English text-to-speech voice on this phone.',
        );
      }
    } finally {
      await speech.dispose();
    }
  }
}
