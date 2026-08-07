import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/scheme_model.dart';
import '../models/localized_scheme.dart';
import '../models/user_profile.dart';
import '../services/assistant_session_controller.dart';
import '../services/edge_slm_understanding_engine.dart';
import '../services/intelligent_scheme_search.dart';
import '../services/livekit_voice_agent_controller.dart';
import '../services/official_grounded_search.dart';
import '../services/private_ai_knowledge_base.dart';
import '../services/scheme_understanding_engine.dart';
import '../services/speech_output_controller.dart';
import '../services/voice_recognition_controller.dart';
import '../services/voice_agent_controller.dart';
import '../services/centralized_translator.dart';
import '../utils/responsive.dart';
import '../l10n/l10n.dart';

enum _VoiceAssistantPhase {
  starting,
  listening,
  processing,
  ready,
  unavailable,
}

enum VoiceInputLanguage { english, tamil }

enum VoiceEdgeActivity { idle, listening, processing, speaking }

enum _OnlineGroundingPhase { idle, checking, found, unavailable, noSources }

enum _VoiceTranscriptSpeaker { user, assistant }

@immutable
class _VoiceTranscriptTurn {
  const _VoiceTranscriptTurn({
    required this.id,
    required this.speaker,
    required this.text,
  });

  final String id;
  final _VoiceTranscriptSpeaker speaker;
  final String text;

  _VoiceTranscriptTurn copyWith({String? text}) =>
      _VoiceTranscriptTurn(id: id, speaker: speaker, text: text ?? this.text);
}

class VoiceAssistantOverlay extends StatefulWidget {
  const VoiceAssistantOverlay({
    super.key,
    required this.onClose,
    required this.onSubmit,
    this.schemes = const [],
    this.profile,
    this.onProfileConfirmed,
    this.onSearch,
    this.onSchemeSelected,
    this.recognitionController,
    this.speechOutputController,
    this.understandingEngine,
    this.sessionController,
    this.voiceAgentController,
    this.groundedSearch,
    this.surface = VoiceAgentSurface.regular,
    this.initialText,
    this.autoStart = true,
  });

  final VoidCallback onClose;
  final ValueChanged<String> onSubmit;
  final List<Scheme> schemes;
  final UserProfile? profile;
  final ValueChanged<UserProfile>? onProfileConfirmed;
  final Future<List<SchemeSearchMatch>> Function(String query)? onSearch;
  final ValueChanged<Scheme>? onSchemeSelected;
  final VoiceRecognitionController? recognitionController;
  final SpeechOutputController? speechOutputController;
  final SchemeUnderstandingEngine? understandingEngine;
  final AssistantSessionController? sessionController;
  final VoiceAgentController? voiceAgentController;
  final OfficialGroundedSearch? groundedSearch;
  final VoiceAgentSurface surface;
  final String? initialText;
  final bool autoStart;

  @override
  State<VoiceAssistantOverlay> createState() => _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends State<VoiceAssistantOverlay>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final VoiceRecognitionController _recognitionController;
  late final SpeechOutputController _speechOutputController;
  late final bool _ownsRecognitionController;
  late final bool _ownsSpeechOutputController;
  late final bool _ownsSessionController;
  late final OfficialGroundedSearch _groundedSearch;
  late final bool _ownsGroundedSearch;
  bool _ownsUnderstandingEngine = false;
  EdgeSlmUnderstandingEngine? _edgeSlmEngine;
  VoiceAgentController? _voiceAgentController;
  bool _ownsVoiceAgentController = false;
  StreamSubscription<VoiceAgentEvent>? _voiceAgentEvents;
  AssistantSessionController? _sessionController;
  late final AnimationController _edgeController;
  late final AnimationController _edgeRevealController;
  late final AnimationController _pulseController;
  late final AnimationController _waveController;
  late final ValueNotifier<double> _edgeIntensity;
  late final ValueNotifier<double> _soundLevel;
  late final Listenable _edgeRepaint;
  bool _reduceEdgeMotion = false;

  _VoiceAssistantPhase _voicePhase = _VoiceAssistantPhase.starting;
  String _transcript = '';
  String? _message;
  String? _detectedLanguage;
  VoiceInputLanguage _fallbackLanguage = VoiceInputLanguage.english;
  VoiceRecognitionCapabilities? _recognitionCapabilities;
  SpeechOutputCapabilities? _speechCapabilities;
  bool _showFallbackPicker = false;
  bool _startingRecognition = false;
  bool _speaking = false;
  bool _closing = false;
  bool _fallingBackToLocal = false;
  List<SchemeSearchMatch> _legacyMatches = const [];
  bool _legacySearching = false;
  int _operationGeneration = 0;
  int _recognitionGeneration = 0;
  String? _lastSpokenTurn;
  String? _lastFinalTranscript;
  int _lastFinalRecognitionGeneration = -1;
  DateTime _lastSoundLevelUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  final TextEditingController _typedController = TextEditingController();
  _OnlineGroundingPhase _groundingPhase = _OnlineGroundingPhase.idle;
  List<GroundedSource> _groundedSources = const [];
  String? _groundingKey;
  int _groundingGeneration = 0;
  final List<_VoiceTranscriptTurn> _conversationTurns = [];
  final ScrollController _panelScrollController = ScrollController();
  int _fallbackTranscriptId = 0;

  bool get _isListening => _voicePhase == _VoiceAssistantPhase.listening;
  bool get _cloudSessionInUse {
    final state = _voiceAgentController?.state;
    if (state?.usingCloud != true) return false;
    return switch (state!.phase) {
      VoiceAgentConnectionPhase.initializing ||
      VoiceAgentConnectionPhase.connecting ||
      VoiceAgentConnectionPhase.connected ||
      VoiceAgentConnectionPhase.reconnecting => true,
      _ => false,
    };
  }

  bool get _isCompanion => widget.surface == VoiceAgentSurface.companion;
  Color get _accent =>
      _isCompanion ? const Color(0xFFEA580C) : const Color(0xFF2563EB);
  bool get _hasConversation => _sessionController != null;
  AssistantSessionState? get _session => _sessionController?.state;
  VoiceEdgeActivity get _edgeActivity {
    if (_speaking) return VoiceEdgeActivity.speaking;
    if (_isListening) return VoiceEdgeActivity.listening;
    if (_voicePhase == _VoiceAssistantPhase.processing ||
        _session?.phase == AssistantSessionPhase.understanding) {
      return VoiceEdgeActivity.processing;
    }
    return VoiceEdgeActivity.idle;
  }

  bool get _presentInTamil {
    if (_session?.isTamil == true) return true;
    if (_detectedLanguage?.toLowerCase().startsWith('ta') == true) return true;
    if (_detectedLanguage?.toLowerCase().startsWith('en') == true) return false;
    if (_transcript.trim().isNotEmpty) {
      return IntelligentSchemeSearch.interpret(_transcript).isTamil;
    }
    return _showFallbackPicker && _fallbackLanguage == VoiceInputLanguage.tamil;
  }

  String get _languageBadgeLabel {
    if (_detectedLanguage?.toLowerCase().startsWith('ta') == true ||
        _session?.isTamil == true) {
      return 'தமிழ்';
    }
    if (_detectedLanguage?.toLowerCase().startsWith('en') == true) {
      return 'English';
    }
    return 'Auto';
  }

  String get _statusLabel {
    if (_speaking) return _presentInTamil ? 'பேசுகிறது...' : 'Speaking...';
    if (_isListening) return _presentInTamil ? 'கேட்கிறது...' : 'Listening...';
    if (_voicePhase == _VoiceAssistantPhase.processing) {
      return _presentInTamil ? 'செயலாக்குகிறது...' : 'Processing...';
    }
    switch (_session?.phase) {
      case AssistantSessionPhase.understanding:
        return _presentInTamil ? 'புரிந்துகொள்கிறது...' : 'Understanding...';
      case AssistantSessionPhase.asking:
        return _presentInTamil ? 'ஒரு கேள்வி' : 'One question';
      case AssistantSessionPhase.results:
        return _presentInTamil ? 'திட்டங்கள் கிடைத்தன' : 'Matches found';
      case AssistantSessionPhase.noConfidentMatch:
        return _presentInTamil ? 'மேலும் தகவல் தேவை' : 'Needs more detail';
      default:
        if (_legacySearching) return 'Finding...';
        if (_legacyMatches.isNotEmpty) return 'Found ${_legacyMatches.length}';
        return _presentInTamil ? 'தயார்' : 'Ready';
    }
  }

