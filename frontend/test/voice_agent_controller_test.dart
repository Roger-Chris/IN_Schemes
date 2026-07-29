import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/services/assistant_session_controller.dart';
import 'package:frontend/services/scheme_understanding_engine.dart';
import 'package:frontend/services/voice_agent_controller.dart';

void main() {
  test('local controller never enters a cloud session', () async {
    final session = AssistantSessionController(
      engine: const LocalSchemeUnderstandingEngine(),
      schemes: const [],
      profile: UserProfile(),
    );
    final controller = LocalVoiceAgentController(session: session);

    await controller.initialize();
    await controller.connect();

    expect(controller.state.usingCloud, isFalse);
    expect(controller.state.phase, VoiceAgentConnectionPhase.fallback);
    expect(controller.state.message, contains('on-device'));
    await controller.dispose();
    session.dispose();
  });

  test('typed text uses the same private assistant session', () async {
    final session = AssistantSessionController(
      engine: const LocalSchemeUnderstandingEngine(),
      schemes: const [],
      profile: UserProfile(),
    );
    final controller = LocalVoiceAgentController(session: session);

    await controller.sendText('I need a scholarship');

    expect(controller.state.inputTranscript, 'I need a scholarship');
    expect(session.state.statement, 'I need a scholarship');
    expect(controller.state.usingCloud, isFalse);
    await controller.dispose();
    session.dispose();
  });
}
