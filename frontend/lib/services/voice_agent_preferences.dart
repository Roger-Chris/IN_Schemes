import 'package:shared_preferences/shared_preferences.dart';

class VoiceAgentPreferences {
  static const _voiceKey = 'device_assistant_voice';
  static const defaultVoice = 'natural';
  static const supportedVoices = {'natural', 'clear'};

  static Future<String> loadVoice() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_voiceKey)?.toLowerCase();
    // Migrate the previous cloud-voice labels without losing user intent.
    if (value == 'marin') return 'natural';
    if (value == 'cedar') return 'clear';
    return supportedVoices.contains(value) ? value! : defaultVoice;
  }

  static Future<void> saveVoice(String voice) async {
    final normalized = voice.toLowerCase();
    if (!supportedVoices.contains(normalized)) {
      throw ArgumentError.value(
        voice,
        'voice',
        'Unsupported device voice style',
      );
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_voiceKey, normalized);
  }
}
