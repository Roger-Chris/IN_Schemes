import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/scheme_model.dart';
import '../services/intelligent_scheme_search.dart';

enum _VoiceAssistantPhase { starting, listening, ready, unavailable }

enum VoiceInputLanguage { english, tamil }

class VoiceAssistantOverlay extends StatefulWidget {
  const VoiceAssistantOverlay({
    super.key,
    required this.onClose,
    required this.onSubmit,
    this.onSearch,
    this.onSchemeSelected,
    this.autoStart = true,
  });

  final VoidCallback onClose;
  final ValueChanged<String> onSubmit;
  final Future<List<SchemeSearchMatch>> Function(String query)? onSearch;
  final ValueChanged<Scheme>? onSchemeSelected;
  final bool autoStart;

  @override
  State<VoiceAssistantOverlay> createState() => _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends State<VoiceAssistantOverlay>
    with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  late final AnimationController _edgeController;
  late final AnimationController _pulseController;
  late final AnimationController _waveController;
  late final ValueNotifier<double> _edgeIntensity;
  late final Listenable _edgeRepaint;

  _VoiceAssistantPhase _phase = _VoiceAssistantPhase.starting;
  String _transcript = '';
  String? _message;
  VoiceInputLanguage _language = VoiceInputLanguage.english;
  List<SchemeSearchMatch> _matches = const [];
  bool _isSearching = false;
  int _searchGeneration = 0;
  String _lastSearchedQuery = '';
  DateTime _lastSoundLevelUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _isListening => _phase == _VoiceAssistantPhase.listening;
  bool get _hasTranscript => _transcript.trim().isNotEmpty;
  bool get _hasSearch => widget.onSearch != null;
  String get _statusLabel {
    if (_isListening) return 'Listening...';
    if (_isSearching) return 'Finding...';
    if (_matches.isNotEmpty) return 'Found ${_matches.length}';
    return 'Ready';
  }

