import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/categories_screen.dart';
import 'package:frontend/services/centralized_translator.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  group('FINAL APP-WIDE LOCALIZATION STABILIZATION & UI OVERFLOW SUITE', () {
    final protectedTerms = {
      'MSME',
      'MSMED',
      'GST',
      'CGST',
      'SGST',
      'IGST',
      'PAN',
      'AADHAAR',
      'SIDBI',
      'NSIC',
      'DIC',
      'KVIC',
      'TIIC',
      'SIPCOT',
      'DGFT',
      'TREDS',
      'IEC',
      'RCMC',
      'HS',
      'INR',
      'RBI',
      'PMEGP',
      'CGTMSE',
      'SFURTI',
      'TANSEED',
      'MSEFC',
      'NBFC',
      'RXIL',
      'M1XCHANGE',
      'INVOICEMART',
      'DPIIT',
      'MRR',
      'ARR',
      'KYC',
      'CSR',
      'CODE',
      'EMI',
      'MSME-DI',
      'DI',
    };

    final tamilRegex = RegExp(r'[\u0B80-\u0BFF]');

    void assertNoMixedLanguage(String original, String contextName) {
      final translated = CentralizedTranslator.instance.translate(original);
      expect(
        translated.trim(),
        isNotEmpty,
        reason: '$contextName translated to empty string',
      );

      final tokens = translated.split(RegExp(r'[^a-zA-Z0-9]+'));
      final invalidEnglishWords = tokens.where((token) {
        if (token.length < 3) return false;
        return !protectedTerms.contains(token.toUpperCase());
      }).toList();

      final hasTamil = tamilRegex.hasMatch(translated);
      if (hasTamil && invalidEnglishWords.isNotEmpty) {
        fail(
          'Mixed language sentence in $contextName: "$translated" (Invalid English words: $invalidEnglishWords) from original "$original"',
        );
      }
    }

    test('1. Verify ARB Localizations for English & Tamil', () async {
      final enLoc = await AppLocalizations.delegate.load(const Locale('en'));
      final taLoc = await AppLocalizations.delegate.load(const Locale('ta'));

      expect(enLoc.calcUdyamClassifierTitle, 'Udyam MSME Classifier');
      expect(taLoc.calcUdyamClassifierTitle, 'உத்யம் MSME வகைப்படுத்தி');

      expect(enLoc.calcGstTitle, 'GST / Tax Calculator');
      expect(taLoc.calcGstTitle, 'GST / வரி கால்குலேட்டர்');

      expect(enLoc.calcEmiTitle, 'Business Loan EMI Calculator');
      expect(taLoc.calcEmiTitle, 'தொழில் கடன் EMI கால்குலேட்டர்');

      expect(
        enLoc.notifToastSelectedRead,
        'Selected notifications marked as read',
      );
      expect(
        taLoc.notifToastSelectedRead,
        'தேர்ந்தெடுக்கப்பட்ட அறிவிப்புகள் படித்ததாகக் குறிக்கப்பட்டன',
      );
    });

    test('2. Verify Zero Mixed-Language Sentences Across All Static UI Copy', () {
      final staticCopy = [
        'Udyam MSME Classifier',
        'Classify your business under official government guidelines.',
        'Investment in Plant & Machinery',
        'Enter original purchase value of machinery in Crores',
        'Annual Turnover',
        'Enter total revenue/sales of last financial year in Crores',
        'Classification Result',
        'Calculate Classification',
        'GST / Tax Calculator',
        'Calculate CGST, SGST, and Total invoice amounts.',
        'Base Amount',
        'Enter net value of goods or services before GST',
        'GST Rate (%)',
        'Calculate Tax',
        'Business Loan EMI Calculator',
        'Calculate monthly payments for your business loan.',
        'Loan Amount',
        'Enter total business loan sum required',
        'Interest Rate (% p.a.)',
        'Tenure (Months)',
        'Calculate EMI',
        'DPIIT Recognition Checklist',
        'Evaluate if your business qualifies as a startup under DPIIT rules.',
        'Seed Valuation Estimator',
        'Calculate estimated seed stage valuation ranges based on MRR and growth.',
        'Business Setup Document Checklist',
        'Essential documents for registering and operating a business in India.',
        'Selected notifications marked as read',
        'Selected notifications deleted',
        'All notifications marked as read',
        'All notifications deleted',
        'Filter options opened',
        'Retry voice',
      ];

      for (final text in staticCopy) {
        assertNoMixedLanguage(text, 'Static UI Copy "$text"');
      }
    });

    testWidgets(
      '3. Responsive UI Sweep — Categories Screen at 320dp (Tamil mode)',
      (WidgetTester tester) async {
        final appProvider = AppProvider();
        appProvider.changeLanguage('ta');

        await tester.binding.setSurfaceSize(const Size(320, 640));

        await tester.pumpWidget(
          ChangeNotifierProvider<AppProvider>.value(
            value: appProvider,
            child: MaterialApp(
              locale: const Locale('ta'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('ta')],
              home: const Scaffold(body: CategoriesScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '4. Responsive UI Sweep — Categories Screen at 360dp (Tamil mode)',
      (WidgetTester tester) async {
        final appProvider = AppProvider();
        appProvider.changeLanguage('ta');

        await tester.binding.setSurfaceSize(const Size(360, 740));

        await tester.pumpWidget(
          ChangeNotifierProvider<AppProvider>.value(
            value: appProvider,
            child: MaterialApp(
              locale: const Locale('ta'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('ta')],
              home: const Scaffold(body: CategoriesScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
