import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/app_state_provider.dart';
import '../../models/scheme_model.dart';
import '../../services/assistant_session_controller.dart';
import '../../services/edge_slm_understanding_engine.dart';
import '../../services/scheme_understanding_engine.dart';
import '../../services/speech_output_controller.dart';
import '../../services/voice_recognition_controller.dart';
import '../profile_screen.dart';
import '../notifications_screen.dart';
import '../regular_mode/scheme_details_screen.dart';

enum SaarthiVoiceState {
  idle,
  listening,
  processing,
  speaking,
  ended,
}

class SaarthiMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String text;
  final DateTime timestamp;
  final String? status; // 'transcribing' | null
  final List<Scheme>? schemeResults;
  final String? speakingState; // 'speaking' | null

  SaarthiMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.status,
    this.schemeResults,
    this.speakingState,
  });

  SaarthiMessage copyWith({
    String? text,
    String? status,
    List<Scheme>? schemeResults,
    String? speakingState,
  }) {
    return SaarthiMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      timestamp: timestamp,
      status: status ?? this.status,
      schemeResults: schemeResults ?? this.schemeResults,
      speakingState: speakingState ?? this.speakingState,
    );
  }
}

class SaarthiHomeScreen extends StatefulWidget {
  const SaarthiHomeScreen({super.key});

  @override
  State<SaarthiHomeScreen> createState() => _SaarthiHomeScreenState();
}

class _SaarthiHomeScreenState extends State<SaarthiHomeScreen> with TickerProviderStateMixin {
  // State variables for conversation mode
  bool _isConversationActive = false;
  bool _isKeyboardMode = false;
  bool _isUserScrolling = false;
  final List<SaarthiMessage> _messages = [];
  String _partialUserTranscript = '';

  // State machine voice state
  SaarthiVoiceState _voiceState = SaarthiVoiceState.idle;

  // Controllers
  late final AutomaticVoiceRecognitionController _recognitionController;
  late final NativeSpeechOutputController _speechOutputController;
  AssistantSessionController? _sessionController;

  // Animation controllers
  late final AnimationController _pulseController;
  late final AnimationController _waveController;
  late final ValueNotifier<double> _soundLevel;

  // Internal states
  VoiceRecognitionCapabilities? _recognitionCapabilities;
  bool _startingRecognition = false;
  bool _speaking = false;
  int _recognitionGeneration = 0;
  String? _lastSpokenTurn;
  String? _lastFinalTranscript;
  int _lastFinalRecognitionGeneration = -1;
  DateTime _lastSoundLevelUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  bool _controllersInitialized = false;