  Color get _statusColor => _isListening
      ? const Color(0xFF10B981)
      : _isSearching
      ? const Color(0xFFF59E0B)
      : _matches.isNotEmpty
      ? const Color(0xFF60A5FA)
      : const Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _edgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _edgeIntensity = ValueNotifier<double>(0.12);
    _edgeRepaint = Listenable.merge([_edgeController, _edgeIntensity]);
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

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
    } else {
      _phase = _VoiceAssistantPhase.ready;
    }
  }

  Future<void> _startListening() async {
    if (!mounted) return;
    _setListeningAnimations(false);
    setState(() {
      _phase = _VoiceAssistantPhase.starting;
      _message = null;
    });

    try {
      final available = await _speech.initialize(
        onStatus: _handleStatus,
        onError: (error) {
          if (!mounted) return;
          _edgeIntensity.value = 0.12;
          _setListeningAnimations(false);
          setState(() {
            _phase = _VoiceAssistantPhase.unavailable;
            _message = error.errorMsg == 'error_permission'
                ? 'Microphone permission is needed for voice search.'
                : 'I could not hear you. Tap the microphone to try again.';
          });
        },
      );

      if (!mounted) return;
      if (!available) {
        _edgeIntensity.value = 0.12;
        _setListeningAnimations(false);
        setState(() {
          _phase = _VoiceAssistantPhase.unavailable;
          _message = 'Voice recognition is not available on this device.';
        });
        return;
      }

      setState(() {
        _phase = _VoiceAssistantPhase.listening;
        _message = null;
      });
      _edgeIntensity.value = 0.25;
      _setListeningAnimations(true);

      await _speech.listen(
        onResult: _handleResult,
        onSoundLevelChange: (level) {
          if (!mounted) return;
          final now = DateTime.now();
          if (now.difference(_lastSoundLevelUpdate) <
              const Duration(milliseconds: 66)) {
            return;
          }
          _lastSoundLevelUpdate = now;
          final normalizedLevel = ((level + 2) / 12).clamp(0.0, 1.0);
          _edgeIntensity.value = math.max(0.25, normalizedLevel);
        },
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          listenMode: ListenMode.search,
          autoPunctuation: true,
          listenFor: Duration(seconds: 30),
          pauseFor: Duration(seconds: 4),
          localeId: await _localeIdFor(_language),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _edgeIntensity.value = 0.12;
      _setListeningAnimations(false);
      setState(() {
        _phase = _VoiceAssistantPhase.unavailable;
        _message = 'Voice recognition could not start. Please try again.';
      });
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    if (_transcript == result.recognizedWords && !result.finalResult) return;
    setState(() {
      _transcript = result.recognizedWords;
      if (result.finalResult) {
        _phase = _VoiceAssistantPhase.ready;
        _setListeningAnimations(false);
      }
    });
    if (result.finalResult && _hasSearch) {
      unawaited(_searchTranscript());
    }
  }

  void _handleStatus(String status) {
    if (!mounted) return;
    if (status == SpeechToText.listeningStatus) {
      _edgeIntensity.value = 0.25;
      _setListeningAnimations(true);
      if (_phase != _VoiceAssistantPhase.listening) {
        setState(() => _phase = _VoiceAssistantPhase.listening);
      }
    } else if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _edgeIntensity.value = 0.12;
      _setListeningAnimations(false);
      setState(() {
        _phase = _VoiceAssistantPhase.ready;
      });
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (!mounted) return;
    _edgeIntensity.value = 0.12;
    _setListeningAnimations(false);
    setState(() {
      _phase = _VoiceAssistantPhase.ready;
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<String?> _localeIdFor(VoiceInputLanguage language) async {
    final requestedPrefix = language == VoiceInputLanguage.tamil ? 'ta' : 'en';
    final preferredRegion = language == VoiceInputLanguage.tamil
        ? 'ta-in'
        : 'en-in';
    try {
      final locales = await _speech.locales();
      String normalized(String locale) =>
          locale.toLowerCase().replaceAll('_', '-');
      for (final locale in locales) {
        if (normalized(locale.localeId) == preferredRegion) {
          return locale.localeId;
        }
      }
      for (final locale in locales) {
        if (normalized(locale.localeId).startsWith('$requestedPrefix-')) {
          return locale.localeId;
        }
      }
    } catch (_) {
      // Let the platform use its default locale when locale discovery fails.
    }
    return null;
  }

  Future<void> _changeLanguage(VoiceInputLanguage language) async {
    if (_language == language) return;
    _searchGeneration++;
    await _speech.cancel();
    if (!mounted) return;
    setState(() {
      _language = language;
      _transcript = '';
      _matches = const [];
      _lastSearchedQuery = '';
      _isSearching = false;
      _message = null;
      _phase = _VoiceAssistantPhase.ready;
    });
    await _startListening();
  }

  Future<void> _searchTranscript({bool force = false}) async {
    final query = _transcript.trim();
    final search = widget.onSearch;
    if (query.isEmpty || search == null) return;
    if (!force && query == _lastSearchedQuery) return;

    final generation = ++_searchGeneration;
    setState(() {
      _isSearching = true;
      _message = null;
      _matches = const [];
      _lastSearchedQuery = query;
    });
    try {
      final matches = await search(query);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _matches = matches;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _matches = const [];
        _isSearching = false;
        _message = 'I could not search right now. Please try again.';
      });
    }
  }

  Future<void> _useSuggestion(String query) async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    if (!mounted) return;
    _setListeningAnimations(false);
    setState(() {
      _phase = _VoiceAssistantPhase.ready;
      _transcript = query;
      _message = null;
    });
    if (_hasSearch) {
      await _searchTranscript(force: true);
    } else {
      widget.onSubmit(query);
    }
  }

  void _setListeningAnimations(bool listening) {
    if (listening) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
      if (!_waveController.isAnimating) {
        _waveController.repeat();
      }
      return;
    }

    _pulseController.stop();
    _pulseController.value = 1;
    _waveController.stop();
    _waveController.value = 0;
  }

  Future<void> _close() async {
    await _speech.cancel();
    if (mounted) widget.onClose();
  }

  Future<void> _submit() async {
    final query = _transcript.trim();
    if (query.isEmpty || _isSearching) return;
    await _speech.stop();
    if (!mounted) return;
    if (_hasSearch && _matches.isEmpty) {
      await _searchTranscript(force: true);
      return;
    }
    widget.onSubmit(query);
  }

  @override
  void dispose() {
    _speech.cancel();
    _edgeController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _edgeIntensity.dispose();
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
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xFF020617).withValues(alpha: 0.08),
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
                      progress: _edgeController.value,
                      intensity: _edgeIntensity.value,
                      radius: edgeRadius,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: RepaintBoundary(child: _buildVoicePanel()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoicePanel() {
    final showTranscript = _transcript.trim().isNotEmpty || _message != null;
    final displayedText =
        _message ??
        (_hasTranscript
            ? _transcript
            : 'I can help you find schemes, check eligibility, track applications and more.');

    return Container(
      key: const Key('voice-assistant-panel'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF030D1E), Color(0xFF01060F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: 0.16),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.24),
            blurRadius: 36,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Companion bot image
              Image.asset(
                'assets/images/compoanion bot.png',
                height: 72,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),

              // Middle: Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Wrap (prevents overflow on narrow screens)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF60A5FA),
                          size: 16,
                        ),
                        Text(
                          'Ask IN AI',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Status Indicator Dot & Text
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _statusLabel,
                              style: GoogleFonts.inter(
                                color: _statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Transcript or helper text
                    Text(
                      displayedText,
                      key: const Key('voice-transcript'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _message == null
                            ? Colors.white.withValues(alpha: 0.72)
                            : const Color(0xFFFCA5A5),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLanguageSelector(),
                    // Suggestion Chips (only when empty)
                    if (!showTranscript) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildSuggestionChip(
                              'Business loans',
                              _language == VoiceInputLanguage.tamil
                                  ? 'business ku loan venum'
                                  : 'business loans for me',
                            ),
                            const SizedBox(width: 8),
                            _buildSuggestionChip(
                              'Student scholarship',
                              _language == VoiceInputLanguage.tamil
                                  ? 'padippuku scholarship venum'
                                  : 'scholarships for students',
                            ),
                            const SizedBox(width: 8),
                            _buildSuggestionChip(
                              'Farmer subsidy',
                              _language == VoiceInputLanguage.tamil
                                  ? 'vivasayathukku maaniyam venum'
                                  : 'subsidy for farmers',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Right Column: Waveform, Close, Mic Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pulsing Waveform
                      VoiceLevelBars(
                        animation: _waveController,
                        level: _edgeIntensity,
                        active: _isListening,
                      ),
                      const SizedBox(width: 4),
                      // Close button
                      Semantics(
                        button: true,
                        label: 'Close voice assistant',
                        child: GestureDetector(
                          key: const Key('voice-close-button'),
                          onTap: _close,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF94A3B8),
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Mic or Submit Button
                  _hasTranscript
                      ? GestureDetector(
                          onTap: _submit,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2563EB,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: _toggleListening,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF2563EB),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2563EB,
                                  ).withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none_rounded,
                              color: const Color(0xFF2563EB),
                              size: 22,
                            ),
                          ),
                        ),
                ],
              ),
            ],
          ),
          if (_isSearching) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              key: Key('voice-search-progress'),
              minHeight: 2,
              color: Color(0xFF60A5FA),
              backgroundColor: Color(0xFF172554),
            ),
          ] else if (_matches.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSearchResults(),
          ] else if (_hasTranscript &&
              _lastSearchedQuery.isNotEmpty &&
              _message == null) ...[
            const SizedBox(height: 10),
            Text(
              _language == VoiceInputLanguage.tamil
                  ? 'பொருத்தமான திட்டம் கிடைக்கவில்லை. வேறு வார்த்தைகளில் சொல்லிப் பாருங்கள்.'
                  : 'No matching scheme found. Try saying it another way.',
              key: const Key('voice-no-results'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFFFBBF24),
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Drag handle
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
    );
  }

  Widget _buildLanguageSelector() {
    return Semantics(
      label: 'Voice input language',
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('EN', VoiceInputLanguage.english),
            _buildLanguageOption('தமிழ்', VoiceInputLanguage.tamil),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String label, VoiceInputLanguage language) {
    final selected = _language == language;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: Key('voice-language-${language.name}'),
        onTap: () => _changeLanguage(language),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
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
      ),
    );
  }

  Widget _buildSearchResults() {
    final visible = _matches.take(3).toList(growable: false);
    return Column(
      key: const Key('voice-search-results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _language == VoiceInputLanguage.tamil
                    ? 'உங்களுக்கான சிறந்த திட்டங்கள்'
                    : 'Best matching schemes',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              key: const Key('voice-view-all-results'),
              onPressed: () => widget.onSubmit(_transcript.trim()),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View all',
                style: GoogleFonts.inter(
                  color: const Color(0xFF60A5FA),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        ...visible.map(_buildSearchResultCard),
      ],
    );
  }

  Widget _buildSearchResultCard(SchemeSearchMatch match) {
    final reason = match.reasons.isEmpty
        ? 'Relevant scheme'
        : match.reasons.join(' • ');
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Semantics(
        button: true,
        label: 'Open ${match.scheme.name}',
        child: InkWell(
          key: Key('voice-result-${match.scheme.id}'),
          onTap: () {
            final callback = widget.onSchemeSelected;
            if (callback != null) {
              callback(match.scheme);
            } else {
              widget.onSubmit(_transcript.trim());
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF60A5FA).withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    size: 17,
                    color: Color(0xFF93C5FD),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.scheme.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF60A5FA),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label, String query) {
    return GestureDetector(
      onTap: () => _useSuggestion(query),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
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
  Widget build(BuildContext context) {
    return Semantics(
      label: active ? 'Live voice level' : 'Voice level inactive',
      image: true,
      child: AnimatedOpacity(
        key: const Key('voice-level-bars'),
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
      ),
    );
  }
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
  bool shouldRepaint(covariant VoiceLevelPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.level != level ||
        oldDelegate.active != active;
  }
}

class VoiceEdgePainter extends CustomPainter {
  const VoiceEdgePainter({
    required this.progress,
    required this.intensity,
    required this.radius,
  });

  final double progress;
  final double intensity;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 1.25;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      math.max(0, size.width - inset * 2),
      math.max(0, size.height - inset * 2),
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final gradient = SweepGradient(
      transform: GradientRotation(progress * math.pi * 2),
      colors: const [
        Color(0x001D4ED8),
        Color(0xFF38BDF8),
        Color(0xFF2563EB),
        Color(0xFFA855F7),
        Color(0xFF22D3EE),
        Color(0x001D4ED8),
      ],
      stops: const [0, 0.16, 0.38, 0.62, 0.82, 1],
    );

    final haloGradient = SweepGradient(
      transform: GradientRotation(progress * math.pi * 2),
      colors: const [
        Color(0x001D4ED8),
        Color(0x5538BDF8),
        Color(0x662563EB),
        Color(0x66A855F7),
        Color(0x5522D3EE),
        Color(0x001D4ED8),
      ],
      stops: const [0, 0.16, 0.38, 0.62, 0.82, 1],
    );
    final haloPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 + intensity * 3
      ..shader = haloGradient.createShader(rect);
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 + intensity * 1.3
      ..shader = gradient.createShader(rect);

    canvas.drawRRect(rrect, haloPaint);
    canvas.drawRRect(rrect, edgePaint);
  }

  @override
  bool shouldRepaint(covariant VoiceEdgePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.intensity != intensity ||
        oldDelegate.radius != radius;
  }
}
