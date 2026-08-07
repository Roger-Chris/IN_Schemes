/// Stage 2 verification — OTP screen overflow fixes.
///
/// Guards the three named root causes from the Phase 11 audit:
///   1. lines ~194-222  subtitle+phone+icon Row -> now a Wrap
///   2. lines ~255-301  fixed 42px pin boxes -> now LayoutBuilder-derived
///   3. lines ~317-345  unguarded timer RichText -> now FittedBox
/// plus the verify-button label and the main.dart TextScaler amplifier.
///
/// Renders the real OtpScreen at the three widths named in the execution
/// prompt (320/360/414 logical px), in both locales, at default and at a
/// bumped text scale, and asserts no FlutterError (RenderFlex overflow)
/// was thrown during layout.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/otp_screen.dart';
import 'package:frontend/utils/profile_l10n.dart';

Future<void> _pumpOtpAt({
  required WidgetTester tester,
  required double width,
  required String locale,
  required double textScale,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // otp_screen.dart reads AppProvider.selectedLanguage with `listen: false`
  // (correct for production: the real app always selects a language, via
  // LanguageSelectionScreen, before this screen is ever reached, and there
  // is no in-screen language switcher). So OtpScreen will NOT rebuild just
  // because the provider's language changes -- we force a fresh build by
  // calling pumpWidget a second time, after the language is set, matching
  // how a real remount would pick up the current value.
  final provider = AppProvider();

  Widget buildApp() => ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            );
          },
          // Deliberately not const: buildApp() is called twice (before and
          // after changeLanguage) and must produce a distinct widget
          // identity each time, otherwise Flutter's element diffing treats
          // the second pumpWidget as a no-op and never re-runs build().
          home: OtpScreen(phoneNumber: '9876543210'),
        ),
      );

  // First pump: lets AppProvider's constructor-triggered async _loadState()
  // (cache reads, catalog load, ...) start running.
  await tester.pumpWidget(buildApp());
  // Drain microtasks (zero-duration pumps, not a real-duration pump which
  // would also tick the OTP screen's own Timer.periodic countdown) so
  // _loadState()'s early, one-time _selectedLanguage assignment resolves
  // before we override it below.
  for (var i = 0; i < 10; i++) {
    await tester.pump(Duration.zero);
  }
  provider.changeLanguage(locale);
  // Second pump with a fresh widget tree: forces OtpScreen to rebuild from
  // scratch, picking up the now-current language despite listen: false.
  await tester.pumpWidget(buildApp());
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  // Reset the mocked SharedPreferences store before every test so a
  // language choice persisted by SessionCacheService in one test can't
  // leak into the next test's AppProvider._loadState() cache read.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const widths = [320.0, 360.0, 414.0];
  const locales = ['en', 'ta'];
  const textScales = [1.0, 2.0]; // 2.0 simulates max OS accessibility scale

  for (final width in widths) {
    for (final locale in locales) {
      for (final scale in textScales) {
        testWidgets(
          'OTP screen has no overflow at ${width}dp, locale=$locale, textScale=$scale',
          (tester) async {
            await _pumpOtpAt(
              tester: tester,
              width: width,
              locale: locale,
              textScale: scale,
            );

            expect(
              tester.takeException(),
              isNull,
              reason:
                  'OTP screen threw during layout at ${width}dp / $locale / scale=$scale '
                  '(likely a RenderFlex overflow)',
            );
          },
        );
      }
    }
  }

  testWidgets('OTP screen renders the correct Tamil OTP-sent subtitle text',
      (tester) async {
    await _pumpOtpAt(tester: tester, width: 360, locale: 'ta', textScale: 1.0);
    expect(
      find.text(ProfileL10n.t('enter_otp_sent', true)),
      findsOneWidget,
      reason: 'Tamil subtitle should render, not silently fall back to English',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('OTP screen renders the correct English OTP-sent subtitle text',
      (tester) async {
    await _pumpOtpAt(tester: tester, width: 360, locale: 'en', textScale: 1.0);
    expect(
      find.text(ProfileL10n.t('enter_otp_sent', false)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('all 6 OTP pin boxes are present and tappable at 320dp',
      (tester) async {
    await _pumpOtpAt(tester: tester, width: 320, locale: 'en', textScale: 1.0);
    expect(find.byType(TextFormField), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });
}