  final TextEditingController _textInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers immediately for vsync
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.82,
      upperBound: 1.0,
      value: 1.0,
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _soundLevel = ValueNotifier<double>(0.1);
  }

  void _initializeControllers() {
    if (_controllersInitialized) return;
    _controllersInitialized = true;

    final provider = Provider.of<AppProvider>(context, listen: false);
    _recognitionController = AutomaticVoiceRecognitionController();
    _speechOutputController = NativeSpeechOutputController();

    final engine = EdgeSlmUnderstandingEngine.standard();
    unawaited(engine.prepare());

    _sessionController = AssistantSessionController(
      engine: engine,
      schemes: provider.allSchemes,
      profile: provider.profile,
    );
    _sessionController!.addListener(_handleSessionChanged);

    _initializeSpeechOutput();

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        final isAtBottom = maxScroll - currentScroll < 40;

        if (isAtBottom && _isUserScrolling) {
          setState(() {
            _isUserScrolling = false;
          });
        } else if (!isAtBottom && !_isUserScrolling) {
          setState(() {
            _isUserScrolling = true;
          });
        }
      }
    });
  }

  Future<void> _initializeSpeechOutput() async {
    await _speechOutputController.initialize();
  }

  @override
  void dispose() {
    if (_controllersInitialized) {
      _sessionController?.removeListener(_handleSessionChanged);
      _sessionController?.dispose();
      _recognitionController.dispose();
      _speechOutputController.dispose();
    }
    _pulseController.dispose();
    _waveController.dispose();
    _soundLevel.dispose();
    _textInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startConversationMode() {
    _initializeControllers();

    setState(() {
      _isConversationActive = true;
      _voiceState = SaarthiVoiceState.listening;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening(preserveTranscript: false);
    });
  }

  Future<void> _startListening({bool preserveTranscript = false}) async {
    if (!mounted || _startingRecognition || _speaking) return;
    _startingRecognition = true;
    _recognitionGeneration++;
    _lastFinalTranscript = null;
    _lastFinalRecognitionGeneration = -1;
    await _speechOutputController.stop();
    if (!mounted) return;
    _setListeningAnimations(false);
    setState(() {
      _voiceState = SaarthiVoiceState.listening;
      if (!preserveTranscript) {
        _partialUserTranscript = '';
      }
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
        _setListeningAnimations(false);
        setState(() {
          _voiceState = SaarthiVoiceState.idle;
        });
        return;
      }

      setState(() {
        _voiceState = SaarthiVoiceState.listening;
      });
      _sessionController?.setListening(
        transcript: preserveTranscript ? _partialUserTranscript : '',
      );
      _setListeningAnimations(true);

      final provider = Provider.of<AppProvider>(context, listen: false);
      final isTamil = provider.selectedLanguage == 'ta';
      await _recognitionController.listen(
        localeId: isTamil ? 'ta-IN' : 'en-IN',
      );
      if (mounted && !_recognitionController.isListening) {
        _setListeningAnimations(false);
      }
    } catch (_) {
      if (!mounted) return;
      _setListeningAnimations(false);
      setState(() {
        _voiceState = SaarthiVoiceState.idle;
      });
    } finally {
      _startingRecognition = false;
    }
  }

  Future<void> _stopListening() async {
    await _recognitionController.stop();
    if (!mounted) return;
    _setListeningAnimations(false);
    setState(() {
      _voiceState = SaarthiVoiceState.idle;
    });
  }

  Future<void> _endConversation() async {
    _sessionController?.cancel();
    await _speechOutputController.stop();
    await _recognitionController.cancel();
    _setListeningAnimations(false);

    setState(() {
      _isConversationActive = false;
      _isKeyboardMode = false;
      _voiceState = SaarthiVoiceState.ended;
      _messages.clear();
      _partialUserTranscript = '';
    });
  }

  void _handleResult(VoiceRecognitionResult result) {
    if (!mounted) return;
    final transcript = result.transcript.trim();

    setState(() {
      _partialUserTranscript = transcript;
      _updateLiveUserTranscript(transcript, isFinal: result.isFinal);
      if (result.isFinal) {
        _voiceState = SaarthiVoiceState.processing;
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
    unawaited(_processFinalTranscript(transcript));
  }

  void _updateLiveUserTranscript(String text, {required bool isFinal}) {
    if (text.isEmpty) return;

    if (_messages.isNotEmpty && _messages.last.role == 'user' && _messages.last.status == 'transcribing') {
      setState(() {
        _messages[_messages.length - 1] = _messages.last.copyWith(
          text: text,
          status: isFinal ? null : 'transcribing',
        );
      });
    } else {
      final newMsg = SaarthiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        text: text,
        timestamp: DateTime.now(),
        status: isFinal ? null : 'transcribing',
      );
      setState(() {
        _messages.add(newMsg);
      });
    }
    _scrollToBottom();
  }

  Future<void> _processFinalTranscript(String transcript) async {
    final value = transcript.trim();
    if (value.isEmpty) return;

    final session = _sessionController;
    if (session != null) {
      if (session.state.question != null) {
        await session.answer(value);
      } else {
        _lastSpokenTurn = null;
        final provider = Provider.of<AppProvider>(context, listen: false);
        await session.start(value, isTamil: provider.selectedLanguage == 'ta');
      }
    }
  }

  void _handleSessionChanged() {
    if (!mounted || !_isConversationActive) return;
    final state = _sessionController!.state;

    if (state.phase == AssistantSessionPhase.understanding) {
      setState(() {
        _voiceState = SaarthiVoiceState.processing;
      });
    } else if (state.phase == AssistantSessionPhase.asking && state.question != null) {
      final question = state.question!;
      final questionText = _questionText(state, question);

      final turnKey = 'asking|${state.questionsAsked}|${question.factKey.name}';
      if (_lastSpokenTurn != turnKey) {
        _lastSpokenTurn = turnKey;
        _speakAndShowResponse(questionText, state.isTamil ? 'ta-IN' : 'en-IN', questionOptions: question.options);
      }
    } else if ((state.phase == AssistantSessionPhase.results ||
                state.phase == AssistantSessionPhase.noConfidentMatch) &&
               state.reply != null) {
      final reply = state.reply!;

      final turnKey = 'reply|${reply.topic}|${reply.displayText}';
      if (_lastSpokenTurn != turnKey) {
        _lastSpokenTurn = turnKey;

        final schemes = state.recommendations.map((r) => r.scheme).toList();
        _speakAndShowResponse(reply.displayText, reply.languageTag, schemes: schemes);
      }
    } else if (state.phase == AssistantSessionPhase.error) {
      setState(() {
        _voiceState = SaarthiVoiceState.idle;
      });
      _addAssistantMessage(state.message ?? 'An error occurred. Please try again.');
    }
  }

  Future<void> _speakAndShowResponse(String text, String languageTag, {List<String>? questionOptions, List<Scheme>? schemes}) async {
    await _recognitionController.cancel();
    _setListeningAnimations(false);

    setState(() {
      _voiceState = SaarthiVoiceState.speaking;
      _speaking = true;
    });

    final speakFuture = _speechOutputController.speak(text, languageTag: languageTag);

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final words = text.split(' ');
    int wordIndex = 0;

    final msg = SaarthiMessage(
      id: messageId,
      role: 'assistant',
      text: '',
      timestamp: DateTime.now(),
      speakingState: 'speaking',
    );

    setState(() {
      _messages.add(msg);
    });
    _scrollToBottom();

    Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (!mounted || !_isConversationActive) {
        t.cancel();
        return;
      }

      if (wordIndex >= words.length) {
        t.cancel();
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == messageId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              text: text,
              schemeResults: schemes,
              speakingState: null,
            );
          }
        });
        _scrollToBottom();
        return;
      }

      setState(() {
        final idx = _messages.indexWhere((m) => m.id == messageId);
        if (idx != -1) {
          final partial = words.sublist(0, wordIndex + 1).join(' ');
          _messages[idx] = _messages[idx].copyWith(
            text: partial,
          );
        }
      });
      _scrollToBottom();
      wordIndex++;
    });

    final completed = await speakFuture;

    if (mounted) {
      setState(() {
        _speaking = false;
      });
    }

    if (completed && mounted && _isConversationActive) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted && _isConversationActive) {
        await _startListening(preserveTranscript: false);
      }
    }
  }

  void _sendTypedQuestion(String text) {
    if (text.trim().isEmpty) return;

    final userMsg = SaarthiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isKeyboardMode = false;
      _voiceState = SaarthiVoiceState.processing;
    });
    _scrollToBottom();

    final session = _sessionController;
    if (session != null) {
      final state = session.state;
      if (state.question != null) {
        session.answer(text);
      } else {
        _lastSpokenTurn = null;
        session.start(text, isTamil: state.isTamil);
      }
    }
  }

  void _scrollToBottom() {
    if (_isUserScrolling) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToLatest() {
    setState(() {
      _isUserScrolling = false;
    });
    _scrollToBottom();
  }

  void _setListeningAnimations(bool listening) {
    if (listening) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
      if (!_waveController.isAnimating) _waveController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0;
      _waveController.stop();
      _waveController.value = 0.0;
    }
  }

  void _handleStatus(String status) {
    if (!mounted) return;
    if (status == 'listening') {
      _setListeningAnimations(true);
      setState(() => _voiceState = SaarthiVoiceState.listening);
    } else if (status == 'processing') {
      _setListeningAnimations(false);
      setState(() => _voiceState = SaarthiVoiceState.processing);
    } else if (status == 'done' || status == 'notListening') {
      _setListeningAnimations(false);
    }
  }

  void _handleSoundLevel(double level) {
    if (!mounted) return;
    final now = DateTime.now();
    if (now.difference(_lastSoundLevelUpdate) < const Duration(milliseconds: 66)) {
      return;
    }
    _lastSoundLevelUpdate = now;
    final normalizedLevel = ((level + 2) / 12).clamp(0.0, 1.0);
    _soundLevel.value = normalizedLevel;
  }

  void _handleLanguage(String language) {}

  void _handleError(VoiceRecognitionError error) {
    if (!mounted) return;
    _setListeningAnimations(false);
    setState(() {
      _voiceState = SaarthiVoiceState.idle;
    });
    _addAssistantMessage(error.message);
  }

  void _addAssistantMessage(String text) {
    setState(() {
      _messages.add(SaarthiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        text: text,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  Future<void> _handleControllerMicTap() async {
    if (_voiceState == SaarthiVoiceState.listening) {
      await _stopListening();
    } else if (_voiceState == SaarthiVoiceState.speaking) {
      await _speechOutputController.stop();
      setState(() {
        _voiceState = SaarthiVoiceState.listening;
      });
      await _startListening(preserveTranscript: false);
    } else {
      await _startListening(preserveTranscript: false);
    }
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

  Color _getStatusColor() {
    switch (_voiceState) {
      case SaarthiVoiceState.listening:
        return const Color(0xFF2563EB);
      case SaarthiVoiceState.processing:
        return const Color(0xFFF59E0B);
      case SaarthiVoiceState.speaking:
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  String _getStatusLabel() {
    switch (_voiceState) {
      case SaarthiVoiceState.listening:
        return 'Listening...';
      case SaarthiVoiceState.processing:
        return 'Thinking...';
      case SaarthiVoiceState.speaking:
        return 'Saarthi is speaking...';
      default:
        return 'Idle';
    }
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final userName = provider.profile.name.isNotEmpty
        ? provider.profile.name.split(' ')[0]
        : 'Praveen';

    const Color kBrandBlue = Color(0xFF2563EB);
    const Color kDarkSlate = Color(0xFF0F172A);
    const Color kSlate500 = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top bar: Language Pill & Notifications / Profile Avatar
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
              child: _buildTopBar(provider, kDarkSlate, kBrandBlue, kSlate500),
            ),

            // 2. Character Welcome Banner / Compact Header
            _buildCharacterHeader(userName, kDarkSlate, kBrandBlue, kSlate500),

            // 3. Expanded content area
            Expanded(
              child: _isConversationActive
                  ? _buildTranscriptSection()
                  : const SizedBox.shrink(),
            ),

            // 4. Bottom Control panel
            _buildBottomPanel(kBrandBlue, kDarkSlate, kSlate500),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AppProvider provider, Color kDarkSlate, Color kBrandBlue, Color kSlate500) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Language Pill selector
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.language,
                color: Color(0xFF2563EB),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                provider.selectedLanguage == 'ta' ? 'தமிழ்' : 'English',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: kDarkSlate,
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF64748B),
                size: 16,
              ),
            ],
          ),
        ),
        // Notification icon & Profile photo
        Row(
          children: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF0F172A),
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                if (provider.notifications.any((n) => n['read'] == false))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEFF6FF),
                child: ClipOval(
                  child: () {
                    final photo = provider.profile.profilePhoto;
                    if (photo.isEmpty) {
                      return Image.asset(
                        'assets/images/supporting assets/user_avatar.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      );
                    }
                    if (photo.startsWith('http://') || photo.startsWith('https://')) {
                      return Image.network(
                        photo,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      );
                    }
                    final file = File(photo);
                    if (file.existsSync()) {
                      return Image.file(
                        file,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      );
                    }
                    return Image.asset(
                      'assets/images/supporting assets/user_avatar.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    );
                  }(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCharacterHeader(String userName, Color kDarkSlate, Color kBrandBlue, Color kSlate500) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                width: _isConversationActive ? 56 : 170,
                height: _isConversationActive ? 56 : 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEFF6FF),
                  border: Border.all(
                    color: const Color(0xFFDBEAFE),
                    width: _isConversationActive ? 2 : 4,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/saarthi/sarathi.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (!_isConversationActive) ...[
                const Positioned(
                  left: 0,
                  top: 55,
                  child: Icon(
                    Icons.star,
                    color: Color(0xFF93C5FD),
                    size: 14,
                  ),
                ),
                const Positioned(
                  right: 0,
                  top: 45,
                  child: Icon(
                    Icons.star,
                    color: Color(0xFF93C5FD),
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isConversationActive
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Column(
            children: [
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kDarkSlate,
                    ),
                    children: [
                      const TextSpan(text: 'Good Morning, '),
                      TextSpan(
                        text: '$userName! 👋',
                        style: const TextStyle(color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: kDarkSlate,
                    ),
                    children: const [
                      TextSpan(text: "I'm "),
                      TextSpan(
                        text: 'Saarthi',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ', your AI companion for\nMSME success.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          secondChild: Column(
            children: [
              Center(
                child: Text(
                  'AI Saarthi',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kDarkSlate,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _getStatusLabel(),
                      style: GoogleFonts.inter(
                        color: _getStatusColor(),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTranscriptSection() {
    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final message = _messages[index];
            return _buildMessageItem(message);
          },
        ),
        if (_isUserScrolling)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _scrollToLatest,
                icon: const Icon(Icons.arrow_downward, size: 16, color: Colors.white),
                label: const Text('Latest', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageItem(SaarthiMessage message) {
    if (message.role == 'user') {
      return _buildUserMessage(message);
    } else {
      return _buildAiMessage(message);
    }
  }

  Widget _buildUserMessage(SaarthiMessage message) {
    final timeStr = _formatTimestamp(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFEFF6FF),
            child: ClipOval(
              child: Image.asset(
                'assets/images/supporting assets/user_avatar.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'You',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: const Color(0xFFEFF6FF), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAiMessage(SaarthiMessage message) {
    final timeStr = _formatTimestamp(message.timestamp);
    final isSpeaking = message.speakingState == 'speaking';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI Saarthi',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(0),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      if (isSpeaking) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildWaveformBar(6, 12),
                            _buildWaveformBar(9, 6),
                            _buildWaveformBar(12, 14),
                            _buildWaveformBar(7, 8),
                            _buildWaveformBar(10, 10),
                            const SizedBox(width: 6),
                            Text(
                              'Saarthi is speaking...',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (message.schemeResults != null && message.schemeResults!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...message.schemeResults!.map((scheme) => _buildCompactSchemeCard(scheme)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFEFF6FF),
            child: ClipOval(
              child: Image.asset(
                'assets/images/saarthi/sarathi.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformBar(double height, double animDelay) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final scale = 0.5 + 0.5 * math.sin(_waveController.value * math.pi * 2 + animDelay);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 2.5,
          height: height * scale,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      },
    );
  }

  Widget _buildCompactSchemeCard(Scheme scheme) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SchemeDetailsScreen(scheme: scheme),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFF6FF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildSchemeIcon(scheme.name),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scheme.name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scheme.overview.length > 50
                        ? '${scheme.overview.substring(0, 47)}...'
                        : scheme.overview,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemeIcon(String schemeName) {
    final lower = schemeName.toLowerCase();
    String emoji = '🏢';
    Color bg = const Color(0xFFEFF6FF);

    if (lower.contains('pmegp')) {
      emoji = '🏭';
      bg = const Color(0xFFEFF6FF);
    } else if (lower.contains('cgtmse')) {
      emoji = '💰';
      bg = const Color(0xFFECFDF5);
    } else if (lower.contains('mse-cdp')) {
      emoji = '⚙️';
      bg = const Color(0xFFF5F3FF);
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildBottomPanel(Color kBrandBlue, Color kDarkSlate, Color kSlate500) {
    if (!_isConversationActive) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ask Saarthi Card (The Box)
            GestureDetector(
              onTap: _startConversationMode,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEFF6FF),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kBrandBlue.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Ask Saarthi anything...',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: kDarkSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap the mic to speak or type your question',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: kSlate500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Type your question...',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: kSlate500,
                            ),
                          ),
                          Icon(
                            Icons.keyboard,
                            color: kBrandBlue,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Mic and Waves (Outside the Box)
            GestureDetector(
              onTap: _startConversationMode,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: List.generate(8, (index) {
                        final h = (index % 3 == 0)
                            ? 14.0
                            : ((index % 2 == 0) ? 8.0 : 4.0);
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 1.5,
                          ),
                          width: 2,
                          height: h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF93C5FD),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kBrandBlue,
                        boxShadow: [
                          BoxShadow(
                            color: kBrandBlue.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: List.generate(8, (index) {
                        final h = (index % 3 == 0)
                            ? 14.0
                            : ((index % 2 == 0) ? 8.0 : 4.0);
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 1.5,
                          ),
                          width: 2,
                          height: h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF93C5FD),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isKeyboardMode) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textInputController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (val) {
                          _sendTypedQuestion(val);
                          _textInputController.clear();
                        },
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Type your question...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Color(0xFF2563EB)),
                      onPressed: () {
                        _sendTypedQuestion(_textInputController.text);
                        _textInputController.clear();
                      },
                    ),
                  ],
                ),
              ),
            ],
            Text(
              _getVoiceStatusText(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isKeyboardMode = !_isKeyboardMode;
                          });
                        },
                        icon: Icon(
                          Icons.keyboard,
                          color: _isKeyboardMode ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                          size: 24,
                        ),
                      ),
                      Text(
                        'Keyboard',
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildControllerDots(isLeft: true),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _handleControllerMicTap,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_voiceState == SaarthiVoiceState.listening || _voiceState == SaarthiVoiceState.speaking)
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 66 * _pulseController.value,
                                  height: 66 * _pulseController.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                  ),
                                );
                              },
                            ),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF2563EB),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              _getMicIcon(),
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildControllerDots(isLeft: false),
                  ],
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _endConversation,
                        icon: const Icon(
                          Icons.delete_sweep_outlined,
                          color: Color(0xFF64748B),
                          size: 28,
                        ),
                      ),
                      Text(
                        'Clear Chat 🧹',
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  'Tap stop when you\'re done speaking',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  IconData _getMicIcon() {
    switch (_voiceState) {
      case SaarthiVoiceState.listening:
        return Icons.mic;
      case SaarthiVoiceState.processing:
        return Icons.hourglass_empty;
      case SaarthiVoiceState.speaking:
        return Icons.volume_up;
      default:
        return Icons.mic_none;
    }
  }

  String _getVoiceStatusText() {
    switch (_voiceState) {
      case SaarthiVoiceState.listening:
        return 'Listening...';
      case SaarthiVoiceState.processing:
        return 'Thinking...';
      case SaarthiVoiceState.speaking:
        return 'Saarthi is speaking...';
      default:
        return 'Ready';
    }
  }

  Widget _buildControllerDots({required bool isLeft}) {
    final active = _voiceState == SaarthiVoiceState.listening || _voiceState == SaarthiVoiceState.speaking;

    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final hFactor = active ? math.sin(_waveController.value * math.pi * 2 + (index * 0.5) + (isLeft ? 0 : math.pi)) : 0.0;
            final dotHeight = 3.0 + 10.0 * (hFactor.abs());

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3.0,
              height: active ? dotHeight : 3.0,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }
}