  Color get _statusColor => _isListening
      ? const Color(0xFF10B981)
      : _speaking ||
            _voicePhase == _VoiceAssistantPhase.processing ||
            _session?.phase == AssistantSessionPhase.understanding
      ? const Color(0xFFF59E0B)
      : (_session?.recommendations.isNotEmpty == true ||
            _legacyMatches.isNotEmpty)
      ? const Color(0xFF60A5FA)
      : const Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsRecognitionController = widget.recognitionController == null;
    _recognitionController =
        widget.recognitionController ?? AutomaticVoiceRecognitionController();
    _ownsSpeechOutputController = widget.speechOutputController == null;
    _speechOutputController =
        widget.speechOutputController ?? NativeSpeechOutputController();
    _ownsSessionController = widget.sessionController == null;
    if (widget.sessionController != null) {
      _sessionController = widget.sessionController;
    } else if (widget.schemes.isNotEmpty) {
      final engine =
          widget.understandingEngine ?? EdgeSlmUnderstandingEngine.standard();
      _ownsUnderstandingEngine = widget.understandingEngine == null;
      if (engine is EdgeSlmUnderstandingEngine) {
        _edgeSlmEngine = engine;
        engine.addListener(_handleEdgeSlmChanged);
        unawaited(engine.prepare());
      }
      _sessionController = AssistantSessionController(
        engine: engine,
        schemes: widget.schemes,
        profile: widget.profile ?? UserProfile(),
      );
    }
    _sessionController?.addListener(_handleSessionChanged);
    if (widget.voiceAgentController != null) {
      _voiceAgentController = widget.voiceAgentController;
    } else if (_sessionController != null) {
      _voiceAgentController = LiveKitVoiceAgentController.tryFromSupabase(
        session: _sessionController!,
        profile: widget.profile ?? UserProfile(),
      );
      _ownsVoiceAgentController = _voiceAgentController != null;
    }
    _ownsGroundedSearch = widget.groundedSearch == null;
    _groundedSearch = widget.groundedSearch ?? HttpOfficialGroundedSearch();

