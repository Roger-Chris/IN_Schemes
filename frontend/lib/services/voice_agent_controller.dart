import 'dart:async';

import 'package:flutter/foundation.dart';

import 'assistant_session_controller.dart';

enum VoiceAgentSurface { regular, companion }

enum VoiceAgentConnectionPhase {
  idle,
  initializing,
  connecting,
  connected,
  reconnecting,
  fallback,
  closed,
  error,
}

enum VoiceAgentEventType {
  connection,
  speechStarted,
  speechStopped,
  inputTranscriptDelta,
  inputTranscriptDone,
  outputTranscriptDelta,
  outputTranscriptDone,
  audioLevel,
  toolStarted,
  toolFinished,
  rateLimits,
  recoverableError,
  fatalError,
}

@immutable
class VoiceAgentEvent {
  const VoiceAgentEvent(this.type, {this.text, this.value, this.data});

  final VoiceAgentEventType type;
  final String? text;
  final double? value;
  final Map<String, Object?>? data;
}

@immutable
class VoiceAgentState {
  const VoiceAgentState({
    this.phase = VoiceAgentConnectionPhase.idle,
    this.isListening = false,
    this.isSpeaking = false,
    this.isMuted = false,
    this.usingCloud = false,
    this.inputTranscript = '',
    this.outputTranscript = '',
    this.audioLevel = 0,
    this.message,
  });

  final VoiceAgentConnectionPhase phase;
  final bool isListening;
  final bool isSpeaking;
  final bool isMuted;
  final bool usingCloud;
  final String inputTranscript;
  final String outputTranscript;
  final double audioLevel;
  final String? message;

  VoiceAgentState copyWith({
    VoiceAgentConnectionPhase? phase,
    bool? isListening,
    bool? isSpeaking,
    bool? isMuted,
    bool? usingCloud,
    String? inputTranscript,
    String? outputTranscript,
    double? audioLevel,
    String? message,
    bool clearMessage = false,
  }) => VoiceAgentState(
    phase: phase ?? this.phase,
    isListening: isListening ?? this.isListening,
    isSpeaking: isSpeaking ?? this.isSpeaking,
    isMuted: isMuted ?? this.isMuted,
    usingCloud: usingCloud ?? this.usingCloud,
    inputTranscript: inputTranscript ?? this.inputTranscript,
    outputTranscript: outputTranscript ?? this.outputTranscript,
    audioLevel: audioLevel ?? this.audioLevel,
    message: clearMessage ? null : message ?? this.message,
  );
}

abstract interface class VoiceAgentController implements Listenable {
  VoiceAgentState get state;
  AssistantSessionController get session;
  Stream<VoiceAgentEvent> get events;

  Future<void> initialize();
  Future<void> connect();
  Future<void> sendText(String text);
  Future<void> setMuted(bool muted);
  Future<void> interrupt();
  Future<void> retry();
  Future<void> close();
  Future<void> dispose();
}

/// Shared controller boundary for both visual surfaces.
///
/// Speech recognition and speech output remain native and sequential. Text is
/// sent into the same private assistant session as voice transcripts, while
/// statement understanding is delegated to the optional on-device SLM.
class LocalVoiceAgentController extends ChangeNotifier
    implements VoiceAgentController {
  LocalVoiceAgentController({required this.session});

  @override
  final AssistantSessionController session;
  final StreamController<VoiceAgentEvent> _events =
      StreamController<VoiceAgentEvent>.broadcast();
  VoiceAgentState _state = const VoiceAgentState();
  bool _disposed = false;

  @override
  VoiceAgentState get state => _state;

  @override
  Stream<VoiceAgentEvent> get events => _events.stream;

  void _setState(VoiceAgentState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  Future<void> initialize() async {
    _setState(_state.copyWith(phase: VoiceAgentConnectionPhase.initializing));
  }

  @override
  Future<void> connect() async {
    _setState(
      _state.copyWith(
        phase: VoiceAgentConnectionPhase.fallback,
        usingCloud: false,
        message: 'Using private on-device voice and Edge AI.',
      ),
    );
  }

  @override
  Future<void> sendText(String text) async {
    final value = text.trim();
    if (value.isEmpty) return;
    _setState(_state.copyWith(inputTranscript: value, clearMessage: true));
    if (session.state.question != null) {
      await session.answer(value);
    } else {
      await session.start(value);
    }
    final reply = session.state.reply?.displayText ?? '';
    if (reply.isNotEmpty) {
      _setState(_state.copyWith(outputTranscript: reply));
      _events.add(
        VoiceAgentEvent(VoiceAgentEventType.outputTranscriptDone, text: reply),
      );
    }
  }

  @override
  Future<void> setMuted(bool muted) async {
    _setState(_state.copyWith(isMuted: muted));
  }

  @override
  Future<void> interrupt() async {}

  @override
  Future<void> retry() => connect();

  @override
  Future<void> close() async {
    session.cancel();
    _setState(
      _state.copyWith(
        phase: VoiceAgentConnectionPhase.closed,
        isListening: false,
        isSpeaking: false,
        audioLevel: 0,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await close();
    _disposed = true;
    await _events.close();
    super.dispose();
  }
}
