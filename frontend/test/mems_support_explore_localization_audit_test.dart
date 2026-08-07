import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/scheme_repository.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/models/localized_scheme.dart';
import 'package:frontend/services/centralized_translator.dart';
import 'package:frontend/utils/profile_l10n.dart';
import 'package:frontend/models/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MSS Localization Final Sweep — MEMS / Support / Explore Audit', () {
    late List<Scheme> allSchemes;

    setUpAll(() async {
      allSchemes = await SchemeRepository.instance.getRecommendedSchemes(UserProfile());
    });

    test('1. Every scheme converts to LocalizedScheme with valid Tamil fields', () {
      expect(allSchemes, isNotEmpty);
      for (final scheme in allSchemes) {
        final locTa = scheme.toLocalized('ta');
        expect(locTa, isA<LocalizedScheme>());
        expect(locTa.name.trim(), isNotEmpty, reason: 'Scheme ${scheme.id} has empty Tamil name');
        expect(locTa.category.trim(), isNotEmpty, reason: 'Scheme ${scheme.id} has empty Tamil category');
        expect(locTa.sponsoringBody.trim(), isNotEmpty, reason: 'Scheme ${scheme.id} has empty Tamil sponsoring body');
        expect(locTa.overview.trim(), isNotEmpty, reason: 'Scheme ${scheme.id} has empty Tamil overview');
      }
    });

    test('2. CentralizedTranslator produces valid Tamil translations for MEMS, Home Cards & Support strings', () {
      final sampleTerms = [
        'Interactive Tools & Actions',
        'Search Schemes',
        'Complete Profile',
        'Keep your list updated!',
        'Remove schemes you\'re no longer interested in.',
        'Discover Results',
        'Based on your answers',
        'Eligibility Results',
        'Great News! 🎉',
        'You are eligible for',
        'Recommended Schemes',
        'Delayed Payment Interest Calculator',
        'Invoice Amount',
        'Days Delayed',
        'Interest Rate',
        'Total Claimable',
        'WHAT THE USER GETS',
      ];

      for (final term in sampleTerms) {
        final translated = CentralizedTranslator.instance.translate(term);
        expect(translated.trim(), isNotEmpty);
      }

      final homeCardTags = [
        'enterprise finance',
        'women entrepreneurship',
        'research grant / career support',
        'general',
        'manufacturing enterprises',
        'land-purchase subsidy',
        'women welfare / household support',
        'enterprise/startup support',
      ];

      for (final tag in homeCardTags) {
        final translatedTag = CentralizedTranslator.instance.translateTag(tag);
        expect(translatedTag.trim(), isNotEmpty);
        expect(translatedTag, isNot(equals(tag)), reason: 'Tag $tag should be localized into Tamil');
      }
    });

    test('3. ProfileL10n returns Tamil for all profile role keys', () {
      final roleKeys = [
        'student',
        'student_subtitle',
        'aspiring_entrepreneur',
        'aspiring_entrepreneur_subtitle',
        'existing_business',
        'existing_business_subtitle',
        'msme_owner',
        'msme_owner_subtitle',
        'farmer',
        'farmer_subtitle',
        'artisan_shg',
        'artisan_shg_subtitle',
      ];

      for (final key in roleKeys) {
        final translated = ProfileL10n.t(key, true);
        expect(translated.trim(), isNotEmpty);
        expect(translated, isNot(equals(key)));
      }
    });
  });
}
