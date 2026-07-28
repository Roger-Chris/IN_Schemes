import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/services/intelligent_scheme_search.dart';
import 'package:frontend/services/voice_recognition_controller.dart';
import 'package:frontend/widgets/voice_assistant_overlay.dart';

void main() {
  testWidgets(
    'voice assistant presents its panel and full-screen edge outline',
    (tester) async {
      var closed = false;
      final controller = _FakeVoiceRecognitionController();

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceAssistantOverlay(
            autoStart: false,
            recognitionController: controller,
            onClose: () => closed = true,
            onSubmit: (_) {},
          ),
        ),
      );

      expect(find.byKey(const Key('voice-assistant-overlay')), findsOneWidget);
      expect(find.byKey(const Key('voice-edge-outline')), findsOneWidget);
      expect(find.byKey(const Key('voice-assistant-panel')), findsOneWidget);
      expect(find.byKey(const Key('voice-level-bars')), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.text('Ask IN AI'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
      expect(
        find.byKey(const Key('voice-language-auto-badge')),
        findsOneWidget,
      );
      expect(find.text('Auto'), findsOneWidget);
      expect(
        find.byKey(const Key('voice-language-fallback-picker')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('voice-close-button')));
      await tester.pump();

      expect(closed, isTrue);
      expect(controller.cancelCount, 1);
    },
  );

  testWidgets('automatic recognition reports Tamil and ranks schemes', (
    tester,
  ) async {
    const scheme = Scheme(
      id: 'IN-TAMIL',
      name: 'Farmer Subsidy',
      targetBeneficiary: 'Farmers',
    );
    final controller = _FakeVoiceRecognitionController();

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceAssistantOverlay(
          recognitionController: controller,
          onClose: () {},
          onSubmit: (_) {},
          onSearch: (_) async => const [
            SchemeSearchMatch(
              scheme: scheme,
              score: 0.95,
              reasons: ['Agriculture'],
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(controller.lastLocaleId, isNull);
    expect(find.text('Auto'), findsOneWidget);
    expect(
      find.byKey(const Key('voice-language-fallback-picker')),
      findsNothing,
    );

    controller.emitLanguage('ta-IN');
    await tester.pump();
    expect(find.text('தமிழ்'), findsOneWidget);

    controller.emitResult('எனக்கு விவசாய மானியம் வேண்டும்', isFinal: true);
    await tester.pump();
    await tester.pump();
    expect(find.text('Farmer Subsidy'), findsOneWidget);
    expect(find.text('உங்களுக்கான சிறந்த திட்டங்கள்'), findsOneWidget);
  });

  testWidgets('unsupported devices reveal the fallback language picker', (
    tester,
  ) async {
    final controller = _FakeVoiceRecognitionController(
      capabilities: const VoiceRecognitionCapabilities(
        available: true,
        automaticLanguageDetection: false,
        reason: 'Automatic language detection requires Android 14 or newer.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceAssistantOverlay(
          recognitionController: controller,
          onClose: () {},
          onSubmit: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const Key('voice-language-fallback-picker')),
      findsOneWidget,
    );
    expect(find.text('EN'), findsOneWidget);
    expect(find.text('தமிழ்'), findsOneWidget);
    expect(
      find.text('Automatic language detection requires Android 14 or newer.'),
      findsOneWidget,
    );
    expect(controller.lastLocaleId, anyOf('en-IN', 'ta-IN'));
  });

  testWidgets('missing language model changes only that session to fallback', (
    tester,
  ) async {
    final controller = _FakeVoiceRecognitionController(
      errorOnListen: const VoiceRecognitionError(
        code: 'language_unavailable',
        message: 'English or Tamil language model is unavailable.',
        automaticUnavailable: true,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceAssistantOverlay(
          recognitionController: controller,
          onClose: () {},
          onSubmit: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const Key('voice-language-fallback-picker')),
      findsOneWidget,
    );
    expect(
      find.text('English or Tamil language model is unavailable.'),
      findsOneWidget,
    );
  });

  testWidgets('permission denial is explained without showing a toggle', (
    tester,
  ) async {
    final controller = _FakeVoiceRecognitionController(
      capabilities: const VoiceRecognitionCapabilities(
        available: false,
        automaticLanguageDetection: false,
        reason: 'Microphone permission is needed for voice search.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceAssistantOverlay(
          recognitionController: controller,
          onClose: () {},
          onSubmit: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Microphone permission is needed for voice search.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('voice-language-fallback-picker')),
      findsNothing,
    );
  });

  testWidgets('no match and repeated microphone taps remain stable', (
    tester,
  ) async {
    final controller = _FakeVoiceRecognitionController();

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceAssistantOverlay(
          autoStart: false,
          recognitionController: controller,
          onClose: () {},
          onSubmit: (_) {},
          onSearch: (_) async => const [],
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.mic_none_rounded));
    await tester.pump();
    await tester.pump();
    expect(controller.listenCount, 1);

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    expect(controller.stopCount, 1);

    await tester.tap(find.byIcon(Icons.mic_none_rounded));
    await tester.pump();
    await tester.pump();
    expect(controller.listenCount, 2);

    controller.emitResult('play a movie song', isFinal: true);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('voice-no-results')), findsOneWidget);
  });

  testWidgets('voice assistant presents ranked results and opens a scheme', (
    tester,
  ) async {
    const scheme = Scheme(
      id: 'IN-VOICE',
      name: 'Women Entrepreneur Loan',
      targetBeneficiary: 'Women entrepreneurs',
    );
    Scheme? selected;
    final controller = _FakeVoiceRecognitionController();

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceAssistantOverlay(
          autoStart: false,
          recognitionController: controller,
          onClose: () {},
          onSubmit: (_) {},
          onSearch: (_) async => const [
            SchemeSearchMatch(
              scheme: scheme,
              score: 0.9,
              reasons: ['Who it supports'],
            ),
          ],
          onSchemeSelected: (value) => selected = value,
        ),
      ),
    );

    await tester.tap(find.text('Business loans'));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('voice-search-results')), findsOneWidget);
    expect(find.text('Women Entrepreneur Loan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('voice-result-IN-VOICE')));
    expect(selected?.id, 'IN-VOICE');
  });

  test('edge painter repaints when animation values change', () {
    const original = VoiceEdgePainter(progress: 0, intensity: 0.2, radius: 28);
    const changed = VoiceEdgePainter(progress: 0.5, intensity: 0.2, radius: 28);

    expect(changed.shouldRepaint(original), isTrue);
  });

  test('voice level painter repaints for live audio changes', () {
    const original = VoiceLevelPainter(progress: 0, level: 0.2, active: true);
    const changed = VoiceLevelPainter(progress: 0.5, level: 0.8, active: true);

    expect(changed.shouldRepaint(original), isTrue);
  });
}

