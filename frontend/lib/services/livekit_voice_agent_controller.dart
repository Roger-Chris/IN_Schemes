import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as livekit;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../models/scheme_model.dart';
import 'assistant_session_controller.dart';
import 'voice_agent_controller.dart';

const _defaultAgentName = 'saarthi-agent';
const _tokenFunctionName = 'livekit-token';

@visibleForTesting
const cloudProfileContextTopic = 'in-schemes.profile.v1';

@visibleForTesting
const cloudSchemeResultsAttribute = 'in.schemes.results.v1';

@immutable
class CloudSchemeResult {
  const CloudSchemeResult({
    required this.id,
    required this.code,
    required this.name,
    this.matchConfidence,
    this.isVerified = false,
    this.sourceConfidence = '',
  });

  final String id;
  final String code;
  final String name;
  final int? matchConfidence;
  final bool isVerified;
  final String sourceConfidence;
}

@visibleForTesting
List<CloudSchemeResult> parseCloudSchemeResultsAttribute(String? value) {
  if (value == null || value.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(value);
    if (decoded is! Map || decoded['schema'] != 'in-schemes-results-v1') {
      return const [];
    }
    final rawResults = decoded['results'];
    if (rawResults is! List) return const [];
    final results = <CloudSchemeResult>[];
    for (final raw in rawResults.take(5)) {
      if (raw is! Map) continue;
      String text(String key) => (raw[key] as String? ?? '').trim();
      final result = CloudSchemeResult(
        id: text('id'),
        code: text('code'),
        name: text('name'),
        matchConfidence: raw['match_confidence'] is num
            ? (raw['match_confidence'] as num).round().clamp(0, 100)
            : null,
        isVerified: raw['is_verified'] == true,
        sourceConfidence: text('source_confidence'),
      );
      if (result.id.isNotEmpty ||
          result.code.isNotEmpty ||
          result.name.isNotEmpty) {
        results.add(result);
      }
    }
    return results;
  } on FormatException {
    return const [];
  }
}

List<Scheme> matchCloudSchemeResultsToCatalog(
  List<CloudSchemeResult> results,
  List<Scheme> catalog,
) {
  String normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  final byCode = <String, Scheme>{
    for (final scheme in catalog)
      if (scheme.id.trim().isNotEmpty) normalize(scheme.id): scheme,
    for (final scheme in catalog)
      if (scheme.schemeCode.trim().isNotEmpty)
        normalize(scheme.schemeCode): scheme,
  };
  final byName = <String, Scheme>{
    for (final scheme in catalog)
      if (scheme.name.trim().isNotEmpty) normalize(scheme.name): scheme,
  };
  final matched = <Scheme>[];
  for (final result in results) {
    final scheme =
        byCode[normalize(result.code)] ??
        byCode[normalize(result.id)] ??
        byName[normalize(result.name)];
    if (scheme != null && !matched.any((item) => item.id == scheme.id)) {
      matched.add(scheme);
    }
  }
  return matched;
}

@visibleForTesting
const cloudVoicePreConnectAudio = true;

@visibleForTesting
bool shouldReportCloudListening({
  required bool agentCanListen,
  required bool isMuted,
  required bool isSpeaking,
}) => agentCanListen && !isMuted && !isSpeaking;

@visibleForTesting
Map<String, dynamic> buildCloudProfileMetadata(
  UserProfile profile, {
  DateTime? now,
}) {
  final facts = <String, dynamic>{};

  void addText(String key, String value) {
    final cleaned = value.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();
    if (cleaned.isNotEmpty) {
      facts[key] = cleaned.substring(0, cleaned.length.clamp(0, 80));
    }
  }

  addText('name', profile.name);
  final dob = profile.dob;
  if (dob != null) {
    final today = now ?? DateTime.now();
    var age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age -= 1;
    }
    if (age >= 0 && age <= 120) facts['age'] = age;
  }
  addText('gender', profile.gender);
  addText('state', profile.state);
  addText('district', profile.district);
  addText('community', profile.community);
  addText(
    'education',
    profile.qualification.trim().isNotEmpty
        ? profile.qualification
        : profile.educationLevel,
  );
  addText('employment', profile.employmentStatus);
  if (profile.annualIncome > 0) facts['annualIncome'] = profile.annualIncome;
  addText('disability', profile.disability);
  facts['veteran'] = profile.veteran;

  return {'schema': 'in-schemes-profile-v1', 'profile': facts};
}

