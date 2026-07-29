import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/companion/ai_companion_screens.dart';
import 'package:frontend/services/voice_agent_controller.dart';
import 'package:frontend/widgets/voice_assistant_overlay.dart';

void main() {
  testWidgets('Companion home exposes both shared voice entry points', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AiCompanionHomeScreen()));

    expect(find.byKey(const Key('companion-main-microphone')), findsOneWidget);
    expect(find.byKey(const Key('companion-talk-to-saarthi')), findsOneWidget);
  });

  testWidgets('Search with Saarthi exposes the shared microphone', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchWithSaarthiScreen()));

    expect(
      find.byKey(const Key('companion-search-microphone')),
      findsOneWidget,
    );
  });

  testWidgets('Companion surface uses Saarthi theme and typed conversation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VoiceAssistantOverlay(
          surface: VoiceAgentSurface.companion,
          autoStart: false,
          onClose: () {},
          onSubmit: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Talk to Saarthi'), findsOneWidget);
    expect(find.byKey(const Key('voice-typed-input')), findsOneWidget);
    expect(find.byKey(const Key('voice-assistant-image')), findsOneWidget);
  });
}
