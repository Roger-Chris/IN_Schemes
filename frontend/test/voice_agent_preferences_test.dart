import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/voice_agent_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('migrates old cloud voice labels to private device styles', () async {
    SharedPreferences.setMockInitialValues({'device_assistant_voice': 'marin'});
    expect(await VoiceAgentPreferences.loadVoice(), 'natural');

    SharedPreferences.setMockInitialValues({'device_assistant_voice': 'cedar'});
    expect(await VoiceAgentPreferences.loadVoice(), 'clear');
  });

  test('persists only supported device voice styles', () async {
    SharedPreferences.setMockInitialValues({});

    await VoiceAgentPreferences.saveVoice('clear');
    expect(await VoiceAgentPreferences.loadVoice(), 'clear');
    await expectLater(
      VoiceAgentPreferences.saveVoice('robotic'),
      throwsArgumentError,
    );
  });
}
