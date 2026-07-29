import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/scheme_model.dart';
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

@immutable
class VoiceAgentTransportConfig {
  const VoiceAgentTransportConfig({required this.surface, required this.voice});

  final VoiceAgentSurface surface;
  final String voice;
}

abstract interface class VoiceAgentTransport {
  Stream<Map<String, Object?>> get events;
  Future<void> connect(VoiceAgentTransportConfig config);
  Future<void> send(Map<String, Object?> event);
  Future<void> setMuted(bool muted);
  Future<void> close();
}

/// Compile-time gate. Enable only with a protected, configured Edge Function:
/// `flutter run --dart-define=OPENAI_REALTIME_ENABLED=true`.
const bool openAiRealtimeEnabled = bool.fromEnvironment(
  'OPENAI_REALTIME_ENABLED',
  defaultValue: false,
);

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
        message: openAiRealtimeEnabled
            ? 'Cloud voice is unavailable. Using private on-device voice.'
            : 'Using private on-device voice.',
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

class OpenAiRealtimeVoiceAgentController extends ChangeNotifier
    implements VoiceAgentController {
  OpenAiRealtimeVoiceAgentController({
    required this.session,
    required VoiceAgentTransport transport,
    required this.surface,
    required this.voice,
    this.onOpenScheme,
  }) : _transport = transport;

  @override
  final AssistantSessionController session;
  final VoiceAgentTransport _transport;
  final VoiceAgentSurface surface;
  final String voice;
  final ValueChanged<Scheme>? onOpenScheme;
  final StreamController<VoiceAgentEvent> _events =
      StreamController<VoiceAgentEvent>.broadcast();
  static OpenAiRealtimeVoiceAgentController? _activeController;
  StreamSubscription<Map<String, Object?>>? _transportSubscription;
  VoiceAgentState _state = const VoiceAgentState();
  int _generation = 0;
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

  void _emit(VoiceAgentEvent event) {
    if (!_disposed) _events.add(event);
  }

  @override
  Future<void> initialize() async {
    if (_transportSubscription != null) return;
    _setState(_state.copyWith(phase: VoiceAgentConnectionPhase.initializing));
    _transportSubscription = _transport.events.listen(
      _handleTransportEvent,
      onError: (Object error) => _fail(error.toString(), fatal: false),
    );
  }

  @override
  Future<void> connect() async {
    final previous = _activeController;
    if (previous != null && !identical(previous, this)) {
      await previous.close();
    }
    _activeController = this;
    await initialize();
    final generation = ++_generation;
    _setState(
      _state.copyWith(
        phase: VoiceAgentConnectionPhase.connecting,
        clearMessage: true,
      ),
    );
    try {
      await _transport.connect(
        VoiceAgentTransportConfig(surface: surface, voice: voice),
      );
      if (_disposed || generation != _generation) return;
      _setState(
        _state.copyWith(
          phase: VoiceAgentConnectionPhase.connected,
          usingCloud: true,
          isListening: true,
        ),
      );
      _emit(
        const VoiceAgentEvent(
          VoiceAgentEventType.connection,
          text: 'connected',
        ),
      );
    } catch (error) {
      if (_disposed || generation != _generation) return;
      _fail('Cloud voice could not connect. $error', fatal: false);
      rethrow;
    }
  }

  @override
  Future<void> sendText(String text) async {
    final value = text.trim();
    if (value.isEmpty) return;
    _setState(_state.copyWith(inputTranscript: value, clearMessage: true));
    await _transport.send({
      'type': 'conversation.item.create',
      'item': {
        'type': 'message',
        'role': 'user',
        'content': [
          {'type': 'input_text', 'text': value},
        ],
      },
    });
    await _transport.send({'type': 'response.create'});
  }

  @override
  Future<void> setMuted(bool muted) async {
    await _transport.setMuted(muted);
    _setState(_state.copyWith(isMuted: muted, isListening: !muted));
  }

  @override
  Future<void> interrupt() async {
    await _transport.send({'type': 'response.cancel'});
    _setState(_state.copyWith(isSpeaking: false, outputTranscript: ''));
  }

  @override
  Future<void> retry() async {
    await _transport.close();
    await connect();
  }

  @override
  Future<void> close() async {
    _generation++;
    await _transport.close();
    if (identical(_activeController, this)) _activeController = null;
    _setState(
      _state.copyWith(
        phase: VoiceAgentConnectionPhase.closed,
        usingCloud: false,
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
    await _transportSubscription?.cancel();
    _disposed = true;
    await _events.close();
    super.dispose();
  }

  void _handleTransportEvent(Map<String, Object?> event) {
    if (_disposed || _state.phase == VoiceAgentConnectionPhase.closed) return;
    final type = event['type'] as String? ?? '';
    switch (type) {
      case 'input_audio_buffer.speech_started':
        _setState(_state.copyWith(isListening: true, isSpeaking: false));
        _emit(const VoiceAgentEvent(VoiceAgentEventType.speechStarted));
      case 'input_audio_buffer.speech_stopped':
        _setState(_state.copyWith(isListening: false));
        _emit(const VoiceAgentEvent(VoiceAgentEventType.speechStopped));
      case 'conversation.item.input_audio_transcription.delta':
        _appendInput(event['delta'] as String? ?? '', done: false);
      case 'conversation.item.input_audio_transcription.completed':
        _appendInput(event['transcript'] as String? ?? '', done: true);
      case 'response.output_audio_transcript.delta':
      case 'response.audio_transcript.delta':
        _appendOutput(event['delta'] as String? ?? '', done: false);
      case 'response.output_audio_transcript.done':
      case 'response.audio_transcript.done':
        _appendOutput(event['transcript'] as String? ?? '', done: true);
      case 'response.output_audio.delta':
      case 'response.audio.delta':
        _setState(_state.copyWith(isSpeaking: true));
      case 'response.done':
        _setState(_state.copyWith(isSpeaking: false));
      case 'response.function_call_arguments.done':
        unawaited(_executeTool(event));
      case 'rate_limits.updated':
        _emit(VoiceAgentEvent(VoiceAgentEventType.rateLimits, data: event));
      case 'client.audio_level':
        final level = (event['level'] as num?)?.toDouble() ?? 0;
        _setState(_state.copyWith(audioLevel: level.clamp(0, 1)));
        _emit(VoiceAgentEvent(VoiceAgentEventType.audioLevel, value: level));
      case 'error':
        final error = event['error'];
        final message = error is Map
            ? error['message']?.toString() ?? 'Realtime voice error.'
            : 'Realtime voice error.';
        _fail(message, fatal: false);
    }
  }

  void _appendInput(String value, {required bool done}) {
    final next = done ? value : '${_state.inputTranscript}$value';
    _setState(_state.copyWith(inputTranscript: next));
    _emit(
      VoiceAgentEvent(
        done
            ? VoiceAgentEventType.inputTranscriptDone
            : VoiceAgentEventType.inputTranscriptDelta,
        text: next,
      ),
    );
  }

  void _appendOutput(String value, {required bool done}) {
    final next = done ? value : '${_state.outputTranscript}$value';
    _setState(_state.copyWith(outputTranscript: next, isSpeaking: !done));
    _emit(
      VoiceAgentEvent(
        done
            ? VoiceAgentEventType.outputTranscriptDone
            : VoiceAgentEventType.outputTranscriptDelta,
        text: next,
      ),
    );
  }

  Future<void> _executeTool(Map<String, Object?> event) async {
    final name = event['name'] as String? ?? '';
    final callId = event['call_id'] as String? ?? '';
    if (callId.isEmpty) return;
    _emit(VoiceAgentEvent(VoiceAgentEventType.toolStarted, text: name));
    Map<String, Object?> output;
    try {
      final raw = event['arguments'] as String? ?? '{}';
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Tool arguments must be an object.');
      }
      output = switch (name) {
        'recommend_schemes' => await _recommend(decoded),
        'open_scheme_details' => _openDetails(decoded),
        _ => throw FormatException('Unknown tool: $name'),
      };
    } catch (error) {
      output = {'ok': false, 'error': error.toString()};
    }
    await _transport.send({
      'type': 'conversation.item.create',
      'item': {
        'type': 'function_call_output',
        'call_id': callId,
        'output': jsonEncode(output),
      },
    });
    if (name == 'recommend_schemes') {
      await _transport.send({'type': 'response.create'});
    }
    _emit(VoiceAgentEvent(VoiceAgentEventType.toolFinished, text: name));
  }

  Future<Map<String, Object?>> _recommend(Map<String, dynamic> args) async {
    final need = (args['interpreted_need'] ?? args['statement'])
        ?.toString()
        .trim();
    if (need == null || need.isEmpty || need.length > 1200) {
      throw const FormatException('A concise interpreted_need is required.');
    }
    if (session.state.question != null) {
      await session.answer(need);
    } else {
      await session.start(need);
    }
    final state = session.state;
    return {
      'ok': true,
      'recommendations': state.recommendations
          .take(3)
          .map((recommendation) {
            final scheme = recommendation.scheme;
            return {
              'id': scheme.id,
              'name': scheme.name,
              'match_state': recommendation.state.name,
              'reasons': recommendation.reasons,
              'unknown_requirements': recommendation.unknownRequirements,
              'official_url': scheme.officialWebsite.isNotEmpty
                  ? scheme.officialWebsite
                  : scheme.sourceUrl,
            };
          })
          .toList(growable: false),
      'next_follow_up': state.question?.text(tamilLanguage: state.isTamil),
      'facts_are_unconfirmed': true,
    };
  }

  Map<String, Object?> _openDetails(Map<String, dynamic> args) {
    final id = args['scheme_id']?.toString();
    final allowed = session.state.recommendations
        .map((item) => item.scheme)
        .where((scheme) => scheme.id == id)
        .toList(growable: false);
    if (allowed.length != 1) {
      throw const FormatException(
        'scheme_id must be from the current recommendation set.',
      );
    }
    onOpenScheme?.call(allowed.single);
    return {'ok': true, 'opened_scheme_id': id};
  }

  void _fail(String message, {required bool fatal}) {
    _generation++;
    unawaited(_transport.close());
    _setState(
      _state.copyWith(
        phase: fatal
            ? VoiceAgentConnectionPhase.error
            : VoiceAgentConnectionPhase.fallback,
        usingCloud: false,
        isListening: false,
        isSpeaking: false,
        message: message,
      ),
    );
    _emit(
      VoiceAgentEvent(
        fatal
            ? VoiceAgentEventType.fatalError
            : VoiceAgentEventType.recoverableError,
        text: message,
      ),
    );
  }
}
