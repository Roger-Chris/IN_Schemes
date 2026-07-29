import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/services/assistant_session_controller.dart';
import 'package:frontend/services/scheme_understanding_engine.dart';
import 'package:frontend/services/voice_agent_controller.dart';

class _FakeTransport implements VoiceAgentTransport {
  final controller = StreamController<Map<String, Object?>>.broadcast();
  final sent = <Map<String, Object?>>[];
  bool connected = false;
  bool closed = false;
  bool muted = false;

  @override
  Stream<Map<String, Object?>> get events => controller.stream;

  @override
  Future<void> connect(VoiceAgentTransportConfig config) async {
    connected = true;
    closed = false;
  }

  @override
  Future<void> send(Map<String, Object?> event) async => sent.add(event);

  @override
  Future<void> setMuted(bool value) async => muted = value;

  @override
  Future<void> close() async {
    connected = false;
    closed = true;
  }

  Future<void> dispose() => controller.close();
}

AssistantSessionController _session() => AssistantSessionController(
  engine: const LocalSchemeUnderstandingEngine(),
  schemes: const [],
  profile: UserProfile(),
);

void main() {
  test('typed messages use the active Realtime conversation', () async {
    final transport = _FakeTransport();
    final session = _session();
    final controller = OpenAiRealtimeVoiceAgentController(
      session: session,
      transport: transport,
      surface: VoiceAgentSurface.companion,
      voice: 'marin',
    );

    await controller.connect();
    await controller.sendText('I need help starting a small business');

    expect(controller.state.usingCloud, isTrue);
    expect(transport.sent, hasLength(2));
    expect(transport.sent.first['type'], 'conversation.item.create');
    expect(transport.sent.last['type'], 'response.create');

    await controller.dispose();
    await transport.dispose();
    session.dispose();
  });

  test(
    'transcript, VAD, audio level, and interruption events are typed',
    () async {
      final transport = _FakeTransport();
      final session = _session();
      final controller = OpenAiRealtimeVoiceAgentController(
        session: session,
        transport: transport,
        surface: VoiceAgentSurface.regular,
        voice: 'cedar',
      );
      await controller.connect();

      transport.controller.add({'type': 'input_audio_buffer.speech_started'});
      transport.controller.add({
        'type': 'conversation.item.input_audio_transcription.completed',
        'transcript': 'எனக்கு கல்வி உதவி வேண்டும்',
      });
      transport.controller.add({'type': 'client.audio_level', 'level': 0.72});
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isListening, isTrue);
      expect(controller.state.inputTranscript, 'எனக்கு கல்வி உதவி வேண்டும்');
      expect(controller.state.audioLevel, 0.72);

      await controller.interrupt();
      expect(transport.sent.last['type'], 'response.cancel');
      await controller.dispose();
      await transport.dispose();
      session.dispose();
    },
  );

  test('open details rejects IDs outside current recommendations', () async {
    final transport = _FakeTransport();
    final session = _session();
    var navigationCount = 0;
    final controller = OpenAiRealtimeVoiceAgentController(
      session: session,
      transport: transport,
      surface: VoiceAgentSurface.regular,
      voice: 'marin',
      onOpenScheme: (_) => navigationCount++,
    );
    await controller.connect();

    transport.controller.add({
      'type': 'response.function_call_arguments.done',
      'name': 'open_scheme_details',
      'call_id': 'call-1',
      'arguments': '{"scheme_id":"not-recommended"}',
    });
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(navigationCount, 0);
    final output = transport.sent.singleWhere(
      (event) => event['type'] == 'conversation.item.create',
    );
    expect(
      output.toString(),
      contains('must be from the current recommendation'),
    );
    await controller.dispose();
    await transport.dispose();
    session.dispose();
  });

  test('closing tears down transport and ignores stale callbacks', () async {
    final transport = _FakeTransport();
    final session = _session();
    final controller = OpenAiRealtimeVoiceAgentController(
      session: session,
      transport: transport,
      surface: VoiceAgentSurface.regular,
      voice: 'marin',
    );
    await controller.connect();
    await controller.close();
    transport.controller.add({'type': 'client.audio_level', 'level': 1.0});
    await Future<void>.delayed(Duration.zero);

    expect(transport.closed, isTrue);
    expect(controller.state.phase, VoiceAgentConnectionPhase.closed);
    expect(controller.state.audioLevel, 0);
    await controller.dispose();
    await transport.dispose();
    session.dispose();
  });
}
