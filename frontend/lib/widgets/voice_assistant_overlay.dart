import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum _VoiceAssistantPhase { starting, listening, ready, unavailable }

class VoiceAssistantOverlay extends StatefulWidget {
  const VoiceAssistantOverlay({
    super.key,
    required this.onClose,
    required this.onSubmit,
    this.autoStart = true,
  });

  final VoidCallback onClose;
  final ValueChanged<String> onSubmit;
  final bool autoStart;

  @override
  State<VoiceAssistantOverlay> createState() => _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends State<VoiceAssistantOverlay>
    with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  late final AnimationController _edgeController;
  late final AnimationController _pulseController;

  _VoiceAssistantPhase _phase = _VoiceAssistantPhase.starting;
  String _transcript = '';
  String? _message;
  double _soundLevel = 0;

  bool get _isListening => _phase == _VoiceAssistantPhase.listening;
  bool get _hasTranscript => _transcript.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _edgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.82,
      upperBound: 1,
    )..repeat(reverse: true);

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
    } else {
      _phase = _VoiceAssistantPhase.ready;
    }
  }

  Future<void> _startListening() async {
    if (!mounted) return;
    setState(() {
      _phase = _VoiceAssistantPhase.starting;
      _message = null;
    });

    try {
      final available = await _speech.initialize(
        onStatus: _handleStatus,
        onError: (error) {
          if (!mounted) return;
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

      await _speech.listen(
        onResult: _handleResult,
        onSoundLevelChange: (level) {
          if (!mounted) return;
          setState(() {
            _soundLevel = ((level + 2) / 12).clamp(0.0, 1.0);
          });
        },
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          listenMode: ListenMode.search,
          autoPunctuation: true,
          listenFor: Duration(seconds: 30),
          pauseFor: Duration(seconds: 4),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _VoiceAssistantPhase.unavailable;
        _message = 'Voice recognition could not start. Please try again.';
      });
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      _transcript = result.recognizedWords;
      if (result.finalResult) {
        _phase = _VoiceAssistantPhase.ready;
      }
    });
  }

  void _handleStatus(String status) {
    if (!mounted) return;
    if (status == SpeechToText.listeningStatus) {
      setState(() => _phase = _VoiceAssistantPhase.listening);
    } else if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      setState(() {
        _phase = _VoiceAssistantPhase.ready;
        _soundLevel = 0;
      });
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (!mounted) return;
    setState(() {
      _phase = _VoiceAssistantPhase.ready;
      _soundLevel = 0;
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _close() async {
    await _speech.cancel();
    if (mounted) widget.onClose();
  }

  Future<void> _submit() async {
    final query = _transcript.trim();
    if (query.isEmpty) return;
    await _speech.stop();
    if (mounted) widget.onSubmit(query);
  }

  @override
  void dispose() {
    _speech.cancel();
    _edgeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String get _statusLabel {
    switch (_phase) {
      case _VoiceAssistantPhase.starting:
        return 'Getting ready…';
      case _VoiceAssistantPhase.listening:
        return 'Listening…';
      case _VoiceAssistantPhase.ready:
        return _hasTranscript ? 'Voice query ready' : 'Tap the mic to speak';
      case _VoiceAssistantPhase.unavailable:
        return 'Voice is unavailable';
    }
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
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
              child: Container(
                color: const Color(0xFF020617).withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                key: const Key('voice-edge-outline'),
                animation: _edgeController,
                builder: (context, child) => CustomPaint(
                  painter: VoiceEdgePainter(
                    progress: _edgeController.value,
                    intensity: _isListening
                        ? math.max(0.25, _soundLevel)
                        : 0.12,
                    radius: edgeRadius,
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
                child: _buildVoicePanel(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoicePanel() {
    final helperText =
        _message ??
        (_hasTranscript
            ? _transcript
            : 'Ask about a scholarship, farmer benefit, business loan, or any government scheme.');

    return Container(
      key: const Key('voice-assistant-panel'),
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF07111F),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.28),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF60A5FA),
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Ask IN AI',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: AnimatedOpacity(
                        opacity: _isListening ? 1 : 0.65,
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          _statusLabel,
                          key: const Key('voice-status-label'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: _isListening
                                ? const Color(0xFF67E8F9)
                                : const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  helperText,
                  key: const Key('voice-transcript'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _message == null
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFFFCA5A5),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (_hasTranscript)
            IconButton.filled(
              key: const Key('voice-submit-button'),
              tooltip: 'Search with voice query',
              onPressed: _submit,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
            )
          else
            ScaleTransition(
              scale: _isListening
                  ? _pulseController
                  : const AlwaysStoppedAnimation(1),
              child: IconButton.filled(
                key: const Key('voice-microphone-button'),
                tooltip: _isListening ? 'Stop listening' : 'Start listening',
                onPressed: _toggleListening,
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: _isListening
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF2563EB),
                  foregroundColor: _isListening
                      ? const Color(0xFF0F172A)
                      : Colors.white,
                ),
                icon: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                ),
              ),
            ),
          IconButton(
            key: const Key('voice-close-button'),
            tooltip: 'Close voice assistant',
            onPressed: _close,
            color: const Color(0xFF94A3B8),
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
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
    const inset = 3.5;
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

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 + intensity * 5
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 + intensity * 1.8
      ..shader = gradient.createShader(rect);

    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, edgePaint);
  }

  @override
  bool shouldRepaint(covariant VoiceEdgePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.intensity != intensity ||
        oldDelegate.radius != radius;
  }
}