/// Adapts the authenticated Supabase function to LiveKit's token-source API.
class SupabaseLiveKitTokenSource implements livekit.TokenSourceConfigurable {
  SupabaseLiveKitTokenSource(this.client);

  final SupabaseClient client;

  @override
  Future<livekit.TokenSourceResponse> fetch(
    livekit.TokenRequestOptions options,
  ) async {
    var session = client.auth.currentSession;
    if (session == null) {
      throw StateError('Sign in to use LiveKit Cloud voice.');
    }
    // A cached Supabase session can still exist after its access token expires.
    // Refresh it before invoking the protected token function; otherwise the
    // 401 was interpreted by the UI as a reason to start the legacy TTS path.
    if (session.isExpired) {
      final refreshed = await client.auth.refreshSession();
      session = refreshed.session;
      if (session == null) {
        throw StateError('Your sign-in session expired. Please sign in again.');
      }
    }

    final response = await client.functions.invoke(
      _tokenFunctionName,
      body: options.toRequest().toJson(),
    );
    final data = response.data;
    if (data is! Map) {
      throw StateError(
        'The LiveKit token service returned an invalid response.',
      );
    }
    return livekit.TokenSourceResponse.fromJson(
      Map<String, dynamic>.from(data),
    );
  }
}

/// Connects the shared voice UI to a deployed LiveKit Agent.
///
/// The companion keeps its existing local assistant session so the overlay can
/// fall back immediately when the user is signed out, offline, or Cloud fails.
class LiveKitVoiceAgentController extends ChangeNotifier
    implements VoiceAgentController {
  LiveKitVoiceAgentController({
    required this.session,
    required this.profile,
    required livekit.TokenSourceConfigurable tokenSource,
    required bool Function() cloudSessionAvailable,
    String agentName = _defaultAgentName,
  }) : _tokenSource = tokenSource,
       _cloudSessionAvailable = cloudSessionAvailable,
       _agentName = agentName;

  static LiveKitVoiceAgentController? tryFromSupabase({
    required AssistantSessionController session,
    required UserProfile profile,
  }) {
    try {
      final client = Supabase.instance.client;
      return LiveKitVoiceAgentController(
        session: session,
        profile: profile,
        tokenSource: SupabaseLiveKitTokenSource(client),
        cloudSessionAvailable: () => client.auth.currentSession != null,
      );
    } catch (_) {
      // Supabase is intentionally absent in isolated widget/unit tests.
      return null;
    }
  }

  @override
  final AssistantSessionController session;
  final UserProfile profile;
  final livekit.TokenSourceConfigurable _tokenSource;
  final bool Function() _cloudSessionAvailable;
  final String _agentName;
  final StreamController<VoiceAgentEvent> _events =
      StreamController<VoiceAgentEvent>.broadcast();
  final Map<String, String> _messageText = {};

  livekit.Session? _liveKitSession;
  livekit.EventsListener<livekit.RoomEvent>? _roomListener;
  String? _lastSchemeResultsState;
  VoiceAgentState _state = const VoiceAgentState();
  Object? _lastError;
  bool _connectedOnce = false;
  bool _closing = false;
  bool _disposed = false;

  @override
  VoiceAgentState get state => _state;

  @override
  Stream<VoiceAgentEvent> get events => _events.stream;

  void _setState(VoiceAgentState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  Future<void> initialize() async {
    if (_disposed) return;
    _setState(
      _state.copyWith(
        phase: VoiceAgentConnectionPhase.initializing,
        clearMessage: true,
      ),
    );
    if (!_cloudSessionAvailable()) {
      _setState(
        _state.copyWith(
          phase: VoiceAgentConnectionPhase.fallback,
          usingCloud: false,
          message: 'Sign in to use cloud voice. Using private on-device voice.',
        ),
      );
      return;
    }

    _ensureSession();
  }

  void _ensureSession() {
    if (_liveKitSession != null) return;
    final cloudSession = livekit.Session.withAgent(
      _agentName,
      tokenSource: _tokenSource,
      // Buffer speech immediately after Ask AI is tapped so the first words
      // are not lost while the token is fetched and the agent joins.
      options: livekit.SessionOptions(
        preConnectAudio: cloudVoicePreConnectAudio,
        room: livekit.Room(
          roomOptions: const livekit.RoomOptions(
            defaultAudioCaptureOptions: livekit.AudioCaptureOptions(
              // Keep WebRTC processing explicit for phone microphones.
              // Enhanced agent-side Voice Focus handles the second pass.
              noiseSuppression: true,
              echoCancellation: true,
              autoGainControl: true,
              voiceIsolation: true,
              typingNoiseDetection: true,
            ),
          ),
        ),
      ),
    );
    cloudSession.addListener(_syncFromLiveKit);
    final listener = cloudSession.room.createListener();
    listener.on<livekit.ParticipantAttributesChanged>((event) {
      final isAgent = cloudSession.room.agentParticipants.any(
        (participant) => participant.identity == event.participant.identity,
      );
      if (isAgent) {
        _emitSchemeResults(
          event.participant.attributes[cloudSchemeResultsAttribute],
        );
      }
    });
    _roomListener = listener;
    _liveKitSession = cloudSession;
  }

  void _emitSchemeResults(String? state) {
    if (state == null || state == _lastSchemeResultsState) return;
    _lastSchemeResultsState = state;
    final results = parseCloudSchemeResultsAttribute(state);
    _events.add(
      VoiceAgentEvent(
        VoiceAgentEventType.schemeResults,
        data: {'results': results},
      ),
    );
  }

  @override
  Future<void> connect() async {
    if (_disposed || !_cloudSessionAvailable()) return;
    _ensureSession();
    final cloudSession = _liveKitSession!;
    _closing = false;
    _lastError = null;
    _setState(
      _state.copyWith(
        phase: VoiceAgentConnectionPhase.connecting,
        usingCloud: true,
        clearMessage: true,
      ),
    );
    await cloudSession.start();
    _syncFromLiveKit();
    if (cloudSession.error != null) {
      throw StateError(cloudSession.error!.message);
    }
    if (!cloudSession.isConnected) {
      throw StateError('LiveKit did not connect to a room.');
    }
    for (final agent in cloudSession.room.agentParticipants) {
      _emitSchemeResults(agent.attributes[cloudSchemeResultsAttribute]);
    }
    await _publishProfileContext(cloudSession);
  }

  Future<void> _publishProfileContext(livekit.Session cloudSession) async {
    // The deployed token already grants reliable data publishing. Wait for the
    // dispatched agent participant, then send only minimized eligibility facts.
    for (var attempt = 0; attempt < 30; attempt += 1) {
      final agents = cloudSession.room.agentParticipants.toList();
      final participant = cloudSession.room.localParticipant;
      if (participant != null && agents.isNotEmpty) {
        try {
          await participant.publishData(
            utf8.encode(jsonEncode(buildCloudProfileMetadata(profile))),
            reliable: true,
            destinationIdentities: agents
                .map((agent) => agent.identity)
                .toList(),
            topic: cloudProfileContextTopic,
          );
        } catch (error) {
          debugPrint('Unable to send saved profile to Saarthi: $error');
        }
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    debugPrint('Saarthi joined without receiving saved profile context.');
  }

  void _syncFromLiveKit() {
    final cloudSession = _liveKitSession;
    if (_disposed || cloudSession == null) return;

    final error = cloudSession.error ?? cloudSession.agent.error;
    if (error != null && error != _lastError) {
      _lastError = error;
      _setState(
        _state.copyWith(
          phase: VoiceAgentConnectionPhase.error,
          usingCloud: false,
          isListening: false,
          isSpeaking: false,
          message: error is livekit.SessionError
              ? error.message
              : (error as livekit.AgentFailure).message,
        ),
      );
      _events.add(
        VoiceAgentEvent(VoiceAgentEventType.fatalError, text: _state.message),
      );
      return;
    }

    final connectionPhase = switch (cloudSession.connectionState) {
      livekit.ConnectionState.connecting =>
        VoiceAgentConnectionPhase.connecting,
      livekit.ConnectionState.connected => VoiceAgentConnectionPhase.connected,
      livekit.ConnectionState.reconnecting =>
        VoiceAgentConnectionPhase.reconnecting,
      livekit.ConnectionState.disconnected =>
        _closing
            ? VoiceAgentConnectionPhase.closed
            : _connectedOnce
            ? VoiceAgentConnectionPhase.error
            : VoiceAgentConnectionPhase.connecting,
    };
    if (cloudSession.connectionState == livekit.ConnectionState.connected) {
      _connectedOnce = true;
    }

    final agentState = cloudSession.agent.agentState;
    final speaking = agentState == livekit.AgentState.speaking;
    final listening = shouldReportCloudListening(
      agentCanListen: cloudSession.agent.canListen,
      isMuted: _state.isMuted,
      isSpeaking: speaking,
    );
    final agentLevel = cloudSession.room.agentParticipants.isEmpty
        ? 0.0
        : cloudSession.room.agentParticipants.first.audioLevel;
    final userLevel = cloudSession.room.localParticipant?.audioLevel ?? 0.0;

    if (speaking != _state.isSpeaking) {
      _events.add(
        VoiceAgentEvent(
          speaking
              ? VoiceAgentEventType.speechStarted
              : VoiceAgentEventType.speechStopped,
        ),
      );
    }

    var inputTranscript = _state.inputTranscript;
    var outputTranscript = _state.outputTranscript;
    for (final message in cloudSession.messages) {
      final previous = _messageText[message.id];
      final current = message.content.text;
      if (previous == current) continue;
      _messageText[message.id] = current;
      switch (message.content) {
        case livekit.UserTranscript():
        case livekit.UserInput():
          inputTranscript = current;
          _events.add(
            VoiceAgentEvent(
              VoiceAgentEventType.inputTranscriptDelta,
              text: current,
            ),
          );
        case livekit.AgentTranscript():
          outputTranscript = current;
          _events.add(
            VoiceAgentEvent(
              VoiceAgentEventType.outputTranscriptDelta,
              text: current,
            ),
          );
      }
    }

    final unexpectedlyDisconnected =
        connectionPhase == VoiceAgentConnectionPhase.error && !_closing;
    _setState(
      _state.copyWith(
        phase: connectionPhase,
        usingCloud: !unexpectedlyDisconnected,
        isListening: listening && !_state.isMuted,
        isSpeaking: speaking,
        inputTranscript: inputTranscript,
        outputTranscript: outputTranscript,
        audioLevel: speaking ? agentLevel : userLevel,
        clearMessage: !unexpectedlyDisconnected,
        message: unexpectedlyDisconnected
            ? 'Cloud voice disconnected unexpectedly.'
            : null,
      ),
    );
    _events.add(
      VoiceAgentEvent(
        VoiceAgentEventType.connection,
        data: {'phase': connectionPhase.name},
      ),
    );
    if (unexpectedlyDisconnected) {
      _events.add(
        const VoiceAgentEvent(
          VoiceAgentEventType.recoverableError,
          text: 'Cloud voice disconnected.',
        ),
      );
    }
  }

  @override
  Future<void> sendText(String text) async {
    final value = text.trim();
    final cloudSession = _liveKitSession;
    if (value.isEmpty || cloudSession == null || !cloudSession.isConnected) {
      return;
    }
    _setState(_state.copyWith(inputTranscript: value, clearMessage: true));
    final sent = await cloudSession.sendText(value);
    if (sent == null && cloudSession.error != null) {
      _syncFromLiveKit();
    }
  }

  @override
  Future<void> setMuted(bool muted) async {
    final localParticipant = _liveKitSession?.room.localParticipant;
    if (localParticipant != null) {
      await localParticipant.setMicrophoneEnabled(!muted);
    }
    _setState(
      _state.copyWith(
        isMuted: muted,
        isListening: muted ? false : _state.isListening,
      ),
    );
  }

  @override
  Future<void> interrupt() => setMuted(false);

  @override
  Future<void> retry() async {
    _liveKitSession?.dismissError();
    await connect();
  }

  @override
  Future<void> close() async {
    if (_disposed) return;
    _closing = true;
    await _liveKitSession?.end();
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
    final cloudSession = _liveKitSession;
    cloudSession?.removeListener(_syncFromLiveKit);
    await _roomListener?.dispose();
    if (cloudSession != null) await cloudSession.dispose();
    _disposed = true;
    await _events.close();
    super.dispose();
  }
}
