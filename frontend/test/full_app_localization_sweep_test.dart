import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/centralized_translator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Exhaustive Full-App Localization & UI Polish Audit', () {
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

    test('1. Verify Calculator Modals & Error Toast Memory', () {
      final calcItems = [
        'Invalid Input',
        'Please enter valid values greater than 0',
        'Base Price',
        'Total Invoice',
        'Calculate Classification',
        'Calculate Tax',
        'Calculate EMI',
        'Calculate Valuation',
        'Udyam MSME Classifier',
        'Classify your business under official government guidelines.',
        'Investment in Plant & Machinery',
        'Enter original purchase value of machinery in Crores',
        'Annual Turnover',
        'Enter total revenue/sales of last financial year in Crores',
        'GST / Tax Calculator',
        'Calculate CGST, SGST, and Total invoice amounts.',
        'Base Amount',
        'Enter net value of goods or services before GST',
        'GST Rate (%)',
        'Please enter a valid base amount',
      ];

      for (final text in calcItems) {
        assertNoMixedLanguage(text, 'Calculator Item "$text"');
      }
    });

    test('2. Verify Notifications Screen Toast & Filter Memory', () {
      final notifItems = [
        'Selected notifications marked as read',
        'Selected notifications deleted',
        'Filter options opened',
        'All notifications marked as read',
        'All notifications deleted',
      ];

      for (final text in notifItems) {
        assertNoMixedLanguage(text, 'Notif Item "$text"');
      }
    });

    test('3. Verify Companion Mode Voice UI Memory', () {
      final saarthiItems = ['Retry voice', 'Natural', 'Clear', 'Latest'];

      for (final text in saarthiItems) {
        assertNoMixedLanguage(text, 'Saarthi Voice Item "$text"');
      }
    });
  });
}
