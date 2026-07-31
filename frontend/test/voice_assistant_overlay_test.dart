import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/services/assistant_session_controller.dart';
import 'package:frontend/services/intelligent_scheme_search.dart';
import 'package:frontend/services/official_grounded_search.dart';
import 'package:frontend/services/scheme_understanding_engine.dart';
import 'package:frontend/services/speech_output_controller.dart';
import 'package:frontend/services/voice_recognition_controller.dart';
import 'package:frontend/services/voice_agent_controller.dart';
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
            speechOutputController: _FakeSpeechOutputController(),
            onClose: () => closed = true,
            onSubmit: (_) {},
          ),
        ),
      );

      expect(find.byKey(const Key('voice-assistant-overlay')), findsOneWidget);
      expect(find.byKey(const Key('voice-edge-outline')), findsOneWidget);
      expect(find.byKey(const Key('voice-assistant-panel')), findsOneWidget);
      expect(find.byKey(const Key('voice-level-bars')), findsOneWidget);
      expect(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        findsOneWidget,
      );
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.text('Ask IN AI'), findsOneWidget);
      expect(find.byKey(const Key('voice-assistant-image')), findsOneWidget);
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
      await tester.pump(const Duration(milliseconds: 50));

      expect(closed, isTrue);
      expect(controller.cancelCount, 1);
    },
  );

  testWidgets('close navigation does not wait for speech cancellation', (
    tester,
  ) async {
    final cancelCompleter = Completer<void>();
    final controller = _FakeVoiceRecognitionController(
      cancelCompleter: cancelCompleter,
    );
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceAssistantOverlay(
          autoStart: false,
          recognitionController: controller,
          speechOutputController: _FakeSpeechOutputController(),
          onClose: () => closed = true,
          onSubmit: (_) {},
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('voice-close-button')));
    await tester.pump();

    expect(closed, isTrue);
    expect(controller.cancelCount, 1);
    cancelCompleter.complete();
  });

  testWidgets('processing is distinct from active listening', (tester) async {
    final controller = _FakeVoiceRecognitionController();

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceAssistantOverlay(
          recognitionController: controller,
          speechOutputController: _FakeSpeechOutputController(),
          onClose: () {},
          onSubmit: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    controller.emitStatus('processing');
    await tester.pump();

    expect(find.text('Processing...'), findsOneWidget);
    expect(
      tester.widget<VoiceLevelBars>(find.byType(VoiceLevelBars)).active,
      isFalse,
    );
  });

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
          speechOutputController: _FakeSpeechOutputController(),
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
          speechOutputController: _FakeSpeechOutputController(),
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
          speechOutputController: _FakeSpeechOutputController(),
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
          speechOutputController: _FakeSpeechOutputController(),
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
          speechOutputController: _FakeSpeechOutputController(),
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
          speechOutputController: _FakeSpeechOutputController(),
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

  testWidgets('conversational assistant speaks a follow-up and auto-listens', (
    tester,
  ) async {
    const scheme = Scheme(
      id: 'IN-CONVERSE',
      schemeCode: 'IN-CONVERSE',
      name: 'College Student Scholarship',
      sector: 'Education',
      targetBeneficiary: 'College students',
      benefits: 'Scholarship for degree education',
      status: 'Current',
      verificationStatus: 'Verified current official source',
      sourceUrl: 'https://example.gov.in/student',
      eligibilityCriteria: [
        'Current students with annual family income up to 2.5 lakh can apply.',
      ],
    );
    final recognition = _FakeVoiceRecognitionController();
    final speech = _FakeSpeechOutputController(completeSpeech: true);
    final session = AssistantSessionController(
      engine: const LocalSchemeUnderstandingEngine(),
      schemes: const [scheme],
      profile: UserProfile(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceAssistantOverlay(
          schemes: const [scheme],
          profile: UserProfile(),
          sessionController: session,
          recognitionController: recognition,
          speechOutputController: speech,
          onClose: () {},
          onSubmit: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    recognition.emitResult(
      'I am a college student and need a scholarship',
      isFinal: true,
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));

    expect(find.byKey(const Key('voice-follow-up-question')), findsOneWidget);
    expect(find.byKey(const Key('voice-assistant-reply')), findsOneWidget);
    expect(speech.spokenTexts, isNotEmpty);
    expect(speech.spokenTexts.single, contains('annual income'));
    expect(recognition.listenCount, 2);

    recognition.emitResult('2 lakh rupees annual income', isFinal: true);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      session.state.statement,
      'I am a college student and need a scholarship',
    );
    expect(session.state.facts[EligibilityFactKey.studentStatus]?.value, 'Yes');
    expect(
      session.state.facts[EligibilityFactKey.annualIncome]?.value,
      '200000',
    );
    expect(session.state.phase, AssistantSessionPhase.results);
    expect(find.byKey(const Key('voice-search-results')), findsOneWidget);
    expect(find.text('College Student Scholarship'), findsOneWidget);
    expect(find.textContaining('Why this fits:'), findsOneWidget);
    expect(find.text('Current official source verified'), findsOneWidget);
  });

  testWidgets('profile facts are reviewed before being saved', (tester) async {
    const scheme = Scheme(
      id: 'IN-PROFILE',
      schemeCode: 'IN-PROFILE',
      name: 'Women Enterprise Support',
      state: 'Tamil Nadu',
      sector: 'Business manufacturing',
      targetBeneficiary: 'Women entrepreneurs',
      benefits: 'Loan and subsidy',
      status: 'Current',
      verificationStatus: 'Verified official source',
      sourceUrl: 'https://example.gov.in/women',
      eligibilityCriteria: [
        'Women aged 21-45 residing in Tamil Nadu can start a manufacturing enterprise.',
      ],
    );
    final recognition = _FakeVoiceRecognitionController();
    UserProfile? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceAssistantOverlay(
          autoStart: false,
          schemes: const [scheme],
          profile: UserProfile(),
          understandingEngine: const LocalSchemeUnderstandingEngine(),
          recognitionController: recognition,
          speechOutputController: _FakeSpeechOutputController(),
          onProfileConfirmed: (profile) => saved = profile,
          onClose: () {},
          onSubmit: (_) {},
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.mic_none_rounded));
    await tester.pump();
    recognition.emitResult(
      'I am a 30 years old woman in Tamil Nadu starting a manufacturing business',
      isFinal: true,
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('voice-review-profile')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('voice-review-profile')));
    await tester.tap(find.byKey(const Key('voice-review-profile')));
    await tester.pump();
    expect(find.byKey(const Key('voice-profile-review')), findsOneWidget);
    await tester.tap(find.text('Save confirmed'));
    await tester.pump();

    expect(saved?.gender, 'Female');
    expect(saved?.state, 'Tamil Nadu');
    expect(saved?.businessIndustry, 'Manufacturing');
    expect(saved?.profileCompleted, isTrue);
  });

  testWidgets(
    'regular and Companion surfaces show cited official online evidence',
    (tester) async {
      for (final surface in VoiceAgentSurface.values) {
        final grounding = _FakeOfficialGroundedSearch();
        await tester.pumpWidget(
          MaterialApp(
            home: VoiceAssistantOverlay(
              key: ValueKey(surface),
              autoStart: false,
              initialText: 'msme definition and registration',
              schemes: const [
                Scheme(
                  id: 'IN-MSME',
                  schemeCode: 'IN-MSME',
                  name: 'MSME Registration Support',
                  sector: 'Business MSME registration',
                  benefits: 'Registration guidance',
                  status: 'Current',
                  verificationStatus: 'Verified official source',
                  sourceUrl: 'https://udyamregistration.gov.in/Important.aspx',
                ),
              ],
              profile: UserProfile(),
              understandingEngine: const LocalSchemeUnderstandingEngine(),
              recognitionController: _FakeVoiceRecognitionController(),
              speechOutputController: _FakeSpeechOutputController(),
              groundedSearch: grounding,
              surface: surface,
              onClose: () {},
              onSubmit: (_) {},
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));

        expect(find.byKey(const Key('voice-online-grounding')), findsOneWidget);
        expect(find.textContaining('Grounded online'), findsOneWidget);
        expect(find.text('Udyam Registration Portal'), findsOneWidget);
        expect(
          find.byKey(const Key('voice-grounding-privacy-note')),
          findsOneWidget,
        );
        expect(grounding.lastRequest?.topic, 'msme_definition');
        expect(
          grounding.lastRequest?.sourceUrls,
          contains('https://udyamregistration.gov.in/Important.aspx'),
        );
      }
    },
  );

  testWidgets('missing Tamil TTS leaves the follow-up readable and manual', (
    tester,
  ) async {
    const scheme = Scheme(
      id: 'IN-TAMIL-FOLLOWUP',
      name: 'மாணவர் கல்வி உதவித்தொகை',
      sector: 'Education student scholarship',
      targetBeneficiary: 'Students',
      status: 'Current',
      verificationStatus: 'Verified official source',
      sourceUrl: 'https://example.gov.in/tamil-student',
      eligibilityCriteria: [
        'Current students with annual family income up to 2.5 lakh can apply.',
      ],
    );
    final recognition = _FakeVoiceRecognitionController();
    final speech = _FakeSpeechOutputController(
      capabilities: const SpeechOutputCapabilities(
        available: true,
        english: true,
        tamil: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VoiceAssistantOverlay(
          schemes: const [scheme],
          profile: UserProfile(),
          understandingEngine: const LocalSchemeUnderstandingEngine(),
          recognitionController: recognition,
          speechOutputController: speech,
          onClose: () {},
          onSubmit: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    recognition.emitLanguage('ta-IN');
    recognition.emitResult('எனக்கு கல்லூரி உதவித்தொகை வேண்டும்', isFinal: true);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('voice-follow-up-question')), findsOneWidget);
    expect(
      find.text('Speech output is unavailable; tap the microphone to answer.'),
      findsOneWidget,
    );
    expect(speech.spokenTexts, isEmpty);
    expect(recognition.listenCount, 1);
  });

  test('edge painter repaints when animation values change', () {
    final original = VoiceEdgePainter(
      entranceProgress: 1,
      ambientProgress: 0,
      activityIntensity: 0.2,
      activity: VoiceEdgeActivity.idle,
      radius: 28,
      reduceMotion: false,
    );
    final changed = VoiceEdgePainter(
      entranceProgress: 1,
      ambientProgress: 0.5,
      activityIntensity: 0.2,
      activity: VoiceEdgeActivity.idle,
      radius: 28,
      reduceMotion: false,
    );

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
    this.cancelCompleter,
  });

  final VoiceRecognitionCapabilities capabilities;
  final VoiceRecognitionError? errorOnListen;
  final Completer<void>? cancelCompleter;
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

  void emitStatus(String status) {
    _isListening = status == 'listening';
    _onStatus?.call(status);
  }

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
    await cancelCompleter?.future;
  }

  @override
  Future<void> dispose() async {
    _isListening = false;
  }
}

class _FakeSpeechOutputController implements SpeechOutputController {
  _FakeSpeechOutputController({
    this.capabilities = const SpeechOutputCapabilities(
      available: true,
      english: true,
      tamil: true,
    ),
    this.completeSpeech = false,
  });

  final SpeechOutputCapabilities capabilities;
  final bool completeSpeech;
  final List<String> spokenTexts = [];

  @override
  Future<SpeechOutputCapabilities> initialize() async => capabilities;

  @override
  Future<bool> speak(String text, {required String languageTag}) async {
    spokenTexts.add(text);
    return completeSpeech;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _FakeOfficialGroundedSearch implements OfficialGroundedSearch {
  GroundedSearchRequest? lastRequest;

  @override
  Future<GroundedSearchResult> search(GroundedSearchRequest request) async {
    lastRequest = request;
    return GroundedSearchResult(
      outcome: GroundedSearchOutcome.found,
      sources: [
        GroundedSource(
          title: 'Udyam Registration Portal',
          url: Uri.parse('https://udyamregistration.gov.in/Important.aspx'),
          snippet:
              'MSME registration is completed online through the official Udyam portal.',
          verifiedAt: DateTime(2026, 7, 31),
        ),
      ],
    );
  }

  @override
  void close() {}
}
