import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/models/localized_scheme.dart';
import 'package:frontend/services/centralized_translator.dart';

void main() {
  group('CentralizedTranslator Priority Pipeline & Protection Rules', () {
    final translator = CentralizedTranslator.instance;

    test('Preserves protected text: URLs, Emails, Phone Numbers, IDs, and Dates', () {
      expect(translator.isProtectedText('https://msme.gov.in/scheme'), isTrue);
      expect(translator.isProtectedText('support@msme.gov.in'), isTrue);
      expect(translator.isProtectedText('+91 9876543210'), isTrue);
      expect(translator.isProtectedText('TN_MSME_001'), isTrue);
    });

    test('Translates chips, tags, levels, and categories into Tamil', () {
      expect(translator.translateTag('Central Scheme'), equals('மத்திய அரசு திட்டம்'));
      expect(translator.translateTag('State Scheme'), equals('மாநில அரசு திட்டம்'));
      expect(translator.translateTag('Loan'), equals('கடன்'));
      expect(translator.translateTag('Subsidy'), equals('மானியம்'));
      expect(translator.translateTag('Women'), equals('மகளிர்'));
      expect(translator.translateTag('Youth'), equals('இளைஞர்கள்'));
      expect(translator.translateTag('Agriculture'), equals('வேளாண்மை'));
      expect(translator.translateTag('Startup'), equals('ஸ்டார்ட்அப்'));
      expect(translator.translateTag('Required'), equals('தேவையானவை'));
      expect(translator.translateTag('Conditional'), equals('நிபந்தனைக்குட்பட்டது'));
    });

    test('Translates dynamic content phrases, compound strings, and micro-texts', () {
      expect(
        translator.translate('aspiring and existing entrepreneurs'),
        equals('புதிய மற்றும் நிலவும் தொழில்முனைவோர்கள்'),
      );
      expect(
        translator.translate('Technology Centre / Implementing'),
        equals('தொழில்நுட்ப மையம் / செயல்படுத்தும்'),
      );
      expect(
        translator.translate('No separate government fee stated'),
        equals('தனியான அரசு கட்டணம் இல்லை'),
      );
      expect(
        translator.translate('Age / programme eligibility information'),
        equals('வயது / திட்ட தகுதி விவரங்கள்'),
      );
      expect(
        translator.translate('Training / entrepreneurship'),
        equals('பயிற்சி / தொழில்முனைவு'),
      );
      expect(
        translator.translate('Candidate'),
        equals('விண்ணப்பதாரர்'),
      );
      expect(
        translator.translate('Varies'),
        equals('மாறுபடும்'),
      );
    });

    test('LocalizedScheme priority pipeline prefers JSON Tamil name over translation', () {
      const rawScheme = Scheme(
        id: 'test_1',
        schemeCode: 'TN_001',
        name: 'Tamil Nadu MSME Loan Scheme',
        nameTa: 'தமிழ்நாடு குறு சிறு தொழில்கள் கடன் திட்டம்',
        overview: 'Provides capital subsidy to small businesses.',
        category: 'Loan',
        governmentLevel: 'State',
        officialWebsite: 'https://tnmsme.gov.in',
      );

      final localizedTa = rawScheme.toLocalized('ta');
      // Priority 1: JSON nameTa used directly
      expect(localizedTa.name, equals('தமிழ்நாடு குறு சிறு தொழில்கள் கடன் திட்டம்'));
      // Priority 2: Category and GovernmentLevel translated to Tamil
      expect(localizedTa.category, equals('கடன்'));
      expect(localizedTa.governmentLevel, equals('மாநில அரசு'));
      // Priority 3: Protected URL preserved
      expect(localizedTa.officialWebsite, equals('https://tnmsme.gov.in'));
    });

    test('LocalizedScheme falls back to CentralizedTranslator when nameTa is empty', () {
      const rawScheme = Scheme(
        id: 'test_2',
        schemeCode: 'IN_002',
        name: 'Women Entrepreneurship Training Program',
        nameTa: '',
        category: 'Training',
        governmentLevel: 'Central',
        eligibilityCriteria: ['Women entrepreneurs aged 18+'],
        documents: [
          SchemeDocument(
            name: 'Aadhaar Card Proof',
            description: 'Identity verification certificate',
            issuingAuthority: 'UIDAI Authority',
          ),
        ],
      );

      final localizedTa = rawScheme.toLocalized('ta');
      // Priority 2: CentralizedTranslator translates name, category, eligibility, document title & authority
      expect(localizedTa.category, equals('பயிற்சி'));
      expect(localizedTa.governmentLevel, equals('மத்திய அரசு'));
      expect(localizedTa.documents.first.name, contains('சான்று'));
      expect(localizedTa.documents.first.issuingAuthority, contains('அதிகாரம்'));
    });

    test('LocalizedScheme returns unmodified values when languageCode is en', () {
      const rawScheme = Scheme(
        id: 'test_3',
        schemeCode: 'IN_003',
        name: 'Mudra Loan Scheme',
        nameTa: 'முத்ரா கடன் திட்டம்',
        category: 'Loan',
      );

      final localizedEn = rawScheme.toLocalized('en');
      expect(localizedEn.name, equals('Mudra Loan Scheme'));
      expect(localizedEn.category, equals('Loan'));
    });
  });
}