class _FakeVoiceRecognitionController implements VoiceRecognitionController {
  _FakeVoiceRecognitionController({
    this.capabilities = const VoiceRecognitionCapabilities(
      available: true,
      automaticLanguageDetection: true,
    ),
    this.errorOnListen,
  });

  final VoiceRecognitionCapabilities capabilities;
  final VoiceRecognitionError? errorOnListen;
  VoiceStatusCallback? _onStatus;
  VoiceResultCallback? _onResult;
  VoiceLanguageCallback? _onLanguage;
  VoiceErrorCallback? _onError;
  int listenCount = 0;
  int stopCount = 0;
  int cancelCount = 0;
  String? lastLocaleId;
  bool _isListening = false;

  @override
  bool get isListening => _isListening;

  @override
  Future<VoiceRecognitionCapabilities> initialize({
    required VoiceStatusCallback onStatus,
    required VoiceResultCallback onResult,
    required VoiceSoundLevelCallback onSoundLevel,
    required VoiceLanguageCallback onLanguage,
    required VoiceErrorCallback onError,
  }) async {
    _onStatus = onStatus;
    _onResult = onResult;
    _onLanguage = onLanguage;
    _onError = onError;
    return capabilities;
  }

  @override
  Future<void> listen({String? localeId}) async {
    listenCount++;
    lastLocaleId = localeId;
    final error = errorOnListen;
    if (error != null) {
      _isListening = false;
      _onError?.call(error);
      return;
    }
    _isListening = true;
    _onStatus?.call('listening');
  }

  void emitLanguage(String language) => _onLanguage?.call(language);

  void emitResult(String transcript, {required bool isFinal}) {
    if (isFinal) _isListening = false;
    _onResult?.call(
      VoiceRecognitionResult(transcript: transcript, isFinal: isFinal),
    );
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _isListening = false;
    _onStatus?.call('done');
  }

  @override
  Future<void> cancel() async {
    cancelCount++;
    _isListening = false;
  }

  @override
  Future<void> dispose() async {
    _isListening = false;
  }
}