    final deviceLanguage = PlatformDispatcher.instance.locale.languageCode;
    _fallbackLanguage = deviceLanguage == 'ta'
        ? VoiceInputLanguage.tamil
        : VoiceInputLanguage.english;
    _edgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    _edgeRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _edgeRevealController.addStatusListener(_handleEdgeBloomStatus);
    _edgeController.repeat();
    _edgeRevealController.forward();
    _edgeIntensity = ValueNotifier<double>(0.12);
    _soundLevel = ValueNotifier<double>(0.1);
    _edgeRepaint = Listenable.merge([
      _edgeController,
      _edgeRevealController,
      _edgeIntensity,
    ]);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.82,
      upperBound: 1,
      value: 1,
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    unawaited(_initializeSpeechOutput());
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _initializeVoiceAgent(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_voiceAgentController?.close());
      unawaited(_recognitionController.cancel());
      unawaited(_speechOutputController.stop());
      _setListeningAnimations(false);
    }
  }

  Future<void> _initializeVoiceAgent() async {
    if (!mounted) return;
    final agent = _voiceAgentController;
    if (agent != null) {
      agent.addListener(_handleVoiceAgentChanged);
      _voiceAgentEvents = agent.events.listen(_handleVoiceAgentEvent);
      try {
        await agent.initialize();
        await agent.connect();
        if (mounted && agent.state.usingCloud) {
          _handleVoiceAgentChanged();
          if (widget.initialText?.trim().isNotEmpty == true) {
            await agent.sendText(widget.initialText!.trim());
          }
          return;
        }
      } catch (_) {
        await agent.close();
        // Cloud voice is unavailable.
        if (mounted) {
          setState(() {
            // Unused fallback reason removed
          });
        }
      }
    }
    if (widget.initialText?.trim().isNotEmpty == true) {
      final value = widget.initialText!.trim();
      if (mounted) setState(() => _transcript = value);
      await _processFinalTranscript(value);
    } else if (widget.autoStart) {
      await _startListening();
    } else if (mounted) {
      setState(() => _voicePhase = _VoiceAssistantPhase.ready);
    }
  }

  void _handleEdgeSlmChanged() {
    if (mounted) setState(() {});
  }

  void _handleVoiceAgentChanged() {
    if (!mounted || _voiceAgentController == null) return;
    final state = _voiceAgentController!.state;
    if (!state.usingCloud) return;
    final level = state.audioLevel.clamp(0.0, 1.0);
    _soundLevel.value = level;
    _edgeIntensity.value = math.max(0.18, level);
    _setListeningAnimations(state.isListening && !state.isMuted);
    setState(() {
      _voicePhase = state.isListening && !state.isMuted
          ? _VoiceAssistantPhase.listening
          : state.isSpeaking
          ? _VoiceAssistantPhase.processing
          : _VoiceAssistantPhase.ready;
      _speaking = state.isSpeaking;
      if (state.inputTranscript.isNotEmpty) {
        _transcript = state.inputTranscript;
      }
      _message = state.message;
    });
  }

  void _handleVoiceAgentEvent(VoiceAgentEvent event) {
    if (!mounted) return;
    if (event.type == VoiceAgentEventType.inputTranscriptDelta ||
        event.type == VoiceAgentEventType.inputTranscriptDone) {
      _upsertTranscriptTurn(event, _VoiceTranscriptSpeaker.user);
      return;
    }
    if (event.type == VoiceAgentEventType.outputTranscriptDelta ||
        event.type == VoiceAgentEventType.outputTranscriptDone) {
      _upsertTranscriptTurn(event, _VoiceTranscriptSpeaker.assistant);
      return;
    }
    if (event.type == VoiceAgentEventType.schemeResults) {
      final raw = event.data?['results'];
      final results = raw is List<CloudSchemeResult>
          ? raw
          : const <CloudSchemeResult>[];
      final schemes = matchCloudSchemeResultsToCatalog(results, widget.schemes);
      setState(() {
        _legacyMatches = schemes
            .map(
              (scheme) => SchemeSearchMatch(
                scheme: scheme,
                score: 1,
                reasons: const [
                  'Recommended by Saarthi from the verified catalog',
                ],
              ),
            )
            .toList(growable: false);
      });
      return;
    }
    if (event.type == VoiceAgentEventType.recoverableError ||
        event.type == VoiceAgentEventType.fatalError) {
      setState(() {
        // Cloud voice disconnected.
      });
      unawaited(_fallBackToLocalVoice());
    }
  }

  void _upsertTranscriptTurn(
    VoiceAgentEvent event,
    _VoiceTranscriptSpeaker speaker,
  ) {
    final text = event.text?.trim() ?? '';
    if (text.isEmpty) return;
    final suppliedId = event.data?['messageId'];
    final id = suppliedId is String && suppliedId.trim().isNotEmpty
        ? suppliedId.trim()
        : '${speaker.name}-${_fallbackTranscriptId++}';
    final index = _conversationTurns.indexWhere((turn) => turn.id == id);
    setState(() {
      if (index >= 0) {
        _conversationTurns[index] = _conversationTurns[index].copyWith(
          text: text,
        );
      } else {
        _conversationTurns.add(
          _VoiceTranscriptTurn(id: id, speaker: speaker, text: text),
        );
        if (_conversationTurns.length > 12) {
          _conversationTurns.removeAt(0);
        }
      }
      if (speaker == _VoiceTranscriptSpeaker.user) {
        _transcript = text;
      }
    });
    _scrollToLatestTurn();
  }

  void _scrollToLatestTurn() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_panelScrollController.hasClients) return;
      _panelScrollController.animateTo(
        _panelScrollController.position.maxScrollExtent,
        duration: _reduceEdgeMotion
            ? Duration.zero
            : const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _fallBackToLocalVoice() async {
    if (_fallingBackToLocal || _closing) return;
    _fallingBackToLocal = true;
    await _voiceAgentController?.close();
    if (mounted && !_closing) {
      setState(() {
        // Cloud voice disconnected.
      });
      await _startListening(preserveTranscript: _transcript.isNotEmpty);
    }
    _fallingBackToLocal = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion == _reduceEdgeMotion) return;
    _reduceEdgeMotion = reduceMotion;
    if (reduceMotion) {
      _edgeController.stop();
      _edgeController.value = 0;
      _edgeRevealController.stop();
      _edgeRevealController.value = 0.5;
    } else {
      _startEdgeBloom();
    }
  }

  void _handleEdgeBloomStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _edgeController.stop();
  }

  void _startEdgeBloom() {
    if (_reduceEdgeMotion) return;
    if (!_edgeController.isAnimating) _edgeController.repeat();
    _edgeRevealController.forward(from: 0);
  }

  Future<void> _initializeSpeechOutput() async {
    final capabilities = await _speechOutputController.initialize();
    if (mounted) setState(() => _speechCapabilities = capabilities);
  }

  void _handleSessionChanged() {
    if (!mounted) return;
    final state = _sessionController!.state;
    setState(() {
      _message = state.message;
      if (state.latestTranscript.isNotEmpty) {
        _transcript = state.latestTranscript;
      }
      if (state.phase == AssistantSessionPhase.understanding) {
        _groundingGeneration++;
        _groundingKey = null;
        _groundingPhase = _OnlineGroundingPhase.idle;
        _groundedSources = const [];
      }
    });
    if ((state.phase == AssistantSessionPhase.results ||
            state.phase == AssistantSessionPhase.noConfidentMatch) &&
        state.reply != null) {
      _startOnlineGrounding(state);
    }
    if (_cloudSessionInUse) return;
    final reply = state.reply;
    final question = state.question;
    final turnKey = [
      state.statement,
      state.questionsAsked,
      reply?.topic,
      question?.factKey.name,
    ].join('|');
    if (_lastSpokenTurn == turnKey) return;
    if (state.phase == AssistantSessionPhase.asking && question != null) {
      _lastSpokenTurn = turnKey;
      _upsertTranscriptTurn(
        VoiceAgentEvent(
          VoiceAgentEventType.outputTranscriptDone,
          text: _questionText(state, question),
          data: {'messageId': 'local-assistant-$turnKey'},
        ),
        _VoiceTranscriptSpeaker.assistant,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_speakQuestionAndListen());
      });
    } else if ((state.phase == AssistantSessionPhase.results ||
            state.phase == AssistantSessionPhase.noConfidentMatch) &&
        reply != null) {
      _lastSpokenTurn = turnKey;
      _upsertTranscriptTurn(
        VoiceAgentEvent(
          VoiceAgentEventType.outputTranscriptDone,
          text: reply.displayText,
          data: {'messageId': 'local-assistant-$turnKey'},
        ),
        _VoiceTranscriptSpeaker.assistant,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_speakReply(reply));
      });
    }
  }

  void _startOnlineGrounding(AssistantSessionState state) {
    final reply = state.reply;
    if (reply == null) return;
    final urls = <String>[];
    final labels = <String, String>{};
    void addSource(String url, String label) {
      final value = url.trim();
      if (value.isEmpty || urls.contains(value)) return;
      urls.add(value);
      labels[value] = label;
    }

    addSource(reply.sourceUrl, reply.sourceLabel);
    for (final recommendation in state.recommendations.take(3)) {
      addSource(recommendation.scheme.sourceUrl, recommendation.scheme.name);
    }
    if (urls.isEmpty) return;
    final key = '${reply.topic}|${urls.join('|')}';
    if (_groundingKey == key) return;
    _groundingKey = key;
    final generation = ++_groundingGeneration;
    setState(() {
      _groundingPhase = _OnlineGroundingPhase.checking;
      _groundedSources = const [];
    });
    unawaited(
      _groundedSearch
          .search(
            GroundedSearchRequest(
              topic: reply.topic,
              sourceUrls: urls,
              sourceLabels: labels,
            ),
          )
          .then((result) {
            if (!mounted || generation != _groundingGeneration) return;
            setState(() {
              _groundedSources = result.sources;
              _groundingPhase = switch (result.outcome) {
                GroundedSearchOutcome.found => _OnlineGroundingPhase.found,
                GroundedSearchOutcome.offline =>
                  _OnlineGroundingPhase.unavailable,
                GroundedSearchOutcome.noSources =>
                  _OnlineGroundingPhase.noSources,
              };
            });
          }),
    );
  }

  Future<void> _startListening({bool preserveTranscript = false}) async {
    if (!mounted || _startingRecognition || _speaking) return;
    if (_cloudSessionInUse) {
      await _voiceAgentController!.setMuted(false);
      return;
    }
    _startingRecognition = true;
    _operationGeneration++;
    _recognitionGeneration++;
    _lastFinalTranscript = null;
    _lastFinalRecognitionGeneration = -1;
    await _speechOutputController.stop();
    if (!mounted) return;
    _setListeningAnimations(false);
    setState(() {
      _voicePhase = _VoiceAssistantPhase.starting;
      _message = null;
      if (!preserveTranscript) _transcript = '';
    });

    try {
      final capabilities =
          _recognitionCapabilities ??
          await _recognitionController.initialize(
            onStatus: _handleStatus,
            onResult: _handleResult,
            onSoundLevel: _handleSoundLevel,
            onLanguage: _handleLanguage,
            onError: _handleError,
          );
      _recognitionCapabilities = capabilities;
      if (!mounted) return;
      if (!capabilities.available) {
        _edgeIntensity.value = 0.12;
        _setListeningAnimations(false);
        setState(() {
          _voicePhase = _VoiceAssistantPhase.unavailable;
          _message =
              capabilities.reason ??
              'Voice recognition is not available on this device.';
        });
        return;
      }

      final useFallback = !capabilities.automaticLanguageDetection;
      final isUnavailableReason =
          capabilities.reason?.contains('unavailable') == true;
      setState(() {
        _voicePhase = _VoiceAssistantPhase.listening;
        _message = (useFallback && isUnavailableReason)
            ? capabilities.reason
            : null;
        _showFallbackPicker = useFallback;
      });
      _sessionController?.setListening(
        transcript: preserveTranscript ? _transcript : '',
      );
      _edgeIntensity.value = 0.25;
      _setListeningAnimations(true);
      await _recognitionController.listen(
        localeId: useFallback ? _fallbackLocaleId : null,
      );
      if (mounted && !_recognitionController.isListening) {
        _edgeIntensity.value = 0.12;
        _setListeningAnimations(false);
      }
    } catch (_) {
      if (!mounted) return;
      _edgeIntensity.value = 0.12;
      _setListeningAnimations(false);
      setState(() {
        _voicePhase = _VoiceAssistantPhase.unavailable;
        _message = 'Voice recognition could not start. Please try again.';
      });
    } finally {
      _startingRecognition = false;
    }
  }

  String get _fallbackLocaleId =>
      _fallbackLanguage == VoiceInputLanguage.tamil ? 'ta-IN' : 'en-IN';

  void _handleResult(VoiceRecognitionResult result) {
    if (!mounted) return;
    final transcript = result.transcript.trim();
    if (_transcript == transcript && !result.isFinal) return;
    setState(() {
      _transcript = transcript;
      if (result.isFinal) {
        _voicePhase = _VoiceAssistantPhase.ready;
        _setListeningAnimations(false);
      }
    });
    if (!result.isFinal) {
      _sessionController?.updatePartialTranscript(transcript);
      return;
    }
    if (transcript.isEmpty) return;
    if (_lastFinalRecognitionGeneration == _recognitionGeneration &&
        _lastFinalTranscript == transcript) {
      return;
    }
    _lastFinalRecognitionGeneration = _recognitionGeneration;
    _lastFinalTranscript = transcript;
    _upsertTranscriptTurn(
      VoiceAgentEvent(
        VoiceAgentEventType.inputTranscriptDone,
        text: transcript,
        data: {'messageId': 'local-user-$_recognitionGeneration'},
      ),
      _VoiceTranscriptSpeaker.user,
    );
    unawaited(_processFinalTranscript(transcript));
  }

  Future<void> _processFinalTranscript(String transcript) async {
    final value = transcript.trim();
    final normalized = PrivateAiKnowledgeBase.normalizeForUnderstanding(value);
    if (normalized.isEmpty) return;
    final session = _sessionController;
    if (session != null) {
      if (session.state.question != null) {
        await session.answer(value);
      } else {
        _lastSpokenTurn = null;
        await session.start(value, isTamil: _presentInTamil);
      }
      return;
    }
    await _legacySearch(value);
  }

  Future<void> _legacySearch(String query) async {
    final search = widget.onSearch;
    if (search == null || query.trim().isEmpty) {
      widget.onSubmit(query);
      return;
    }
    final generation = ++_operationGeneration;
    setState(() {
      _legacySearching = true;
      _legacyMatches = const [];
      _message = null;
    });
    try {
      final matches = await search(query);
      if (!mounted || generation != _operationGeneration) return;
      setState(() {
        _legacySearching = false;
        _legacyMatches = matches;
      });
    } catch (_) {
      if (!mounted || generation != _operationGeneration) return;
      setState(() {
        _legacySearching = false;
        _legacyMatches = const [];
        _message = 'I could not search right now. Please try again.';
      });
    }
  }

  void _handleSoundLevel(double level) {
    if (!mounted) return;
    final now = DateTime.now();
    if (now.difference(_lastSoundLevelUpdate) <
        const Duration(milliseconds: 66)) {
      return;
    }
    _lastSoundLevelUpdate = now;
    final normalizedLevel = ((level + 2) / 12).clamp(0.0, 1.0);
    _soundLevel.value = normalizedLevel;
    _edgeIntensity.value = math.max(0.25, normalizedLevel);
  }

  void _handleLanguage(String language) {
    if (!mounted || language == _detectedLanguage) return;
    setState(() => _detectedLanguage = language);
  }

  void _handleError(VoiceRecognitionError error) {
    if (!mounted) return;
    _edgeIntensity.value = 0.12;
    _soundLevel.value = 0.1;
    _setListeningAnimations(false);
    setState(() {
      _voicePhase = _VoiceAssistantPhase.unavailable;
      if (error.automaticUnavailable) {
        _showFallbackPicker = true;
      }
      _message = error.message;
    });
  }

  void _handleStatus(String status) {
    if (!mounted) return;
    if (status == 'listening') {
      _startEdgeBloom();
      _edgeIntensity.value = 0.25;
      _setListeningAnimations(true);
      if (_voicePhase != _VoiceAssistantPhase.listening) {
        setState(() => _voicePhase = _VoiceAssistantPhase.listening);
      }
    } else if (status == 'processing') {
      _edgeIntensity.value = 0.16;
      _soundLevel.value = 0.1;
      _setListeningAnimations(false);
      if (_voicePhase != _VoiceAssistantPhase.processing) {
        setState(() => _voicePhase = _VoiceAssistantPhase.processing);
      }
    } else if (status == 'done' || status == 'notListening') {
      _edgeIntensity.value = 0.12;
      _soundLevel.value = 0.1;
      _setListeningAnimations(false);
      if (_voicePhase == _VoiceAssistantPhase.listening) {
        setState(() => _voicePhase = _VoiceAssistantPhase.ready);
      }
    }
  }

  Future<void> _stopListening() async {
    _operationGeneration++;
    if (_cloudSessionInUse) {
      await _voiceAgentController!.setMuted(true);
      if (!mounted) return;
      _edgeIntensity.value = 0.12;
      _soundLevel.value = 0.1;
      _setListeningAnimations(false);
      setState(() => _voicePhase = _VoiceAssistantPhase.ready);
      return;
    }
    await _recognitionController.stop();
    if (!mounted) return;
    _edgeIntensity.value = 0.12;
    _soundLevel.value = 0.1;
    _setListeningAnimations(false);
    setState(() => _voicePhase = _VoiceAssistantPhase.ready);
  }

  Future<void> _toggleListening() async {
    if (_cloudSessionInUse && _speaking) {
      await _voiceAgentController!.interrupt();
      await _voiceAgentController!.setMuted(false);
      return;
    }
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening(preserveTranscript: _session?.question != null);
    }
  }

  Future<void> _changeLanguage(VoiceInputLanguage language) async {
    if (_fallbackLanguage == language && _isListening) return;
    _operationGeneration++;
    await _recognitionController.cancel();
    if (!mounted) return;
    setState(() {
      _fallbackLanguage = language;
      _detectedLanguage = language == VoiceInputLanguage.tamil
          ? 'ta-IN'
          : 'en-IN';
      _message = null;
      _voicePhase = _VoiceAssistantPhase.ready;
    });
    await _startListening(preserveTranscript: _session?.question != null);
  }

  Future<void> _speakQuestionAndListen() async {
    if (_cloudSessionInUse) return;
    final state = _session;
    final question = state?.question;
    if (state == null || question == null || _speaking) return;
    await _recognitionController.cancel();
    if (!mounted) return;
    final reply = state.reply;
    final languageTag =
        reply?.languageTag ?? (state.isTamil ? 'ta-IN' : 'en-IN');
    final supported = _speechCapabilities?.supports(languageTag) ?? false;
    if (!supported) return;
    final generation = ++_operationGeneration;
    setState(() {
      _speaking = true;
      _voicePhase = _VoiceAssistantPhase.ready;
    });
    final questionText = _questionText(state, question);
    final spokenText = reply == null
        ? questionText
        : '${reply.spokenText} $questionText';
    final completed = await _speechOutputController.speak(
      spokenText,
      languageTag: languageTag,
    );
    if (!mounted || generation != _operationGeneration) return;
    setState(() => _speaking = false);
    if (completed) {
      // Give Android audio focus a moment to move from TTS back to the mic.
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted && generation == _operationGeneration) {
        await _startListening(preserveTranscript: true);
      }
    }
  }

  Future<void> _speakReply(GroundedAssistantReply reply) async {
    if (_cloudSessionInUse || _speaking || reply.spokenText.trim().isEmpty) {
      return;
    }
    await _recognitionController.cancel();
    if (!mounted) return;
    final supported = _speechCapabilities?.supports(reply.languageTag) ?? false;
    if (!supported) return;
    final generation = ++_operationGeneration;
    setState(() {
      _speaking = true;
      _voicePhase = _VoiceAssistantPhase.ready;
    });
    await _speechOutputController.speak(
      reply.spokenText,
      languageTag: reply.languageTag,
    );
    if (!mounted || generation != _operationGeneration) return;
    setState(() => _speaking = false);
  }

  String _questionText(AssistantSessionState state, FollowUpQuestion question) {
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(state.statement)) {
      return question.tamil;
    }
    if (!state.isTamil) return question.english;
    return switch (question.factKey) {
      EligibilityFactKey.age => 'Unga vayasu enna?',
      EligibilityFactKey.state => 'Neenga entha state-la irukkeenga?',
      EligibilityFactKey.district => 'Neenga entha district-la irukkeenga?',
      EligibilityFactKey.annualIncome =>
        'Unga family annual income approximately evlo?',
      EligibilityFactKey.gender => 'Unga gender category enna?',
      EligibilityFactKey.community => 'Unga community category enna?',
      EligibilityFactKey.occupation => 'Ippo unga occupation enna?',
      EligibilityFactKey.education => 'Unga education level enna?',
      EligibilityFactKey.disability => 'Disability category apply aaguma?',
      EligibilityFactKey.maritalStatus => 'Unga marital status enna?',
      EligibilityFactKey.studentStatus =>
        'Neenga ippo student-ah irukkeengala?',
      EligibilityFactKey.businessStage =>
        'Idhu idea stage-ah, new business-ah, illa existing business-ah?',
      EligibilityFactKey.businessSector => 'Business sector enna?',
      EligibilityFactKey.fundingNeed => 'Approximately evlo funding thevai?',
      EligibilityFactKey.landholding => 'Unga landholding evlo?',
    };
  }

  Future<void> _answerOption(String option) async {
    await _recognitionController.cancel();
    await _speechOutputController.stop();
    if (!mounted) return;
    setState(() {
      _speaking = false;
      _transcript = option;
    });
    _upsertTranscriptTurn(
      VoiceAgentEvent(
        VoiceAgentEventType.inputTranscriptDone,
        text: option,
        data: {'messageId': 'option-${_session?.questionsAsked ?? 0}'},
      ),
      _VoiceTranscriptSpeaker.user,
    );
    await _sessionController?.answer(option);
  }

  Future<void> _useSuggestion(String query) async {
    await _recognitionController.cancel();
    if (!mounted) return;
    setState(() {
      _voicePhase = _VoiceAssistantPhase.ready;
      _transcript = query;
      _message = null;
    });
    _upsertTranscriptTurn(
      VoiceAgentEvent(
        VoiceAgentEventType.inputTranscriptDone,
        text: query,
        data: {'messageId': 'suggestion-${_fallbackTranscriptId++}'},
      ),
      _VoiceTranscriptSpeaker.user,
    );
    if (_cloudSessionInUse) {
      await _voiceAgentController!.sendText(query);
    } else {
      await _processFinalTranscript(query);
    }
  }

  Future<void> _sendTypedInput() async {
    final value = _typedController.text.trim();
    if (value.isEmpty) return;
    _typedController.clear();
    await _recognitionController.cancel();
    if (_cloudSessionInUse) {
      await _voiceAgentController!.sendText(value);
    } else {
      setState(() => _transcript = value);
      _upsertTranscriptTurn(
        VoiceAgentEvent(
          VoiceAgentEventType.inputTranscriptDone,
          text: value,
          data: {'messageId': 'typed-${_fallbackTranscriptId++}'},
        ),
        _VoiceTranscriptSpeaker.user,
      );
      await _processFinalTranscript(value);
    }
  }

  Future<void> _editFact(EligibilityFact fact) async {
    final controller = TextEditingController(text: fact.value);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        title: Text(
          'Edit ${_factLabel(context, fact.key)}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          key: const Key('voice-fact-editor'),
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(CentralizedTranslator.instance.translate('Use value')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && mounted) {
      await _sessionController?.editFact(fact.key, value);
    }
  }

  Future<void> _reviewAndSaveFacts() async {
    final controller = _sessionController;
    final callback = widget.onProfileConfirmed;
    if (controller == null || callback == null) return;
    final candidates = controller.state.facts.values
        .where((fact) => fact.source != EligibilityFactSource.profile)
        .where(
          (fact) => !{
            EligibilityFactKey.age,
            EligibilityFactKey.maritalStatus,
            EligibilityFactKey.studentStatus,
            EligibilityFactKey.landholding,
          }.contains(fact.key),
        )
        .toList(growable: false);
    if (candidates.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('voice-profile-review'),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        title: Text(
          'Review profile updates',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: candidates
                .map(
                  (fact) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_factLabel(context, fact.key)),
                    subtitle: Text(fact.value),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: Text(
              _presentInTamil
                  ? CentralizedTranslator.instance.translate(
                      'Keep session only',
                    )
                  : 'Keep session only',
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              _presentInTamil
                  ? CentralizedTranslator.instance.translate('Save confirmed')
                  : 'Save confirmed',
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    for (final fact in candidates) {
      controller.confirmFact(fact.key);
    }
    callback(controller.buildUpdatedProfile());
    if (mounted) {
      setState(() => _message = 'Confirmed details saved to your profile.');
    }
  }

  void _setListeningAnimations(bool listening) {
    if (listening) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
      if (!_waveController.isAnimating) _waveController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.value = 1;
      _waveController.stop();
      _waveController.value = 0;
    }
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    _operationGeneration++;
    _sessionController?.cancel();
    // Navigation must never wait for an OEM speech service to acknowledge
    // cancellation. Disposal still performs the full native cleanup.
    unawaited(_speechOutputController.stop());
    unawaited(_recognitionController.cancel());
    unawaited(_voiceAgentController?.close());
    widget.onClose();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voiceAgentController?.removeListener(_handleVoiceAgentChanged);
    unawaited(_voiceAgentEvents?.cancel());
    if (_ownsVoiceAgentController) {
      unawaited(_voiceAgentController?.dispose());
    } else {
      unawaited(_voiceAgentController?.close());
    }
    _sessionController?.removeListener(_handleSessionChanged);
    if (_ownsSessionController) _sessionController?.dispose();
    _groundingGeneration++;
    if (_ownsGroundedSearch) _groundedSearch.close();
    _edgeSlmEngine?.removeListener(_handleEdgeSlmChanged);
    if (_ownsUnderstandingEngine) {
      unawaited(_edgeSlmEngine?.close());
    }
    if (_ownsRecognitionController) {
      unawaited(_recognitionController.dispose());
    } else {
      unawaited(_recognitionController.cancel());
    }
    if (_ownsSpeechOutputController) {
      unawaited(_speechOutputController.dispose());
    } else {
      unawaited(_speechOutputController.stop());
    }
    _edgeController.dispose();
    _edgeRevealController.removeStatusListener(_handleEdgeBloomStatus);
    _edgeRevealController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _edgeIntensity.dispose();
    _soundLevel.dispose();
    _typedController.dispose();
    _panelScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final edgeRadius = math.max(26.0, media.viewPadding.top + 10);
    return Material(
      key: const Key('voice-assistant-overlay'),
      color: Colors.transparent,
      child: Stack(
        children: [
          const Positioned.fill(
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                systemStatusBarContrastEnforced: false,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarIconBrightness: Brightness.light,
                systemNavigationBarContrastEnforced: false,
              ),
              child: SizedBox.expand(),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xFF020617).withValues(alpha: 0.10),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  key: const Key('voice-edge-outline'),
                  animation: _edgeRepaint,
                  builder: (context, child) => CustomPaint(
                    isComplex: true,
                    willChange: true,
                    painter: VoiceEdgePainter(
                      entranceProgress: _edgeRevealController.value,
                      ambientProgress: _edgeController.value,
                      activityIntensity: _edgeIntensity.value,
                      activity: _edgeActivity,
                      radius: edgeRadius,
                      reduceMotion: _reduceEdgeMotion,
                      companion: _isCompanion,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 620,
                  maxHeight: math.min(media.size.height * 0.86, 760),
                ),
                child: Container(
                  key: const Key('voice-assistant-panel'),
                  decoration: BoxDecoration(
                    color:
                        (_isCompanion
                                ? const Color(0xFF1C1008)
                                : const Color(0xFF07111F))
                            .withValues(alpha: 0.98),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: _accent.withValues(alpha: 0.34)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66020A16),
                        blurRadius: 30,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: _panelScrollController,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 12),
                        _buildListeningArea(),
                        if (_conversationTurns.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildConversationTranscript(),
                        ],
                        if (_cloudSessionInUse) ...[
                          const SizedBox(height: 8),
                          Row(
                            key: const Key('voice-cloud-disclosure'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_outlined,
                                size: 13,
                                color: _accent,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Live audio is processed securely. This app does not save audio or raw transcripts.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFCBD5E1),
                                    fontSize: 9.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_message != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _message!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFCA5A5),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                        if (_session?.reply case final reply?) ...[
                          const SizedBox(height: 12),
                          _buildAssistantReply(reply),
                        ],
                        if (_groundingPhase != _OnlineGroundingPhase.idle) ...[
                          const SizedBox(height: 9),
                          _buildOnlineGrounding(),
                        ],
                        if (_session?.facts.isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          _buildFactChips(),
                        ],
                        if (_session?.question != null) ...[
                          const SizedBox(height: 12),
                          _buildQuestionCard(_session!.question!),
                        ],
                        if (_legacySearching ||
                            _session?.phase ==
                                AssistantSessionPhase.understanding) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            key: Key('voice-search-progress'),
                            minHeight: 2,
                            color: _accent,
                            backgroundColor: _accent.withValues(alpha: 0.20),
                          ),
                        ] else if (_session?.recommendations.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 12),
                          _buildConversationalResults(),
                        ] else if (_legacyMatches.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildLegacyResults(),
                        ] else if (_session?.phase ==
                                AssistantSessionPhase.noConfidentMatch ||
                            (_transcript.isNotEmpty &&
                                !_hasConversation &&
                                !_legacySearching)) ...[
                          const SizedBox(height: 10),
                          Text(
                            _presentInTamil
                                ? 'நம்பகமான பொருத்தம் கிடைக்கவில்லை. உங்கள் நிலையை வேறு வார்த்தைகளில் சொல்லுங்கள்.'
                                : 'No confident scheme match yet. Tell me a little more about your situation.',
                            key: const Key('voice-no-results'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFBBF24),
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (_session?.excludedUncertainCount case final count?
                            when count > 0) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            key: const Key('voice-show-uncertain'),
                            onPressed: () =>
                                _sessionController?.setIncludeUncertain(true),
                            icon: const Icon(Icons.info_outline, size: 15),
                            label: Text(
                              'See $count uncertain or historical schemes',
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Semantics(
          image: true,
          label: 'IN AI assistant',
          child: SizedBox(
            width: 56,
            height: 56,
            child: ClipOval(
              child: Image.asset(
                'assets/images/saarthi/sarathi.png',
                key: const Key('voice-assistant-image'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isCompanion ? 'Talk to Saarthi' : 'Ask IN AI',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Semantics(
                liveRegion: true,
                label: _statusLabel,
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: FitOneLine(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _statusLabel,
                          key: const Key('voice-live-status'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: _statusColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildLanguageSelector(),
        if (_cloudSessionInUse)
          IconButton(
            key: const Key('voice-mute-button'),
            tooltip: _voiceAgentController!.state.isMuted ? 'Unmute' : 'Mute',
            onPressed: () => _voiceAgentController!.setMuted(
              !_voiceAgentController!.state.isMuted,
            ),
            icon: Icon(
              _voiceAgentController!.state.isMuted
                  ? Icons.mic_off_rounded
                  : Icons.mic_rounded,
              color: const Color(0xFFCBD5E1),
            ),
          ),
        IconButton(
          key: const Key('voice-close-button'),
          tooltip: 'Cancel assistant',
          onPressed: _close,
          icon: const Icon(Icons.close_rounded, color: Color(0xFFCBD5E1)),
        ),
      ],
    );
  }

  Widget _buildListeningArea() {
    final showSuggestions =
        _transcript.isEmpty && _session?.statement.isEmpty != false;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _conversationTurns.isNotEmpty
                ? (_speaking
                      ? (_presentInTamil
                            ? 'பதிலை கேளுங்கள் அல்லது இடைமறிக்க தட்டுங்கள்'
                            : 'Listen, or tap below to interrupt')
                      : _isListening
                      ? (_presentInTamil
                            ? 'இயல்பாக பேசுங்கள்; முடிந்ததும் சிறிது நிறுத்துங்கள்'
                            : 'Speak naturally, then pause when you are done')
                      : (_presentInTamil
                            ? 'அடுத்த கேள்விக்கு தயாராக உள்ளது'
                            : 'Ready for your next question'))
                : _transcript.isEmpty
                ? (_presentInTamil
                      ? 'உங்கள் நிலையை இயல்பாக சொல்லுங்கள்...'
                      : 'Tell me your situation naturally...')
                : _transcript,
            key: const Key('voice-transcript'),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _transcript.isEmpty
                  ? const Color(0xFF94A3B8)
                  : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          if (showSuggestions) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _suggestionChip('Business loans'),
                _suggestionChip('College scholarship'),
                _suggestionChip('Farmer subsidy'),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _cloudSessionInUse
                      ? Semantics(
                          label: 'Server noise filtering is active',
                          child: const Icon(
                            Icons.noise_control_off_rounded,
                            color: Color(0xFF34D399),
                            size: 22,
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
              const SizedBox(width: 24),
              Semantics(
                button: true,
                label: _speaking
                    ? 'Interrupt assistant'
                    : _isListening
                    ? 'Stop listening'
                    : 'Start listening',
                hint: 'Double tap to control the microphone',
                onTap: _toggleListening,
                excludeSemantics: true,
                child: IconButton.filled(
                  key: const Key('voice-primary-control'),
                  onPressed: _toggleListening,
                  style: IconButton.styleFrom(
                    backgroundColor: _isListening
                        ? const Color(0xFF10B981)
                        : _accent,
                    minimumSize: const Size(56, 56),
                  ),
                  icon: Icon(
                    _speaking
                        ? Icons.front_hand_rounded
                        : _isListening
                        ? Icons.stop_rounded
                        : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: VoiceLevelBars(
                    key: const Key('voice-level-bars'),
                    animation: _waveController,
                    level: _soundLevel,
                    active: _isListening,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _speaking
                ? 'Interrupt'
                : _isListening
                ? 'Tap when finished'
                : 'Tap to speak',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_cloudSessionInUse) ...[
            const SizedBox(height: 6),
            Semantics(
              label: 'Server noise filtering is on',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF34D399),
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _presentInTamil
                        ? 'சத்தம் வடிகட்டப்படுகிறது'
                        : 'Noise filtering on',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6EE7B7),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isCompanion) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('voice-typed-input'),
                    controller: _typedController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendTypedInput(),
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: _isCompanion
                          ? 'Type to Saarthi...'
                          : 'Type instead...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  key: const Key('voice-send-text'),
                  tooltip: 'Send message',
                  onPressed: _sendTypedInput,
                  icon: Icon(Icons.send_rounded, color: _accent),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversationTranscript() {
    final visibleTurns = _conversationTurns.length <= 8
        ? _conversationTurns
        : _conversationTurns.sublist(_conversationTurns.length - 8);
    return Semantics(
      container: true,
      label: 'Conversation transcript',
      child: Container(
        key: const Key('voice-conversation-transcript'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.forum_outlined, color: _accent, size: 16),
                const SizedBox(width: 7),
                Text(
                  _presentInTamil ? 'உரையாடல்' : 'Conversation',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final turn in visibleTurns) _buildTranscriptBubble(turn),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptBubble(_VoiceTranscriptTurn turn) {
    final isUser = turn.speaker == _VoiceTranscriptSpeaker.user;
    final bubbleColor = isUser
        ? _accent.withValues(alpha: 0.24)
        : Colors.white.withValues(alpha: 0.075);
    final label = isUser
        ? (_presentInTamil ? 'நீங்கள்' : 'You')
        : (_presentInTamil ? 'உதவியாளர்' : 'Assistant');
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: '$label: ${turn.text}',
        child: Container(
          key: Key('voice-turn-${turn.id}'),
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            border: Border.all(
              color: isUser
                  ? _accent.withValues(alpha: 0.34)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isUser ? const Color(0xFF93C5FD) : _accent,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                turn.text,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.42,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suggestionChip(String label) => ActionChip(
    label: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    ),
    onPressed: () => _useSuggestion(label),
    side: BorderSide(color: _accent),
    backgroundColor: _accent.withValues(alpha: 0.18),
    labelStyle: const TextStyle(color: Colors.white),
    visualDensity: VisualDensity.compact,
  );

  Widget _buildLanguageSelector() {
    if (!_showFallbackPicker) {
      return Semantics(
        label: 'Voice language $_languageBadgeLabel',
        child: Container(
          key: const Key('voice-language-auto-badge'),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF93C5FD)),
          ),
          child: Text(
            _languageBadgeLabel,
            style: GoogleFonts.inter(
              color: const Color(0xFF172554),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    return Container(
      key: const Key('voice-language-fallback-picker'),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _languageOption('EN', VoiceInputLanguage.english),
          _languageOption('தமிழ்', VoiceInputLanguage.tamil),
        ],
      ),
    );
  }

  Widget _languageOption(String label, VoiceInputLanguage language) {
    final selected = _fallbackLanguage == language;
    return InkWell(
      key: Key('voice-language-${language.name}'),
      onTap: () => _changeLanguage(language),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFactChips() {
    final facts = _session!.facts.values.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _presentInTamil ? 'நான் புரிந்துகொண்டது' : 'What I understood',
          style: GoogleFonts.inter(
            color: const Color(0xFFCBD5E1),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: facts
              .map((fact) {
                final conflict = fact.hasConflict;
                return InputChip(
                  key: Key('voice-fact-${fact.key.name}'),
                  avatar: Icon(
                    conflict
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    size: 15,
                    color: conflict
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF60A5FA),
                  ),
                  label: Text(
                    '${_factLabel(context, fact.key)}: ${_displayFactValue(fact)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _editFact(fact),
                  side: BorderSide(
                    color: conflict
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF334155),
                  ),
                  backgroundColor: const Color(0xFF172554),
                  labelStyle: const TextStyle(color: Colors.white),
                  visualDensity: VisualDensity.compact,
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(FollowUpQuestion question) {
    final text = _questionText(_session!, question);
    return Container(
      key: const Key('voice-follow-up-question'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D4ED8).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF60A5FA),
                size: 17,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              IconButton(
                key: const Key('voice-repeat-question'),
                tooltip: 'Repeat question',
                onPressed: _speakQuestionAndListen,
                icon: const Icon(
                  Icons.volume_up_outlined,
                  color: Color(0xFF93C5FD),
                  size: 20,
                ),
              ),
            ],
          ),
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: question.options
                  .map(
                    (option) => ActionChip(
                      key: Key(
                        'voice-answer-${option.toLowerCase().replaceAll(' ', '-')}',
                      ),
                      label: Text(
                        option,
                        style: const TextStyle(
                          color: Color(0xFF172554),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => _answerOption(option),
                      backgroundColor: const Color(0xFFDBEAFE),
                      side: const BorderSide(color: Color(0xFF93C5FD)),
                      labelStyle: const TextStyle(color: Color(0xFF172554)),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (_speechCapabilities?.supports(
                _session!.isTamil ? 'ta-IN' : 'en-IN',
              ) ==
              false)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Speech output is unavailable; tap the microphone to answer.',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFBBF24),
                  fontSize: 9.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConversationalResults() {
    final recommendations = _session!.recommendations
        .take(3)
        .toList(growable: false);
    return Column(
      key: const Key('voice-search-results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _presentInTamil
                    ? 'உங்களுக்கு பொருத்தமான திட்டங்கள்'
                    : 'Schemes suited to your situation',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              key: const Key('voice-view-all-results'),
              onPressed: () => widget.onSubmit(_session!.statement),
              child: Text(
                CentralizedTranslator.instance.translate('View all'),
                style: const TextStyle(fontSize: 10.5),
              ),
            ),
          ],
        ),
        ...recommendations.map(_buildRecommendationCard),
        if (widget.onProfileConfirmed != null &&
            _session!.facts.values.any(
              (fact) => fact.source != EligibilityFactSource.profile,
            )) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('voice-review-profile'),
            onPressed: _reviewAndSaveFacts,
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 17),
            label: Text(
              CentralizedTranslator.instance.translate(
                'Review and save confirmed details',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAssistantReply(GroundedAssistantReply reply) {
    return Container(
      key: const Key('voice-assistant-reply'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _accent.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 15, color: _accent),
              const SizedBox(width: 6),
              Flexible(
                child: FitOneLine(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isCompanion ? 'Saarthi' : 'Ask IN AI',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            reply.displayText,
            style: GoogleFonts.inter(
              color: const Color(0xFFE2E8F0),
              fontSize: 11,
              height: 1.45,
            ),
          ),
          if (reply.sourceUrl.isNotEmpty) ...[
            const SizedBox(height: 7),
            TextButton.icon(
              key: const Key('voice-assistant-source'),
              onPressed: () => _openReplySource(reply.sourceUrl),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.open_in_new, size: 14),
              label: Text(
                reply.sourceLabel.isEmpty
                    ? 'Open official source'
                    : reply.sourceLabel,
                style: const TextStyle(fontSize: 10.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOnlineGrounding() {
    final isChecking = _groundingPhase == _OnlineGroundingPhase.checking;
    final isFound = _groundingPhase == _OnlineGroundingPhase.found;
    final icon = isChecking
        ? Icons.travel_explore
        : isFound
        ? Icons.verified_outlined
        : Icons.cloud_off_outlined;
    final title = switch (_groundingPhase) {
      _OnlineGroundingPhase.checking => 'Checking official sources…',
      _OnlineGroundingPhase.found =>
        'Grounded online · ${_groundedSources.length} official ${_groundedSources.length == 1 ? 'source' : 'sources'}',
      _OnlineGroundingPhase.unavailable =>
        'Offline · using private on-device knowledge',
      _OnlineGroundingPhase.noSources =>
        'Official page unavailable · using the verified local catalog',
      _OnlineGroundingPhase.idle => '',
    };
    return Container(
      key: const Key('voice-online-grounding'),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1D2E),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: (isFound ? const Color(0xFF22C55E) : _accent).withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: isFound ? const Color(0xFF4ADE80) : _accent,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFE2E8F0),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isChecking)
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    key: const Key('voice-online-grounding-progress'),
                    strokeWidth: 1.5,
                    color: _accent,
                  ),
                ),
            ],
          ),
          if (isFound) ...[
            const SizedBox(height: 5),
            ..._groundedSources.map(
              (source) => Padding(
                padding: const EdgeInsets.only(top: 5),
                child: InkWell(
                  key: Key('voice-grounded-source-${source.url}'),
                  onTap: () => _openReplySource(source.url.toString()),
                  borderRadius: BorderRadius.circular(9),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                source.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF93C5FD),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.open_in_new,
                              size: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          source.snippet,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFCBD5E1),
                            fontSize: 9.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          source.host,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF4ADE80),
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (isChecking || isFound) ...[
            const SizedBox(height: 5),
            Text(
              'Only the topic and official links are checked. Your statement and profile stay on this device.',
              key: const Key('voice-grounding-privacy-note'),
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 8.5,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openReplySource(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      setState(() => _message = 'Could not open the official source.');
    }
  }

  Widget _buildRecommendationCard(SchemeRecommendation recommendation) {
    final scheme = recommendation.scheme;
    final label = switch (recommendation.state) {
      SchemeMatchState.strongMatch => 'Strong match',
      SchemeMatchState.likelyMatch => 'Likely match',
      SchemeMatchState.needsInformation => 'Needs confirmation',
      SchemeMatchState.notSuitable => 'Not suitable',
      SchemeMatchState.noConfidentMatch => 'No confident match',
    };
    final color = switch (recommendation.state) {
      SchemeMatchState.strongMatch => const Color(0xFF22C55E),
      SchemeMatchState.likelyMatch => const Color(0xFF60A5FA),
      SchemeMatchState.needsInformation => const Color(0xFFF59E0B),
      _ => const Color(0xFFF87171),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: InkWell(
        key: Key('voice-result-${scheme.id}'),
        onTap: () => widget.onSchemeSelected?.call(scheme),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.052),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      scheme.toLocalized(_presentInTamil ? 'ta' : 'en').name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.62)),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (recommendation.reasons.isNotEmpty)
                _resultLine(
                  Icons.check_circle_outline,
                  _presentInTamil
                      ? 'ஏன் பொருந்துகிறது: ${recommendation.reasons.join(' • ')}'
                      : 'Why this fits: ${recommendation.reasons.join(' • ')}',
                  const Color(0xFF86EFAC),
                ),
              if (recommendation.unknownRequirements.isNotEmpty)
                _resultLine(
                  Icons.help_outline,
                  _presentInTamil
                      ? 'சரிபார்க்க வேண்டியவை: ${recommendation.unknownRequirements.take(2).join(' • ')}'
                      : 'Still confirm: ${recommendation.unknownRequirements.take(2).join(' • ')}',
                  const Color(0xFFFCD34D),
                ),
              _resultLine(
                recommendation.isTrusted
                    ? Icons.verified_outlined
                    : Icons.warning_amber_outlined,
                recommendation.isTrusted
                    ? (_presentInTamil
                          ? 'அதிகாரப்பூர்வ மூலத்தில் சரிபார்க்கப்பட்டது'
                          : 'Current official source verified')
                    : (_presentInTamil
                          ? 'விண்ணப்பிக்கும் முன் சரிபார்க்கவும்'
                          : 'Uncertain or historical — verify before applying'),
                recommendation.isTrusted
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFFFCA5A5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultLine(IconData icon, String text, Color color) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFFF1F5F9),
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildLegacyResults() {
    return Column(
      key: const Key('voice-search-results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _presentInTamil
              ? 'உங்களுக்கான சிறந்த திட்டங்கள்'
              : 'Best matching schemes',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        ..._legacyMatches
            .take(3)
            .map(
              (match) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    key: Key('voice-result-${match.scheme.id}'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Colors.white.withValues(alpha: 0.055),
                    title: Text(
                      match.scheme
                          .toLocalized(_presentInTamil ? 'ta' : 'en')
                          .name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      match.reasons.join(' • '),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                      ),
                    ),
                    onTap: () => widget.onSchemeSelected?.call(match.scheme),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  static String _factLabel(BuildContext context, EligibilityFactKey key) {
    final l10n = context.l10n;
    return switch (key) {
      EligibilityFactKey.age => l10n.labelAge,
      EligibilityFactKey.state => 'State',
      EligibilityFactKey.district => l10n.filterDistrict,
      EligibilityFactKey.annualIncome => l10n.labelAnnualIncome,
      EligibilityFactKey.gender => l10n.labelGender,
      EligibilityFactKey.community => l10n.labelCommunity,
      EligibilityFactKey.occupation => 'Situation',
      EligibilityFactKey.education => l10n.labelEducation,
      EligibilityFactKey.disability => l10n.labelDisability,
      EligibilityFactKey.maritalStatus => 'Marital status',
      EligibilityFactKey.studentStatus => l10n.empStudent,
      EligibilityFactKey.businessStage => l10n.labelBusinessStage,
      EligibilityFactKey.businessSector => 'Sector',
      EligibilityFactKey.fundingNeed => 'Funding need',
      EligibilityFactKey.landholding => 'Landholding',
    };
  }

  static String _displayFactValue(EligibilityFact fact) {
    if ({
      EligibilityFactKey.annualIncome,
      EligibilityFactKey.fundingNeed,
    }.contains(fact.key)) {
      final amount = double.tryParse(fact.value);
      if (amount != null) {
        if (amount >= 10000000) {
          return '₹${(amount / 10000000).toStringAsFixed(1)} crore';
        }
        if (amount >= 100000) {
          return '₹${(amount / 100000).toStringAsFixed(1)} lakh';
        }
      }
    }
    return fact.hasConflict
        ? '${fact.value} (profile: ${fact.conflictingValue})'
        : fact.value;
  }
}

class VoiceLevelBars extends StatelessWidget {
  const VoiceLevelBars({
    super.key,
    required this.animation,
    required this.level,
    required this.active,
  });

  final Animation<double> animation;
  final ValueListenable<double> level;
  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: active ? 1 : 0.32,
    duration: const Duration(milliseconds: 180),
    child: RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([animation, level]),
        builder: (context, child) => CustomPaint(
          size: const Size(54, 20),
          painter: VoiceLevelPainter(
            progress: animation.value,
            level: level.value,
            active: active,
          ),
        ),
      ),
    ),
  );
}

class VoiceLevelPainter extends CustomPainter {
  const VoiceLevelPainter({
    required this.progress,
    required this.level,
    required this.active,
  });

  static const int barCount = 9;
  final double progress;
  final double level;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 3.2;
    final spacing = (size.width - strokeWidth) / (barCount - 1);
    final center = (barCount - 1) / 2;
    final energy = ((level - 0.12) / 0.88).clamp(0.0, 1.0);
    final phase = progress * math.pi * 2;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xFF2563EB), Color(0xFF67E8F9)],
      ).createShader(Offset.zero & size);
    for (var index = 0; index < barCount; index++) {
      final distance = ((index - center).abs() / center).clamp(0.0, 1.0);
      final envelope = 1 - distance * 0.48;
      final motion = (math.sin(phase * 2 + index * 0.82) + 1) / 2;
      final normalizedHeight = active
          ? (0.2 + envelope * (0.2 + motion * 0.5) * (0.55 + energy * 0.65))
                .clamp(0.2, 1.0)
          : 0.2 + envelope * 0.08;
      final barHeight = size.height * normalizedHeight;
      final x = strokeWidth / 2 + spacing * index;
      final top = (size.height - barHeight) / 2;
      canvas.drawLine(Offset(x, top), Offset(x, size.height - top), paint);
    }
  }

  @override
  bool shouldRepaint(covariant VoiceLevelPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.level != level ||
      oldDelegate.active != active;
}

class VoiceEdgePainter extends CustomPainter {
  const VoiceEdgePainter({
    required this.entranceProgress,
    required this.ambientProgress,
    required this.activityIntensity,
    required this.activity,
    required this.radius,
    required this.reduceMotion,
    this.companion = false,
  });

  final double entranceProgress;
  final double ambientProgress;
  final double activityIntensity;
  final VoiceEdgeActivity activity;
  final double radius;
  final bool reduceMotion;
  final bool companion;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final timeline = entranceProgress.clamp(0.0, 1.0);
    final envelope = reduceMotion
        ? switch (activity) {
            VoiceEdgeActivity.listening => 0.50,
            VoiceEdgeActivity.processing => 0.34,
            VoiceEdgeActivity.speaking => 0.42,
            VoiceEdgeActivity.idle => 0.28,
          }
        : _bloomEnvelope(timeline);
    if (envelope <= 0.001) return;

    final spread = reduceMotion
        ? 1.0
        : Curves.easeOutCubic.transform((timeline / 0.34).clamp(0.0, 1.0));
    final phase = reduceMotion ? 0.0 : ambientProgress * math.pi * 2;
    final level = activityIntensity.clamp(0.0, 1.0);
    final strength = switch (activity) {
      VoiceEdgeActivity.idle => 0.72,
      VoiceEdgeActivity.listening => 0.82 + level * 0.16,
      VoiceEdgeActivity.processing => 0.64,
      VoiceEdgeActivity.speaking => 0.74,
    };
    final opacity = envelope * strength;
    final horizontalDrift = reduceMotion ? 0.0 : math.sin(phase) * 8;
    final verticalDrift = reduceMotion ? 0.0 : math.sin(phase * 1.4) * 12;
    final cornerRadius = radius.clamp(24.0, 58.0);
    final sideTop = size.height * (1 - 0.92 * spread);

    // Gemini's effect is a wide U-shaped wash, not a bordered rectangle. The
    // two neutral strokes create a cloudy inner edge with no crisp core and no
    // line across the top of the screen.
    final ambientRail = Path()
      ..moveTo(0, sideTop)
      ..lineTo(0, size.height - cornerRadius)
      ..quadraticBezierTo(0, size.height, cornerRadius, size.height)
      ..lineTo(size.width - cornerRadius, size.height)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width,
        size.height - cornerRadius,
      )
      ..lineTo(size.width, sideTop);
    canvas.drawPath(
      ambientRail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 40
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26)
        ..color = const Color(0xFFE8EDF3).withValues(alpha: opacity * 0.22),
    );
    canvas.drawPath(
      ambientRail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
        ..color = const Color(0xFFF8FAFC).withValues(alpha: opacity * 0.38),
    );

    final sideHeight = size.height * (0.24 + spread * 0.56);
    _drawGlow(
      canvas,
      center: Offset(-12 + horizontalDrift, size.height * 0.80),
      width: 150,
      height: sideHeight * 0.58,
      color: companion ? const Color(0xFFF97316) : const Color(0xFF62E58F),
      opacity: opacity * 0.44,
    );
    _drawGlow(
      canvas,
      center: Offset(-20 - horizontalDrift * 0.4, size.height * 0.47),
      width: 105,
      height: sideHeight * 0.66,
      color: companion ? const Color(0xFFFDBA74) : const Color(0xFF93C5FD),
      opacity: opacity * 0.20,
    );
    _drawGlow(
      canvas,
      center: Offset(size.width * 0.48 + horizontalDrift, size.height + 12),
      width: size.width * 0.64,
      height: 125,
      color: companion ? const Color(0xFFFB923C) : const Color(0xFFFACC15),
      opacity: opacity * 0.48,
    );
    _drawGlow(
      canvas,
      center: Offset(size.width * 0.82 - horizontalDrift, size.height + 6),
      width: size.width * 0.46,
      height: 120,
      color: const Color(0xFF60A5FA),
      opacity: opacity * 0.30,
    );
    _drawGlow(
      canvas,
      center: Offset(size.width + 12 - horizontalDrift, size.height * 0.76),
      width: 145,
      height: sideHeight * 0.62,
      color: const Color(0xFFC084FC),
      opacity: opacity * 0.40,
    );
    _drawGlow(
      canvas,
      center: Offset(
        size.width + 18 + horizontalDrift * 0.5,
        size.height * 0.27 + verticalDrift,
      ),
      width: 110,
      height: sideHeight * 0.72,
      color: const Color(0xFFFB7185),
      opacity: opacity * 0.34,
    );
  }

  double _bloomEnvelope(double timeline) {
    if (timeline < 0.10) {
      return Curves.easeOut.transform(timeline / 0.10);
    }
    if (timeline < 0.56) return 1;
    return 1 - Curves.easeInCubic.transform((timeline - 0.56) / 0.44);
  }

  void _drawGlow(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required Color color,
    required double opacity,
  }) {
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.46),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.42, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant VoiceEdgePainter oldDelegate) =>
      oldDelegate.entranceProgress != entranceProgress ||
      oldDelegate.ambientProgress != ambientProgress ||
      oldDelegate.activityIntensity != activityIntensity ||
      oldDelegate.activity != activity ||
      oldDelegate.radius != radius ||
      oldDelegate.reduceMotion != reduceMotion ||
      oldDelegate.companion != companion;
}
