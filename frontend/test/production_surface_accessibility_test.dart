import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/navigation_mode_screen.dart' as app_navigation;
import 'package:frontend/screens/regular_mode/about_you_profile_screen.dart';
import 'package:frontend/screens/regular_mode/basic_profile_screen.dart';
import 'package:frontend/screens/regular_mode/language_selection_screen.dart';
import 'package:frontend/screens/regular_mode/location_profile_screen.dart';
import 'package:frontend/services/speech_output_controller.dart';
import 'package:frontend/services/voice_recognition_controller.dart';
import 'package:frontend/widgets/voice_assistant_overlay.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _phoneViewport = Size(320, 568);
const _tabletViewport = Size(800, 1000);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  for (final viewport in <String, Size>{
    'narrow phone': _phoneViewport,
    'wide tablet': _tabletViewport,
  }.entries) {
    testWidgets(
      'Google-only login is accessible and overflow-free on ${viewport.key}',
      (tester) async {
        await _withSemantics(tester, () async {
          final provider = AppProvider();
          addTearDown(provider.dispose);
          _setViewport(tester, viewport.value);

          await _pumpSurface(tester, provider, const LoginScreen());

          final googleButton = find.widgetWithText(
            OutlinedButton,
            'Continue with Google',
          );
          expect(googleButton, findsOneWidget);
          expect(find.byType(TextFormField), findsNothing);
          expect(find.textContaining('OTP'), findsNothing);
          expect(find.textContaining('Mobile number'), findsNothing);
          expect(
            tester.widget<OutlinedButton>(googleButton).onPressed,
            isNotNull,
          );
          _expectTappableSemantics(
            tester,
            googleButton,
            'Continue with Google',
          );
          expect(tester.takeException(), isNull);
        });
      },
    );

    testWidgets(
      'navigation mode controls select and continue on ${viewport.key}',
      (tester) async {
        await _withSemantics(tester, () async {
          final provider = AppProvider();
          addTearDown(provider.dispose);
          _setViewport(tester, viewport.value);
          app_navigation.NavigationMode? submittedMode;

          await _pumpSurface(
            tester,
            provider,
            app_navigation.NavigationModeScreen(
              onContinue: (mode) => submittedMode = mode,
            ),
          );

          expect(find.text('Regular Navigation'), findsOneWidget);
          expect(find.text('AI Companion'), findsOneWidget);
          expect(
            find.byType(app_navigation.NavigationOptionCard),
            findsNWidgets(2),
          );

          await tester.ensureVisible(find.text('AI Companion'));
          await tester.tap(find.text('AI Companion'));
          await tester.pump(const Duration(milliseconds: 350));

          final continueButton = find.widgetWithText(
            ElevatedButton,
            'Continue',
          );
          await tester.ensureVisible(continueButton);
          expect(
            tester.widget<ElevatedButton>(continueButton).onPressed,
            isNotNull,
          );
          _expectTappableSemantics(tester, continueButton, 'Continue');
          await tester.tap(continueButton);
          await tester.pump();

          expect(submittedMode, app_navigation.NavigationMode.companion);
          expect(provider.navigationMode, 'companion');
          expect(tester.takeException(), isNull);
        });
      },
    );

    testWidgets(
      'language selection is operable and persists Tamil on ${viewport.key}',
      (tester) async {
        await _withSemantics(tester, () async {
          final provider = AppProvider();
          addTearDown(provider.dispose);
          _setViewport(tester, viewport.value);

          await _pumpSurface(tester, provider, const LanguageSelectionScreen());

          expect(find.text('Choose Your Language'), findsOneWidget);
          expect(find.text('English'), findsNWidgets(2));
          expect(find.text('Tamil'), findsOneWidget);
          expect(find.byType(InkWell), findsAtLeastNWidgets(2));

          final continueButton = find.byType(ElevatedButton);
          await tester.ensureVisible(continueButton);
          _expectTappableSemantics(tester, continueButton, 'Continue');

          await tester.ensureVisible(find.text('Tamil'));
          await tester.tap(find.text('Tamil'));
          await tester.pump(const Duration(milliseconds: 250));
          await tester.ensureVisible(continueButton);
          await tester.tap(continueButton);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(provider.selectedLanguage, 'ta');
          expect(find.byType(LoginScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      },
    );

    testWidgets(
      'profile onboarding controls validate safely on ${viewport.key}',
      (tester) async {
        await _withSemantics(tester, () async {
          final provider = AppProvider();
          addTearDown(provider.dispose);
          _setViewport(tester, viewport.value);

          await _pumpSurface(tester, provider, const BasicProfileScreen());
          expect(find.text('Complete Your Profile'), findsOneWidget);
          expect(find.text('Full Name'), findsOneWidget);
          expect(find.text('Email Address'), findsOneWidget);
          expect(find.text('Gender'), findsOneWidget);
          expect(find.text('Date of Birth (DOB)'), findsOneWidget);
          expect(find.byType(TextFormField), findsAtLeastNWidgets(3));

          var continueButton = find.widgetWithText(ElevatedButton, 'Continue');
          await tester.ensureVisible(continueButton);
          _expectTappableSemantics(tester, continueButton, 'Continue');
          await tester.tap(continueButton);
          await tester.pump();
          expect(find.byType(SnackBar), findsOneWidget);
          expect(find.byType(LocationProfileScreen), findsNothing);
          expect(tester.takeException(), isNull);

          await _pumpSurface(tester, provider, const LocationProfileScreen());
          await tester.pump();
          expect(find.text('Where Are You Located?'), findsOneWidget);
          expect(find.text('Use My Current Location'), findsOneWidget);
          expect(find.byType(TextFormField), findsNWidgets(5));
          continueButton = find.widgetWithText(ElevatedButton, 'Continue');
          await tester.ensureVisible(continueButton);
          _expectTappableSemantics(tester, continueButton, 'Continue');
          await tester.tap(continueButton);
          await tester.pump();
          expect(find.byType(SnackBar), findsOneWidget);
          expect(find.byType(AboutYouProfileScreen), findsNothing);
          expect(tester.takeException(), isNull);

          await _pumpSurface(tester, provider, const AboutYouProfileScreen());
          expect(find.text('Tell Us About You'), findsOneWidget);
          expect(find.text('Student'), findsOneWidget);
          expect(find.text('Farmer'), findsOneWidget);
          continueButton = find.widgetWithText(ElevatedButton, 'Continue');
          await tester.ensureVisible(continueButton);
          await tester.tap(continueButton);
          await tester.pump();
          expect(provider.profile.profileCompleted, isFalse);
          expect(find.byType(SnackBar), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      },
    );

    testWidgets(
      'voice overlay exposes responsive mic and close controls on ${viewport.key}',
      (tester) async {
        await _withSemantics(tester, () async {
          _setViewport(tester, viewport.value);
          final recognition = _AuditRecognitionController();
          var closed = false;

          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: VoiceAssistantOverlay(
                autoStart: false,
                recognitionController: recognition,
                speechOutputController: const _AuditSpeechOutputController(),
                onClose: () => closed = true,
                onSubmit: (_) {},
              ),
            ),
          );
          await tester.pump();

          final mic = find.byKey(const Key('voice-primary-control'));
          final close = find.byKey(const Key('voice-close-button'));
          expect(mic, findsOneWidget);
          expect(close, findsOneWidget);
          _expectTappableSemantics(tester, mic, 'Start listening');
          final closeSemantics = tester.getSemantics(close).getSemanticsData();
          expect(closeSemantics.tooltip, 'Cancel assistant');
          expect(closeSemantics.hasAction(SemanticsAction.tap), isTrue);
          expect(tester.widget<IconButton>(mic).onPressed, isNotNull);
          expect(tester.widget<IconButton>(close).onPressed, isNotNull);

          await tester.tap(mic);
          await tester.pump();
          expect(recognition.listenCount, 1);
          _expectTappableSemantics(tester, mic, 'Stop listening');
          expect(tester.takeException(), isNull);

          await tester.tap(close);
          await tester.pump();
          expect(closed, isTrue);
          expect(recognition.cancelCount, 1);
        });
      },
    );
  }
}

Future<void> _withSemantics(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final handle = tester.ensureSemantics();
  try {
    await body();
  } finally {
    handle.dispose();
  }
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpSurface(
  WidgetTester tester,
  AppProvider provider,
  Widget home,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pump();
}

void _expectTappableSemantics(
  WidgetTester tester,
  Finder finder,
  String expectedLabel,
) {
  expect(finder, findsOneWidget);
  final semanticsFinder = find.bySemanticsLabel(expectedLabel);
  expect(semanticsFinder, findsOneWidget);
  final data = tester.getSemantics(semanticsFinder).getSemanticsData();
  expect(data.hasAction(SemanticsAction.tap), isTrue);
}

class _AuditRecognitionController implements VoiceRecognitionController {
  VoiceStatusCallback? _onStatus;
  bool _isListening = false;
  int listenCount = 0;
  int cancelCount = 0;

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
    return const VoiceRecognitionCapabilities(
      available: true,
      automaticLanguageDetection: true,
    );
  }

  @override
  Future<void> listen({String? localeId}) async {
    listenCount++;
    _isListening = true;
    _onStatus?.call('listening');
  }

  @override
  Future<void> stop() async {
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

class _AuditSpeechOutputController implements SpeechOutputController {
  const _AuditSpeechOutputController();

  @override
  Future<SpeechOutputCapabilities> initialize() async =>
      const SpeechOutputCapabilities(
        available: true,
        english: true,
        tamil: true,
      );

  @override
  Future<bool> speak(String text, {required String languageTag}) async => false;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
