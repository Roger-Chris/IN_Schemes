import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/scheme_repository.dart';
import 'package:frontend/services/centralized_translator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Category Navigation Architecture & Exact Data Consistency Tests', () {
    final repo = SchemeRepository.instance;
    final translator = CentralizedTranslator.instance;

    setUpAll(() async {
      await repo.getAllSchemes();
    });

    test(
      '1. SHG & Artisan returns clean exact dataset without BioCARE or WING',
      () async {
        final schemes = await repo.getSchemesByCategory('SHG & Artisan');
        expect(schemes.isNotEmpty, isTrue);

        final schemeNames = schemes.map((s) => s.name.toLowerCase()).toList();

        // Verify unrelated schemes like BioCARE and WING are NOT present
        expect(schemeNames.any((n) => n.contains('biocare')), isFalse);
        expect(schemeNames.any((n) => n.contains('wing')), isFalse);

        // Verify every returned scheme belongs to SHG / Artisan / Vishwakarma / Weaver / Craftsman
        for (final s in schemes) {
          final text =
              '${s.name} ${s.schemeType} ${s.category} ${s.targetBeneficiary} ${s.searchKeywords} ${s.overview}'
                  .toLowerCase();
          final matchesCategory =
              text.contains('artisan') ||
              text.contains('shg') ||
              text.contains('vishwakarma') ||
              text.contains('weaver') ||
              text.contains('craftsman') ||
              text.contains('self help');
          expect(
            matchesCategory,
            isTrue,
            reason:
                'Scheme ${s.name} does not belong to SHG & Artisan category',
          );
        }
      },
    );

    test(
      '2. MSME Category returns exact 134 schemes matching card badge count',
      () async {
        final schemes = await repo.getSchemesByCategory('MSME');
        expect(schemes.length, equals(134));

        for (final s in schemes) {
          final text =
              '${s.name} ${s.schemeType} ${s.category} ${s.sector} ${s.targetBeneficiary} ${s.searchKeywords} ${s.overview}'
                  .toLowerCase();
          final matchesMSME =
              text.contains('msme') ||
              text.contains('micro') ||
              text.contains('udyam') ||
              text.contains('business');
          expect(
            matchesMSME,
            isTrue,
            reason: 'Scheme ${s.name} does not belong to MSME category',
          );
        }
      },
    );

    test('3. Women Entrepreneurs Category returns exact 73 schemes', () async {
      final schemes = await repo.getSchemesByCategory('Women Entrepreneurs');
      expect(schemes.length, equals(73));

      for (final s in schemes) {
        final text =
            '${s.name} ${s.schemeType} ${s.category} ${s.targetBeneficiary} ${s.searchKeywords}'
                .toLowerCase();
        final matchesWomen =
            text.contains('women') ||
            text.contains('female') ||
            text.contains('mahila') ||
            text.contains('stree');
        expect(
          matchesWomen,
          isTrue,
          reason:
              'Scheme ${s.name} does not belong to Women Entrepreneurs category',
        );
      }
    });

    test('4. Business Loans & Credit Category returns exact 31 schemes', () async {
      final schemes = await repo.getSchemesByCategory(
        'Business Loans & Credit',
      );
      expect(schemes.length, equals(31));

      for (final s in schemes) {
        final text =
            '${s.name} ${s.schemeType} ${s.category} ${s.searchKeywords} ${s.overview}'
                .toLowerCase();
        final matchesLoan =
            text.contains('loan') ||
            text.contains('credit') ||
            text.contains('mudra') ||
            text.contains('cgtmse') ||
            text.contains('financing') ||
            text.contains('working capital');
        expect(
          matchesLoan,
          isTrue,
          reason:
              'Scheme ${s.name} does not belong to Business Loans & Credit category',
        );
      }
    });

    test('5. Startup Category returns exact 26 schemes', () async {
      final schemes = await repo.getSchemesByCategory('Startup');
      expect(schemes.length, equals(26));
    });

    test('6. Technology Category returns exact 22 schemes', () async {
      final schemes = await repo.getSchemesByCategory('Technology');
      expect(schemes.length, equals(22));
    });

    test(
      '7. Export & Trade Promotion Category returns exact 19 schemes',
      () async {
        final schemes = await repo.getSchemesByCategory(
          'Export & Trade Promotion',
        );
        expect(schemes.length, equals(19));
      },
    );

    test('8. Manufacturing Category returns exact 12 schemes', () async {
      final schemes = await repo.getSchemesByCategory('Manufacturing');
      expect(schemes.length, equals(12));
    });

    test(
      '9. All Category Titles translate cleanly to Tamil via CentralizedTranslator',
      () {
        expect(translator.translateTag('MSME'), equals('MSME'));
        expect(translator.translateTag('Startup'), equals('ஸ்டார்ட்அப்'));
        expect(
          translator.translateTag('Women Entrepreneurs'),
          equals('பெண் தொழில்முனைவோர்'),
        );
        expect(
          translator.translateTag('Business Loans & Credit'),
          equals('தொழில் கடன்கள் & கடன் உதவி'),
        );
        expect(
          translator.translateTag('Export & Trade Promotion'),
          equals('ஏற்றுமதி & வர்த்தக ஊக்குவிப்பு'),
        );
        expect(
          translator.translateTag('SHG & Artisan'),
          equals('சுய உதவிக்குழு & கைவினைஞர்'),
        );
        expect(translator.translateTag('Technology'), equals('தொழில்நுட்பம்'));
        expect(
          translator.translateTag('Manufacturing'),
          equals('உற்பத்தித் துறை'),
        );
      },
    );
  });
}
