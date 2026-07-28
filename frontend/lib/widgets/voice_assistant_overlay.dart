import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/scheme_model.dart';
import '../models/user_profile.dart';
import '../services/assistant_session_controller.dart';
import '../services/intelligent_scheme_search.dart';
import '../services/scheme_understanding_engine.dart';
import '../services/speech_output_controller.dart';
import '../services/voice_recognition_controller.dart';

enum _VoiceAssistantPhase {
  starting,
  listening,
  processing,
  ready,
  unavailable,
}

enum VoiceInputLanguage { english, tamil }

enum VoiceEdgeActivity { idle, listening, processing, speaking }

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
  final bool autoStart;

  @override
  State<VoiceAssistantOverlay> createState() => _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends State<VoiceAssistantOverlay>
    with TickerProviderStateMixin {
  late final VoiceRecognitionController _recognitionController;
  late final SpeechOutputController _speechOutputController;
  late final bool _ownsRecognitionController;
  late final bool _ownsSpeechOutputController;
  late final bool _ownsSessionController;
  AssistantSessionController? _sessionController;
  late final AnimationController _edgeController;
  late final AnimationController _edgeRevealController;
  late final AnimationController _pulseController;
  late final AnimationController _waveController;
  late final ValueNotifier<double> _edgeIntensity;
  late final ValueNotifier<double> _soundLevel;
  late final Listenable _edgeRepaint;
  late final VoiceEdgeGeometryCache _edgeGeometryCache;
  bool _reduceEdgeMotion = false;

  _VoiceAssistantPhase _voicePhase = _VoiceAssistantPhase.starting;
  String _transcript = '';
  String? _message;
  String? _detectedLanguage;
  String? _fallbackReason;
  VoiceInputLanguage _fallbackLanguage = VoiceInputLanguage.english;
  VoiceRecognitionCapabilities? _recognitionCapabilities;
  SpeechOutputCapabilities? _speechCapabilities;
  bool _showFallbackPicker = false;
  bool _startingRecognition = false;
  bool _speaking = false;
  bool _closing = false;
  List<SchemeSearchMatch> _legacyMatches = const [];
  bool _legacySearching = false;
  int _operationGeneration = 0;
  String? _lastSpokenQuestion;
  DateTime _lastSoundLevelUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _isListening => _voicePhase == _VoiceAssistantPhase.listening;
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
      _sessionController = AssistantSessionController(
        engine:
            widget.understandingEngine ??
            const LocalSchemeUnderstandingEngine(),
        schemes: widget.schemes,
        profile: widget.profile ?? UserProfile(),
      );
    }
    _sessionController?.addListener(_handleSessionChanged);

    final deviceLanguage = PlatformDispatcher.instance.locale.languageCode;
    _fallbackLanguage = deviceLanguage == 'ta'
        ? VoiceInputLanguage.tamil
        : VoiceInputLanguage.english;
    _edgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
    _edgeRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _edgeIntensity = ValueNotifier<double>(0.12);
    _soundLevel = ValueNotifier<double>(0.1);
    _edgeRepaint = Listenable.merge([
      _edgeController,
      _edgeRevealController,
      _edgeIntensity,
    ]);
    _edgeGeometryCache = VoiceEdgeGeometryCache();
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
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
    } else {
      _voicePhase = _VoiceAssistantPhase.ready;
    }
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
      _edgeRevealController.value = 1;
    } else {
      _edgeController.repeat();
      if (_edgeRevealController.value < 1) {
        _edgeRevealController.forward();
      }
    }
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
    });
    final question = state.question;
    if (state.phase == AssistantSessionPhase.asking && question != null) {
      final text = question.text(tamilLanguage: state.isTamil);
      if (_lastSpokenQuestion != text) {
        _lastSpokenQuestion = text;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_speakQuestionAndListen());
        });
      }
    }
  }

  Future<void> _startListening({bool preserveTranscript = false}) async {
    if (!mounted || _startingRecognition || _speaking) return;
    _startingRecognition = true;
    _operationGeneration++;
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
      setState(() {
        _voicePhase = _VoiceAssistantPhase.listening;
        _message = null;
        _showFallbackPicker = useFallback;
        _fallbackReason = useFallback ? capabilities.reason : null;
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
    if (transcript.isNotEmpty) unawaited(_processFinalTranscript(transcript));
  }

  Future<void> _processFinalTranscript(String transcript) async {
    final session = _sessionController;
    if (session != null) {
      if (session.state.question != null) {
        await session.answer(transcript);
      } else {
        await session.start(transcript, isTamil: _presentInTamil);
      }
      return;
    }
    await _legacySearch(transcript);
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
        _fallbackReason = error.message;
        _message = null;
      } else {
        _message = error.message;
      }
    });
  }

  void _handleStatus(String status) {
    if (!mounted) return;
    if (status == 'listening') {
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
    await _recognitionController.stop();
    if (!mounted) return;
    _edgeIntensity.value = 0.12;
    _soundLevel.value = 0.1;
    _setListeningAnimations(false);
    setState(() => _voicePhase = _VoiceAssistantPhase.ready);
  }

  Future<void> _toggleListening() async {
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
    final state = _session;
    final question = state?.question;
    if (state == null || question == null || _speaking) return;
    await _recognitionController.cancel();
    if (!mounted) return;
    final languageTag = state.isTamil ? 'ta-IN' : 'en-IN';
    final supported = _speechCapabilities?.supports(languageTag) ?? false;
    if (!supported) return;
    final generation = ++_operationGeneration;
    setState(() {
      _speaking = true;
      _voicePhase = _VoiceAssistantPhase.ready;
    });
    final completed = await _speechOutputController.speak(
      question.text(tamilLanguage: state.isTamil),
      languageTag: languageTag,
    );
    if (!mounted || generation != _operationGeneration) return;
    setState(() => _speaking = false);
    if (completed) {
      // Give Android audio focus a moment to move from TTS back to the mic.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted && generation == _operationGeneration) {
        await _startListening(preserveTranscript: true);
      }
    }
  }

  Future<void> _answerOption(String option) async {
    await _recognitionController.cancel();
    await _speechOutputController.stop();
    if (!mounted) return;
    setState(() {
      _speaking = false;
      _transcript = option;
    });
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
    await _processFinalTranscript(query);
  }

  Future<void> _editFact(EligibilityFact fact) async {
    final controller = TextEditingController(text: fact.value);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${_factLabel(fact.key)}'),
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Use value'),
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
        title: const Text('Review profile updates'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: candidates
                .map(
                  (fact) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_factLabel(fact.key)),
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
            child: const Text('Keep session only'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save confirmed'),
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
    widget.onClose();
  }

  @override
  void dispose() {
    _sessionController?.removeListener(_handleSessionChanged);
    if (_ownsSessionController) _sessionController?.dispose();
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
    _edgeRevealController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _edgeIntensity.dispose();
    _soundLevel.dispose();
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
                      geometryCache: _edgeGeometryCache,
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
                    color: const Color(0xFF07111F).withValues(alpha: 0.98),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFF60A5FA).withValues(alpha: 0.24),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66020A16),
                        blurRadius: 30,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 12),
                        _buildListeningArea(),
                        if (_fallbackReason != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _fallbackReason!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFBBF24),
                              fontSize: 10.5,
                            ),
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
                          const LinearProgressIndicator(
                            key: Key('voice-search-progress'),
                            minHeight: 2,
                            color: Color(0xFF60A5FA),
                            backgroundColor: Color(0xFF172554),
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
            child: Image.asset(
              'assets/images/compoanion bot.png',
              key: const Key('voice-assistant-image'),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ask IN AI',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
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
                  Text(
                    _statusLabel,
                    style: GoogleFonts.inter(
                      color: _statusColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildLanguageSelector(),
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
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _transcript.isEmpty
                      ? (_presentInTamil
                            ? 'உங்கள் நிலையை இயல்பாக சொல்லுங்கள்...'
                            : 'Tell me your situation naturally...')
                      : _transcript,
                  key: const Key('voice-transcript'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _transcript.isEmpty
                        ? const Color(0xFF94A3B8)
                        : Colors.white,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              VoiceLevelBars(
                key: const Key('voice-level-bars'),
                animation: _waveController,
                level: _soundLevel,
                active: _isListening,
              ),
              const SizedBox(width: 6),
              Semantics(
                button: true,
                label: _isListening ? 'Stop listening' : 'Start listening',
                child: IconButton.filled(
                  onPressed: _toggleListening,
                  style: IconButton.styleFrom(
                    backgroundColor: _isListening
                        ? const Color(0xFF10B981)
                        : const Color(0xFF2563EB),
                    minimumSize: const Size(48, 48),
                  ),
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (showSuggestions) ...[
            const SizedBox(height: 8),
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
        ],
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
    side: const BorderSide(color: Color(0xFF3B82F6)),
    backgroundColor: const Color(0xFF172554),
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
                    '${_factLabel(fact.key)}: ${_displayFactValue(fact)}',
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
    final text = question.text(tamilLanguage: _session!.isTamil);
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
              child: const Text('View all', style: TextStyle(fontSize: 10.5)),
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
            label: const Text('Review and save confirmed details'),
          ),
        ],
      ],
    );
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
                      scheme.name,
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
                  'Why this fits: ${recommendation.reasons.join(' • ')}',
                  const Color(0xFF86EFAC),
                ),
              if (recommendation.unknownRequirements.isNotEmpty)
                _resultLine(
                  Icons.help_outline,
                  'Still confirm: ${recommendation.unknownRequirements.take(2).join(' • ')}',
                  const Color(0xFFFCD34D),
                ),
              _resultLine(
                recommendation.isTrusted
                    ? Icons.verified_outlined
                    : Icons.warning_amber_outlined,
                recommendation.isTrusted
                    ? 'Current official source verified'
                    : 'Uncertain or historical — verify before applying',
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
                child: ListTile(
                  key: Key('voice-result-${match.scheme.id}'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Colors.white.withValues(alpha: 0.055),
                  title: Text(
                    match.scheme.name,
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
      ],
    );
  }

  static String _factLabel(EligibilityFactKey key) => switch (key) {
    EligibilityFactKey.age => 'Age',
    EligibilityFactKey.state => 'State',
    EligibilityFactKey.district => 'District',
    EligibilityFactKey.annualIncome => 'Annual income',
    EligibilityFactKey.gender => 'Gender',
    EligibilityFactKey.community => 'Community',
    EligibilityFactKey.occupation => 'Situation',
    EligibilityFactKey.education => 'Education',
    EligibilityFactKey.disability => 'Disability',
    EligibilityFactKey.maritalStatus => 'Marital status',
    EligibilityFactKey.studentStatus => 'Student',
    EligibilityFactKey.businessStage => 'Business stage',
    EligibilityFactKey.businessSector => 'Sector',
    EligibilityFactKey.fundingNeed => 'Funding need',
    EligibilityFactKey.landholding => 'Landholding',
  };

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
    required this.geometryCache,
  });

  final double entranceProgress;
  final double ambientProgress;
  final double activityIntensity;
  final VoiceEdgeActivity activity;
  final double radius;
  final bool reduceMotion;
  final VoiceEdgeGeometryCache geometryCache;

  static const _sourceColors = [
    Color(0xFF38BDF8),
    Color(0xFF2563EB),
    Color(0xFFA855F7),
    Color(0xFFF472B6),
  ];

  static const _sourcePositions = [0.03, 0.29, 0.55, 0.79];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final geometry = geometryCache.resolve(size, radius);
    final path = geometry.path;
    final metric = geometry.metric;
    final rect = geometry.rect;
    final reveal = Curves.easeOutCubic.transform(
      entranceProgress.clamp(0.0, 1.0),
    );
    final phase = reduceMotion ? 0.0 : ambientProgress * math.pi * 2;
    final breath = reduceMotion ? 0.5 : (math.sin(phase) + 1) / 2;
    final level = activityIntensity.clamp(0.0, 1.0);
    final strength = switch (activity) {
      VoiceEdgeActivity.idle => 0.38 + breath * 0.05,
      VoiceEdgeActivity.listening => 0.62 + level * 0.36,
      VoiceEdgeActivity.processing => 0.50 + breath * 0.10,
      VoiceEdgeActivity.speaking => 0.58 + breath * 0.14,
    };
    final gradientRotation = reduceMotion
        ? 0.0
        : math.sin(phase) * 0.10 + math.sin(phase * 2) * 0.025;
    final perimeterGradient = SweepGradient(
      transform: GradientRotation(gradientRotation),
      colors: const [
        Color(0xFF38BDF8),
        Color(0xFF2563EB),
        Color(0xFFA855F7),
        Color(0xFFF472B6),
        Color(0xFF22D3EE),
        Color(0xFF38BDF8),
      ],
      stops: const [0, 0.20, 0.42, 0.62, 0.82, 1],
    );

    // A faint full-perimeter haze makes the final state feel continuous. It
    // fades in behind the four expanding sources, so no side becomes a visual
    // starting point during the entrance.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18 + strength * 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9)
        ..shader = perimeterGradient.createShader(rect)
        ..colorFilter = ColorFilter.mode(
          Colors.white.withValues(alpha: reveal * reveal * strength * 0.34),
          BlendMode.modulate,
        ),
    );

    final halfSpan = metric.length * (0.015 + reveal * 0.145);
    for (var index = 0; index < _sourcePositions.length; index++) {
      final localPhase = phase + index * math.pi * 0.73;
      final drift = reduceMotion
          ? 0.0
          : math.sin(localPhase) * 0.018 + math.sin(localPhase * 1.7) * 0.006;
      final center = metric.length * (_sourcePositions[index] + drift);
      final segment = _extractWrappedPath(
        metric,
        center - halfSpan,
        center + halfSpan,
      );
      final color = _sourceColors[index];
      canvas.drawPath(
        segment,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9 + strength * 5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5)
          ..color = color.withValues(alpha: reveal * strength * 0.62),
      );
    }

    // The crisp core remains unbroken after the source segments merge, while
    // the brighter lobes above it drift independently rather than orbiting as
    // one obvious sweep.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1 + strength * 1.7
        ..strokeCap = StrokeCap.round
        ..shader = perimeterGradient.createShader(rect)
        ..colorFilter = ColorFilter.mode(
          Colors.white.withValues(alpha: reveal * (0.50 + strength * 0.42)),
          BlendMode.modulate,
        ),
    );
  }

  Path _extractWrappedPath(PathMetric metric, double start, double end) {
    final length = metric.length;
    final span = (end - start).clamp(0.0, length);
    if (span >= length) return metric.extractPath(0, length);
    final normalizedStart = ((start % length) + length) % length;
    final normalizedEnd = normalizedStart + span;
    if (normalizedEnd <= length) {
      return metric.extractPath(normalizedStart, normalizedEnd);
    }
    return Path()
      ..addPath(metric.extractPath(normalizedStart, length), Offset.zero)
      ..addPath(metric.extractPath(0, normalizedEnd - length), Offset.zero);
  }

  @override
  bool shouldRepaint(covariant VoiceEdgePainter oldDelegate) =>
      oldDelegate.entranceProgress != entranceProgress ||
      oldDelegate.ambientProgress != ambientProgress ||
      oldDelegate.activityIntensity != activityIntensity ||
      oldDelegate.activity != activity ||
      oldDelegate.radius != radius ||
      oldDelegate.reduceMotion != reduceMotion;
}

class VoiceEdgeGeometryCache {
  Size? _size;
  double? _radius;
  VoiceEdgeGeometry? _geometry;

  VoiceEdgeGeometry resolve(Size size, double radius) {
    if (_geometry != null && _size == size && _radius == radius) {
      return _geometry!;
    }
    const inset = 1.25;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      math.max(0, size.width - inset * 2),
      math.max(0, size.height - inset * 2),
    );
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final geometry = VoiceEdgeGeometry(
      rect: rect,
      path: path,
      metric: path.computeMetrics().first,
    );
    _size = size;
    _radius = radius;
    _geometry = geometry;
    return geometry;
  }
}

@immutable
class VoiceEdgeGeometry {
  const VoiceEdgeGeometry({
    required this.rect,
    required this.path,
    required this.metric,
  });

  final Rect rect;
  final Path path;
  final PathMetric metric;
}
