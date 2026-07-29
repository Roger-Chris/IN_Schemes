import 'package:shared_preferences/shared_preferences.dart';

class VoiceAgentPreferences {
  static const _voiceKey = 'openai_realtime_voice';
  static const defaultVoice = 'marin';
  static const supportedVoices = {'marin', 'cedar'};

  static Future<String> loadVoice() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_voiceKey)?.toLowerCase();
    return supportedVoices.contains(value) ? value! : defaultVoice;
  }

  static Future<void> saveVoice(String voice) async {
    final normalized = voice.toLowerCase();
    if (!supportedVoices.contains(normalized)) {
      throw ArgumentError.value(voice, 'voice', 'Unsupported Realtime voice');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_voiceKey, normalized);
  }
}
