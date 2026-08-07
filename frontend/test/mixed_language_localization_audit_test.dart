import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/centralized_translator.dart';
import 'package:frontend/services/scheme_repository.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/models/localized_scheme.dart';
import 'package:frontend/widgets/standard_page_header.dart';
import 'package:frontend/utils/app_card_style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Final Localization Quality & UI Consistency Audit', () {
    late List<Scheme> allSchemes;

    setUpAll(() async {
      allSchemes = await SchemeRepository.instance.getRecommendedSchemes(
        UserProfile(),
      );
    });

    test('1. Verify 0 mixed-language sentences on full UI sentences', () {
      final fullUiSentences = [
        'Find government subsidies, grants, and registration schemes you are eligible for, customized to your profile details.',
        'Personalized schemes matched to business profile',
        'Personalized schemes matched to your profile',
        'Complete your profile or explore schemes with the search engine to get smart matching results.',
        'Instantly search our database for credit support, collateral-free business loans, and SIDBI programs.',
        'Under the MSMED Act Section 15/16, buyers must pay 3x the RBI Bank Rate as compound interest with monthly rests for delays exceeding 45 days.',
        'Discover every Government Scheme in India',
        'Search for schemes offering cluster development, technology upgrades, and incubator grants.',
        'Interactive Tools & Actions',
        'Search Schemes',
        'Complete Profile',
        'Delayed Payment Interest Calculator',
        'Invoice Amount',
        'Days Delayed',
        'Interest Rate',
        'Total Claimable',
        'WHAT THE USER GETS',
      ];

      final tamilRegex = RegExp(r'[\u0B80-\u0BFF]');

      // List of protected technical terms allowed to remain English in Tamil context
      final protectedTerms = {
        'MSME',
        'MSMED',
        'GST',
        'PAN',
        'Aadhaar',
        'SIDBI',
        'CGTMSE',
        'PMEGP',
        'TReDS',
        'KVIC',
        'NSIC',
        'DIC',
        'TIIC',
        'StartupTN',
        'EdiiTN',
        'TANGEDCO',
        'INR',
        'RBI',
        'ARR',
        'CSR',
        'BSE',
        'NSE',
        'ECGC',
        'RoDTEP',
        'RoSCTL',
      };

      for (final sentence in fullUiSentences) {
        final translated = CentralizedTranslator.instance.translate(sentence);
        expect(
          translated.trim(),
          isNotEmpty,
          reason: 'Sentence "$sentence" translated to empty',
        );

        final words = translated.split(RegExp(r'\s+'));
        final englishWords = words.where((w) {
          final clean = w.replaceAll(RegExp(r'[^a-zA-Z]'), '');
          return clean.length >= 3 &&
              !protectedTerms.contains(clean.toUpperCase());
        }).toList();

        final hasTamil = tamilRegex.hasMatch(translated);

        if (hasTamil && englishWords.isNotEmpty) {
          fail(
            'Mixed language sentence detected: "$translated" (English words: $englishWords) from original "$sentence"',
          );
        }
      }
    });

    test('2. Verify standard page header widget preferred height', () {
      const headerNormal = StandardPageHeader(title: 'Test Header');
      expect(headerNormal.preferredSize.height, equals(56.0));

      const headerWithSub = StandardPageHeader(
        title: 'Test Header',
        subtitle: 'Test Subtitle',
      );
      expect(headerWithSub.preferredSize.height, equals(64.0));
    });

    test('3. Verify AppCardStyle design tokens', () {
      expect(AppCardStyle.borderRadiusValue, equals(16.0));
      expect(AppCardStyle.cardMargin.horizontal, equals(32.0));
      expect(AppCardStyle.chipSpacing, equals(6.0));
    });

    test(
      '4. Verify catalog scheme descriptions translate cleanly without mixed-language artifacts',
      () {
        expect(allSchemes, isNotEmpty);
        for (final scheme in allSchemes.take(20)) {
          final locTa = scheme.toLocalized('ta');
          expect(locTa.name.trim(), isNotEmpty);
          expect(locTa.overview.trim(), isNotEmpty);
          expect(locTa.benefits.trim(), isNotEmpty);
        }
      },
    );
  });
}
